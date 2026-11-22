import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../../core/services/auth_service.dart';
import '../../../core/services/google_auth_service.dart';
import '../../itqan_journey/data/journey_auth_api.dart';
import 'register_screen.dart';
import '../../home/home_screen.dart';
import '../../../core/theme/colors.dart';

class LoginScreen extends StatefulWidget {
  final bool sessionExpired;

  const LoginScreen({super.key, this.sessionExpired = false});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _busy = false;
  bool _remember = true;
  bool _obscure = true;
  late final JourneyAuthApi _api = JourneyAuthApi(client: http.Client());

  @override
  void initState() {
    super.initState();
    _restoreSavedCredentials();
    if (widget.sessionExpired) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _message('انتهت الجلسة. سجّل الدخول للمتابعة.');
      });
    }
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
      if (_remember) {
        await AuthService.saveCredentials(_email.text.trim(), _password.text);
      } else {
        await AuthService.clearCredentials();
      }
      if (mounted) {
        if (Navigator.canPop(context)) {
          Navigator.pop(context, true);
        } else {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute<void>(builder: (_) => const HomeScreen()),
            (_) => false,
          );
        }
      }
    } catch (e) {
      _message('$e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _loginWithGoogle() async {
    setState(() => _busy = true);
    try {
      final result = await GoogleAuthService.signIn();
      if (!mounted) return;
      if (result.isCancelled) return;
      if (!result.success || result.firebaseIdToken == null) {
        _message(result.message ?? 'فشل تسجيل الدخول بواسطة Google');
        return;
      }

      await _api.firebaseLogin(idToken: result.firebaseIdToken!);
      if (!mounted) return;
      _message('تم تسجيل الدخول بنجاح');

      if (!mounted) return;
      if (Navigator.canPop(context)) {
        Navigator.pop(context, true);
      } else {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute<void>(builder: (_) => const HomeScreen()),
          (_) => false,
        );
      }
    } catch (e) {
      if (mounted) _message('حدث خطأ أثناء الاتصال: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _message(String value) => ScaffoldMessenger.of(context)
      .showSnackBar(SnackBar(content: Text(value)));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [ItqanColors.cream, ItqanColors.surfaceSoft],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── Logo / Brand ──────────────────────────────────────────
                Center(
                  child: Column(
                    children: [
                      Container(
                        width: 88,
                        height: 88,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [ItqanColors.emerald, ItqanColors.emeraldDark],
                          ),
                          borderRadius: BorderRadius.circular(28),
                          boxShadow: [
                            BoxShadow(
                              color: ItqanColors.emerald.withValues(alpha: 0.3),
                              blurRadius: 24,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: const Icon(Icons.auto_awesome_rounded,
                            color: ItqanColors.white, size: 44),
                      ),
                      const SizedBox(height: 18),
                      const Text(
                        'إتقان',
                        style: TextStyle(
                          fontFamily: 'Tajawal',
                          fontSize: 32,
                          fontWeight: FontWeight.w800,
                          color: ItqanColors.emerald,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'مساحة يومية للسكينة والقرآن',
                        style: TextStyle(
                          fontFamily: 'Tajawal',
                          fontSize: 14,
                          color: ItqanColors.inkSoft,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 40),

                // ── Login Card ────────────────────────────────────────────
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: ItqanColors.surface,
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(color: ItqanColors.border),
                    boxShadow: [
                      BoxShadow(
                        color: ItqanColors.ink.withValues(alpha: 0.07),
                        blurRadius: 24,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        'تسجيل الدخول',
                        style: TextStyle(
                          fontFamily: 'Tajawal',
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: ItqanColors.ink,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),

                      // Email field
                      TextField(
                        controller: _email,
                        keyboardType: TextInputType.emailAddress,
                        decoration: InputDecoration(
                          labelText: 'البريد الإلكتروني',
                          prefixIcon: const Icon(Icons.email_outlined,
                              color: ItqanColors.emerald, size: 20),
                          filled: true,
                          fillColor: ItqanColors.cream,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: const BorderSide(color: ItqanColors.border),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: const BorderSide(color: ItqanColors.border),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: const BorderSide(
                                color: ItqanColors.emerald, width: 1.5),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Password field
                      TextField(
                        controller: _password,
                        obscureText: _obscure,
                        decoration: InputDecoration(
                          labelText: 'كلمة المرور',
                          prefixIcon: const Icon(Icons.lock_outline_rounded,
                              color: ItqanColors.emerald, size: 20),
                          filled: true,
                          fillColor: ItqanColors.cream,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: const BorderSide(color: ItqanColors.border),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: const BorderSide(color: ItqanColors.border),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: const BorderSide(
                                color: ItqanColors.emerald, width: 1.5),
                          ),
                          suffixIcon: IconButton(
                            onPressed: () => setState(() => _obscure = !_obscure),
                            icon: Icon(
                              _obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                              color: ItqanColors.muted,
                              size: 20,
                            ),
                          ),
                        ),
                      ),

                      // Remember me
                      Row(
                        children: [
                          Transform.scale(
                            scale: 0.9,
                            child: Checkbox(
                              value: _remember,
                              onChanged: (v) => setState(() => _remember = v ?? false),
                              activeColor: ItqanColors.emerald,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(5)),
                            ),
                          ),
                          const Text(
                            'تذكر بيانات الدخول',
                            style: TextStyle(
                              fontFamily: 'Tajawal',
                              fontSize: 13,
                              color: ItqanColors.inkSoft,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 8),

                      // Login button
                      SizedBox(
                        height: 54,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [ItqanColors.emerald, ItqanColors.emeraldDark],
                            ),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: ItqanColors.emerald.withValues(alpha: 0.3),
                                blurRadius: 14,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: FilledButton(
                            onPressed: _busy ? null : _login,
                            style: FilledButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16)),
                            ),
                            child: _busy
                                ? const SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2.5, color: Colors.white))
                                : const Text('دخول',
                                    style: TextStyle(
                                        fontSize: 16, fontWeight: FontWeight.w700)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // ── Divider ───────────────────────────────────────────────
                Row(children: [
                  Expanded(child: Divider(color: ItqanColors.border.withValues(alpha: 0.8))),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    child: Text('أو',
                        style: TextStyle(
                            color: ItqanColors.muted,
                            fontSize: 13,
                            fontWeight: FontWeight.w600)),
                  ),
                  Expanded(child: Divider(color: ItqanColors.border.withValues(alpha: 0.8))),
                ]),

                const SizedBox(height: 16),

                // ── Google Sign-in ────────────────────────────────────────
                Container(
                  height: 54,
                  decoration: BoxDecoration(
                    color: ItqanColors.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: ItqanColors.border),
                    boxShadow: [
                      BoxShadow(
                        color: ItqanColors.ink.withValues(alpha: 0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: OutlinedButton.icon(
                    onPressed: _busy ? null : _loginWithGoogle,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: BorderSide.none,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                    ),
                    icon: Image.network(
                      'https://www.gstatic.com/images/branding/product/2x/googleg_48dp.png',
                      width: 22,
                      height: 22,
                      errorBuilder: (_, __, ___) =>
                          const Icon(Icons.g_mobiledata, size: 28, color: Colors.blue),
                    ),
                    label: const Text(
                      'الدخول بواسطة Google',
                      style: TextStyle(
                        fontFamily: 'Tajawal',
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: ItqanColors.ink,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // ── Secondary actions ─────────────────────────────────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute<void>(
                              builder: (_) => const RegisterScreen())),
                      child: const Text(
                        'إنشاء حساب',
                        style: TextStyle(color: ItqanColors.emerald, fontWeight: FontWeight.w600),
                      ),
                    ),
                    Container(
                      width: 1,
                      height: 16,
                      color: ItqanColors.border,
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute<void>(builder: (_) => const HomeScreen()),
                          (_) => false),
                      child: const Text(
                        'المتابعة كضيف',
                        style: TextStyle(color: ItqanColors.inkSoft, fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
