import 'package:flutter/material.dart';
import 'package:itqan/core/settings/app_settings_provider.dart';
import 'package:itqan/features/about/screens/about_screen.dart';
import 'package:itqan/features/ai/screens/ai_chat_screen.dart';

class CustomDrawer extends StatelessWidget {
  const CustomDrawer({super.key});

  static const Color _green = Color(0xFF1B5E20);

  @override
  Widget build(BuildContext context) {
    final settings = AppSettingsScope.of(context);
    final theme = Theme.of(context);

    return Drawer(
      backgroundColor: theme.scaffoldBackgroundColor,
      child: SafeArea(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            Container(
              color: _green,
              padding: const EdgeInsets.fromLTRB(20, 28, 20, 24),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 34,
                    backgroundColor: Colors.white,
                    child: Icon(
                      Icons.person_rounded,
                      size: 38,
                      color: _green,
                    ),
                  ),
                  SizedBox(height: 14),
                  Text(
                    'عبد الله',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 19,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 3),
                  Text(
                    'user@example.com',
                    style: TextStyle(color: Colors.white70),
                  ),
                ],
              ),
            ),
            SwitchListTile(
              secondary: const Icon(Icons.dark_mode_outlined, color: _green),
              title: const Text('الوضع الداكن'),
              value: settings.isDarkMode,
              onChanged: settings.setDarkMode,
            ),
            ListTile(
              leading: const Icon(Icons.language_rounded, color: _green),
              title: const Text('اللغة'),
              subtitle: Text(_languageName(settings.locale.languageCode)),
              onTap: () => _showLanguagePicker(context, settings),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.auto_awesome_rounded, color: _green),
              title: const Text('اسأل الذكاء الاصطناعي'),
              onTap: () => _open(context, const AiChatScreen()),
            ),
            ListTile(
              leading: const Icon(Icons.info_outline_rounded, color: _green),
              title: const Text('من نحن'),
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
    Navigator.of(context).pop();
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => page),
    );
  }

  Future<void> _showLanguagePicker(
    BuildContext context,
    AppSettingsProvider settings,
  ) async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'اختر اللغة',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            for (final option in const [
              (code: 'ar', label: 'العربية (Arabic)'),
              (code: 'en', label: 'English (الإنجليزية)'),
              (code: 'fr', label: 'Français (الفرنسية)'),
              (code: 'ur', label: 'اردو (الأردية)'),
              (code: 'id', label: 'Bahasa Indonesia (الإندونيسية)'),
              (code: 'tr', label: 'Türkçe (التركية)'),
              (code: 'es', label: 'Español (الإسبانية)'),
              (code: 'de', label: 'Deutsch (الألمانية)'),
              (code: 'ru', label: 'Русский (الروسية)'),
              (code: 'zh', label: '中文 (الصينية)'),
              (code: 'ja', label: '日本語 (اليابانية)'),
              (code: 'ko', label: '한국어 (الكورية)'),
              (code: 'hi', label: 'हिन्दी (الهندية)'),
              (code: 'bn', label: 'বাংলা (البنغالية)'),
              (code: 'fa', label: 'فارسی (الفارسية)'),
              (code: 'ms', label: 'Bahasa Melayu (الماليزية)'),
              (code: 'sw', label: 'Kiswahili (السواحيلية)'),
              (code: 'pt', label: 'Português (البرتغالية)'),
              (code: 'it', label: 'Italiano (الإيطالية)'),
              (code: 'nl', label: 'Nederlands (الهولندية)'),
            ])
              ListTile(
                title: Text(option.label),
                trailing: settings.locale.languageCode == option.code
                    ? const Icon(Icons.check, color: _green)
                    : null,
                onTap: () async {
                  await settings.setLocale(Locale(option.code));

                  if (sheetContext.mounted) {
                    Navigator.of(sheetContext).pop();
                  }
                  if (context.mounted && Navigator.of(context).canPop()) {
                    Navigator.of(context).pop();
                  }
                },
              ),
          ],
        ),
      ),
    );
  }
}
