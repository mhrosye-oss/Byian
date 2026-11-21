import 'package:shared_preferences/shared_preferences.dart';

/// واجهة موحّدة لقراءة/كتابة إعدادات الأذان من/إلى shared_preferences.
///
/// المفاتيح:
/// - adhan_enabled          (bool)   التفعيل العام
/// - adhan_fajr_enabled     (bool)   تفكيك لكل صلاة
/// - adhan_dhuhr_enabled    (bool)
/// - adhan_asr_enabled      (bool)
/// - adhan_maghrib_enabled  (bool)
/// - adhan_isha_enabled     (bool)
/// - adhan_sound            (String) 'makkah' | 'madinah'
/// - adhan_lat / adhan_lng  (double) إحداثيات الموقع (افتراضي: مكة المكرمة)
/// - adhan_last_played      (String) منع التكرار: "fajr:2026-11-21"
class AdhanPreferences {
  static const String keyEnabled = 'adhan_enabled';
  static const String keySound = 'adhan_sound';
  static const String keyLat = 'adhan_lat';
  static const String keyLng = 'adhan_lng';
  static const String keyLastPlayed = 'adhan_last_played';

  /// الصلوات الخمس بالترتيب (بدون الشروق).
  static const List<String> prayers = [
    'fajr',
    'dhuhr',
    'asr',
    'maghrib',
    'isha',
  ];

  static String prayerEnabledKey(String prayer) => 'adhan_${prayer}_enabled';

  // القيم الافتراضية
  static const bool defaultEnabled = true;
  static const String defaultSound = 'makkah';
  static const double defaultLat = 21.422487; // مكة المكرمة
  static const double defaultLng = 39.826206;

  final SharedPreferences _prefs;

  AdhanPreferences(this._prefs);

  // ===== التفعيل العام =====
  bool get enabled => _prefs.getBool(keyEnabled) ?? defaultEnabled;
  Future<void> setEnabled(bool value) => _prefs.setBool(keyEnabled, value);

  // ===== تفعيل كل صلاة =====
  bool isPrayerEnabled(String prayer) =>
      _prefs.getBool(prayerEnabledKey(prayer)) ?? true;

  Future<void> setPrayerEnabled(String prayer, bool value) =>
      _prefs.setBool(prayerEnabledKey(prayer), value);

  // ===== المؤذن =====
  String get sound => _prefs.getString(keySound) ?? defaultSound;

  bool get isMadinah => sound == 'madinah';

  Future<void> setSound(String value) => _prefs.setString(keySound, value);

  // ===== الموقع =====
  double get lat => _prefs.getDouble(keyLat) ?? defaultLat;
  double get lng => _prefs.getDouble(keyLng) ?? defaultLng;

  Future<void> setLocation(double lat, double lng) async {
    await _prefs.setDouble(keyLat, lat);
    await _prefs.setDouble(keyLng, lng);
  }

  // ===== منع التكرار (يوم/صلاة) =====
  String? get lastPlayed => _prefs.getString(keyLastPlayed);

  Future<void> setLastPlayed(String value) =>
      _prefs.setString(keyLastPlayed, value);
}
