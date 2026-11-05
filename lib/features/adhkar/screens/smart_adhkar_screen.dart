import 'package:flutter/material.dart';
import 'adhkar_detail_screen.dart';

class SmartAdhkarScreen extends StatelessWidget {
  const SmartAdhkarScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // قائمة الحالات السياقية
    final List<Map<String, dynamic>> contexts = [
      {'id': 'travel', 'title': 'مسافر', 'desc': 'أدعية وأذكار السفر', 'icon': Icons.flight_takeoff_rounded, 'color': Colors.blue},
      {'id': 'sickness', 'title': 'مريض', 'desc': 'أدعية الشفاء والمرض', 'icon': Icons.healing_rounded, 'color': Colors.red},
      {'id': 'rain', 'title': 'ممطر', 'desc': 'أذكار المطر والرعد', 'icon': Icons.water_drop_rounded, 'color': Colors.lightBlue},
      {'id': 'mosque', 'title': 'في المسجد', 'desc': 'أدعية دخول وخروج المسجد', 'icon': Icons.mosque_rounded, 'color': Colors.green},
      {'id': 'home', 'title': 'في المنزل', 'desc': 'أذكار الدخول والخروج', 'icon': Icons.home_rounded, 'color': Colors.orange},
      {'id': 'sadness', 'title': 'حزين أو مهموم', 'desc': 'أدعية تفريج الهم والحزن', 'icon': Icons.cloud_rounded, 'color': Colors.grey},
    ];

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('أذكار تناسب حالتك', style: TextStyle(color: Colors.white)),
        centerTitle: true,
        backgroundColor: const Color(0xFF1B5E20),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          // ترويسة توضيحية
          Container(
            width: double.infinity,
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF1B5E20).withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Text(
              'اختر حالتك أو مكانك الحالي، وسنعرض لك الأذكار والأدعية المناسبة لك الآن.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 15, color: Color(0xFF1B5E20), fontWeight: FontWeight.bold),
              textDirection: TextDirection.rtl,
            ),
          ),
          
          // شبكة الحالات
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 0.95,
              ),
              itemCount: contexts.length,
              itemBuilder: (context, index) {
                final ctx = contexts[index];
                return InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => AdhkarDetailScreen(
                          categoryId: ctx['id'],
                          categoryTitle: ctx['title'],
                        ),
                      ),
                    );
                  },
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    decoration: BoxDecoration(
                      color: theme.cardColor,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: (ctx['color'] as Color).withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(ctx['icon'], size: 36, color: ctx['color']),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          ctx['title'],
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: theme.textTheme.bodyLarge?.color),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          ctx['desc'],
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 12, color: theme.textTheme.bodySmall?.color),
                        ),
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
}
