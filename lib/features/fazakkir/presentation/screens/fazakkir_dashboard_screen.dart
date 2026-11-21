import 'package:flutter/material.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/theme/typography.dart';
import '../../application/intelligence_engine.dart';
import '../../application/scheduling_engine.dart';
import '../../data/fazakkir_repository.dart';
import '../../domain/models/fazakkir_program.dart';
import '../../domain/models/interaction_record.dart';
import '../../domain/models/reminder_item.dart';
import '../../domain/models/smart_suggestion.dart';
import 'create_program_screen.dart';
import 'missed_reminders_screen.dart';
import 'program_detail_screen.dart';
import 'quiet_hours_screen.dart';
import 'reliability_check_screen.dart';
import 'fazakkir_settings_screen.dart';

/// مركز إدارة «فَذَكِّر» الرئيسي
class FazakkirDashboardScreen extends StatefulWidget {
  const FazakkirDashboardScreen({super.key});

  @override
  State<FazakkirDashboardScreen> createState() =>
      _FazakkirDashboardScreenState();
}

class _FazakkirDashboardScreenState extends State<FazakkirDashboardScreen> {
  final FazakkirRepository _repository = FazakkirRepository.instance;
  final SchedulingEngine _schedulingEngine = SchedulingEngine();
  final IntelligenceEngine _intelligenceEngine = IntelligenceEngine();

  bool _isLoading = true;
  List<FazakkirProgram> _programs = [];
  List<ReminderItem> _reminders = [];
  List<ScheduledOccurrence> _todaySchedule = [];
  List<SmartSuggestion> _suggestions = [];
  int _missedCount = 0;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    setState(() => _isLoading = true);
    await _repository.ensureInitialized();

    final programs = await _repository.getPrograms();
    final reminders = await _repository.getReminders();
    final schedule = await _schedulingEngine.rebuildSchedule();
    final suggestions =
        await _intelligenceEngine.analyzeAndGenerateSuggestions();
    final records = await _repository.getRecords();

    // حساب التذكيرات التي فات وقتها اليوم
    final now = DateTime.now();
    final missed = records
        .where((r) =>
            r.status == ReminderStatus.expired &&
            r.scheduledTime.day == now.day &&
            r.scheduledTime.month == now.month)
        .length;

    if (mounted) {
      setState(() {
        _programs = programs;
        _reminders = reminders;
        _todaySchedule = schedule;
        _suggestions = suggestions;
        _missedCount = missed;
        _isLoading = false;
      });
    }
  }

  /// تسجيل إتمام التذكير («تمّ»)
  Future<void> _completeReminder(ReminderItem reminder, DateTime time) async {
    final record = InteractionRecord(
      id: 'comp_${reminder.id}_${time.millisecondsSinceEpoch}',
      reminderId: reminder.id,
      scheduledTime: time,
      actionTime: DateTime.now(),
      status: ReminderStatus.completed,
    );
    await _repository.saveRecord(record);
    await _loadDashboardData();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('تقبل الله ذكرك وطاعتك «${reminder.title}»'),
          backgroundColor: ItqanColors.emeraldDark,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  /// تأجيل التذكير
  Future<void> _snoozeReminder(ReminderItem reminder) async {
    final snoozed = DateTime.now().add(const Duration(minutes: 15));
    final updated = reminder.copyWith(snoozeUntil: snoozed);
    await _repository.saveReminder(updated);
    await _schedulingEngine.rebuildSchedule();
    await _loadDashboardData();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تم تأجيل التذكير ١٥ دقيقة بهدوء'),
          backgroundColor: ItqanColors.roseGold,
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
          title: const Text(
            'فَذَكِّر',
            style: TextStyle(
              fontFamily: 'Amiri',
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: ItqanColors.emerald,
            ),
          ),
          centerTitle: true,
          elevation: 0,
          backgroundColor: Colors.transparent,
          actions: [
            IconButton(
              icon: const Icon(Icons.verified_user_outlined,
                  color: ItqanColors.emerald),
              tooltip: 'فحص الموثوقية والصلاحيات',
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const ReliabilityCheckScreen(),
                  ),
                );
              },
            ),
            IconButton(
              icon: const Icon(Icons.tune_rounded, color: ItqanColors.inkSoft),
              tooltip: 'إعدادات فَذَكِّر',
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const FazakkirSettingsScreen(),
                  ),
                ).then((_) => _loadDashboardData());
              },
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          backgroundColor: ItqanColors.emerald,
          foregroundColor: Colors.white,
          icon: const Icon(Icons.add_rounded),
          label: const Text(
            'برنامج جديد',
            style: TextStyle(
              fontFamily: 'NotoNaskhArabic',
              fontWeight: FontWeight.bold,
            ),
          ),
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const CreateProgramScreen(),
              ),
            ).then((_) => _loadDashboardData());
          },
        ),
        body: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: ItqanColors.emerald),
              )
            : RefreshIndicator(
                color: ItqanColors.emerald,
                onRefresh: _loadDashboardData,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(18, 10, 18, 90),
                  children: [
                    // 1. التذكير القادم مباشرة
                    _buildNextReminderSection(),

                    const SizedBox(height: 20),

                    // 2. مسار اليوم بترتيب زمني
                    _buildTodayTimelineSection(),

                    const SizedBox(height: 24),

                    // 3. الاقتراحات الذكية (تظهر فقط عند وجود اقتراح فعلي)
                    if (_suggestions.isNotEmpty) ...[
                      _buildSuggestionsSection(),
                      const SizedBox(height: 24),
                    ],

                    // 4. قائمة برامجي
                    _buildMyProgramsSection(),

                    const SizedBox(height: 24),

                    // 5. روابط سريعة: «ما فاتني» وساعات الهدوء
                    _buildQuickCardsRow(),
                  ],
                ),
              ),
      ),
    );
  }

  // ─── 1. Next Reminder Section ─────────────────────────────────────────────
  Widget _buildNextReminderSection() {
    if (_todaySchedule.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: ItqanColors.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: ItqanColors.border),
        ),
        child: Row(
          children: [
            const Icon(Icons.check_circle_outline_rounded,
                color: ItqanColors.correct, size: 28),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text('لا توجد تذكيرات مجدولة حالياً',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  SizedBox(height: 2),
                  Text('أضف برنامجاً أو فعّل أحد القوالب السبعة للبدء',
                      style: ItqanTypography.caption),
                ],
              ),
            ),
          ],
        ),
      );
    }

    final nextOcc = _todaySchedule.first;
    final r = nextOcc.reminder;
    final t = nextOcc.resolvedTime;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: ItqanColors.emerald.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: ItqanColors.emerald.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                decoration: BoxDecoration(
                  color: ItqanColors.emerald,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'التذكير القادم',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                _formatTime(t),
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: ItqanColors.emeraldDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            r.title,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: ItqanColors.ink,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '«${r.text}»',
            style: const TextStyle(
              fontFamily: 'NotoNaskhArabic',
              fontSize: 14,
              color: ItqanColors.inkSoft,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'المصدر: ${r.reference}',
            style: const TextStyle(
              fontSize: 11,
              color: ItqanColors.muted,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton.icon(
                onPressed: () => _snoozeReminder(r),
                icon: const Icon(Icons.snooze_rounded, size: 16),
                label: const Text('تأجيل ١٥ د'),
                style: TextButton.styleFrom(
                  foregroundColor: ItqanColors.roseGold,
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                onPressed: () => _completeReminder(r, t),
                icon: const Icon(Icons.check_rounded, size: 16),
                label: const Text('تمّ'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: ItqanColors.emerald,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ─── 2. Today Timeline ───────────────────────────────────────────────────
  Widget _buildTodayTimelineSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text('مسار اليوم', style: ItqanTypography.heading2),
            const Spacer(),
            Text(
              '${_todaySchedule.length} مواعيد مجدولة',
              style: ItqanTypography.caption
                  .copyWith(color: ItqanColors.roseGold),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (_todaySchedule.isEmpty)
          const Text('لا توجد مواعيد أخرى اليوم',
              style: ItqanTypography.caption)
        else
          ..._todaySchedule.take(5).map((occ) {
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: ItqanColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: ItqanColors.border),
              ),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: ItqanColors.surfaceSoft,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.alarm_rounded,
                        size: 18, color: ItqanColors.emerald),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          occ.reminder.title,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: ItqanColors.ink,
                          ),
                        ),
                        Text(
                          _formatTime(occ.resolvedTime),
                          style: const TextStyle(
                            fontSize: 11,
                            color: ItqanColors.muted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.check_circle_outline_rounded,
                        color: ItqanColors.emerald),
                    tooltip: 'تسجيل إتمام',
                    onPressed: () =>
                        _completeReminder(occ.reminder, occ.resolvedTime),
                  ),
                ],
              ),
            );
          }),
      ],
    );
  }

  // ─── 3. Suggestions Section ───────────────────────────────────────────────
  Widget _buildSuggestionsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('اقتراح ذكي هادئ', style: ItqanTypography.heading2),
        const SizedBox(height: 10),
        ..._suggestions.map((s) {
          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFFAF6EE),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFFE2D1A8)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.tips_and_updates_rounded,
                        color: Color(0xFF9A6A12), size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        s.question,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF6B4804),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  s.description,
                  style: const TextStyle(fontSize: 12, color: Colors.black87),
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () async {
                        await _intelligenceEngine.dismissSuggestion(s.id);
                        _loadDashboardData();
                      },
                      child: const Text('ليس الآن',
                          style: TextStyle(color: Colors.black54)),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF9A6A12),
                        foregroundColor: Colors.white,
                      ),
                      onPressed: () async {
                        await _intelligenceEngine
                            .applySeparationSuggestion(s);
                        _loadDashboardData();
                      },
                      child: const Text('موافق، طبق التعديل'),
                    ),
                  ],
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  // ─── 4. My Programs Section ───────────────────────────────────────────────
  Widget _buildMyProgramsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text('برامجي', style: ItqanTypography.heading2),
            const Spacer(),
            Text(
              '${_programs.length} برامج',
              style: ItqanTypography.caption
                  .copyWith(color: ItqanColors.roseGold),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (_programs.isEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: ItqanColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: ItqanColors.border),
            ),
            child: const Center(
              child: Text(
                'لم تنشئ أي برامج بعد. اضغط «برنامج جديد» للبدء.',
                style: ItqanTypography.caption,
              ),
            ),
          )
        else
          ..._programs.map((program) {
            final programReminders = _reminders
                .where((r) => r.programId == program.id)
                .toList();

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: ItqanColors.surface,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: ItqanColors.border),
              ),
              child: ListTile(
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                leading: Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: program.isPaused
                        ? Colors.grey.withValues(alpha: 0.2)
                        : ItqanColors.emerald.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.auto_stories_rounded,
                    color: program.isPaused
                        ? Colors.grey
                        : ItqanColors.emerald,
                  ),
                ),
                title: Text(
                  program.name,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    decoration: program.isPaused
                        ? TextDecoration.lineThrough
                        : TextDecoration.none,
                  ),
                ),
                subtitle: Text(
                  '${programReminders.length} أوراد • ${program.isPaused ? "موقوف مؤقتاً" : "نشط"}',
                  style: ItqanTypography.caption,
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Switch(
                      activeThumbColor: ItqanColors.emerald,
                      value: !program.isPaused,
                      onChanged: (val) async {
                        final updated =
                            program.copyWith(isPaused: !val);
                        await _repository.saveProgram(updated);
                        await _schedulingEngine.rebuildSchedule();
                        _loadDashboardData();
                      },
                    ),
                    const Icon(Icons.arrow_forward_ios_rounded,
                        size: 14, color: ItqanColors.muted),
                  ],
                ),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => ProgramDetailScreen(program: program),
                    ),
                  ).then((_) => _loadDashboardData());
                },
              ),
            );
          }),
      ],
    );
  }

  // ─── 5. Quick Cards Row (Missed & Quiet Hours) ─────────────────────────────
  Widget _buildQuickCardsRow() {
    return Row(
      children: [
        Expanded(
          child: _buildSmallActionCard(
            title: 'ما فاتَني',
            subtitle: _missedCount > 0
                ? '$_missedCount تذكيرات فائتة'
                : 'مسارك مكتمل بسكينة',
            icon: Icons.history_rounded,
            badge: _missedCount > 0 ? '$_missedCount' : null,
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const MissedRemindersScreen(),
                ),
              ).then((_) => _loadDashboardData());
            },
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildSmallActionCard(
            title: 'ساعات الهدوء',
            subtitle: 'فترات النوم والراحة',
            icon: Icons.nightlight_round,
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const QuietHoursScreen(),
                ),
              ).then((_) => _loadDashboardData());
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSmallActionCard({
    required String title,
    required String subtitle,
    required IconData icon,
    String? badge,
    required VoidCallback onTap,
  }) {
    return Material(
      color: ItqanColors.surface,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: ItqanColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, size: 20, color: ItqanColors.emerald),
                  const Spacer(),
                  if (badge != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: ItqanColors.roseGold.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        badge,
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: ItqanColors.roseGold,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: ItqanColors.ink,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: ItqanTypography.caption.copyWith(fontSize: 11),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  static String _formatTime(DateTime time) {
    final h = time.hour > 12
        ? time.hour - 12
        : (time.hour == 0 ? 12 : time.hour);
    final m = time.minute.toString().padLeft(2, '0');
    final period = time.hour >= 12 ? 'م' : 'ص';
    return '$h:$m $period';
  }
}
