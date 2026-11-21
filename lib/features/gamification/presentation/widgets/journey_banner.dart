import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:itqan/core/services/auth_service.dart';
import 'package:itqan/features/auth/screens/login_screen.dart';
import '../../../itqan_journey/application/itqan_journey_provider.dart';
import '../../../itqan_journey/world/presentation/itqan_world_screen.dart';
import '../../../../core/theme/colors.dart';

class JourneyBanner extends ConsumerStatefulWidget {
  const JourneyBanner({super.key});

  @override
  ConsumerState<JourneyBanner> createState() => _JourneyBannerState();
}

class _JourneyBannerState extends ConsumerState<JourneyBanner>
    with WidgetsBindingObserver {
  bool _isGuest = true;
  bool _checkingSession = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    Future.microtask(_refreshSessionAndJourney);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _refreshSessionAndJourney();
    }
  }

  Future<void> _refreshSessionAndJourney() async {
    if (_checkingSession) return;
    _checkingSession = true;
    try {
      final token = await AuthService.getToken();
      final authenticated = token != null && token.trim().isNotEmpty;
      if (!mounted) return;
      setState(() {
        _isGuest = !authenticated;
      });
      if (!authenticated) return;

      await ref.read(itqanJourneyProvider.notifier).loadAll();
      final refreshedToken = await AuthService.getToken();
      if (mounted && (refreshedToken == null || refreshedToken.trim().isEmpty)) {
        setState(() => _isGuest = true);
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isGuest = true;
        });
      }
    } finally {
      _checkingSession = false;
    }
  }

  Future<void> _handleStartJourney() async {
    if (_isGuest) {
      await Navigator.of(context).push<void>(
        MaterialPageRoute<void>(builder: (_) => const LoginScreen()),
      );
      if (mounted) await _refreshSessionAndJourney();
    } else {
      await Navigator.of(context).push<void>(
        MaterialPageRoute<void>(builder: (_) => const ItqanWorldScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(itqanJourneyProvider);
    final profile = state.profile;

    final stats = profile != null && profile['stats'] is Map
        ? profile['stats'] as Map
        : const {};
    final level = stats['level'] is Map ? stats['level'] as Map : const {};
    final rawProgress = level['progress_percentage'];
    final double progress = (rawProgress is num
            ? (rawProgress.toDouble() / 100)
            : 0.68)
        .clamp(0.0, 1.0);
    final int totalPoints = stats['total_xp'] is int ? stats['total_xp'] as int : 880;
    final int levelNum = level['number'] is int ? level['number'] as int : 7;
    final int streakDays = stats['streak_days'] is int ? stats['streak_days'] as int : 12;

    return Container(
      decoration: BoxDecoration(
        color: ItqanColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: ItqanColors.border),
        boxShadow: [
          BoxShadow(
            color: ItqanColors.ink.withValues(alpha: 0.06),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(24),
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: _handleStartJourney,
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Top Row: "+40 نقطة" on left, Title on right (RTL)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Badge "+40 نقطة" (Left in RTL)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF3C7),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFFFDE68A)),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.bolt_rounded, size: 14, color: Color(0xFFD97706)),
                          SizedBox(width: 2),
                          Text(
                            '+40 نقطة',
                            style: TextStyle(
                              fontFamily: 'Tajawal',
                              color: Color(0xFFD97706),
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const Spacer(),

                    // Title and Subtitle (Right in RTL)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text(
                          'رحلتك الإيمانية',
                          style: TextStyle(
                            fontFamily: 'Tajawal',
                            color: ItqanColors.ink,
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'المستوى $levelNum • $totalPoints نقطة',
                          style: const TextStyle(
                            fontFamily: 'Tajawal',
                            color: ItqanColors.inkSoft,
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 10),

                    // Icon container
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: const Color(0xFFECFDF5),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFA7F3D0)),
                      ),
                      child: const Icon(
                        Icons.auto_awesome_rounded,
                        color: Color(0xFF059669),
                        size: 20,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 14),

                // Progress Bar (dual gradient emerald to gold)
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    height: 8,
                    color: const Color(0xFFF3F4F6),
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: FractionallySizedBox(
                        widthFactor: progress,
                        child: Container(
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Color(0xFFD97706), // gold
                                Color(0xFF059669), // emerald
                              ],
                            ),
                            borderRadius: BorderRadius.horizontal(
                              right: Radius.circular(8),
                              left: Radius.circular(8),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 8),

                // Sub-progress row: "68% إلى المستوى 8" & "عرض التفاصيل <"
                Row(
                  children: [
                    const Text(
                      'عرض التفاصيل  ›',
                      style: TextStyle(
                        fontFamily: 'Tajawal',
                        color: Color(0xFFD97706),
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '${(progress * 100).toInt()}% إلى المستوى ${levelNum + 1}',
                      style: const TextStyle(
                        fontFamily: 'Tajawal',
                        color: ItqanColors.inkSoft,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 14),
                const Divider(height: 1, color: Color(0xFFF3F4F6)),
                const SizedBox(height: 12),

                // 3 Stats bottom row:
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStatItem(
                      icon: Icons.star_rounded,
                      iconColor: const Color(0xFFF59E0B),
                      text: '$totalPoints نقطة',
                    ),
                    _buildStatItem(
                      icon: Icons.menu_book_rounded,
                      iconColor: const Color(0xFF059669),
                      text: 'ورد اليوم: 12/20',
                    ),
                    _buildStatItem(
                      icon: Icons.local_fire_department_rounded,
                      iconColor: const Color(0xFFEA580C),
                      text: '$streakDays يوم متواصل',
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required Color iconColor,
    required String text,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          text,
          style: const TextStyle(
            fontFamily: 'Tajawal',
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: ItqanColors.ink,
          ),
        ),
        const SizedBox(width: 5),
        Icon(icon, size: 16, color: iconColor),
      ],
    );
  }
}
