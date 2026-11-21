import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/widgets/itqan_points_icon.dart';
import '../../application/itqan_journey_provider.dart';
import '../../domain/itqan_tasks_registry.dart';
import '../../quran_journey/presentation/quran_journey_screen.dart';
import '../../adhkar_journey/presentation/adhkar_journey_screen.dart';
import '../../dua_journey/presentation/dua_journey_screen.dart';
import '../../share_journey/presentation/share_journey_screen.dart';
import '../../social_share/presentation/share_card_generator_screen.dart';
import '../../referral/presentation/referral_card_widget.dart';
import '../../../tasbih/screens/smart_tasbih_screen.dart';
import '../../../khatmah/screens/khatmah_screen.dart';
import '../../../tafsir/screens/tafsir_screen.dart';
import 'itqan_journey_progress.dart';
import '../widgets/itqan_world_canvas.dart';
import '../widgets/itqan_zone_widget.dart';

class ItqanWorldScreen extends ConsumerStatefulWidget {
  const ItqanWorldScreen({super.key});

  @override
  ConsumerState<ItqanWorldScreen> createState() => _ItqanWorldScreenState();
}

class _ItqanWorldScreenState extends ConsumerState<ItqanWorldScreen> {
  ItqanZone _activeZone = ItqanZone.quranOasis;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      final state = ref.read(itqanJourneyProvider);
      if (state.profile == null && !state.loading) {
        ref.read(itqanJourneyProvider.notifier).loadAll();
      }
    });
  }

  void _onTaskSelected(ItqanTaskDefinition task) {
    switch (task.route) {
      case 'quran_wird':
      case 'quran_journey':
        Navigator.push(context,
            MaterialPageRoute(builder: (_) => const QuranJourneyScreen()));
        break;
      case 'khatmah':
        Navigator.push(
            context, MaterialPageRoute(builder: (_) => const KhatmahScreen()));
        break;
      case 'tafsir':
        Navigator.push(
            context, MaterialPageRoute(builder: (_) => const TafsirScreen()));
        break;
      case 'adhkar_morning':
      case 'adhkar_evening':
      case 'adhkar_prayer':
        Navigator.push(context,
            MaterialPageRoute(builder: (_) => const AdhkarJourneyScreen()));
        break;
      case 'tasbih':
        Navigator.push(context,
            MaterialPageRoute(builder: (_) => const SmartTasbihScreen()));
        break;
      case 'dua_journey':
      case 'duas_occasions':
      case 'dua_bookmarks':
        Navigator.push(context,
            MaterialPageRoute(builder: (_) => const DuaJourneyScreen()));
        break;
      case 'share_card_generator':
        Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) => const ShareCardGeneratorScreen()));
        break;
      case 'share_journey':
        Navigator.push(context,
            MaterialPageRoute(builder: (_) => const ShareJourneyScreen()));
        break;
      case 'referral_section':
        _showReferralDialog();
        break;
      default:
        Navigator.push(context,
            MaterialPageRoute(builder: (_) => const QuranJourneyScreen()));
    }
  }

  void _showReferralDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Color(0xFFF9F6F0),
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: const SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(height: 10),
              ReferralCardWidget(),
              SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(itqanJourneyProvider);
    final stats = state.profile?['stats'] as Map<String, dynamic>?;
    final level = stats?['level'] as Map<String, dynamic>?;
    final totalPoints = stats?['total_xp'] ?? 0;
    final currentStreak = stats?['current_streak'] ?? 0;
    final journeyProgress =
        itqanJourneyProgressRatio(state.journey, state.tasks);

    return Scaffold(
      backgroundColor: const Color(0xFFF9F6F0),
      appBar: AppBar(
        title: const Text(
          'عالم إتقان والرحلة الإيمانية',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            tooltip: 'تحديث الرحلة',
            icon: const Icon(Icons.refresh_rounded, color: Color(0xFF0A5C36)),
            onPressed: () => ref.read(itqanJourneyProvider.notifier).loadAll(),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // شريط الهيدر التحفيزي
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF0A5C36), Color(0xFF147A49)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x260A5C36),
                    blurRadius: 12,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                textDirection: TextDirection.rtl,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'المستوى ${level?['number'] ?? 1} • ${level?['title'] ?? 'المبتدئ'}',
                        style: const TextStyle(
                          color: Color(0xFFFFF4D0),
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                        textDirection: TextDirection.rtl,
                      ),
                      const SizedBox(height: 6),
                      Row(
                        textDirection: TextDirection.rtl,
                        children: [
                          const ItqanPointsIcon(size: 16),
                          const SizedBox(width: 6),
                          Text(
                            '$totalPoints نقطة إتقان',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                            textDirection: TextDirection.rtl,
                          ),
                        ],
                      ),
                    ],
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                          color:
                              const Color(0xFFD4AF37).withValues(alpha: 0.5)),
                    ),
                    child: Column(
                      children: [
                        const Icon(Icons.local_fire_department_rounded,
                            color: Color(0xFFFFF4D0), size: 22),
                        const SizedBox(height: 2),
                        Text(
                          '$currentStreak أيام',
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),

            // عنوان لوحة العالم
            Row(
              textDirection: TextDirection.rtl,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'خريطة عالم إتقان التفاعلية',
                  style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF202B24)),
                  textDirection: TextDirection.rtl,
                ),
                Text(
                  'المس المنطقة للاستكشاف',
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                  textDirection: TextDirection.rtl,
                ),
              ],
            ),
            const SizedBox(height: 10),

            // الرسام التفاعلي لعالم إتقان
            ItqanWorldCanvas(
              overallProgress: journeyProgress ?? 0,
              activeZone: _activeZone,
              onZoneSelected: (zone) {
                setState(() => _activeZone = zone);
              },
            ),
            const SizedBox(height: 8),
            Align(
              alignment: AlignmentDirectional.centerEnd,
              child: Text(
                journeyProgress == null
                    ? 'تقدم الرحلة غير متاح حالياً.'
                    : 'إنجاز الرحلة: ${(journeyProgress * 100).round()}٪',
                style: TextStyle(
                  color: journeyProgress == null
                      ? Colors.grey.shade700
                      : const Color(0xFF0A5C36),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 22),

            // قائمة المناطق والمهام العشرين
            const Text(
              'مناطق الرحلة والمهام العشرون:',
              style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF202B24)),
              textDirection: TextDirection.rtl,
            ),
            const SizedBox(height: 12),

            ...ItqanZone.values.map((zone) {
              final tasks = ItqanTasksRegistry.getTasksForZone(zone);
              final isSelected = zone == _activeZone;
              return ItqanZoneWidget(
                zone: zone,
                isSelected: isSelected,
                tasks: tasks,
                onTap: () {
                  setState(() {
                    _activeZone = isSelected ? zone : zone;
                  });
                },
                onTaskTap: _onTaskSelected,
              );
            }),

            const SizedBox(height: 16),
            const ReferralCardWidget(),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}
