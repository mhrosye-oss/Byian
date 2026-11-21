import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../application/itqan_journey_provider.dart';

class JourneyAchievementsScreen extends ConsumerStatefulWidget {
  const JourneyAchievementsScreen({super.key});

  @override
  ConsumerState<JourneyAchievementsScreen> createState() =>
      _JourneyAchievementsScreenState();
}

class _JourneyAchievementsScreenState
    extends ConsumerState<JourneyAchievementsScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(
      () => ref.read(itqanJourneyProvider.notifier).refreshAchievements(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(itqanJourneyProvider);
    final raw = state.achievements?['achievements'];
    final rows = raw is List ? raw : const <dynamic>[];
    final earnedCount = state.achievements?['earned'] ??
        rows
            .where((entry) => entry is Map && entry['is_earned'] == true)
            .length;
    final totalCount = state.achievements?['total'] ?? rows.length;

    return Scaffold(
      appBar: AppBar(title: const Text('الإنجازات والأوسمة')),
      body: state.achievements == null
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(state.error ?? 'جارٍ تحميل الإنجازات'),
                  TextButton(
                    onPressed: () => ref
                        .read(itqanJourneyProvider.notifier)
                        .refreshAchievements(),
                    child: const Text('إعادة المحاولة'),
                  ),
                ],
              ),
            )
          : rows.isEmpty
              ? const Center(child: Text('لا توجد إنجازات متاحة حالياً.'))
              : ListView(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text('المكتسب: $earnedCount / $totalCount'),
                    ),
                    ...rows.whereType<Map>().map((entry) {
                      final achievement = Map<String, dynamic>.from(entry);
                      final isEarned = achievement['is_earned'] == true;
                      return ListTile(
                        leading: Icon(
                          isEarned ? Icons.military_tech : Icons.lock_outline,
                          color: isEarned
                              ? Theme.of(context).colorScheme.primary
                              : Theme.of(context).disabledColor,
                        ),
                        title: Text('${achievement['title'] ?? ''}'),
                        subtitle: Text(
                          '${achievement['description'] ?? ''}\n'
                          '${isEarned ? achievement['earned_at'] ?? 'مكتسب' : 'لم يُكتسب بعد'}',
                        ),
                      );
                    }),
                  ],
                ),
    );
  }
}
