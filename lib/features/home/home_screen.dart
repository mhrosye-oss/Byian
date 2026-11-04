import 'package:flutter/material.dart';
import 'widgets/custom_drawer.dart';

import '../../core/theme/colors.dart';
import '../../core/theme/typography.dart';
import '../adhkar/screens/new_adhkar_screen.dart';
import '../about/screens/about_screen.dart';
import '../ai/screens/ai_chat_screen.dart';
import '../audio/screens/audio_quran_screen.dart';
import '../asma/screens/asma_screen.dart';
import '../calendar/screens/hijri_calendar_screen.dart';
import '../hadiths/screens/hadiths_screen.dart';
import '../khatmah/screens/khatmah_screen.dart';
import '../mushaf/qcf_quran_screen.dart';
import '../prayer/screens/prayer_times_screen.dart';
import '../qibla/screens/qibla_screen.dart';
import '../quran/models/ayah.dart';
import '../radio/screens/radio_screen.dart';
import '../recitation/recitation_screen.dart';
import '../settings/settings_screen.dart';
import '../tafsir/screens/tafsir_screen.dart';
import '../tajweed/tajweed_screen.dart';
import '../tasbih/screens/smart_tasbih_screen.dart';
import '../zakat/screens/zakat_calculator_screen.dart';
import 'widgets/next_prayer_banner.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  void _open(BuildContext context, String route) {
    final Widget page;
    switch (route) {
      case 'quran': page = const QcfQuranScreen(); break;
      case 'prayer': page = const PrayerTimesScreen(); break;
      case 'qibla': page = const QiblaScreen(); break;
      case 'recitation':
        page = RecitationScreen(
          ayah: Ayah(surahNumber: 1, ayahNumber: 1,
            textUthmani: 'بِسْمِ ٱللّٰهِ ٱلرَّحْمٰنِ ٱلرَّحِيمِ',
            words: const [], translation: 'باسم الله الرحمن الرحيم'),
          surahName: 'الفاتحة',
        );
        break;
      case 'adhkar': page = const NewAdhkarScreen(); break;
      case 'tasbih': page = const SmartTasbihScreen(); break;
      case 'calendar': page = const HijriCalendarScreen(); break;
      case 'hadith': page = const HadithsScreen(); break;
      case 'asma': page = const AsmaScreen(); break;
      case 'khatmah': page = const KhatmahScreen(); break;
      case 'zakat': page = const ZakatCalculatorScreen(); break;
      case 'radio': page = const RadioScreen(); break;
      case 'settings': page = const SettingsScreen(); break;
      case 'tafsir': page = const TafsirScreen(); break;
      case 'tajweed': page = const TajweedScreen(); break;
      case 'audio': page = const AudioQuranScreen(); break;
      case 'ai': page = const AiChatScreen(); break;
      case 'about': page = const AboutScreen(); break;
      default: return;
    }
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => page));
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        drawer: const CustomDrawer(),
        backgroundColor: ItqanColors.cream,
        body: SafeArea(
          bottom: false,
          child: CustomScrollView(
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                sliver: SliverList(delegate: SliverChildListDelegate([
                  _buildHeader(context),
                  const SizedBox(height: 22),
                  NextPrayerBanner(onOpenPrayerTimes: () => _open(context, 'prayer')),
                  const SizedBox(height: 24),
                  _sectionHeader('مساحتك اليومية', 'وصول سريع'),
                  const SizedBox(height: 13),
                  _buildFeaturedBento(context),
                  const SizedBox(height: 12),
                  _buildThreeCardRow(context),
                  const SizedBox(height: 24),
                  _sectionHeader('اكتشف المزيد', 'خدمات إتقان'),
                  const SizedBox(height: 12),
                  _buildMoreServices(context),
                  const SizedBox(height: 18),
                  _buildFooterNote(),
                ])),
              ),
            ],
          ),
        ),
        bottomNavigationBar: NavigationBar(
          height: 70,
          selectedIndex: 0,
          onDestinationSelected: (index) {
            switch (index) {
              case 1: _open(context, 'quran'); break;
              case 2: _open(context, 'prayer'); break;
              case 3: _open(context, 'settings'); break;
            }
          },
          destinations: const [
            NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home_rounded), label: 'الرئيسية'),
            NavigationDestination(icon: Icon(Icons.menu_book_outlined), selectedIcon: Icon(Icons.menu_book_rounded), label: 'القرآن'),
            NavigationDestination(icon: Icon(Icons.access_time_outlined), selectedIcon: Icon(Icons.access_time_filled_rounded), label: 'الصلاة'),
            NavigationDestination(icon: Icon(Icons.tune_rounded), label: 'الإعدادات'),
          ],
        ),
      );

  Widget _buildHeader(BuildContext context) => Row(children: [
        Container(width: 48, height: 48,
          decoration: BoxDecoration(color: ItqanColors.emerald.withValues(alpha: .09), borderRadius: BorderRadius.circular(17)),
          child: const Icon(Icons.auto_awesome_rounded, color: ItqanColors.emerald, size: 24)),
        const SizedBox(width: 12),
        const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('أهلاً بك في إتقان', style: ItqanTypography.heading2),
          SizedBox(height: 2), Text('مساحة يومية للسكينة والقرآن', style: ItqanTypography.caption),
        ])),
        Builder(builder: (context) => IconButton.filledTonal(
          tooltip: 'القائمة', onPressed: () => Scaffold.of(context).openDrawer(),
          style: IconButton.styleFrom(backgroundColor: ItqanColors.surface, foregroundColor: ItqanColors.emerald),
          icon: const Icon(Icons.menu_rounded))),
      ]);

  Widget _sectionHeader(String title, String trailing) => Row(children: [
        Expanded(child: Text(title, style: ItqanTypography.heading2)),
        Text(trailing, style: ItqanTypography.caption.copyWith(color: ItqanColors.roseGold)),
      ]);

  Widget _buildFeaturedBento(BuildContext context) => SizedBox(
        height: 226,
        child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Expanded(flex: 6, child: _BentoCard(height: 226, title: 'مصحفي', subtitle: 'اقرأ القرآن وتدبّر آياته',
              icon: Icons.menu_book_rounded, onTap: () => _open(context, 'quran'), featured: true)),
          const SizedBox(width: 12),
          Expanded(flex: 4, child: Column(children: [
            Expanded(child: _BentoCard(title: 'تلاوتي', subtitle: 'استمع وتعلّم', icon: Icons.graphic_eq_rounded,
                onTap: () => _open(context, 'recitation'), accent: ItqanColors.roseGold)),
            const SizedBox(height: 12),
            Expanded(child: _BentoCard(title: 'القبلة', subtitle: 'اتجاه مكة', icon: Icons.explore_rounded,
                onTap: () => _open(context, 'qibla'))),
          ])),
        ]),
      );

  Widget _buildThreeCardRow(BuildContext context) => Row(children: [
        Expanded(child: _BentoCard(height: 142, title: 'الأذكار', subtitle: 'أذكار يومك', icon: Icons.spa_rounded,
            onTap: () => _open(context, 'adhkar'), accent: ItqanColors.roseGold)),
        const SizedBox(width: 10),
        Expanded(child: _BentoCard(height: 142, title: 'المسبحة', subtitle: 'سبّح واذكر', icon: Icons.radio_button_checked_rounded,
            onTap: () => _open(context, 'tasbih'))),
        const SizedBox(width: 10),
        Expanded(child: _BentoCard(height: 142, title: 'الختمة', subtitle: 'تابع وردك', icon: Icons.auto_stories_rounded,
            onTap: () => _open(context, 'khatmah'), accent: ItqanColors.roseGold)),
      ]);

  Widget _buildMoreServices(BuildContext context) {
    const services = <({String title, String route, IconData icon})>[
      (title: 'التقويم الهجري', route: 'calendar', icon: Icons.calendar_month_rounded),
      (title: 'الأحاديث', route: 'hadith', icon: Icons.format_quote_rounded),
      (title: 'أسماء الله', route: 'asma', icon: Icons.local_florist_rounded),
      (title: 'حاسبة الزكاة', route: 'zakat', icon: Icons.volunteer_activism_rounded),
      (title: 'إذاعة القرآن', route: 'radio', icon: Icons.radio_rounded),
      (title: 'مواقيت الصلاة', route: 'prayer', icon: Icons.access_time_rounded),
      (title: 'الأدعية', route: 'adhkar', icon: Icons.favorite_border_rounded),
      (title: 'التجويد', route: 'tajweed', icon: Icons.menu_book_rounded),
      (title: 'التفاسير', route: 'tafsir', icon: Icons.chrome_reader_mode_rounded),
      (title: 'القرآن الصوتي', route: 'audio', icon: Icons.headphones_rounded),
    ];
    return Wrap(spacing: 9, runSpacing: 9, children: services.map((service) => ActionChip(
      onPressed: () => _open(context, service.route),
      avatar: Icon(service.icon, size: 17, color: ItqanColors.emerald),
      label: Text(service.title),
      labelStyle: const TextStyle(color: ItqanColors.ink, fontSize: 12, fontWeight: FontWeight.w600),
      backgroundColor: ItqanColors.surface,
      side: const BorderSide(color: ItqanColors.border),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
    )).toList());
  }

  Widget _buildFooterNote() => Container(
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 13),
        decoration: BoxDecoration(color: ItqanColors.roseGold.withValues(alpha: .10), borderRadius: BorderRadius.circular(18)),
        child: const Row(children: [
          Icon(Icons.favorite_rounded, color: ItqanColors.roseGold, size: 18),
          SizedBox(width: 10),
          Expanded(child: Text('خطوة صغيرة كل يوم تصنع أثرًا كبيرًا', style: TextStyle(color: ItqanColors.ink, fontSize: 12, fontWeight: FontWeight.w600), textDirection: TextDirection.rtl)),
          Icon(Icons.auto_awesome_rounded, color: ItqanColors.emerald, size: 18),
        ]),
      );
}

class _BentoCard extends StatelessWidget {
  const _BentoCard({required this.title, required this.subtitle, required this.icon, required this.onTap, this.height, this.accent = ItqanColors.emerald, this.featured = false});
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;
  final double? height;
  final Color accent;
  final bool featured;

  @override
  Widget build(BuildContext context) {
    final foreground = featured ? ItqanColors.white : ItqanColors.ink;
    final supporting = featured ? ItqanColors.white.withValues(alpha: .76) : ItqanColors.inkSoft;
    return SizedBox(height: height, child: Material(
      color: featured ? ItqanColors.emerald : ItqanColors.surface,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(onTap: onTap, borderRadius: BorderRadius.circular(20), child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(featured ? 14 : 12),
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(20), border: Border.all(color: featured ? ItqanColors.emerald : ItqanColors.border),
            boxShadow: [BoxShadow(color: ItqanColors.ink.withValues(alpha: .045), blurRadius: 14, offset: const Offset(0, 5))]),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Row(children: [
            Container(width: featured ? 52 : 36, height: featured ? 52 : 36,
              decoration: BoxDecoration(color: featured ? ItqanColors.roseGold : accent.withValues(alpha: .15), borderRadius: BorderRadius.circular(15)),
              child: Icon(icon, color: featured ? ItqanColors.white : accent, size: featured ? 27 : 20)),
            const Spacer(),
            Icon(Icons.north_west_rounded, size: 16, color: featured ? Colors.white70 : ItqanColors.muted),
          ]),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: foreground, fontSize: featured ? 21 : 14.5, fontWeight: FontWeight.w800)),
            const SizedBox(height: 3),
            Text(subtitle, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(color: supporting, fontSize: featured ? 12 : 9.5, height: 1.25)),
          ]),
        ]),
      )),
    ));
  }
}
