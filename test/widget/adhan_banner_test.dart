import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:itqan/features/home/widgets/next_prayer_banner.dart';
import 'package:itqan/features/prayer/services/adhan_playback_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeAudio implements AdhanAudioBackend {
  final events = StreamController<bool>.broadcast(sync: true);
  int loads = 0;
  int stops = 0;
  bool failure = false;
  @override
  Stream<bool> get playing => events.stream;
  @override
  Future<void> load() async {
    loads++;
    if (failure) throw StateError('load failed');
  }

  @override
  Future<void> play() async => events.add(true);
  @override
  Future<void> stop() async {
    stops++;
    events.add(false);
  }

  @override
  Future<void> dispose() => events.close();
}

void main() {
  testWidgets('banner plays and stops audio, shows failures', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final audio = _FakeAudio();
    final controller = AdhanPlaybackController(backend: audio);
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
            body: NextPrayerBanner(
      onOpenPrayerTimes: () {},
      playbackController: controller,
    ))));
    await tester.tap(find.text('استمع للأذان'));
    await tester.pump();
    expect(audio.loads, 1);
    expect(find.text('إيقاف الأذان'), findsOneWidget);
    await tester.tap(find.text('إيقاف الأذان'));
    await tester.pump();
    expect(audio.stops, 1);
    expect(find.text('استمع للأذان'), findsOneWidget);
    audio.failure = true;
    await tester.tap(find.text('استمع للأذان'));
    await tester.pump();
    expect(find.textContaining('تعذّر تشغيل الأذان'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    controller.dispose();
  });
}
