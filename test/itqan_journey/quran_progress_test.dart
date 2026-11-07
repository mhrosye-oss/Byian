import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:itqan/features/itqan_journey/data/journey_content_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory directory;

  setUp(() async {
    directory = await Directory.systemTemp.createTemp('itqan-quran-progress-');
    Hive.init(directory.path);
  });

  tearDown(() async {
    await Hive.close();
    await directory.delete(recursive: true);
  });

  test('confirmed and pending pages persist as distinct states', () async {
    final repository = JourneyQuranRepository();
    await repository.markPageCompleted(7);
    await repository.markPagePending(8, 'pending-uuid');

    expect(await repository.completedPages(), {7});
    expect(await repository.pendingPages(), {8: 'pending-uuid'});

    await Hive.close();
    Hive.init(directory.path);
    final reopened = JourneyQuranRepository();
    expect(await reopened.completedPages(), {7});
    expect(await reopened.pendingPages(), {8: 'pending-uuid'});

    await reopened.markPageCompleted(8);
    expect(await reopened.completedPages(), {7, 8});
    expect(await reopened.pendingPages(), isEmpty);
  });

  test('rejects page numbers outside the Mushaf range', () async {
    final repository = JourneyQuranRepository();
    await repository.markPageCompleted(605);
    await repository.markPagePending(0, 'invalid');

    expect(await repository.completedPages(), isEmpty);
    expect(await repository.pendingPages(), isEmpty);
  });
}
