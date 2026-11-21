import 'package:adhan/adhan.dart' as adhan;
import 'package:shared_preferences/shared_preferences.dart';

import 'adhan_audio_handler.dart';
import 'adhan_session_config.dart';

/// Singleton مسؤول عن:
/// 1. حساب مواقيت الصلاة لليوم بحزمة adhan (نفس حزمة المشروع).
/// 2. قراءة الإعدادات من shared_preferences.
/// 3. تشغيل الأذان عند دخول وقت صلاة مفعّلة (نافذة ±90 ثانية) مع منع التكرار.
/// 4. التشغيل اليدوي عبر playNow() للمعاينة.
class AdhanScheduler {
  AdhanScheduler._();

  static AdhanScheduler? _instance;
  static AdhanScheduler get instance => _instance ??= AdhanScheduler._();

  AdhanAudioHandler? _handler;
  AdhanPreferences? _prefs;
  bool _initialized = false;

  /// يُستدعى مرة واحدة من main.dart بعد AudioService.init.
  /// الحارس يمنع إعادة التهيئة عند Full Restart (R) فلا يحدث PlatformException.
  void init(AdhanAudioHandler handler) {
    if (_initialized) return;
    _initialized = true;
    _handler = handler;
    // ضبط جلسة الصوت مرة واحدة (usage=alarm على أندرويد / playback على iOS).
    AdhanSessionConfig.configure();
  }

  bool get isInitialized => _initialized && _handler != null;

  Future<AdhanPreferences> _loadPrefs() async {
    return _prefs ??= AdhanPreferences(await SharedPreferences.getInstance());
  }

  // ===== أسماء الصلوات بالعربية =====
  static const Map<String, String> prayerNamesAr = {
    'fajr': 'الفجر',
    'dhuhr': 'الظهر',
    'asr': 'العصر',
    'maghrib': 'المغرب',
    'isha': 'العشاء',
  };

  /// مسار ملف الأذان حسب المؤذن المختار.
  String assetPathFor(String sound) => sound == 'madinah'
      ? 'assets/audio/adhan_madinah.mp3'
      : 'assets/audio/adhan_makkah.mp3';

  // ===== حساب مواقيت اليوم =====

  /// مواقيت الصلوات الخمس لليوم كـ DateTime محلية.
  Map<String, DateTime> todayTimes(AdhanPreferences prefs) {
    final coordinates = adhan.Coordinates(prefs.lat, prefs.lng);
    final params = adhan.CalculationMethod.umm_al_qura;
    final times = adhan.PrayerTimes(
      coordinates,
      adhan.DateComponents.from(DateTime.now()),
      params,
    );
    // حزمة adhan تعيد القيم بتوقيت UTC — نحولها للتوقيت المحلي.
    DateTime toLocal(DateTime? t) => (t ?? DateTime.now()).toLocal();
    return {
      'fajr': toLocal(times.fajr),
      'dhuhr': toLocal(times.dhuhr),
      'asr': toLocal(times.asr),
      'maghrib': toLocal(times.maghrib),
      'isha': toLocal(times.isha),
    };
  }

  // ===== الفحص الدوري (كل دقيقة من الشاشة الرئيسية) =====

  /// يفحص هل دخل وقت صلاة مفعّلة خلال آخر 90 ثانية، فإن كان كذلك يشغّل الأذان.
  /// يُمنع التكرار بحفظ "صلاة:تاريخ" في shared_preferences.
  Future<void> checkAndPlay({double? lat, double? lng}) async {
    if (!isInitialized) return;

    final prefs = await _loadPrefs();
    if (!prefs.enabled) return;

    if (lat != null && lng != null && (lat != prefs.lat || lng != prefs.lng)) {
      await prefs.setLocation(lat, lng);
    }

    final times = todayTimes(prefs);
    final now = DateTime.now();
    final dateKey =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    final nowSeconds = now.hour * 3600 + now.minute * 60 + now.second;

    for (final entry in times.entries) {
      final prayer = entry.key;
      if (!AdhanPreferences.prayers.contains(prayer)) continue;
      if (!prefs.isPrayerEnabled(prayer)) continue;

      final t = entry.value;
      final tSeconds = t.hour * 3600 + t.minute * 60 + t.second;
      final diff = nowSeconds - tSeconds; // ثوانٍ منذ دخول الوقت

      // نافذة ±90 ثانية من دخول الوقت.
      if (diff >= -90 && diff <= 90) {
        final playedKey = '$prayer:$dateKey';
        if (prefs.lastPlayed == playedKey) continue; // منع التكرار
        await prefs.setLastPlayed(playedKey);
        await play(prayer);
        return; // صلاة واحدة في كل مرة
      }
    }
  }

  // ===== التشغيل =====

  /// تشغيل أذان صلاة محددة (داخلي).
  Future<void> play(String prayer) async {
    if (!isInitialized) return;
    final prefs = await _loadPrefs();
    await AdhanSessionConfig.configure();
    await _handler!.playAdhanFromAsset(
      assetPathFor(prefs.sound),
      prayerNamesAr[prayer] ?? prayer,
    );
  }

  /// زر "معاينة الأذان" في شاشة الإعدادات: تشغيل فوري بغض النظر عن التفعيل.
  Future<void> playNow({String? sound}) async {
    if (!isInitialized) return;
    final prefs = await _loadPrefs();
    await AdhanSessionConfig.configure();
    await _handler!.playAdhanFromAsset(
      assetPathFor(sound ?? prefs.sound),
      'معاينة',
    );
  }

  /// إيقاف التشغيل (من إشعار النظام).
  Future<void> stop() async {
    if (!isInitialized) return;
    await _handler!.stop();
  }
}
