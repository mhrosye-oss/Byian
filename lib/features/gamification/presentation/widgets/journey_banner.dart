import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../itqan_journey/application/itqan_journey_provider.dart';
import '../../../itqan_journey/presentation/journey_dashboard_screen.dart';

class JourneyBanner extends ConsumerStatefulWidget {
  const JourneyBanner({super.key});

  @override
  ConsumerState<JourneyBanner> createState() => _JourneyBannerState();
}

class _JourneyBannerState extends ConsumerState<JourneyBanner>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    Future.microtask(() => ref.read(itqanJourneyProvider.notifier).loadAll());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      ref.read(itqanJourneyProvider.notifier).loadAll();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(itqanJourneyProvider);
    final profile = state.profile;
    if (state.loading && profile == null) {
      return const Card(
        child: SizedBox(
          height: 118,
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }
    if (state.error != null && profile == null) {
      return Card(
        child: ListTile(
          title: const Text('تعذر تحميل رحلتك'),
          subtitle: Text(state.error!),
          trailing: IconButton(
            tooltip: 'إعادة المحاولة',
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.read(itqanJourneyProvider.notifier).loadAll(),
          ),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute<void>(
              builder: (_) => const JourneyDashboardScreen(),
            ),
          ),
        ),
      );
    }
    if (profile == null) return const SizedBox.shrink();

    final stats = profile['stats'] is Map ? profile['stats'] as Map : const {};
    final level = stats['level'] is Map ? stats['level'] as Map : const {};
    final rawProgress = level['progress_percentage'];
    final progress = rawProgress is num
        ? (rawProgress.toDouble() / 100).clamp(0.0, 1.0)
        : null;
    final journey = state.journey;
    final rawStage = journey?['current_stage'];
    final currentStage = rawStage is Map ? rawStage : const {};
    final stageTitle = currentStage['name'] ?? currentStage['title'];

    return Card(
      color: Theme.of(context).colorScheme.primary,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute<void>(
            builder: (_) => const JourneyDashboardScreen(),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Directionality(
            textDirection: TextDirection.rtl,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.auto_stories_rounded,
                        color: Colors.white, size: 32),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'رحلتك إلى الأفضل',
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(color: Colors.white),
                          ),
                          Text(
                            'المستوى ${level['number'] ?? '—'} • ${level['title'] ?? ''}',
                            style: const TextStyle(color: Colors.white70),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text('${stats['total_xp'] ?? '—'} XP',
                            style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold)),
                        Text('${stats['total_coins'] ?? '—'} Coins',
                            style: const TextStyle(color: Colors.white70)),
                      ],
                    ),
                  ],
                ),
                if (progress != null) ...[
                  const SizedBox(height: 14),
                  LinearProgressIndicator(
                    value: progress,
                    backgroundColor: Colors.white24,
                    color: Colors.white,
                  ),
                ],
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        stageTitle == null
                            ? 'افتح الرحلة لمتابعة تقدمك ومهامك'
                            : 'المرحلة الحالية: $stageTitle',
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                    const Icon(Icons.chevron_left, color: Colors.white),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
