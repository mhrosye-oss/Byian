import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/auth_service.dart';
import '../application/itqan_journey_provider.dart';
import 'achievements_screen.dart';

class JourneyProfileScreen extends ConsumerStatefulWidget {
  const JourneyProfileScreen({super.key});

  @override
  ConsumerState<JourneyProfileScreen> createState() =>
      _JourneyProfileScreenState();
}

class _JourneyProfileScreenState extends ConsumerState<JourneyProfileScreen> {
  Map<String, String>? user;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      user = await AuthService.getUser();
      if (mounted) setState(() {});
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تعذر تحميل بيانات المستخدم المحلية.')),
        );
      }
    }
    if (mounted) {
      await ref.read(itqanJourneyProvider.notifier).refreshProfile();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(itqanJourneyProvider);
    final profile = state.profile;
    final stats = profile?['stats'] as Map?;
    final level = stats?['level'] as Map?;
    final achievements = stats?['achievements'] as Map?;
    final streak = stats?['streak'] as Map?;
    final tasks = stats?['tasks'] as Map?;
    final pillars = stats?['pillars'] as Map?;
    final progress =
        (((level?['progress_percentage'] as num?)?.toDouble() ?? 0) / 100)
            .clamp(0.0, 1.0);
    final profileUser = profile?['user'] as Map?;
    final displayName = user?['name'] ?? profileUser?['name']?.toString() ?? '';
    final initial = displayName.isEmpty ? '؟' : displayName.characters.first;

    return Scaffold(
      appBar: AppBar(title: const Text('ملفي الشخصي')),
      body: profile == null
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(state.error ?? 'جارٍ تحميل الملف الشخصي'),
                  TextButton(
                    onPressed: () => ref
                        .read(itqanJourneyProvider.notifier)
                        .refreshProfile(),
                    child: const Text('إعادة المحاولة'),
                  ),
                ],
              ),
            )
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Card(
                  child: ListTile(
                    leading: CircleAvatar(child: Text(initial)),
                    title: Text(displayName),
                    subtitle: Text(user?['email'] ?? ''),
                  ),
                ),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                            'المستوى ${level?['number'] ?? '—'} • ${level?['title'] ?? ''}'),
                        Text('${stats?['total_xp'] ?? '—'} XP'),
                        Text('${stats?['total_coins'] ?? '—'} Coins'),
                        const SizedBox(height: 8),
                        LinearProgressIndicator(value: progress),
                        Text(
                            'الحد التالي: ${level?['next_threshold'] ?? '—'} • المتبقي: ${level?['xp_to_next_level'] ?? '—'} XP'),
                      ],
                    ),
                  ),
                ),
                ListTile(
                  title: const Text('الأوسمة المكتسبة'),
                  trailing: Text(
                      '${achievements?['earned'] ?? '—'} / ${achievements?['total'] ?? '—'}'),
                ),
                ListTile(
                  title: const Text('سلسلة الاستمرارية'),
                  subtitle: Text(
                      'الحالية ${streak?['current'] ?? '—'} • الأطول ${streak?['longest'] ?? '—'}'),
                ),
                ListTile(
                  title: const Text('المهام المكتملة'),
                  subtitle: Text(
                      '${tasks?['completed_total'] ?? '—'} / ${tasks?['total_available'] ?? '—'}'),
                ),
                if (pillars is Map)
                  ...pillars.entries.map(
                    (entry) => ListTile(
                      title: Text('${entry.key}'),
                      subtitle: Text('${entry.value}'),
                    ),
                  ),
                OutlinedButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute<void>(
                      builder: (_) => const JourneyAchievementsScreen(),
                    ),
                  ),
                  child: const Text('سجل الإنجازات'),
                ),
              ],
            ),
    );
  }
}
