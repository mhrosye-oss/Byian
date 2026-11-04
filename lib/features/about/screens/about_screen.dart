import 'package:flutter/material.dart';
import 'package:itqan/core/theme/colors.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: ItqanColors.cream,
        appBar: AppBar(title: const Text('من نحن')),
        body: ListView(padding: const EdgeInsets.all(20), children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(children: [
                const CircleAvatar(radius: 38, backgroundColor: Color(0xFF1B5E20),
                    child: Icon(Icons.menu_book_rounded, color: Colors.white, size: 38)),
                const SizedBox(height: 16),
                const Text('إتقان', style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold, color: Color(0xFF1B5E20))),
                const SizedBox(height: 8),
                Text('تطبيق ي��اعدك على الارتباط بالقرآن الكريم والعبادات اليومية.', textAlign: TextAlign.center,
                    style: TextStyle(color: ItqanColors.inkSoft, height: 1.6)),
              ]),
            ),
          ),
          const SizedBox(height: 12),
          const Card(child: ListTile(leading: Icon(Icons.code_rounded, color: Color(0xFF1B5E20)), title: Text('المطوّر'), subtitle: Text('فريق إتقان'))),
          const Card(child: ListTile(leading: Icon(Icons.email_outlined, color: Color(0xFF1B5E20)), title: Text('للتواصل'), subtitle: Text('user@example.com'))),
          const SizedBox(height: 12),
          Card(
            color: const Color(0xFF1B5E20),
            child: Padding(
              padding: const EdgeInsets.all(22),
              child: Column(children: [
                const Icon(Icons.volunteer_activism_rounded, color: Colors.white, size: 32),
                const SizedBox(height: 12),
                const Text('رسالة الوقف', style: TextStyle(color: Colors.white, fontSize: 19, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text('نسعى أن يكون هذا العمل نافعًا مستمرًا، ونسأل الله أن يجعله صدقةً جاريةً وأثرًا طيبًا لكل من ساهم فيه.',
                    textAlign: TextAlign.center, textDirection: TextDirection.rtl,
                    style: TextStyle(color: Colors.white.withValues(alpha: .9), height: 1.8)),
              ]),
            ),
          ),
        ]),
      );
}
