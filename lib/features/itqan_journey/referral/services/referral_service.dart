import 'dart:math';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:share_plus/share_plus.dart';
import '../../../../core/services/auth_service.dart';

/// خدمة إدارة وتوليد والتحقق من كود الإحالة الشخصي
/// تلتزم بدقة بضوابط إتقان: كود نصي فريد فقط، بدون روابط أو ديب لينكس
class ReferralService {
  static const _userReferralCodeKey = 'itqan_user_referral_code';
  static const _usedReferralCodeKey = 'itqan_used_referral_code';
  static const _referralCountKey = 'itqan_referral_success_count';

  /// الحصول على كود الإحالة الخاص بالمستخدم الحالي
  /// يتم توليده وتثبيته مرة واحدة إن لم يكن موجوداً
  static Future<String> getOrCreateMyReferralCode() async {
    final prefs = await SharedPreferences.getInstance();
    String? code = prefs.getString(_userReferralCodeKey);

    if (code != null && code.isNotEmpty) {
      return code;
    }

    // توليد كود مميز يعتمد على معرف المستخدم إن وُجد أو حروف وأرقام عشوائية واضحة
    final userId = await AuthService.getUserId();
    final random = Random();
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789'; // بدون حروف مشتبهة مثل O, 0, I, 1

    final suffix = List.generate(4, (_) => chars[random.nextInt(chars.length)]).join();
    if (userId != null && userId > 0) {
      code = 'ITQ-$userId$suffix';
    } else {
      final prefix = List.generate(2, (_) => chars[random.nextInt(chars.length)]).join();
      code = 'ITQ-$prefix$suffix';
    }

    await prefs.setString(_userReferralCodeKey, code);
    return code;
  }

  /// هل تم ربط المستخدم الحالي بكود إحالة سابقاً؟
  static Future<bool> hasAppliedReferralCode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey(_usedReferralCodeKey);
  }

  /// الكود الذي استخدمه المستخدم عند التسجيل
  static Future<String?> getAppliedReferralCode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_usedReferralCodeKey);
  }

  /// عدد الأشخاص الذين استخدموا كود المستخدم
  static Future<int> getReferralCount() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_referralCountKey) ?? 0;
  }

  /// التحقق من كود الإحالة وتطبيقه للمستخدم الجديد
  /// يمنع الإحالة الذاتية ويمنع التكرار
  static Future<ReferralApplyResult> applyReferralCode(String inputCode) async {
    final code = inputCode.trim().toUpperCase();
    if (code.isEmpty) {
      return ReferralApplyResult(
        success: false,
        message: 'يرجى إدخال كود الإحالة',
      );
    }

    // التحقق من الطول والتنسيق العام
    if (code.length < 4 || code.length > 15) {
      return ReferralApplyResult(
        success: false,
        message: 'صيغة كود الإحالة غير صالحة',
      );
    }

    // التحقق من منع الإحالة الذاتية
    final myCode = await getOrCreateMyReferralCode();
    if (code == myCode.toUpperCase()) {
      return ReferralApplyResult(
        success: false,
        message: 'لا يمكن استخدام كود الإحالة الخاص بك شخصياً',
      );
    }

    // التحقق من عدم الاستخدام المسبق
    if (await hasAppliedReferralCode()) {
      return ReferralApplyResult(
        success: false,
        message: 'تم تسجيل كود إحالة لهذا الحساب مسبقاً ولا يمكن تغييره',
      );
    }

    // حفظ الكود المعتمد محلياً
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_usedReferralCodeKey, code);

    return ReferralApplyResult(
      success: true,
      message: 'تم تفعيل كود الإحالة بنجاح وبدء الرحلة!',
      appliedCode: code,
    );
  }

  /// نسخ الكود الحقيقي إلى الحافظة
  static Future<void> copyCodeToClipboard(String code) async {
    await Clipboard.setData(ClipboardData(text: code));
  }

  /// مشاركة كود الإحالة عبر Android Sharesheet
  /// رسالة رسمية نقية بدون أي روابط وهمية
  static Future<void> shareReferralMessage(String code) async {
    final message =
        'انضم إلى رحلتنا مع إتقان، وابدأ رحلتك الإيمانية معنا.\nكود الدعوة الخاص بي: $code';
    await Share.share(message, subject: 'دعوة للانضمام إلى تطبيق إتقان');
  }
}

class ReferralApplyResult {
  final bool success;
  final String message;
  final String? appliedCode;

  ReferralApplyResult({
    required this.success,
    required this.message,
    this.appliedCode,
  });
}

