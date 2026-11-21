import 'package:hive_flutter/hive_flutter.dart';

@HiveType(typeId: 0)
class RecitationResult extends HiveObject {
  @HiveField(0)
  final bool engineUnavailable;

  @HiveField(1)
  final String? transcript;

  @HiveField(2)
  final String? expectedText;

  RecitationResult({required this.engineUnavailable, this.transcript, this.expectedText});
}

class RecitationResultAdapter extends TypeAdapter<RecitationResult> {
  @override
  final int typeId = 0;

  @override
  RecitationResult read(BinaryReader reader) {
    final engineUnavailable = reader.readBool();
    final hasTranscript = reader.readBool();
    final transcript = hasTranscript ? reader.readString() : null;
    final hasExpected = reader.readBool();
    final expected = hasExpected ? reader.readString() : null;
    return RecitationResult(
      engineUnavailable: engineUnavailable,
      transcript: transcript,
      expectedText: expected,
    );
  }

  @override
  void write(BinaryWriter writer, RecitationResult obj) {
    writer.writeBool(obj.engineUnavailable);
    writer.writeBool(obj.transcript != null);
    if (obj.transcript != null) writer.writeString(obj.transcript!);
    writer.writeBool(obj.expectedText != null);
    if (obj.expectedText != null) writer.writeString(obj.expectedText!);
  }
}
