import 'package:flutter/material.dart';

import '../../core/theme/colors.dart';
import '../about/screens/about_screen.dart';
import '../adhkar/screens/duas_screen.dart';
import '../adhkar/screens/new_adhkar_screen.dart';
import '../adhkar/screens/smart_adhkar_screen.dart';
import '../ai/screens/ai_chat_screen.dart';
import '../asma/screens/asma_screen.dart';
import '../audio/screens/audio_quran_screen.dart';
import '../calendar/screens/hijri_calendar_screen.dart';
import '../engagement/presentation/widgets/banner_slider_widget.dart';
import '../engagement/presentation/widgets/dynamic_popup_widget.dart';
import '../fazakkir/presentation/screens/fazakkir_dashboard_screen.dart';
import '../gamification/presentation/widgets/journey_banner.dart';
import '../hadiths/screens/hadiths_screen.dart';
import '../hifz/screens/group_hifz_screen.dart';
import '../inheritance/screens/inheritance_screen.dart';
import '../itqan_journey/social_share/presentation/share_card_generator_screen.dart';
import '../itqan_journey/world/presentation/itqan_world_screen.dart';
import '../khatmah/screens/group_khatmah_screen.dart';
import '../khatmah/screens/khatmah_screen.dart';
import '../kids/screens/kids_mode_screen.dart';
import '../mushaf/mushafi_view_screen.dart';
import '../nearby_mosques/presentation/nearby_mosques_screen.dart';
import '../notifications/screens/system_notifications_screen.dart';
import '../prayer/screens/prayer_notifications_screen.dart';
import '../prayer/screens/prayer_times_screen.dart';
import '../qibla/screens/qibla_screen.dart';
import '../quran/models/ayah.dart';
import '../quran_mood/screens/mood_quran_screen.dart';
import '../quran_teacher/presentation/screens/quran_teacher_home_screen.dart';
import '../radio/screens/radio_screen.dart';
import '../recitation/recitation_screen.dart';
import '../sacred_places/screens/sacred_places_screen.dart';
import '../settings/settings_screen.dart';
import '../surah_browser/surah_browser_screen.dart';
import '../tafsir/screens/tafsir_screen.dart';
import '../tasbih/screens/smart_tasbih_screen.dart';
import '../waqf/screens/waqf_screen.dart';
import '../zakat/screens/zakat_calculator_screen.dart';
import 'widgets/custom_drawer.dart';
import 'widgets/itqan_bottom_nav_bar.dart';
import 'widgets/next_prayer_banner.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      DynamicPopupWidget.showIfAvailable(
        context,
        placementKey: 'welcome_popup',
        onNavigateRoute: (route) => _open(context, route),
      );
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _open(BuildContext context, String route) {
    final Widget page;
    switch (route) {
      case 'footer_quran':
        page = const SurahBrowserScreen();
        break;
      case 'my_mushaf':
        page = const MushafiViewScreen(initialPage: 1);
        break;
      case 'prayer':
        page = const PrayerTimesScreen();
        break;
      case 'qibla':
        page = const QiblaScreen();
        break;
      case 'recitation':
        page = RecitationScreen(
          ayah: Ayah(
            surahNumber: 1,
            ayahNumber: 1,
            textUthmani: 'بِسْمِ ٱللّٰهِ ٱلرَّحْمٰنِ ٱلرَّحِيمِ',
            words: const [],
            translation: 'باسم الله الرحمن الرحيم',
          ),
          surahName: 'الفاتحة',
        );
        break;
      case 'adhkar':
        page = const NewAdhkarScreen();
        break;
      case 'smart_adhkar':
        page = const SmartAdhkarScreen();
        break;
      case 'duas':
        page = const DuasScreen();
        break;
      case 'tasbih':
        page = const SmartTasbihScreen();
        break;
      case 'calendar':
        page = const HijriCalendarScreen();
        break;
      case 'hadith':
        page = const HadithsScreen();
        break;
      case 'asma':
        page = const AsmaScreen();
        break;
      case 'group_khatmah':
        page = const GroupKhatmahScreen();
        break;
      case 'group_hifz':
        page = const GroupHifzScreen();
        break;
      case 'mood_quran':
        page = const MoodQuranScreen();
        break;
      case 'khatmah':
        page = const KhatmahScreen();
        break;
      case 'zakat':
        page = const ZakatCalculatorScreen();
        break;
      case 'radio':
        page = const RadioScreen();
        break;
      case 'settings':
        page = const SettingsScreen();
        break;
      case 'tafsir':
        page = const TafsirScreen();
        break;
      case 'teacher_home':
        page = const QuranTeacherHomeScreen();
        break;
      case 'audio':
        page = const AudioQuranScreen();
        break;
      case 'ai':
        page = const AiChatScreen();
        break;
      case 'about':
        page = const AboutScreen();
        break;
      case 'inheritance':
        page = const InheritanceScreen();
        break;
      case 'sacred_places':
        page = const SacredPlacesScreen();
        break;
      case 'waqf':
        page = const WaqfScreen();
        break;
      case 'kids_mode':
        page = const KidsModeScreen();
        break;
      case 'itqan_world':
        page = const ItqanWorldScreen();
        break;
      case 'social_share':
        page = const ShareCardGeneratorScreen();
        break;
      case 'fazakkir':
        page = const FazakkirDashboardScreen();
        break;
      case 'nearby_mosques':
        page = const NearbyMosquesScreen();
        break;
      case 'prayer_notifications':
        page = const PrayerNotificationsScreen();
        break;
      case 'system_notifications':
        page = const SystemNotificationsScreen();
        break;
      default:
        return;
    }
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => page));
  }

  // 22 services matching the exact screenshot
  List<({String title, String subtitle, String route, IconData icon, Color bg, Color iconColor})>
      _getAllServices(BuildContext context) {
    return [
      (
        title: 'مواقيت الصلاة',
        subtitle: 'مواقيت الأذان والصلوات',
        route: 'prayer',
        icon: Icons.access_time_filled_rounded,
        bg: const Color(0xFFEEF2FF),
        iconColor: const Color(0xFF4F46E5),
      ),
      (
        title: 'المصحف الشريف',
        subtitle: 'قراءة وتدبر الآيات',
        route: 'my_mushaf',
        icon: Icons.menu_book_rounded,
        bg: const Color(0xFFECFDF5),
        iconColor: const Color(0xFF059669),
      ),
      (
        title: 'اتجاه القبلة',
        subtitle: 'تحديد القبلة بدقة',
        route: 'qibla',
        icon: Icons.explore_rounded,
        bg: const Color(0xFFFEF3C7),
        iconColor: const Color(0xFFD97706),
      ),
      (
        title: 'المسبحة',
        subtitle: 'عداد استغفار وتسبيح',
        route: 'tasbih',
        icon: Icons.fingerprint_rounded,
        bg: const Color(0xFFF0FDF4),
        iconColor: const Color(0xFF16A34A),
      ),
      (
        title: 'الأذكار والأدعية',
        subtitle: 'صباح، مساء، وأدعية',
        route: 'adhkar',
        icon: Icons.spa_rounded,
        bg: const Color(0xFFF0FDFA),
        iconColor: const Color(0xFF0D9488),
      ),
      (
        title: 'حديث اليوم',
        subtitle: 'أحاديث نبوية شريفة',
        route: 'hadith',
        icon: Icons.format_quote_rounded,
        bg: const Color(0xFFFFF7ED),
        iconColor: const Color(0xFFEA580C),
      ),
      (
        title: 'حاسبة الزكاة',
        subtitle: 'حساب زكاة المال',
        route: 'zakat',
        icon: Icons.volunteer_activism_rounded,
        bg: const Color(0xFFFEF9C3),
        iconColor: const Color(0xFFCA8A04),
      ),
      (
        title: 'التقويم الهجري',
        subtitle: 'مناسبات وأيام بيض',
        route: 'calendar',
        icon: Icons.calendar_month_rounded,
        bg: const Color(0xFFECFEFF),
        iconColor: const Color(0xFF0891B2),
      ),
      (
        title: 'جدول الصلوات',
        subtitle: 'جدول شهري للمواقيت',
        route: 'prayer',
        icon: Icons.schedule_rounded,
        bg: const Color(0xFFECFDF5),
        iconColor: const Color(0xFF047857),
      ),
      (
        title: 'مساجد قريبة',
        subtitle: 'العثور على أقرب مسجد',
        route: 'nearby_mosques',
        icon: Icons.mosque_rounded,
        bg: const Color(0xFFF0F9FF),
        iconColor: const Color(0xFF0284C7),
      ),
      (
        title: 'الصيام',
        subtitle: 'إمساك وإفطار وتذكير',
        route: 'calendar',
        icon: Icons.nights_stay_rounded,
        bg: const Color(0xFFFAF5FF),
        iconColor: const Color(0xFF9333EA),
      ),
      (
        title: 'الحج والعمرة',
        subtitle: 'خطوات ومناسك',
        route: 'sacred_places',
        icon: Icons.mosque_rounded,
        bg: const Color(0xFFFFFBEB),
        iconColor: const Color(0xFFB45309),
      ),
      (
        title: 'الحصانة والرقية',
        subtitle: 'أذكار وأدعية التحصين',
        route: 'smart_adhkar',
        icon: Icons.shield_rounded,
        bg: const Color(0xFFE6FFFA),
        iconColor: const Color(0xFF2C7A7B),
      ),
      (
        title: 'أسماء الله',
        subtitle: '99 اسماً وشرحها',
        route: 'asma',
        icon: Icons.local_florist_rounded,
        bg: const Color(0xFFFEF9C3),
        iconColor: const Color(0xFFB45309),
      ),
      (
        title: 'السيرة النبوية',
        subtitle: 'محطات السيرة العطرة',
        route: 'hadith',
        icon: Icons.auto_stories_rounded,
        bg: const Color(0xFFF0FDF4),
        iconColor: const Color(0xFF15803D),
      ),
      (
        title: 'تعليم الصلاة',
        subtitle: 'خطوة بخطوة للجميع',
        route: 'teacher_home',
        icon: Icons.accessibility_new_rounded,
        bg: const Color(0xFFE0F2FE),
        iconColor: const Color(0xFF0369A1),
      ),
      (
        title: 'الصدقة والوقف',
        subtitle: 'أبواب الخير والعطاء',
        route: 'waqf',
        icon: Icons.favorite_rounded,
        bg: const Color(0xFFFFF1F2),
        iconColor: const Color(0xFFE11D48),
      ),
      (
        title: 'القرآن الصوتي',
        subtitle: 'تلاوات بأصوات القراء',
        route: 'audio',
        icon: Icons.graphic_eq_rounded,
        bg: const Color(0xFFCCFBF1),
        iconColor: const Color(0xFF0F766E),
      ),
      (
        title: 'أدعية مختارة',
        subtitle: 'أدعية مأثورة وشاملة',
        route: 'duas',
        icon: Icons.pan_tool_rounded,
        bg: const Color(0xFFF3E8FF),
        iconColor: const Color(0xFF7E22CE),
      ),
      (
        title: 'الإعدادات',
        subtitle: 'تخصيص التطبيق',
        route: 'settings',
        icon: Icons.tune_rounded,
        bg: const Color(0xFFF1F5F9),
        iconColor: const Color(0xFF475569),
      ),
      (
        title: 'تصوير الشاشة 📸',
        subtitle: 'مشاركة البطاقات والآيات',
        route: 'social_share',
        icon: Icons.camera_alt_rounded,
        bg: const Color(0xFFFEF3C7),
        iconColor: const Color(0xFFD97706),
      ),
      (
        title: 'وثيقة المساعد 📄',
        subtitle: 'دليل وخدمات الذكاء',
        route: 'ai',
        icon: Icons.description_rounded,
        bg: const Color(0xFFFEF9C3),
        iconColor: const Color(0xFFB45309),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final allServices = _getAllServices(context);
    final filteredServices = _searchQuery.trim().isEmpty
        ? allServices
        : allServices.where((s) {
            final q = _searchQuery.trim().toLowerCase();
            return s.title.toLowerCase().contains(q) ||
                s.subtitle.toLowerCase().contains(q);
          }).toList();

    return Scaffold(
      key: _scaffoldKey,
      drawer: const CustomDrawer(),
      backgroundColor: ItqanColors.cream,
      body: SafeArea(
        bottom: false,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(18, 14, 18, 30),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  // 1. Next Prayer Hero Card (Forest Green curved countdown card)
                  NextPrayerBanner(
                    onOpenPrayerTimes: () => _open(context, 'prayer'),
                    onOpenDrawer: () => _scaffoldKey.currentState?.openDrawer(),
                  ),

                  // Banners (home_top_desktop) - Between NextPrayerBanner and JourneyBanner
                  BannerSliderWidget(
                    placementKey: 'home_top_desktop',
                    onNavigateRoute: (route) => _open(context, route),
                    padding: const EdgeInsets.only(top: 18),
                  ),

                  const SizedBox(height: 18),

                  // 2. Faith Journey Card (رحلتك الإيمانية)
                  const JourneyBanner(),

                  const SizedBox(height: 24),

                  // 3. Daily Space Header (مساحتك اليومية)
                  _buildSectionHeader(
                    title: 'مساحتك اليومية',
                    actionLabel: 'عرض الكل',
                    onAction: () => _open(context, 'footer_quran'),
                  ),

                  const SizedBox(height: 12),

                  // 4. Daily Space Bento (Big card right, 3 stacked cards left in RTL)
                  _buildDailySpaceBento(context),

                  const SizedBox(height: 12),

                  // 5. Two Cards Row (دعاء اليوم & أذكار المساء)
                  _buildDailyTwoCardsRow(context),

                  const SizedBox(height: 28),

                  // 6. All Islamic Services Header
                  _buildSectionHeader(
                    title: 'جميع الخدمات الإسلامية',
                    badge: '${allServices.length} خدمة',
                  ),

                  const SizedBox(height: 14),

                  // 7. Search Bar
                  _buildSearchBar(),

                  const SizedBox(height: 16),

                  // 8. 3-Column Services Grid
                  _buildServicesGrid(context, filteredServices),

                  const SizedBox(height: 24),

                  // 9. Footer Note
                  _buildFooterNote(context),
                ]),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: ItqanBottomNavBar(
        selectedIndex: 0,
        onTabSelected: (index) {
          if (index == 0) {
            // Already on home screen
          }
        },
        onOpenPrayer: () => _open(context, 'prayer'),
        onOpenMushaf: () => _open(context, 'my_mushaf'),
        onOpenTasbih: () => _open(context, 'tasbih'),
        onOpenDrawer: () => _scaffoldKey.currentState?.openDrawer(),
      ),
    );
  }

  // ── Section Header ──────────────────────────────────────────────────────────
  Widget _buildSectionHeader({
    required String title,
    String? actionLabel,
    String? badge,
    VoidCallback? onAction,
  }) {
    return Row(
      children: [
        if (actionLabel != null)
          InkWell(
            onTap: onAction,
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.chevron_left_rounded,
                      size: 18, color: Color(0xFFD97706)),
                  Text(
                    actionLabel,
                    style: const TextStyle(
                      fontFamily: 'Tajawal',
                      color: Color(0xFFD97706),
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          )
        else if (badge != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: ItqanColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: ItqanColors.border),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.grid_view_rounded,
                    size: 13, color: ItqanColors.inkSoft),
                const SizedBox(width: 4),
                Text(
                  badge,
                  style: const TextStyle(
                    fontFamily: 'Tajawal',
                    color: ItqanColors.inkSoft,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        const Spacer(),
        Text(
          title,
          style: const TextStyle(
            fontFamily: 'Tajawal',
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: ItqanColors.ink,
          ),
        ),
      ],
    );
  }

  // ── Daily Space Bento (Big card right, 3 small left) ─────────────────────────
  Widget _buildDailySpaceBento(BuildContext context) {
    return SizedBox(
      height: 228,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Left: 3 Stacked Cards (القبلة, التسبيح, أذكار المساء)
          Expanded(
            flex: 5,
            child: Column(
              children: [
                Expanded(
                  child: _buildSmallHorizontalCard(
                    title: 'معلّم القرآن',
                    subtitle: 'احفظ وسمّع وراجع',
                    icon: Icons.record_voice_over_rounded,
                    iconBg: const Color(0xFFFEF3C7),
                    iconColor: const Color(0xFFD97706),
                    onTap: () => _open(context, 'teacher_home'),
                  ),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: _buildSmallHorizontalCard(
                    title: 'التسبيح',
                    subtitle: 'سبحان الله 33/100',
                    icon: Icons.fingerprint_rounded,
                    iconBg: const Color(0xFFD1FAE5),
                    iconColor: const Color(0xFF059669),
                    onTap: () => _open(context, 'tasbih'),
                  ),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: _buildSmallHorizontalCard(
                    title: 'أذكار المساء',
                    subtitle: 'تم إتمام 2 من 5',
                    icon: Icons.nights_stay_rounded,
                    iconBg: const Color(0xFF064E3B),
                    iconColor: Colors.white,
                    onTap: () => _open(context, 'adhkar'),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 10),

          // Right: Big Dark Green Card (ورد اليوم: سورة الكهف)
          Expanded(
            flex: 6,
            child: Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(24),
              child: InkWell(
                borderRadius: BorderRadius.circular(24),
                onTap: () => _open(context, 'my_mushaf'),
                child: Ink(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topRight,
                      end: Alignment.bottomLeft,
                      colors: [
                        Color(0xFF064E3B),
                        Color(0xFF04382A),
                        Color(0xFF02261C),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF064E3B).withValues(alpha: 0.28),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Tag at top: "ورد اليوم"
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                              color: Colors.white.withValues(alpha: 0.2)),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'ورد اليوم',
                              style: TextStyle(
                                fontFamily: 'Tajawal',
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(width: 4),
                            Icon(Icons.menu_book_rounded,
                                size: 13, color: Color(0xFF34D399)),
                          ],
                        ),
                      ),

                      // Surah Title & details
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          const Text(
                            'سورة الكهف',
                            style: TextStyle(
                              fontFamily: 'Tajawal',
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'الصفحة 293 من 604 • الحزب 30',
                            style: TextStyle(
                              fontFamily: 'Tajawal',
                              color: Colors.white.withValues(alpha: 0.72),
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 10),

                          // Reading progress bar
                          ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: Container(
                              height: 6,
                              color: Colors.white.withValues(alpha: 0.15),
                              child: Align(
                                alignment: Alignment.centerRight,
                                child: FractionallySizedBox(
                                  widthFactor: 0.48,
                                  child: Container(
                                    decoration: const BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          Color(0xFFFBBF24),
                                          Color(0xFF34D399),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),

                      // Bottom link: "أكمل القراءة ←"
                      const Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          Icon(Icons.arrow_back_rounded,
                              size: 15, color: Color(0xFFFBBF24)),
                          SizedBox(width: 4),
                          Text(
                            'أكمل القراءة',
                            style: TextStyle(
                              fontFamily: 'Tajawal',
                              color: Color(0xFFFBBF24),
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Small Horizontal Bento Card ─────────────────────────────────────────────
  Widget _buildSmallHorizontalCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    return Material(
      color: ItqanColors.surface,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: ItqanColors.border),
            boxShadow: [
              BoxShadow(
                color: ItqanColors.ink.withValues(alpha: 0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              const Icon(Icons.chevron_left_rounded,
                  size: 16, color: ItqanColors.muted),
              const Spacer(),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontFamily: 'Tajawal',
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: ItqanColors.ink,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontFamily: 'Tajawal',
                      fontSize: 9.5,
                      color: ItqanColors.muted,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 8),
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, size: 18, color: iconColor),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Two Cards Row: دعاء اليوم & أذكار المساء ────────────────────────────────
  Widget _buildDailyTwoCardsRow(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _buildSmallHorizontalCard(
            title: 'دعاء اليوم',
            subtitle: 'دعاء تيسير الأمور والفرج',
            icon: Icons.pan_tool_rounded,
            iconBg: const Color(0xFFF3E8FF),
            iconColor: const Color(0xFF7E22CE),
            onTap: () => _open(context, 'duas'),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildSmallHorizontalCard(
            title: 'أذكار المساء',
            subtitle: 'حصنك اليومي والسكينة',
            icon: Icons.spa_rounded,
            iconBg: const Color(0xFFCCFBF1),
            iconColor: const Color(0xFF0D9488),
            onTap: () => _open(context, 'adhkar'),
          ),
        ),
      ],
    );
  }

  // ── Search Bar ──────────────────────────────────────────────────────────────
  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: ItqanColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: ItqanColors.border),
        boxShadow: [
          BoxShadow(
            color: ItqanColors.ink.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        onChanged: (val) => setState(() => _searchQuery = val),
        textAlign: TextAlign.right,
        decoration: InputDecoration(
          hintText: 'ابحث عن خدمة، سورة، أو ذكر...',
          hintStyle: const TextStyle(
            fontFamily: 'Tajawal',
            color: ItqanColors.muted,
            fontSize: 13,
          ),
          prefixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.close_rounded,
                      size: 18, color: ItqanColors.muted),
                  onPressed: () {
                    _searchController.clear();
                    setState(() => _searchQuery = '');
                  },
                )
              : null,
          suffixIcon: const Icon(Icons.search_rounded,
              color: ItqanColors.emerald, size: 22),
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }

  // ── 3-Column Services Grid ──────────────────────────────────────────────────
  Widget _buildServicesGrid(
    BuildContext context,
    List<({String title, String subtitle, String route, IconData icon, Color bg, Color iconColor})>
        services,
  ) {
    if (services.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(28),
        alignment: Alignment.center,
        child: const Text(
          'لا توجد خدمات مطابقة لبحثك',
          style: TextStyle(
            fontFamily: 'Tajawal',
            fontSize: 14,
            color: ItqanColors.muted,
          ),
        ),
      );
    }

    return GridView.builder(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      itemCount: services.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 0.88,
      ),
      itemBuilder: (context, index) {
        final s = services[index];
        return _buildServiceTile(
          title: s.title,
          subtitle: s.subtitle,
          icon: s.icon,
          bgColor: s.bg,
          iconColor: s.iconColor,
          onTap: () => _open(context, s.route),
        );
      },
    );
  }

  // ── Single Service Tile ─────────────────────────────────────────────────────
  Widget _buildServiceTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color bgColor,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    return Material(
      color: ItqanColors.surface,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: ItqanColors.border),
            boxShadow: [
              BoxShadow(
                color: ItqanColors.ink.withValues(alpha: 0.035),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, size: 22, color: iconColor),
              ),
              const SizedBox(height: 8),
              Text(
                title,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontFamily: 'Tajawal',
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: ItqanColors.ink,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontFamily: 'Tajawal',
                  fontSize: 9.5,
                  color: ItqanColors.muted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Footer Note ─────────────────────────────────────────────────────────────
  Widget _buildFooterNote(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.centerRight,
          end: Alignment.centerLeft,
          colors: [
            ItqanColors.roseGold.withValues(alpha: 0.12),
            ItqanColors.roseGold.withValues(alpha: 0.04),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: ItqanColors.roseGold.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: ItqanColors.roseGold.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.favorite_rounded,
                color: ItqanColors.roseGold, size: 16),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'خطوة صغيرة كل يوم تصنع أثرًا كبيرًا',
              style: TextStyle(
                fontFamily: 'Tajawal',
                color: Theme.of(context).textTheme.bodyLarge?.color ??
                    Colors.black,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
              textDirection: TextDirection.rtl,
            ),
          ),
          const SizedBox(width: 8),
          const Icon(Icons.auto_awesome_rounded,
              color: ItqanColors.emerald, size: 18),
        ],
      ),
    );
  }
}
