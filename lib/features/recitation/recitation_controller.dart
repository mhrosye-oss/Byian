import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

import '../quran/models/ayah.dart';
import '../quran/services/quran_service.dart';
import '../scoring/models/score_result.dart';
import '../scoring/scoring_service.dart';

enum RecitationState { idle, playing, recording, processing, scored }

class RecitationData {
  final RecitationState state;
  final Ayah? ayah;
  final ScoreResult? result;
  final Duration recordingDuration;
  final String? error;
  /// Index within [ayah.words], or -1 when timing data is unavailable/inactive.
  final int activeWordIndex;

  const RecitationData({
    this.state = RecitationState.idle,
    this.ayah,
    this.result,
    this.recordingDuration = Duration.zero,
    this.error,
    this.activeWordIndex = -1,
  });

  RecitationData copyWith({
    RecitationState? state,
    Ayah? ayah,
    ScoreResult? result,
    Duration? recordingDuration,
    String? error,
    int? activeWordIndex,
  }) {
    return RecitationData(
      state: state ?? this.state,
      ayah: ayah ?? this.ayah,
      result: result ?? this.result,
      recordingDuration: recordingDuration ?? this.recordingDuration,
      error: error,
      activeWordIndex: activeWordIndex ?? this.activeWordIndex,
    );
  }
}

class RecitationController extends StateNotifier<RecitationData> {
  final AudioPlayer _player = AudioPlayer();
  final AudioRecorder _recorder = AudioRecorder();
  final ScoringService _scorer = ScoringService();
  final QuranService _quranService = QuranService();
  late final StreamSubscription<Duration> _positionSubscription;
  late final StreamSubscription<PlayerState> _playerStateSubscription;
  Timer? _recordingTimer;
  String? _currentRecordingPath;

  RecitationController() : super(const RecitationData()) {
    _positionSubscription = _player.positionStream.listen(_updateActiveWord);
    _playerStateSubscription = _player.playerStateStream.listen((playerState) {
      if (playerState.processingState == ProcessingState.completed && mounted) {
        state = state.copyWith(
          state: RecitationState.idle,
          activeWordIndex: -1,
        );
      }
    });
  }

  void loadAyah(Ayah ayah) {
    state = RecitationData(ayah: ayah);
    unawaited(_prepareAyah(ayah));
  }

  Future<void> _prepareAyah(Ayah requestedAyah) async {
    try {
      await _quranService.init();
      var ayah = requestedAyah;
      if (ayah.words.isEmpty) {
        final surahAyahs = await _quranService.getAyahs(ayah.surahNumber);
        for (final candidate in surahAyahs) {
          if (candidate.ayahNumber == ayah.ayahNumber) {
            ayah = candidate;
            break;
          }
        }
      }
      if (ayah.words.isNotEmpty) {
        ayah = await _quranService.attachWordTimings(ayah);
      }
      if (mounted && state.ayah?.verseKey == requestedAyah.verseKey) {
        state = state.copyWith(ayah: ayah, activeWordIndex: -1);
      }
    } catch (_) {
      // Playback remains available when an optional cache/timing service fails.
    }
  }

  void _updateActiveWord(Duration position) {
    if (!mounted || state.state != RecitationState.playing) return;
    final words = state.ayah?.words ?? const <Word>[];
    final milliseconds = position.inMilliseconds;
    var activeIndex = -1;
    for (var index = 0; index < words.length; index++) {
      final word = words[index];
      final start = word.startMs;
      final end = word.endMs;
      if (start != null && end != null && milliseconds >= start && milliseconds < end) {
        activeIndex = index;
        break;
      }
    }
    if (activeIndex != state.activeWordIndex) {
      state = state.copyWith(activeWordIndex: activeIndex);
    }
  }

  Future<void> listen() async {
    final ayah = state.ayah;
    if (ayah == null) return;
    if (state.state == RecitationState.playing) {
      await _player.stop();
      state = state.copyWith(
        state: RecitationState.idle,
        activeWordIndex: -1,
      );
      return;
    }
    try {
      state = state.copyWith(
        state: RecitationState.playing,
        activeWordIndex: -1,
        error: null,
      );
      await _player.setUrl(ayah.audioUrl);
      await _player.play();
    } catch (error) {
      state = state.copyWith(
        state: RecitationState.idle,
        activeWordIndex: -1,
        error: 'Audio error: $error',
      );
    }
  }

  Future<void> startRecording() async {
    if (state.state != RecitationState.idle) return;
    final hasPermission = await _recorder.hasPermission();
    if (!hasPermission) {
      state = state.copyWith(error: 'Microphone permission denied');
      return;
    }
    final directory = await getTemporaryDirectory();
    _currentRecordingPath =
        '${directory.path}/recitation_${DateTime.now().millisecondsSinceEpoch}.m4a';

    await _recorder.start(
      const RecordConfig(encoder: AudioEncoder.aacLc, bitRate: 128000),
      path: _currentRecordingPath!,
    );

    state = state.copyWith(
      state: RecitationState.recording,
      recordingDuration: Duration.zero,
    );

    _recordingTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        state = state.copyWith(
          recordingDuration:
              state.recordingDuration + const Duration(seconds: 1),
        );
      }
    });
  }

  Future<void> stopRecording() async {
    if (state.state != RecitationState.recording) return;
    _recordingTimer?.cancel();

    await _recorder.stop();
    state = state.copyWith(state: RecitationState.processing);

    if (state.ayah != null && _currentRecordingPath != null) {
      try {
        final result = await _scorer.scoreRecording(
          audioPath: _currentRecordingPath!,
          ayah: state.ayah!,
        );
        state = state.copyWith(state: RecitationState.scored, result: result);
        await _saveSession(result);
      } catch (error) {
        state = state.copyWith(
          state: RecitationState.idle,
          error: 'Scoring failed: $error',
        );
      }
    }
  }

  Future<void> _saveSession(ScoreResult result) async {
    try {
      if (!Hive.isBoxOpen('sessions')) {
        await Hive.openBox('sessions');
      }
      final box = Hive.box('sessions');
      await box.add({
        'surah': result.surahNumber,
        'ayah': result.ayahNumber,
        'overall': result.overall,
        'wordAccuracy': result.wordAccuracy,
        'letterAccuracy': result.letterAccuracy,
        'tajweed': result.tajweed,
        'fluency': result.fluency,
        'timestamp': DateTime.now().toIso8601String(),
      });
    } catch (_) {
      // Non-fatal: ignore Hive errors.
    }
  }

  void retry() {
    state = RecitationData(ayah: state.ayah);
  }

  @override
  void dispose() {
    _recordingTimer?.cancel();
    unawaited(_positionSubscription.cancel());
    unawaited(_playerStateSubscription.cancel());
    unawaited(_player.dispose());
    unawaited(_recorder.dispose());
    super.dispose();
  }
}

final recitationProvider =
    StateNotifierProvider.autoDispose<RecitationController, RecitationData>(
  (ref) => RecitationController(),
);
