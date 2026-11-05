import 'package:flutter/material.dart';
import '../quran/models/ayah.dart';
import '../quran/services/quran_service.dart';

class MushafSwipeReader extends StatefulWidget {
  const MushafSwipeReader({super.key});

  @override
  State<MushafSwipeReader> createState() => _MushafSwipeReaderState();
}

class _MushafSwipeReaderState extends State<MushafSwipeReader> {
  final PageController _pageController = PageController();
  bool _isLoading = true;
  
  // لتجربة تقليب الصفحات، سنقوم بإنشاء صفحتين (الأولى للفاتحة، والثانية تجريبية)
  List<List<Ayah>> _pages = [];
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _loadPages();
  }

  Future<void> _loadPages() async {
    try {
      final quranService = QuranService();
      final fatiha = await quranService.getAyahs(1); // الفاتحة
      
      // الصفحة الأولى: الفاتحة كاملة
      List<Ayah> page1 = fatiha;
      
      // الصفحة الثانية (تجريبية): نصوص من سورة أخرى لتجربة التقليب
      // في التطبيق الحقيقي، سيتم جلب 604 صفحة وتقسيمها
      List<Ayah> page2 = [
        Ayah(surahNumber: 112, ayahNumber: 1, textUthmani: 'قُلْ هُوَ ٱللَّهُ أَحَدٌ', words: const [], translation: 'Say, "He is Allah, [who is] One,'),
        Ayah(surahNumber: 112, ayahNumber: 2, textUthmani: 'ٱللَّهُ ٱلصَّمَدُ', words: const [], translation: 'Allah, the Eternal Refuge.'),
        Ayah(surahNumber: 112, ayahNumber: 3, textUthmani: 'لَمْ يَلِدْ وَلَمْ يُولَدْ', words: const [], translation: 'He neither begets nor is born,'),
        Ayah(surahNumber: 112, ayahNumber: 4, textUthmani: 'وَلَمْ يَكُن لَّهُۥ كُفُوًا أَحَدٌ', words: const [], translation: 'Nor is there to Him any equivalent.'),
      ];

      if (mounted) {
        setState(() {
          _pages = [page1, page2];
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  // بناء صفحة واحدة من المصحف
  Widget _buildMushafPage(List<Ayah> ayahs, int pageIndex) {
    // نستخدم لون البيج الفاتح لورق المصحف
    const Color paperColor = Color(0xFFFDFBF7);
    const Color textColor = Color(0xFF1A1A1A);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      decoration: BoxDecoration(
        color: paperColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFD4AF37), width: 3), // إطار ذهبي
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 5)),
        ],
      ),
      child: Column(
        children: [
          // رأس الصفحة (زخرفة علوية)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: Color(0xFFD4AF37), width: 1)),
            ),
            child: Text(
              'سُورَةُ ${pageIndex == 0 ? "الفَاتِحَة" : "الإِخْلَاص"}',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'Amiri',
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1B5E20),
              ),
            ),
          ),
          
          // النص القرآني
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Text.rich(
                TextSpan(
                  children: ayahs.map((ayah) {
                    return TextSpan(
                      children: [
                        TextSpan(
                          text: '${ayah.textUthmani} ',
                          style: const TextStyle(
                            fontFamily: 'Amiri',
                            fontSize: 26,
                            height: 2.0,
                            color: textColor,
                          ),
                        ),
                        TextSpan(
                          text: '﴿${ayah.ayahNumber}﴾ ',
                          style: const TextStyle(
                            fontFamily: 'Amiri',
                            fontSize: 20,
                            color: Color(0xFF1B5E20), // رقم الآية باللون الأخضر
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ),
                textAlign: TextAlign.center,
                textDirection: TextDirection.rtl,
              ),
            ),
          ),

          // رقم الصفحة (تذييل)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: Color(0xFFD4AF37), width: 1)),
            ),
            child: Text(
              '${pageIndex + 1}',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1B5E20)),
            ),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // خلفية داكنة خلف الكتاب لإبراز الصفحة
    const Color outerBgColor = Color(0xFF1B5E20); 

    return Scaffold(
      backgroundColor: outerBgColor,
      appBar: AppBar(
        backgroundColor: const Color(0xFF154A19), // أخضر داكن
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'مصحفي - وضع الكتاب',
          style: TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.menu_book_rounded, color: Colors.white),
            onPressed: () {
              // خيار العودة للصفحة الأولى
              _pageController.animateToPage(0, duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
            },
          )
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.white))
          : PageView.builder(
              controller: _pageController,
              onPageChanged: (index) {
                setState(() {
                  _currentPage = index;
                });
              },
              itemCount: _pages.length,
              itemBuilder: (context, index) {
                return _buildMushafPage(_pages[index], index);
              },
            ),
      bottomNavigationBar: Container(
        height: 70,
        decoration: const BoxDecoration(color: Color(0xFF154A19)),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
              onPressed: _currentPage > 0 ? () => _pageController.previousPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut) : null,
            ),
            const Text(
              'اسحب لليسار أو اليمين لتقليب الصفحات',
              style: TextStyle(color: Colors.white70, fontSize: 12),
            ),
            IconButton(
              icon: const Icon(Icons.arrow_forward_ios, color: Colors.white),
              onPressed: _currentPage < _pages.length - 1 ? () => _pageController.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut) : null,
            ),
          ],
        ),
      ),
    );
  }
}
