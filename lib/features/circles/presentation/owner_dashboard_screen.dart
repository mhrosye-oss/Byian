import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/colors.dart';
import '../domain/circles_providers.dart';
import 'circle_dashboard_screen.dart';
import 'circle_leader_dashboard_screen.dart';
import 'create_circle_screen.dart';

class OwnerDashboardScreen extends ConsumerWidget {
  const OwnerDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ownedCircles = ref.watch(ownedCirclesProvider);
    final totalMembers = ownedCircles.fold<int>(
      0,
      (sum, c) => sum + c.membersCount,
    );

    return Scaffold(
      backgroundColor: ItqanColors.cream,
      appBar: AppBar(
        backgroundColor: ItqanColors.cream,
        elevation: 0,
        title: const Text(
          'لوحة القائد',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: ItqanColors.ink,
          ),
        ),
      ),
      body: ownedCircles.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: ItqanColors.roseGold.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.admin_panel_settings_outlined,
                        color: ItqanColors.roseGold,
                        size: 40,
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'أنت لست مالكاً لأي دائرة بعد',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: ItqanColors.ink,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'أنشئ دائرة جديدة لتصبح قائداً لها وتدير مهامها وأعضاءها من هذه اللوحة.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: ItqanColors.inkSoft,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const CreateCircleScreen()),
                        );
                      },
                      icon: const Icon(Icons.add_rounded),
                      label: const Text('إنشاء دائرة جديدة'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: ItqanColors.emerald,
                        foregroundColor: ItqanColors.white,
                      ),
                    ),
                  ],
                ),
              ),
            )
          : RefreshIndicator(
              color: ItqanColors.emerald,
              onRefresh: () => ref.read(myCirclesProvider.notifier).refresh(),
              child: ListView(
                padding: const EdgeInsets.all(18),
                children: [
                  // Header Card
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [ItqanColors.emeraldDark, ItqanColors.emerald],
                        begin: Alignment.topRight,
                        end: Alignment.bottomLeft,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: ItqanColors.emerald.withValues(alpha: 0.25),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.workspace_premium_rounded,
                                color: ItqanColors.white,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Text(
                              'إدارة الدوائر القيادية',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: ItqanColors.white,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        const Text(
                          'تتيح لك لوحة القائد الإشراف الكامل على الدوائر التي أنشأتها ومتابعة تفاعل الأعضاء وإنجاز المهام.',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.white,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 18),
                        Row(
                          children: [
                            _buildWhiteStat(
                                'الدوائر المملوكة', '${ownedCircles.length}'),
                            const SizedBox(width: 24),
                            _buildWhiteStat('إجمالي الأعضاء', '$totalMembers'),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  const Text(
                    'دوائري التي أديرها',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: ItqanColors.ink,
                    ),
                  ),
                  const SizedBox(height: 12),

                  ...ownedCircles.map((circle) => Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: ItqanColors.surface,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: ItqanColors.border),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color:
                                    ItqanColors.roseGold.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.stars_rounded,
                                color: ItqanColors.roseGold,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    circle.name,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: ItqanColors.ink,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${circle.type.name} • ${circle.membersCount} أعضاء',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: ItqanColors.inkSoft,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            ElevatedButton.icon(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => CircleDashboardScreen(
                                      circle: circle,
                                    ),
                                  ),
                                );
                              },
                              icon:
                                  const Icon(Icons.settings_rounded, size: 16),
                              label: const Text('إدارة'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: ItqanColors.emerald,
                                foregroundColor: ItqanColors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                            IconButton(
                              tooltip: 'لوحة القائد',
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => CircleLeaderDashboardScreen(
                                      circle: circle,
                                    ),
                                  ),
                                );
                              },
                              icon: const Icon(Icons.insights_rounded),
                            ),
                          ],
                        ),
                      )),
                ],
              ),
            ),
    );
  }

  Widget _buildWhiteStat(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.white.withValues(alpha: 0.8),
          ),
        ),
      ],
    );
  }
}
