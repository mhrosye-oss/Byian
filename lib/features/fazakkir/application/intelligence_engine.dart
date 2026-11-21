import '../data/fazakkir_repository.dart';
import '../domain/models/reminder_item.dart';
import '../domain/models/smart_suggestion.dart';
import 'scheduling_engine.dart';

/// طبقة الذكاء والتنظيم الهادئ لخدمة «فَذَكِّر» (يقترح ولا يفرض)
class IntelligenceEngine {
  final FazakkirRepository _repository;
  final SchedulingEngine _schedulingEngine;

  IntelligenceEngine({
    FazakkirRepository? repository,
    SchedulingEngine? schedulingEngine,
  })  : _repository = repository ?? FazakkirRepository.instance,
        _schedulingEngine = schedulingEngine ?? SchedulingEngine();

  /// فحص المواعيد وتوليد الاقتراحات الذكية دون تطبيقها
  Future<List<SmartSuggestion>> analyzeAndGenerateSuggestions() async {
    final now = DateTime.now();
    final reminders = await _repository.getReminders();
    final quietHours = await _repository.getQuietHours();
    final maxDensity = await _repository.getMaxDailyDensity();
    final existingSuggestions = await _repository.getSuggestions();

    final activeReminders = reminders.where((r) => r.isActive).toList();
    final newSuggestions = <SmartSuggestion>[];

    // تجميع كافة مواعيد اليوم القادمة
    final dayOccurrences = <({ReminderItem reminder, DateTime time})>[];
    for (final rem in activeReminders) {
      final occs = _schedulingEngine.calculateOccurrences(
        reminder: rem,
        from: now,
        window: const Duration(hours: 24),
      );
      for (final occ in occs) {
        dayOccurrences.add((reminder: rem, time: occ));
      }
    }
    dayOccurrences.sort((a, b) => a.time.compareTo(b.time));

    // 1. فحص التعارض الزمني والتزامن الضيق (أقل من 15 دقيقة بين تذكيرين)
    for (int i = 0; i < dayOccurrences.length - 1; i++) {
      final current = dayOccurrences[i];
      final next = dayOccurrences[i + 1];

      final diffMinutes = next.time.difference(current.time).inMinutes.abs();
      if (diffMinutes < 15 && current.reminder.id != next.reminder.id) {
        final suggestionId =
            'conflict_${current.reminder.id}_${next.reminder.id}';

        // تخطي إذا تم رفضه مؤخراً (خلال 3 أيام)
        final existing =
            existingSuggestions.where((s) => s.id == suggestionId).firstOrNull;
        if (existing?.dismissedUntil != null &&
            existing!.dismissedUntil!.isAfter(now)) {
          continue;
        }

        newSuggestions.add(
          SmartSuggestion(
            id: suggestionId,
            type: SuggestionType.timeConflict,
            question:
                'هل ترغب في مباعدة «${current.reminder.title}» و«${next.reminder.title}»؟',
            description:
                'يوجد تزامن متقارب بين التذكيرين بفارق $diffMinutes دقيقة فقط، ومباعدتهما تمنحك سكينة أكبر.',
            beforeState:
                '«${current.reminder.title}» (${_formatTime(current.time)}) ثم «${next.reminder.title}» (${_formatTime(next.time)})',
            afterState:
                'تأخير «${next.reminder.title}» بمقدار 20 دقيقة ليصبح موعده (${_formatTime(next.time.add(const Duration(minutes: 20)))})',
            relatedReminderId: current.reminder.id,
            secondaryReminderId: next.reminder.id,
          ),
        );
      }
    }

    // 2. فحص الكثافة اليومية (تجاوز الحد المقترح مثلاً 8 تذكيرات في اليوم)
    if (dayOccurrences.length > maxDensity) {
      const densityId = 'density_warning';
      final existing =
          existingSuggestions.where((s) => s.id == densityId).firstOrNull;
      if (existing?.dismissedUntil == null ||
          existing!.dismissedUntil!.isBefore(now)) {
        newSuggestions.add(
          SmartSuggestion(
            id: densityId,
            type: SuggestionType.densityWarning,
            question:
                'لديك ${dayOccurrences.length} تذكيرات اليوم، هل ترغب في تخفيف الكثافة؟',
            description:
                'الحد اليومي المقترح للسكينة هو $maxDensity إشعارات. كثرة التنبيهات قد تحول الذكر إلى عبء.',
            beforeState: '${dayOccurrences.length} تذكيرات مجدولة لليوم',
            afterState:
                'إيقاف مؤقت لأحد البرامج الأقل نشاطاً أو دمج بعض الأوراد',
          ),
        );
      }
    }

    // 3. فحص التداخل مع ساعات الهدوء
    for (final item in dayOccurrences) {
      if (quietHours.isInQuietHours(item.time)) {
        final quietId = 'quiet_overlap_${item.reminder.id}';
        final existing =
            existingSuggestions.where((s) => s.id == quietId).firstOrNull;
        if (existing?.dismissedUntil != null &&
            existing!.dismissedUntil!.isAfter(now)) {
          continue;
        }

        newSuggestions.add(
          SmartSuggestion(
            id: quietId,
            type: SuggestionType.quietHoursInterference,
            question:
                '«${item.reminder.title}» يقع ضمن ساعات الهدوء، هل ترغب بنقله؟',
            description:
                'موعد التذكير في (${_formatTime(item.time)}) يتزامن مع فترة راحتك المحددة.',
            beforeState: 'موعد الإشعار الحالي في ساعات الهدوء',
            afterState:
                'نقله إلى ما بعد نهاية ساعات الهدوء (${quietHours.endTime.hour}:${quietHours.endTime.minute.toString().padLeft(2, '0')})',
            relatedReminderId: item.reminder.id,
          ),
        );
      }
    }

    // حفظ وتحديث الاقتراحات
    await _repository.saveSuggestions(newSuggestions);
    return newSuggestions;
  }

  /// رفض الاقتراح لثلاثة أيام
  Future<void> dismissSuggestion(String suggestionId) async {
    final suggestions = await _repository.getSuggestions();
    final updated = suggestions.map((s) {
      if (s.id == suggestionId) {
        return SmartSuggestion(
          id: s.id,
          type: s.type,
          question: s.question,
          description: s.description,
          beforeState: s.beforeState,
          afterState: s.afterState,
          relatedReminderId: s.relatedReminderId,
          secondaryReminderId: s.secondaryReminderId,
          dismissedUntil: DateTime.now().add(const Duration(days: 3)),
        );
      }
      return s;
    }).toList();
    await _repository.saveSuggestions(updated);
  }

  /// قبول اقتراح المباعدة وتطبيقه فعلياً
  Future<void> applySeparationSuggestion(SmartSuggestion suggestion) async {
    if (suggestion.secondaryReminderId == null) return;
    final reminders = await _repository.getReminders();
    final target = reminders
        .where((r) => r.id == suggestion.secondaryReminderId)
        .firstOrNull;
    if (target != null && target.targetTimes.isNotEmpty) {
      final oldTime = target.targetTimes.first;
      final newTotalMinutes = oldTime.hour * 60 + oldTime.minute + 20;
      final newHour = (newTotalMinutes ~/ 60) % 24;
      final newMinute = newTotalMinutes % 60;

      final updatedTimes = List.of(target.targetTimes);
      updatedTimes[0] =
          target.targetTimes[0].replacing(hour: newHour, minute: newMinute);

      final updatedReminder = target.copyWith(targetTimes: updatedTimes);
      await _repository.saveReminder(updatedReminder);

      // إعادة بناء الجدول
      await _schedulingEngine.rebuildSchedule();
      // إزالة الاقتراح
      await dismissSuggestion(suggestion.id);
    }
  }

  static String _formatTime(DateTime time) {
    final h = time.hour > 12
        ? time.hour - 12
        : (time.hour == 0 ? 12 : time.hour);
    final m = time.minute.toString().padLeft(2, '0');
    final period = time.hour >= 12 ? 'م' : 'ص';
    return '$h:$m $period';
  }
}
