import 'package:flutter/material.dart';

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

  Future<void> _signIn() async {
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

  String _arabicError(Object error) {
    final text = error.toString();
    if (text.contains('network') || text.contains('SocketException')) {
      return 'تعذر الاتصال. تحقق من الإنترنت ثم حاول مجددًا.';
    }
    if (text.contains('ApiException')) {
      return text.replaceFirst('Exception: ', '');
    }
    return 'تعذر تسجيل الدخول عبر Google. تحقق من إعداد Firebase وحاول مجددًا.';
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

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
                      color: ItqanColors.emerald.withValues(alpha: .09),
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: const Icon(
                      Icons.diversity_3_rounded,
                      size: 48,
                      color: ItqanColors.emerald,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'دوائر إتقان',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          color: ItqanColors.emerald,
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'مساحات تجمعنا على الخير، والقراءة، والإنجاز.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: ItqanColors.inkSoft,
                          height: 1.6,
                        ),
                  ),
                  const SizedBox(height: 34),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: _busy ? null : _signIn,
                      icon: _busy
                          ? const SizedBox(
                              height: 18,
                              width: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.login_rounded),
                      label: Text(
                        _busy
                            ? 'جارٍ تسجيل الدخول…'
                            : 'تسجيل الدخول باستخدام Google',
                      ),
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'لن تُحفظ كلمة مرور Google داخل التطبيق.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: ItqanColors.muted,
                        ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
}
