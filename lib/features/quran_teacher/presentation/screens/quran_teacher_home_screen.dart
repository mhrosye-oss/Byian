import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/theme/typography.dart';
import '../../../../core/ui/base_widgets.dart';

/// الشاشة الرئيسية لمعلّم القرآن الذكي
class QuranTeacherHomeScreen extends ConsumerStatefulWidget {
  const QuranTeacherHomeScreen({super.key});

  @override
  ConsumerState<QuranTeacherHomeScreen> createState() =>
      _QuranTeacherHomeScreenState();
}

class _QuranTeacherHomeScreenState extends ConsumerState<QuranTeacherHomeScreen> {
  int _memorizedCount = 0;
  int _revisionCount = 0;
  String _lastSurahName = '';
  bool _isLoadingStats = true;

  @override
  void initState() {
    super.initState();
    _loadProgressStats();
  }

  Future<void> _loadProgressStats() async {
    try {
      final box = await Hive.openBox('quran_teacher_progress');
      int memCount = 0;
      int revCount = 0;
      String lastSurah = '';

      for (var i = 0; i < box.length; i++) {
        // lastSession نسخة لاستعادة آخر اختيار وليست جلسة مستقلة.
        if (box.keyAt(i) == 'lastSession') continue;
        final val = box.getAt(i);
        if (val is Map) {
          final isRevision = val['isRevision'] == true;
          if (isRevision) {
            revCount++;
          } else {
            memCount++;
          }
          if (val['surahName'] != null) {
            lastSurah = val['surahName'].toString();
          } else if (val['surah'] != null) {
            lastSurah = 'سورة ${val['surah']}';
          }
        }
      }

      if (mounted) {
        setState(() {
          _memorizedCount = memCount;
          _revisionCount = revCount;
          _lastSurahName = lastSurah;
          _isLoadingStats = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoadingStats = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: TeacherAppBar(
          title: 'معلّم القرآن الذكي',
          actions: [
            IconButton(
              tooltip: 'تحديث الإحصاءات',
              icon: const Icon(Icons.refresh_rounded, color: ItqanColors.emerald),
              onPressed: _loadProgressStats,
            ),
          ],
        ),
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(18, 12, 18, 28),
            children: [
              // بانر ترحيبي بتصميم إتقان
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: ItqanColors.emerald.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: ItqanColors.emerald.withValues(alpha: 0.2)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: ItqanColors.emerald,
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: const Icon(Icons.school_rounded, color: Colors.white, size: 26),
                    ),
                    const SizedBox(width: 14),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'مرحباً بك في معلّم القرآن',
                            style: TextStyle(
                              fontFamily: ItqanTypography.uiFont,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: ItqanColors.ink,
                            ),
                          ),
                          SizedBox(height: 3),
                          Text(
                            'مسارك التفاعلي لحفظ وتثبيت ومراجعة آيات كتاب الله',
                            style: TextStyle(
                              fontFamily: ItqanTypography.uiFont,
                              fontSize: 12,
                              color: ItqanColors.inkSoft,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // بطاقة الإحصاءات
              if (!_isLoadingStats)
                TeacherStatsBanner(
                  totalMemorizedSessions: _memorizedCount,
                  totalRevisionSessions: _revisionCount,
                  lastSurahName: _lastSurahName,
                ),

              const SizedBox(height: 22),

              const Text(
                'خدمات التعلّم المتاحة',
                style: TextStyle(
                  fontFamily: ItqanTypography.uiFont,
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: ItqanColors.ink,
                ),
              ),
              const SizedBox(height: 12),

              // شبكة الخدمات الأربع
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                crossAxisSpacing: 14,
                mainAxisSpacing: 14,
                childAspectRatio: 0.95,
                children: [
                  TeacherServiceCard(
                    title: 'احفظ معي',
                    description: 'تكرار الآيات والتحكم بالصوت مع إخفاء النص للتثبيت الذاتي',
                    icon: Icons.auto_stories_rounded,
                    badgeText: 'تفاعلي',
                    accentColor: ItqanColors.emerald,
                    onTap: () {
                      Navigator.of(context).pushNamed('/memorization').then((_) => _loadProgressStats());
                    },
                  ),
                  TeacherServiceCard(
                    title: 'سمّع لي',
                    description: 'تسجيل قراءتك ومراجعتها بصوتك مع التحقق من الحفظ',
                    icon: Icons.mic_rounded,
                    badgeText: 'تسجيل صوتي',
                    accentColor: ItqanColors.roseGold,
                    onTap: () {
                      Navigator.of(context).pushNamed('/teacher_recitation').then((_) => _loadProgressStats());
                    },
                  ),
                  TeacherServiceCard(
                    title: 'راجع معي',
                    description: 'جدول المراجعة التراكمية وسجل الآيات المحفوظة لتثبيت الحفظ',
                    icon: Icons.history_rounded,
                    badgeText: 'تكرار متباعد',
                    accentColor: const Color(0xFF2E7D32),
                    onTap: () {
                      Navigator.of(context).pushNamed('/revision').then((_) => _loadProgressStats());
                    },
                  ),
                  TeacherServiceCard(
                    title: 'حسّن تلاوتك',
                    description: 'شرح أحكام التجويد والمخارج مع أمثلة قرآنية وتطبيق عملي',
                    icon: Icons.school_rounded,
                    badgeText: 'أحكام ومخارج',
                    accentColor: const Color(0xFF00796B),
                    onTap: () {
                      Navigator.of(context).pushNamed('/tajweed');
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
