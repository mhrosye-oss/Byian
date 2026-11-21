import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:itqan/core/localization/app_localizations.dart';
import 'package:itqan/core/services/auth_service.dart';
import 'package:itqan/core/settings/app_settings_provider.dart';
import 'package:itqan/core/theme/colors.dart';
import 'package:itqan/features/about/screens/about_screen.dart';
import 'package:itqan/features/ai/screens/ai_chat_screen.dart';
import 'package:itqan/features/auth/screens/login_screen.dart';
import 'package:itqan/features/circles/presentation/invitations_screen.dart';
import 'package:itqan/features/circles/presentation/my_circles_screen.dart';
import 'package:itqan/features/circles/presentation/my_tasks_screen.dart';
import 'package:itqan/features/contributors/screens/hall_of_fame_screen.dart';
import 'package:itqan/features/fazakkir/presentation/screens/fazakkir_dashboard_screen.dart';
import 'package:itqan/features/gamification/presentation/screens/leaderboard_screen.dart';
import 'package:itqan/features/itqan_journey/presentation/achievements_screen.dart';
import 'package:itqan/features/itqan_journey/presentation/profile_screen.dart';
import 'package:itqan/features/itqan_journey/social_share/presentation/share_card_generator_screen.dart';
import 'package:itqan/features/itqan_journey/world/presentation/itqan_world_screen.dart';
import 'package:itqan/features/kids/screens/kids_mode_screen.dart';
import 'package:itqan/features/nearby_mosques/presentation/nearby_mosques_screen.dart';
import 'package:itqan/features/notifications/screens/system_notifications_screen.dart';
import 'package:itqan/features/prayer/screens/prayer_notifications_screen.dart';
import 'package:itqan/features/settings/settings_screen.dart';
import 'package:itqan/features/settings/settings_service.dart';
import 'package:itqan/features/waqf/screens/waqf_screen.dart';

class CustomDrawer extends ConsumerStatefulWidget {
  const CustomDrawer({super.key});

  @override
  ConsumerState<CustomDrawer> createState() => _CustomDrawerState();
}

class _CustomDrawerState extends ConsumerState<CustomDrawer> {
  Map<String, String>? _user;

  static const _languages = {
    'ar': 'العربية',
    'en': 'English',
    'fr': 'Français',
    'id': 'Bahasa Indonesia',
    'bn': 'বাংলা',
    'hi': 'हिन्दी',
    'tr': 'Türkçe',
    'ur': 'اردو',
    'uz': "Oʻzbekcha",
    'es': 'Español',
  };

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final user = await AuthService.getUser();
    if (mounted) {
      setState(() {
        _user = user;
      });
    }
  }

  Future<void> _logout() async {
    await AuthService.logout();
    if (!mounted) return;
    setState(() => _user = null);
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute<void>(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  Future<void> _login() async {
    await Navigator.push<bool>(
      context,
      MaterialPageRoute<bool>(builder: (_) => const LoginScreen()),
    );
    _loadUser();
  }

  void _open(Widget page) {
    Navigator.pop(context);
    Navigator.push(context, MaterialPageRoute<void>(builder: (_) => page));
  }

  Future<void> _selectLanguage() async {
    final l = AppLocalizations.tr;
    final selected = await showDialog<Locale>(
      context: context,
      builder: (c) => SimpleDialog(
        title: Text(l(c, 'choose_language')),
        children: _languages.entries
            .map(
              (e) => SimpleDialogOption(
                onPressed: () => Navigator.pop(c, Locale(e.key)),
                child: Row(
                  children: [
                    Text(e.value, style: const TextStyle(fontSize: 16)),
                    if (Localizations.localeOf(c).languageCode == e.key) ...[
                      const SizedBox(width: 8),
                      const Icon(Icons.check, size: 16, color: Color(0xFF064E3B)),
                    ],
                  ],
                ),
              ),
            )
            .toList(),
      ),
    );

    if (selected == null || !mounted) return;

    try {
      await AppSettingsScope.of(context).setLocale(selected);
      if (!mounted) return;

      final langName = switch (selected.languageCode) {
        'en' => 'english',
        'fr' => 'french',
        'es' => 'spanish',
        'id' => 'indonesian',
        'hi' => 'hindi',
        'bn' => 'bengali',
        'tr' => 'turkish',
        'ur' => 'urdu',
        'uz' => 'uzbek',
        _ => 'arabic',
      };

      await ref
          .read(settingsProvider.notifier)
          .update(ref.read(settingsProvider).copyWith(language: langName));
    } catch (e) {
      if (mounted) {
        final errMsg = AppLocalizations.tr(context, 'language_error');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$errMsg$e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final userName = _user?['name'] ?? 'عبد الله';
    final userSubtitle = _user != null
        ? '${_user?['email']}'
        : 'المستوى 7 • الساعي • 860 نقطة';

    return Drawer(
      backgroundColor: ItqanColors.cream,
      width: MediaQuery.of(context).size.width * 0.86,
      child: Column(
        children: [
          // ─── Header: Forest Green with close button & user info ──────────
          Container(
            padding: const EdgeInsets.fromLTRB(16, 44, 18, 20),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topRight,
                end: Alignment.bottomLeft,
                colors: [
                  Color(0xFF064E3B),
                  Color(0xFF04382A),
                ],
              ),
            ),
            child: Row(
              children: [
                // Close button (X) on left
                Material(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.16),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.20),
                        ),
                      ),
                      child: const Icon(
                        Icons.close_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ),

                const Spacer(),

                // User details & Star Icon on right
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      userName,
                      style: const TextStyle(
                        fontFamily: 'Tajawal',
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      userSubtitle,
                      style: TextStyle(
                        fontFamily: 'Tajawal',
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: Colors.white.withValues(alpha: 0.76),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 10),

                // Star / Sparkle icon
                const Icon(
                  Icons.auto_awesome_rounded,
                  color: Color(0xFFFBBF24),
                  size: 22,
                ),
              ],
            ),
          ),

          // ─── Scrollable Body ─────────────────────────────────────────────
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              children: [
                // Section Title 1
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 4, vertical: 6),
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      'الملاحة الرئيسية',
                      style: TextStyle(
                        fontFamily: 'Tajawal',
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: ItqanColors.inkSoft,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 4),

                _buildDrawerCard(
                  title: 'الرئيسية',
                  subtitle: 'لوحة المتابعة اليومية',
                  icon: Icons.home_rounded,
                  iconBg: const Color(0xFFECFDF5),
                  iconColor: const Color(0xFF059669),
                  onTap: () => Navigator.pop(context),
                ),
                _buildDrawerCard(
                  title: 'تصوير الشاشة',
                  subtitle: 'لقطة كاملة للصفحة 📸',
                  icon: Icons.camera_alt_rounded,
                  iconBg: const Color(0xFFFEF3C7),
                  iconColor: const Color(0xFFD97706),
                  onTap: () => _open(const ShareCardGeneratorScreen()),
                ),
                _buildDrawerCard(
                  title: 'دوائري',
                  subtitle: 'حلقات العائلة والأصدقاء',
                  icon: Icons.diversity_3_rounded,
                  iconBg: const Color(0xFFFEF3C7),
                  iconColor: const Color(0xFFD97706),
                  onTap: () => _open(const MyCirclesScreen()),
                ),
                _buildDrawerCard(
                  title: 'مهامي في الدوائر',
                  subtitle: '4 من 9 مهام منجزة',
                  icon: Icons.checklist_rounded,
                  iconBg: const Color(0xFFE0F2FE),
                  iconColor: const Color(0xFF0284C7),
                  onTap: () => _open(const MyTasksScreen()),
                ),
                _buildDrawerCard(
                  title: 'دعواتي',
                  subtitle: 'ادعُ أحبابك واكسب الأجر',
                  icon: Icons.mail_outline_rounded,
                  iconBg: const Color(0xFFECFDF5),
                  iconColor: const Color(0xFF059669),
                  onTap: () => _open(const InvitationsScreen()),
                ),
                _buildDrawerCard(
                  title: 'فَذَكِّر',
                  subtitle: 'تذكير شخصي طازج',
                  icon: Icons.notifications_active_rounded,
                  iconBg: const Color(0xFFFEF3C7),
                  iconColor: const Color(0xFFD97706),
                  onTap: () => _open(const FazakkirDashboardScreen()),
                ),
                _buildDrawerCard(
                  title: 'مساجد قريبة',
                  subtitle: 'تحديد موقع المساجد وأوقات الصلاة',
                  icon: Icons.mosque_rounded,
                  iconBg: const Color(0xFFECFDF5),
                  iconColor: const Color(0xFF059669),
                  onTap: () => _open(const NearbyMosquesScreen()),
                ),
                _buildDrawerCard(
                  title: 'إشعارات مواقيت الصلاة',
                  subtitle: 'الأذان وتنبيهات الصلوات الخمس',
                  icon: Icons.access_alarms_rounded,
                  iconBg: const Color(0xFFFEF9C3),
                  iconColor: const Color(0xFFCA8A04),
                  onTap: () => _open(const PrayerNotificationsScreen()),
                ),
                _buildDrawerCard(
                  title: 'إشعارات النظام والرسائل',
                  subtitle: 'رسائل فايربيس ومهام الحلقات',
                  icon: Icons.campaign_rounded,
                  iconBg: const Color(0xFFEEF2FF),
                  iconColor: const Color(0xFF4F46E5),
                  onTap: () => _open(const SystemNotificationsScreen()),
                ),
                _buildDrawerCard(
                  title: 'عالم إتقان',
                  subtitle: 'المهام العشرون • اجمع النقاط',
                  icon: Icons.public_rounded,
                  iconBg: const Color(0xFFECFEFF),
                  iconColor: const Color(0xFF0891B2),
                  onTap: () => _open(const ItqanWorldScreen()),
                ),
                _buildDrawerCard(
                  title: 'ملفي وكود الإحالة',
                  subtitle: 'ITQ-8X4K2 • انسخ وشارك',
                  icon: Icons.qr_code_rounded,
                  iconBg: const Color(0xFFF1F5F9),
                  iconColor: const Color(0xFF475569),
                  onTap: () => _open(const JourneyProfileScreen()),
                ),
                _buildDrawerCard(
                  title: 'بطاقات المشاركة',
                  subtitle: 'صور دعوية للمشاركة',
                  icon: Icons.share_rounded,
                  iconBg: const Color(0xFFFEF3C7),
                  iconColor: const Color(0xFFD97706),
                  onTap: () => _open(const ShareCardGeneratorScreen()),
                ),
                _buildDrawerCard(
                  title: 'العشرة الأوائل',
                  subtitle: 'لوحة المتصدرين هذا الأسبوع',
                  icon: Icons.emoji_events_rounded,
                  iconBg: const Color(0xFFFEF9C3),
                  iconColor: const Color(0xFFCA8A04),
                  onTap: () => _open(const LeaderboardScreen()),
                ),
                _buildDrawerCard(
                  title: 'الأوسمة والإنجازات',
                  subtitle: '12 وساماً بانتظارك',
                  icon: Icons.military_tech_rounded,
                  iconBg: const Color(0xFFECFDF5),
                  iconColor: const Color(0xFF059669),
                  onTap: () => _open(const JourneyAchievementsScreen()),
                ),
                _buildDrawerCard(
                  title: 'الإعدادات',
                  subtitle: 'تنبيهات وموقع وثيم',
                  icon: Icons.tune_rounded,
                  iconBg: const Color(0xFFF1F5F9),
                  iconColor: const Color(0xFF475569),
                  onTap: () => _open(const SettingsScreen()),
                ),
                _buildDrawerCard(
                  title: 'اللغة',
                  subtitle: 'العربية • English',
                  icon: Icons.translate_rounded,
                  iconBg: const Color(0xFFFEF3C7),
                  iconColor: const Color(0xFFD97706),
                  onTap: _selectLanguage,
                ),
                _buildDrawerCard(
                  title: 'المساعد الذكي',
                  subtitle: 'اسأل عن العبادات والفقه',
                  icon: Icons.smart_toy_rounded,
                  iconBg: const Color(0xFFF0FDFA),
                  iconColor: const Color(0xFF0D9488),
                  onTap: () => _open(const AiChatScreen()),
                ),
                _buildDrawerCard(
                  title: 'وثيقة المساعد',
                  subtitle: 'دليل التغييرات 📄',
                  icon: Icons.description_rounded,
                  iconBg: const Color(0xFFFEF9C3),
                  iconColor: const Color(0xFFB45309),
                  onTap: () => _open(const AiChatScreen()),
                ),
                _buildDrawerCard(
                  title: 'وضع الأطفال',
                  subtitle: 'قصص وأذكار مبسطة',
                  icon: Icons.child_care_rounded,
                  iconBg: const Color(0xFFECFDF5),
                  iconColor: const Color(0xFF059669),
                  onTap: () => _open(const KidsModeScreen()),
                ),
                _buildDrawerCard(
                  title: 'الصدقة الجارية',
                  subtitle: 'سقيا وكفالة ووقف',
                  icon: Icons.volunteer_activism_rounded,
                  iconBg: const Color(0xFFFEF9C3),
                  iconColor: const Color(0xFFCA8A04),
                  onTap: () => _open(const WaqfScreen()),
                ),
                _buildDrawerCard(
                  title: 'شكراً لمساهمينا',
                  subtitle: 'صنّاع الخير معنا',
                  icon: Icons.favorite_rounded,
                  iconBg: const Color(0xFFECFDF5),
                  iconColor: const Color(0xFF059669),
                  onTap: () => _open(const HallOfFameScreen()),
                ),
                _buildDrawerCard(
                  title: 'من نحن',
                  subtitle: 'رؤيتنا وإصدار التطبيق',
                  icon: Icons.info_outline_rounded,
                  iconBg: const Color(0xFFECFDF5),
                  iconColor: const Color(0xFF059669),
                  onTap: () => _open(const AboutScreen()),
                ),

                const SizedBox(height: 12),

                // Section Title 2
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 4, vertical: 6),
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      'الحساب',
                      style: TextStyle(
                        fontFamily: 'Tajawal',
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: ItqanColors.inkSoft,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 4),

                // Profile Card
                _buildDrawerCard(
                  title: 'الملف الشخصي',
                  subtitle: _user != null
                      ? '$userName • مكة المكرمة'
                      : 'زائر إتقان • انقر للتسجيل',
                  icon: Icons.person_rounded,
                  iconBg: const Color(0xFFECFDF5),
                  iconColor: const Color(0xFF059669),
                  onTap: () => _open(const JourneyProfileScreen()),
                ),

                // Logout / Login Card
                Material(
                  color: ItqanColors.surface,
                  borderRadius: BorderRadius.circular(18),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(18),
                    onTap: _user == null ? _login : _logout,
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: ItqanColors.surface,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: const Color(0xFFFECDD3),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFE11D48)
                                .withValues(alpha: 0.04),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.chevron_left_rounded,
                              size: 18, color: Color(0xFFFDA4AF)),
                          const Spacer(),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                _user == null
                                    ? 'تسجيل الدخول'
                                    : 'تسجيل الخروج',
                                style: const TextStyle(
                                  fontFamily: 'Tajawal',
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFFE11D48),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _user == null
                                    ? 'احفظ وردك وتابع مهامك'
                                    : 'نراكم على خير',
                                style: const TextStyle(
                                  fontFamily: 'Tajawal',
                                  fontSize: 11,
                                  color: ItqanColors.muted,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(width: 12),
                          Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFE4E6),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.logout_rounded,
                              color: Color(0xFFE11D48),
                              size: 20,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 14),

                // Footer
                const Center(
                  child: Text(
                    'إتقان • رفيق الحياة الإسلامية v2.5 🕌',
                    style: TextStyle(
                      fontFamily: 'Tajawal',
                      fontSize: 11,
                      color: ItqanColors.muted,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: ItqanColors.surface,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: ItqanColors.border),
              boxShadow: [
                BoxShadow(
                  color: ItqanColors.ink.withValues(alpha: 0.035),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                const Icon(Icons.chevron_left_rounded,
                    size: 18, color: ItqanColors.muted),
                const Spacer(),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontFamily: 'Tajawal',
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: ItqanColors.ink,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontFamily: 'Tajawal',
                        fontSize: 11,
                        color: ItqanColors.inkSoft,
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 12),
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: iconBg,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: iconColor, size: 20),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
