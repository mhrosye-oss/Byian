import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'register_contributor_screen.dart';

class HallOfFameScreen extends StatefulWidget {
  const HallOfFameScreen({super.key});

  @override
  State<HallOfFameScreen> createState() => _HallOfFameScreenState();
}

class _HallOfFameScreenState extends State<HallOfFameScreen> {
  bool _isLoading = true;
  List<dynamic> _contributors = [];

  @override
  void initState() {
    super.initState();
    _fetchContributors();
  }

  Future<void> _fetchContributors() async {
    setState(() => _isLoading = true);
    try {
      var response = await http.post(
        Uri.parse('https://blueviolet-viper-439935.hostingersite.com/api.php'),
        headers: {'Authorization': 'Bearer MySecretToken123!', 'Content-Type': 'application/json'},
        body: jsonEncode({'action': 'get_contributors'}),
      );
      var data = jsonDecode(response.body);
      if (!mounted) return;
      if (data['status'] == 'success') {
        setState(() => _contributors = data['data']);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('خطأ في الاتصال')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Color _parseHex(String hex) {
    hex = hex.replaceAll('#', '');
    return Color(int.parse('FF$hex', radix: 16));
  }

  IconData _getIcon(String icon) {
    switch (icon) {
      case 'diamond': return Icons.diamond_rounded;
      case 'workspace_premium': return Icons.workspace_premium_rounded;
      case 'military_tech': return Icons.military_tech_rounded;
      default: return Icons.stars_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('جدار الشرف', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: const Color(0xFF1B5E20),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          // البطاقة العلوية (الترويسة)
          Container(
            width: double.infinity,
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFF1B5E20), Color(0xFF2E7D32)]),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [BoxShadow(color: const Color(0xFF1B5E20).withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 5))],
            ),
            child: Column(
              children: [
                const Icon(Icons.favorite_rounded, color: Colors.white, size: 40),
                const SizedBox(height: 10),
                const Text('شكراً لداعمينا', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                const SizedBox(height: 5),
                const Text('أنتم سبب استمرار هذا العمل الخيري', style: TextStyle(color: Colors.white70, fontSize: 14)),
                const SizedBox(height: 15),
                ElevatedButton.icon(
                  onPressed: () async {
                    final res = await Navigator.push(context, MaterialPageRoute(builder: (_) => const RegisterContributorScreen()));
                    if (res == true) _fetchContributors();
                  },
                  icon: const Icon(Icons.add_card_rounded, color: Color(0xFF1B5E20)),
                  label: const Text('انضم لقائمة الداعمين', style: TextStyle(color: Color(0xFF1B5E20), fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                )
              ],
            ),
          ),
          
          // قائمة المساهمين
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: Color(0xFF1B5E20)))
                : _contributors.isEmpty
                    ? const Center(child: Text('لا يوجد مساهمون حالياً، كن أول الداعمين!'))
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: _contributors.length,
                        itemBuilder: (context, index) {
                          final c = _contributors[index];
                          final tierColor = _parseHex(c['color_hex']);
                          final isTop = index == 0; // تمييز أول شخص (شريك التأسيس)

                          return Container(
                            margin: const EdgeInsets.only(bottom: 16),
                            decoration: BoxDecoration(
                              color: theme.cardColor,
                              borderRadius: BorderRadius.circular(16),
                              border: isTop ? Border.all(color: tierColor, width: 2) : null,
                              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
                            ),
                            child: ListTile(
                              contentPadding: const EdgeInsets.all(16),
                              leading: CircleAvatar(
                                radius: 25,
                                backgroundColor: tierColor.withOpacity(0.15),
                                child: Icon(_getIcon(c['icon_name']), color: tierColor, size: 28),
                              ),
                              title: Row(
                                children: [
                                  Text(c['name'], style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: theme.textTheme.bodyLarge?.color)),
                                  const SizedBox(width: 8),
                                  if (isTop) Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), decoration: BoxDecoration(color: tierColor.withOpacity(0.2), borderRadius: BorderRadius.circular(6)), child: Text(c['tier_name'], style: TextStyle(fontSize: 10, color: tierColor, fontWeight: FontWeight.bold))),
                                ],
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(c['country'] ?? '', style: TextStyle(color: theme.textTheme.bodySmall?.color)),
                                  if (c['message'] != null && c['message'].toString().isNotEmpty)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 8),
                                      child: Text('"${c['message']}"', style: const TextStyle(fontStyle: FontStyle.italic, color: Colors.blueGrey)),
                                    ),
                                ],
                              ),
                              trailing: c['show_amount'] == 1
                                  ? Text('${c['amount']} ${c['currency']}', style: TextStyle(fontWeight: FontWeight.bold, color: tierColor))
                                  : const Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.lock, size: 16, color: Colors.grey), Text('سري', style: TextStyle(fontSize: 10, color: Colors.grey))]),
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
