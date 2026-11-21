import 'package:flutter/material.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/theme/typography.dart';
import '../../application/scheduling_engine.dart';
import '../../data/fazakkir_repository.dart';
import '../../domain/models/reminder_item.dart';

/// شاشة تفاصيل التذكير الفردي وتعديله
class ReminderDetailScreen extends StatefulWidget {
  final ReminderItem reminder;

  const ReminderDetailScreen({super.key, required this.reminder});

  @override
  State<ReminderDetailScreen> createState() => _ReminderDetailScreenState();
}

class _ReminderDetailScreenState extends State<ReminderDetailScreen> {
  late ReminderItem _reminder;

  @override
  void initState() {
    super.initState();
    _reminder = widget.reminder;
  }

  Future<void> _updateReminder(ReminderItem updated) async {
    setState(() => _reminder = updated);
    await FazakkirRepository.instance.saveReminder(updated);
    await SchedulingEngine().rebuildSchedule();
  }

  void _confirmDelete() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('حذف التذكير'),
          content: Text('هل أنت متأكد من حذف «${_reminder.title}»؟'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('إلغاء'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade700,
                foregroundColor: Colors.white,
              ),
              onPressed: () async {
                final nav = Navigator.of(context);
                nav.pop();
                await FazakkirRepository.instance.deleteReminder(_reminder.id);
                await SchedulingEngine().rebuildSchedule();
                if (mounted) nav.pop();
              },
              child: const Text('حذف'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final time = _reminder.targetTimes.isNotEmpty
        ? _reminder.targetTimes.first
        : const TimeOfDay(hour: 8, minute: 0);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: AppBar(
          title: Text(_reminder.title),
          centerTitle: true,
          elevation: 0,
          actions: [
            IconButton(
              icon: const Icon(Icons.delete_outline_rounded,
                  color: Colors.redAccent),
              onPressed: _confirmDelete,
            ),
          ],
        ),
        body: ListView(
          padding: const EdgeInsets.all(18),
          children: [
            // بطاقة نص الذكر والمرجع
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: ItqanColors.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: ItqanColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: ItqanColors.emerald.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          _reminder.title,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: ItqanColors.emerald,
                          ),
                        ),
                      ),
                      const Spacer(),
                      Switch(
                        activeThumbColor: ItqanColors.emerald,
                        value: _reminder.isActive,
                        onChanged: (val) =>
                            _updateReminder(_reminder.copyWith(isActive: val)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Text(
                    _reminder.fullText != null &&
                            _reminder.fullText!.isNotEmpty
                        ? _reminder.fullText!
                        : _reminder.text,
                    style: const TextStyle(
                      fontFamily: 'NotoNaskhArabic',
                      fontSize: 15,
                      height: 1.8,
                      color: ItqanColors.ink,
                    ),
                  ),
                  const Divider(height: 24),
                  Row(
                    children: [
                      const Icon(Icons.verified_outlined,
                          size: 16, color: ItqanColors.emerald),
                      const SizedBox(width: 6),
                      Text(
                        'المصدر: ${_reminder.reference}',
                        style: ItqanTypography.caption,
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            const Text('إعدادات التذكير والإشعار',
                style: ItqanTypography.heading2),
            const SizedBox(height: 12),

            // تعديل وقت التذكير
            Container(
              decoration: BoxDecoration(
                color: ItqanColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: ItqanColors.border),
              ),
              child: ListTile(
                leading: const Icon(Icons.access_time_rounded,
                    color: ItqanColors.emerald),
                title: const Text('وقت التذكير'),
                subtitle: Text(_reminder.recurrenceRule.humanDescription),
                trailing: Text(
                  time.format(context),
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: ItqanColors.emeraldDark,
                  ),
                ),
                onTap: () async {
                  final picked = await showTimePicker(
                    context: context,
                    initialTime: time,
                  );
                  if (picked != null) {
                    _updateReminder(
                        _reminder.copyWith(targetTimes: [picked]));
                  }
                },
              ),
            ),

            const SizedBox(height: 10),

            // تشغيل الصوت
            Container(
              decoration: BoxDecoration(
                color: ItqanColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: ItqanColors.border),
              ),
              child: SwitchListTile(
                activeThumbColor: ItqanColors.emerald,
                secondary: const Icon(Icons.volume_up_outlined,
                    color: ItqanColors.emerald),
                title: const Text('تنبيه صوتي هادئ'),
                subtitle: const Text('تشغيل نغمة خفيفة مع الإشعار'),
                value: _reminder.soundEnabled,
                onChanged: (val) => _updateReminder(
                    _reminder.copyWith(soundEnabled: val)),
              ),
            ),

            const SizedBox(height: 10),

            // الاهتزاز
            Container(
              decoration: BoxDecoration(
                color: ItqanColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: ItqanColors.border),
              ),
              child: SwitchListTile(
                activeThumbColor: ItqanColors.emerald,
                secondary: const Icon(Icons.vibration_rounded,
                    color: ItqanColors.emerald),
                title: const Text('الاهتزاز'),
                subtitle: const Text('نبضة اهتزاز خفيفة'),
                value: _reminder.vibrationEnabled,
                onChanged: (val) => _updateReminder(
                    _reminder.copyWith(vibrationEnabled: val)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
