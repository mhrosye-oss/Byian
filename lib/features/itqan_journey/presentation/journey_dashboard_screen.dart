import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../application/itqan_journey_provider.dart';
import '../quran_journey/presentation/quran_journey_screen.dart';
import '../adhkar_journey/presentation/adhkar_journey_screen.dart';
import '../dua_journey/presentation/dua_journey_screen.dart';
import '../share_journey/presentation/share_journey_screen.dart';
import 'achievements_screen.dart';
import 'profile_screen.dart';

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
                    if (tasks.isNotEmpty) ...[
                      Text('مهامك',
                          style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 8),
                      for (final row in tasks)
                        if (row is Map) _taskCard(context, row),
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

  Widget _taskCard(BuildContext context, Map row) {
    final title = '${row['title'] ?? row['name'] ?? row['task_key'] ?? 'مهمة'}';
    final description = '${row['description'] ?? row['status'] ?? ''}';
    final progress = row['progress'];
    final target = row['target'];
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
            if (ratio != null) ...[
              const SizedBox(height: 8),
              LinearProgressIndicator(value: ratio),
              Text('$progress / $target'),
            ],
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
                  const Text('ترتيب كلي (كل الأوقات)'),
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
                            trailing: Text('${row['score']} XP'))),
                  if (me?['rank'] == null)
                    const Card(
                        child: ListTile(title: Text('لم تسجل نشاطاً بعد'))),
                  if (me?['rank'] != null && me?['in_top'] != true)
                    Card(
                        child: ListTile(
                            title: Text('مركزك الحالي: ${me?['rank']}'),
                            trailing: Text('${me?['score']} XP'))),
                ]),
        ));
  }
}
