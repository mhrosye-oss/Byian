import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/colors.dart';
import '../../application/circle_providers.dart';
import '../../domain/circle_models.dart';
import 'circle_dashboard_screen.dart';
import 'create_circle_screen.dart';
import 'join_circle_screen.dart';

class MyCirclesScreen extends ConsumerWidget {
  const MyCirclesScreen({super.key, required this.user});

  final AppUser user;

  Future<void> _openForm(
      BuildContext context, Widget screen, WidgetRef ref) async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(builder: (_) => screen),
    );
    if (changed == true) ref.invalidate(myCirclesProvider);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final circles = ref.watch(myCirclesProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('دوائري'),
        actions: [
          IconButton(
            tooltip: 'خدمات إتقان',
            onPressed: () => context.push('/itqan-home'),
            icon: const Icon(Icons.apps_rounded),
          ),
          IconButton(
            tooltip: 'تحديث',
            onPressed: () => ref.invalidate(myCirclesProvider),
            icon: const Icon(Icons.refresh_rounded),
          ),
          IconButton(
            tooltip: 'الانضمام بكود دعوة',
            onPressed: () => _openForm(
              context,
              const JoinCircleScreen(),
              ref,
            ),
            icon: const Icon(Icons.key_rounded),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openForm(context, const CreateCircleScreen(), ref),
        backgroundColor: ItqanColors.emerald,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text('إنشاء دائرة'),
      ),
      body: SafeArea(
        child: circles.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => _ErrorState(
            message: 'تعذر تحميل الدوائر: $error',
            onRetry: () => ref.invalidate(myCirclesProvider),
            onJoin: () => _openForm(
              context,
              const JoinCircleScreen(),
              ref,
            ),
          ),
          data: (items) => RefreshIndicator(
            onRefresh: () async => ref.invalidate(myCirclesProvider),
            child: items.isEmpty
                ? _EmptyState(
                    userName: user.name,
                    onCreate: () => _openForm(
                      context,
                      const CreateCircleScreen(),
                      ref,
                    ),
                    onJoin: () => _openForm(
                      context,
                      const JoinCircleScreen(),
                      ref,
                    ),
                  )
                : ListView(
                    padding: const EdgeInsets.fromLTRB(18, 8, 18, 108),
                    children: [
                      _Greeting(user: user, circlesCount: items.length),
                      const SizedBox(height: 18),
                      Row(
                        children: [
                          Expanded(
                            child: FilledButton.icon(
                              onPressed: () => _openForm(
                                context,
                                const CreateCircleScreen(),
                                ref,
                              ),
                              icon: const Icon(Icons.add_rounded),
                              label: const Text('إنشاء'),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () => _openForm(
                                context,
                                const JoinCircleScreen(),
                                ref,
                              ),
                              icon: const Icon(Icons.key_rounded),
                              label: const Text('انضمام بدعوة'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 22),
                      Text(
                        'دوائرك',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                      const SizedBox(height: 10),
                      ...items.map(
                        (circle) => _CircleCard(
                          circle: circle,
                          onOpen: () => Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) =>
                                  CircleDashboardScreen(circle: circle),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

class _Greeting extends StatelessWidget {
  const _Greeting({required this.user, required this.circlesCount});
  final AppUser user;
  final int circlesCount;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: ItqanColors.emerald,
          borderRadius: BorderRadius.circular(22),
        ),
        child: Row(
          children: [
            const CircleAvatar(
              backgroundColor: Colors.white24,
              child: Icon(Icons.waving_hand_rounded, color: Colors.white),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'مرحبًا، ${user.name}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '$circlesCount دوائر في مساحتك',
                    style: const TextStyle(color: Colors.white70),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
}

class _CircleCard extends StatelessWidget {
  const _CircleCard({required this.circle, required this.onOpen});
  final Circle circle;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final owner = circle.isOwner;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: ItqanColors.emerald.withOpacity(.10),
                  foregroundColor: ItqanColors.emerald,
                  child: Icon(owner
                      ? Icons.workspace_premium_rounded
                      : Icons.groups_rounded),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        circle.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w800,
                                ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '${circle.type?.name ?? 'دائرة'} · ${circle.membersCount} أعضاء',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: ItqanColors.inkSoft,
                            ),
                      ),
                    ],
                  ),
                ),
                _RoleBadge(label: owner ? 'قائد' : 'عضو', owner: owner),
              ],
            ),
            if (circle.description?.isNotEmpty == true) ...[
              const SizedBox(height: 10),
              Text(
                circle.description!,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: ItqanColors.inkSoft,
                    ),
              ),
            ],
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: owner
                  ? FilledButton.icon(
                      onPressed: onOpen,
                      icon: const Icon(Icons.dashboard_rounded),
                      label: const Text('لوحة التحكم'),
                    )
                  : OutlinedButton.icon(
                      onPressed: onOpen,
                      icon: const Icon(Icons.task_alt_rounded),
                      label: const Text('المهام وتفاصيل الدائرة'),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RoleBadge extends StatelessWidget {
  const _RoleBadge({required this.label, required this.owner});
  final String label;
  final bool owner;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
        decoration: BoxDecoration(
          color: owner
              ? ItqanColors.emerald.withOpacity(.10)
              : ItqanColors.surfaceSoft,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: owner ? ItqanColors.emerald : ItqanColors.inkSoft,
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
      );
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.userName,
    required this.onCreate,
    required this.onJoin,
  });
  final String userName;
  final VoidCallback onCreate;
  final VoidCallback onJoin;

  @override
  Widget build(BuildContext context) => ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(24, 52, 24, 120),
        children: [
          const Icon(Icons.diversity_3_rounded,
              size: 72, color: ItqanColors.emerald),
          const SizedBox(height: 14),
          Text(
            'أهلًا $userName',
            textAlign: TextAlign.center,
            style: Theme.of(context)
                .textTheme
                .titleLarge
                ?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          const Text('لم تنضم إلى أي دائرة بعد. أنشئ دائرة أو انضم بدعوة.',
              textAlign: TextAlign.center),
          const SizedBox(height: 24),
          FilledButton.icon(
              onPressed: onCreate,
              icon: const Icon(Icons.add),
              label: const Text('إنشاء دائرة جديدة')),
          const SizedBox(height: 10),
          OutlinedButton.icon(
              onPressed: onJoin,
              icon: const Icon(Icons.key),
              label: const Text('الانضمام بكود دعوة')),
        ],
      );
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({
    required this.message,
    required this.onRetry,
    required this.onJoin,
  });
  final String message;
  final VoidCallback onRetry;
  final VoidCallback onJoin;

  @override
  Widget build(BuildContext context) => ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24),
        children: [
          const SizedBox(height: 100),
          const Icon(Icons.cloud_off_outlined,
              size: 56, color: ItqanColors.muted),
          const SizedBox(height: 14),
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              OutlinedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('إعادة المحاولة'),
              ),
              const SizedBox(width: 10),
              FilledButton.icon(
                onPressed: onJoin,
                icon: const Icon(Icons.key_rounded),
                label: const Text('الانضمام بدعوة'),
              ),
            ],
          ),
        ],
      );
}
