import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:itqan/features/prayer/services/adhan_playback_controller.dart';

class FakeAudio implements AdhanAudioBackend {
  final events = StreamController<bool>.broadcast(sync: true);
  Completer<void>? playFinished;
  Completer<void>? loadFinished;
  int loads = 0;
  int plays = 0;
  int stops = 0;
  bool disposed = false;
  bool failLoad = false;
  bool failPlay = false;

  @override
  Stream<bool> get playing => events.stream;
  @override
  Future<void> load() async {
    loads++;
    if (failLoad) throw StateError('failed to load');
    if (loadFinished != null) await loadFinished!.future;
  }

  @override
  Future<void> play() async {
    plays++;
    if (failPlay) throw StateError('failed to play');
    events.add(true);
    playFinished = Completer<void>();
    await playFinished!.future;
  }

  @override
  Future<void> stop() async {
    stops++;
    events.add(false);
    if (playFinished != null && !playFinished!.isCompleted) {
      playFinished!.complete();
    }
  }

  void finish() {
    events.add(false);
    if (playFinished != null && !playFinished!.isCompleted) {
      playFinished!.complete();
    }
  }

  @override
  Future<void> dispose() async {
    disposed = true;
    if (playFinished != null && !playFinished!.isCompleted) {
      playFinished!.complete();
    }
    await events.close();
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('bundled asset is present and contains actual audio bytes', () async {
    final audio = await rootBundle.load(adhanAssetPath);
    expect(audio.lengthInBytes, greaterThan(300000));
  });

  test('play is stoppable while its future is still pending and can replay',
      () async {
    final backend = FakeAudio();
    final controller = AdhanPlaybackController(backend: backend);
    await controller.toggle();
    expect(controller.isPlaying, isTrue);
    expect(backend.loads, 1);
    expect(backend.plays, 1);
    expect(backend.playFinished!.isCompleted, isFalse);
    await controller.toggle();
    expect(backend.stops, 1);
    expect(controller.isPlaying, isFalse);
    await controller.toggle();
    expect(backend.loads, 2);
    backend.finish();
    expect(controller.isPlaying, isFalse);
    controller.dispose();
    expect(backend.disposed, isTrue);
  });

  test('load and asynchronous playback failures leave the control stopped',
      () async {
    final backend = FakeAudio()..failLoad = true;
    final controller = AdhanPlaybackController(backend: backend);
    await controller.toggle();
    expect(controller.isPlaying, isFalse);
    expect(controller.isLoading, isFalse);
    expect(controller.error, isNotNull);
    backend.failLoad = false;
    backend.failPlay = true;
    await controller.toggle();
    await Future<void>.delayed(Duration.zero);
    expect(controller.isPlaying, isFalse);
    expect(controller.error, isNotNull);
    controller.dispose();
  });

  test('disposing during load does not start playback', () async {
    final backend = FakeAudio()..loadFinished = Completer<void>();
    final controller = AdhanPlaybackController(backend: backend);
    final started = controller.toggle();
    expect(controller.isLoading, isTrue);
    controller.dispose();
    backend.loadFinished!.complete();
    await started;
    expect(backend.plays, 0);
    expect(backend.disposed, isTrue);
  });
}
