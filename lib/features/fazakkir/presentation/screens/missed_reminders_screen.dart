import 'package:flutter/material.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/theme/typography.dart';
import '../../data/fazakkir_repository.dart';
import '../../domain/models/interaction_record.dart';
import '../../domain/models/reminder_item.dart';

/// مساحة «ما فاتَني» في خدمة «فَذَكِّر»
/// تتبع مبدأ: لا لوم ولا ضغط ولا ألوان تحذيرية أو سلاسل إنجاز
class MissedRemindersScreen extends StatefulWidget {
  const MissedRemindersScreen({super.key});

  @override
  State<MissedRemindersScreen> createState() => _MissedRemindersScreenState();
}

class _MissedRemindersScreenState extends State<MissedRemindersScreen> {
  List<({InteractionRecord record, ReminderItem? reminder})> _missedItems = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadMissed();
  }

  Future<void> _loadMissed() async {
    final repo = FazakkirRepository.instance;
    final records = await repo.getRecords();
    final reminders = await repo.getReminders();
    final remindersMap = {for (var r in reminders) r.id: r};

    // جلب السجلات التي انتهى وقتها أو سُجلت كـ expired
    final filtered = records
        .where((rec) => rec.status == ReminderStatus.expired)
        .map((rec) => (record: rec, reminder: remindersMap[rec.reminderId]))
        .toList();

    filtered.sort((a, b) => b.record.scheduledTime.compareTo(a.record.scheduledTime));

    if (mounted) {
      setState(() {
        _missedItems = filtered;
        _isLoading = false;
      });
    }
  }

  /// تدارك الورد الآن وتسجيله كـ "تمّ"
  Future<void> _completeMissed(InteractionRecord record) async {
    final updated = record.copyWith(
      status: ReminderStatus.completed,
      actionTime: DateTime.now(),
      note: 'تم التدارك بسكينة',
    );
    await FazakkirRepository.instance.saveRecord(updated);
    await _loadMissed();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تقبل الله منك وكتب لك الأجر كاملاً'),
          backgroundColor: ItqanColors.emeraldDark,
          duration: Duration(seconds: 2),
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
          title: const Text('ما فاتَني'),
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
                  // بطاقة سكينة علوية توضيحية
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: ItqanColors.emerald.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: ItqanColors.emerald.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.favorite_outline_rounded,
                            color: ItqanColors.emerald, size: 24),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text(
                            '«أحبُّ الأعمالِ إلى اللهِ أدْوَمُها وإنْ قَلَّ»\nلا حرج إن فاتك موعد، فباب الذكر مفتوح في كل وقت وحين.',
                            style: TextStyle(
                              fontSize: 13,
                              height: 1.5,
                              color: ItqanColors.emeraldDark,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  if (_missedItems.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(32),
                      decoration: BoxDecoration(
                        color: ItqanColors.surface,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: ItqanColors.border),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(Icons.spa_rounded,
                              size: 48, color: ItqanColors.emerald),
                          SizedBox(height: 12),
                          Text(
                            'مسارك نقي ومكتمل',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'لا توجد أوراد معلقة أو فائتة لم تتداركها.',
                            style: ItqanTypography.caption,
                          ),
                        ],
                      ),
                    )
                  else
                    ..._missedItems.map((item) {
                      final title =
                          item.reminder?.title ?? 'تذكير سابق';
                      final text = item.reminder?.text ?? '';

                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: ItqanColors.surface,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: ItqanColors.border),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  title,
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const Spacer(),
                                Text(
                                  _formatDate(item.record.scheduledTime),
                                  style: ItqanTypography.caption,
                                ),
                              ],
                            ),
                            if (text.isNotEmpty) ...[
                              const SizedBox(height: 6),
                              Text(
                                '«$text»',
                                style: const TextStyle(
                                  fontFamily: 'NotoNaskhArabic',
                                  fontSize: 13,
                                  color: ItqanColors.inkSoft,
                                ),
                              ),
                            ],
                            const SizedBox(height: 12),
                            Align(
                              alignment: Alignment.centerLeft,
                              child: ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: ItqanColors.emerald,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                icon: const Icon(Icons.done_all_rounded, size: 16),
                                label: const Text('أتممته الآن'),
                                onPressed: () => _completeMissed(item.record),
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

  static String _formatDate(DateTime dt) {
    return '${dt.day}/${dt.month} - ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}';
  }
}
