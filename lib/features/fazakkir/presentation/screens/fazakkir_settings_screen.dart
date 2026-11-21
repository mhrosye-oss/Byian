import 'package:flutter/material.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/theme/typography.dart';
import '../../application/scheduling_engine.dart';
import '../../data/fazakkir_repository.dart';
import '../../data/templates/fazakkir_templates.dart';

/// شاشة إعدادات خدمة «فَذَكِّر»
class FazakkirSettingsScreen extends StatefulWidget {
  const FazakkirSettingsScreen({super.key});

  @override
  State<FazakkirSettingsScreen> createState() =>
      _FazakkirSettingsScreenState();
}

class _FazakkirSettingsScreenState extends State<FazakkirSettingsScreen> {
  int _maxDensity = 8;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final density = await FazakkirRepository.instance.getMaxDailyDensity();
    if (mounted) {
      setState(() {
        _maxDensity = density;
        _isLoading = false;
      });
    }
  }

  Future<void> _updateDensity(int value) async {
    setState(() => _maxDensity = value);
    await FazakkirRepository.instance.setMaxDailyDensity(value);
  }

  Future<void> _restoreTemplates() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('استعادة القوالب الافتراضية'),
          content: const Text(
            'سيتم تثبيت القوالب السبعة المعتمدة من جديد دون حذف الأوراد المخصصة التي كتبتها بنفسك.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('إلغاء'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: ItqanColors.emerald,
                foregroundColor: Colors.white,
              ),
              onPressed: () => Navigator.pop(context, true),
              child: const Text('استعادة القوالب'),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      final templates = FazakkirTemplates.getTemplates();
      final repo = FazakkirRepository.instance;
      for (final t in templates) {
        await repo.saveProgram(t.program);
        for (final rem in t.reminders) {
          await repo.saveReminder(rem);
        }
      }
      await SchedulingEngine().rebuildSchedule();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تمت استعادة القوالب السبعة المعتمدة بنجاح'),
            backgroundColor: ItqanColors.emeraldDark,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: AppBar(
          title: const Text('إعدادات فَذَكِّر'),
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
                  const Text('كثافة الإشعارات اليومية',
                      style: ItqanTypography.heading2),
                  const SizedBox(height: 6),
                  const Text(
                    'الحد اليومي المقترح لإشعارات الأوراد، للحفاظ على روح السكينة ومنع التشتت:',
                    style: ItqanTypography.caption,
                  ),
                  const SizedBox(height: 14),

                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: ItqanColors.surface,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: ItqanColors.border),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'الحد الأقصى للإشعارات اليومية',
                              style: TextStyle(
                                  fontSize: 14, fontWeight: FontWeight.bold),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: ItqanColors.emerald.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                '$_maxDensity إشعارات',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: ItqanColors.emerald,
                                ),
                              ),
                            ),
                          ],
                        ),
                        Slider(
                          value: _maxDensity.toDouble(),
                          min: 3,
                          max: 18,
                          divisions: 15,
                          activeColor: ItqanColors.emerald,
                          onChanged: (val) => _updateDensity(val.round()),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  const Text('إدارة المحتوى والقوالب',
                      style: ItqanTypography.heading2),
                  const SizedBox(height: 12),

                  Container(
                    decoration: BoxDecoration(
                      color: ItqanColors.surface,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: ItqanColors.border),
                    ),
                    child: ListTile(
                      leading: const Icon(Icons.restore_page_rounded,
                          color: ItqanColors.emerald),
                      title: const Text('استعادة القوالب السبعة المعتمدة'),
                      subtitle: const Text(
                        'إعادة إضافة قوالب إتقان الأصلية إذا حذفتها',
                        style: TextStyle(fontSize: 12),
                      ),
                      onTap: _restoreTemplates,
                    ),
                  ),

                  const SizedBox(height: 12),

                  Container(
                    decoration: BoxDecoration(
                      color: ItqanColors.surface,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: ItqanColors.border),
                    ),
                    child: ListTile(
                      leading: const Icon(Icons.sync_rounded,
                          color: ItqanColors.emerald),
                      title: const Text('إعادة جدولة الأوراد الآن'),
                      subtitle: const Text(
                        'تحديث مواعيد الإشعارات المحلية للأيام الثلاثة القادمة',
                        style: TextStyle(fontSize: 12),
                      ),
                      onTap: () async {
                        await SchedulingEngine().rebuildSchedule();
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('تم تحديث الجدولة بنجاح'),
                              backgroundColor: ItqanColors.emeraldDark,
                            ),
                          );
                        }
                      },
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
