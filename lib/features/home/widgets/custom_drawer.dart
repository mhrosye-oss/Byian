import 'package:flutter/material.dart';
import 'package:itqan/core/settings/app_settings_provider.dart';
import 'package:itqan/core/theme/colors.dart';
import 'package:itqan/features/about/screens/about_screen.dart';
import 'package:itqan/features/ai/screens/ai_chat_screen.dart';

class CustomDrawer extends StatelessWidget {
  const CustomDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = AppSettingsScope.of(context);
    return Drawer(
      backgroundColor: Theme.of(context).brightness == Brightness.dark
          ? const Color(0xFF121A15)
          : ItqanColors.cream,
      child: SafeArea(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            Container(
              color: const Color(0xFF1B5E20),
              padding: const EdgeInsets.fromLTRB(20, 28, 20, 24),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 34,
                    backgroundColor: Colors.white,
                    child: Icon(Icons.person_rounded, size: 38, color: Color(0xFF1B5E20)),
                  ),
                  SizedBox(height: 14),
                  Text('عبد الله', style: TextStyle(color: Colors.white, fontSize: 19, fontWeight: FontWeight.bold)),
                  SizedBox(height: 3),
                  Text('user@example.com', style: TextStyle(color: Colors.white70)),
                ],
              ),
            ),
            SwitchListTile(
              secondary: const Icon(Icons.dark_mode_outlined, color: Color(0xFF1B5E20)),
              title: const Text('الوضع الداكن'),
              value: settings.isDarkMode,
              onChanged: settings.setDarkMode,
            ),
            ListTile(
              leading: const Icon(Icons.language_rounded, color: Color(0xFF1B5E20)),
              title: const Text('اللغة'),
              subtitle: Text(_languageName(settings.locale.languageCode)),
              onTap: () => _showLanguagePicker(context, settings),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.auto_awesome_rounded, color: Color(0xFF1B5E20)),
              title: const Text('اسأل الذكاء الاصطناعي'),
              onTap: () => _open(context, const AiChatScreen()),
            ),
            ListTile(
              leading: const Icon(Icons.info_outline_rounded, color: Color(0xFF1B5E20)),
              title: const Text('م�� نحن'),
              onTap: () => _open(context, const AboutScreen()),
            ),
          ],
        ),
      ),
    );
  }

  String _languageName(String code) => switch (code) {
        'en' => 'English',
        'fr' => 'Français',
        'ur' => 'اردو',
        _ => 'العربية',
      };

  void _open(BuildContext context, Widget page) {
    Navigator.pop(context);
    Navigator.push(context, MaterialPageRoute<void>(builder: (_) => page));
  }

  Future<void> _showLanguagePicker(BuildContext context, AppSettingsProvider settings) async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Padding(padding: EdgeInsets.all(16), child: Text('اختر اللغة', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
          for (final option in const [
            (code: 'ar', label: 'العربية'),
            (code: 'en', label: 'English'),
            (code: 'fr', label: 'Français'),
            (code: 'ur', label: 'اردو'),
          ])
            ListTile(
              title: Text(option.label),
              trailing: settings.locale.languageCode == option.code ? const Icon(Icons.check, color: Color(0xFF1B5E20)) : null,
              onTap: () async {
                await settings.setLocale(Locale(option.code));
                if (sheetContext.mounted) Navigator.pop(sheetContext);
                if (context.mounted && Navigator.canPop(context)) Navigator.pop(context);
              },
            ),
        ]),
      ),
    );
  }
}
