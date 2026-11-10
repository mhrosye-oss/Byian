import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:itqan/core/services/auth_service.dart';
import 'package:itqan/core/services/firebase_messaging_service.dart';
import 'package:itqan/core/services/google_firebase_auth_service.dart';
import 'package:itqan/core/settings/app_settings_provider.dart';
import 'package:itqan/features/auth/screens/login_screen.dart';
import 'package:itqan/features/about/screens/about_screen.dart';
import 'package:itqan/features/ai/screens/ai_chat_screen.dart';
import 'package:itqan/features/settings/settings_service.dart';
import 'package:itqan/features/settings/settings_screen.dart';
import 'package:itqan/features/waqf/screens/waqf_screen.dart';
import 'package:itqan/features/kids/screens/kids_mode_screen.dart';
import 'package:itqan/features/contributors/screens/hall_of_fame_screen.dart';
import 'package:itqan/features/itqan_journey/presentation/journey_dashboard_screen.dart';
import 'package:itqan/features/circles/presentation/screens/my_circles_screen.dart';
import 'package:itqan/features/itqan_journey/presentation/achievements_screen.dart';
import 'package:itqan/features/itqan_journey/presentation/profile_screen.dart';

class CustomDrawer extends ConsumerStatefulWidget {
  const CustomDrawer({super.key});
  @override
  ConsumerState<CustomDrawer> createState() => _CustomDrawerState();
}

class _CustomDrawerState extends ConsumerState<CustomDrawer> {
  Map<String, String>? _user;
  bool _isLoading = true;
  static const _languages = {
    'ar': 'العربية',
    'en': 'English',
    'fr': 'Français'
  };
  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final user = await AuthService.getUser();
    if (mounted)
      setState(() {
        _user = user;
        _isLoading = false;
      });
  }

  Future<void> _logout() async {
    await FirebaseMessagingService.instance.unregisterAfterLogout();
    try {
      await GoogleFirebaseAuthService.instance.signOut();
    } catch (_) {
      // Email/password users may not have an active Firebase session.
    }
    await AuthService.logout();
    if (mounted) setState(() => _user = null);
  }

  Future<void> _selectLanguage() async {
    final currentCode = Localizations.localeOf(context).languageCode;
    final appSettings = AppSettingsScope.of(context);
    final rootNavigator = Navigator.of(context, rootNavigator: true);
    final dialogContext = rootNavigator.context;

    // Close the drawer before rebuilding MaterialApp after a locale change.
    rootNavigator.pop();
    await Future<void>.delayed(Duration.zero);
    if (!mounted) return;

    final selectedLocale = await showDialog<Locale>(
      context: dialogContext,
      useRootNavigator: true,
      builder: (dialogContext) => SimpleDialog(
        title: const Text('اختر اللغة', textDirection: TextDirection.rtl),
        children: _languages.entries.map((entry) {
          return SimpleDialogOption(
            onPressed: () => Navigator.pop(dialogContext, Locale(entry.key)),
            child: Row(
              children: [
                Expanded(child: Text(entry.value)),
                if (entry.key == currentCode)
                  const Icon(Icons.check_rounded, color: Color(0xFF1B5E20)),
              ],
            ),
          );
        }).toList(),
      ),
    );
    if (selectedLocale == null || !mounted) return;

    try {
      await appSettings.setLocale(selectedLocale);
      if (!mounted) return;
      final name = switch (selectedLocale.languageCode) {
        'en' => 'english',
        'fr' => 'french',
        _ => 'arabic'
      };
      await ref
          .read(settingsProvider.notifier)
          .update(ref.read(settingsProvider).copyWith(language: name));
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('تعذر تغيير اللغة: $e')));
    }
  }

  void _open(Widget page) {
    Navigator.pop(context);
    Navigator.push(context, MaterialPageRoute<void>(builder: (_) => page));
  }

  Future<void> _login() async {
    final result = await Navigator.push<bool>(
        context, MaterialPageRoute<bool>(builder: (_) => const LoginScreen()));
    if (result == true) _loadUser();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Drawer(
        backgroundColor: theme.scaffoldBackgroundColor,
        child: SafeArea(
            child: ListView(padding: EdgeInsets.zero, children: [
          Container(
              color: theme.colorScheme.primary,
              padding: const EdgeInsets.all(20),
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(color: Colors.white))
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                          CircleAvatar(
                              child: Icon(_user == null
                                  ? Icons.person_outline
                                  : Icons.person)),
                          const SizedBox(height: 12),
                          Text(_user?['name'] ?? 'مرحباً بك',
                              style: theme.textTheme.titleLarge
                                  ?.copyWith(color: Colors.white)),
                          if (_user != null)
                            Text(_user?['email'] ?? '',
                                style: const TextStyle(color: Colors.white70)),
                          if (_user == null)
                            TextButton(
                                onPressed: _login,
                                child: const Text('تسجيل الدخول',
                                    style: TextStyle(color: Colors.white))),
                          if (_user != null)
                            TextButton(
                                onPressed: _logout,
                                child: const Text('تسجيل الخروج',
                                    style: TextStyle(color: Colors.white)))
                        ])),
          const Divider(),
          ListTile(
              leading: const Icon(Icons.home),
              title: const Text('الرئيسية'),
              onTap: () => Navigator.pop(context)),
          ListTile(
              leading: const Icon(Icons.explore),
              title: const Text('رحلتي'),
              onTap: () => _open(const JourneyDashboardScreen())),
          ListTile(
              leading: const Icon(Icons.groups_2_outlined),
              title: const Text('دوائري'),
              onTap: () => _open(const MyCirclesScreen())),
          ListTile(
              leading: const Icon(Icons.person),
              title: const Text('ملفي الشخصي'),
              onTap: () => _open(const JourneyProfileScreen())),
          ListTile(
              leading: const Icon(Icons.leaderboard),
              title: const Text('العشرة الأوائل'),
              onTap: () => _open(const JourneyLeaderboardScreen())),
          ListTile(
              leading: const Icon(Icons.military_tech),
              title: const Text('الإنجازات'),
              onTap: () => _open(const JourneyAchievementsScreen())),
          ListTile(
              leading: const Icon(Icons.settings),
              title: const Text('الإعدادات'),
              onTap: () => _open(const SettingsScreen())),
          const Divider(),
          ListTile(
              leading: const Icon(Icons.dark_mode_outlined),
              title: const Text('الوضع الداكن'),
              trailing: Switch(
                  value: theme.brightness == Brightness.dark,
                  onChanged: (_) {})),
          ListTile(
              leading: const Icon(Icons.language),
              title: const Text('اللغة'),
              subtitle: Text(
                  _languages[Localizations.localeOf(context).languageCode] ??
                      'العربية'),
              onTap: _selectLanguage),
          ListTile(
              leading: const Icon(Icons.smart_toy),
              title: const Text('المساعد الذكي'),
              onTap: () => _open(const AiChatScreen())),
          ListTile(
              leading: const Icon(Icons.child_care),
              title: const Text('وضع الأطفال'),
              onTap: () => _open(const KidsModeScreen())),
          ListTile(
              leading: const Icon(Icons.volunteer_activism),
              title: const Text('الصدقة الجارية'),
              onTap: () => _open(const WaqfScreen())),
          ListTile(
              leading: const Icon(Icons.diversity_3),
              title: const Text('شكراً لمساهمينا'),
              onTap: () => _open(const HallOfFameScreen())),
          ListTile(
              leading: const Icon(Icons.info_outline),
              title: const Text('من نحن'),
              onTap: () => _open(const AboutScreen()))
        ])));
  }
}
