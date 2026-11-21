import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/theme/typography.dart';
import '../../../../core/ui/base_widgets.dart';

/// شاشة التنويه الإرشادي لخدمة "سمّع لي"
class RecitationIntroScreen extends StatefulWidget {
  const RecitationIntroScreen({super.key});

  @override
  State<RecitationIntroScreen> createState() => _RecitationIntroScreenState();
}

class _RecitationIntroScreenState extends State<RecitationIntroScreen> {
  bool _dontShowAgain = false;

  Future<void> _proceed() async {
    if (_dontShowAgain) {
      try {
        final box = await Hive.openBox('settings');
        await box.put('seen_recitation_disclaimer', true);
      } catch (_) {}
    }

    if (!mounted) return;
    Navigator.of(context).pushReplacementNamed('/teacher_recitation');
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: const TeacherAppBar(title: 'تنويه مهم حول خدمة التسميع'),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: ItqanColors.roseGold.withValues(alpha: 0.12),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.info_outline_rounded,
                            size: 42,
                            color: ItqanColors.roseGold,
                          ),
                        ),
                        const SizedBox(height: 20),
                        const Text(
                          'تنويه تقني وأمانة علمية',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: ItqanTypography.uiFont,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: ItqanColors.ink,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            color: Theme.of(context).cardColor,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: Theme.of(context).dividerColor),
                          ),
                          child: const Text(
                            'أخي القارئ الكريم،\n\n'
                            'يعمل فريق «إتقان» باستمرار على تطوير وبناء نماذج الذكاء الاصطناعي المخصصة للتعرف الصوتي على التلاوة القرآنية وأحكام التجويد.\n\n'
                            '• التقنيات الحالية تخضع للمعايرة والتدريب المستمر وقد لا تكون دقيقة بنسبة 100% في جميع البيئات الصوتية.\n\n'
                            '• لا تُغني النتائج الآلية عن العرض والمشافهة على الشيوخ والعلماء المتقنين المجازين.\n\n'
                            '• يمكنك تسجيل تلاوتك والاستماع إليها لمراجعة حفظك بصوتك في أي وقت.',
                            style: TextStyle(
                              fontFamily: ItqanTypography.uiFont,
                              fontSize: 14,
                              height: 1.7,
                              color: ItqanColors.inkSoft,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        CheckboxListTile(
                          contentPadding: EdgeInsets.zero,
                          value: _dontShowAgain,
                          activeColor: ItqanColors.emerald,
                          title: const Text(
                            'عدم إظهار هذا التنويه في المرات القادمة',
                            style: TextStyle(
                              fontFamily: ItqanTypography.uiFont,
                              fontSize: 13,
                              color: ItqanColors.ink,
                            ),
                          ),
                          onChanged: (val) {
                            setState(() => _dontShowAgain = val ?? false);
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                FilledButton.icon(
                  onPressed: _proceed,
                  style: FilledButton.styleFrom(
                    backgroundColor: ItqanColors.emerald,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  icon: const Icon(Icons.mic_rounded, size: 20),
                  label: const Text(
                    'فهمت، ابدأ التسميع الآن',
                    style: TextStyle(
                      fontFamily: ItqanTypography.uiFont,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
