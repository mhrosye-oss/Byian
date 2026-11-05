import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../../core/services/auth_service.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});
  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _isLoading = false;

  Future<void> _register() async {
    setState(() => _isLoading = true);
    try {
      var response = await http.post(
        Uri.parse('https://blueviolet-viper-439935.hostingersite.com/api.php'),
        headers: {'Authorization': 'Bearer MySecretToken123!', 'Content-Type': 'application/json'},
        body: jsonEncode({'action': 'register', 'name': _name.text.trim(), 'email': _email.text.trim(), 'password': _password.text}),
      );
      var data = jsonDecode(response.body);
      if (data['status'] == 'success') {
        await AuthService.saveUser(data['user']['name'], data['user']['email']);
        if (mounted) {
          Navigator.pop(context); // إغلاق شاشة التسجيل
          Navigator.pop(context, true); // إغلاق شاشة الدخول وإرجاع نجاح
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(data['message'])));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('خطأ في الاتصال')));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('إنشاء حساب'), backgroundColor: const Color(0xFF1B5E20)),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(controller: _name, decoration: const InputDecoration(labelText: 'الاسم')),
            const SizedBox(height: 15),
            TextField(controller: _email, decoration: const InputDecoration(labelText: 'البريد الإلكتروني'), keyboardType: TextInputType.emailAddress),
            const SizedBox(height: 15),
            TextField(controller: _password, decoration: const InputDecoration(labelText: 'كلمة المرور'), obscureText: true),
            const SizedBox(height: 30),
            SizedBox(width: double.infinity, child: ElevatedButton(onPressed: _isLoading ? null : _register, style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1B5E20)), child: Text(_isLoading ? 'جاري...' : 'تسجيل'))),
          ],
        ),
      ),
    );
  }
}
