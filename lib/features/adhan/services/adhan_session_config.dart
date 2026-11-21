import 'package:audio_session/audio_session.dart';

/// يضبط جلسة الصوت مرة واحدة فقط:
/// - iOS: فئة playback مع duckOthers (يخفض صوت التطبيقات الأخرى أثناء الأذان).
/// - Android: usage=alarm حتى يتجاوز الأذان الوضع الصامت.
///
/// ملاحظة: just_audio يتعامل مع المقاطعات (مكالمة/مشغّل موسيقى) تلقائيًا
/// عبر audio_session، فلا حاجة للاستماع اليدوي لـ interruptionEventStream هنا.
class AdhanSessionConfig {
  AdhanSessionConfig._();

  static bool _configured = false;

  static Future<void> configure() async {
    if (_configured) return;
    _configured = true;

    final session = await AudioSession.instance;
    await session.configure(
      AudioSessionConfiguration(
        avAudioSessionCategory: AVAudioSessionCategory.playback,
        avAudioSessionCategoryOptions: AVAudioSessionCategoryOptions.duckOthers,
        avAudioSessionMode: AVAudioSessionMode.spokenAudio,
        avAudioSessionRouteSharingPolicy:
            AVAudioSessionRouteSharingPolicy.defaultPolicy,
        avAudioSessionSetActiveOptions: AVAudioSessionSetActiveOptions.none,
        androidAudioAttributes: const AndroidAudioAttributes(
          contentType: AndroidAudioContentType.speech,
          flags: AndroidAudioFlags.none,
          // usage=alarm: يشغّل الصوت حتى في الوضع الصامت على أندرويد.
          usage: AndroidAudioUsage.alarm,
        ),
        androidAudioFocusGainType: AndroidAudioFocusGainType.gain,
        androidWillPauseWhenDucked: false,
      ),
    );
  }
}
