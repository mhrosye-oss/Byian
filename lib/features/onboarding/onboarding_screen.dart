import 'package:flutter/material.dart';
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F6F0),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        leading: TextButton(
          onPressed: () async {
            // الانتقال لشاشة تسجيل الدخول
            final result = await Navigator.push(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
            // إذا عاد المستخدم بعد تسجيل دخول ناجح، ننتقل للشاشة الرئيسية
            if (result == true && context.mounted) {
              Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const HomeScreen()));
            }
          },
          child: const Text('تسجيل', style: TextStyle(color: Color(0xFF1B5E20), fontWeight: FontWeight.bold, fontSize: 16)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const HomeScreen())),
            child: const Text('تخطي', style: TextStyle(color: Color(0xFF1B5E20), fontWeight: FontWeight.bold, fontSize: 16)),
          ),
        ],
      ),
      body: PageView(
        controller: _controller,
        onPageChanged: (index) => setState(() => _currentPage = index),
        children: [
          _buildPage(
            title: 'إتقان',
            subtitle: 'أتقن تلاوة القرآن الكريم',
            icon: Icons.star_rounded,
          ),
          _buildPage(
            title: 'حدد مستواك',
            subtitle: 'اختر مستواك لنقدم لك تجربة مخصصة',
            icon: Icons.school_rounded,
          ),
          _buildPage(
            title: 'ابدأ رحلتك',
            subtitle: 'استمع، اقرأ، وتدبر آيات الله',
            icon: Icons.menu_book_rounded,
          ),
        ],
      ),
      bottomSheet: Container(
        color: const Color(0xFFF9F6F0),
        padding: const EdgeInsets.all(20),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: List.generate(3, (index) => Container(
                margin: const EdgeInsets.only(right: 8),
                width: _currentPage == index ? 24 : 8,
                height: 8,
                decoration: BoxDecoration(
                  color: _currentPage == index ? const Color(0xFF1B5E20) : Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(4),
                ),
              )),
            ),
            ElevatedButton(
              onPressed: () {
                if (_currentPage == 2) {
                  Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const HomeScreen()));
                } else {
                  _controller.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1B5E20),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              ),
              child: Text(_currentPage == 2 ? 'ابدأ الآن' : 'التالي', style: const TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPage({required String title, required String subtitle, required IconData icon}) {
    return Padding(
      padding: const EdgeInsets.all(40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(30),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFF1B5E20).withOpacity(0.2), width: 2),
            ),
            child: Icon(icon, size: 80, color: const Color(0xFF1B5E20)),
          ),
          const SizedBox(height: 40),
          Text(title, style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: Color(0xFF1B5E20), fontFamily: 'Amiri')),
          const SizedBox(height: 16),
          Text(subtitle, textAlign: TextAlign.center, style: const TextStyle(fontSize: 18, color: Colors.black54)),
        ],
      ),
    );
  }
}
