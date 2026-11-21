import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/auth_service.dart';
import '../../../shared/widgets/itqan_points_icon.dart';
import '../application/itqan_journey_provider.dart';
import '../referral/presentation/referral_card_widget.dart';
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
    final displayName = user?['name'] ?? profileUser?['name']?.toString() ?? 'مسافر إتقان';
    final initial = displayName.isEmpty ? '؟' : displayName.characters.first;
    final totalPoints = stats?['total_xp'] ?? 0;
    final remainingPoints = level?['xp_to_next_level'] ?? 0;

    return Scaffold(
      backgroundColor: const Color(0xFFF9F6F0),
      appBar: AppBar(
        title: const Text('ملفي الشخصي في إتقان', style: TextStyle(fontWeight: FontWeight.w700)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: profile == null
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(state.error ?? 'جارٍ تحميل الملف الشخصي'),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: () => ref
                        .read(itqanJourneyProvider.notifier)
                        .refreshProfile(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0A5C36),
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('إعادة المحاولة'),
                  ),
                ],
              ),
            )
          : ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              children: [
                // كارد المستخدم
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: const Color(0xFFE7E0D5)),
                    boxShadow: const [
                      BoxShadow(color: Color(0x0A000000), blurRadius: 10, offset: Offset(0, 3)),
                    ],
                  ),
                  child: Row(
                    textDirection: TextDirection.rtl,
                    children: [
                      CircleAvatar(
                        radius: 28,
                        backgroundColor: const Color(0xFF0A5C36),
                        child: Text(
                          initial,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFFFF4D0),
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              displayName,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF202B24),
                              ),
                              textDirection: TextDirection.rtl,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              user?['email'] ?? 'رحلة إتقان الإيمانية',
                              style: const TextStyle(fontSize: 12, color: Color(0xFF5F685F)),
                              textDirection: TextDirection.rtl,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // بطاقة المستوى ونقاط إتقان (استبدال XP بأيقونة إتقان)
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: const Color(0xFFD4AF37).withValues(alpha: 0.4)),
                    boxShadow: const [
                      BoxShadow(color: Color(0x0A000000), blurRadius: 10, offset: Offset(0, 3)),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        textDirection: TextDirection.rtl,
                        children: [
                          Text(
                            'المستوى ${level?['number'] ?? 1} • ${level?['title'] ?? 'المبتدئ'}',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF0A5C36),
                            ),
                            textDirection: TextDirection.rtl,
                          ),
                          ItqanPointsBadge(
                            points: totalPoints,
                            iconSize: 18,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF0A5C36),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: LinearProgressIndicator(
                          value: progress,
                          minHeight: 8,
                          backgroundColor: const Color(0xFFE7E0D5),
                          valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFD4AF37)),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        textDirection: TextDirection.rtl,
                        children: [
                          Text(
                            'الحد التالي: ${level?['next_threshold'] ?? '—'}',
                            style: const TextStyle(fontSize: 12, color: Color(0xFF5F685F)),
                            textDirection: TextDirection.rtl,
                          ),
                          Row(
                            textDirection: TextDirection.rtl,
                            children: [
                              const Text(
                                'المتبقي: ',
                                style: TextStyle(fontSize: 12, color: Color(0xFF5F685F)),
                              ),
                              ItqanPointsBadge(points: remainingPoints, iconSize: 12),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // قسم ادعُ صديقاً إلى إتقان (كود الإحالة الحقيقي)
                const ReferralCardWidget(),
                const SizedBox(height: 16),

                // إحصائيات الرحلة
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: const Color(0xFFE7E0D5)),
                  ),
                  child: Column(
                    children: [
                      ListTile(
                        leading: const Icon(Icons.military_tech_rounded, color: Color(0xFFD4AF37)),
                        title: const Text('الأوسمة المكتسبة', textDirection: TextDirection.rtl),
                        trailing: Text(
                          '${achievements?['earned'] ?? 0} / ${achievements?['total'] ?? 0}',
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: const Icon(Icons.local_fire_department_rounded, color: Color(0xFFE65100)),
                        title: const Text('سلسلة الاستمرارية', textDirection: TextDirection.rtl),
                        subtitle: Text(
                          'الحالية ${streak?['current'] ?? 0} أيام • الأطول ${streak?['longest'] ?? 0} أيام',
                          textDirection: TextDirection.rtl,
                        ),
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: const Icon(Icons.task_alt_rounded, color: Color(0xFF0A5C36)),
                        title: const Text('المهام المكتملة', textDirection: TextDirection.rtl),
                        trailing: Text(
                          '${tasks?['completed_total'] ?? 0} / ${tasks?['total_available'] ?? 20}',
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                      if (pillars is Map) ...[
                        const Divider(height: 1),
                        ...pillars.entries.map(
                          (entry) => ListTile(
                            title: Text('${entry.key}', textDirection: TextDirection.rtl),
                            trailing: Text('${entry.value}', style: const TextStyle(fontWeight: FontWeight.w600)),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                ElevatedButton.icon(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute<void>(
                      builder: (_) => const JourneyAchievementsScreen(),
                    ),
                  ),
                  icon: const Icon(Icons.emoji_events_rounded),
                  label: const Text('عرض سجل الأوسمة والإنجازات'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0A5C36),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
                const SizedBox(height: 30),
              ],
            ),
    );
  }
}
