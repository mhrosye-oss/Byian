import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class WaqfScreen extends StatefulWidget {
  const WaqfScreen({super.key});

  @override
  State<WaqfScreen> createState() => _WaqfScreenState();
}

class _WaqfScreenState extends State<WaqfScreen> {
  bool _isLoading = true;
  int _ayahsRead = 0;
  int _khatmahsCompleted = 0;
  int _tasbihCount = 0;

  final String apiUrl = 'https://blueviolet-viper-439935.hostingersite.com/api.php';
  final String apiToken = 'MySecretToken123!';

  @override
  void initState() {
    super.initState();
    _fetchStats();
  }

  Future<void> _fetchStats() async {
    setState(() => _isLoading = true);
    try {
      var response = await http.post(
        Uri.parse(apiUrl),
        headers: {'Authorization': 'Bearer $apiToken', 'Content-Type': 'application/json'},
        body: jsonEncode({'action': 'get_waqf_stats'}),
      );
      var data = jsonDecode(response.body);
      if (data['status'] == 'success' && data['data'] != null) {
        setState(() {
          _ayahsRead = data['data']['ayahs_read'];
          _khatmahsCompleted = data['data']['khatmahs_completed'];
          _tasbihCount = data['data']['tasbih_count'];
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('خطأ في جلب البيانات')));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _addActivity(String type) async {
    try {
      await http.post(
        Uri.parse(apiUrl),
        headers: {'Authorization': 'Bearer $apiToken', 'Content-Type': 'application/json'},
        body: jsonEncode({'action': 'add_waqf_activity', 'type': type}),
      );
      _fetchStats(); // تحديث الأرقام بعد الإضافة
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('خطأ في الاتصال')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('أثرك معنا (الصدقة الجارية)', style: TextStyle(color: Colors.white, fontSize: 18)),
        centerTitle: true,
        backgroundColor: const Color(0xFF1B5E20),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF1B5E20)))
          : Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1B5E20),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Column(
                      children: [
                        Icon(Icons.volunteer_activism, color: Colors.white, size: 60),
                        SizedBox(height: 16),
                        Text('أنت تصنع فرقاً', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
                        SizedBox(height: 8),
                        Text('كل صفحة تقرأها، وكل تسبيحة، تُحسب لك كأثر طيب.', textAlign: TextAlign.center, style: TextStyle(fontSize: 14, color: Colors.white70)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 30),
                  Text('إحصائياتك الحقيقية:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: theme.textTheme.bodyLarge?.color)),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildStatCard('$_ayahsRead', 'آية مقروءة', Icons.menu_book, theme),
                      _buildStatCard('$_khatmahsCompleted', 'ختمات تامة', Icons.auto_stories, theme),
                      _buildStatCard('$_tasbihCount', 'تسبيحة', Icons.fingerprint, theme),
                    ],
                  ),
                  const SizedBox(height: 30),
                  const Divider(),
                  const SizedBox(height: 10),
                  Text('(للتجربة: اضغط لتسجيل نشاط جديد)', style: TextStyle(color: theme.textTheme.bodySmall?.color)),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ElevatedButton(onPressed: () => _addActivity('ayah'), child: const Text('+ قراءة آية')),
                      ElevatedButton(onPressed: () => _addActivity('tasbih'), child: const Text('+ تسبيحة')),
                    ],
                  )
                ],
              ),
            ),
    );
  }

  Widget _buildStatCard(String count, String label, IconData icon, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
      ),
      child: Column(
        children: [
          Icon(icon, color: const Color(0xFF1B5E20), size: 30),
          const SizedBox(height: 8),
          Text(count, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF1B5E20))),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(fontSize: 12, color: theme.textTheme.bodySmall?.color)),
        ],
      ),
    );
  }
}
