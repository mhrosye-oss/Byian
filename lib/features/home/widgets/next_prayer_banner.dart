import 'package:flutter/material.dart';

import '../../../core/theme/colors.dart';
import '../../prayer/services/prayer_times_service.dart';

class NextPrayerBanner extends StatefulWidget {
  const NextPrayerBanner({super.key, required this.onOpenPrayerTimes});

  final VoidCallback onOpenPrayerTimes;

  @override
  State<NextPrayerBanner> createState() => _NextPrayerBannerState();
}

class _NextPrayerBannerState extends State<NextPrayerBanner> {
  late Future<PrayerTime?> _nextPrayer;

  @override
  void initState() {
    super.initState();
    _nextPrayer = PrayerTimesService.getNextPrayerPreview();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: ItqanColors.emerald,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: widget.onOpenPrayerTimes,
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(
                color: ItqanColors.emerald.withValues(alpha: 0.16),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: ItqanColors.roseGold.withValues(alpha: 0.20),
                  borderRadius: BorderRadius.circular(17),
                ),
                child: const Icon(
                  Icons.notifications_active_rounded,
                  color: ItqanColors.white,
                  size: 25,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: FutureBuilder<PrayerTime?>(
                  future: _nextPrayer,
                  builder: (context, snapshot) {
                    final prayer = snapshot.data;
                    final time = prayer == null
                        ? null
                        : TimeOfDay.fromDateTime(prayer.time).format(context);
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          prayer == null ? 'مواقيت الصلاة' : 'الصلاة القادمة',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.78),
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                          textDirection: TextDirection.rtl,
                        ),
                        const SizedBox(height: 3),
                        if (snapshot.connectionState == ConnectionState.waiting)
                          const Text(
                            'جارٍ تحميل المواقيت…',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                            textDirection: TextDirection.rtl,
                          )
                        else if (prayer != null)
                          Text(
                            '${prayer.labelAr}  ·  $time',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 19,
                              fontWeight: FontWeight.w800,
                            ),
                            textDirection: TextDirection.rtl,
                          )
                        else
                          const Text(
                            'اضغط لتحديد موقعك وعرض التالية',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                            textDirection: TextDirection.rtl,
                          ),
                        const SizedBox(height: 2),
                        Text(
                          prayer == null
                              ? 'مواقيت محلية وتنبيهات أذان'
                              : 'الموقع محفوظ على جهازك',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.72),
                            fontSize: 11,
                          ),
                          textDirection: TextDirection.rtl,
                        ),
                      ],
                    );
                  },
                ),
              ),
              const SizedBox(width: 8),
              const Icon(
                Icons.chevron_left_rounded,
                color: ItqanColors.roseGoldLight,
                size: 25,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
