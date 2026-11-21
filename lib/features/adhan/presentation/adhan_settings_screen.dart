import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/adhan_preferences.dart';
import '../services/adhan_scheduler.dart';

/// شاشة إعدادات الأذان الصوتي:
/// - مفتاح تفعيل عام.
/// - مفتاح لكل صلاة من الخمس.
/// - اختيار المؤذن (مكة المكرمة / المدينة المنورة).
/// - زر "معاينة الأذان".
/// أي تغيير يُحفظ فورًا في shared_preferences.
class AdhanSettingsScreen extends StatefulWidget {
  const AdhanSettingsScreen({super.key});

  @override
  State<AdhanSettingsScreen> createState() => _AdhanSettingsScreenState();
}

class _AdhanSettingsScreenState extends State<AdhanSettingsScreen> {
  static const Color primaryGreen = Color(0xFF0F4D3A);

  AdhanPreferences? _prefs;
  bool _enabled = true;
  final Map<String, bool> _prayerEnabled = {
    for (final p in AdhanPreferences.prayers) p: true,
  };
  String _sound = AdhanPreferences.defaultSound;
  bool _playingPreview = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prefs =
        AdhanPreferences(await SharedPreferences.getInstance());
    if (!mounted) return;
    setState(() {
      _prefs = prefs;
      _enabled = prefs.enabled;
      _sound = prefs.sound;
      for (final p in AdhanPreferences.prayers) {
        _prayerEnabled[p] = prefs.isPrayerEnabled(p);
      }
    });
  }

  // ===== حفظ فوري =====
  Future<void> _setEnabled(bool v) async {
    setState(() => _enabled = v);
    await _prefs?.setEnabled(v);
  }

  Future<void> _setPrayerEnabled(String prayer, bool v) async {
    setState(() => _prayerEnabled[prayer] = v);
    await _prefs?.setPrayerEnabled(prayer, v);
  }

  Future<void> _setSound(String v) async {
    setState(() => _sound = v);
    await _prefs?.setSound(v);
  }

  Future<void> _preview() async {
    setState(() => _playingPreview = true);
    try {
      await AdhanScheduler.instance.playNow(sound: _sound);
    } finally {
      if (mounted) setState(() => _playingPreview = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          iconTheme: const IconThemeData(color: primaryGreen),
          title: const Text(
            'الأذان الصوتي',
            style: TextStyle(
              color: primaryGreen,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          centerTitle: true,
        ),
        body: _prefs == null
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ===== التفعيل العام =====
                    _sectionCard(
                      child: SwitchListTile(
                        value: _enabled,
                        onChanged: _setEnabled,
                        activeColor: primaryGreen,
                        title: const Text(
                          'تفعيل الأذان',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: primaryGreen,
                          ),
                        ),
                        subtitle: const Text(
                          'تشغيل الأذان تلقائيًا عند دخول وقت الصلاة',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // ===== الصلوات الخمس =====
                    const Text(
                      'الصلوات',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: primaryGreen,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _sectionCard(
                      child: Column(
                        children: AdhanPreferences.prayers.map((prayer) {
                          return SwitchListTile(
                            value: _prayerEnabled[prayer] ?? true,
                            // تعطيل الصفوف إذا كان التفعيل العام موقفًا.
                            onChanged: _enabled
                                ? (v) => _setPrayerEnabled(prayer, v)
                                : null,
                            activeColor: primaryGreen,
                            title: Text(
                              AdhanScheduler.prayerNamesAr[prayer] ?? prayer,
                              style:
                                  const TextStyle(fontWeight: FontWeight.w600),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // ===== المؤذن =====
                    const Text(
                      'المؤذن',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: primaryGreen,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _sectionCard(
                      child: Column(
                        children: [
                          RadioListTile<String>(
                            value: 'makkah',
                            groupValue: _sound,
                            onChanged: (v) => _setSound(v ?? 'makkah'),
                            activeColor: primaryGreen,
                            title: const Text('مكة المكرمة'),
                          ),
                          RadioListTile<String>(
                            value: 'madinah',
                            groupValue: _sound,
                            onChanged: (v) => _setSound(v ?? 'makkah'),
                            activeColor: primaryGreen,
                            title: const Text('المدينة المنورة'),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // ===== زر المعاينة =====
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton.icon(
                        onPressed: _playingPreview ? null : _preview,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryGreen,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        icon: _playingPreview
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.volume_up),
                        label: const Text(
                          'معاينة الأذان',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _sectionCard({required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }
}
