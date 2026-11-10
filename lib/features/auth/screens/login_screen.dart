import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../../core/services/auth_service.dart';
import '../../../core/services/firebase_auth_api.dart';
import '../../../core/services/firebase_messaging_service.dart';
import '../../../core/services/google_firebase_auth_service.dart';
import '../../itqan_journey/data/journey_auth_api.dart';
import 'register_screen.dart';
import '../../home/home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _busy = false;
  bool _remember = true;
  bool _obscure = true;
  bool _googleBusy = false;
  late final JourneyAuthApi _api = JourneyAuthApi(client: http.Client());
  @override
  void initState() {
    super.initState();
    _restoreSavedCredentials();
  }

  Future<void> _restoreSavedCredentials() async {
    try {
      final saved = await AuthService.getSavedCredentials();
      if (!mounted || saved == null) return;
      _email.text = saved['email'] ?? '';
      _password.text = saved['pass'] ?? '';
    } catch (_) {
      if (mounted) _message('تعذر استعادة بيانات الدخول المحفوظة.');
    }
  }

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (_email.text.trim().isEmpty || _password.text.isEmpty) {
      _message('أدخل البريد وكلمة المرور.');
      return;
    }
    setState(() => _busy = true);
    try {
      await _api.login(_email.text.trim(), _password.text);
      await _registerPushToken();
      if (_remember) {
        await AuthService.saveCredentials(_email.text.trim(), _password.text);
      } else {
        await AuthService.clearCredentials();
      }
      if (mounted) {
        Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute<void>(builder: (_) => const HomeScreen()),
            (_) => false);
      }
    } catch (e) {
      _message('$e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _registerPushToken() async {
    try {
      await FirebaseMessagingService.instance.registerAfterLogin();
    } catch (_) {
      // Notifications are optional and must not block authentication.
    }
  }

  Future<void> _loginWithGoogle() async {
    setState(() => _googleBusy = true);
    try {
      final idToken = await GoogleFirebaseAuthService.instance
          .signInAndGetFirebaseIdToken();
      await FirebaseAuthApi().exchangeFirebaseIdToken(idToken);
      await _registerPushToken();
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute<void>(builder: (_) => const HomeScreen()),
          (_) => false,
        );
      }
    } catch (error) {
      if (mounted) _message('$error');
    } finally {
      if (mounted) setState(() => _googleBusy = false);
    }
  }

  void _message(String value) => ScaffoldMessenger.of(context)
      .showSnackBar(SnackBar(content: Text(value)));
  @override
  Widget build(BuildContext context) => Scaffold(
      appBar: AppBar(title: const Text('تسجيل الدخول')),
      body: ListView(padding: const EdgeInsets.all(24), children: [
        const Icon(Icons.auto_awesome, size: 64),
        const SizedBox(height: 24),
        TextField(
            controller: _email,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(
                labelText: 'البريد الإلكتروني', border: OutlineInputBorder())),
        const SizedBox(height: 16),
        TextField(
            controller: _password,
            obscureText: _obscure,
            decoration: InputDecoration(
                labelText: 'كلمة المرور',
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                    onPressed: () => setState(() => _obscure = !_obscure),
                    icon: Icon(
                        _obscure ? Icons.visibility : Icons.visibility_off)))),
        CheckboxListTile(
            value: _remember,
            onChanged: (v) => setState(() => _remember = v ?? false),
            title: const Text('تذكر بيانات الدخول'),
            contentPadding: EdgeInsets.zero),
        FilledButton(
            onPressed: _busy ? null : _login,
            child:
                _busy ? const CircularProgressIndicator() : const Text('دخول')),
        const SizedBox(height: 10),
        OutlinedButton.icon(
          onPressed: _busy || _googleBusy ? null : _loginWithGoogle,
          icon: const Icon(Icons.login_rounded),
          label: _googleBusy
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('المتابعة باستخدام Google'),
        ),
        TextButton(
            onPressed: () => Navigator.push(
                context,
                MaterialPageRoute<void>(
                    builder: (_) => const RegisterScreen())),
            child: const Text('إنشاء حساب')),
        TextButton(
            onPressed: () => Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute<void>(builder: (_) => const HomeScreen()),
                (_) => false),
            child: const Text('المتابعة كضيف'))
      ]));
}
