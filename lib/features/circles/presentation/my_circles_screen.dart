import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/colors.dart';
import '../domain/circles_providers.dart';
import 'create_circle_screen.dart';
import 'join_circle_screen.dart';
import 'circle_dashboard_screen.dart';
import 'owner_dashboard_screen.dart';
import 'my_tasks_screen.dart';
import 'widgets/circle_card.dart';
import 'widgets/empty_state.dart';

class MyCirclesScreen extends ConsumerStatefulWidget {
  const MyCirclesScreen({super.key});

  @override
  ConsumerState<MyCirclesScreen> createState() => _MyCirclesScreenState();
}

class _MyCirclesScreenState extends ConsumerState<MyCirclesScreen> {
  @override
  Widget build(BuildContext context) {
    final circlesState = ref.watch(myCirclesProvider);
    final hasOwned = ref.watch(hasOwnedCirclesProvider);

    return Scaffold(
      backgroundColor: ItqanColors.cream,
      appBar: AppBar(
        backgroundColor: ItqanColors.cream,
        elevation: 0,
        title: const Text(
          'دوائري',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: ItqanColors.ink,
          ),
        ),
        actions: [
          // Button to open MyTasksScreen
          IconButton(
            tooltip: 'مهامي في الدوائر',
            icon: const Icon(Icons.assignment_turned_in_outlined,
                color: ItqanColors.emerald),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const MyTasksScreen()),
              );
            },
          ),
          // If user owns at least one circle, show Leader Dashboard shortcut
          if (hasOwned)
            IconButton(
              tooltip: 'لوحة القائد',
              icon: const Icon(Icons.admin_panel_settings_outlined,
                  color: ItqanColors.roseGold),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const OwnerDashboardScreen()),
                );
              },
            ),
        ],
      ),
      body: circlesState.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: ItqanColors.emerald),
        ),
        error: (error, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline_rounded,
                    size: 48, color: ItqanColors.error),
                const SizedBox(height: 16),
                Text(
                  error.toString(),
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: ItqanColors.inkSoft),
                ),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: () =>
                      ref.read(myCirclesProvider.notifier).refresh(),
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('إعادة المحاولة'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ItqanColors.emerald,
                    foregroundColor: ItqanColors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
        data: (circles) {
          if (circles.isEmpty) {
            return RefreshIndicator(
              color: ItqanColors.emerald,
              onRefresh: () => ref.read(myCirclesProvider.notifier).refresh(),
              child: CirclesEmptyState(
                onCreateTap: () => _openCreateCircle(context),
                onJoinTap: () => _openJoinCircle(context),
              ),
            );
          }

          return RefreshIndicator(
            color: ItqanColors.emerald,
            onRefresh: () => ref.read(myCirclesProvider.notifier).refresh(),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 88),
              children: [
                // Top Bar / Welcome banner with circle count
                _buildTopHeader(context, circles.length),
                const SizedBox(height: 16),

                // Circles list
                ...circles.map(
                  (circle) => CircleCard(
                    circle: circle,
                    onTap: () => _openDashboard(context, circle, 0),
                    onDashboardTap: () => _openDashboard(context, circle, 0),
                    onMembersTap: () => _openDashboard(context, circle, 1),
                    onTasksTap: () => _openDashboard(context, circle, 2),
                    onWhispersTap: () => _openDashboard(context, circle, 3),
                  ),
                ),
              ],
            ),
          );
        },
      ),
      floatingActionButton: _buildFABs(context),
    );
  }

  Widget _buildTopHeader(BuildContext context, int count) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        color: ItqanColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: ItqanColors.border),
        boxShadow: [
          BoxShadow(
            color: ItqanColors.ink.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: ItqanColors.emerald.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.diversity_3_rounded,
              color: ItqanColors.emerald,
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'أهلاً بك في دوائرك الإيمانية',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: ItqanColors.ink,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'لديك $count ${count == 1 ? "دائرة نشطة" : "دوائر نشطة"} في رحلتك',
                  style: const TextStyle(
                    fontSize: 13,
                    color: ItqanColors.inkSoft,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFABs(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        // Join Button FAB
        FloatingActionButton.extended(
          heroTag: 'joinCircleFAB',
          onPressed: () => _openJoinCircle(context),
          backgroundColor: ItqanColors.surface,
          foregroundColor: ItqanColors.emerald,
          elevation: 2,
          icon: const Icon(Icons.key_rounded, size: 18),
          label: const Text(
            'انضمام بكود',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(width: 12),
        // Create Button FAB
        FloatingActionButton.extended(
          heroTag: 'createCircleFAB',
          onPressed: () => _openCreateCircle(context),
          backgroundColor: ItqanColors.emerald,
          foregroundColor: ItqanColors.white,
          elevation: 3,
          icon: const Icon(Icons.add_rounded, size: 20),
          label: const Text(
            'إنشاء دائرة',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }

  Future<void> _openCreateCircle(BuildContext context) async {
    final created = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const CreateCircleScreen()),
    );
    if (created == true && mounted) {
      ref.read(myCirclesProvider.notifier).refresh();
    }
  }

  Future<void> _openJoinCircle(BuildContext context) async {
    final joined = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const JoinCircleScreen()),
    );
    if (joined == true && mounted) {
      ref.read(myCirclesProvider.notifier).refresh();
    }
  }

  void _openDashboard(BuildContext context, Circle circle, int initialTab) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CircleDashboardScreen(
          circle: circle,
          initialTab: initialTab,
        ),
      ),
    ).then((_) {
      if (mounted) {
        ref.read(myCirclesProvider.notifier).refresh();
      }
    });
  }
}

