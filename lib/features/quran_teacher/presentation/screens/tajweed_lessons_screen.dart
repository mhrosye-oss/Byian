import 'package:flutter/material.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/theme/typography.dart';
import '../../../../core/ui/base_widgets.dart';
import '../../../mushaf/mushaf_screen.dart';

/// شاشة دروس التجويد ومخارج الحروف (حسّن تلاوتك)
class TajweedLessonsScreen extends StatefulWidget {
  const TajweedLessonsScreen({super.key});

  @override
  State<TajweedLessonsScreen> createState() => _TajweedLessonsScreenState();
}

class _TajweedLessonsScreenState extends State<TajweedLessonsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final List<({String title, String category, String rule, String letters, List<String> examples, bool isAvailable})> _lessons = [
    // أحكام النون الساكنة والتنوين
    (
      title: 'الإظهار الحلقي',
      category: 'النون الساكنة والتنوين',
      rule: 'إخراج كل حرف من مخرجه بغير غنة ظاهرة في الحرف المظهر إذا جاء بعد النون الساكنة أو التنوين أحد حروف الحلق.',
      letters: 'ء ، هـ ، ع ، ح ، غ ، خ (أخي هاك علماً حازه غير خاسر)',
      examples: ['{مَنْ آمَنَ}', '{أَنْعَمْتَ}', '{عَذَابٌ أَلِيمٌ}', '{يَنْهَوْنَ}', '{مِنْ حَكِيمٍ}'],
      isAvailable: true,
    ),
    (
      title: 'الإدغام بغنة وبغير غنة',
      category: 'النون الساكنة والتنوين',
      rule: 'إدخال النون الساكنة أو التنوين في الحرف الذي بعدها بحيث يصيران حرفاً واحداً مشدداً كالثاني.',
      letters: 'مجموع في كلمة: يَرْمُلُونَ (بغنة في: يَنْمُو ، وبغير غنة في: ر ، ل)',
      examples: ['{مَن يَقُولُ}', '{مِن مَّالٍ}', '{مِن رَّبِّهِمْ}', '{هُدًى لِّلْمُتَّقِينَ}'],
      isAvailable: true,
    ),
    (
      title: 'الإقلاب',
      category: 'النون الساكنة والتنوين',
      rule: 'قلب النون الساكنة أو التنوين ميماً مخفاة بغنة عند ملاقاة حرف الباء.',
      letters: 'حرف واحد وهو: الباء (ب)',
      examples: ['{مِن بَعْدِ}', '{أَنبِئْهُم}', '{عَلِيمٌ بِذَاتِ الصُّدُورِ}'],
      isAvailable: true,
    ),
    (
      title: 'الإخفاء الحقيقي',
      category: 'النون الساكنة والتنوين',
      rule: 'النطق بالنون الساكنة أو التنوين بصفة بين الإظهار والإدغام عارٍ عن التشديد مع بقاء الغنة.',
      letters: '15 حرفاً: ص، ذ، ث، ك، ج، ش، ق، س، د، ط، ز، ف، ت، ض، ظ (أوائل كلمات: صف ذا ثنا كم جاد شخص قد سما...)',
      examples: ['{مِن قَبْلُ}', '{كُنتُمْ}', '{مِن شَرِّ}', '{مَاءً ثَجَّاجاً}'],
      isAvailable: true,
    ),

    // أحكام الميم الساكنة
    (
      title: 'الإخفاء الشفوي',
      category: 'الميم الساكنة',
      rule: 'نطق الميم الساكنة مخفاة مع بقاء الغنة إذا وقع بعدها حرف الباء مع مراعاة عدم الكز على الشفتين.',
      letters: 'حرف الباء (ب)',
      examples: ['{تَرْمِيهِم بِحِجَارَةٍ}', '{يَعْتَصِم بِاللَّهِ}'],
      isAvailable: true,
    ),
    (
      title: 'إدغام المتماثلين الصغير',
      category: 'الميم الساكنة',
      rule: 'إدغام الميم الساكنة في الميم المتحركة التي تليها لتصبحا ميماً واحدة مشددة بغنة أكمل ما تكون.',
      letters: 'حرف الميم (م)',
      examples: ['{لَهُم مَّا يَشَاءُونَ}', '{أَم مَّنْ}'],
      isAvailable: true,
    ),
    (
      title: 'الإظهار الشفوي',
      category: 'الميم الساكنة',
      rule: 'إظهار الميم الساكنة إظهاراً تاماً دون غنة زائدة عند جميع الحروف عدا الباء والميم، وأشدها إظهاراً عند الواو والفاء.',
      letters: '26 حرفاً (جميع حروف الهجاء عدا الباء والميم)',
      examples: ['{عَلَيْهِمْ وَلاَ}', '{هُمْ فِيهَا}', '{أَلَمْ تَرَ}'],
      isAvailable: true,
    ),

    // مخارج الحروف
    (
      title: 'المخارج العامة الخمسة',
      category: 'مخارج الحروف',
      rule: 'المخارج هي الأماكن التي ينشأ منها الحرف وينقطع الصوت عندها فيتميز بها عن غيره.',
      letters: '1. الجوف  2. الحلق  3. اللسان  4. الشفتان  5. الخيشوم',
      examples: ['الجوف: حروف المد الثلاثة', 'الحلق: الهمزة والهاء والعين والحاء والغين والخاء', 'اللسان: 18 حرفاً', 'الشفتان: الفاء والواو والباء والميم', 'الخيشوم: الغنة'],
      isAvailable: true,
    ),
    (
      title: 'مخرج اللسان وتفاصيله',
      category: 'مخارج الحروف',
      rule: 'أوسع المخارج وأكثرها حروفاً، وفيه عشرة مخارج خاصة لثمانية عشر حرفاً من أقصاه ووسطه وحافته وطرفه.',
      letters: 'القـاف، الكاف، الجيم، الشين، الياء، الضاد، اللام، النون، الراء، الطاء، الدال، التاء، الصاد، السين، الزاي، الظاء، الذال، الثاء',
      examples: ['أقصى اللسان: ق ، ك', 'وسط اللسان: ج ، ش ، ي', 'حافة اللسان: ض ، ل', 'طرف اللسان: ن ، ر ، ط ، د ، ت ، ص ، ز ، س ، ظ ، ذ ، ث'],
      isAvailable: true,
    ),

    // أحكام المدود
    (
      title: 'المدود وأقسامها',
      category: 'أحكام المدود',
      rule: 'إطالة الصوت بحرف من حروف المد الثلاثة (الألف الساكنة المفتوح ما قبلها، الواو الساكنة المضموم ما قبلها، الياء الساكنة المكسور ما قبلها).',
      letters: 'حروف المد الثلاثة: ا ، و ، ي (مجموعة في: نُوحِيهَا)',
      examples: ['المد الطبيعي (حركتان): {قَالَ}، {يَقُولُ}', 'المد المتصل (4-5 حركات): {جَاءَ}، {السَّمَاءِ}', 'المد المنفصل (4-5 حركات): {إِنَّا أَعْطَيْنَاكَ}'],
      isAvailable: true,
    ),
    (
      title: 'المد العارض للسكون والمد اللازم',
      category: 'أحكام المدود',
      rule: 'العارض للسكون: أن يأتي بعد حرف المد حرف ساكن سكوناً عارضاً للوقف. اللازم: أن يأتي بعد حرف المد سكون أصلي وصلاً ووقفاً ويمد 6 حركات.',
      letters: 'حروف المد متبوعة بساكن عارض أو أصلي',
      examples: ['العارض: {الْعَالَمِينَ}، {الرَّحِيمِ}', 'اللازم الكلمي المثقل: {الضَّالِّينَ}، {الصَّاخَّةُ}'],
      isAvailable: false,
    ),
    (
      title: 'صفات الحروف وضدها',
      category: 'صفات الحروف',
      rule: 'الكيفية التي يوصف بها الحرف عند النطق به، وتنقسم إلى صفات لها ضد (كالهمس والجهر، الشدة والرخاوة) وصفات لا ضد لها كالقلب والصفير والقلقلة.',
      letters: 'القلقلة: ق، ط، ب، ج، د (قطب جد) | الهمس: فحثه شخص سكت',
      examples: ['القلقلة: {يَطْمَعُ}، {الْفَلَقِ}', 'الهمس: {يَسْتَبْشِرُونَ}'],
      isAvailable: false,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: TeacherAppBar(
          title: 'حسّن تلاوتك (دروس التجويد)',
          actions: [
            IconButton(
              tooltip: 'المصحف الملون بالتجويد',
              icon: const Icon(Icons.menu_book_rounded, color: ItqanColors.emerald),
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const MushafScreen(tajweedMode: true)),
                );
              },
            ),
          ],
        ),
        body: SafeArea(
          child: Column(
            children: [
              // بطاقة مدخل للمصحف الملون بالتجويد
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [ItqanColors.emerald, ItqanColors.emeraldDark],
                      begin: Alignment.topRight,
                      end: Alignment.bottomLeft,
                    ),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 24),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            Text(
                              'المصحف الملوّن بأحكام التجويد',
                              style: TextStyle(
                                fontFamily: ItqanTypography.uiFont,
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'اقرأ المصحف مباشرة مع ترميز ملون لكل حكم تجويدي',
                              style: TextStyle(
                                fontFamily: ItqanTypography.uiFont,
                                fontSize: 12,
                                color: Colors.white70,
                              ),
                            ),
                          ],
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => const MushafScreen(tajweedMode: true)),
                          );
                        },
                        style: TextButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: ItqanColors.emeraldDark,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                        child: const Text(
                          'تصفح الآن',
                          style: TextStyle(
                            fontFamily: ItqanTypography.uiFont,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // تبويبات الفئات
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Theme.of(context).dividerColor),
                ),
                child: TabBar(
                  controller: _tabController,
                  isScrollable: true,
                  tabAlignment: TabAlignment.start,
                  indicatorSize: TabBarIndicatorSize.tab,
                  indicator: BoxDecoration(
                    color: ItqanColors.emerald,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  labelColor: Colors.white,
                  unselectedLabelColor: ItqanColors.inkSoft,
                  labelStyle: const TextStyle(
                    fontFamily: ItqanTypography.uiFont,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                  unselectedLabelStyle: const TextStyle(
                    fontFamily: ItqanTypography.uiFont,
                    fontSize: 13,
                  ),
                  tabs: const [
                    Tab(text: 'النون الساكنة'),
                    Tab(text: 'الميم الساكنة'),
                    Tab(text: 'مخارج الحروف'),
                    Tab(text: 'المدود والصفات'),
                  ],
                ),
              ),

              // قائمة الدروس في التبويب
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildLessonList('النون الساكنة والتنوين'),
                    _buildLessonList('الميم الساكنة'),
                    _buildLessonList('مخارج الحروف'),
                    _buildLessonListForCategories(['أحكام المدود', 'صفات الحروف']),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLessonList(String category) {
    final filtered = _lessons.where((l) => l.category == category).toList();
    return _buildCards(filtered);
  }

  Widget _buildLessonListForCategories(List<String> categories) {
    final filtered = _lessons.where((l) => categories.contains(l.category)).toList();
    return _buildCards(filtered);
  }

  Widget _buildCards(List<({String title, String category, String rule, String letters, List<String> examples, bool isAvailable})> lessons) {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: lessons.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final lesson = lessons[index];
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Theme.of(context).dividerColor),
            boxShadow: [
              BoxShadow(
                color: ItqanColors.ink.withValues(alpha: 0.04),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: ExpansionTile(
            shape: const Border(),
            leading: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: lesson.isAvailable
                    ? ItqanColors.emerald.withValues(alpha: 0.12)
                    : ItqanColors.muted.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                lesson.isAvailable ? Icons.check_circle_outline_rounded : Icons.lock_clock_rounded,
                color: lesson.isAvailable ? ItqanColors.emerald : ItqanColors.muted,
                size: 20,
              ),
            ),
            title: Row(
              children: [
                Expanded(
                  child: Text(
                    lesson.title,
                    style: const TextStyle(
                      fontFamily: ItqanTypography.uiFont,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: ItqanColors.ink,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: lesson.isAvailable
                        ? ItqanColors.emerald.withValues(alpha: 0.1)
                        : Colors.orange.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    lesson.isAvailable ? 'متاح للمدارسة' : 'قريباً',
                    style: TextStyle(
                      fontFamily: ItqanTypography.uiFont,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: lesson.isAvailable ? ItqanColors.emerald : Colors.orange,
                    ),
                  ),
                ),
              ],
            ),
            subtitle: Text(
              lesson.category,
              style: const TextStyle(
                fontFamily: ItqanTypography.uiFont,
                fontSize: 12,
                color: ItqanColors.muted,
              ),
            ),
            childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            children: [
              const Divider(height: 16),
              // الشرح والقاعدة
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'تعريف الحكم والقاعدة:',
                    style: TextStyle(
                      fontFamily: ItqanTypography.uiFont,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: ItqanColors.emeraldDark,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    lesson.rule,
                    style: const TextStyle(
                      fontFamily: ItqanTypography.uiFont,
                      fontSize: 13,
                      height: 1.5,
                      color: ItqanColors.inkSoft,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // الحروف
                  const Text(
                    'حروف الحكم:',
                    style: TextStyle(
                      fontFamily: ItqanTypography.uiFont,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: ItqanColors.emeraldDark,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: ItqanColors.emerald.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      lesson.letters,
                      style: const TextStyle(
                        fontFamily: ItqanTypography.arabicFont,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: ItqanColors.emeraldDark,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // الأمثلة القرآنية
                  const Text(
                    'أمثلة قرآنية توضيحية:',
                    style: TextStyle(
                      fontFamily: ItqanTypography.uiFont,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: ItqanColors.emeraldDark,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: lesson.examples.map((ex) => Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardColor,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: ItqanColors.border),
                      ),
                      child: Text(
                        ex,
                        style: const TextStyle(
                          fontFamily: ItqanTypography.arabicFont,
                          fontSize: 15,
                          color: ItqanColors.ink,
                        ),
                      ),
                    )).toList(),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

