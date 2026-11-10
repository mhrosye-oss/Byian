import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../application/itqan_journey_provider.dart';
import '../quran_journey/presentation/quran_journey_screen.dart';
import '../adhkar_journey/presentation/adhkar_journey_screen.dart';
import '../dua_journey/presentation/dua_journey_screen.dart';
import '../share_journey/presentation/share_journey_screen.dart';
import 'achievements_screen.dart';
import 'profile_screen.dart';
import 'journey_reminder_settings_screen.dart';

class JourneyDashboardScreen extends ConsumerStatefulWidget {
  const JourneyDashboardScreen({super.key});
  @override
  ConsumerState<JourneyDashboardScreen> createState() =>
      _JourneyDashboardScreenState();
}

class _JourneyDashboardScreenState
    extends ConsumerState<JourneyDashboardScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(itqanJourneyProvider.notifier).loadAll());
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(itqanJourneyProvider);
    final tasks = (state.tasks?['tasks'] as List?) ?? const [];
    return Scaffold(
      appBar: AppBar(title: const Text('رحلتك إلى الأفضل')),
      body: state.loading && state.profile == null
          ? const Center(child: CircularProgressIndicator())
          : state.error != null && state.profile == null
              ? Center(
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Text(state.error!),
                  TextButton(
                      onPressed: () =>
                          ref.read(itqanJourneyProvider.notifier).loadAll(),
                      child: const Text('إعادة المحاولة')),
                ]))
              : RefreshIndicator(
                  onRefresh: () =>
                      ref.read(itqanJourneyProvider.notifier).loadAll(),
                  child: ListView(padding: const EdgeInsets.all(16), children: [
                    _JourneySummary(profile: state.profile),
                    const SizedBox(height: 12),
                    _JourneyProgress(data: state.journey),
                    const SizedBox(height: 12),
                    for (final module in _modules(context))
                      Card(
                          child: ListTile(
                        leading: Icon(module.$3,
                            color: Theme.of(context).colorScheme.primary),
                        title: Text(module.$1),
                        subtitle: Text(module.$2),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => Navigator.push(context,
                            MaterialPageRoute<void>(builder: (_) => module.$4)),
                      )),
                    const SizedBox(height: 12),
                    for (final cadence in const [
                      'core',
                      'daily',
                      'weekly'
                    ]) ...[
                      if (tasks.any((row) =>
                          row is Map && row['cadence'] == cadence)) ...[
                        Text(_cadenceLabel(cadence),
                            style: Theme.of(context).textTheme.titleMedium),
                        const SizedBox(height: 8),
                        for (final row in tasks)
                          if (row is Map && row['cadence'] == cadence)
                            _taskCard(context, row),
                      ],
                    ],
                    if (state.tasks != null)
                      Text(
                          'المهام المكتملة اليوم: ${state.tasks!['counts']?['completed'] ?? 0} / ${state.tasks!['counts']?['total'] ?? 0}'),
                    if (state.lastActivity != null)
                      Text(
                          'النقاط المكتسبة في آخر نشاط: ${state.lastActivity!['xp_earned'] ?? 0} XP'),
                    if (state.streak != null)
                      Text(
                          'الاستمرارية الحالية: ${state.streak!['current_streak'] ?? 0}'),
                    if (tasks.isEmpty && state.tasks != null)
                      const Text('لا توجد مهام متاحة حالياً.'),
                    OutlinedButton.icon(
                      onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute<void>(
                              builder: (_) =>
                                  const JourneyAchievementsScreen())),
                      icon: const Icon(Icons.military_tech),
                      label: const Text('الإنجازات والأوسمة'),
                    ),
                    OutlinedButton.icon(
                      onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute<void>(
                              builder: (_) =>
                                  const JourneyLeaderboardScreen())),
                      icon: const Icon(Icons.leaderboard),
                      label: const Text('العشرة الأوائل'),
                    ),
                    OutlinedButton.icon(
                      onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute<void>(
                              builder: (_) => const JourneyProfileScreen())),
                      icon: const Icon(Icons.person),
                      label: const Text('ملفي الشخصي'),
                    ),
                    OutlinedButton.icon(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute<void>(
                          builder: (_) => const JourneyReminderSettingsScreen(),
                        ),
                      ),
                      icon: const Icon(Icons.notifications_active_outlined),
                      label: const Text('تذكيرات الرحلة'),
                    ),
                  ]),
                ),
    );
  }

  List<(String, String, IconData, Widget)> _modules(BuildContext context) => [
        (
          'القرآن الكريم',
          'اقرأ وردك اليومي',
          Icons.menu_book_rounded,
          const QuranJourneyScreen()
        ),
        (
          'الأذكار',
          'حافظ على أذكارك اليومية',
          Icons.spa_rounded,
          const AdhkarJourneyScreen()
        ),
        (
          'الأدعية',
          'اقرأ دعاء اليوم',
          Icons.volunteer_activism_rounded,
          const DuaJourneyScreen()
        ),
        (
          'مشاركة الخير',
          'شارك فائدة أو ذكراً أو دعاءً',
          Icons.share_rounded,
          const ShareJourneyScreen()
        ),
      ];

  String _cadenceLabel(String cadence) => switch (cadence) {
        'core' => 'المهام الأساسية',
        'daily' => 'المهام اليومية',
        'weekly' => 'المهام الأسبوعية',
        _ => 'مهام أخرى',
      };

  Widget _taskCard(BuildContext context, Map row) {
    final title = '${row['title'] ?? row['name'] ?? row['task_key'] ?? 'مهمة'}';
    final description = '${row['description'] ?? row['status'] ?? ''}';
    final activityType = '${row['activity_type'] ?? row['type'] ?? ''}';
    final progress = row['progress'];
    final target = row['target'];
    final status =
        row['completed'] == true ? 'مكتملة' : '${row['status'] ?? ''}';
    final hasProgress = progress is num && target is num && target > 0;
    final ratio =
        hasProgress ? (progress / target).toDouble().clamp(0.0, 1.0) : null;
    final pillar = '${row['pillar'] ?? row['task_key'] ?? ''}';

    return Card(
      child: ListTile(
        title: Text(title),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (description.isNotEmpty) Text(description),
            if (activityType.isNotEmpty) Text('نوع النشاط: $activityType'),
            if (status.isNotEmpty) Text('الحالة: $status'),
            if (ratio != null) ...[
              const SizedBox(height: 8),
              LinearProgressIndicator(value: ratio),
              Text('$progress / $target'),
            ],
            Text(
                'المكافأة: ${row['xp_reward'] ?? '—'} XP • ${row['coin_reward'] ?? '—'} Coins'),
          ],
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => _openPillar(context, pillar),
      ),
    );
  }

  void _openPillar(BuildContext context, String pillar) {
    final key = pillar.toLowerCase();
    final Widget page = key.contains('quran')
        ? const QuranJourneyScreen()
        : key.contains('adhkar')
            ? const AdhkarJourneyScreen()
            : key.contains('dua')
                ? const DuaJourneyScreen()
                : const ShareJourneyScreen();
    Navigator.push(context, MaterialPageRoute<void>(builder: (_) => page));
  }
}

class _JourneyProgress extends StatelessWidget {
  const _JourneyProgress({required this.data});

  final Map<String, dynamic>? data;

  @override
  Widget build(BuildContext context) {
    final nested = data?['journey'];
    final journey = nested is Map ? _journeyMap(nested) : data;
    if (journey == null) {
      return const Card(
        child:
            ListTile(title: Text('بيانات العوالم والمراحل غير متاحة حالياً.')),
      );
    }

    final currentStage = _journeyMap(journey['current_stage']);
    final currentWorld = _journeyMap(journey['current_world']);
    final worlds =
        journey['worlds'] is List ? journey['worlds'] as List : const [];
    final stages =
        journey['stages'] is List ? journey['stages'] as List : const [];
    final pillars = _journeyMap(journey['pillars']);
    final worldName = currentWorld['name'] ??
        currentWorld['title'] ??
        currentWorld['key'] ??
        journey['current_world'] ??
        '—';
    final stageName = currentStage['name'] ??
        currentStage['title'] ??
        currentStage['key'] ??
        journey['current_stage'] ??
        '—';
    final percentage = journey['completion_percentage'];
    final ratio = percentage is num
        ? (percentage.toDouble() / 100).clamp(0.0, 1.0)
        : null;

    return Card(
      child: ExpansionTile(
        initiallyExpanded: true,
        leading: const Icon(Icons.route_outlined),
        title: const Text('العوالم والمراحل'),
        subtitle: Text('العالم $worldName • المرحلة $stageName'),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        children: [
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              'المراحل المكتملة: ${journey['completed_stages'] ?? '—'} / ${journey['total_stages'] ?? '—'}',
            ),
          ),
          if (ratio != null) ...[
            const SizedBox(height: 8),
            LinearProgressIndicator(value: ratio),
            Text('تقدم الرحلة: ${percentage.toString()}%'),
          ],
          if (pillars.isNotEmpty) ...[
            const Divider(height: 24),
            const Align(
              alignment: Alignment.centerRight,
              child: Text('تقدم المجالات',
                  style: TextStyle(fontWeight: FontWeight.bold)),
            ),
            for (final entry in pillars.entries)
              _JourneyDataRow(
                title: _journeyDomain(entry.key),
                value: entry.value,
              ),
          ],
          if (worlds.isNotEmpty) ...[
            const Divider(height: 24),
            const Align(
              alignment: Alignment.centerRight,
              child: Text('العوالم',
                  style: TextStyle(fontWeight: FontWeight.bold)),
            ),
            for (final item in worlds)
              if (item is Map)
                _JourneyDataRow(
                  title:
                      '${item['name'] ?? item['title'] ?? item['key'] ?? 'العالم'}',
                  value: item['status'] ??
                      item['state'] ??
                      (item['is_unlocked'] == true
                          ? 'unlocked'
                          : item['is_unlocked'] == false
                              ? 'locked'
                              : ''),
                ),
          ],
          if (stages.isNotEmpty) ...[
            const Divider(height: 24),
            const Align(
              alignment: Alignment.centerRight,
              child: Text('المراحل',
                  style: TextStyle(fontWeight: FontWeight.bold)),
            ),
            for (final item in stages)
              if (item is Map) _JourneyStageRow(stage: _journeyMap(item)),
          ],
        ],
      ),
    );
  }
}

class _JourneyDataRow extends StatelessWidget {
  const _JourneyDataRow({required this.title, required this.value});

  final String title;
  final dynamic value;

  @override
  Widget build(BuildContext context) {
    final map = _journeyMap(value);
    final progress = map['progress'] ?? map['completed'] ?? map['current'];
    final target = map['target'] ?? map['required'];
    final percent = map['percentage'] ?? map['progress_percentage'];
    final subtitle = map.isEmpty
        ? _journeyStatus('$value')
        : [
            if (progress != null)
              '$progress${target == null ? '' : ' / $target'}',
            if (percent is num) '${percent.toString()}%',
            if (map['status'] != null) _journeyStatus('${map['status']}'),
          ].join(' • ');
    final ratio =
        percent is num ? (percent.toDouble() / 100).clamp(0.0, 1.0) : null;
    return ListTile(
      dense: true,
      contentPadding: EdgeInsets.zero,
      title: Text(title),
      subtitle: subtitle.isEmpty ? null : Text(subtitle),
      trailing: ratio == null
          ? null
          : SizedBox(width: 48, child: LinearProgressIndicator(value: ratio)),
    );
  }
}

class _JourneyStageRow extends StatelessWidget {
  const _JourneyStageRow({required this.stage});

  final Map<String, dynamic> stage;

  @override
  Widget build(BuildContext context) {
    final number = stage['number'] ?? stage['stage_number'];
    final name = stage['name'] ?? stage['title'] ?? stage['key'];
    final status = stage['status'] ??
        stage['state'] ??
        (stage['is_completed'] == true
            ? 'completed'
            : stage['is_locked'] == true
                ? 'locked'
                : stage['is_unlocked'] == true
                    ? 'unlocked'
                    : null);
    final percent = stage['percentage'] ?? stage['progress_percentage'];
    final requirements = stage['requirements'];
    final requirementText = requirements == null ? '' : '$requirements';
    return ListTile(
      dense: true,
      contentPadding: EdgeInsets.zero,
      leading: Icon(status == 'completed'
          ? Icons.check_circle_outline
          : status == 'locked'
              ? Icons.lock_outline
              : Icons.radio_button_unchecked),
      title: Text('مرحلة ${number ?? ''}${name == null ? '' : ' • $name'}'),
      subtitle: Text([
        if (status != null) _journeyStatus('$status'),
        if (percent is num) 'التقدم ${percent.toString()}%',
        if (requirementText.isNotEmpty) 'المتطلبات: $requirementText',
      ].join(' • ')),
      trailing: percent is num
          ? SizedBox(
              width: 48,
              child: LinearProgressIndicator(
                value: (percent.toDouble() / 100).clamp(0.0, 1.0),
              ),
            )
          : null,
    );
  }
}

Map<String, dynamic> _journeyMap(dynamic value) =>
    value is Map ? Map<String, dynamic>.from(value) : <String, dynamic>{};

String _journeyDomain(String key) => switch (key) {
      'quran' => 'القرآن',
      'adhkar' => 'الأذكار',
      'dua' => 'الأدعية',
      'sharing' || 'share' => 'المشاركة',
      _ => key,
    };

String _journeyStatus(String status) => switch (status) {
      'locked' => 'مقفلة',
      'unlocked' => 'مفتوحة',
      'completed' => 'مكتملة',
      _ => status,
    };

class _JourneySummary extends StatelessWidget {
  const _JourneySummary({this.profile});
  final Map<String, dynamic>? profile;
  @override
  Widget build(BuildContext context) {
    final stats = profile?['stats'] as Map?;
    final level = stats?['level'] as Map?;
    final tasks = stats?['tasks'] as Map?;
    final progress =
        (((level?['progress_percentage'] as num?)?.toDouble() ?? 0) / 100)
            .clamp(0.0, 1.0);
    return Card(
        child: Padding(
            padding: const EdgeInsets.all(18),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('رحلتك إلى الأفضل',
                  style: Theme.of(context).textTheme.titleLarge),
              Text(
                  'المستوى ${level?['number'] ?? '—'} • ${level?['title'] ?? ''}'),
              Text('${stats?['total_xp'] ?? '—'} XP'),
              Text('${stats?['total_coins'] ?? '—'} Coins'),
              const SizedBox(height: 8),
              LinearProgressIndicator(value: progress),
              const SizedBox(height: 8),
              Text(
                  'المهام المكتملة: ${tasks?['completed_total'] ?? '—'} / ${tasks?['total_available'] ?? '—'}'),
            ])));
  }
}

class JourneyLeaderboardScreen extends ConsumerStatefulWidget {
  const JourneyLeaderboardScreen({super.key});
  @override
  ConsumerState<JourneyLeaderboardScreen> createState() =>
      _JourneyLeaderboardScreenState();
}

class _JourneyLeaderboardScreenState
    extends ConsumerState<JourneyLeaderboardScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(
        () => ref.read(itqanJourneyProvider.notifier).refreshLeaderboard());
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(itqanJourneyProvider);
    final data = state.leaderboard;
    final top = (data?['top'] as List?) ?? const [];
    final me = data?['me'] as Map?;
    return Scaffold(
        appBar: AppBar(title: const Text('العشرة الأوائل')),
        body: RefreshIndicator(
          onRefresh: () =>
              ref.read(itqanJourneyProvider.notifier).refreshLeaderboard(),
          child: data == null
              ? ListView(children: [
                  const SizedBox(height: 160),
                  Center(
                      child: TextButton(
                          onPressed: () => ref
                              .read(itqanJourneyProvider.notifier)
                              .refreshLeaderboard(),
                          child: Text(state.error ?? 'إعادة المحاولة')))
                ])
              : ListView(padding: const EdgeInsets.all(16), children: [
                  const Text('أكثر المستخدمين إنجازاً'),
                  Text('الفترة: ${data['period'] ?? '—'}'),
                  Text('نوع النقاط: ${data['score_type'] ?? '—'}'),
                  if (top.isEmpty)
                    const Padding(
                        padding: EdgeInsets.all(24),
                        child: Text('لا توجد نتائج')),
                  for (final row in top)
                    Card(
                        child: ListTile(
                            leading:
                                CircleAvatar(child: Text('${row['rank']}')),
                            title: Text('${row['name']}'),
                            subtitle: Text(
                                'المستوى ${row['level']} • ${row['level_title']}'),
                            trailing: Text(
                                '${row['score']} ${data['score_type'] ?? ''}'))),
                  if (me?['rank'] == null)
                    const Card(
                        child: ListTile(title: Text('لم تسجل نشاطاً بعد'))),
                  if (me?['rank'] != null && me?['in_top'] != true)
                    Card(
                        child: ListTile(
                            title: Text(
                                'مركزك الحالي: ${me?['rank']} • ${me?['name'] ?? ''}'),
                            trailing: Text(
                                '${me?['score']} ${data['score_type'] ?? ''}'))),
                ]),
        ));
  }
}
