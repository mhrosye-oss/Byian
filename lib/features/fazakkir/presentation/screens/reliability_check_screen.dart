import 'package:flutter/material.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/theme/typography.dart';
import '../../application/fazakkir_notification_service.dart';
import '../../application/scheduling_engine.dart';
import '../../data/fazakkir_repository.dart';

/// صفحة «فحص الموثوقية والصلاحيات» لخدمة «فَذَكِّر»
class ReliabilityCheckScreen extends StatefulWidget {
  const ReliabilityCheckScreen({super.key});

  @override
  State<ReliabilityCheckScreen> createState() =>
      _ReliabilityCheckScreenState();
}

class _ReliabilityCheckScreenState extends State<ReliabilityCheckScreen> {
  bool _isLoading = true;
  bool _notificationGranted = false;
  bool _exactAlarmGranted = false;
  DateTime? _lastRebuildTime;
  int _scheduledCount = 0;

  @override
  void initState() {
    super.initState();
    _checkStatus();
  }

  Future<void> _checkStatus() async {
    setState(() => _isLoading = true);
    final notifService = FazakkirNotificationService.instance;
    final perms = await notifService.checkAndRequestPermissions();
    final repo = FazakkirRepository.instance;
    final lastRebuild = await repo.getLastRebuildTime();
    final reminders = await repo.getReminders();
    final active = reminders.where((r) => r.isActive).length;

    if (mounted) {
      setState(() {
        _notificationGranted = perms.notificationsGranted;
        _exactAlarmGranted = perms.exactAlarmGranted;
        _lastRebuildTime = lastRebuild;
        _scheduledCount = active;
        _isLoading = false;
      });
    }
  }

  Future<void> _triggerManualRebuild() async {
    setState(() => _isLoading = true);
    await SchedulingEngine().rebuildSchedule();
    await _checkStatus();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تمت إعادة بناء الجدولة بنجاح محلياً'),
          backgroundColor: ItqanColors.emeraldDark,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: AppBar(
          title: const Text('فحص الموثوقية والصلاحيات'),
          centerTitle: true,
          elevation: 0,
        ),
        body: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: ItqanColors.emerald),
              )
            : ListView(
                padding: const EdgeInsets.all(18),
                children: [
                  // بطاقة الحالة العامة
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: _notificationGranted
                          ? ItqanColors.emerald.withValues(alpha: 0.08)
                          : Colors.orange.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(
                        color: _notificationGranted
                            ? ItqanColors.emerald.withValues(alpha: 0.3)
                            : Colors.orange.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          _notificationGranted
                              ? Icons.verified_rounded
                              : Icons.warning_amber_rounded,
                          color: _notificationGranted
                              ? ItqanColors.emerald
                              : Colors.orange,
                          size: 38,
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _notificationGranted
                                    ? 'النظام جاهز وموثوق'
                                    : 'تنبيه: الصلاحيات بحاجة لتفعيل',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _notificationGranted
                                    ? 'إشعارات الأوراد مجدولة ($_scheduledCount ورداً نشطاً) وستصلك في مواعيدها.'
                                    : 'يُرجى السماح بالإشعارات من إعدادات الهاتف لتتمكن الخدمة من تذكيرك.',
                                style: ItqanTypography.caption,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  const Text('مؤشرات موثوقية النظام',
                      style: ItqanTypography.heading2),
                  const SizedBox(height: 12),

                  // فحص إذن الإشعارات POST_NOTIFICATIONS
                  _buildStatusTile(
                    title: 'إذن إرسال الإشعارات',
                    subtitle: 'صلاحية عرض التنبيهات في شريط النظام',
                    isOk: _notificationGranted,
                  ),

                  const SizedBox(height: 10),

                  // فحص التنبيه الدقيق EXACT_ALARM
                  _buildStatusTile(
                    title: 'صلاحية التنبيه الدقيق (Exact Alarm)',
                    subtitle: 'إطلاق الإشعار بالدقيقة المحددة تماماً',
                    isOk: _exactAlarmGranted,
                  ),

                  const SizedBox(height: 10),

                  // حالة آخر إعادة بناء
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: ItqanColors.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: ItqanColors.border),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.sync_rounded,
                            color: ItqanColors.emerald),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'آخر إعادة بناء للجدولة',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _lastRebuildTime != null
                                    ? '${_lastRebuildTime!.day}/${_lastRebuildTime!.month} - ${_lastRebuildTime!.hour}:${_lastRebuildTime!.minute.toString().padLeft(2, '0')}'
                                    : 'تمت التهيئة الآن',
                                style: ItqanTypography.caption,
                              ),
                            ],
                          ),
                        ),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: ItqanColors.surfaceSoft,
                            foregroundColor: ItqanColors.emerald,
                            elevation: 0,
                          ),
                          onPressed: _triggerManualRebuild,
                          child: const Text('تحديث الآن'),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  const Text('إرشادات ضبط الهاتف لضمان عدم تفويت الأوراد',
                      style: ItqanTypography.heading2),
                  const SizedBox(height: 10),

                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: ItqanColors.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: ItqanColors.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          '١. استثناء إتقan من توفير البطارية (Battery Optimization)\n'
                          'تقوم بعض واجهات أندرويد (مثل سامسونج وشاومي) بإيقاف التنبيهات في الخلفية لتوفير الطاقة. اضبط إتقان على "غير مقيّد" في إدارة التطبيقات.\n\n'
                          '٢. التشغيل التلقائي بعد إعادة تشغيل الهاتف\n'
                          'الخدمة مزودة بمستقبل Boot Receiver يقوم بإعادة جدولة الأوراد تلقائياً فور فتح الجهاز.',
                          style: TextStyle(
                            fontSize: 12,
                            height: 1.6,
                            color: ItqanColors.inkSoft,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildStatusTile({
    required String title,
    required String subtitle,
    required bool isOk,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ItqanColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: ItqanColors.border),
      ),
      child: Row(
        children: [
          Icon(
            isOk ? Icons.check_circle_rounded : Icons.cancel_rounded,
            color: isOk ? ItqanColors.correct : Colors.redAccent,
            size: 22,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(subtitle, style: ItqanTypography.caption),
              ],
            ),
          ),
          Text(
            isOk ? 'مفعّل' : 'غير متوفر',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: isOk ? ItqanColors.correct : Colors.redAccent,
            ),
          ),
        ],
      ),
    );
  }
}
