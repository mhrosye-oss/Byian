import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/colors.dart';
import '../../../core/theme/spacing.dart';
import '../../../core/theme/typography.dart';
import '../services/prayer_times_service.dart';

class PrayerTimesScreen extends ConsumerStatefulWidget {
  const PrayerTimesScreen({super.key});

  @override
  ConsumerState<PrayerTimesScreen> createState() => _PrayerTimesScreenState();
}

class _PrayerTimesScreenState extends ConsumerState<PrayerTimesScreen> {
  late Future<List<PrayerTime>> _future;
  bool _scheduling = false;
  String? _feedback;
  bool _scheduleSucceeded = false;

  @override
  void initState() {
    super.initState();
    _future = PrayerTimesService.getTodayPrayerTimes();
  }

  Future<void> _scheduleAlerts() async {
    setState(() {
      _scheduling = true;
      _feedback = null;
    });
    try {
      await PrayerTimesService.scheduleUpcomingNotifications();
      if (!mounted) return;
      setState(() {
        _scheduleSucceeded = true;
        _feedback = 'تم تفعيل تذكير قبل الصلاة بـ15 دقيقة والأذان عند دخول الوقت.';
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _scheduleSucceeded = false;
        _feedback = error.toString().replaceFirst('Bad state: ', '');
      });
    } finally {
      if (mounted) setState(() => _scheduling = false);
    }
  }

  void _refresh() {
    setState(() {
      _future = PrayerTimesService.getTodayPrayerTimes();
      _feedback = null;
      _scheduleSucceeded = false;
    });
  }

  String _timeLabel(DateTime time) =>
      '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ItqanColors.void_,
      appBar: AppBar(
        title: const Text('مواقيت الصلاة', style: ItqanTypography.heading2),
        actions: [
          IconButton(
            tooltip: 'تحديث الموقع والمواقيت',
            onPressed: _refresh,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: FutureBuilder<List<PrayerTime>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: ItqanColors.gold),
            );
          }
          if (snapshot.hasError) {
            return _LoadError(
              message: snapshot.error.toString(),
              onRetry: _refresh,
            );
          }

          final prayers = snapshot.data ?? const <PrayerTime>[];
          final now = DateTime.now();
          final nextIndex = prayers.indexWhere((prayer) => prayer.time.isAfter(now));

          return ListView(
            padding: const EdgeInsets.fromLTRB(
              ItqanSpacing.lg,
              ItqanSpacing.md,
              ItqanSpacing.lg,
              ItqanSpacing.xl,
            ),
            children: [
              _LocationCard(today: now),
              const SizedBox(height: ItqanSpacing.md),
              FilledButton.icon(
                onPressed: _scheduling ? null : _scheduleAlerts,
                icon: _scheduling
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: ItqanColors.void_,
                        ),
                      )
                    : Icon(_scheduleSucceeded
                        ? Icons.notifications_active_rounded
                        : Icons.notifications_outlined),
                label: Text(
                  _scheduling
                      ? 'جارٍ إعداد التنبيهات…'
                      : _scheduleSucceeded
                          ? 'تحديث تنبيهات الصلاة'
                          : 'تفعيل تنبيهات الصلاة والأذان',
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: ItqanColors.gold,
                  foregroundColor: ItqanColors.void_,
                  disabledBackgroundColor: ItqanColors.goldDeep,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  textStyle: const TextStyle(fontWeight: FontWeight.w700),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(ItqanRadius.md),
                  ),
                ),
              ),
              if (_feedback != null) ...[
                const SizedBox(height: ItqanSpacing.sm),
                Container(
                  padding: const EdgeInsets.all(ItqanSpacing.md),
                  decoration: BoxDecoration(
                    color: _scheduleSucceeded
                        ? ItqanColors.goldShimmer
                        : ItqanColors.error.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(ItqanRadius.md),
                    border: Border.all(
                      color: _scheduleSucceeded
                          ? ItqanColors.goldGlow
                          : ItqanColors.error.withValues(alpha: 0.4),
                    ),
                  ),
                  child: Text(
                    _feedback!,
                    textDirection: TextDirection.rtl,
                    style: ItqanTypography.caption.copyWith(
                      color: _scheduleSucceeded
                          ? ItqanColors.goldLight
                          : ItqanColors.error,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: ItqanSpacing.lg),
              Row(
                children: [
                  const Expanded(
                    child: Text('صلوات اليوم', style: ItqanTypography.heading2),
                  ),
                  Text(
                    'حسب موقعك الحالي',
                    style: ItqanTypography.caption,
                    textDirection: TextDirection.rtl,
                  ),
                ],
              ),
              const SizedBox(height: ItqanSpacing.sm),
              ...List.generate(prayers.length, (index) {
                final prayer = prayers[index];
                return _PrayerTile(
                  prayer: prayer,
                  timeLabel: _timeLabel(prayer.time),
                  isNext: index == nextIndex,
                );
              }),
              const SizedBox(height: ItqanSpacing.sm),
              Text(
                'تُعاد جدولة التنبيهات لستة أيام عند تفعيلها أو تحديث الموقع. قد يتطلب Android السماح بالتنبيهات الدقيقة.',
                style: ItqanTypography.caption.copyWith(height: 1.5),
                textDirection: TextDirection.rtl,
              ),
            ],
          );
        },
      ),
    );
  }
}

class _LocationCard extends StatelessWidget {
  final DateTime today;

  const _LocationCard({required this.today});

  @override
  Widget build(BuildContext context) {
    final date = '${today.year}/${today.month.toString().padLeft(2, '0')}/${today.day.toString().padLeft(2, '0')}';
    return Container(
      padding: const EdgeInsets.all(ItqanSpacing.lg),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [ItqanColors.onyx, ItqanColors.obsidian],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ),
        borderRadius: BorderRadius.circular(ItqanRadius.lg),
        border: Border.all(color: ItqanColors.goldGlow),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: ItqanColors.goldShimmer,
              borderRadius: BorderRadius.circular(ItqanRadius.md),
            ),
            child: const Icon(Icons.location_on_rounded,
                color: ItqanColors.gold, size: 23),
          ),
          const SizedBox(width: ItqanSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'مواقيت محلية دقيقة',
                  style: TextStyle(
                    color: ItqanColors.snow,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                  textDirection: TextDirection.rtl,
                ),
                const SizedBox(height: 4),
                Text(
                  'حُسبت عبر Awqat اعتمادًا على GPS · $date',
                  style: ItqanTypography.caption,
                  textDirection: TextDirection.rtl,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PrayerTile extends StatelessWidget {
  final PrayerTime prayer;
  final String timeLabel;
  final bool isNext;

  const _PrayerTile({
    required this.prayer,
    required this.timeLabel,
    required this.isNext,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: ItqanSpacing.sm),
      padding: const EdgeInsets.symmetric(
        horizontal: ItqanSpacing.md,
        vertical: ItqanSpacing.md,
      ),
      decoration: BoxDecoration(
        color: isNext ? ItqanColors.goldShimmer : ItqanColors.onyx,
        borderRadius: BorderRadius.circular(ItqanRadius.md),
        border: Border.all(
          color: isNext ? ItqanColors.gold : ItqanColors.charcoal,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: isNext ? ItqanColors.gold : ItqanColors.charcoal,
              borderRadius: BorderRadius.circular(ItqanRadius.sm),
            ),
            child: Icon(
              Icons.access_time_rounded,
              color: isNext ? ItqanColors.void_ : ItqanColors.silver,
              size: 21,
            ),
          ),
          const SizedBox(width: ItqanSpacing.md),
          Expanded(
            child: Text(
              prayer.labelAr,
              style: TextStyle(
                color: isNext ? ItqanColors.goldLight : ItqanColors.snow,
                fontSize: 17,
                fontWeight: FontWeight.w700,
              ),
              textDirection: TextDirection.rtl,
            ),
          ),
          if (isNext) ...[
            const Text('القادمة',
                style: TextStyle(color: ItqanColors.gold, fontSize: 11)),
            const SizedBox(width: ItqanSpacing.sm),
          ],
          Text(
            timeLabel,
            style: TextStyle(
              color: isNext ? ItqanColors.gold : ItqanColors.silver,
              fontSize: 18,
              fontWeight: FontWeight.w700,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}

class _LoadError extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _LoadError({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(ItqanSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.location_off_rounded,
                color: ItqanColors.mist, size: 44),
            const SizedBox(height: ItqanSpacing.md),
            Text(
              'تعذر حساب المواقيت: $message',
              style: ItqanTypography.body.copyWith(color: ItqanColors.error),
              textAlign: TextAlign.center,
              textDirection: TextDirection.rtl,
            ),
            const SizedBox(height: ItqanSpacing.md),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('إعادة المحاولة'),
            ),
          ],
        ),
      ),
    );
  }
}
