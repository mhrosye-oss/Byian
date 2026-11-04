import 'package:flutter/material.dart';

const _green = Color(0xFF1B5E20);
const _cream = Color(0xFFF9F6F0);
const _surface = Color(0xFFFFFEFC);
const _muted = Color(0xFF687268);
const _border = Color(0xFFE7E0D5);

class NewAdhkarScreen extends StatelessWidget {
  const NewAdhkarScreen({super.key});

  static const _categories = <_AdhkarCategory>[
    _AdhkarCategory(
      title: 'أذكار الصباح',
      subtitle: 'ابدأ يومك بذكر الله',
      icon: Icons.wb_sunny_outlined,
      adhkar: [
        _Dhikr(text: 'أَصْبَحْنَا وَأَصْبَحَ الْمُلْكُ لِلَّهِ، وَالْحَمْدُ لِلَّهِ', repetitions: 1),
        _Dhikr(text: 'سُبْحَانَ اللَّهِ وَبِحَمْدِهِ', repetitions: 100),
        _Dhikr(text: 'أَسْتَغْفِرُ اللَّهَ وَأَتُوبُ إِلَيْهِ', repetitions: 3),
      ],
    ),
    _AdhkarCategory(
      title: 'أذكار المساء',
      subtitle: 'اختم يومك بالسكينة',
      icon: Icons.nights_stay_outlined,
      adhkar: [
        _Dhikr(text: 'أَمْسَيْنَا وَأَمْسَى الْمُلْكُ لِلَّهِ، وَالْحَمْدُ لِلَّهِ', repetitions: 1),
        _Dhikr(text: 'أَعُوذُ بِكَلِمَاتِ اللَّهِ التَّامَّاتِ مِنْ شَرِّ مَا خَلَقَ', repetitions: 3),
        _Dhikr(text: 'سُبْحَانَ اللَّهِ وَبِحَمْدِهِ', repetitions: 100),
      ],
    ),
    _AdhkarCategory(
      title: 'أذكار النوم',
      subtitle: 'اذكر الله قبل أن تنام',
      icon: Icons.bedtime_outlined,
      adhkar: [
        _Dhikr(text: 'بِاسْمِكَ اللَّهُمَّ أَمُوتُ وَأَحْيَا', repetitions: 1),
        _Dhikr(text: 'سُبْحَانَ اللَّهِ', repetitions: 33),
        _Dhikr(text: 'الْحَمْدُ لِلَّهِ', repetitions: 33),
        _Dhikr(text: 'اللَّهُ أَكْبَرُ', repetitions: 34),
      ],
    ),
  ];

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: _cream,
        appBar: AppBar(
          title: const Text('الأذكار', textDirection: TextDirection.rtl),
          backgroundColor: _cream,
          foregroundColor: _green,
          elevation: 0,
          centerTitle: true,
        ),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(18, 8, 18, 28),
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: _green,
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Row(
                textDirection: TextDirection.rtl,
                children: [
                  Icon(Icons.spa_outlined, color: Colors.white, size: 32),
                  SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'طمئن قلبك بذكر الله',
                          textDirection: TextDirection.rtl,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        SizedBox(height: 5),
                        Text(
                          'أذكار مختارة ليومك وليلتك',
                          textDirection: TextDirection.rtl,
                          style: TextStyle(color: Colors.white70, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),
            for (final category in _categories) ...[
              _CategoryHeading(category: category),
              const SizedBox(height: 10),
              for (final dhikr in category.adhkar)
                _DhikrCard(dhikr: dhikr),
              const SizedBox(height: 14),
            ],
          ],
        ),
      );
}

class _AdhkarCategory {
  const _AdhkarCategory({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.adhkar,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final List<_Dhikr> adhkar;
}

class _Dhikr {
  const _Dhikr({required this.text, required this.repetitions});

  final String text;
  final int repetitions;
}

class _CategoryHeading extends StatelessWidget {
  const _CategoryHeading({required this.category});

  final _AdhkarCategory category;

  @override
  Widget build(BuildContext context) => Row(
        textDirection: TextDirection.rtl,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: _green.withValues(alpha: 0.09),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Icon(category.icon, color: _green),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  category.title,
                  textDirection: TextDirection.rtl,
                  style: const TextStyle(
                    color: _green,
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  category.subtitle,
                  textDirection: TextDirection.rtl,
                  style: const TextStyle(color: _muted, fontSize: 12),
                ),
              ],
            ),
          ),
          Text(
            '${category.adhkar.length} أذكار',
            textDirection: TextDirection.rtl,
            style: const TextStyle(color: _muted, fontSize: 12),
          ),
        ],
      );
}

class _DhikrCard extends StatefulWidget {
  const _DhikrCard({required this.dhikr});

  final _Dhikr dhikr;

  @override
  State<_DhikrCard> createState() => _DhikrCardState();
}

class _DhikrCardState extends State<_DhikrCard> {
  int _count = 0;

  @override
  Widget build(BuildContext context) {
    final isComplete = _count >= widget.dhikr.repetitions;
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      color: _surface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: _border),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 16, 18, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              widget.dhikr.text,
              textAlign: TextAlign.center,
              textDirection: TextDirection.rtl,
              style: const TextStyle(
                color: Color(0xFF263329),
                fontFamily: 'NotoNaskhArabic',
                fontSize: 21,
                height: 1.8,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              textDirection: TextDirection.rtl,
              children: [
                Expanded(
                  child: Text(
                    'التكرار: ${widget.dhikr.repetitions}',
                    textDirection: TextDirection.rtl,
                    style: const TextStyle(color: _muted, fontSize: 12),
                  ),
                ),
                FilledButton.icon(
                  onPressed: isComplete
                      ? null
                      : () => setState(() => _count++),
                  style: FilledButton.styleFrom(
                    backgroundColor: _green,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: _green.withValues(alpha: 0.12),
                    disabledForegroundColor: _green,
                  ),
                  icon: Icon(isComplete ? Icons.check_rounded : Icons.touch_app_rounded),
                  label: Text('$_count / ${widget.dhikr.repetitions}'),
                ),
                IconButton(
                  tooltip: 'إعادة العداد',
                  onPressed: _count == 0 ? null : () => setState(() => _count = 0),
                  color: _muted,
                  icon: const Icon(Icons.refresh_rounded),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
