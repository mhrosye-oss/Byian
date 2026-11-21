import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/localization/app_localizations.dart';
import '../../core/settings/app_settings_provider.dart';
import '../home/home_screen.dart';
import '../auth/screens/login_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _controller = PageController();
  int _currentPage = 0;

  // إجمالي الصفحات: اختيار اللغة + 3 صفحات ترحيب = 4
  static const int _totalPages = 4;

  static const _languages = <Map<String, String>>[
    {'code': 'ar', 'name': 'العربية', 'flag': '🇸🇦'},
    {'code': 'en', 'name': 'English', 'flag': '🇬🇧'},
    {'code': 'fr', 'name': 'Français', 'flag': '🇫🇷'},
    {'code': 'id', 'name': 'Bahasa Indonesia', 'flag': '🇮🇩'},
    {'code': 'bn', 'name': 'বাংলা', 'flag': '🇧🇩'},
    {'code': 'hi', 'name': 'हिन्दी', 'flag': '🇮🇳'},
    {'code': 'tr', 'name': 'Türkçe', 'flag': '🇹🇷'},
    {'code': 'ur', 'name': 'اردو', 'flag': '🇵🇰'},
    {'code': 'uz', 'name': "Oʻzbekcha", 'flag': '🇺🇿'},
    {'code': 'es', 'name': 'Español', 'flag': '🇪🇸'},
  ];

  String _selectedLang = 'ar';

  Future<void> _applyLanguage(String code) async {
    setState(() => _selectedLang = code);
    if (!mounted) return;
    try {
      await AppSettingsScope.of(context).setLocale(Locale(code));
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text('تم حفظ اللغة محليًا، لكن تعذر تحديثها على الخادم: $error'),
        ),
      );
    }
  }

  Future<void> _finish() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_completed', true);
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const HomeScreen()),
    );
  }

  void _next() {
    if (_currentPage == _totalPages - 1) {
      _finish();
    } else {
      _controller.nextPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // ─── صفحة اختيار اللغة ─────────────────────────────────────────────────
  Widget _buildLanguagePage() {
    final l = AppLocalizations.tr;
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
      child: Column(
        children: [
          const SizedBox(height: 8),
          const Icon(Icons.language_rounded,
              size: 60, color: Color(0xFF1B5E20)),
          const SizedBox(height: 16),
          Text(
            l(context, 'choose_language'),
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1B5E20),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Select your preferred language / اختر لغتك المفضلة',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: GridView.builder(
              itemCount: _languages.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 2.8,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
              ),
              itemBuilder: (_, i) {
                final lang = _languages[i];
                final code = lang['code']!;
                final isSelected = _selectedLang == code;
                return GestureDetector(
                  onTap: () => _applyLanguage(code),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    decoration: BoxDecoration(
                      color:
                          isSelected ? const Color(0xFF1B5E20) : Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isSelected
                            ? const Color(0xFF1B5E20)
                            : Colors.grey.shade300,
                        width: 2,
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: const Color(0xFF1B5E20)
                                    .withValues(alpha: .25),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              )
                            ]
                          : [],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(lang['flag']!,
                            style: const TextStyle(fontSize: 22)),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            lang['name']!,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: isSelected ? Colors.white : Colors.black87,
                            ),
                          ),
                        ),
                        if (isSelected) ...[
                          const SizedBox(width: 4),
                          const Icon(Icons.check_circle,
                              color: Colors.white, size: 16),
                        ],
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // ─── صفحات الترحيب ─────────────────────────────────────────────────────
  Widget _buildWelcomePage({
    required String titleKey,
    required String subtitleKey,
    required IconData icon,
    Color? iconColor,
  }) {
    final l = AppLocalizations.tr;
    return Padding(
      padding: const EdgeInsets.all(40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(30),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF1B5E20).withValues(alpha: .07),
              border: Border.all(
                color: const Color(0xFF1B5E20).withValues(alpha: .2),
                width: 2,
              ),
            ),
            child: Icon(icon,
                size: 80, color: iconColor ?? const Color(0xFF1B5E20)),
          ),
          const SizedBox(height: 40),
          Text(
            l(context, titleKey),
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 30,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1B5E20),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            l(context, subtitleKey),
            textAlign: TextAlign.center,
            style: const TextStyle(
                fontSize: 17, color: Colors.black54, height: 1.6),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.tr;
    final isLastPage = _currentPage == _totalPages - 1;

    return Scaffold(
      backgroundColor: const Color(0xFFF9F6F0),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        leading: _currentPage > 0
            ? TextButton(
                onPressed: () async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                  );
                  if (result == true && context.mounted) await _finish();
                },
                child: Text(
                  l(context, 'drawer_login'),
                  style: const TextStyle(
                    color: Color(0xFF1B5E20),
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
              )
            : null,
        actions: [
          if (_currentPage > 0)
            TextButton(
              onPressed: _finish,
              child: Text(
                l(context, 'onboarding_skip'),
                style: const TextStyle(
                  color: Colors.grey,
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
      body: PageView(
        controller: _controller,
        onPageChanged: (index) => setState(() => _currentPage = index),
        children: [
          // ── صفحة 0: اختيار اللغة ──────────────────────────────────
          _buildLanguagePage(),

          // ── صفحة 1: مرحبا ─────────────────────────────────────────
          _buildWelcomePage(
            titleKey: 'onboarding_title_1',
            subtitleKey: 'onboarding_sub_1',
            icon: Icons.star_rounded,
          ),

          // ── صفحة 2: مستواك ────────────────────────────────────────
          _buildWelcomePage(
            titleKey: 'onboarding_title_2',
            subtitleKey: 'onboarding_sub_2',
            icon: Icons.school_rounded,
          ),

          // ── صفحة 3: ابدأ ──────────────────────────────────────────
          _buildWelcomePage(
            titleKey: 'onboarding_title_3',
            subtitleKey: 'onboarding_sub_3',
            icon: Icons.menu_book_rounded,
          ),
        ],
      ),
      bottomSheet: Container(
        color: const Color(0xFFF9F6F0),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // نقاط التنقل
            Row(
              children: List.generate(
                _totalPages,
                (index) => AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  margin: const EdgeInsets.only(right: 6),
                  width: _currentPage == index ? 24 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: _currentPage == index
                        ? const Color(0xFF1B5E20)
                        : Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ),

            // زر التالي / البدء
            ElevatedButton(
              onPressed: _next,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1B5E20),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: 28, vertical: 13),
              ),
              child: Text(
                isLastPage
                    ? l(context, 'onboarding_start')
                    : _currentPage == 0
                        ? l(context, 'onboarding_confirm_lang')
                        : l(context, 'onboarding_next'),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
