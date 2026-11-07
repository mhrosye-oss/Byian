import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:itqan/core/services/auth_service.dart';
import 'package:itqan/core/settings/app_settings_provider.dart';
import 'package:itqan/features/auth/screens/login_screen.dart';
import 'package:itqan/features/about/screens/about_screen.dart';
import 'package:itqan/features/ai/screens/ai_chat_screen.dart';
import 'package:itqan/features/settings/settings_service.dart';
import 'package:itqan/features/waqf/screens/waqf_screen.dart';
import 'package:itqan/features/kids/screens/kids_mode_screen.dart';
import 'package:itqan/features/contributors/screens/hall_of_fame_screen.dart';

class CustomDrawer extends ConsumerStatefulWidget {
  const CustomDrawer({super.key});
  @override
  ConsumerState<CustomDrawer> createState() => _CustomDrawerState();
}

class _CustomDrawerState extends ConsumerState<CustomDrawer> {
  Map<String, String>? _user;
  bool _isLoading = true;
  static const _languages = <String, String>{
    'ar': 'العربية',
    'en': 'English',
    'fr': 'Français',
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
        _isLoading = false;
      });
    }
  }

  Future<void> _logout() async {
    await AuthService.logout();
    if (mounted) {
      setState(() => _user = null);
    }
  }

  Future<void> _selectLanguage() async {
    final currentCode = Localizations.localeOf(context).languageCode;
    final selectedLocale = await showDialog<Locale>(
      context: context,
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
      final appSettings = AppSettingsScope.of(context);
      await appSettings.setLocale(selectedLocale);
      if (!mounted) return;
      final languageName = switch (selectedLocale.languageCode) {
        'en' => 'english',
        'fr' => 'french',
        _ => 'arabic',
      };
      await ref.read(settingsProvider.notifier).update(
            ref.read(settingsProvider).copyWith(language: languageName),
          );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('تعذر تغيير اللغة: $error')),
      );
    }
  }

  void _goToLogin() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
    if (result == true) {
      _loadUser();
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color green = Color(0xFF1B5E20);
    final theme = Theme.of(context);
    final selectedLanguage =
        _languages[Localizations.localeOf(context).languageCode] ??
            _languages['ar']!;

    return Drawer(
      backgroundColor: theme.scaffoldBackgroundColor,
      child: SafeArea(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            Container(
              color: green,
              padding: const EdgeInsets.fromLTRB(20, 28, 20, 24),
              child: _isLoading 
                  ? const Center(child: CircularProgressIndicator(color: Colors.white))
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CircleAvatar(
                          radius: 34, 
                          backgroundColor: Colors.white, 
                          child: Icon(_user != null ? Icons.person : Icons.person_outline, size: 38, color: green)
                        ),
                        const SizedBox(height: 14),
                        
                        if (_user != null) ...[
                          Text(_user!['name']!, style: const TextStyle(color: Colors.white, fontSize: 19, fontWeight: FontWeight.bold)),
                          Text(_user!['email']!, style: const TextStyle(color: Colors.white70, fontSize: 14)),
                          const SizedBox(height: 8),
                          InkWell(
                            onTap: _logout,
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.logout, color: Colors.white70, size: 16),
                                SizedBox(width: 4),
                                Text('تسجيل الخروج', style: TextStyle(color: Colors.white70, fontSize: 12)),
                              ],
                            ),
                          )
                        ] else ...[
                          const Text('مرحباً بك', style: TextStyle(color: Colors.white, fontSize: 19, fontWeight: FontWeight.bold)),
                          const Text('أنت تتصفح كزائر حالياً', style: TextStyle(color: Colors.white70, fontSize: 14)),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _goToLogin,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: green,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                padding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                              child: const Text('تسجيل الدخول / إنشاء حساب', style: TextStyle(fontWeight: FontWeight.bold)),
                            ),
                          )
                        ],
                      ],
                    ),
            ),
            
            const SizedBox(height: 10),

            _buildDrawerItem(
              icon: Icons.dark_mode_outlined,
              title: 'الوضع الداكن',
              trailing: Switch(
                value: theme.brightness == Brightness.dark,
                activeColor: green,
                onChanged: (val) {}, 
              ),
            ),
            
            _buildDrawerItem(
              icon: Icons.language_rounded,
              title: 'اللغة',
              subtitle: selectedLanguage,
              onTap: _selectLanguage,
            ),
            
            const Divider(),
            
            _buildDrawerItem(
              icon: Icons.smart_toy_rounded,
              title: 'المساعد الذكي',
              onTap: () => _openPage(context, const AiChatScreen()),
            ),
            
            _buildDrawerItem(
              icon: Icons.child_care_rounded,
              title: 'وضع الأطفال',
              onTap: () => _openPage(context, const KidsModeScreen()),
            ),
            
            _buildDrawerItem(
              icon: Icons.volunteer_activism_rounded,
              title: 'الصدقة الجارية',
              onTap: () => _openPage(context, const WaqfScreen()),
            ),
            
            _buildDrawerItem(
              icon: Icons.diversity_3_rounded,
              title: 'شكراً لمساهمينا',
              onTap: () => _openPage(context, const HallOfFameScreen()),
            ),
            
            const Divider(),
            
            _buildDrawerItem(
              icon: Icons.info_outline_rounded,
              title: 'من نحن',
              onTap: () => _openPage(context, const AboutScreen()),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerItem({
    required IconData icon, 
    required String title, 
    String? subtitle, 
    Widget? trailing, 
    VoidCallback? onTap
  }) {
    const Color green = Color(0xFF1B5E20);
    return ListTile(
      leading: Icon(icon, color: green),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: subtitle != null ? Text(subtitle) : null,
      trailing: trailing,
      onTap: onTap,
    );
  }

  void _openPage(BuildContext context, Widget page) {
    Navigator.pop(context); 
    Navigator.push(context, MaterialPageRoute(builder: (_) => page));
  }
}
