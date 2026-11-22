import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:itqan/features/quran_teacher/data/audio/engine/no_op_asr_engine.dart';

void main() {
  group('NoOpAsrEngine', () {
    test('does not claim recognition of a placeholder file', () async {
      final directory = await Directory.systemTemp.createTemp('asr_no_op_');
      addTearDown(() => directory.delete(recursive: true));
      final recording = File('${directory.path}/recording.m4a');
      // These bytes are not audio: NoOp must never claim to transcribe them.
      await recording.writeAsBytes([1, 2, 3]);

      final result = await NoOpAsrEngine().recognize(recording.path);

      expect(result.engineUnavailable, isTrue);
      expect(result.transcript, isNull);
      expect(result.expectedText, isNull);
    });

    test('does not fabricate a transcript for a missing file', () async {
      final directory = await Directory.systemTemp.createTemp('asr_missing_');
      addTearDown(() => directory.delete(recursive: true));

      final result =
          await NoOpAsrEngine().recognize('${directory.path}/missing.m4a');

      expect(result.engineUnavailable, isTrue);
      expect(result.transcript, isNull);
    });
  });
}
