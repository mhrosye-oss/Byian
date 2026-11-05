import 'package:flutter/material.dart';

// نموذج بيانات المساهم (سيتم جلبها من الباك اند مستقبلاً)
class Contributor {
  final String name;
  final String country;
  final String amount;
  final bool showAmount; // خيار إخفاء المبلغ

  Contributor({
    required this.name,
    required this.country,
    required this.amount,
    required this.showAmount,
  });
}

class ContributorsScreen extends StatefulWidget {
  const ContributorsScreen({super.key});

  @override
  State<ContributorsScreen> createState() => _ContributorsScreenState();
}

class _ContributorsScreenState extends State<ContributorsScreen> {
  bool _isLoading = true;
  List<Contributor> _contributors = [];

  @override
  void initState() {
    super.initState();
    _loadContributors();
  }

  // محاكاة جلب البيانات من السيرفر
  Future<void> _loadContributors() async {
    await Future.delayed(const Duration(milliseconds: 500)); // تأخير بسيط للتجربة
    setState(() {
      _contributors = [
        Contributor(name: 'الأستاذ صالح القنان', country: 'اليمن', amount: '1,000,000 ر.ي', showAmount: true),
        Contributor(name: 'فاعل خير', country: 'السعودية', amount: '500,000 ر.س', showAmount: false), // مبلغ مخفي
        Contributor(name: 'عائلة الآنسي', country: 'اليمن', amount: '250,000 ر.ي', showAmount: true),
        Contributor(name: 'أحد محبي الخير', country: 'الإمارات', amount: '100,000 د.إ', showAmount: false), // مبلغ مخفي
        Contributor(name: 'مجهول', country: 'الكويت', amount: '50,000 د.ك', showAmount: false), // مبلغ مخفي
      ];
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('شكراً لمساهمينا', style: TextStyle(color: Colors.white)),
        centerTitle: true,
        backgroundColor: const Color(0xFF1B5E20),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          // ترويسة توضيحية
          Container(
            width: double.infinity,
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF1B5E20).withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                const Icon(Icons.favorite_rounded, color: Color(0xFF1B5E20), size: 40),
                const SizedBox(height: 10),
                Text(
                  'هذا التطبيق قائم بفضل دعمكم',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: theme.textTheme.bodyLarge?.color),
                ),
                const SizedBox(height: 5),
                Text(
                  'جزى الله خيراً كل من ساهم في بناء ونشر هذا العمل، وجعله في موازين حسناتهم.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, color: theme.textTheme.bodySmall?.color),
                ),
              ],
            ),
          ),

          // قائمة المساهمين
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: Color(0xFF1B5E20)))
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _contributors.length,
                    itemBuilder: (context, index) {
                      final contributor = _contributors[index];
                      return Card(
                        color: theme.cardColor,
                        margin: const EdgeInsets.only(bottom: 12),
                        elevation: 2,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          leading: CircleAvatar(
                            backgroundColor: const Color(0xFF1B5E20).withOpacity(0.1),
                            child: const Icon(Icons.person, color: Color(0xFF1B5E20)),
                          ),
                          title: Text(
                            contributor.name,
                            style: TextStyle(fontWeight: FontWeight.bold, color: theme.textTheme.bodyLarge?.color),
                          ),
                          subtitle: Text(
                            contributor.country,
                            style: TextStyle(color: theme.textTheme.bodySmall?.color),
                          ),
                          trailing: contributor.showAmount
                              ? Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    const Text('المساهمة', style: TextStyle(fontSize: 10, color: Colors.grey)),
                                    Text(
                                      contributor.amount,
                                      style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1B5E20), fontSize: 14),
                                    ),
                                  ],
                                )
                              : const Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Icon(Icons.lock_rounded, size: 16, color: Colors.grey),
                                    SizedBox(height: 4),
                                    Text('مبلغ مخفي', style: TextStyle(fontSize: 10, color: Colors.grey)),
                                  ],
                                ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
