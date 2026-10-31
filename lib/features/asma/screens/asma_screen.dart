import 'package:flutter/material.dart';

class AsmaItem {
  final String arabicName;
  final String meaning;

  const AsmaItem({
    required this.arabicName,
    required this.meaning,
  });
}

class AsmaScreen extends StatelessWidget {
  const AsmaScreen({super.key});

  static const List<AsmaItem> _names = [
    AsmaItem(
      arabicName: 'اللَّهُ',
      meaning: 'الله',
    ),
    AsmaItem(
      arabicName: 'الرَّحْمَن',
      meaning: 'الرحمن',
    ),
    AsmaItem(
      arabicName: 'الرَّحِيم',
      meaning: 'الرحيم',
    ),
    AsmaItem(
      arabicName: 'الْمَلِك',
      meaning: 'الملك',
    ),
    AsmaItem(
      arabicName: 'الْقُدُّوس',
      meaning: 'القدوس',
    ),
    AsmaItem(
      arabicName: 'السَّلَام',
      meaning: 'السلام',
    ),
    AsmaItem(
      arabicName: 'الْمُؤْمِن',
      meaning: 'المؤمن',
    ),
    AsmaItem(
      arabicName: 'الْمُهَيْمِن',
      meaning: 'المهيمن',
    ),
    AsmaItem(
      arabicName: 'الْعَزِيز',
      meaning: 'العزيز',
    ),
    AsmaItem(
      arabicName: 'الْجَبَّار',
      meaning: 'الجبار',
    ),
    AsmaItem(
      arabicName: 'الْمُتَكَبِّر',
      meaning: 'المتكبر',
    ),
    AsmaItem(
      arabicName: 'الْخَالِق',
      meaning: 'الخالق',
    ),
    AsmaItem(
      arabicName: 'الْبَارِئ',
      meaning: 'البارئ',
    ),
    AsmaItem(
      arabicName: 'الْمُصَوِّر',
      meaning: 'المصور',
    ),
    AsmaItem(
      arabicName: 'الْغَفَّار',
      meaning: 'الغفار',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text(
          'أسماء الله الحسنى',
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
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: GridView.builder(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 0.8,
          ),
          itemCount: _names.length,
          itemBuilder: (context, index) {
            final name = _names[index];
            return Container(
              padding: const EdgeInsets.all(10),
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
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    name.arabicName,
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFFD32F2F),
                      height: 1.6,
                    ),
                    textDirection: TextDirection.rtl,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    name.meaning,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF1A1A1A),
                    ),
                    textDirection: TextDirection.rtl,
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
