import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:itqan/app.dart';
import 'package:itqan/features/settings/settings_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory hiveDirectory;

  setUp(() async {
    hiveDirectory = await Directory.systemTemp.createTemp('itqan_settings_ui_');
    Hive.init(hiveDirectory.path);
    await Hive.openBox('settings');
  });

  tearDown(() async {
    await Hive.close();
    if (await hiveDirectory.exists()) {
      await hiveDirectory.delete(recursive: true);
    }
  });

  testWidgets('settings screen renders Arabic labels', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('ar'),
        supportedLocales: const [Locale('ar')],
        localizationsDelegates: itqanLocalizationsDelegates,
        home: const ProviderScope(child: SettingsScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('الإعدادات'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
