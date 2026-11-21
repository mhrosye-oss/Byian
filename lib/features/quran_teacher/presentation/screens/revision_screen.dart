import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/theme/typography.dart';
import '../../../../core/ui/base_widgets.dart';

/// شاشة "راجع معي" – جدول المراجعة التراكمية وسجل الآيات المحفوظة
class RevisionScreen extends ConsumerStatefulWidget {
  const RevisionScreen({super.key});

  @override
  ConsumerState<RevisionScreen> createState() => _RevisionScreenState();
}

class _RevisionScreenState extends ConsumerState<RevisionScreen> {
  List<Map<String, dynamic>> _sessions = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSessions();
  }

  Future<void> _loadSessions() async {
    setState(() => _isLoading = true);
    try {
      final box = await Hive.openBox('quran_teacher_progress');
      final list = <Map<String, dynamic>>[];
      for (var i = 0; i < box.length; i++) {
        final key = box.keyAt(i);
        // نتجاهل المفتاح التلقائي 'lastSession'
        if (key == 'lastSession') continue;

        final val = box.getAt(i);
        if (val is Map) {
          final item = Map<String, dynamic>.from(val);
          item['_key'] = key;
          list.add(item);
        }
      }

      // الأقرب استحقاقاً أولاً، مع إبقاء السجلات القديمة بلا موعد في النهاية.
      DateTime? reviewDate(Map<String, dynamic> item) {
        final raw = item['nextReviewDate'];
        return raw is String ? DateTime.tryParse(raw) : null;
      }
      list.sort((a, b) {
        final dueA = reviewDate(a);
        final dueB = reviewDate(b);
        if (dueA == null && dueB == null) return 0;
        if (dueA == null) return 1;
        if (dueB == null) return -1;
        return dueA.compareTo(dueB);
      });

      if (mounted) {
        setState(() {
          _sessions = list;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _updateReviewStatus(int index, String newStatus, int addDays) async {
    final session = _sessions[index];
    final key = session['_key'];
    if (key == null) return;

    try {
      final box = await Hive.openBox('quran_teacher_progress');
      session['masteryLevel'] = newStatus;
      session['lastReviewedAt'] = DateTime.now().toIso8601String();
      session['nextReviewDate'] = DateTime.now().add(Duration(days: addDays)).toIso8601String();
      session['isRevision'] = true;

      await box.put(key, session);
      await _loadSessions();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('تم تحديث موعد المراجعة القادمة بعد $addDays أيام.'),
            backgroundColor: ItqanColors.emeraldDark,
          ),
        );
      }
    } catch (_) {}
  }

  Future<void> _deleteSession(int index) async {
    final session = _sessions[index];
    final key = session['_key'];
    if (key == null) return;

    try {
      final box = await Hive.openBox('quran_teacher_progress');
      await box.delete(key);
      await _loadSessions();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم حذف الجلسة من السجل.')),
        );
      }
    } catch (_) {}
  }

  void _showReviewActionSheet(int index) {
    final session = _sessions[index];
    final surahName = session['surahName'] ?? 'سورة ${session['surah']}';
    final startAyah = session['startAyah'] ?? 1;
    final endAyah = session['endAyah'] ?? 1;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'مراجعة $surahName (الآيات $startAyah - $endAyah)',
                style: const TextStyle(
                  fontFamily: ItqanTypography.uiFont,
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: ItqanColors.ink,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'ما مدى إتقانك للمقطع بعد مراجعته اليوم؟',
                style: TextStyle(
                  fontFamily: ItqanTypography.uiFont,
                  fontSize: 13,
                  color: ItqanColors.muted,
                ),
              ),
              const SizedBox(height: 20),
              ListTile(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                tileColor: ItqanColors.emerald.withValues(alpha: 0.08),
                leading: const Icon(Icons.check_circle_rounded, color: ItqanColors.emerald),
                title: const Text('ممتاز ومتقن تماماً', style: TextStyle(fontFamily: ItqanTypography.uiFont, fontWeight: FontWeight.bold)),
                subtitle: const Text('تأجيل المراجعة القادمة إلى بعد ٧ أيام', style: TextStyle(fontFamily: ItqanTypography.uiFont, fontSize: 12)),
                onTap: () {
                  Navigator.pop(ctx);
                  _updateReviewStatus(index, 'متقن', 7);
                },
              ),
              const SizedBox(height: 8),
              ListTile(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                tileColor: Colors.orange.withValues(alpha: 0.08),
                leading: const Icon(Icons.refresh_rounded, color: Colors.orange),
                title: const Text('جيد ولكن يحتاج تثبيتاً إضافياً', style: TextStyle(fontFamily: ItqanTypography.uiFont, fontWeight: FontWeight.bold)),
                subtitle: const Text('تكرار المراجعة بعد يومين', style: TextStyle(fontFamily: ItqanTypography.uiFont, fontSize: 12)),
                onTap: () {
                  Navigator.pop(ctx);
                  _updateReviewStatus(index, 'يحتاج تثبيت', 2);
                },
              ),
              const SizedBox(height: 8),
              ListTile(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                tileColor: ItqanColors.roseGold.withValues(alpha: 0.08),
                leading: const Icon(Icons.replay_rounded, color: ItqanColors.roseGold),
                title: const Text('نسيان أو تعثر في الآيات', style: TextStyle(fontFamily: ItqanTypography.uiFont, fontWeight: FontWeight.bold)),
                subtitle: const Text('مراجعة غداً مع التكرار في "احفظ معي"', style: TextStyle(fontFamily: ItqanTypography.uiFont, fontSize: 12)),
                onTap: () {
                  Navigator.pop(ctx);
                  _updateReviewStatus(index, 'قيد الحفظ', 1);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(String? iso) {
    if (iso == null || iso.isEmpty) return '—';
    final dt = DateTime.tryParse(iso);
    if (dt == null) return iso;
    return '${dt.year}/${dt.month}/${dt.day}';
  }

  Color _getStatusColor(String? status) {
    switch (status) {
      case 'متقن':
        return ItqanColors.emerald;
      case 'يحتاج تثبيت':
        return Colors.orange;
      case 'قيد الحفظ':
        return Colors.blue;
      default:
        return ItqanColors.emerald;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: TeacherAppBar(
          title: 'راجع معي',
          actions: [
            IconButton(
              tooltip: 'تحديث السجل',
              icon: const Icon(Icons.refresh_rounded, color: ItqanColors.emerald),
              onPressed: _loadSessions,
            ),
          ],
        ),
        body: SafeArea(
          child: _isLoading
              ? const TeacherLoadingWidget(message: 'جاري تحميل سجل المراجعات...')
              : _sessions.isEmpty
                  ? TeacherEmptyState(
                      title: 'لا يوجد محفوظات في جدول المراجعة بعد',
                      subtitle: 'ابدأ بحفظ مقطع من خدمة «احفظ معي» أو سجّل تلاوتك في «سمّع لي» وسيظهر هنا تلقائياً لجدولته.',
                      icon: Icons.history_edu_rounded,
                      actionLabel: 'ابدأ الحفظ الآن',
                      onAction: () {
                        Navigator.of(context).pushReplacementNamed('/memorization');
                      },
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.all(18),
                      itemCount: _sessions.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final s = _sessions[index];
                        final surahName = s['surahName'] ?? 'سورة ${s['surah']}';
                        final start = s['startAyah'] ?? 1;
                        final end = s['endAyah'] ?? 1;
                        final level = s['masteryLevel'] ?? 'قيد الحفظ';
                        final color = _getStatusColor(level);
                        final nextReview = _formatDate(s['nextReviewDate']);
                        final created = _formatDate(s['timestamp']);

                        return Container(
                          decoration: BoxDecoration(
                            color: Theme.of(context).cardColor,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Theme.of(context).dividerColor),
                            boxShadow: [
                              BoxShadow(
                                color: ItqanColors.ink.withValues(alpha: 0.04),
                                blurRadius: 10,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(20),
                            onTap: () => _showReviewActionSheet(index),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        width: 44,
                                        height: 44,
                                        decoration: BoxDecoration(
                                          color: color.withValues(alpha: 0.12),
                                          borderRadius: BorderRadius.circular(14),
                                        ),
                                        child: Icon(Icons.bookmark_rounded, color: color, size: 24),
                                      ),
                                      const SizedBox(width: 14),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              surahName,
                                              style: const TextStyle(
                                                fontFamily: ItqanTypography.arabicFont,
                                                fontSize: 17,
                                                fontWeight: FontWeight.bold,
                                                color: ItqanColors.ink,
                                              ),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              'الآيات من $start إلى $end',
                                              style: const TextStyle(
                                                fontFamily: ItqanTypography.uiFont,
                                                fontSize: 13,
                                                color: ItqanColors.muted,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: color.withValues(alpha: 0.1),
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        child: Text(
                                          level,
                                          style: TextStyle(
                                            fontFamily: ItqanTypography.uiFont,
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                            color: color,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 14),
                                  const Divider(height: 1),
                                  const SizedBox(height: 10),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              const Icon(Icons.calendar_today_rounded, size: 13, color: ItqanColors.muted),
                                              const SizedBox(width: 5),
                                              Text(
                                                'المراجعة: $nextReview',
                                                style: const TextStyle(fontFamily: ItqanTypography.uiFont, fontSize: 12, color: ItqanColors.inkSoft),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            'أُنشئت: $created',
                                            style: const TextStyle(fontFamily: ItqanTypography.uiFont, fontSize: 11, color: ItqanColors.muted),
                                          ),
                                        ],
                                      ),
                                      Row(
                                        children: [
                                          IconButton(
                                            tooltip: 'تسجيل مراجعة اليوم',
                                            icon: const Icon(Icons.edit_calendar_rounded, size: 20, color: ItqanColors.emerald),
                                            onPressed: () => _showReviewActionSheet(index),
                                          ),
                                          IconButton(
                                            tooltip: 'حذف',
                                            icon: const Icon(Icons.delete_outline_rounded, size: 20, color: ItqanColors.roseGold),
                                            onPressed: () => _deleteSession(index),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
        ),
      ),
    );
  }
}
