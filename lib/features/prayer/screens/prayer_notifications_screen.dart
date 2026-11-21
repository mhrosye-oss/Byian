import 'package:flutter/material.dart';
import '../../../core/theme/colors.dart';
import '../../../core/notification/notification_service.dart';

/// صفحة إشعارات مواقيت الصلاة المخصصة
/// تتيح تفعيل الأذان والتنبيهات المسبقة لكل صلاة واختبار الإشعارات
class PrayerNotificationsScreen extends StatefulWidget {
  const PrayerNotificationsScreen({super.key});

  @override
  State<PrayerNotificationsScreen> createState() => _PrayerNotificationsScreenState();
}

class _PrayerNotificationsScreenState extends State<PrayerNotificationsScreen> {
  bool _allPrayersEnabled = true;
  bool _prePrayerReminder = true;
  bool _playAzanSound = true;

  final Map<String, bool> _prayerToggles = {
    'الفجر': true,
    'الظهر': true,
    'العصر': true,
    'المغرب': true,
    'العشاء': true,
  };

  bool _isTesting = false;

  Future<void> _testPrayerNotification() async {
    setState(() => _isTesting = true);
    try {
      await NotificationService().showSystemNotification(
        id: 1001,
        title: '🕌 حان الآن وقت أذان المغرب',
        body: 'الله أكبر الله أكبر.. حيّ على الصلاة حيّ على الفلاح',
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تم إرسال إشعار تجريبي لمواقيت الصلاة بنجاح'),
          backgroundColor: ItqanColors.emerald,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('تعذر إرسال الإشعار: $e'),
          backgroundColor: ItqanColors.roseGold,
        ),
      );
    } finally {
      if (mounted) setState(() => _isTesting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: ItqanColors.cream,
        appBar: AppBar(
          backgroundColor: const Color(0xFF064E3B),
          foregroundColor: Colors.white,
          elevation: 0,
          title: const Row(
            children: [
              Icon(Icons.access_alarms_rounded, size: 24, color: Color(0xFFFBBF24)),
              SizedBox(width: 10),
              Text(
                'إشعارات مواقيت الصلاة',
                style: TextStyle(
                  fontFamily: 'Tajawal',
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        body: ListView(
          padding: const EdgeInsets.all(18),
          children: [
            // بطاقة التنبيه العام
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFE5E7EB)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  SwitchListTile.adaptive(
                    value: _allPrayersEnabled,
                    activeTrackColor: const Color(0xFF064E3B),
                    title: const Text(
                      'تفعيل تنبيهات الصلاة',
                      style: TextStyle(
                        fontFamily: 'Tajawal',
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    subtitle: const Text(
                      'تشغيل التنبيهات والأذان عند حلول وقت الصلاة',
                      style: TextStyle(fontFamily: 'Tajawal', fontSize: 13),
                    ),
                    onChanged: (val) {
                      setState(() {
                        _allPrayersEnabled = val;
                      });
                    },
                  ),
                  const Divider(),
                  SwitchListTile.adaptive(
                    value: _prePrayerReminder,
                    activeTrackColor: const Color(0xFF064E3B),
                    title: const Text(
                      'تذكير مسبق بـ 15 دقيقة',
                      style: TextStyle(
                        fontFamily: 'Tajawal',
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    subtitle: const Text(
                      'إشعار خفيف للاستعداد والوضوء قبل دخول الوقت',
                      style: TextStyle(fontFamily: 'Tajawal', fontSize: 12),
                    ),
                    onChanged: (val) {
                      setState(() {
                        _prePrayerReminder = val;
                      });
                    },
                  ),
                  const Divider(),
                  SwitchListTile.adaptive(
                    value: _playAzanSound,
                    activeTrackColor: const Color(0xFF064E3B),
                    title: const Text(
                      'تشغيل صوت الأذان',
                      style: TextStyle(
                        fontFamily: 'Tajawal',
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    subtitle: const Text(
                      'سماع صوت الأذان كاملاً عند دخول وقت الفريضة',
                      style: TextStyle(fontFamily: 'Tajawal', fontSize: 12),
                    ),
                    onChanged: (val) {
                      setState(() {
                        _playAzanSound = val;
                      });
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // تخصيص الصلوات الفردية
            const Text(
              'تخصيص الصلوات الخمس',
              style: TextStyle(
                fontFamily: 'Tajawal',
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: ItqanColors.ink,
              ),
            ),
            const SizedBox(height: 10),

            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFE5E7EB)),
              ),
              child: Column(
                children: _prayerToggles.entries.map((entry) {
                  return Column(
                    children: [
                      SwitchListTile.adaptive(
                        value: entry.value && _allPrayersEnabled,
                        activeTrackColor: const Color(0xFF064E3B),
                        title: Text(
                          'صلاة ${entry.key}',
                          style: const TextStyle(
                            fontFamily: 'Tajawal',
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                          ),
                        ),
                        secondary: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF064E3B).withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.nights_stay_rounded,
                            color: Color(0xFF064E3B),
                            size: 20,
                          ),
                        ),
                        onChanged: _allPrayersEnabled
                            ? (val) {
                                setState(() {
                                  _prayerToggles[entry.key] = val;
                                });
                              }
                            : null,
                      ),
                      if (entry.key != 'العشاء') const Divider(height: 1),
                    ],
                  );
                }).toList(),
              ),
            ),

            const SizedBox(height: 24),

            // زر اختبار الإشعار
            SizedBox(
              height: 52,
              child: ElevatedButton.icon(
                onPressed: _isTesting ? null : _testPrayerNotification,
                icon: const Icon(Icons.notifications_active_rounded),
                label: Text(
                  _isTesting ? 'جارٍ الإرسال...' : 'تجربة إشعار الأذان الآن',
                  style: const TextStyle(
                    fontFamily: 'Tajawal',
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF064E3B),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
