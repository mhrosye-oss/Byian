import 'package:flutter/material.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/theme/typography.dart';
import '../../application/scheduling_engine.dart';
import '../../data/fazakkir_repository.dart';
import '../../domain/models/quiet_hours.dart';

/// شاشة إعداد ساعات الهدوء في «فَذَكِّر»
class QuietHoursScreen extends StatefulWidget {
  const QuietHoursScreen({super.key});

  @override
  State<QuietHoursScreen> createState() => _QuietHoursScreenState();
}

class _QuietHoursScreenState extends State<QuietHoursScreen> {
  late QuietHoursSettings _settings;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final s = await FazakkirRepository.instance.getQuietHours();
    if (mounted) {
      setState(() {
        _settings = s;
        _isLoading = false;
      });
    }
  }

  Future<void> _saveSettings(QuietHoursSettings newSettings) async {
    setState(() => _settings = newSettings);
    await FazakkirRepository.instance.saveQuietHours(newSettings);
    await SchedulingEngine().rebuildSchedule();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: AppBar(
          title: const Text('ساعات الهدوء'),
          centerTitle: true,
          elevation: 0,
        ),
        body: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: ItqanColors.emerald),
              )
            : ListView(
                padding: const EdgeInsets.all(18),
                children: [
                  // بطاقة التفعيل العامة
                  Container(
                    decoration: BoxDecoration(
                      color: ItqanColors.surface,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: ItqanColors.border),
                    ),
                    child: SwitchListTile(
                      activeThumbColor: ItqanColors.emerald,
                      secondary: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: ItqanColors.emerald.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.nightlight_round,
                            color: ItqanColors.emerald),
                      ),
                      title: const Text(
                        'تفعيل ساعات الهدوء',
                        style: TextStyle(
                            fontSize: 15, fontWeight: FontWeight.bold),
                      ),
                      subtitle: const Text(
                        'كتم الإشعارات خلال فترات النوم أو الراحة',
                        style: TextStyle(fontSize: 12),
                      ),
                      value: _settings.isEnabled,
                      onChanged: (val) {
                        _saveSettings(_settings.copyWith(isEnabled: val));
                      },
                    ),
                  ),

                  const SizedBox(height: 20),

                  // تحديد البداية والنهاية
                  Row(
                    children: [
                      Expanded(
                        child: _buildTimePickerCard(
                          title: 'بداية الهدوء',
                          time: _settings.startTime,
                          onPick: (picked) {
                            _saveSettings(_settings.copyWith(startTime: picked));
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildTimePickerCard(
                          title: 'نهاية الهدوء',
                          time: _settings.endTime,
                          onPick: (picked) {
                            _saveSettings(_settings.copyWith(endTime: picked));
                          },
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // الإجراء عند تداخل تذكير مع ساعات الهدوء
                  const Text('عند تداخل تذكير مع ساعات الهدوء:',
                      style: ItqanTypography.heading2),
                  const SizedBox(height: 10),

                  Container(
                    decoration: BoxDecoration(
                      color: ItqanColors.surface,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: ItqanColors.border),
                    ),
                    child: RadioGroup<QuietHoursAction>(
                      groupValue: _settings.action,
                      onChanged: (val) {
                        if (val != null) {
                          _saveSettings(_settings.copyWith(action: val));
                        }
                      },
                      child: Column(
                        children: [
                          RadioListTile<QuietHoursAction>(
                            activeColor: ItqanColors.emerald,
                            title: const Text('تأجيله لما بعد انتهاء الهدوء'),
                            subtitle: const Text(
                              'يُعرض الإشعار بهدوء بعد استيقاظك أو نهاية فترة الهدوء مباشرة',
                              style: TextStyle(fontSize: 11),
                            ),
                            value: QuietHoursAction.postponeAfterQuiet,
                          ),
                          const Divider(height: 1),
                          RadioListTile<QuietHoursAction>(
                            activeColor: ItqanColors.emerald,
                            title: const Text('تخطي الإشعار في صمت'),
                            subtitle: const Text(
                              'تسجيله في السجل كـ "ضمن الهدوء" دون إرسال إشعار',
                              style: TextStyle(fontSize: 11),
                            ),
                            value: QuietHoursAction.skip,
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // أثر ساعات الهدوء التوضيحي
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF9F6EE),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE5D7B7)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.info_outline_rounded,
                            size: 20, color: Color(0xFF9A6A12)),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'فترة الهدوء الحالية تمتد من ${_settings.startTime.format(context)} حتى ${_settings.endTime.format(context)}، ويتم التعامل مع الأوراد باحترام تام لسكينتك.',
                            style: const TextStyle(
                              fontSize: 12,
                              height: 1.5,
                              color: Color(0xFF6B4804),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildTimePickerCard({
    required String title,
    required TimeOfDay time,
    required ValueChanged<TimeOfDay> onPick,
  }) {
    return Material(
      color: ItqanColors.surface,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () async {
          final picked = await showTimePicker(
            context: context,
            initialTime: time,
          );
          if (picked != null) onPick(picked);
        },
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: ItqanColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: ItqanTypography.caption),
              const SizedBox(height: 6),
              Row(
                children: [
                  const Icon(Icons.access_time_rounded,
                      size: 18, color: ItqanColors.emerald),
                  const SizedBox(width: 8),
                  Text(
                    time.format(context),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: ItqanColors.ink,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
