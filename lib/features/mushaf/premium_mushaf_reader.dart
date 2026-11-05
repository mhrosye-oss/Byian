import 'package:flutter/material.dart';
import '../quran/models/ayah.dart';
import '../quran/services/quran_service.dart';

class PremiumMushafReader extends StatefulWidget {
  const PremiumMushafReader({super.key});

  @override
  State<PremiumMushafReader> createState() => _PremiumMushafReaderState();
}

class _PremiumMushafReaderState extends State<PremiumMushafReader> {
  bool _showTranslation = true;
  bool _isLoading = true;
  List<Ayah> _ayahs = [];

  @override
  void initState() {
    super.initState();
    _loadSurah();
  }

  Future<void> _loadSurah() async {
    try {
      final quranService = QuranService();
      final data = await quranService.getAyahs(1); // جلب سورة الفاتحة
      setState(() {
        _ayahs = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  void _showAyahMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(30),
          boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10)],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildMenuIcon(context, Icons.play_arrow_rounded, Colors.white, const Color(0xFF1B5E20)),
            _buildMenuIcon(context, Icons.star_rounded, const Color(0xFFFBC02D), Colors.white),
            _buildMenuIcon(context, Icons.ios_share_rounded, Colors.white, const Color(0xFF1B5E20)),
            _buildMenuIcon(context, Icons.keyboard_arrow_up_rounded, Theme.of(context).iconTheme.color ?? Colors.black, Theme.of(context).cardColor),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuIcon(BuildContext context, IconData icon, Color iconColor, Color bgColor) {
    return CircleAvatar(radius: 24, backgroundColor: bgColor, child: Icon(icon, color: iconColor, size: 28));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textColor = theme.textTheme.bodyLarge?.color ?? Colors.black;
    final subTextColor = theme.textTheme.bodySmall?.color ?? Colors.grey;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: const Color(0xFF1B5E20),
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'سُورَةُ الفَاتِحَة',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, fontFamily: 'Amiri', color: Colors.white),
        ),
        actions: [
          IconButton(
            icon: Icon(_showTranslation ? Icons.translate : Icons.translate_outlined, color: Colors.white),
            onPressed: () => setState(() => _showTranslation = !_showTranslation),
          ),
        ],
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF1B5E20)))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _ayahs.length,
              itemBuilder: (context, index) {
                final ayah = _ayahs[index];
                return GestureDetector(
                  onLongPress: () => _showAyahMenu(context),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: theme.cardColor,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: theme.dividerColor),
                    ),
                    child: _showTranslation
                        ? Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // الترجمة الإنجليزية (يسار)
                              Expanded(
                                flex: 4,
                                child: Text(
                                  ayah.translation ?? '',
                                  textAlign: TextAlign.left,
                                  textDirection: TextDirection.ltr,
                                  style: TextStyle(fontSize: 14, height: 1.5, color: subTextColor, fontFamily: 'Roboto'),
                                ),
                              ),
                              const SizedBox(width: 16),
                              // النص العربي (يمين)
                              Expanded(
                                flex: 5,
                                child: Text(
                                  '${ayah.textUthmani} ﴿${ayah.ayahNumber}﴾',
                                  textAlign: TextAlign.right,
                                  textDirection: TextDirection.rtl,
                                  style: TextStyle(fontSize: 22, fontFamily: 'Amiri', height: 1.8, color: textColor),
                                ),
                              ),
                            ],
                          )
                        : Text(
                            '${ayah.textUthmani} ﴿${ayah.ayahNumber}﴾',
                            textAlign: TextAlign.center,
                            textDirection: TextDirection.rtl,
                            style: TextStyle(fontSize: 24, fontFamily: 'Amiri', height: 2.0, color: textColor),
                          ),
                  ),
                );
              },
            ),
      bottomNavigationBar: Container(
        height: 70,
        decoration: BoxDecoration(color: theme.cardColor, border: Border(top: BorderSide(color: theme.dividerColor))),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildBottomIcon(Icons.headphones_rounded, 'سماع', const Color(0xFF1B5E20)),
            _buildBottomIcon(Icons.book_rounded, 'المراجع', subTextColor),
            _buildBottomIcon(Icons.swap_vert_rounded, 'لف تلقائي', subTextColor),
            _buildBottomIcon(Icons.share_rounded, 'مشاركة', subTextColor),
            _buildBottomIcon(Icons.translate_rounded, 'الترجمة', subTextColor),
            _buildBottomIcon(Icons.bookmark_rounded, 'الحفظ', subTextColor),
            _buildBottomIcon(Icons.more_horiz_rounded, 'مزيد', subTextColor),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomIcon(IconData icon, String label, Color color) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, color: color, size: 22),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(fontSize: 10, color: color)),
      ],
    );
  }
}
