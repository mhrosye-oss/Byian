import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/colors.dart';
import '../../application/circle_providers.dart';
import '../../domain/circle_models.dart';

class OwnerDashboardScreen extends ConsumerWidget {
  const OwnerDashboardScreen({super.key, this.onOpenCircle});

  /// The host may provide navigation without coupling this feature to a
  /// particular dashboard route or screen implementation.
  final ValueChanged<Circle>? onOpenCircle;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final circlesAsync = ref.watch(myCirclesProvider);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: ItqanColors.cream,
        appBar: AppBar(
          backgroundColor: ItqanColors.cream,
          foregroundColor: ItqanColors.ink,
          elevation: 0,
          centerTitle: false,
          title: const Text(
            'لوحة إدارة الدوائر',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
        body: circlesAsync.when(
          loading: () => const Center(
            child: CircularProgressIndicator(color: ItqanColors.emerald),
          ),
          error: (error, stackTrace) => _DashboardMessage(
            icon: Icons.cloud_off_outlined,
            title: 'تعذر تحميل الدوائر',
            message: 'تحقق من اتصالك ثم حاول مرة أخرى.',
            actionLabel: 'إعادة المحاولة',
            onAction: () => ref.invalidate(myCirclesProvider),
          ),
          data: (circles) {
            final ownedCircles = circles
                .where((circle) => circle.myRole == 'owner')
                .toList(growable: false);

            if (ownedCircles.isEmpty) {
              return const _DashboardMessage(
                icon: Icons.groups_2_outlined,
                title: 'لا توجد دوائر تديرها',
                message: 'ستظهر هنا الدوائر التي يكون دورك فيها مالكًا.',
              );
            }

            return ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
              children: [
                Text(
                  'دوائرك المملوكة (${ownedCircles.length})',
                  style: const TextStyle(
                    color: ItqanColors.inkSoft,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 14),
                for (final circle in ownedCircles) ...[
                  _OwnerCircleCard(
                    circle: circle,
                    onOpenCircle: onOpenCircle,
                  ),
                  const SizedBox(height: 14),
                ],
              ],
            );
          },
        ),
      ),
    );
  }
}

class _OwnerCircleCard extends StatefulWidget {
  const _OwnerCircleCard({
    required this.circle,
    required this.onOpenCircle,
  });

  final Circle circle;
  final ValueChanged<Circle>? onOpenCircle;

  @override
  State<_OwnerCircleCard> createState() => _OwnerCircleCardState();
}

class _OwnerCircleCardState extends State<_OwnerCircleCard> {
  late Future<_CircleStats> _statsFuture;

  @override
  void initState() {
    super.initState();
    _statsFuture = _loadStats();
  }

  @override
  void didUpdateWidget(covariant _OwnerCircleCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.circle.uuid != widget.circle.uuid) {
      _statsFuture = _loadStats();
    }
  }

  Future<_CircleStats> _loadStats() async {
    final api = ProviderScope.containerOf(context, listen: false)
        .read(circleApiClientProvider);
    final results = await Future.wait<List<Map<String, dynamic>>>([
      api.getMembers(widget.circle.uuid),
      api.getCircleTasks(widget.circle.uuid),
      api.getActivities(widget.circle.uuid),
    ]);
    final activities =
        results[2].map(CircleActivity.fromJson).toList(growable: false);

    return _CircleStats(
      memberCount: results[0].length,
      taskCount: results[1].length,
      activities: activities,
    );
  }

  void _retryStats() {
    setState(() {
      _statsFuture = _loadStats();
    });
  }

  @override
  Widget build(BuildContext context) {
    final openCircle = widget.onOpenCircle;

    return Card(
      color: ItqanColors.surface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        side: const BorderSide(color: ItqanColors.border),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: ItqanColors.surfaceSoft,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.groups_outlined,
                    color: ItqanColors.emerald,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.circle.name,
                        style: const TextStyle(
                          color: ItqanColors.ink,
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if ((widget.circle.description ?? '').trim().isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            widget.circle.description!,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: ItqanColors.inkSoft,
                              fontSize: 13,
                              height: 1.4,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            FutureBuilder<_CircleStats>(
              future: _statsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Center(
                      child: SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: ItqanColors.emerald,
                        ),
                      ),
                    ),
                  );
                }

                if (snapshot.hasError || !snapshot.hasData) {
                  return _StatsError(onRetry: _retryStats);
                }

                final stats = snapshot.data!;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _StatItem(
                            icon: Icons.person_outline,
                            label: 'الأعضاء',
                            value: stats.memberCount,
                          ),
                        ),
                        const _StatDivider(),
                        Expanded(
                          child: _StatItem(
                            icon: Icons.checklist_outlined,
                            label: 'المهام',
                            value: stats.taskCount,
                          ),
                        ),
                        const _StatDivider(),
                        Expanded(
                          child: _StatItem(
                            icon: Icons.history_outlined,
                            label: 'النشاط',
                            value: stats.activities.length,
                          ),
                        ),
                      ],
                    ),
                    if (stats.activities.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      const Text(
                        'النشاط الأخير',
                        style: TextStyle(
                          color: ItqanColors.ink,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 6),
                      ...stats.activities.take(3).map(
                            (activity) => ListTile(
                              dense: true,
                              contentPadding: EdgeInsets.zero,
                              leading: const Icon(
                                Icons.bolt_rounded,
                                size: 18,
                                color: ItqanColors.emerald,
                              ),
                              title: Text(
                                activity.description ??
                                    activity.type ??
                                    'نشاط جديد',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              subtitle: activity.actorName == null
                                  ? null
                                  : Text(activity.actorName!),
                            ),
                          ),
                    ],
                  ],
                );
              },
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: openCircle == null
                        ? null
                        : () => openCircle(widget.circle),
                    icon: const Icon(Icons.settings_outlined, size: 18),
                    label: const Text('إدارة الدائرة'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: ItqanColors.emerald,
                      disabledForegroundColor: ItqanColors.muted,
                      side: const BorderSide(color: ItqanColors.border),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Tooltip(
                    message:
                        'لم يرد endpoint لإرسال إشعار جماعي في عقد API المتاح.',
                    child: OutlinedButton.icon(
                      onPressed: null,
                      icon: const Icon(Icons.notifications_active_outlined,
                          size: 18),
                      label: const Text('إرسال إشعار'),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _CircleStats {
  const _CircleStats({
    required this.memberCount,
    required this.taskCount,
    required this.activities,
  });

  final int memberCount;
  final int taskCount;
  final List<CircleActivity> activities;
}

class _StatItem extends StatelessWidget {
  const _StatItem({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final int value;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, size: 18, color: ItqanColors.emerald),
        const SizedBox(height: 6),
        Text(
          '$value',
          style: const TextStyle(
            color: ItqanColors.ink,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(color: ItqanColors.inkSoft, fontSize: 12),
        ),
      ],
    );
  }
}

class _StatDivider extends StatelessWidget {
  const _StatDivider();

  @override
  Widget build(BuildContext context) => Container(
        height: 48,
        width: 1,
        color: ItqanColors.border,
      );
}

class _StatsError extends StatelessWidget {
  const _StatsError({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: ItqanColors.surfaceSoft,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Expanded(
            child: Text(
              'تعذر تحميل إحصاءات الدائرة.',
              style: TextStyle(color: ItqanColors.inkSoft, fontSize: 13),
            ),
          ),
          TextButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh, size: 17),
            label: const Text('إعادة'),
            style: TextButton.styleFrom(foregroundColor: ItqanColors.emerald),
          ),
        ],
      ),
    );
  }
}

class _DashboardMessage extends StatelessWidget {
  const _DashboardMessage({
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: ItqanColors.emerald),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: ItqanColors.ink,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: ItqanColors.inkSoft,
                height: 1.5,
              ),
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 18),
              FilledButton.icon(
                onPressed: onAction,
                icon: const Icon(Icons.refresh),
                label: Text(actionLabel!),
                style: FilledButton.styleFrom(
                  backgroundColor: ItqanColors.emerald,
                  foregroundColor: ItqanColors.white,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
