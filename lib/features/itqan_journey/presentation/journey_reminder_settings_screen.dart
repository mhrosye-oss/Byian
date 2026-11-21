import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../prayer/services/prayer_notification_service.dart';

class JourneyReminderSettingsScreen extends StatefulWidget {
  const JourneyReminderSettingsScreen({super.key});

  @override
  State<JourneyReminderSettingsScreen> createState() =>
      _JourneyReminderSettingsScreenState();
}

class _JourneyReminderSettingsScreenState
    extends State<JourneyReminderSettingsScreen> {
  static const _reminders = <_ReminderDefinition>[
    _ReminderDefinition(
      key: 'quran',
      id: 910001,
      title: 'ورد القرآن',
      body: 'حان وقت وردك من القرآن الكريم.',
      defaultTime: '20:00',
      icon: Icons.menu_book_outlined,
    ),
    _ReminderDefinition(
      key: 'adhkar',
      id: 910002,
      title: 'الأذكار',
      body: 'خصص وقتاً لأذكارك اليومية.',
      defaultTime: '08:00',
      icon: Icons.spa_outlined,
    ),
    _ReminderDefinition(
      key: 'dua',
      id: 910003,
      title: 'الأدعية',
      body: 'تذكّر قراءة دعاء اليوم.',
      defaultTime: '19:00',
      icon: Icons.volunteer_activism_outlined,
    ),
    _ReminderDefinition(
      key: 'tasks',
      id: 910004,
      title: 'مهام الرحلة',
      body: 'تحقق من مهام رحلتك غير المكتملة.',
      defaultTime: '18:00',
      icon: Icons.checklist_rounded,
    ),
  ];

  final Map<String, bool> _enabled = {};
  final Map<String, String> _times = {};
  final Set<String> _busy = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final raw = Hive.box('settings').get('journey_reminders');
    final saved = raw is Map ? Map<String, dynamic>.from(raw) : const {};
    for (final reminder in _reminders) {
      _enabled[reminder.key] = saved['${reminder.key}_enabled'] == true;
      _times[reminder.key] = _validTime(
        saved['${reminder.key}_time']?.toString(),
        reminder.defaultTime,
      );
    }
    if (mounted) setState(() => _loading = false);

    for (final reminder in _reminders.where((item) => _enabled[item.key]!)) {
      try {
        await _schedule(reminder);
      } catch (_) {
        // Keep the saved choice; the user can revisit the setting to retry.
      }
    }
  }

  String _validTime(String? value, String fallback) {
    if (value == null || !RegExp(r'^\d{2}:\d{2}$').hasMatch(value)) {
      return fallback;
    }
    final parts = value.split(':').map(int.tryParse).toList();
    if (parts[0] == null ||
        parts[1] == null ||
        parts[0]! > 23 ||
        parts[1]! > 59) {
      return fallback;
    }
    return value;
  }

  TimeOfDay _timeOf(String key) {
    final parts = (_times[key] ?? '20:00').split(':').map(int.parse).toList();
    return TimeOfDay(hour: parts[0], minute: parts[1]);
  }

  Future<void> _persist() async {
    await Hive.box('settings').put('journey_reminders', {
      for (final reminder in _reminders) ...{
        '${reminder.key}_enabled': _enabled[reminder.key] ?? false,
        '${reminder.key}_time': _times[reminder.key] ?? reminder.defaultTime,
      },
    });
  }

  Future<void> _schedule(_ReminderDefinition reminder) async {
    final time = _timeOf(reminder.key);
    await PrayerNotificationService.instance.scheduleJourneyReminder(
      id: reminder.id,
      title: reminder.title,
      body: reminder.body,
      hour: time.hour,
      minute: time.minute,
    );
  }

  Future<void> _toggle(_ReminderDefinition reminder, bool enabled) async {
    if (_busy.contains(reminder.key)) return;
    setState(() => _busy.add(reminder.key));
    try {
      if (enabled) {
        final permission = await PrayerNotificationService.instance
            .requestReminderPermissions();
        if (!permission) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                  content: Text('يلزم السماح بالإشعارات لتفعيل التذكير.')),
            );
          }
          return;
        }
        await _schedule(reminder);
        _enabled[reminder.key] = true;
      } else {
        await PrayerNotificationService.instance
            .cancelJourneyReminder(reminder.id);
        _enabled[reminder.key] = false;
      }
      await _persist();
      if (mounted) setState(() {});
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('تعذر تحديث التذكير المحلي: $error')),
        );
      }
    } finally {
      if (mounted) setState(() => _busy.remove(reminder.key));
    }
  }

  Future<void> _chooseTime(_ReminderDefinition reminder) async {
    final selected = await showTimePicker(
      context: context,
      initialTime: _timeOf(reminder.key),
      helpText: 'وقت تذكير ${reminder.title}',
    );
    if (selected == null || !mounted) return;
    final value =
        '${selected.hour.toString().padLeft(2, '0')}:${selected.minute.toString().padLeft(2, '0')}';
    setState(() => _times[reminder.key] = value);
    try {
      if (_enabled[reminder.key] == true) await _schedule(reminder);
      await _persist();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('تعذر حفظ وقت التذكير: $error')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('تذكيرات الرحلة')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const Text(
                  'تذكيرات محلية اختيارية على هذا الجهاز؛ لا تعتمد على API ولا تسجل نشاطاً أو مكافأة.',
                  textDirection: TextDirection.rtl,
                ),
                const SizedBox(height: 12),
                for (final reminder in _reminders)
                  Card(
                    child: ListTile(
                      leading: Icon(reminder.icon),
                      title: Text(reminder.title),
                      subtitle: Text(
                          'الوقت: ${_times[reminder.key] ?? reminder.defaultTime}'),
                      onTap: () => _chooseTime(reminder),
                      trailing: Switch(
                        value: _enabled[reminder.key] ?? false,
                        onChanged: _busy.contains(reminder.key)
                            ? null
                            : (value) => _toggle(reminder, value),
                      ),
                    ),
                  ),
                const SizedBox(height: 8),
                Text(
                  'اضغط على وقت التذكير لتغييره. تذكير المهام يطلب منك مراجعة المهام غير المكتملة عند فتح الرحلة.',
                  textDirection: TextDirection.rtl,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
    );
  }
}

class _ReminderDefinition {
  const _ReminderDefinition({
    required this.key,
    required this.id,
    required this.title,
    required this.body,
    required this.defaultTime,
    required this.icon,
  });

  final String key;
  final int id;
  final String title;
  final String body;
  final String defaultTime;
  final IconData icon;
}
