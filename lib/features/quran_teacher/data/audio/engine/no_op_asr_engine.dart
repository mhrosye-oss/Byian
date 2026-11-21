import 'asr_engine.dart';
import '../../../domain/models/recitation_result.dart';

/// محرك ASR بدائي لا يفعل شيء؛ يعيد نتيجة تفيد بعدم توفر المحرك.
class NoOpAsrEngine implements AsrEngine {
  @override
  Future<RecitationResult> recognize(String audioPath) async {
    // لا يتم تحليل الملف؛ فقط إرجاع علامة عدم توفر المحرك.
    return RecitationResult(engineUnavailable: true);
  }
}

