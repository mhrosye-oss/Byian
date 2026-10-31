import 'package:flutter/material.dart';
import '../mushaf/mushaf_screen.dart';
import '../prayer/screens/prayer_times_screen.dart';
import '../quran/models/ayah.dart';
import '../recitation/recitation_screen.dart';
import '../tasbih/screens/smart_tasbih_screen.dart';
import '../zakat/screens/zakat_calculator_screen.dart';
import '../qibla/screens/qibla_screen.dart';
import '../adhkar/screens/adhkar_screen.dart';
import '../calendar/screens/hijri_calendar_screen.dart';
import '../hadiths/screens/hadiths_screen.dart';
import '../asma/screens/asma_screen.dart';
import '../khatmah/screens/khatmah_screen.dart';
import '../radio/screens/radio_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});
  static const Color primaryRed = Color(0xFFD32F2F);
  static const Color background = Color(0xFFF8F9FA);
  static const Color white = Color(0xFFFFFFFF);
  static const Color dark = Color(0xFF1A1A1A);

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> services = [
      {'title': 'اقرأ القرآن', 'icon': Icons.menu_book_rounded, 'route': 'quran'},
      {'title': 'مواقيت الصلاة', 'icon': Icons.access_time_rounded, 'route': 'prayer'},
      {'title': 'القبلة', 'icon': Icons.explore_rounded, 'route': 'qibla'},
      {'title': 'التلاوة الذكية', 'icon': Icons.mic_rounded, 'route': 'recitation'},
      {'title': 'الأذكار', 'icon': Icons.self_improvement_rounded, 'route': 'adhkar'},
      {'title': 'المسبحة', 'icon': Icons.favorite_rounded, 'route': 'tasbih'},
      {'title': 'التقويم الهجري', 'icon': Icons.calendar_month_rounded, 'route': 'calendar'},
      {'title': 'الأحاديث', 'icon': Icons.format_quote_rounded, 'route': 'hadith'},
      {'title': 'أسماء الله', 'icon': Icons.abc_rounded, 'route': 'asma'},
      {'title': 'ختمة القرآن', 'icon': Icons.auto_stories_rounded, 'route': 'khatmah'},
      {'title': 'حاسبة الزكاة', 'icon': Icons.account_balance_wallet_rounded, 'route': 'zakat'},
      {'title': 'إذاعة القرآن', 'icon': Icons.radio_rounded, 'route': 'radio'},
    ];

    return Scaffold(
      backgroundColor: background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('أهلاً بك', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: dark), textDirection: TextDirection.rtl),
                      SizedBox(height: 8),
                      Text('١٤٤٦ هـ', style: TextStyle(fontSize: 14, color: dark), textDirection: TextDirection.rtl),
                    ],
                  ),
                  Row(
                    children: [
                      IconButton(onPressed: () {}, icon: const Icon(Icons.notifications_none_rounded), color: dark),
                      IconButton(onPressed: () {}, icon: const Icon(Icons.chat_bubble_outline_rounded), color: dark),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Container(
                width: double.infinity,
                height: 180,
                decoration: BoxDecoration(color: white, borderRadius: BorderRadius.circular(24), boxShadow: const [BoxShadow(color: Color(0x1A000000), blurRadius: 12, offset: Offset(0, 6))]),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: Stack(
                    children: [
                      Container(decoration: const BoxDecoration(gradient: LinearGradient(colors: [Color(0xFFB71C1C), Color(0xFFD32F2F)], begin: Alignment.topLeft, end: Alignment.bottomRight))),
                      const Positioned(
                        right: 16, bottom: 18, left: 16,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('رحلة روحانية يومية', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: Colors.white), textDirection: TextDirection.rtl),
                            SizedBox(height: 6),
                            Text('ابدأ الآن', style: TextStyle(fontSize: 14, color: Colors.white70), textDirection: TextDirection.rtl),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 18),
              const Text('الخدمات', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: dark), textDirection: TextDirection.rtl),
              const SizedBox(height: 16),
              Expanded(
                child: GridView.count(
                  crossAxisCount: 3, mainAxisSpacing: 12, crossAxisSpacing: 12, childAspectRatio: 0.82,
                  children: services.map((service) {
                    final title = service['title'] as String;
                    final icon = service['icon'] as IconData;
                    final route = service['route'] as String;
                    return Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () {
                          switch (route) {
                            case 'quran': Navigator.push(context, MaterialPageRoute(builder: (_) => const MushafScreen())); break;
                            case 'prayer': Navigator.push(context, MaterialPageRoute(builder: (_) => const PrayerTimesScreen())); break;
                            case 'qibla': Navigator.push(context, MaterialPageRoute(builder: (_) => const QiblaScreen())); break;
                            case 'recitation': Navigator.push(context, MaterialPageRoute(builder: (_) => RecitationScreen(ayah: Ayah(surahNumber: 1, ayahNumber: 1, textUthmani: 'بِسْمِ ٱللّٰهِ ٱلرَّحْمٰنِ ٱلرَّحِيمِ', words: const [], translation: 'باسم الله الرحمن الرحيم'), surahName: 'الفاتحة'))); break;
                            case 'adhkar': Navigator.push(context, MaterialPageRoute(builder: (_) => const AdhkarScreen())); break;
                            case 'tasbih': Navigator.push(context, MaterialPageRoute(builder: (_) => const SmartTasbihScreen())); break;
                            case 'calendar': Navigator.push(context, MaterialPageRoute(builder: (_) => const HijriCalendarScreen())); break;
                            case 'hadith': Navigator.push(context, MaterialPageRoute(builder: (_) => const HadithsScreen())); break;
                            case 'asma': Navigator.push(context, MaterialPageRoute(builder: (_) => const AsmaScreen())); break;
                            case 'khatmah': Navigator.push(context, MaterialPageRoute(builder: (_) => const KhatmahScreen())); break;
                            case 'zakat': Navigator.push(context, MaterialPageRoute(builder: (_) => const ZakatCalculatorScreen())); break;
                            case 'radio': Navigator.push(context, MaterialPageRoute(builder: (_) => const RadioScreen())); break;
                            default: break;
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(color: white, borderRadius: BorderRadius.circular(18), boxShadow: const [BoxShadow(color: Color(0x1A000000), blurRadius: 8, offset: Offset(0, 4))]),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                width: 48, height: 48,
                                decoration: BoxDecoration(color: const Color(0xFFD32F2F).withOpacity(0.08), borderRadius: BorderRadius.circular(14)),
                                child: Icon(icon, color: primaryRed, size: 24),
                              ),
                              const SizedBox(height: 10),
                              Text(title, textAlign: TextAlign.center, textDirection: TextDirection.rtl, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: dark)),
                            ],
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
