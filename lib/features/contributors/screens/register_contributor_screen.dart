import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class RegisterContributorScreen extends StatefulWidget {
  const RegisterContributorScreen({super.key});
  @override
  State<RegisterContributorScreen> createState() => _RegisterContributorScreenState();
}

class _RegisterContributorScreenState extends State<RegisterContributorScreen> {
  final _name = TextEditingController();
  final _country = TextEditingController();
  final _amount = TextEditingController();
  final _message = TextEditingController();
  bool _showAmount = true;
  bool _isAnonymous = false;
  bool _isLoading = false;

  Future<void> _submit() async {
    setState(() => _isLoading = true);
    try {
      var response = await http.post(
        Uri.parse('https://blueviolet-viper-439935.hostingersite.com/api.php'),
        headers: {'Authorization': 'Bearer MySecretToken123!', 'Content-Type': 'application/json'},
        body: jsonEncode({
          'action': 'register_contributor',
          'name': _isAnonymous ? 'فاعل خير' : _name.text.trim(),
          'country': _country.text.trim(),
          'amount': double.tryParse(_amount.text) ?? 0,
          'message': _message.text.trim(),
          'show_amount': _showAmount,
          'is_anonymous': _isAnonymous,
        }),
      );
      var data = jsonDecode(response.body);
      if (!mounted) return;
      if (data['status'] == 'success') {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم تسجيل مساهمتك، شكراً لك!')));
          Navigator.pop(context, true);
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(data['message'])));
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('خطأ في الاتصال')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('التسجيل كمساهم'), backgroundColor: const Color(0xFF1B5E20)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('ساهم في استمرار التطبيق', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: theme.textTheme.bodyLarge?.color)),
            const SizedBox(height: 10),
            Text('مساهمتك ستساعدنا في تغطية تكاليف السيرفرات وتطوير المزيد من الخدمات.', style: TextStyle(color: theme.textTheme.bodySmall?.color)),
            const SizedBox(height: 24),

            // مفتاح إخفاء الاسم
            SwitchListTile(
              title: const Text('مساهمة مجهولة (فاعل خير)'),
              subtitle: const Text('لن يظهر اسمك في جدار الشرف.'),
              value: _isAnonymous,
              activeColor: const Color(0xFF1B5E20),
              onChanged: (val) => setState(() => _isAnonymous = val),
            ),
            
            if (!_isAnonymous) ...[
              TextField(controller: _name, decoration: const InputDecoration(labelText: 'الاسم (كما تريد ظهوره)')),
              const SizedBox(height: 15),
            ],
            
            TextField(controller: _country, decoration: const InputDecoration(labelText: 'الدولة')),
            const SizedBox(height: 15),
            TextField(controller: _amount, decoration: const InputDecoration(labelText: 'المبلغ'), keyboardType: TextInputType.number),
            const SizedBox(height: 15),
            TextField(controller: _message, decoration: const InputDecoration(labelText: 'رسالة أو إهداء (اختياري)'), maxLines: 2),
            const SizedBox(height: 15),
            
            // مفتاح إخفاء المبلغ
            SwitchListTile(
              title: const Text('إظهار المبلغ في جدار الشرف'),
              subtitle: const Text('إذا ألغيته، سيظهر اسمك فقط والمبلغ سيكون سرياً.'),
              value: _showAmount,
              activeColor: const Color(0xFF1B5E20),
              onChanged: (val) => setState(() => _showAmount = val),
            ),
            
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _submit,
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1B5E20), padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                child: Text(_isLoading ? 'جاري الإرسال...' : 'تأكيد المساهمة', style: const TextStyle(fontSize: 18, color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
