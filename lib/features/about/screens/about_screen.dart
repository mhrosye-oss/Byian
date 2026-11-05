import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  Future<void> _launchURL(String url) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      throw Exception('Could not launch $url');
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color green = Color(0xFF1B5E20);
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('من نحن', style: TextStyle(color: Colors.white)),
        centerTitle: true,
        backgroundColor: green,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // بطاقة الوقف والمعلومات
            Card(
              color: theme.cardColor,
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'عن التطبيق:',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: green),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'هذا التطبيق أُسس ليكون صدقة جارية، وعملاً خالصاً لوجه الله تعالى، يخدم كتاب الله وسنة نبيه ﷺ.',
                      style: TextStyle(fontSize: 16, height: 1.6, color: theme.textTheme.bodyLarge?.color),
                      textDirection: TextDirection.rtl,
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'الرعاية والدعم السخي:',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: green),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'ببادرة كريمة ورعاية سخية، تفضل رجل الأعمال الأستاذ / صلاح صالح القنان (حفظه الله) بدعم وإشراف على هذا العمل وإطلاقه، ليكون عوناً في خدمة كتاب الله ونشر العلم. جزاه الله خيراً وجعل ذلك في موازين حسناته.',
                      style: TextStyle(fontSize: 16, height: 1.6, color: theme.textTheme.bodyLarge?.color),
                      textDirection: TextDirection.rtl,
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'البرمجة والتطوير:',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: green),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'تم تطوير وبناء التطبيق بجهود المهندس / محروس لطف الآنسي.',
                      style: TextStyle(fontSize: 16, height: 1.6, color: theme.textTheme.bodyLarge?.color),
                      textDirection: TextDirection.rtl,
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'رسالة الوقف والدعاء:',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: green),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'وقد جُعل هذا التطبيق وقفاً خالصاً لوجه الله تعالى من كلا الفريقين، لولديهما ولذريتهم من قبل ومن بعد.\nسائلين المولى عز وجل أن ينفع به، وأن يتقبله بقبولٍ حسن، وأن يجعله في موازين حسناتهم يوم القيامة، وصدقة جارية لوالديهم وذريتهم.',
                      style: TextStyle(fontSize: 16, height: 1.6, color: theme.textTheme.bodyLarge?.color),
                      textDirection: TextDirection.rtl,
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // قسم التواصل
            const Text(
              'للتواصل مع المطور:',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: green),
            ),
            const SizedBox(height: 16),
            
            // أزرار التواصل
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildContactButton(
                  icon: Icons.phone,
                  label: 'اتصال',
                  color: Colors.blue,
                  onTap: () => _launchURL('tel:777255617'),
                ),
                _buildContactButton(
                  icon: Icons.chat,
                  label: 'واتساب',
                  color: const Color(0xFF25D366),
                  onTap: () => _launchURL('https://wa.me/777255617'),
                ),
                _buildContactButton(
                  icon: Icons.email,
                  label: 'بريد',
                  color: Colors.red,
                  onTap: () => _launchURL('mailto:m.lutf.m@gmail.com'),
                ),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildContactButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.5)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}
