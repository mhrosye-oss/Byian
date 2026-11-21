import 'package:flutter/material.dart';

/// حالات المهمة الأربع وفق معايير المشروع
enum ItqanTaskStatus {
  notStarted,
  inProgress,
  completed,
  locked,
}

extension ItqanTaskStatusX on ItqanTaskStatus {
  String get arabicLabel {
    switch (this) {
      case ItqanTaskStatus.notStarted:
        return 'لم تبدأ';
      case ItqanTaskStatus.inProgress:
        return 'قيد التنفيذ';
      case ItqanTaskStatus.completed:
        return 'مكتملة';
      case ItqanTaskStatus.locked:
        return 'مقفلة';
    }
  }

  Color get color {
    switch (this) {
      case ItqanTaskStatus.notStarted:
        return const Color(0xFF8A8C83);
      case ItqanTaskStatus.inProgress:
        return const Color(0xFFD4AF37); // ذهبي إتقان
      case ItqanTaskStatus.completed:
        return const Color(0xFF0A5C36); // أخضر إتقان
      case ItqanTaskStatus.locked:
        return const Color(0xFFB0B3B8);
    }
  }

  IconData get icon {
    switch (this) {
      case ItqanTaskStatus.notStarted:
        return Icons.radio_button_unchecked_rounded;
      case ItqanTaskStatus.inProgress:
        return Icons.timelapse_rounded;
      case ItqanTaskStatus.completed:
        return Icons.check_circle_rounded;
      case ItqanTaskStatus.locked:
        return Icons.lock_outline_rounded;
    }
  }
}

/// مناطق عالم إتقان الخمس
enum ItqanZone {
  quranOasis, // 1. واحة القرآن
  adhkarGarden, // 2. حديقة الأذكار
  duaOrchard, // 3. بستان الأدعية
  goodnessPlaza, // 4. ميدان الخير والمشاركة
  itqanPeak, // 5. قمة الإتقان
}

extension ItqanZoneX on ItqanZone {
  String get title {
    switch (this) {
      case ItqanZone.quranOasis:
        return 'واحة القرآن';
      case ItqanZone.adhkarGarden:
        return 'حديقة الأذكار';
      case ItqanZone.duaOrchard:
        return 'بستان الأدعية';
      case ItqanZone.goodnessPlaza:
        return 'ميدان الخير والمشاركة';
      case ItqanZone.itqanPeak:
        return 'قمة الإتقان';
    }
  }

  String get description {
    switch (this) {
      case ItqanZone.quranOasis:
        return 'تلاوة، تدبر، واستمرارية قرآنية يومية';
      case ItqanZone.adhkarGarden:
        return 'حصن المسلم وأذكار الصباح والمساء والصلوات';
      case ItqanZone.duaOrchard:
        return 'مناجاة الرحمن وأدعية اليوم والمناسبات';
      case ItqanZone.goodnessPlaza:
        return 'نشر الخير وبطاقات الآيات وكود الإحالة';
      case ItqanZone.itqanPeak:
        return 'تحديات الأسبوع وسلسلة الاستمرارية وبلوغ التمام';
    }
  }

  IconData get icon {
    switch (this) {
      case ItqanZone.quranOasis:
        return Icons.menu_book_rounded;
      case ItqanZone.adhkarGarden:
        return Icons.spa_rounded;
      case ItqanZone.duaOrchard:
        return Icons.favorite_rounded;
      case ItqanZone.goodnessPlaza:
        return Icons.share_rounded;
      case ItqanZone.itqanPeak:
        return Icons.military_tech_rounded;
    }
  }

  Color get primaryColor {
    switch (this) {
      case ItqanZone.quranOasis:
        return const Color(0xFF0A5C36);
      case ItqanZone.adhkarGarden:
        return const Color(0xFF2E7D32);
      case ItqanZone.duaOrchard:
        return const Color(0xFF00796B);
      case ItqanZone.goodnessPlaza:
        return const Color(0xFFD4AF37);
      case ItqanZone.itqanPeak:
        return const Color(0xFF5D4037);
    }
  }
}

/// تعريف تفصيلي لإحدى المهام العشرين
class ItqanTaskDefinition {
  final int number; // 1 إلى 20
  final String key;
  final String title;
  final String description;
  final ItqanZone zone;
  final int pointsReward;
  final int target;
  final String unit;
  final String route;
  final IconData visualIcon;

  const ItqanTaskDefinition({
    required this.number,
    required this.key,
    required this.title,
    required this.description,
    required this.zone,
    required this.pointsReward,
    required this.target,
    required this.unit,
    required this.route,
    required this.visualIcon,
  });
}

/// سجل المهام العشرين الرسمي المعتمد في إتقان
class ItqanTasksRegistry {
  static const List<ItqanTaskDefinition> tasks = [
    // أ. مهام القرآن الكريم (واحة القرآن)
    ItqanTaskDefinition(
      number: 1,
      key: 'quran_daily_wird',
      title: 'ورد القرآن اليومي',
      description: 'قراءة الورد اليومي المحدد ومتابعة صفحات المصحف الشريف.',
      zone: ItqanZone.quranOasis,
      pointsReward: 50,
      target: 4,
      unit: 'صفحات',
      route: 'quran_wird',
      visualIcon: Icons.auto_stories_rounded,
    ),
    ItqanTaskDefinition(
      number: 2,
      key: 'quran_khatmah_progress',
      title: 'رحلة ختم القرآن',
      description: 'متابعة التقدم التراكمي في السور والأجزاء لبلوغ الختمة.',
      zone: ItqanZone.quranOasis,
      pointsReward: 80,
      target: 1,
      unit: 'جزء/حزب',
      route: 'khatmah',
      visualIcon: Icons.book_rounded,
    ),
    ItqanTaskDefinition(
      number: 3,
      key: 'quran_tadabbur',
      title: 'التدبر والتأمل',
      description: 'الوقوف عند آيات مباركة وقراءة تفسيرها والتأمل في معانيها.',
      zone: ItqanZone.quranOasis,
      pointsReward: 40,
      target: 1,
      unit: 'جلسة تدبر',
      route: 'tafsir',
      visualIcon: Icons.lightbulb_rounded,
    ),
    ItqanTaskDefinition(
      number: 4,
      key: 'quran_continuity',
      title: 'الاستمرارية القرآنية',
      description: 'المواظبة على فتح المصحف والقراءة دون انقطاع لأيام متتالية.',
      zone: ItqanZone.quranOasis,
      pointsReward: 60,
      target: 1,
      unit: 'يوم متواصل',
      route: 'quran_journey',
      visualIcon: Icons.repeat_rounded,
    ),

    // ب. مهام الأذكار (حديقة الأذكار)
    ItqanTaskDefinition(
      number: 5,
      key: 'adhkar_morning',
      title: 'أذكار الصباح',
      description: 'قراءة أذكار الصباح المباركة وإكمال تكراراتها كاملة.',
      zone: ItqanZone.adhkarGarden,
      pointsReward: 40,
      target: 1,
      unit: 'إتمام كامل',
      route: 'adhkar_morning',
      visualIcon: Icons.wb_sunny_rounded,
    ),
    ItqanTaskDefinition(
      number: 6,
      key: 'adhkar_evening',
      title: 'أذكار المساء',
      description: 'قراءة أذكار المساء وحصن المسلم في وقت العصر والمغرب.',
      zone: ItqanZone.adhkarGarden,
      pointsReward: 40,
      target: 1,
      unit: 'إتمام كامل',
      route: 'adhkar_evening',
      visualIcon: Icons.nights_stay_rounded,
    ),
    ItqanTaskDefinition(
      number: 7,
      key: 'adhkar_after_prayer',
      title: 'أذكار ما بعد الصلاة',
      description: 'ترديد الأذكار والتسبيحات الواردة عقب الصلوات المكتوبة.',
      zone: ItqanZone.adhkarGarden,
      pointsReward: 30,
      target: 5,
      unit: 'صلوات',
      route: 'adhkar_prayer',
      visualIcon: Icons.mosque_rounded,
    ),
    ItqanTaskDefinition(
      number: 8,
      key: 'tasbih_counter',
      title: 'مسبحة الأذكار',
      description: 'إنجاز دورة تسبيح تفاعلية مع حفظ الجلسة واستمراريتها.',
      zone: ItqanZone.adhkarGarden,
      pointsReward: 35,
      target: 100,
      unit: 'تسبيحة',
      route: 'tasbih',
      visualIcon: Icons.fingerprint_rounded,
    ),

    // ج. مهام الأدعية (بستان الأدعية)
    ItqanTaskDefinition(
      number: 9,
      key: 'dua_daily',
      title: 'أدعية يومية',
      description: 'قراءة الأدعية المأثورة الموثوقة لليوم والليلة.',
      zone: ItqanZone.duaOrchard,
      pointsReward: 30,
      target: 3,
      unit: 'أدعية',
      route: 'dua_journey',
      visualIcon: Icons.favorite_border_rounded,
    ),
    ItqanTaskDefinition(
      number: 10,
      key: 'dua_tasbih',
      title: 'مسبحة الأدعية',
      description: 'ترديد الاستغفار وسيد الاستغفار بعداد مسبحة الأدعية التفاعلي.',
      zone: ItqanZone.duaOrchard,
      pointsReward: 35,
      target: 70,
      unit: 'استغفار ودعاء',
      route: 'tasbih',
      visualIcon: Icons.all_inclusive_rounded,
    ),
    ItqanTaskDefinition(
      number: 11,
      key: 'dua_occasions',
      title: 'أدعية المناسبات والأحوال',
      description: 'الاستفادة من أدعية الكرب والمطر والسفر والاستخارة والشفاء.',
      zone: ItqanZone.duaOrchard,
      pointsReward: 25,
      target: 1,
      unit: 'دعاء مناسبة',
      route: 'duas_occasions',
      visualIcon: Icons.celebration_rounded,
    ),
    ItqanTaskDefinition(
      number: 12,
      key: 'dua_personal',
      title: 'الأدعية الشخصية المحفوظة',
      description: 'حفظ الأدعية المفضلة والمناجاة الشخصية للرجوع إليها.',
      zone: ItqanZone.duaOrchard,
      pointsReward: 20,
      target: 1,
      unit: 'دعاء محفوظ',
      route: 'dua_bookmarks',
      visualIcon: Icons.bookmark_added_rounded,
    ),

    // د. مهام المشاركة ونشر الخير (ميدان الخير)
    ItqanTaskDefinition(
      number: 13,
      key: 'share_quran_ayah',
      title: 'مشاركة القرآن',
      description: 'توليد ومشاركة بطاقة قرآنية أنيقة لآية كريمة مع الآخرين.',
      zone: ItqanZone.goodnessPlaza,
      pointsReward: 30,
      target: 1,
      unit: 'مشاركة بطاقة',
      route: 'share_card_generator',
      visualIcon: Icons.format_quote_rounded,
    ),
    ItqanTaskDefinition(
      number: 14,
      key: 'share_hadith',
      title: 'مشاركة الأحاديث النبوية',
      description: 'نشر حديث نبوي شريف موثق عبر بطاقة مشاركة احترافية.',
      zone: ItqanZone.goodnessPlaza,
      pointsReward: 30,
      target: 1,
      unit: 'حديث موثق',
      route: 'share_card_generator',
      visualIcon: Icons.menu_book_outlined,
    ),
    ItqanTaskDefinition(
      number: 15,
      key: 'share_adhkar_dua',
      title: 'مشاركة الأذكار والأدعية',
      description: 'مشاركة الذكر والدعاء وتذكير الأهل والأصدقاء بالخير.',
      zone: ItqanZone.goodnessPlaza,
      pointsReward: 25,
      target: 1,
      unit: 'مشاركة',
      route: 'share_journey',
      visualIcon: Icons.volunteer_activism_rounded,
    ),
    ItqanTaskDefinition(
      number: 16,
      key: 'share_achievement',
      title: 'مشاركة الإنجاز والوسام',
      description: 'مشاركة وسامك أو مستواك المحقق في إتقان لتشجيع الصحبة الصالحة.',
      zone: ItqanZone.goodnessPlaza,
      pointsReward: 35,
      target: 1,
      unit: 'إنجاز معلن',
      route: 'share_card_generator',
      visualIcon: Icons.workspace_premium_rounded,
    ),

    // هـ. الذكاء والاستمرارية (قمة الإتقان)
    ItqanTaskDefinition(
      number: 17,
      key: 'daily_smart_challenge',
      title: 'التحدي اليومي',
      description: 'إنجاز التحدي اليومي المتجدد والمناسب لمستواك في الرحلة.',
      zone: ItqanZone.itqanPeak,
      pointsReward: 60,
      target: 1,
      unit: 'تحدٍ منجز',
      route: 'journey_dashboard',
      visualIcon: Icons.star_border_purple500_rounded,
    ),
    ItqanTaskDefinition(
      number: 18,
      key: 'weekly_goal_challenge',
      title: 'التحدي الأسبوعي',
      description: 'تحقيق أهداف الأسبوع الإيمانية بتوازن واستمرار.',
      zone: ItqanZone.itqanPeak,
      pointsReward: 120,
      target: 7,
      unit: 'أيام التزام',
      route: 'journey_dashboard',
      visualIcon: Icons.emoji_events_rounded,
    ),
    ItqanTaskDefinition(
      number: 19,
      key: 'streak_continuity',
      title: 'سلسلة الاستمرارية',
      description: 'المحافظة على الحضور الإيماني اليومي دون انقطاع السلسلة.',
      zone: ItqanZone.itqanPeak,
      pointsReward: 70,
      target: 3,
      unit: 'أيام متتالية',
      route: 'journey_profile',
      visualIcon: Icons.local_fire_department_rounded,
    ),
    ItqanTaskDefinition(
      number: 20,
      key: 'invitation_goodness',
      title: 'دعوة الخير (كود الإحالة)',
      description: 'دعوة صديق للانضمام إلى إتقان باستخدام كود الإحالة الشخصي الخاص بك.',
      zone: ItqanZone.itqanPeak,
      pointsReward: 100,
      target: 1,
      unit: 'دعوة صديق',
      route: 'referral_section',
      visualIcon: Icons.person_add_alt_1_rounded,
    ),
  ];

  static List<ItqanTaskDefinition> getTasksForZone(ItqanZone zone) {
    return tasks.where((t) => t.zone == zone).toList();
  }

  static ItqanTaskDefinition? getTaskByKey(String key) {
    try {
      return tasks.firstWhere((t) => t.key == key);
    } catch (_) {
      return null;
    }
  }
}

