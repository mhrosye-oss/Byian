import 'dart:async';
import 'package:flutter/material.dart';

import '../../prayer/services/prayer_times_service.dart';

class NextPrayerBanner extends StatefulWidget {
  const NextPrayerBanner({
    super.key,
    required this.onOpenPrayerTimes,
    this.onOpenDrawer,
  });

  final VoidCallback onOpenPrayerTimes;
  final VoidCallback? onOpenDrawer;

  @override
  State<NextPrayerBanner> createState() => _NextPrayerBannerState();
}

class _NextPrayerBannerState extends State<NextPrayerBanner> {
  PrayerTime? _prayer;
  Timer? _timer;
  Duration _remaining = const Duration(hours: 1, minutes: 24, seconds: 18);
  bool _isPlayingAdhan = false;

  @override
  void initState() {
    super.initState();
    _fetchNextPrayer();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _fetchNextPrayer() async {
    try {
      final p = await PrayerTimesService.getNextPrayerPreview();
      if (mounted && p != null) {
        setState(() {
          _prayer = p;
          final diff = p.time.difference(DateTime.now());
          _remaining = diff.isNegative ? Duration.zero : diff;
        });
      }
    } catch (_) {}
  }

  void _tick() {
    if (!mounted) return;
    setState(() {
      if (_remaining.inSeconds > 0) {
        _remaining = _remaining - const Duration(seconds: 1);
      } else {
        _fetchNextPrayer();
      }
    });
  }

  String _twoDigits(int n) => n.toString().padLeft(2, '0');

  @override
  Widget build(BuildContext context) {
    final hours = _twoDigits(_remaining.inHours);
    final minutes = _twoDigits(_remaining.inMinutes.remainder(60));
    final seconds = _twoDigits(_remaining.inSeconds.remainder(60));

    final prayerName = _prayer?.labelAr ?? 'صلاة المغرب';
    final countdownStr = '$hours:$minutes:$seconds';

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [
            Color(0xFF064E3B), // deep forest green
            Color(0xFF043F30),
            Color(0xFF022C22),
          ],
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF064E3B).withValues(alpha: 0.35),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Background ambient light glow
          Positioned(
            top: -20,
            left: -20,
            child: Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF10B981).withValues(alpha: 0.12),
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Top Row: Bell on left, Live badge + Prayer Name on right (RTL layout)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Left actions: Drawer Toggle (Menu) & Notification Bell
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Menu / Drawer Toggle Button
                        Material(
                          color: Colors.transparent,
                          borderRadius: BorderRadius.circular(16),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(16),
                            onTap: widget.onOpenDrawer,
                            child: Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.14),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.20),
                                ),
                              ),
                              child: const Icon(
                                Icons.menu_rounded,
                                color: Colors.white,
                                size: 22,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(width: 8),

                        // Notification Bell
                        Material(
                          color: Colors.transparent,
                          borderRadius: BorderRadius.circular(16),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(16),
                            onTap: widget.onOpenPrayerTimes,
                            child: Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.18),
                                ),
                              ),
                              child: const Icon(
                                Icons.notifications_none_rounded,
                                color: Colors.white,
                                size: 22,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const Spacer(),

                    // Prayer Name and Subtitle (Right in RTL)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        // Live badge
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFF10B981).withValues(alpha: 0.20),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: const Color(0xFF10B981).withValues(alpha: 0.40),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 7,
                                height: 7,
                                decoration: const BoxDecoration(
                                  color: Color(0xFF34D399),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 6),
                              const Text(
                                'مباشر',
                                style: TextStyle(
                                  fontFamily: 'Tajawal',
                                  color: Color(0xFF34D399),
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          prayerName,
                          style: const TextStyle(
                            fontFamily: 'Tajawal',
                            color: Colors.white,
                            fontSize: 26,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'متبقي حتى الأذان $countdownStr',
                          style: TextStyle(
                            fontFamily: 'Tajawal',
                            color: Colors.white.withValues(alpha: 0.78),
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // Countdown Blocks: 18 ثانية : 24 دقيقة : 01 ساعات
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildCountdownBox(value: seconds, label: 'ثانية'),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8),
                      child: Text(
                        ':',
                        style: TextStyle(
                          color: Color(0xFFFBBF24),
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    _buildCountdownBox(value: minutes, label: 'دقيقة'),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8),
                      child: Text(
                        ':',
                        style: TextStyle(
                          color: Color(0xFFFBBF24),
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    _buildCountdownBox(value: hours, label: 'ساعات'),
                  ],
                ),

                const SizedBox(height: 22),

                // Bottom Action Buttons: [المواقيت] [استمع للأذان]
                Row(
                  children: [
                    // Left: المواقيت (Timetable)
                    Expanded(
                      flex: 4,
                      child: Material(
                        color: Colors.transparent,
                        borderRadius: BorderRadius.circular(16),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: widget.onOpenPrayerTimes,
                          child: Container(
                            height: 48,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.20),
                              ),
                            ),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.calendar_month_outlined,
                                    color: Colors.white, size: 18),
                                SizedBox(width: 8),
                                Text(
                                  'المواقيت',
                                  style: TextStyle(
                                    fontFamily: 'Tajawal',
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(width: 12),

                    // Right: استمع للأذان (Golden/Amber Button)
                    Expanded(
                      flex: 6,
                      child: Material(
                        color: Colors.transparent,
                        borderRadius: BorderRadius.circular(16),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: () {
                            setState(() => _isPlayingAdhan = !_isPlayingAdhan);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(_isPlayingAdhan
                                    ? 'تم تشغيل تجربة الأذان بصوت ندي'
                                    : 'تم إيقاف الأذان'),
                                backgroundColor: const Color(0xFF064E3B),
                                duration: const Duration(seconds: 2),
                              ),
                            );
                          },
                          child: Container(
                            height: 48,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [
                                  Color(0xFFF59E0B), // amber-500
                                  Color(0xFFD97706), // amber-600
                                ],
                              ),
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFFF59E0B).withValues(alpha: 0.35),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  _isPlayingAdhan
                                      ? Icons.stop_rounded
                                      : Icons.volume_up_rounded,
                                  color: Colors.white,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  _isPlayingAdhan ? 'إيقاف الأذان' : 'استمع للأذان',
                                  style: const TextStyle(
                                    fontFamily: 'Tajawal',
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCountdownBox({required String value, required String label}) {
    return Container(
      width: 76,
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.20),
        ),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              fontFamily: 'Tajawal',
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Tajawal',
              color: Colors.white.withValues(alpha: 0.70),
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
