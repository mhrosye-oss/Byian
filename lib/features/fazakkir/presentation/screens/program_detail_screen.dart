import 'package:flutter/material.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/theme/typography.dart';
import '../../application/scheduling_engine.dart';
import '../../data/fazakkir_repository.dart';
import '../../domain/models/fazakkir_program.dart';
import '../../domain/models/reminder_item.dart';
import 'reminder_detail_screen.dart';

/// شاشة تفاصيل البرنامج في «فَذَكِّر»
class ProgramDetailScreen extends StatefulWidget {
  final FazakkirProgram program;

  const ProgramDetailScreen({super.key, required this.program});

  @override
  State<ProgramDetailScreen> createState() => _ProgramDetailScreenState();
}

class _ProgramDetailScreenState extends State<ProgramDetailScreen> {
  late FazakkirProgram _program;
  List<ReminderItem> _reminders = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _program = widget.program;
    _loadReminders();
  }

  Future<void> _loadReminders() async {
    final repo = FazakkirRepository.instance;
    final all = await repo.getReminders();
    final filtered = all.where((r) => r.programId == _program.id).toList();

    if (mounted) {
      setState(() {
        _reminders = filtered;
        _isLoading = false;
      });
    }
  }

  Future<void> _togglePause() async {
    final updated = _program.copyWith(isPaused: !_program.isPaused);
    final repo = FazakkirRepository.instance;
    await repo.saveProgram(updated);
    await SchedulingEngine().rebuildSchedule();

    if (mounted) {
      setState(() => _program = updated);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            updated.isPaused
                ? 'تم إيقاف البرنامج مؤقتاً'
                : 'تم استئناف البرنامج بنجاح',
          ),
          backgroundColor: ItqanColors.emerald,
        ),
      );
    }
  }

  void _confirmDelete() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('حذف البرنامج'),
          content: const Text(
            'هل ترغب في حذف البرنامج مع الاحتفاظ بأوراده وتذكيراته مستقلة، أم حذف كل شيء؟',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('إلغاء'),
            ),
            TextButton(
              onPressed: () async {
                final nav = Navigator.of(context);
                nav.pop();
                await FazakkirRepository.instance.deleteProgram(
                  _program.id,
                  deleteAssociatedReminders: false,
                );
                await SchedulingEngine().rebuildSchedule();
                if (mounted) nav.pop();
              },
              child: const Text('حذف البرنامج فقط'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade700,
                foregroundColor: Colors.white,
              ),
              onPressed: () async {
                final nav = Navigator.of(context);
                nav.pop();
                await FazakkirRepository.instance.deleteProgram(
                  _program.id,
                  deleteAssociatedReminders: true,
                );
                await SchedulingEngine().rebuildSchedule();
                if (mounted) nav.pop();
              },
              child: const Text('حذف الكل'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: AppBar(
          title: Text(_program.name),
          centerTitle: true,
          elevation: 0,
          actions: [
            IconButton(
              icon: const Icon(Icons.delete_outline_rounded,
                  color: Colors.redAccent),
              tooltip: 'حذف البرنامج',
              onPressed: _confirmDelete,
            ),
          ],
        ),
        body: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: ItqanColors.emerald),
              )
            : ListView(
                padding: const EdgeInsets.all(18),
                children: [
                  // بطاقة معلومات البرنامج
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
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: _program.isPaused
                                    ? Colors.grey.withValues(alpha: 0.2)
                                    : ItqanColors.emerald.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Icon(
                                Icons.auto_stories_rounded,
                                color: _program.isPaused
                                    ? Colors.grey
                                    : ItqanColors.emerald,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _program.name,
                                    style: const TextStyle(
                                      fontSize: 17,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    _program.isPaused
                                        ? 'موقوف مؤقتاً'
                                        : 'نشط ويعمل وفق الجدولة',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: _program.isPaused
                                          ? Colors.grey
                                          : ItqanColors.emerald,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Switch(
                              activeThumbColor: ItqanColors.emerald,
                              value: !_program.isPaused,
                              onChanged: (_) => _togglePause(),
                            ),
                          ],
                        ),
                        if (_program.description.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          Text(
                            _program.description,
                            style: ItqanTypography.caption,
                          ),
                        ],
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  Row(
                    children: [
                      const Text('الأوراد والتذكيرات المندرجة',
                          style: ItqanTypography.heading2),
                      const Spacer(),
                      Text(
                        '${_reminders.length} تذكيرات',
                        style: ItqanTypography.caption,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  if (_reminders.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: ItqanColors.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: ItqanColors.border),
                      ),
                      child: const Center(
                        child: Text(
                          'لا توجد تذكيرات في هذا البرنامج حالياً.',
                          style: ItqanTypography.caption,
                        ),
                      ),
                    )
                  else
                    ..._reminders.map((reminder) {
                      final time = reminder.targetTimes.isNotEmpty
                          ? reminder.targetTimes.first
                          : null;

                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        decoration: BoxDecoration(
                          color: ItqanColors.surface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: ItqanColors.border),
                        ),
                        child: ListTile(
                          title: Text(
                            reminder.title,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          subtitle: Text(
                            '«${reminder.text}»',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 12),
                          ),
                          trailing: time != null
                              ? Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: ItqanColors.surfaceSoft,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    time.format(context),
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12),
                                  ),
                                )
                              : null,
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (_) => ReminderDetailScreen(
                                  reminder: reminder,
                                ),
                              ),
                            ).then((_) => _loadReminders());
                          },
                        ),
                      );
                    }),
                ],
              ),
      ),
    );
  }
}
