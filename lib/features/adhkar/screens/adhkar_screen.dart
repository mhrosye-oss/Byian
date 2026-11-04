import 'package:flutter/material.dart';

class DhikrItem {
  final String title;
  final String arabicText;
  final int count;

  const DhikrItem({
    required this.title,
    required this.arabicText,
    required this.count,
  });
}

class AdhkarScreen extends StatefulWidget {
  const AdhkarScreen({super.key});

  @override
  State<AdhkarScreen> createState() => _AdhkarScreenState();
}

class _AdhkarScreenState extends State<AdhkarScreen> {
  final List<Map<String, dynamic>> _sections = [
    {
      'title': 'أذكار الصباح',
      'items': [
        DhikrItem(
          title: 'أذكار الصباح',
          arabicText: 'اللَّهُ أَكْبَرُ',
          count: 1,
        ),
        DhikrItem(
          title: 'أذكار الصباح',
          arabicText: 'سُبْحَانَ اللَّهِ',
          count: 3,
        ),
        DhikrItem(
          title: 'أذكار الصباح',
          arabicText: 'أَسْتَغْفِرُ اللَّهَ',
          count: 3,
        ),
      ],
    },
    {
      'title': 'أذكار المساء',
      'items': [
        DhikrItem(
          title: 'أذكار المساء',
          arabicText: 'اللَّهُ أَكْبَرُ',
          count: 1,
        ),
        DhikrItem(
          title: 'أذكار المساء',
          arabicText: 'أَعُوذُ بِاللَّهِ مِنَ الشَّيْطَانِ الرَّجِيمِ',
          count: 1,
        ),
        DhikrItem(
          title: 'أذكار المساء',
          arabicText: 'حَسْبُنَا اللَّهُ وَنِعْمَ الْوَكِيلُ',
          count: 1,
        ),
      ],
    },
    {
      'title': 'أذكار النوم',
      'items': [
        DhikrItem(
          title: 'أذكار النوم',
          arabicText: 'بِسْمِ اللَّهِ الرَّحْمَنِ الرَّحِيمِ',
          count: 1,
        ),
        DhikrItem(
          title: 'أذكار النوم',
          arabicText: 'أَعُوذُ بِاللَّهِ مِنَ الشَّيْطَانِ الرَّجِيمِ',
          count: 1,
        ),
        DhikrItem(
          title: 'أذكار النوم',
          arabicText: 'اللَّهُمَّ قِنِي عَذَابَكَ يَوْمَ تَبْعَثُ عِبَادَكَ',
          count: 1,
        ),
      ],
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text(
          'الأذكار',
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
        itemCount: _sections.length,
        itemBuilder: (context, index) {
          final section = _sections[index];
          final items = section['items'] as List<DhikrItem>;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 10),
              Text(
                section['title'] as String,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1A1A1A),
                ),
                textDirection: TextDirection.rtl,
              ),
              const SizedBox(height: 12),
              ...items.map((item) => _DhikrCard(item: item)),
            ],
          );
        },
      ),
    );
  }
}

class _DhikrCard extends StatefulWidget {
  final DhikrItem item;

  const _DhikrCard({required this.item});

  @override
  State<_DhikrCard> createState() => _DhikrCardState();
}

class _DhikrCardState extends State<_DhikrCard> {
  int _count = 0;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
            widget.item.arabicText,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1A1A1A),
              height: 1.8,
            ),
            textDirection: TextDirection.rtl,
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'التكرار: ${widget.item.count}',
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF1A1A1A),
                ),
                textDirection: TextDirection.rtl,
              ),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _count++;
                  });
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFD32F2F),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  '$_count',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
