import 'package:flutter/material.dart';

class MoodQuranScreen extends StatelessWidget {
  const MoodQuranScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // قائمة الحالات المزاجية مع الآيات المناسبة لكل حالة
    final List<Map<String, dynamic>> moods = [
      {
        'title': 'حزين أو مهموم',
        'desc': 'آيات السكينة والطمأنينة',
        'icon': Icons.sentiment_dissatisfied_rounded,
        'color': Colors.blueGrey,
        'ayahs': [
          {'text': 'أَلَا بِذِكْرِ اللَّهِ تَطْمَئِنُّ الْقُلُوبُ', 'ref': 'الرعد: 28'},
          {'text': 'وَلَسَوْفَ يُعْطِيكَ رَبُّكَ فَتَرْضَىٰ', 'ref': 'الضحى: 5'},
          {'text': 'فَإِنَّ مَعَ الْعُسْرِ يُسْرًا', 'ref': 'الشرح: 5'}
        ]
      },
      {
        'title': 'قلق أو خائف',
        'desc': 'آيات الحفظ والأمان',
        'icon': Icons.psychology_alt_rounded,
        'color': Colors.orange,
        'ayahs': [
          {'text': 'أَلَا إِنَّ أَوْلِيَاءَ اللَّهِ لَا خَوْفٌ عَلَيْهِمْ وَلَا هُمْ يَحْزَنُونَ', 'ref': 'يونس: 62'},
          {'text': 'وَمَن يَتَوَكَّلْ عَلَى اللَّهِ فَهُوَ حَسْبُهُ', 'ref': 'الطلاق: 3'}
        ]
      },
      {
        'title': 'مريض',
        'desc': 'آيات الشفاء',
        'icon': Icons.local_hospital_rounded,
        'color': Colors.red,
        'ayahs': [
          {'text': 'وَإِذَا مَرِضْتُ فَهُوَ يَشْفِينِ', 'ref': 'الشعراء: 80'},
          {'text': 'وَنُنَزِّلُ مِنَ الْقُرْآنِ مَا هُوَ شِفَاءٌ وَرَحْمَةٌ لِّلْمُؤْمِنِينَ', 'ref': 'الإسراء: 82'}
        ]
      },
      {
        'title': 'ممتن وشاكر',
        'desc': 'آيات الشكر والحمد',
        'icon': Icons.volunteer_activism_rounded,
        'color': Colors.green,
        'ayahs': [
          {'text': 'وَإِذْ تَأَذَّنَ رَبُّكُمْ لَئِن شَكَرْتُمْ لَأَزِيدَنَّكُمْ', 'ref': 'إبراهيم: 7'},
          {'text': 'فَاذْكُرُونِي أَذْكُرْكُمْ وَاشْكُرُوا لِي وَلَا تَكْفُرُونِ', 'ref': 'البقرة: 152'}
        ]
      }
    ];

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('القرآن حسب حالتك', style: TextStyle(color: Colors.white)),
        centerTitle: true,
        backgroundColor: const Color(0xFF1B5E20),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView.builder(
          itemCount: moods.length,
          itemBuilder: (context, index) {
            final mood = moods[index];
            return Card(
              color: theme.cardColor,
              margin: const EdgeInsets.only(bottom: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 2,
              child: ExpansionTile(
                leading: CircleAvatar(
                  backgroundColor: (mood['color'] as Color).withOpacity(0.1),
                  child: Icon(mood['icon'], color: mood['color']),
                ),
                title: Text(mood['title'], style: TextStyle(fontWeight: FontWeight.bold, color: theme.textTheme.bodyLarge?.color)),
                subtitle: Text(mood['desc'], style: TextStyle(color: theme.textTheme.bodySmall?.color)),
                children: (mood['ayahs'] as List).map((ayah) {
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: theme.scaffoldBackgroundColor,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: theme.dividerColor),
                    ),
                    child: Column(
                      children: [
                        Text(
                          ayah['text'],
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 20, fontFamily: 'Amiri', color: theme.textTheme.bodyLarge?.color, height: 1.8),
                          textDirection: TextDirection.rtl,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          ayah['ref'],
                          style: TextStyle(fontSize: 12, color: theme.textTheme.bodySmall?.color),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            );
          },
        ),
      ),
    );
  }
}
