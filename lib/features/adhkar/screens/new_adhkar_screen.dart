import 'package:flutter/material.dart';
import 'package:itqan/core/theme/colors.dart';

class NewAdhkarScreen extends StatelessWidget {
  const NewAdhkarScreen({super.key});

  static const _categories = <_Category>[
    _Category('أذكار الص��اح', Icons.wb_sunny_outlined, ['أَصْبَحْنَا وَأَصْبَحَ الْمُلْكُ لِلَّهِ', 'سُبْحَانَ اللَّهِ وَبِحَمْدِهِ', 'اللَّهُمَّ بِكَ أَصْبَحْنَا وَبِكَ أَمْسَيْنَا']),
    _Category('أذكار المساء', Icons.nights_stay_outlined, ['أَمْسَيْنَا وَأَمْسَى الْمُلْكُ لِلَّهِ', 'أَعُوذُ بِكَلِمَاتِ اللَّهِ التَّامَّاتِ مِنْ شَرِّ مَا خَلَقَ']),
    _Category('أذكار النوم', Icons.bedtime_outlined, ['بِاسْمِكَ اللَّهُمَّ أَمُوتُ وَأَحْيَا', 'اللَّهُمَّ قِنِي عَذَابَكَ يَوْمَ تَبْعَثُ عِبَادَكَ']),
    _Category('أذكار الصلاة', Icons.mosque_outlined, ['أَسْتَغْفِرُ اللَّهَ', 'اللَّهُمَّ أَنْتَ السَّلَامُ وَمِنْكَ السَّلَامُ']),
    _Category('أذكار الاستيقاظ', Icons.alarm_on_outlined, ['الْحَمْدُ لِلَّهِ الَّذِي أَحْيَانَا بَعْدَ مَا أَمَاتَنَا']),
    _Category('أذكار متنوعة', Icons.spa_outlined, ['سُبْحَانَ اللَّهِ', 'الْحَمْدُ لِلَّهِ', 'اللَّهُ أَكْبَرُ']),
  ];

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: ItqanColors.cream,
        appBar: AppBar(title: const Text('الأذكار')),
        body: GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, crossAxisSpacing: 12, mainAxisSpacing: 12, childAspectRatio: 1.15),
          itemCount: _categories.length,
          itemBuilder: (context, index) {
            final category = _categories[index];
            return Card(
              child: InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: () => Navigator.push(context, MaterialPageRoute<void>(builder: (_) => _DhikrListScreen(category: category))),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Icon(category.icon, size: 34, color: const Color(0xFF1B5E20)),
                    const SizedBox(height: 12),
                    Text(category.title, textAlign: TextAlign.center, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 5),
                    Text('${category.items.length} أذكار', style: const TextStyle(color: ItqanColors.inkSoft, fontSize: 12)),
                  ]),
                ),
              ),
            );
          },
        ),
      );
}

class _Category {
  const _Category(this.title, this.icon, this.items);
  final String title;
  final IconData icon;
  final List<String> items;
}

class _DhikrListScreen extends StatelessWidget {
  const _DhikrListScreen({required this.category});
  final _Category category;

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: ItqanColors.cream,
        appBar: AppBar(title: Text(category.title)),
        body: ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: category.items.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (context, index) => _DhikrCounterCard(text: category.items[index]),
        ),
      );
}

class _DhikrCounterCard extends StatefulWidget {
  const _DhikrCounterCard({required this.text});
  final String text;
  @override
  State<_DhikrCounterCard> createState() => _DhikrCounterCardState();
}

class _DhikrCounterCardState extends State<_DhikrCounterCard> {
  int _count = 0;
  @override
  Widget build(BuildContext context) => Card(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Text(widget.text, textAlign: TextAlign.center, textDirection: TextDirection.rtl,
                style: const TextStyle(fontFamily: 'NotoNaskhArabic', fontSize: 23, height: 1.8)),
            const SizedBox(height: 14),
            FilledButton.icon(
              onPressed: () => setState(() => _count++),
              icon: const Icon(Icons.touch_app_rounded),
              label: Text('$_count'),
            ),
            TextButton(onPressed: () => setState(() => _count = 0), child: const Text('إعادة العداد')),
          ]),
        ),
      );
}
