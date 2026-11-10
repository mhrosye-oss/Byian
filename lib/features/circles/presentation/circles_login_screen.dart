import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/colors.dart';
import '../data/circle_api_client.dart';
import '../data/circle_auth_service.dart';
import '../domain/circle_models.dart';

class CirclesLoginScreen extends StatefulWidget {
  const CirclesLoginScreen({super.key, required this.onSignedIn});

  final ValueChanged<AppUser> onSignedIn;

  @override
  State<CirclesLoginScreen> createState() => _CirclesLoginScreenState();
}

class _CirclesLoginScreenState extends State<CirclesLoginScreen> {
  bool _busy = false;
  bool _registerMode = false;
  bool _obscurePassword = true;
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _signInWithGoogle() async {
    setState(() => _busy = true);
    try {
      final user = await CircleFirebaseAuthService.instance
          .loginWithGoogle(CircleApiClient.instance);
      if (!mounted || user == null) return;
      widget.onSignedIn(user);
    } on UnsupportedError catch (error) {
      _showError(error.message ?? 'Firebase غير مهيأ لهذه المنصة.');
    } catch (error) {
      _showError(_arabicError(error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _submitEmail() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final name = _nameController.text.trim();
    if (email.isEmpty || password.isEmpty || (_registerMode && name.isEmpty)) {
      _showError(_registerMode
          ? 'أدخل الاسم والبريد وكلمة المرور.'
          : 'أدخل البريد الإلكتروني وكلمة المرور.');
      return;
    }
    setState(() => _busy = true);
    try {
      final auth = CircleFirebaseAuthService.instance;
      final user = _registerMode
          ? await auth.registerWithEmail(
              CircleApiClient.instance,
              name: name,
              email: email,
              password: password,
            )
          : await auth.loginWithEmail(
              CircleApiClient.instance,
              email: email,
              password: password,
            );
      if (mounted) widget.onSignedIn(user);
    } catch (error) {
      _showError(_arabicError(error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  String _arabicError(Object error) {
    final text = error.toString();
    if (text.contains('network') || text.contains('SocketException')) {
      return 'تعذر الاتصال. تحقق من الإنترنت ثم حاول مجددًا.';
    }
    if (text.contains('ApiException')) {
      return text.replaceFirst('Exception: ', '');
    }
    if (text.contains('Api10') || text.contains('sign_in_failed')) {
      return 'تعذر تسجيل Google Play (Api10). أضف SHA-1 وSHA-256 لشهادة نسخة Play Console إلى تطبيق Android ذي المعرّف com.itqan.itqan في Firebase، ثم نزّل ملف الإعدادات الجديد وأعد البناء.';
    }
    if (text.contains('StateError')) {
      return text
          .replaceFirst('Bad state: ', '')
          .replaceFirst('Exception: ', '');
    }
    return 'تعذر تسجيل الدخول. تحقق من البيانات وإعداد Firebase ثم حاول مجددًا.';
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  InputDecoration _decoration(String label, IconData icon) => InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
      );

  @override
  Widget build(BuildContext context) => Scaffold(
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(28, 36, 28, 28),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 92,
                    height: 92,
                    decoration: BoxDecoration(
                      color: ItqanColors.emerald.withOpacity(.09),
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: const Icon(Icons.diversity_3_rounded,
                        size: 48, color: ItqanColors.emerald),
                  ),
                  const SizedBox(height: 24),
                  Text('دوائر إتقان',
                      style:
                          Theme.of(context).textTheme.headlineMedium?.copyWith(
                                color: ItqanColors.emerald,
                                fontWeight: FontWeight.w800,
                              )),
                  const SizedBox(height: 8),
                  Text('مساحات تجمعنا على الخير، والقراءة، والإنجاز.',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: ItqanColors.inkSoft,
                            height: 1.6,
                          )),
                  const SizedBox(height: 28),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: _busy ? null : _signInWithGoogle,
                      icon: _busy
                          ? const SizedBox(
                              height: 18,
                              width: 18,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white),
                            )
                          : const Icon(Icons.login_rounded),
                      label: const Text('تسجيل الدخول باستخدام Google'),
                      style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16)),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Row(children: [
                    Expanded(child: Divider()),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 12),
                      child: Text('أو البريد الإلكتروني'),
                    ),
                    Expanded(child: Divider()),
                  ]),
                  const SizedBox(height: 16),
                  if (_registerMode)
                    TextField(
                      controller: _nameController,
                      enabled: !_busy,
                      textInputAction: TextInputAction.next,
                      decoration: _decoration('الاسم', Icons.person_outline),
                    ),
                  if (_registerMode) const SizedBox(height: 12),
                  TextField(
                    controller: _emailController,
                    enabled: !_busy,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    decoration:
                        _decoration('البريد الإلكتروني', Icons.email_outlined),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _passwordController,
                    enabled: !_busy,
                    obscureText: _obscurePassword,
                    onSubmitted: (_) => _submitEmail(),
                    decoration:
                        _decoration('كلمة المرور', Icons.lock_outline_rounded)
                            .copyWith(
                      suffixIcon: IconButton(
                        onPressed: () => setState(
                            () => _obscurePassword = !_obscurePassword),
                        icon: Icon(_obscurePassword
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _busy ? null : _submitEmail,
                      icon: const Icon(Icons.email_outlined),
                      label: Text(_registerMode
                          ? 'إنشاء حساب بالبريد الإلكتروني'
                          : 'الدخول بالبريد الإلكتروني'),
                      style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 15)),
                    ),
                  ),
                  TextButton(
                    onPressed: _busy
                        ? null
                        : () => setState(() => _registerMode = !_registerMode),
                    child: Text(_registerMode
                        ? 'لديك حساب؟ تسجيل الدخول'
                        : 'ليس لديك حساب؟ إنشاء حساب جديد'),
                  ),
                  Text('كلمة المرور تُدار عبر Firebase ولا تُحفظ داخل التطبيق.',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: ItqanColors.muted,
                          )),
                  const SizedBox(height: 14),
                  TextButton.icon(
                    onPressed: _busy ? null : () => context.go('/itqan-home'),
                    icon: const Icon(Icons.arrow_forward_rounded),
                    label: const Text('تخطي إلى القائمة الرئيسية'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
}
