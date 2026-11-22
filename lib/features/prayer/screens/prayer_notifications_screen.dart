import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../core/theme/colors.dart';
import '../services/prayer_notification_service.dart';
import '../services/prayer_times_service.dart';

/// Settings for the actual scheduled prayer notifications.
class PrayerNotificationsScreen extends StatefulWidget {
  const PrayerNotificationsScreen({super.key});

  @override
  State<PrayerNotificationsScreen> createState() =>
      _PrayerNotificationsScreenState();
}

class _PrayerNotificationsScreenState extends State<PrayerNotificationsScreen> {
  bool? _enabled;
  bool _busy = false;
  String? _message;

  @override
  void initState() {
    super.initState();
    _readStatus();
  }

  Future<void> _readStatus() async {
    try {
      final enabled = await PrayerTimesService.prayerNotificationsEnabled();
      if (mounted) setState(() => _enabled = enabled);
    } catch (_) {
      if (mounted) {
        setState(() {
          _enabled = false;
          _message = 'تعذر قراءة إعدادات التنبيهات.';
        });
      }
    }
  }

  Future<void> _setEnabled(bool enabled) async {
    setState(() {
      _busy = true;
      _message = null;
    });
    try {
      if (enabled) {
        await PrayerTimesService.scheduleUpcomingNotifications();
      } else {
        await PrayerTimesService.disablePrayerNotifications();
      }
      if (mounted) {
        setState(() {
          _enabled = enabled;
          _message = enabled ? 'تم إعداد التنبيهات.' : 'تم إيقاف التنبيهات.';
        });
      }
    } catch (error) {
      bool? actualStatus;
      try {
        actualStatus = await PrayerTimesService.prayerNotificationsEnabled();
      } catch (_) {
        actualStatus = null;
      }
      if (mounted) {
        setState(() {
          _enabled = actualStatus;
          _message =
              'تعذّر إعداد التنبيهات: ${error.toString().replaceFirst('Bad state: ', '')}';
        });
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _sendTestNotification() async {
    setState(() {
      _busy = true;
      _message = null;
    });
    try {
      final allowed = await PrayerNotificationService.instance
          .requestReminderPermissions();
      if (!allowed) {
        throw StateError('اسمح بإشعارات التطبيق من إعدادات النظام أولاً.');
      }
      await PrayerNotificationService.instance.showTestAdhanNotification();
      if (mounted) {
        setState(() => _message = 'تم إرسال إشعار اختبار الأذان الآن.');
      }
    } catch (error) {
      if (mounted) {
        setState(() => _message =
            'تعذر إرسال اختبار الأذان: ${error.toString().replaceFirst('Bad state: ', '')}');
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final android = !kIsWeb && defaultTargetPlatform == TargetPlatform.android;
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: ItqanColors.cream,
        appBar: AppBar(title: const Text('إشعارات مواقيت الصلاة')),
        body: ListView(
          padding: const EdgeInsets.all(18),
          children: [
            SwitchListTile.adaptive(
              title: const Text('تنبيهات الصلاة'),
              subtitle: const Text(
                  'تذكير قبل الصلاة بـ15 دقيقة وإشعار عند دخول الوقت'),
              value: _enabled ?? false,
              onChanged: _busy || _enabled == null ? null : _setEnabled,
            ),
            if (_busy) const LinearProgressIndicator(),
            if (_message != null)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text(_message!),
              ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: _busy ? null : _sendTestNotification,
              icon: const Icon(Icons.notifications_active_outlined),
              label: const Text('اختبار إشعار الأذان الآن'),
            ),
            const SizedBox(height: 12),
            const Text(
                'صوت الإشعار مقتطف أذان مدته 27 ثانية، وليس الأذان كاملًا. يعتمد الصوت على إعدادات القناة ومستوى الصوت ووضع الجهاز.'),
            const SizedBox(height: 12),
            Text(android
                ? 'تُجدول التنبيهات مسبقًا لستة أيام ويُحاول Android تجديدها دوريًا من آخر موقع محفوظ. قد يتأخر التجديد أو التنبيه بسبب قيود النظام أو الأذونات؛ أعد تحديث الموقع عند السفر.'
                : 'تُجدول التنبيهات لستة أيام فقط؛ افتح التطبيق وأعد تفعيلها لتجديدها.'),
            const SizedBox(height: 12),
            const Text(
                'لا تتوفر بعد خيارات مستقلة لكل صلاة أو للتذكير المسبق.'),
          ],
        ),
      ),
    );
  }
}
