import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../application/gamification_provider.dart';
import '../screens/journey_screen.dart';

class JourneyBanner extends ConsumerWidget {
  const JourneyBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(gamificationProvider);
    if (state.profile == null && state.error == null) {
      return Card(
        color: Theme.of(context).colorScheme.primary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: ListTile(
          leading: const Icon(Icons.auto_stories_rounded,
              color: Colors.white, size: 34),
          title: const Text('رحلتك إلى الأفضل',
              style: TextStyle(color: Colors.white)),
          subtitle: const Text('افتح الرحلة لعرض مستواك ونقاطك ومهامك',
              style: TextStyle(color: Colors.white70)),
          trailing: TextButton(
            onPressed: () => Navigator.push(context,
                MaterialPageRoute<void>(builder: (_) => const JourneyScreen())),
            child: const Text('متابعة', style: TextStyle(color: Colors.white)),
          ),
        ),
      );
    }
    if (state.loading && state.profile == null) {
      return const Card(
          child: SizedBox(
              height: 150, child: Center(child: CircularProgressIndicator())));
    }
    if (state.error != null && state.profile == null) {
      return Card(
          child: ListTile(
        title: const Text('تعذر تحميل رحلتك'),
        subtitle: Text(state.error!),
        trailing: IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.read(gamificationProvider.notifier).loadAll()),
      ));
    }
    final profile = state.profile;
    if (profile == null) return const SizedBox.shrink();
    final level = profile.level;
    final done = state.tasks?.completed ?? profile.tasksCompleted;
    final count = state.tasks?.total ?? profile.tasksTotal;
    final progress = ((level?.progressPercentage ?? 0) / 100).clamp(0.0, 1.0);
    return Card(
      color: Theme.of(context).colorScheme.primary,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            const Icon(Icons.auto_stories_rounded,
                color: Colors.white, size: 34),
            const SizedBox(width: 12),
            Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Text('رحلتك إلى الأفضل',
                      style: Theme.of(context)
                          .textTheme
                          .titleLarge
                          ?.copyWith(color: Colors.white)),
                  Text(
                      'المستوى ${level?.number ?? '—'} • ${level?.title ?? ''}',
                      style: const TextStyle(color: Colors.white70)),
                ])),
            Text('${profile.totalXp} XP',
                style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold)),
          ]),
          const SizedBox(height: 14),
          LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.white24,
              color: Colors.white),
          const SizedBox(height: 8),
          Row(children: [
            Expanded(
                child: Text('المهام المكتملة: $done / $count',
                    style: const TextStyle(color: Colors.white))),
            TextButton(
              onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute<void>(
                      builder: (_) => const JourneyScreen())),
              child: const Text('تابع الرحلة',
                  style: TextStyle(color: Colors.white)),
            ),
          ]),
        ]),
      ),
    );
  }
}
