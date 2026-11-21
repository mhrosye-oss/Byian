import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';

/// معالج صوت الأذان: يدير التشغيل عبر just_audio ويبث الحالة لـ audio_service
/// لعرض إشعار تحكم (إيقاف/إيقاف مؤقت) في شريط النظام.
class AdhanAudioHandler extends BaseAudioHandler with SeekHandler {
  final AudioPlayer _player = AudioPlayer();

  AdhanAudioHandler() {
    _player.playerStateStream.listen(_onPlayerStateChanged);
  }

  void _onPlayerStateChanged(PlayerState state) {
    final playing = state.playing;
    final AudioProcessingState aps;
    switch (state.processingState) {
      case ProcessingState.idle:
        aps = AudioProcessingState.idle;
        break;
      case ProcessingState.loading:
      case ProcessingState.buffering:
        aps = AudioProcessingState.buffering;
        break;
      case ProcessingState.ready:
        aps = AudioProcessingState.ready;
        break;
      case ProcessingState.completed:
        aps = AudioProcessingState.idle;
        break;
    }

    playbackState.add(playbackState.value.copyWith(
      controls: playing
          ? [MediaControl.pause, MediaControl.stop]
          : [MediaControl.play, MediaControl.stop],
      systemActions: const {MediaAction.stop},
      processingState: aps,
      playing: playing,
    ));

    // عند انتهاء الأذان: إيقاف الخدمة وإخفاء الإشعار.
    if (state.processingState == ProcessingState.completed) {
      stop();
    }
  }

  /// تشغيل ملف أذان من الأصول.
  Future<void> playAdhanFromAsset(String assetPath, String prayerName) async {
    // إيقاف أي تشغيل سابق أولًا.
    await _player.stop();

    mediaItem.add(MediaItem(
      id: assetPath,
      album: 'الأذان',
      title: 'الأذان - $prayerName',
      artist: 'الأذان الصوتي',
    ));

    await _player.setAsset(assetPath);
    await _player.play();
  }

  @override
  Future<void> play() async => _player.play();

  @override
  Future<void> pause() async => _player.pause();

  @override
  Future<void> stop() async {
    await _player.stop();
    await _player.seek(Duration.zero);
    await super.stop();
  }

  @override
  Future<void> onTaskRemoved() async {
    // إزالة التطبيق من قائمة المهام: إيقاف الصوت.
    await stop();
  }
}
