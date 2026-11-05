import 'package:flutter/material.dart';

class MyKhatmahTaskScreen extends StatefulWidget {
  final String memberName;
  final int startPage;
  final int endPage;

  const MyKhatmahTaskScreen({
    super.key,
    required this.memberName,
    required this.startPage,
    required this.endPage,
  });

  @override
  State<MyKhatmahTaskScreen> createState() => _MyKhatmahTaskScreenState();
}

class _MyKhatmahTaskScreenState extends State<MyKhatmahTaskScreen> {
  // لتخزين الصفحات التي تمت قراءتها (للتجربة المحلية)
  final Set<int> _readPages = {};

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // حساب عدد الصفحات الكلي المخصصة له
    final int totalPages = (widget.endPage - widget.startPage) + 1;
    final int pagesRemaining = totalPages - _readPages.length;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text('مهمة ${widget.memberName}', style: const TextStyle(color: Colors.white)),
        centerTitle: true,
        backgroundColor: const Color(0xFF1B5E20),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          // بطاقة ملخص المهمة
          Container(
            width: double.infinity,
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF1B5E20),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                Text(
                  'حصتك من الختمة',
                  style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 14),
                ),
                const SizedBox(height: 8),
                Text(
                  'من صفحة ${widget.startPage} إلى ${widget.endPage}',
                  style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildStat('متبقي', '$pagesRemaining', Colors.amber),
                    const SizedBox(width: 20),
                    _buildStat('تمت', '${_readPages.length}', Colors.greenAccent),
                  ],
                )
              ],
            ),
          ),

          // قائمة الصفحات
          Expanded(
            child: ListView.builder(
              itemCount: totalPages,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemBuilder: (context, index) {
                final pageNumber = widget.startPage + index;
                final isRead = _readPages.contains(pageNumber);

                return Card(
                  color: isRead ? const Color(0xFF1B5E20).withOpacity(0.05) : theme.cardColor,
                  margin: const EdgeInsets.only(bottom: 10),
                  child: CheckboxListTile(
                    value: isRead,
                    activeColor: const Color(0xFF1B5E20),
                    title: Text(
                      'صفحة $pageNumber',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        decoration: isRead ? TextDecoration.lineThrough : null,
                        color: isRead ? Colors.grey : theme.textTheme.bodyLarge?.color,
                      ),
                    ),
                    secondary: Icon(
                      isRead ? Icons.check_circle : Icons.menu_book,
                      color: isRead ? const Color(0xFF1B5E20) : Colors.grey,
                    ),
                    onChanged: (bool? value) {
                      setState(() {
                        if (value == true) {
                          _readPages.add(pageNumber);
                        } else {
                          _readPages.remove(pageNumber);
                        }
                      });
                      // هنا سيتم إرسال طلب للسيرفر لتحديث حالة الصفحة لاحقاً
                      if (value == true && _readPages.length == totalPages) {
                        _showCompletionDialog();
                      }
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStat(String label, String value, Color color) {
    return Column(
      children: [
        Text(value, style: TextStyle(color: color, fontSize: 20, fontWeight: FontWeight.bold)),
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
      ],
    );
  }

  void _showCompletionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ما شاء الله!'),
        content: const Text('لقد أتممت حصتك من الختمة. تقبل الله منك.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // إغلاق النافذة
              Navigator.pop(context); // العودة للشاشة السابقة
            },
            child: const Text('حسناً'),
          ),
        ],
      ),
    );
  }
}
