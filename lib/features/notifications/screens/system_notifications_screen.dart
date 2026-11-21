import 'package:flutter/material.dart';
import '../../../core/theme/colors.dart';
import '../../../core/notification/notification_service.dart';

/// صفحة إشعارات النظام وفايربيس المخصصة
/// مخصصة لرسائل الحلقات والهمسات وإعلانات الإدارة والإشعارات السحابية (FCM)
class SystemNotificationsScreen extends StatefulWidget {
  const SystemNotificationsScreen({super.key});

  @override
  State<SystemNotificationsScreen> createState() => _SystemNotificationsScreenState();
}

class _SystemNotificationsScreenState extends State<SystemNotificationsScreen> {
  bool _circleTasksEnabled = true;
  bool _whispersEnabled = true;
  bool _generalAnnouncements = true;

  final List<Map<String, dynamic>> _mockNotifications = [
    {
      'title': '✨ تم تكليفك بورد جديد في دائرة العائلة',
      'body': 'قراءة سورة الكهف والصفحات 21-30 قبل موعد الغد.',
      'time': 'منذ 15 دقيقة',
      'type': 'task',
      'icon': Icons.task_alt_rounded,
      'color': Color(0xFF059669),
    },
    {
      'title': '💬 همسة جديدة من عبد الله',
      'body': 'تقبل الله طاعاتكم وبارك الله في جهودك بالحلقة.',
      'time': 'منذ ساعتين',
      'type': 'whisper',
      'icon': Icons.chat_bubble_outline_rounded,
      'color': Color(0xFFD97706),
    },
    {
      'title': '📢 إعلان من إدارة إتقان',
      'body': 'تم إطلاق التحديث الجديد v2.5 مع ميزة معلّم القرآن والتحسينات الجديدة.',
      'time': 'أمس',
      'type': 'announcement',
      'icon': Icons.campaign_rounded,
      'color': Color(0xFF4F46E5),
    },
  ];

  bool _isTesting = false;

  Future<void> _sendTestSystemNotification() async {
    setState(() => _isTesting = true);
    try {
      await NotificationService().showSystemNotification(
        id: 2002,
        title: '🔔 إشعار تجريبي من نظام إتقان',
        body: 'تم استقبال إشعار النظام السحابي بنجاح وتفعيل القناة المستقلة.',
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تم إرسال إشعار نظام تجريبي بنجاح عبر قناة Firebase'),
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
              Icon(Icons.campaign_rounded, size: 24, color: Color(0xFFFBBF24)),
              SizedBox(width: 10),
              Text(
                'إشعارات النظام وفايربيس',
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
            // إعدادات قنوات النظام
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
                    value: _circleTasksEnabled,
                    activeTrackColor: const Color(0xFF064E3B),
                    title: const Text(
                      'مهام الحلقات القرآنية',
                      style: TextStyle(
                        fontFamily: 'Tajawal',
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    subtitle: const Text(
                      'إشعارات المهام الموكلة وإتمام أوراد الختمة',
                      style: TextStyle(fontFamily: 'Tajawal', fontSize: 12),
                    ),
                    onChanged: (val) => setState(() => _circleTasksEnabled = val),
                  ),
                  const Divider(),
                  SwitchListTile.adaptive(
                    value: _whispersEnabled,
                    activeTrackColor: const Color(0xFF064E3B),
                    title: const Text(
                      'همسات وتشجيع الإخوة',
                      style: TextStyle(
                        fontFamily: 'Tajawal',
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    subtitle: const Text(
                      'تنبيهات فورية عند وصول رسالة أو دعاء خاص',
                      style: TextStyle(fontFamily: 'Tajawal', fontSize: 12),
                    ),
                    onChanged: (val) => setState(() => _whispersEnabled = val),
                  ),
                  const Divider(),
                  SwitchListTile.adaptive(
                    value: _generalAnnouncements,
                    activeTrackColor: const Color(0xFF064E3B),
                    title: const Text(
                      'إعلانات وتحديثات التطبيق',
                      style: TextStyle(
                        fontFamily: 'Tajawal',
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    subtitle: const Text(
                      'رسائل النظام السحابية عبر Firebase Cloud Messaging',
                      style: TextStyle(fontFamily: 'Tajawal', fontSize: 12),
                    ),
                    onChanged: (val) => setState(() => _generalAnnouncements = val),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // زر إرسال تجربة
            SizedBox(
              height: 50,
              child: OutlinedButton.icon(
                onPressed: _isTesting ? null : _sendTestSystemNotification,
                icon: const Icon(Icons.send_rounded, color: Color(0xFF064E3B)),
                label: Text(
                  _isTesting ? 'جارٍ الإرسال...' : 'إرسال إشعار سحابي تجريبي (FCM)',
                  style: const TextStyle(
                    fontFamily: 'Tajawal',
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF064E3B),
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFF064E3B), width: 1.5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 24),

            // صندوق الوارد للرسائل
            const Text(
              'صندوق الرسائل والتنبيهات',
              style: TextStyle(
                fontFamily: 'Tajawal',
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: ItqanColors.ink,
              ),
            ),
            const SizedBox(height: 10),

            ..._mockNotifications.map((notif) {
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: (notif['color'] as Color).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(
                        notif['icon'] as IconData,
                        color: notif['color'] as Color,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  notif['title'] as String,
                                  style: const TextStyle(
                                    fontFamily: 'Tajawal',
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: ItqanColors.ink,
                                  ),
                                ),
                              ),
                              Text(
                                notif['time'] as String,
                                style: const TextStyle(
                                  fontFamily: 'Tajawal',
                                  fontSize: 11,
                                  color: ItqanColors.muted,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            notif['body'] as String,
                            style: const TextStyle(
                              fontFamily: 'Tajawal',
                              fontSize: 13,
                              color: ItqanColors.inkSoft,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
