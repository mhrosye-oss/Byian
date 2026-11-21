import 'package:flutter/material.dart';
import '../../domain/models/fazakkir_program.dart';
import '../../domain/models/recurrence_rule.dart';
import '../../domain/models/reminder_item.dart';
import '../../domain/models/reminder_type.dart';

class PrebuiltTemplate {
  final FazakkirProgram program;
  final List<ReminderItem> reminders;

  const PrebuiltTemplate({
    required this.program,
    required this.reminders,
  });
}

/// القوالب السبعة الجاهزة المعتمدة في خدمة «فَذَكِّر»
class FazakkirTemplates {
  FazakkirTemplates._();

  static List<PrebuiltTemplate> getTemplates() {
    final now = DateTime.now();

    // 1. يومٌ ذاكر
    const program1Id = 'template_program_yawm_thakir';
    final program1 = FazakkirProgram(
      id: program1Id,
      name: 'يومٌ ذاكر',
      description: 'مسار يومي هادئ يجمع بين أذكار الصباح وذكر النهار وأذكار المساء',
      iconName: 'wb_sunny_rounded',
      createdAt: now,
      reminderIds: ['rem_yawm_1', 'rem_yawm_2', 'rem_yawm_3'],
    );
    final reminders1 = [
      ReminderItem(
        id: 'rem_yawm_1',
        programId: program1Id,
        category: ReminderTypeCategory.morningEvening,
        title: 'أذكار الصباح',
        text: 'أَصْبَحْنَا وَأَصْبَحَ الْمُلْكُ لِلَّهِ، وَالْحَمْدُ لِلَّهِ، لَا إِلَهَ إِلَّا اللَّهُ وَحْدَهُ لَا شَرِيكَ لَهُ',
        fullText: 'أَصْبَحْنَا وَأَصْبَحَ الْمُلْكُ لِلَّهِ، وَالْحَمْدُ لِلَّهِ، لَا إِلَهَ إِلَّا اللَّهُ وَحْدَهُ لَا شَرِيكَ لَهُ، لَهُ الْمُلْكُ وَلَهُ الْحَمْدُ وَهُوَ عَلَى كُلِّ شَيْءٍ قَدِيرٌ',
        reference: 'صحيح مسلم',
        recurrenceRule: const RecurrenceRule(frequency: RecurrenceFrequency.daily),
        targetTimes: const [TimeOfDay(hour: 7, minute: 0)],
        createdAt: now,
      ),
      ReminderItem(
        id: 'rem_yawm_2',
        programId: program1Id,
        category: ReminderTypeCategory.tasbihTahmid,
        title: 'باقيات النهار',
        text: 'سُبْحَانَ اللَّهِ، وَالْحَمْدُ لِلَّهِ، وَلَا إِلَهَ إِلَّا اللَّهُ، وَاللَّهُ أَكْبَرُ',
        reference: 'صحيح مسلم',
        recurrenceRule: const RecurrenceRule(frequency: RecurrenceFrequency.daily),
        targetTimes: const [TimeOfDay(hour: 13, minute: 30)],
        createdAt: now,
      ),
      ReminderItem(
        id: 'rem_yawm_3',
        programId: program1Id,
        category: ReminderTypeCategory.morningEvening,
        title: 'أذكار المساء',
        text: 'أَمْسَيْنَا وَأَمْسَى الْمُلْكُ لِلَّهِ، وَالْحَمْدُ لِلَّهِ',
        reference: 'صحيح مسلم',
        recurrenceRule: const RecurrenceRule(frequency: RecurrenceFrequency.daily),
        targetTimes: const [TimeOfDay(hour: 17, minute: 0)],
        createdAt: now,
      ),
    ];

    // 2. سِلْمُ المغفرة
    const program2Id = 'template_program_silm_maghfirah';
    final program2 = FazakkirProgram(
      id: program2Id,
      name: 'سِلْمُ المغفرة',
      description: 'ورد الاستغفار والتوبة وتفريج الهموم بسيد الاستغفار',
      iconName: 'water_drop_rounded',
      createdAt: now,
      reminderIds: ['rem_silm_1', 'rem_silm_2'],
    );
    final reminders2 = [
      ReminderItem(
        id: 'rem_silm_1',
        programId: program2Id,
        category: ReminderTypeCategory.istighfar,
        title: 'سيد الاستغفار',
        text: 'اللَّهُمَّ أَنْتَ رَبِّي لَا إِلَهَ إِلَّا أَنْتَ، خَلَقْتَنِي وَأَنَا عَبْدُكَ، وَأَنَا عَلَى عَهْدِكَ وَوَعْدِكَ مَا اسْتَطَعْتُ',
        fullText: 'اللَّهُمَّ أَنْتَ رَبِّي لَا إِلَهَ إِلَّا أَنْتَ، خَلَقْتَنِي وَأَنَا عَبْدُكَ، وَأَنَا عَلَى عَهْدِكَ وَوَعْدِكَ مَا اسْتَطَعْتُ، أَعُوذُ بِكَ مِنْ شَرِّ مَا صَنَعْتُ، أَبُوءُ لَكَ بِنِعْمَتِكَ عَلَيَّ، وَأَبُوءُ بِذَنْبِي فَاغْفِرْ لِي فَإِنَّهُ لَا يَغْفِرُ الذُّنُوبَ إِلَّا أَنْتَ',
        reference: 'صحيح البخاري',
        recurrenceRule: const RecurrenceRule(frequency: RecurrenceFrequency.daily),
        targetTimes: const [TimeOfDay(hour: 7, minute: 30)],
        createdAt: now,
      ),
      ReminderItem(
        id: 'rem_silm_2',
        programId: program2Id,
        category: ReminderTypeCategory.istighfar,
        title: 'ورد الاستغفار',
        text: 'أَسْتَغْفِرُ اللَّهَ الَّذِي لَا إِلَهَ إِلَّا هُوَ الْحَيَّ الْقَيُّومَ وَأَتُوبُ إِلَيْهِ',
        reference: 'سنن أبي داود والترمذي',
        recurrenceRule: const RecurrenceRule(frequency: RecurrenceFrequency.daily),
        targetTimes: const [TimeOfDay(hour: 21, minute: 0)],
        createdAt: now,
      ),
    ];

    // 3. الصلاة على النبي ﷺ
    const program3Id = 'template_program_salawat';
    final program3 = FazakkirProgram(
      id: program3Id,
      name: 'الصلاة على النبي ﷺ',
      description: 'نيل شفاعة النبي ﷺ ومضاعفة الصلاة والسلام عليه',
      iconName: 'favorite_rounded',
      createdAt: now,
      reminderIds: ['rem_salawat_1', 'rem_salawat_2'],
    );
    final reminders3 = [
      ReminderItem(
        id: 'rem_salawat_1',
        programId: program3Id,
        category: ReminderTypeCategory.salawat,
        title: 'الصلاة الإبراهيمية',
        text: 'اللَّهُمَّ صَلِّ عَلَى مُحَمَّدٍ وَعَلَى آلِ مُحَمَّدٍ، كَمَا صَلَّيْتَ عَلَى إِبْرَاهِيمَ وَعَلَى آلِ إِبْرَاهِيمَ، إِنَّكَ حَمِيدٌ مَجِيدٌ',
        reference: 'صحيح البخاري ومسلم',
        recurrenceRule: const RecurrenceRule(frequency: RecurrenceFrequency.daily),
        targetTimes: const [TimeOfDay(hour: 12, minute: 0)],
        createdAt: now,
      ),
      ReminderItem(
        id: 'rem_salawat_2',
        programId: program3Id,
        category: ReminderTypeCategory.salawat,
        title: 'ورد الصلاة على النبي يوم الجمعة',
        text: '«أَكْثِرُوا عَلَيَّ مِنَ الصَّلَاةِ يَوْمَ الْجُمُعَةِ وَلَيْلَةَ الْجُمُعَةِ»',
        reference: 'سنن البيهقي وصححه الألباني',
        recurrenceRule: const RecurrenceRule(
          frequency: RecurrenceFrequency.specificWeekdays,
          weekdays: [DateTime.friday],
        ),
        targetTimes: const [TimeOfDay(hour: 14, minute: 0)],
        createdAt: now,
      ),
    ];

    // 4. صباحٌ ومساء
    const program4Id = 'template_program_sabah_masa';
    final program4 = FazakkirProgram(
      id: program4Id,
      name: 'صباحٌ ومساء',
      description: 'المحافظة على أوراد الصباح والمساء في مواعيدها المعتمدة',
      iconName: 'wb_twilight_rounded',
      createdAt: now,
      reminderIds: ['rem_sm_1', 'rem_sm_2'],
    );
    final reminders4 = [
      ReminderItem(
        id: 'rem_sm_1',
        programId: program4Id,
        category: ReminderTypeCategory.morningEvening,
        title: 'ورد الصباح',
        text: 'اللَّهُمَّ بِكَ أَصْبَحْنَا، وَبِكَ أَمْسَيْنَا، وَبِكَ نَحْيَا، وَبِكَ نَمُوتُ، وَإِلَيْكَ النُّشُورُ',
        reference: 'جامع الترمذي',
        recurrenceRule: const RecurrenceRule(frequency: RecurrenceFrequency.daily),
        targetTimes: const [TimeOfDay(hour: 6, minute: 30)],
        createdAt: now,
      ),
      ReminderItem(
        id: 'rem_sm_2',
        programId: program4Id,
        category: ReminderTypeCategory.morningEvening,
        title: 'ورد المساء',
        text: 'اللَّهُمَّ بِكَ أَمْسَيْنَا، وَبِكَ أَصْبَحْنَا، وَبِكَ نَحْيَا، وَبِكَ نَمُوتُ، وَإِلَيْكَ الْمَصِيرُ',
        reference: 'جامع الترمذي',
        recurrenceRule: const RecurrenceRule(frequency: RecurrenceFrequency.daily),
        targetTimes: const [TimeOfDay(hour: 17, minute: 30)],
        createdAt: now,
      ),
    ];

    // 5. نُورُ الجمعة
    const program5Id = 'template_program_noor_jumua';
    final program5 = FazakkirProgram(
      id: program5Id,
      name: 'نُورُ الجمعة',
      description: 'سنن وبركات يوم الجمعة من قراءة الكهف وساعة الإجابة والصلاة على النبي',
      iconName: 'auto_awesome_rounded',
      createdAt: now,
      reminderIds: ['rem_jumua_1', 'rem_jumua_2'],
    );
    final reminders5 = [
      ReminderItem(
        id: 'rem_jumua_1',
        programId: program5Id,
        category: ReminderTypeCategory.quranWird,
        title: 'سورة الكهف',
        text: '«مَنْ قَرَأَ سُورَةَ الْكَهْفِ فِي يَوْمِ الْجُمُعَةِ أَضَاءَ لَهُ مِنَ النُّورِ مَا بَيْنَ الْجُمُعَتَيْنِ»',
        reference: 'المستدرك للحاكم وصححه الألباني',
        recurrenceRule: const RecurrenceRule(
          frequency: RecurrenceFrequency.specificWeekdays,
          weekdays: [DateTime.friday],
        ),
        targetTimes: const [TimeOfDay(hour: 9, minute: 30)],
        createdAt: now,
      ),
      ReminderItem(
        id: 'rem_jumua_2',
        programId: program5Id,
        category: ReminderTypeCategory.dailyDua,
        title: 'ساعة الإجابة قبل الغروب',
        text: '«يَوْمُ الْجُمُعَةِ اثْنَتَا عَشْرَةَ سَاعَةً، لَا يُوجَدُ فِيهَا عَبْدٌ مُسْلِمٌ يَسْأَلُ اللَّهَ شَيْئًا إِلَّا آتَاهُ إِيَّاهُ»',
        reference: 'سنن أبي داود والنسائي',
        recurrenceRule: const RecurrenceRule(
          frequency: RecurrenceFrequency.specificWeekdays,
          weekdays: [DateTime.friday],
        ),
        targetTimes: const [TimeOfDay(hour: 16, minute: 45)],
        createdAt: now,
      ),
    ];

    // 6. وِردُ النوم
    const program6Id = 'template_program_wird_nawm';
    final program6 = FazakkirProgram(
      id: program6Id,
      name: 'وِردُ النوم',
      description: 'سكينة المساء وحفظ القرآن وآية الكرسي والمعوذات قبل النوم',
      iconName: 'bedtime_rounded',
      createdAt: now,
      reminderIds: ['rem_nawm_1', 'rem_nawm_2'],
    );
    final reminders6 = [
      ReminderItem(
        id: 'rem_nawm_1',
        programId: program6Id,
        category: ReminderTypeCategory.morningEvening,
        title: 'آية الكرسي والمعوذات',
        text: '﴿اللَّهُ لَا إِلَهَ إِلَّا هُوَ الْحَيُّ الْقَيُّومُ...﴾ والإخلاص والفلق والناس',
        reference: 'صحيح البخاري',
        recurrenceRule: const RecurrenceRule(frequency: RecurrenceFrequency.daily),
        targetTimes: const [TimeOfDay(hour: 22, minute: 30)],
        createdAt: now,
      ),
      ReminderItem(
        id: 'rem_nawm_2',
        programId: program6Id,
        category: ReminderTypeCategory.morningEvening,
        title: 'دعاء النوم',
        text: 'بِاسْمِكَ رَبِّي وَضَعْتُ جَنْبِي، وَبِكَ أَرْفَعُهُ، فَإِنْ أَمْسَكْتَ نَفْسِي فَارْحَمْهَا، وَإِنْ أَرْسَلْتَهَا فَاحْفَظْهَا بِمَا تَحْفَظُ بِهِ عِبَادَكَ الصَّالِحِينَ',
        reference: 'صحيح البخاري ومسلم',
        recurrenceRule: const RecurrenceRule(frequency: RecurrenceFrequency.daily),
        targetTimes: const [TimeOfDay(hour: 22, minute: 50)],
        createdAt: now,
      ),
    ];

    // 7. مَواردُ القرآن
    const program7Id = 'template_program_mawarid_quran';
    final program7 = FazakkirProgram(
      id: program7Id,
      name: 'مَواردُ القرآن',
      description: 'عهد يومي ثابت مع كتاب الله تلاوةً وتدبراً',
      iconName: 'menu_book_rounded',
      createdAt: now,
      reminderIds: ['rem_quran_1', 'rem_quran_2'],
    );
    final reminders7 = [
      ReminderItem(
        id: 'rem_quran_1',
        programId: program7Id,
        category: ReminderTypeCategory.quranWird,
        title: 'ورد التلاوة اليومي',
        text: '﴿أَقِمِ الصَّلَاةَ لِدُلُوكِ الشَّمْسِ إِلَى غَسَقِ اللَّيْلِ وَقُرْآنَ الْفَجْرِ إِنَّ قُرْآنَ الْفَجْرِ كَانَ مَشْهُودًا﴾',
        reference: 'سورة الإسراء: 78',
        recurrenceRule: const RecurrenceRule(frequency: RecurrenceFrequency.daily),
        targetTimes: const [TimeOfDay(hour: 6, minute: 0)],
        createdAt: now,
      ),
      ReminderItem(
        id: 'rem_quran_2',
        programId: program7Id,
        category: ReminderTypeCategory.quranWird,
        title: 'وقفة تدبر',
        text: '﴿كِتَابٌ أَنزَلْنَاهُ إِلَيْكَ مُبَارَكٌ لِّيَدَّبَّرُوا آيَاتِهِ وَلِيَتَذَكَّرَ أُولُو الْأَلْبَابِ﴾',
        reference: 'سورة ص: 29',
        recurrenceRule: const RecurrenceRule(frequency: RecurrenceFrequency.daily),
        targetTimes: const [TimeOfDay(hour: 20, minute: 30)],
        createdAt: now,
      ),
    ];

    return [
      PrebuiltTemplate(program: program1, reminders: reminders1),
      PrebuiltTemplate(program: program2, reminders: reminders2),
      PrebuiltTemplate(program: program3, reminders: reminders3),
      PrebuiltTemplate(program: program4, reminders: reminders4),
      PrebuiltTemplate(program: program5, reminders: reminders5),
      PrebuiltTemplate(program: program6, reminders: reminders6),
      PrebuiltTemplate(program: program7, reminders: reminders7),
    ];
  }
}
