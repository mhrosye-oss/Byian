import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:itqan/features/engagement/data/services/engagement_service.dart';
import 'package:itqan/features/engagement/presentation/widgets/banner_slider_widget.dart';
import 'package:itqan/features/engagement/presentation/widgets/dynamic_popup_widget.dart';
import 'package:itqan/features/engagement/presentation/widgets/engagement_popup_widget.dart';
import 'package:itqan/features/gamification/presentation/widgets/journey_banner.dart';
import 'package:itqan/features/home/home_screen.dart';
import 'package:itqan/features/home/widgets/next_prayer_banner.dart';
import 'package:shared_preferences/shared_preferences.dart';

Map<String, dynamic> item(
        String uuid, String type, String placement, String title) =>
    {
      'uuid': uuid,
      'type': type,
      'placement': placement,
      'text': {'title': title},
    };
http.Response response(List<Map<String, dynamic>> items) => http.Response(
    jsonEncode({'success': true, 'count': items.length, 'data': items}), 200);

void main() {
  final binding = TestWidgetsFlutterBinding.ensureInitialized();
  const storage = MethodChannel('plugins.it_nomads.com/flutter_secure_storage');
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    binding.defaultBinaryMessenger
        .setMockMethodCallHandler(storage, (_) async => null);
  });
  tearDown(() {
    binding.defaultBinaryMessenger.setMockMethodCallHandler(storage, null);
  });

  testWidgets(
      'home places banner between prayer and journey, using separate paths',
      (tester) async {
    tester.view.physicalSize = const Size(1000, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final paths = <String>[];
    final service = EngagementService(
        client: MockClient((request) async {
          paths.add(request.url.path);
          if (request.url.path.endsWith('home_top_desktop')) {
            return response([
              item('bad-popup', 'popup', 'home_top_desktop', 'Not a banner'),
              item('other-placement', 'banner', 'welcome_popup',
                  'Wrong placement'),
              item('good-banner', 'banner', 'home_top_desktop',
                  'Banner content'),
            ]);
          }
          return response([]);
        }),
        tokenProvider: () async => null);
    await tester.pumpWidget(ProviderScope(
        child: MaterialApp(
      home: HomeScreen(
          engagementService: service, popupSession: EngagementPopupSession()),
    )));
    await tester.pump();
    await tester.pump();
    final prayer = find.byType(NextPrayerBanner);
    final banner = find.byType(BannerSliderWidget);
    final journey = find.byType(JourneyBanner);
    expect(prayer, findsOneWidget);
    expect(banner, findsOneWidget);
    expect(journey, findsOneWidget);
    expect(
        tester.getTopLeft(prayer).dy, lessThan(tester.getTopLeft(banner).dy));
    expect(
        tester.getTopLeft(banner).dy, lessThan(tester.getTopLeft(journey).dy));
    expect(find.text('Banner content'), findsOneWidget);
    expect(find.text('Not a banner'), findsNothing);
    expect(find.text('Wrong placement'), findsNothing);
    expect(find.byType(DynamicPopupWidget), findsNothing);
    expect(paths.where((p) => p.endsWith('/home_top_desktop')).length, 1);
    expect(paths.where((p) => p.endsWith('/welcome_popup')).length, 1);
    expect(paths.where((p) => p.endsWith('/good-banner/track-view')).length, 1);
    expect(paths.any((p) => p.contains('bad-popup/track-view')), isFalse);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });

  testWidgets(
      'popup appears after first frame once per session, not per rebuild or re-entry',
      (tester) async {
    final session = EngagementPopupSession();
    var fetches = 0;
    var tracks = 0;
    final service = EngagementService(
        client: MockClient((request) async {
          if (request.method == 'POST') {
            tracks++;
            expect(request.url.path, endsWith('/popup/track-view'));
            return http.Response('', 204);
          }
          fetches++;
          expect(request.url.path, endsWith('/welcome_popup'));
          return response([
            item('wrong-type', 'banner', 'welcome_popup', 'Not popup'),
            item('wrong-place', 'popup', 'home_top_desktop', 'Wrong popup'),
            item('popup', 'popup', 'welcome_popup', 'Welcome popup'),
            item('second-popup', 'popup', 'welcome_popup', 'Second popup'),
          ]);
        }),
        tokenProvider: () async => null);
    Widget app(EngagementPopupSession run, String value) => MaterialApp(
          home: EngagementPopupWidget(
            session: run,
            service: service,
            child: Scaffold(body: Text(value)),
          ),
        );
    await tester.pumpWidget(app(session, 'initial'));
    expect(find.byType(DynamicPopupWidget), findsNothing);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Welcome popup'), findsOneWidget);
    expect(find.text('Second popup'), findsNothing);
    expect(find.text('Not popup'), findsNothing);
    expect(tracks, 1);
    await tester.pumpWidget(app(session, 'rebuilt'));
    await tester.pump();
    expect(find.byType(DynamicPopupWidget), findsOneWidget);
    expect(fetches, 1);
    await tester.tap(find.byIcon(Icons.close_rounded));
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpWidget(app(session, 're-entered'));
    await tester.pump();
    expect(find.byType(DynamicPopupWidget), findsNothing);
    expect(fetches, 1);
    // A fresh in-memory session models a new app process, with no preferences.
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpWidget(app(EngagementPopupSession(), 'new run'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byType(DynamicPopupWidget), findsOneWidget);
    expect(fetches, 2);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });

  testWidgets('simultaneous home entries cannot show two dialogs',
      (tester) async {
    final pending = Completer<http.Response>();
    var fetches = 0;
    final session = EngagementPopupSession();
    final service = EngagementService(
        client: MockClient((request) async {
          if (request.method == 'POST') return http.Response('', 204);
          fetches++;
          return pending.future;
        }),
        tokenProvider: () async => null);
    await tester.pumpWidget(MaterialApp(
        home: Column(children: [
      EngagementPopupWidget(
          session: session, service: service, child: const SizedBox()),
      EngagementPopupWidget(
          session: session, service: service, child: const SizedBox()),
    ])));
    await tester.pump();
    expect(fetches, 1);
    pending.complete(
        response([item('popup', 'popup', 'welcome_popup', 'Only one')]));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byType(DynamicPopupWidget), findsOneWidget);
    expect(fetches, 1);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    expect(tester.takeException(), isNull);
  });

  testWidgets('disposed home does not show pending popup; next entry can retry',
      (tester) async {
    final first = Completer<http.Response>();
    final session = EngagementPopupSession();
    var fetches = 0;
    final service = EngagementService(
        client: MockClient((request) async {
          if (request.method == 'POST') return http.Response('', 204);
          fetches++;
          if (fetches == 1) return first.future;
          return response(
              [item('new', 'popup', 'welcome_popup', 'New home popup')]);
        }),
        tokenProvider: () async => null);
    Widget app(bool show) => MaterialApp(
        home: show
            ? EngagementPopupWidget(
                session: session, service: service, child: const Text('Home'))
            : const Text('Away'));
    await tester.pumpWidget(app(true));
    await tester.pump();
    expect(fetches, 1);
    await tester.pumpWidget(app(false));
    await tester.pumpWidget(app(true));
    await tester.pump();
    expect(fetches, 1);
    first.complete(
        response([item('old', 'popup', 'welcome_popup', 'Old popup')]));
    await tester.pump();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(fetches, 2);
    expect(find.text('Old popup'), findsNothing);
    expect(find.text('New home popup'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });

  testWidgets('a covered home does not open a popup over another dialog',
      (tester) async {
    final pending = Completer<http.Response>();
    final navigator = GlobalKey<NavigatorState>();
    var tracks = 0;
    final service = EngagementService(
        client: MockClient((request) async {
          if (request.method == 'POST') {
            tracks++;
            return http.Response('', 204);
          }
          return pending.future;
        }),
        tokenProvider: () async => null);
    await tester.pumpWidget(MaterialApp(
      navigatorKey: navigator,
      home: EngagementPopupWidget(
        session: EngagementPopupSession(),
        service: service,
        child: const Scaffold(body: Text('Home')),
      ),
    ));
    await tester.pump();
    navigator.currentState!.push(DialogRoute<void>(
      context: navigator.currentContext!,
      builder: (_) => const AlertDialog(content: Text('Other dialog')),
    ));
    await tester.pump(const Duration(milliseconds: 300));
    pending.complete(response([item('ad', 'popup', 'welcome_popup', 'Ad')]));
    await tester.pump();
    expect(find.text('Other dialog'), findsOneWidget);
    expect(find.byType(DynamicPopupWidget), findsNothing);
    expect(tracks, 0);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    expect(tester.takeException(), isNull);
  });

  testWidgets('removing the home owner closes its active popup',
      (tester) async {
    final visible = ValueNotifier(true);
    addTearDown(visible.dispose);
    final service = EngagementService(
        client: MockClient((request) async => request.method == 'POST'
            ? http.Response('', 204)
            : response([item('ad', 'popup', 'welcome_popup', 'Ad')])),
        tokenProvider: () async => null);
    final session = EngagementPopupSession();
    await tester.pumpWidget(MaterialApp(
      home: ValueListenableBuilder<bool>(
        valueListenable: visible,
        builder: (_, show, __) => show
            ? EngagementPopupWidget(
                session: session,
                service: service,
                child: const Scaffold(body: Text('Home')),
              )
            : const Scaffold(body: Text('Away')),
      ),
    ));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byType(DynamicPopupWidget), findsOneWidget);
    visible.value = false;
    await tester.pump();
    await tester.pump();
    expect(find.byType(DynamicPopupWidget), findsNothing);
    expect(find.text('Away'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
