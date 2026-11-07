import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../auth/screens/login_screen.dart';
import '../auth/screens/register_screen.dart';
import '../home/home_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _controller = PageController();
  int _currentPage = 0;

  Future<void> _finish() async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setBool('onboarding_completed', true);
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const HomeScreen()),
    );
  }

  Future<void> _openLogin() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
    if (result == true && mounted) {
      await _finish();
    }
  }

  Future<void> _openRegister() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const RegisterScreen()),
    );
    if (result == true && mounted) {
      await _finish();
    }
  }

  void _nextPage() {
    if (_currentPage < 2) {
      _controller.nextPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOutCubic,
      );
      return;
    }
    _finish();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isLastPage = _currentPage == 2;

    return Scaffold(
      backgroundColor: const Color(0xFFF9F6F0),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: const Color(0xFF1B5E20).withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.auto_awesome_rounded,
                color: Color(0xFF1B5E20),
                size: 18,
              ),
            ),
            const SizedBox(width: 8),
            const Text(
              'إتقان',
              style: TextStyle(
                color: Color(0xFF1B5E20),
                fontWeight: FontWeight.w800,
                fontSize: 20,
                fontFamily: 'Amiri',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: _finish,
            child: const Text(
              'تخطي',
              style: TextStyle(
                color: Colors.grey,
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView(
                controller: _controller,
                onPageChanged: (index) => setState(() => _currentPage = index),
                children: [
                  _buildIntroPage(),
                  _buildPracticesPage(),
                  _buildWelcomePage(),
                ],
              ),
            ),
            Container(
              color: Colors.transparent,
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 22),
              child: Row(
                children: [
                  Expanded(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(3, (index) {
                        final active = index == _currentPage;
                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 240),
                          curve: Curves.easeInOut,
                          width: active ? 28 : 8,
                          height: 8,
                          margin: const EdgeInsets.symmetric(horizontal: 5),
                          decoration: BoxDecoration(
                            color: active
                                ? const Color(0xFF1B5E20)
                                : Colors.grey.shade300,
                            borderRadius: BorderRadius.circular(99),
                          ),
                        );
                      }),
                    ),
                  ),
                  if (!isLastPage)
                    SizedBox(
                      width: 110,
                      height: 52,
                      child: FilledButton(
                        onPressed: _nextPage,
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF1B5E20),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                        ),
                        child: const Text(
                          'التالي',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIntroPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 20),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minHeight: MediaQuery.of(context).size.height -
              (MediaQuery.of(context).padding.top + 180),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              height: 290,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(34),
                color: Colors.white,
                border: Border.all(
                  color: const Color(0xFF1B5E20).withOpacity(0.12),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF1B5E20).withOpacity(0.08),
                    blurRadius: 18,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  Positioned(
                    top: 18,
                    right: 26,
                    child: _MiniOrnament(
                      color: const Color(0xFF1B5E20).withOpacity(0.18),
                    ),
                  ),
                  Positioned(
                    bottom: 18,
                    left: 28,
                    child: _MiniOrnament(
                      color: const Color(0xFFE0C98C).withOpacity(0.45),
                    ),
                  ),
                  Center(
                    child: CustomPaint(
                      size: const Size(220, 200),
                      painter: _OpenBookPainter(
                        bookColor: const Color(0xFFEAF3EC),
                        lineColor: const Color(0xFF1B5E20),
                        accentColor: const Color(0xFFE0C98C),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            Text(
              'ابدأ رحلتك نحو الأفضل',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF1B5E20),
                fontFamily: 'Amiri',
                height: 1.3,
              ),
            ),
            const SizedBox(height: 14),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                'خطوات صغيرة كل يوم، تصنع أثراً عظيماً في حياتك. اجعل القرآن والذكر والدعاء والخير رفيقاً ليومك.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.black.withOpacity(0.65),
                  height: 1.8,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPracticesPage() {
    final cards = <Map<String, dynamic>>[
      {
        'title': 'القرآن الكريم',
        'subtitle': 'اقرأ وتدبر، واجعل لك ورداً يومياً.',
        'icon': Icons.menu_book_rounded,
      },
      {
        'title': 'الأذكار',
        'subtitle': 'اجعل ذكر الله جزءاً من يومك.',
        'icon': Icons.spa_rounded,
      },
      {
        'title': 'الأدعية',
        'subtitle': 'اقرأ وتعلم واحفظ أدعية الخير.',
        'icon': Icons.favorite_rounded,
      },
      {
        'title': 'مشاركة الخير',
        'subtitle': 'انشر ما ينفع واجعل أثرك ممتداً.',
        'icon': Icons.volunteer_activism_rounded,
      },
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 12),
          Text(
            'كيف تعمل رحلتك؟',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF1B5E20),
              fontFamily: 'Amiri',
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'أربع ممارسات بسيطة تساعدك على بناء يوم مليء بالخير والاستمرار على الطاعات.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: Colors.black.withOpacity(0.65),
              height: 1.8,
            ),
          ),
          const SizedBox(height: 18),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: cards.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 14,
              mainAxisSpacing: 14,
              childAspectRatio: 0.92,
            ),
            itemBuilder: (context, index) {
              final item = cards[index];
              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: const Color(0xFF1B5E20).withOpacity(0.08),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF1B5E20).withOpacity(0.04),
                      blurRadius: 12,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: const Color(0xFF1B5E20).withOpacity(0.12),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(
                        item['icon'] as IconData,
                        color: const Color(0xFF1B5E20),
                        size: 26,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      item['title'] as String,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF1B5E20),
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: Text(
                        item['subtitle'] as String,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.black.withOpacity(0.62),
                          height: 1.6,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFE9EFEA),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: const Color(0xFF1B5E20).withOpacity(0.12),
              ),
            ),
            child: Text(
              'مع كل خطوة، تقترب من نسخة أفضل من نفسك، وتكتسب إنجازات وأوسمة تعبّر عن استمرارك.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                height: 1.8,
                color: Colors.black.withOpacity(0.7),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWelcomePage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 20),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minHeight: MediaQuery.of(context).size.height -
              (MediaQuery.of(context).padding.top + 180),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(
              width: 104,
              height: 104,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 92,
                    height: 92,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFF1B5E20).withOpacity(0.10),
                    ),
                  ),
                  Container(
                    width: 62,
                    height: 62,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                      border: Border.all(
                        color: const Color(0xFF1B5E20).withOpacity(0.2),
                        width: 1.5,
                      ),
                    ),
                    child: const Icon(
                      Icons.auto_awesome_rounded,
                      color: Color(0xFF1B5E20),
                      size: 32,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 26),
            Text(
              'مرحباً بك في إتقان',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 34,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF1B5E20),
                fontFamily: 'Amiri',
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                'ابدأ رحلتك واجعل كل يوم فرصة جديدة للخير والإنجاز.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.black.withOpacity(0.64),
                  height: 1.8,
                ),
              ),
            ),
            const SizedBox(height: 26),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _openLogin,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1B5E20),
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(58),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
                child: const Text(
                  'تسجيل الدخول',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: _openRegister,
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF1B5E20),
                  side: const BorderSide(color: Color(0xFF1B5E20)),
                  minimumSize: const Size.fromHeight(58),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
                child: const Text(
                  'إنشاء حساب جديد',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: _finish,
              child: const Text(
                'المتابعة كضيف',
                style: TextStyle(
                  fontSize: 16,
                  color: Color(0xFF1B5E20),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: null,
                icon: const Icon(Icons.g_mobiledata_rounded, size: 22),
                label: const Text(
                  'Google قريباً',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(54),
                  foregroundColor: Colors.black87,
                  side: const BorderSide(color: Colors.grey),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniOrnament extends StatelessWidget {
  const _MiniOrnament({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(36, 36),
      painter: _OrnamentPainter(color),
    );
  }
}

class _OrnamentPainter extends CustomPainter {
  const _OrnamentPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;

    final rect = Rect.fromCenter(
      center: Offset(size.width / 2, size.height / 2),
      width: size.width - 6,
      height: size.height - 6,
    );

    canvas.drawArc(rect, 0, 3.14, false, paint);
    canvas.drawArc(rect, 3.14, 3.14, false, paint);
    canvas.drawLine(
      Offset(size.width * 0.2, size.height / 2),
      Offset(size.width * 0.8, size.height / 2),
      paint,
    );
    canvas.drawLine(
      Offset(size.width / 2, size.height * 0.2),
      Offset(size.width / 2, size.height * 0.8),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _OpenBookPainter extends CustomPainter {
  const _OpenBookPainter({
    required this.bookColor,
    required this.lineColor,
    required this.accentColor,
  });

  final Color bookColor;
  final Color lineColor;
  final Color accentColor;

  @override
  void paint(Canvas canvas, Size size) {
    final base = Paint()
      ..color = bookColor
      ..style = PaintingStyle.fill;

    final outline = Paint()
      ..color = lineColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.6;

    final accent = Paint()
      ..color = accentColor
      ..style = PaintingStyle.fill;

    final leftBook = RRect.fromRectAndRadius(
      const Rect.fromLTWH(0, 0, 105, 150),
      const Radius.circular(28),
    );
    final rightBook = RRect.fromRectAndRadius(
      const Rect.fromLTWH(115, 0, 105, 150),
      const Radius.circular(28),
    );

    canvas.drawRRect(leftBook, base);
    canvas.drawRRect(rightBook, base);
    canvas.drawRRect(leftBook, outline);
    canvas.drawRRect(rightBook, outline);

    final mid = Path()
      ..moveTo(size.width / 2, 12)
      ..quadraticBezierTo(
        size.width / 2 + 8,
        size.height / 2,
        size.width / 2,
        size.height - 12,
      );
    canvas.drawPath(mid, outline);

    canvas.drawCircle(
      Offset(size.width * 0.5, size.height * 0.5),
      7,
      accent,
    );

    final linePaint = Paint()
      ..color = lineColor.withOpacity(0.45)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    for (int i = 0; i < 5; i++) {
      final y = 34.0 + (i * 18.0);
      canvas.drawLine(
        Offset(32, y),
        Offset(size.width * 0.38, y),
        linePaint,
      );
      canvas.drawLine(
        Offset(size.width * 0.62, y),
        Offset(size.width - 32, y),
        linePaint,
      );
    }

    canvas.drawPath(
      Path()
        ..moveTo(52, 24)
        ..lineTo(size.width * 0.38, 24)
        ..moveTo(size.width * 0.62, 24)
        ..lineTo(size.width - 52, 24),
      linePaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
