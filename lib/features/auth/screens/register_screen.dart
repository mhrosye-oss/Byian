import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../../core/services/fcm_service.dart';
import '../../../core/services/google_auth_service.dart';
import '../../itqan_journey/data/journey_auth_api.dart';
import '../../itqan_journey/referral/services/referral_service.dart';
import '../../home/home_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _password = TextEditingController();
  final _referralCode = TextEditingController();
  bool _busy = false;
  late final JourneyAuthApi _api = JourneyAuthApi(client: http.Client());

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _phone.dispose();
    _password.dispose();
    _referralCode.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    final name = _name.text.trim();
    final email = _email.text.trim();
    final password = _password.text;
    final phone = _phone.text.trim();
    final referral = _referralCode.text.trim();

    if (name.isEmpty || email.isEmpty || password.length < 8) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('يرجى إكمال البيانات، وكلمة المرور 8 أحرف على الأقل.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    // إذا أدخل المستخدم كود إحالة، نتحقق منه قبل المتابعة
    if (referral.isNotEmpty) {
      final validation = await ReferralService.applyReferralCode(referral);
      if (!validation.success) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(validation.message),
            backgroundColor: Colors.red.shade700,
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }
    }

    setState(() => _busy = true);
    try {
      await _api.register(
        name: name,
        email: email,
        password: password,
        phone: phone.isEmpty ? null : phone,
      );

      await _registerPushNotifications();
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute<void>(builder: (_) => const HomeScreen()),
          (_) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$e'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _registerWithGoogle() async {
    final referral = _referralCode.text.trim();
    if (referral.isNotEmpty) {
      final validation = await ReferralService.applyReferralCode(referral);
      if (!validation.success) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(validation.message),
            backgroundColor: Colors.red.shade700,
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }
    }

    setState(() => _busy = true);
    try {
      final result = await GoogleAuthService.signIn(
          referralCode: referral.isEmpty ? null : referral);
      if (!mounted) return;
      if (result.isCancelled) return;
      if (!result.success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.message ?? 'فشل التسجيل بواسطة Google'),
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }

      if (result.firebaseIdToken == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تعذر الحصول على رمز Google للمصادقة.')),
        );
        return;
      }
      await _api.firebaseLogin(idToken: result.firebaseIdToken!);
      await _registerPushNotifications();
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute<void>(builder: (_) => const HomeScreen()),
        (_) => false,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('حدث خطأ: $e'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _registerPushNotifications() async {
    try {
      final registered = await FcmService.registerCurrentDevice();
      if (!registered && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'لم تُفعّل إشعارات إتقان. تحقق من إذن الإشعارات في إعدادات الجهاز.'),
          ),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('تعذر تفعيل الإشعارات: $error')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F6F0),
      appBar: AppBar(
        title: const Text(
          'إنشاء حساب',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          children: [
            const Text(
              'انضم إلى رحلتنا الإيمانية',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: Color(0xFF0A5C36),
              ),
              textAlign: TextAlign.center,
              textDirection: TextDirection.rtl,
            ),
            const SizedBox(height: 6),
            const Text(
              'أتقن تلاوتك، حافظ على أذكارك، وشارك الأجر مع أصحابك',
              style: TextStyle(fontSize: 13, color: Color(0xFF5F685F)),
              textAlign: TextAlign.center,
              textDirection: TextDirection.rtl,
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _name,
              textDirection: TextDirection.rtl,
              decoration: InputDecoration(
                labelText: 'الاسم الكامل',
                prefixIcon: const Icon(Icons.person_outline_rounded),
                filled: true,
                fillColor: Colors.white,
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                labelText: 'البريد الإلكتروني',
                prefixIcon: const Icon(Icons.email_outlined),
                filled: true,
                fillColor: Colors.white,
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _phone,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                labelText: 'رقم الهاتف (اختياري)',
                prefixIcon: const Icon(Icons.phone_outlined),
                filled: true,
                fillColor: Colors.white,
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _password,
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'كلمة المرور (8 أحرف على الأقل)',
                prefixIcon: const Icon(Icons.lock_outline_rounded),
                filled: true,
                fillColor: Colors.white,
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
            const SizedBox(height: 14),
            // حقل كود الإحالة الاختياري
            TextField(
              controller: _referralCode,
              textCapitalization: TextCapitalization.characters,
              decoration: InputDecoration(
                labelText: 'كود الإحالة / الدعوة (اختياري)',
                hintText: 'مثال: ITQ-7X9K',
                prefixIcon: const Icon(Icons.card_giftcard_rounded,
                    color: Color(0xFFD4AF37)),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: Color(0xFFD4AF37)),
                ),
              ),
            ),
            const SizedBox(height: 26),
            FilledButton(
              onPressed: _busy ? null : _register,
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF0A5C36),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              child: _busy
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2),
                    )
                  : const Text(
                      'إنشاء الحساب وبدء الرحلة',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                    ),
            ),
            const SizedBox(height: 18),
            Row(
              children: const [
                Expanded(child: Divider()),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    'أو',
                    style: TextStyle(
                        color: Colors.grey, fontWeight: FontWeight.bold),
                  ),
                ),
                Expanded(child: Divider()),
              ],
            ),
            const SizedBox(height: 18),
            OutlinedButton.icon(
              onPressed: _busy ? null : _registerWithGoogle,
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                backgroundColor: Colors.white,
                side: BorderSide(color: Colors.grey.shade300),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              icon: Image.network(
                'https://www.gstatic.com/images/branding/product/2x/googleg_48dp.png',
                width: 22,
                height: 22,
                errorBuilder: (_, __, ___) => const Icon(Icons.g_mobiledata,
                    size: 28, color: Colors.blue),
              ),
              label: const Text(
                'التسجيل والمتابعة بواسطة Google',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF2C3E50),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
