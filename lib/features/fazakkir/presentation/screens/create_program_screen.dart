import 'package:flutter/material.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/theme/typography.dart';
import '../../application/fazakkir_notification_service.dart';
import '../../application/scheduling_engine.dart';
import '../../data/fazakkir_repository.dart';
import '../../data/templates/fazakkir_templates.dart';
import '../../domain/models/fazakkir_program.dart';
import '../../domain/models/recurrence_rule.dart';
import '../../domain/models/reminder_item.dart';
import '../../domain/models/reminder_type.dart';

/// رحلة إنشاء برنامج جديد في «فَذَكِّر» عبر ٤ محطات أساسية
class CreateProgramScreen extends StatefulWidget {
  const CreateProgramScreen({super.key});

  @override
  State<CreateProgramScreen> createState() => _CreateProgramScreenState();
}

class _CreateProgramScreenState extends State<CreateProgramScreen> {
  int _currentStation = 0; // 0 = الأنواع, 1 = الجدولة, 2 = المراجعة, 3 = التشغيل

  // بيانات البرنامج
  String _programName = 'برنامجي اليومي';
  String _programDesc = 'مسار أوراد وتذكير هادئ ومبارك';

  // المحطة الأولى: اختيار الأنواع
  final Set<ReminderTypeCategory> _selectedCategories = {
    ReminderTypeCategory.morningEvening,
    ReminderTypeCategory.istighfar,
  };

  // المحطة الثانية: التذكيرات وجدولتها
  final List<ReminderItem> _configuredReminders = [];
  final TimeOfDay _selectedMorningTime = const TimeOfDay(hour: 7, minute: 0);
  final TimeOfDay _selectedEveningTime = const TimeOfDay(hour: 17, minute: 30);

  // المحطة الرابعة: التشغيل
  bool _isActivating = false;
  String? _activationError;
  bool _isSuccess = false;

  @override
  void initState() {
    super.initState();
    _populateDefaultReminders();
  }

  void _populateDefaultReminders() {
    _configuredReminders.clear();
    final now = DateTime.now();

    for (final cat in _selectedCategories) {
      if (cat == ReminderTypeCategory.morningEvening) {
        _configuredReminders.add(
          ReminderItem(
            id: 'rem_${DateTime.now().microsecondsSinceEpoch}_1',
            category: cat,
            title: 'أذكار الصباح',
            text: 'أَصْبَحْنَا وَأَصْبَحَ الْمُلْكُ لِلَّهِ، وَالْحَمْدُ لِلَّهِ',
            reference: 'صحيح مسلم',
            recurrenceRule:
                const RecurrenceRule(frequency: RecurrenceFrequency.daily),
            targetTimes: [_selectedMorningTime],
            createdAt: now,
          ),
        );
        _configuredReminders.add(
          ReminderItem(
            id: 'rem_${DateTime.now().microsecondsSinceEpoch}_2',
            category: cat,
            title: 'أذكار المساء',
            text: 'أَمْسَيْنَا وَأَمْسَى الْمُلْكُ لِلَّهِ، وَالْحَمْدُ لِلَّهِ',
            reference: 'صحيح مسلم',
            recurrenceRule:
                const RecurrenceRule(frequency: RecurrenceFrequency.daily),
            targetTimes: [_selectedEveningTime],
            createdAt: now,
          ),
        );
      } else if (cat == ReminderTypeCategory.istighfar) {
        _configuredReminders.add(
          ReminderItem(
            id: 'rem_${DateTime.now().microsecondsSinceEpoch}_3',
            category: cat,
            title: 'سيد الاستغفار',
            text: 'اللَّهُمَّ أَنْتَ رَبِّي لَا إِلَهَ إِلَّا أَنْتَ، خَلَقْتَنِي وَأَنَا عَبْدُكَ',
            reference: 'صحيح البخاري',
            recurrenceRule:
                const RecurrenceRule(frequency: RecurrenceFrequency.daily),
            targetTimes: [const TimeOfDay(hour: 13, minute: 0)],
            createdAt: now,
          ),
        );
      } else if (cat == ReminderTypeCategory.salawat) {
        _configuredReminders.add(
          ReminderItem(
            id: 'rem_${DateTime.now().microsecondsSinceEpoch}_4',
            category: cat,
            title: 'الصلاة على النبي ﷺ',
            text: 'اللَّهُمَّ صَلِّ عَلَى مُحَمَّدٍ وَعَلَى آلِ مُحَمَّدٍ',
            reference: 'صحيح البخاري ومسلم',
            recurrenceRule:
                const RecurrenceRule(frequency: RecurrenceFrequency.daily),
            targetTimes: [const TimeOfDay(hour: 12, minute: 0)],
            createdAt: now,
          ),
        );
      } else {
        final info = ReminderTypeInfo.fromCategory(cat);
        _configuredReminders.add(
          ReminderItem(
            id: 'rem_${DateTime.now().microsecondsSinceEpoch}_${cat.index}',
            category: cat,
            title: info.title,
            text: 'سبحان الله وبحمده، سبحان الله العظيم',
            reference: 'مكتبة إتقان المعتمدة',
            recurrenceRule:
                const RecurrenceRule(frequency: RecurrenceFrequency.daily),
            targetTimes: [const TimeOfDay(hour: 15, minute: 0)],
            createdAt: now,
          ),
        );
      }
    }
  }

  /// تطبيق قالب جاهز بنقرة واحدة
  void _applyTemplate(PrebuiltTemplate template) {
    setState(() {
      _programName = template.program.name;
      _programDesc = template.program.description;
      _configuredReminders.clear();
      _configuredReminders.addAll(template.reminders);
      _selectedCategories.clear();
      for (final r in template.reminders) {
        _selectedCategories.add(r.category);
      }
      _currentStation = 2; // الانتقال مباشرة لمحطة المراجعة
    });
  }

  /// تشغيل البرنامج وتفعيله الفعلي
  Future<void> _activateProgram() async {
    setState(() {
      _isActivating = true;
      _activationError = null;
    });

    try {
      final notifService = FazakkirNotificationService.instance;
      final permissions = await notifService.checkAndRequestPermissions();

      final programId = 'prog_${DateTime.now().millisecondsSinceEpoch}';
      final reminderIds = _configuredReminders.map((r) => r.id).toList();

      final program = FazakkirProgram(
        id: programId,
        name: _programName.trim().isEmpty ? 'برنامجي الذاكر' : _programName,
        description: _programDesc,
        createdAt: DateTime.now(),
        reminderIds: reminderIds,
      );

      final repo = FazakkirRepository.instance;
      await repo.saveProgram(program);

      // حفظ التذكيرات وربطها بالبرنامج
      for (final rem in _configuredReminders) {
        final updated = rem.copyWith(programId: programId);
        await repo.saveReminder(updated);
      }

      // جدولة المواعيد فعلياً
      final scheduler = SchedulingEngine();
      await scheduler.rebuildSchedule();

      if (mounted) {
        setState(() {
          _isActivating = false;
          _isSuccess = true;
        });
      }

      if (!permissions.notificationsGranted && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'تم حفظ البرنامج بنجاح. يُرجى تفعيل إذن الإشعارات من إعدادات الهاتف لتصلك التذكيرات في موعدها.',
            ),
            duration: Duration(seconds: 4),
            backgroundColor: ItqanColors.warning,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isActivating = false;
          _activationError = 'تعذر تفعيل الجدولة: $e';
        });
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
          title: const Text('إنشاء برنامج جديد'),
          centerTitle: true,
          elevation: 0,
        ),
        body: Column(
          children: [
            // شريط تقدم المحطات الأربع
            _buildStationsProgressIndicator(),

            // محتوى المحطة الحالية
            Expanded(
              child: _buildStationContent(),
            ),

            // شريط الأزرار السفلي للتنقل
            _buildBottomNavButtons(),
          ],
        ),
      ),
    );
  }

  // ─── Stations Progress Indicator ──────────────────────────────────────────
  Widget _buildStationsProgressIndicator() {
    final stations = ['اختيار الأنواع', 'الجدولة', 'المراجعة', 'التشغيل'];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: ItqanColors.border),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: List.generate(stations.length, (index) {
          final isCurrent = _currentStation == index;
          final isDone = _currentStation > index;

          return Row(
            children: [
              CircleAvatar(
                radius: 13,
                backgroundColor: isCurrent
                    ? ItqanColors.emerald
                    : (isDone
                        ? ItqanColors.emeraldDark
                        : Colors.grey.shade300),
                child: isDone
                    ? const Icon(Icons.check, size: 14, color: Colors.white)
                    : Text(
                        '${index + 1}',
                        style: TextStyle(
                          fontSize: 12,
                          color: isCurrent ? Colors.white : Colors.black87,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
              const SizedBox(width: 6),
              Text(
                stations[index],
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                  color: isCurrent ? ItqanColors.emerald : Colors.grey.shade600,
                ),
              ),
              if (index < stations.length - 1)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Icon(Icons.arrow_left_rounded,
                      size: 16, color: Colors.grey.shade400),
                ),
            ],
          );
        }),
      ),
    );
  }

  // ─── Station Content Router ───────────────────────────────────────────────
  Widget _buildStationContent() {
    switch (_currentStation) {
      case 0:
        return _buildStation1Types();
      case 1:
        return _buildStation2Scheduling();
      case 2:
        return _buildStation3Review();
      case 3:
        return _buildStation4Activation();
      default:
        return const SizedBox();
    }
  }

  // ─── Station 1: اختيار الأنواع والقوالب ─────────────────────────────────────
  Widget _buildStation1Types() {
    final templates = FazakkirTemplates.getTemplates();

    return ListView(
      padding: const EdgeInsets.all(18),
      children: [
        // قسم القوالب الجاهزة السريعة
        const Text('أو ابدأ بقالب جاهز ومبارك',
            style: ItqanTypography.heading2),
        const SizedBox(height: 6),
        const Text(
          'سبعة قوالب معدّة ومحققة مسبقاً، يمكنك تعديلها بحرية قبل التفعيل:',
          style: ItqanTypography.caption,
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 105,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: templates.length,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (context, idx) {
              final t = templates[idx];
              return InkWell(
                onTap: () => _applyTemplate(t),
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  width: 140,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: ItqanColors.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFD4AF37)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        t.program.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          color: ItqanColors.emeraldDark,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${t.reminders.length} أوراد مقترحة',
                        style: ItqanTypography.caption.copyWith(fontSize: 11),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),

        const Divider(height: 32),

        const Text('اختر أنواع الأذكار والأوراد للبرنامج',
            style: ItqanTypography.heading2),
        const SizedBox(height: 6),
        const Text('يمكنك اختيار نوع أو أكثر لبناء جدولك الخاص:',
            style: ItqanTypography.caption),
        const SizedBox(height: 14),

        // بطاقات الأنواع
        ...ReminderTypeInfo.allTypes.map((typeInfo) {
          final isSelected = _selectedCategories.contains(typeInfo.category);

          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            decoration: BoxDecoration(
              color: isSelected
                  ? ItqanColors.emerald.withValues(alpha: 0.06)
                  : ItqanColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isSelected
                    ? ItqanColors.emerald
                    : ItqanColors.border,
                width: isSelected ? 1.5 : 1,
              ),
            ),
            child: CheckboxListTile(
              activeColor: ItqanColors.emerald,
              value: isSelected,
              secondary: CircleAvatar(
                backgroundColor: typeInfo.accentColor.withValues(alpha: 0.15),
                child: Icon(typeInfo.icon,
                    color: typeInfo.accentColor, size: 20),
              ),
              title: Text(
                typeInfo.title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              subtitle: Text(
                typeInfo.description,
                style: ItqanTypography.caption.copyWith(fontSize: 11),
              ),
              onChanged: (val) {
                setState(() {
                  if (val == true) {
                    _selectedCategories.add(typeInfo.category);
                  } else {
                    if (_selectedCategories.length > 1) {
                      _selectedCategories.remove(typeInfo.category);
                    }
                  }
                  _populateDefaultReminders();
                });
              },
            ),
          );
        }),
      ],
    );
  }

  // ─── Station 2: الجدولة ───────────────────────────────────────────────────
  Widget _buildStation2Scheduling() {
    return ListView(
      padding: const EdgeInsets.all(18),
      children: [
        const Text('متى يناسبك التذكير؟', style: ItqanTypography.heading2),
        const SizedBox(height: 4),
        const Text(
          'اضبط المواعيد المفضلة للأوراد، كل تذكير له وقته المستقل:',
          style: ItqanTypography.caption,
        ),
        const SizedBox(height: 18),

        // اسم البرنامج ووصفه
        TextField(
          controller: TextEditingController(text: _programName),
          decoration: InputDecoration(
            labelText: 'اسم البرنامج',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
          ),
          onChanged: (val) => _programName = val,
        ),
        const SizedBox(height: 16),

        // قائمة التذكيرات وضبط مواعيدها
        ...List.generate(_configuredReminders.length, (idx) {
          final rem = _configuredReminders[idx];
          final time = rem.targetTimes.isNotEmpty
              ? rem.targetTimes.first
              : const TimeOfDay(hour: 8, minute: 0);

          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: ItqanColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: ItqanColors.border),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        rem.title,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        rem.recurrenceRule.humanDescription,
                        style: ItqanTypography.caption,
                      ),
                    ],
                  ),
                ),
                InkWell(
                  onTap: () async {
                    final picked = await showTimePicker(
                      context: context,
                      initialTime: time,
                    );
                    if (picked != null) {
                      setState(() {
                        _configuredReminders[idx] =
                            rem.copyWith(targetTimes: [picked]);
                      });
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: ItqanColors.surfaceSoft,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: ItqanColors.border),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.access_time_rounded,
                            size: 16, color: ItqanColors.emerald),
                        const SizedBox(width: 6),
                        Text(
                          time.format(context),
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        }),

        const SizedBox(height: 8),

        // خيارات متقدمة مطوية
        ExpansionTile(
          title: const Text(
            'خيارات الجدولة المتقدمة',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
          ),
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                children: const [
                  Text(
                    'تعتمد الخدمة نافذة جدولة متدحرجة لمدة ٧٢ ساعة مع مراعاة ساعات الهدوء، وإعادة البناء التلقائي عند تبديل التوقيت أو إعادة تشغيل الهاتف.',
                    style: ItqanTypography.caption,
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ─── Station 3: المراجعة ──────────────────────────────────────────────────
  Widget _buildStation3Review() {
    return ListView(
      padding: const EdgeInsets.all(18),
      children: [
        const Text('مراجعة البرنامج قبل التفعيل',
            style: ItqanTypography.heading2),
        const SizedBox(height: 4),
        const Text(
          'تأكد من توزيع الأوراد والمواعيد لضمان عدم حدوث تعارضات:',
          style: ItqanTypography.caption,
        ),
        const SizedBox(height: 18),

        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: ItqanColors.emerald.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(18),
            border:
                Border.all(color: ItqanColors.emerald.withValues(alpha: 0.2)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _programName,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: ItqanColors.emeraldDark,
                ),
              ),
              const SizedBox(height: 4),
              Text(_programDesc, style: ItqanTypography.caption),
              const Divider(height: 20),
              Text('عدد الأوراد المجدولة: ${_configuredReminders.length}'),
            ],
          ),
        ),

        const SizedBox(height: 18),

        const Text('جدول المواعيد اليومية:',
            style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),

        ..._configuredReminders.map((r) {
          final t = r.targetTimes.isNotEmpty ? r.targetTimes.first : null;
          return ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.circle, size: 10, color: ItqanColors.emerald),
            title: Text(r.title, style: const TextStyle(fontSize: 14)),
            subtitle: Text('المصدر: ${r.reference}',
                style: const TextStyle(fontSize: 11)),
            trailing: t != null
                ? Text(t.format(context),
                    style: const TextStyle(fontWeight: FontWeight.bold))
                : null,
          );
        }),
      ],
    );
  }

  // ─── Station 4: التشغيل ───────────────────────────────────────────────────
  Widget _buildStation4Activation() {
    if (_isSuccess) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.verified_rounded,
                  color: ItqanColors.emerald, size: 72),
              const SizedBox(height: 16),
              const Text(
                'تم تفعيل البرنامج والجدولة بنجاح!',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'تمت جدولة إشعارات الأوراد محلياً على جهازك وفق الضوابط الهادئة وساعات الهدوء.',
                textAlign: TextAlign.center,
                style: ItqanTypography.caption,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: ItqanColors.emerald,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(200, 48),
                ),
                onPressed: () => Navigator.pop(context),
                child: const Text('العودة إلى مركز فَذَكِّر'),
              ),
            ],
          ),
        ),
      );
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.play_circle_fill_rounded,
                color: ItqanColors.emerald, size: 64),
            const SizedBox(height: 16),
            const Text(
              'جاهز للتشغيل والجدولة',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'سيتم التحقق من الصلاحيات وتثبيت الأوراد في النظام المحلي فور الضغط أدناه.',
              textAlign: TextAlign.center,
              style: ItqanTypography.caption,
            ),
            if (_activationError != null) ...[
              const SizedBox(height: 14),
              Text(
                _activationError!,
                style: const TextStyle(color: Colors.red, fontSize: 13),
              ),
            ],
            const SizedBox(height: 24),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: ItqanColors.emerald,
                foregroundColor: Colors.white,
                minimumSize: const Size(200, 48),
              ),
              onPressed: _isActivating ? null : _activateProgram,
              child: _isActivating
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('تفعيل البرنامج الآن'),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Bottom Navigation Buttons ────────────────────────────────────────────
  Widget _buildBottomNavButtons() {
    if (_isSuccess) return const SizedBox();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: const BoxDecoration(
        color: ItqanColors.surface,
        border: Border(top: BorderSide(color: ItqanColors.border)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          if (_currentStation > 0)
            TextButton(
              onPressed: () => setState(() => _currentStation--),
              child: const Text('السابق'),
            )
          else
            const SizedBox(width: 80),
          if (_currentStation < 3)
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: ItqanColors.emerald,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                setState(() => _currentStation++);
              },
              child: const Text('التالي'),
            )
          else
            const SizedBox(width: 80),
        ],
      ),
    );
  }
}
