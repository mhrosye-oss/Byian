import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import 'package:itqan/features/quran/models/ayah.dart';

/// خدمة تشغيل الصوت لمعلّم القرآن
/// تدعم تشغيل تلاوة الآيات، تشغيل التسجيلات الصوتية المحلية، التحكم في التكرار والإيقاف المؤقت.
class AudioPlayerService {
  final AudioPlayer _player = AudioPlayer();

  AudioPlayer get player => _player;

  /// تشغيل تلاوة آية قرآنية
  Future<void> playAyah(Ayah ayah) async {
    try {
      await _player.stop();
      final s = ayah.surahNumber.toString().padLeft(3, '0');
      final a = ayah.ayahNumber.toString().padLeft(3, '0');
      final uri = 'https://everyayah.com/data/Alafasy_128kbps/$s$a.mp3';

      await _player.setUrl(uri);
      await _player.play();
    } catch (e) {
      debugPrint('AudioPlayerService error: $e');
      rethrow;
    }
  }

  /// تشغيل ملف تسجيل صوتي محلي (للاستماع للتسميع المسجل)
  Future<void> playFilePath(String filePath) async {
    try {
      await _player.stop();
      if (!File(filePath).existsSync()) {
        throw Exception('ملف الصوت غير موجود');
      }
      await _player.setFilePath(filePath);
      await _player.play();
    } catch (e) {
      debugPrint('AudioPlayerService file playback error: $e');
      rethrow;
    }
  }

  /// إيقاف مؤقت
  Future<void> pause() async {
    await _player.pause();
  }

  /// استئناف التشغيل
  Future<void> resume() async {
    await _player.play();
  }

  /// إيقاف التشغيل كلياً
  Future<void> stop() async {
    await _player.stop();
  }

  /// ضبط التكرار
  Future<void> setLoopMode(LoopMode loopMode) async {
    await _player.setLoopMode(loopMode);
  }

  /// تنظيف الموارد
  Future<void> dispose() async {
    await _player.dispose();
  }

  /// تدفق حالة المشغل
  Stream<PlayerState> get playerStateStream => _player.playerStateStream;

  /// تدفق موضع التشغيل
  Stream<Duration> get positionStream => _player.positionStream;

  /// تدفق مدة الصوت الكلية
  Stream<Duration?> get durationStream => _player.durationStream;

  /// هل المشغل يعمل حالياً؟
  bool get isPlaying => _player.playing;
}
