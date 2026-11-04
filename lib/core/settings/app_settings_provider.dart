import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// App-wide settings persisted locally and exposed to the widget tree.
class AppSettingsProvider extends ChangeNotifier {
  static const _darkModeKey = 'app_dark_mode';
  static const _languageKey = 'app_language';

  bool _isDarkMode = false;
  Locale _locale = const Locale('ar');
  bool _loaded = false;

  bool get isDarkMode => _isDarkMode;
  Locale get locale => _locale;
  bool get isLoaded => _loaded;

  Future<void> load() async {
    final preferences = await SharedPreferences.getInstance();
    _isDarkMode = preferences.getBool(_darkModeKey) ?? false;
    final language = preferences.getString(_languageKey) ?? 'ar';
    _locale = Locale(_supportedLanguage(language));
    _loaded = true;
    notifyListeners();
  }

  Future<void> setDarkMode(bool enabled) async {
    _isDarkMode = enabled;
    notifyListeners();
    final preferences = await SharedPreferences.getInstance();
    await preferences.setBool(_darkModeKey, enabled);
  }

  Future<void> setLocale(Locale locale) async {
    final language = _supportedLanguage(locale.languageCode);
    _locale = Locale(language);
    notifyListeners();
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_languageKey, language);
  }

  String _supportedLanguage(String language) =>
      const {'ar', 'en', 'fr', 'ur'}.contains(language) ? language : 'ar';
}

class AppSettingsScope extends InheritedNotifier<AppSettingsProvider> {
  const AppSettingsScope({
    required AppSettingsProvider settings,
    required super.child,
    super.key,
  }) : super(notifier: settings);

  static AppSettingsProvider of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AppSettingsScope>();
    assert(scope != null, 'AppSettingsScope is missing from the widget tree.');
    return scope!.notifier!;
  }
}
