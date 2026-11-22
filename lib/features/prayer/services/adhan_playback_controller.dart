import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';

/// The bundled CC0 recording is a 27-second excerpt, not a complete adhan.
const adhanAssetPath = 'assets/audio/adhan.mp3';

abstract class AdhanAudioBackend {
  Stream<bool> get playing;
  Future<void> load();
  Future<void> play();
  Future<void> stop();
  Future<void> dispose();
}

class JustAudioAdhanBackend implements AdhanAudioBackend {
  JustAudioAdhanBackend() : _player = AudioPlayer();
  final AudioPlayer _player;

  @override
  Stream<bool> get playing => _player.playerStateStream
      .map(
        (state) =>
            state.playing && state.processingState != ProcessingState.completed,
      )
      .distinct();

  @override
  Future<void> load() async {
    await _player.setAsset(adhanAssetPath);
  }

  // just_audio's play future completes when playback ends or is stopped.
  @override
  Future<void> play() => _player.play();

  @override
  Future<void> stop() => _player.stop();

  @override
  Future<void> dispose() => _player.dispose();
}

class AdhanPlaybackController extends ChangeNotifier {
  AdhanPlaybackController({AdhanAudioBackend? backend})
      : _backend = backend ?? JustAudioAdhanBackend() {
    _subscription = _backend.playing.listen((value) {
      if (_disposed) return;
      isPlaying = value;
      notifyListeners();
    }, onError: (Object error) => _report(error));
  }

  final AdhanAudioBackend _backend;
  late final StreamSubscription<bool> _subscription;
  bool isPlaying = false;
  bool isLoading = false;
  String? error;
  bool _disposed = false;

  Future<void> toggle() async {
    if (_disposed || isLoading) return;
    error = null;
    if (isPlaying) {
      try {
        await _backend.stop();
        if (!_disposed) {
          isPlaying = false;
          notifyListeners();
        }
      } catch (e) {
        _report(e);
      }
      return;
    }
    isLoading = true;
    notifyListeners();
    try {
      await _backend.load();
      if (_disposed) return;
      // Do not await play: that future lasts until playback is finished and
      // would make the stop control unavailable.
      isPlaying = true;
      isLoading = false;
      notifyListeners();
      unawaited(_backend.play().catchError((Object e) => _report(e)));
    } catch (e) {
      _report(e);
    }
  }

  void _report(Object failure) {
    if (_disposed) return;
    isPlaying = false;
    isLoading = false;
    error = 'تعذّر تشغيل الأذان. تحقق من إعدادات الصوت وحاول مجددًا.';
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    unawaited(_subscription.cancel());
    unawaited(_backend.dispose());
    super.dispose();
  }
}
