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
    final earned = rows
        .where((entry) => entry is Map && entry['is_earned'] == true)
        .toList();

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
          : earned.isEmpty
              ? const Center(child: Text('لم تحصل على أوسمة بعد'))
              : ListView(
                  children: earned.map((entry) {
                    final achievement = Map<String, dynamic>.from(entry as Map);
                    return ListTile(
                      leading: const Icon(Icons.military_tech),
                      title: Text('${achievement['title'] ?? ''}'),
                      subtitle: Text(
                        '${achievement['description'] ?? ''}\n'
                        '${achievement['earned_at'] ?? ''}',
                      ),
                    );
                  }).toList(),
                ),
    );
  }
}
