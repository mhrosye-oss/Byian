import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class KhatmahScreen extends StatefulWidget {
  const KhatmahScreen({super.key});

  @override
  State<KhatmahScreen> createState() => _KhatmahScreenState();
}

class _KhatmahScreenState extends State<KhatmahScreen> {
  static const int _totalQuranPages = 604;
  static const String _currentPageKey = 'khatmah_current_page';
  static const String _totalReadKey = 'khatmah_total_pages_read';

  int _currentPage = 0;
  int _totalReadPages = 0;

  @override
  void initState() {
    super.initState();
    _loadProgress();
  }

  Future<void> _loadProgress() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _currentPage = prefs.getInt(_currentPageKey) ?? 0;
      _totalReadPages = prefs.getInt(_totalReadKey) ?? 0;
    });
  }

  Future<void> _saveProgress() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_currentPageKey, _currentPage);
    await prefs.setInt(_totalReadKey, _totalReadPages);
  }

  Future<void> _readPages(int pages) async {
    final update = _currentPage + pages;
    if (update < 0) {
      return;
    }

    setState(() {
      _currentPage = update;
      _totalReadPages = update;
    });

    await _saveProgress();
  }

  double get _completionPercent {
    if (_totalQuranPages <= 0) return 0;
    return ((_currentPage / _totalQuranPages) * 100).clamp(0, 100);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text(
          'ختمة القرآن',
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
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x1A000000),
                    blurRadius: 10,
                    offset: Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                children: [
                  const Text(
                    'التقدم الإجمالي',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1A1A1A),
                    ),
                    textDirection: TextDirection.rtl,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '${_completionPercent.toStringAsFixed(1)}%',
                    style: const TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFFD32F2F),
                    ),
                    textDirection: TextDirection.rtl,
                  ),
                  const SizedBox(height: 18),
                  LinearProgressIndicator(
                    value: _completionPercent / 100,
                    minHeight: 10,
                    backgroundColor: const Color(0xFF1A1A1A).withOpacity(0.08),
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      Color(0xFFD32F2F),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x1A000000),
                    blurRadius: 10,
                    offset: Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'عداد القراءة',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1A1A1A),
                    ),
                    textDirection: TextDirection.rtl,
                  ),
                  const SizedBox(height: 14),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'الصفحات الحالية: $_currentPage',
                              style: const TextStyle(
                                fontSize: 14,
                                color: Color(0xFF1A1A1A),
                              ),
                              textDirection: TextDirection.rtl,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'إجمالي الصفحات: $_totalReadPages',
                              style: const TextStyle(
                                fontSize: 14,
                                color: Color(0xFF1A1A1A),
                              ),
                              textDirection: TextDirection.rtl,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  ElevatedButton(
                    onPressed: () async {
                      await _readPages(10);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFD32F2F),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 14,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text(
                      '+ قراءة 10 صفحات',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
