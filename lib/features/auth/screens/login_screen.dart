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
  bool _obscurePassword = true;
  bool _rememberMe = false;

  @override
  void initState() {
    super.initState();
    _loadSavedCredentials();
  }

  Future<void> _loadSavedCredentials() async {
    final creds = await AuthService.getSavedCredentials();
    if (creds != null) {
      setState(() {
        _email.text = creds['email']!;
        _password.text = creds['pass']!;
        _rememberMe = true;
      });
    }
  }

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
        
        if (_rememberMe) {
          await AuthService.saveCredentials(_email.text.trim(), _password.text);
        } else {
          await AuthService.clearCredentials();
        }
        
        if (mounted) Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(data['message'])));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('خطأ في الاتصال')));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _loginWithGoogle() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('جاري الاتصال بجوجل... (يتطلب إعداد Firebase)')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('تسجيل الدخول'), backgroundColor: const Color(0xFF1B5E20)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const SizedBox(height: 20),
            const Icon(Icons.lock_person_rounded, size: 80, color: Color(0xFF1B5E20)),
            const SizedBox(height: 30),
            TextField(controller: _email, decoration: const InputDecoration(labelText: 'البريد الإلكتروني', prefixIcon: Icon(Icons.email)), keyboardType: TextInputType.emailAddress),
            const SizedBox(height: 15),
            TextField(
              controller: _password,
              decoration: InputDecoration(
                labelText: 'كلمة المرور',
                prefixIcon: const Icon(Icons.lock),
                suffixIcon: IconButton(
                  icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility, color: Colors.grey),
                  onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                ),
              ),
              obscureText: _obscurePassword,
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Checkbox(
                  value: _rememberMe,
                  activeColor: const Color(0xFF1B5E20),
                  onChanged: (val) => setState(() => _rememberMe = val!),
                ),
                const Text('تذكرني', style: TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _login,
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1B5E20), padding: const EdgeInsets.symmetric(vertical: 16)),
                child: Text(_isLoading ? 'جاري...' : 'دخول', style: const TextStyle(fontSize: 18)),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RegisterScreen())),
              child: const Text('ليس لديك حساب؟ سجل الآن', style: TextStyle(color: Color(0xFF1B5E20))),
            ),
            const SizedBox(height: 20),
            const Row(children: [Expanded(child: Divider()), Padding(padding: EdgeInsets.symmetric(horizontal: 10), child: Text('أو')), Expanded(child: Divider())]),
            const SizedBox(height: 20),
            OutlinedButton.icon(
              onPressed: _loginWithGoogle,
              icon: const Icon(Icons.g_mobiledata, size: 30, color: Colors.red),
              label: const Text('الدخول بواسطة Google', style: TextStyle(fontSize: 16, color: Colors.black87)),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
                side: const BorderSide(color: Colors.grey),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            )
          ],
        ),
      ),
    );
  }
}
