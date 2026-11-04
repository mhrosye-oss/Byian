import 'package:flutter/material.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const Color green = Color(0xFF1B5E20);
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('من نحن'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Card(
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
      ),
    );
  }
}
