import 'package:flutter/material.dart';
import 'package:qcf_quran_plus/qcf_quran_plus.dart';
import '../surah_browser/surah_browser_screen.dart';

class QcfQuranScreen extends StatefulWidget {
  const QcfQuranScreen({super.key});

  @override
  State<QcfQuranScreen> createState() => _QcfQuranScreenState();
}

class _QcfQuranScreenState extends State<QcfQuranScreen> {
  final PageController _controller = PageController(initialPage: 0);
  final ValueNotifier<List<HighlightVerse>> _highlights = ValueNotifier([]);

  @override
  void dispose() {
    _controller.dispose();
    _highlights.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('المصحف الشريف'),
        leading: IconButton(
          icon: const Icon(Icons.menu_book),
          onPressed: () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const SurahBrowserScreen()));
          },
        ),
      ),
      body: QuranPageView(
        pageController: _controller,
        highlights: _highlights,
        isDarkMode: Theme.of(context).brightness == Brightness.dark,
        onLongPress: (surah, verse, details) {
          showModalBottomSheet(
            context: context,
            builder: (context) => Container(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('سورة $surah - آية $verse', style: const TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildOption(Icons.play_arrow, 'سماع', () {}),
                      _buildOption(Icons.share, 'مشاركة', () {}),
                      _buildOption(Icons.translate, 'ترجمة', () {}),
                      _buildOption(Icons.bookmark_add, 'حفظ', () {}),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
        // تفعيل العرض المزدوج (صفحتين جنبًا إلى جنب) كما في الصور
        enableTwoPageLayout: true,
      ),
    );
  }

  Widget _buildOption(IconData icon, String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(child: Icon(icon)),
          const SizedBox(height: 8),
          Text(label),
        ],
      ),
    );
  }
}
