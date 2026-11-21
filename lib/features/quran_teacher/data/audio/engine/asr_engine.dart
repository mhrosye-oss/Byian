import '../../../domain/models/recitation_result.dart';

/// واجهة محرك التعرف على الكلام (ASR).
abstract class AsrEngine {
  /// يمرر مسار ملف الصوت ويعيد نتيجة التحليل.
  /// إذا لم يتوفر محرك فعلي، يمكن إرجاع كائن RecitationResult مع
  /// `engineUnavailable = true`.
  Future<RecitationResult> recognize(String audioPath);
}

