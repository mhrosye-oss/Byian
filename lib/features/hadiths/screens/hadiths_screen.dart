import 'package:flutter/material.dart';

class HadithItem {
  final String reference;
  final String arabicText;
  final String englishMeaning;

  const HadithItem({
    required this.reference,
    required this.arabicText,
    required this.englishMeaning,
  });
}

class HadithsScreen extends StatelessWidget {
  const HadithsScreen({super.key});

  static const List<HadithItem> _hadiths = [
    HadithItem(
      reference: 'صحيح البخاري',
      arabicText:
          'إِنَّمَا الأَعْمَالُ بِالنِّيَّاتِ، وَإِنَّمَا لِكُلِّ امْرِئٍ مَا نَوَى',
      englishMeaning: 'الأعمال بالنيات، ولكل امرئ ما نوى.',
    ),
    HadithItem(
      reference: 'صحيح مسلم',
      arabicText:
          'مَنْ جَلَسَ فِي مَجْلِسٍ وَقَالَ لا حَوْلَ وَلا قُوَّةَ إِلا بِاللَّهِ، غُفِرَتْ خَطَايَاهُ وَإِنْ كَانَتْ مِثْلَ زَبَدِ الْبَحْرِ',
      englishMeaning: 'من قال لا حول ولا قوة إلا بالله غفرت ذنوبه.',
    ),
    HadithItem(
      reference: 'سنن أبي داود',
      arabicText:
          'مَنْ كَانَ يُؤْمِنُ بِاللَّهِ وَالْيَوْمِ الآخِرِ فَلْيَقُلْ خَيْرًا أَوْ لِيَصْمُتْ',
      englishMeaning: 'من آمن بالله واليوم الآخر فليقل خيرًا أو ليصمت.',
    ),
    HadithItem(
      reference: 'صحيح البخاري',
      arabicText:
          'لا يُؤْمِنُ أَحَدُكُمْ حَتَّى يُحِبَّ لأَخِيهِ مَا يُحِبُّ لِنَفْسِهِ',
      englishMeaning: 'لا يَؤمن أحدكم حتى يحب لأخيه ما يحب لنفسه.',
    ),
    HadithItem(
      reference: 'سنن الترمذي',
      arabicText:
          'مَا نَهَيْتُكُمْ عَنْهُ فَاجْتَنِبُوهُ، وَمَا أَمَرْتُكُمْ بِهِ فَافْعَلُوا مِنْهُ مَا اسْتَطَعْتُمْ',
      englishMeaning: 'ما نهيتكم عنه فاجتنبوه، وما أمرتكم به فافعلوا منه ما استطعتم.',
    ),
    HadithItem(
      reference: 'صحيح مسلم',
      arabicText:
          'إِنَّ اللَّهَ يَرْفَعُ بِهَذَا الْكِتَابِ أَقْوَامًا وَيَضَعُ بِهِ آخَرِينَ',
      englishMeaning: 'إن الله يرفع بهذا الكتاب قومًا ويضع آخرين.',
    ),
    HadithItem(
      reference: 'سنن ابن ماجه',
      arabicText:
          'الْبِرُّ حُسْنُ الْخُلُقِ، وَالإِثْمُ مَا حَاكَ فِي صَدْرِكَ وَكَرِهْتَ أَنْ يَعْلَمَ النَّاسُ',
      englishMeaning: 'البر حسن الخلق، والإثم ما حاك في صدرك وكرهت أن يعلم الناس.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text(
          'الأحاديث',
          style: TextStyle(
            color: Color(0xFF1A1A1A),
            fontWeight: FontWeight.w700,
            fontSize: 22,
          ),
          textDirection: TextDirection.rtl,
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF1A1A1A)),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: _hadiths.length,
        itemBuilder: (context, index) {
          final item = _hadiths[index];
          return Container(
            margin: const EdgeInsets.only(bottom: 14),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x1A000000),
                  blurRadius: 8,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.reference,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFFD32F2F),
                    fontWeight: FontWeight.w700,
                  ),
                  textDirection: TextDirection.rtl,
                ),
                const SizedBox(height: 10),
                Text(
                  item.arabicText,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1A1A1A),
                    height: 1.8,
                  ),
                  textDirection: TextDirection.rtl,
                ),
                const SizedBox(height: 10),
                Text(
                  item.englishMeaning,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF1A1A1A).withOpacity(0.75),
                  ),
                  textDirection: TextDirection.rtl,
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
