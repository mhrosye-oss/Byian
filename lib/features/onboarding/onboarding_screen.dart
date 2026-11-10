import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/theme/colors.dart';
import '../../core/theme/typography.dart';
import '../auth/screens/login_screen.dart';
import '../auth/screens/register_screen.dart';
import '../home/home_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  static const int _pageCount = 3;

  final PageController _controller = PageController();
  int _currentPage = 0;
  bool _isFinishing = false;

  Future<void> _finish() async {
    if (_isFinishing) return;
    _isFinishing = true;

    final preferences = await SharedPreferences.getInstance();
    await preferences.setBool('onboarding_completed', true);
    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute<void>(builder: (_) => const HomeScreen()),
    );
  }

  Future<void> _goToPage(int page) async {
    await _controller.animateToPage(
      page,
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeInOutCubic,
    );
  }

  void _openLogin() {
    Navigator.push<void>(
      context,
      MaterialPageRoute<void>(builder: (_) => const LoginScreen()),
    );
  }

  void _openRegistration() {
    Navigator.push<void>(
      context,
      MaterialPageRoute<void>(builder: (_) => const RegisterScreen()),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: ItqanColors.cream,
        body: SafeArea(
          child: Column(
            children: [
              _buildTopBar(),
              Expanded(
                child: PageView(
                  controller: _controller,
                  onPageChanged: (index) => setState(() => _currentPage = index),
                  children: [
                    _buildWelcomePage(),
                    _buildJourneyPage(),
                    _buildAccountPage(),
                  ],
                ),
              ),
              _buildPageControls(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar() => Padding(
        padding: const EdgeInsetsDirectional.fromSTEB(22, 10, 22, 4),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: ItqanColors.emerald.withOpacity(.09),
                borderRadius: BorderRadius.circular(13),
              ),
              child: const Icon(
                Icons.auto_awesome_rounded,
                color: ItqanColors.emerald,
                size: 20,
              ),
            ),
            const SizedBox(width: 10),
            const Text('إتقان', style: ItqanTypography.gold),
            const Spacer(),
            if (_currentPage < _pageCount - 1)
              TextButton(
                onPressed: _finish,
                child: const Text(
                  'تخطي',
                  style: TextStyle(
                    fontFamily: ItqanTypography.uiFont,
                    color: ItqanColors.inkSoft,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
          ],
        ),
      );

  Widget _buildWelcomePage() => SingleChildScrollView(
        padding: const EdgeInsetsDirectional.fromSTEB(26, 12, 26, 22),
        child: Column(
          children: [
            const SizedBox(height: 8),
            _buildBookIllustration(),
            const SizedBox(height: 30),
            const Text(
              'ابدأ رحلتك نحو الأفضل',
              textAlign: TextAlign.center,
              style: ItqanTypography.heading1,
            ),
            const SizedBox(height: 14),
            const Text(
              'خطوات صغيرة من الخير تصنع أثراً عظيماً. اجعل لكل يوم بداية جديدة، واقترب من الله بالقرآن والذكر والدعاء والعمل النافع.',
              textAlign: TextAlign.center,
              style: ItqanTypography.body,
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              decoration: BoxDecoration(
                color: ItqanColors.surface,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: ItqanColors.border),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.favorite_rounded,
                      size: 18, color: ItqanColors.roseGold),
                  SizedBox(width: 8),
                  Text(
                    'كل يوم فرصة لبداية طيبة',
                    style: TextStyle(
                      fontFamily: ItqanTypography.uiFont,
                      color: ItqanColors.inkSoft,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );

  Widget _buildBookIllustration() => SizedBox(
        height: 230,
        width: 260,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: 210,
              height: 210,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: ItqanColors.surfaceSoft,
                border: Border.all(color: ItqanColors.border),
              ),
            ),
            Positioned(
              top: 16,
              right: 24,
              child: _decorativeIcon(Icons.star_rounded, 22),
            ),
            Positioned(
              bottom: 30,
              left: 18,
              child: _decorativeIcon(Icons.auto_awesome_rounded, 19),
            ),
            Container(
              width: 132,
              height: 150,
              decoration: BoxDecoration(
                color: ItqanColors.emerald,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: ItqanColors.emerald.withOpacity(.18),
                    blurRadius: 22,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    margin: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.white.withOpacity(.42)),
                    ),
                  ),
                  const Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.menu_book_rounded,
                          color: Colors.white, size: 56),
                      SizedBox(height: 8),
                      Text(
                        'إتقان',
                        style: TextStyle(
                          fontFamily: ItqanTypography.arabicFont,
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Positioned(
              top: 40,
              left: 42,
              child: Container(
                width: 42,
                height: 42,
                decoration: const BoxDecoration(
                  color: ItqanColors.roseGold,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.nightlight_round,
                  color: Colors.white,
                  size: 23,
                ),
              ),
            ),
          ],
        ),
      );

  Widget _decorativeIcon(IconData icon, double size) => Icon(
        icon,
        size: size,
        color: ItqanColors.roseGold.withOpacity(.8),
      );

  Widget _buildJourneyPage() => SingleChildScrollView(
        padding: const EdgeInsetsDirectional.fromSTEB(22, 12, 22, 20),
        child: Column(
          children: [
            const SizedBox(height: 10),
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: ItqanColors.emerald.withOpacity(.09),
                borderRadius: BorderRadius.circular(22),
              ),
              child: const Icon(
                Icons.route_rounded,
                color: ItqanColors.emerald,
                size: 32,
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'كيف تعمل رحلتك؟',
              textAlign: TextAlign.center,
              style: ItqanTypography.heading1,
            ),
            const SizedBox(height: 8),
            const Text(
              'في إتقان، تجعل أعمال الخير جزءاً من يومك، وتتابع خطواتك وإنجازاتك.',
              textAlign: TextAlign.center,
              style: ItqanTypography.body,
            ),
            const SizedBox(height: 20),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.15,
              children: const [
                _JourneyCard(
                  icon: Icons.menu_book_rounded,
                  title: 'القرآن',
                  description: 'اقرأ وتدبر، واجعل لك ورداً يومياً.',
                  accent: ItqanColors.emerald,
                ),
                _JourneyCard(
                  icon: Icons.spa_rounded,
                  title: 'الأذكار',
                  description: 'اجعل ذكر الله جزءاً من يومك.',
                  accent: ItqanColors.roseGold,
                ),
                _JourneyCard(
                  icon: Icons.volunteer_activism_rounded,
                  title: 'الأدعية',
                  description: 'اقرأ الأدعية وتعلمها واحفظ ما تستطيع منها.',
                  accent: ItqanColors.emerald,
                ),
                _JourneyCard(
                  icon: Icons.ios_share_rounded,
                  title: 'مشاركة الخير',
                  description: 'انشر ما ينفع الآخرين من آيات وأذكار وأدعية.',
                  accent: ItqanColors.roseGold,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: ItqanColors.roseGold.withOpacity(.09),
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Text(
                'أنجز مهامك، وتابع تقدمك، واجمع الأوسمة والألقاب خلال رحلتك.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: ItqanTypography.uiFont,
                  color: ItqanColors.ink,
                  fontWeight: FontWeight.w600,
                  height: 1.5,
                ),
              ),
            ),
          ],
        ),
      );

  Widget _buildAccountPage() => SingleChildScrollView(
        padding: const EdgeInsetsDirectional.fromSTEB(26, 10, 26, 20),
        child: Column(
          children: [
            const SizedBox(height: 8),
            Container(
              width: 82,
              height: 82,
              decoration: BoxDecoration(
                color: ItqanColors.emerald.withOpacity(.09),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.volunteer_activism_rounded,
                color: ItqanColors.emerald,
                size: 40,
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'مرحباً بك في إتقان',
              textAlign: TextAlign.center,
              style: ItqanTypography.heading1,
            ),
            const SizedBox(height: 8),
            const Text(
              'ابدأ رحلتك، واجعل الخير عادة في حياتك.',
              textAlign: TextAlign.center,
              style: ItqanTypography.body,
            ),
            const SizedBox(height: 26),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _openLogin,
                icon: const Icon(Icons.login_rounded),
                label: const Text('تسجيل الدخول'),
                style: _primaryButtonStyle(),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _openRegistration,
                icon: const Icon(Icons.person_add_alt_1_rounded),
                label: const Text('إنشاء حساب'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: ItqanColors.emerald,
                  side: const BorderSide(color: ItqanColors.emerald),
                  minimumSize: const Size.fromHeight(52),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  textStyle: const TextStyle(
                    fontFamily: ItqanTypography.uiFont,
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 14),
            const Row(
              children: [
                Expanded(child: Divider(color: ItqanColors.border)),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 14),
                  child: Text(
                    'أو',
                    style: TextStyle(
                      fontFamily: ItqanTypography.uiFont,
                      color: ItqanColors.muted,
                    ),
                  ),
                ),
                Expanded(child: Divider(color: ItqanColors.border)),
              ],
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: null,
                icon: const Icon(Icons.g_mobiledata_rounded, size: 28),
                label: const Text('Google — غير متاح حالياً'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  textStyle: const TextStyle(
                    fontFamily: ItqanTypography.uiFont,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextButton.icon(
              onPressed: _finish,
              icon: const Icon(Icons.person_outline_rounded),
              label: const Text('الدخول كضيف'),
              style: TextButton.styleFrom(
                foregroundColor: ItqanColors.inkSoft,
                textStyle: const TextStyle(
                  fontFamily: ItqanTypography.uiFont,
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
              ),
            ),
          ],
        ),
      );

  ButtonStyle _primaryButtonStyle() => FilledButton.styleFrom(
        backgroundColor: ItqanColors.emerald,
        foregroundColor: Colors.white,
        minimumSize: const Size.fromHeight(54),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        textStyle: const TextStyle(
          fontFamily: ItqanTypography.uiFont,
          fontWeight: FontWeight.w700,
          fontSize: 16,
        ),
      );

  Widget _buildPageControls() => Padding(
        padding: const EdgeInsetsDirectional.fromSTEB(22, 4, 22, 14),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(_pageCount, (index) {
                final isCurrent = _currentPage == index;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: isCurrent ? 25 : 8,
                  height: 8,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    color: isCurrent ? ItqanColors.emerald : ItqanColors.border,
                    borderRadius: BorderRadius.circular(8),
                  ),
                );
              }),
            ),
            const SizedBox(height: 14),
            SizedBox(
              height: 48,
              child: Row(
                children: [
                  if (_currentPage > 0)
                    TextButton.icon(
                      onPressed: () => _goToPage(_currentPage - 1),
                      icon: const Icon(Icons.arrow_forward_rounded, size: 18),
                      label: const Text('السابق'),
                      style: TextButton.styleFrom(
                        foregroundColor: ItqanColors.inkSoft,
                        textStyle: const TextStyle(
                          fontFamily: ItqanTypography.uiFont,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    )
                  else
                    const SizedBox(width: 88),
                  const Spacer(),
                  if (_currentPage < _pageCount - 1)
                    FilledButton.icon(
                      onPressed: () => _goToPage(_currentPage + 1),
                      icon: const Icon(Icons.arrow_back_rounded, size: 18),
                      label: const Text('التالي'),
                      style: _primaryButtonStyle().copyWith(
                        minimumSize: const WidgetStatePropertyAll(Size(132, 48)),
                      ),
                    )
                  else
                    const SizedBox(width: 88),
                ],
              ),
            ),
          ],
        ),
      );
}

class _JourneyCard extends StatelessWidget {
  const _JourneyCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.accent,
  });

  final IconData icon;
  final String title;
  final String description;
  final Color accent;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(
          color: ItqanColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: ItqanColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: accent.withOpacity(.10),
                borderRadius: BorderRadius.circular(13),
              ),
              child: Icon(icon, color: accent, size: 21),
            ),
            const SizedBox(height: 9),
            Text(
              title,
              style: const TextStyle(
                fontFamily: ItqanTypography.uiFont,
                fontWeight: FontWeight.w700,
                fontSize: 15,
                color: ItqanColors.ink,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontFamily: ItqanTypography.uiFont,
                color: ItqanColors.inkSoft,
                fontSize: 11.5,
                height: 1.35,
              ),
            ),
          ],
        ),
      );
}
