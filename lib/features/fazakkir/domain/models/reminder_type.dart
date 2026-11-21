import 'package:flutter/material.dart';

/// أنواع التذكير المدعومة في خدمة «فَذَكِّر»
enum ReminderTypeCategory {
  morningEvening, // أذكار الصباح والمساء والنوم
  afterPrayer, // أذكار ما بعد الصلاة
  istighfar, // الاستغفار
  tasbihTahmid, // التسبيح والتحميد والتهليل والتكبير
  salawat, // الصلاة على النبي ﷺ
  dailyDua, // الأدعية اليومية والشخصية
  occasionalDua, // أدعية المناسبات
  quranWird, // ورد القرآن والختمة
  islamicOccasions, // المناسبات الإسلامية
  custom, // تذكير يكتبه المستخدم
}

class ReminderTypeInfo {
  final ReminderTypeCategory category;
  final String title;
  final String description;
  final IconData icon;
  final Color accentColor;

  const ReminderTypeInfo({
    required this.category,
    required this.title,
    required this.description,
    required this.icon,
    this.accentColor = const Color(0xFF0A5C36),
  });

  static const List<ReminderTypeInfo> allTypes = [
    ReminderTypeInfo(
      category: ReminderTypeCategory.morningEvening,
      title: 'أذكار الصباح والمساء والنوم',
      description: 'حصن المسلم اليومي في الصباح والعشي وعند النوم',
      icon: Icons.wb_twilight_rounded,
      accentColor: Color(0xFFB76E79),
    ),
    ReminderTypeInfo(
      category: ReminderTypeCategory.afterPrayer,
      title: 'أذكار ما بعد الصلاة',
      description: 'الأذكار الواردة عقب الصلوات المكتوبة',
      icon: Icons.mosque_rounded,
      accentColor: Color(0xFF0A5C36),
    ),
    ReminderTypeInfo(
      category: ReminderTypeCategory.istighfar,
      title: 'الاستغفار وسيد الاستغفار',
      description: 'أوراد الاستغفار وسؤال العفو والمغفرة',
      icon: Icons.water_drop_rounded,
      accentColor: Color(0xFF286A8A),
    ),
    ReminderTypeInfo(
      category: ReminderTypeCategory.tasbihTahmid,
      title: 'التسبيح والتحميد والتكبير',
      description: 'الباقيات الصالحات وذكر الله العظيم',
      icon: Icons.all_inclusive_rounded,
      accentColor: Color(0xFF9A6A12),
    ),
    ReminderTypeInfo(
      category: ReminderTypeCategory.salawat,
      title: 'الصلاة على النبي ﷺ',
      description: 'ورد الصلاة والسلام على رسول الله خصوصاً يوم الجمعة',
      icon: Icons.favorite_rounded,
      accentColor: Color(0xFF064426),
    ),
    ReminderTypeInfo(
      category: ReminderTypeCategory.dailyDua,
      title: 'الأدعية اليومية والشخصية',
      description: 'أدعية اليوم والليلة وجوامع الدعاء النبوي',
      icon: Icons.pan_tool_rounded,
      accentColor: Color(0xFF725A9B),
    ),
    ReminderTypeInfo(
      category: ReminderTypeCategory.occasionalDua,
      title: 'أدعية الأحوال والمناسبات',
      description: 'دعاء السفر، نزول المطر، الرزق، وعيادة المريض',
      icon: Icons.cloud_done_rounded,
      accentColor: Color(0xFF3B6F91),
    ),
    ReminderTypeInfo(
      category: ReminderTypeCategory.quranWird,
      title: 'ورد القرآن والختمة',
      description: 'التذكير الهادئ بورد التلاوة وسورة الكهف والتدبر',
      icon: Icons.menu_book_rounded,
      accentColor: Color(0xFF0A5C36),
    ),
    ReminderTypeInfo(
      category: ReminderTypeCategory.islamicOccasions,
      title: 'المناسبات والأيام الفاضلة',
      description: 'تذكير بصيام الاثنين والخميس والأيام البيض',
      icon: Icons.calendar_month_rounded,
      accentColor: Color(0xFFB76E79),
    ),
    ReminderTypeInfo(
      category: ReminderTypeCategory.custom,
      title: 'تذكير مخصص (أكتبه بنفسي)',
      description: 'ورد خاص أو دعاء تصيغه أنت بكلماتك الشخصية',
      icon: Icons.edit_note_rounded,
      accentColor: Color(0xFF5F685F),
    ),
  ];

  static ReminderTypeInfo fromCategory(ReminderTypeCategory category) {
    return allTypes.firstWhere(
      (t) => t.category == category,
      orElse: () => allTypes.first,
    );
  }
}
