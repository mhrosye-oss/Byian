import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../../core/services/auth_service.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _isLoading = false;

  Future<void> _login() async {
    setState(() => _isLoading = true);
    try {
      var response = await http.post(
        Uri.parse('https://blueviolet-viper-439935.hostingersite.com/api.php'),
        headers: {'Authorization': 'Bearer MySecretToken123!', 'Content-Type': 'application/json'},
        body: jsonEncode({'action': 'login', 'email': _email.text.trim(), 'password': _password.text}),
      );
      var data = jsonDecode(response.body);
      if (data['status'] == 'success') {
        await AuthService.saveUser(data['user']['name'], data['user']['email']);
        if (mounted) Navigator.pop(context, true); // إغلاق الشاشة وإرجاع نجاح
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
      appBar: AppBar(title: const Text('تسجيل الدخول'), backgroundColor: const Color(0xFF1B5E20)),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(controller: _email, decoration: const InputDecoration(labelText: 'البريد الإلكتروني'), keyboardType: TextInputType.emailAddress),
            const SizedBox(height: 15),
            TextField(controller: _password, decoration: const InputDecoration(labelText: 'كلمة المرور'), obscureText: true),
            const SizedBox(height: 30),
            SizedBox(width: double.infinity, child: ElevatedButton(onPressed: _isLoading ? null : _login, style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1B5E20)), child: Text(_isLoading ? 'جاري...' : 'دخول'))),
            TextButton(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RegisterScreen())), child: const Text('ليس لديك حساب؟ سجل الآن')),
          ],
        ),
      ),
    );
  }
}
