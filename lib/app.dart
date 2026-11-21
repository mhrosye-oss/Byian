import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/theme/app_theme.dart';
import 'core/localization/app_localizations.dart';
import 'core/services/auth_service.dart';
import 'core/services/fcm_service.dart';
import 'core/settings/app_settings_provider.dart';
import 'features/circles/presentation/circle_khatmah_screen.dart';
import 'features/circles/presentation/circle_community_features_screen.dart';
import 'features/circles/presentation/circle_lessons_screen.dart';
import 'features/circles/presentation/invitations_screen.dart';
import 'features/circles/presentation/my_circles_screen.dart';
import 'features/circles/presentation/my_tasks_screen.dart';
import 'features/circles/presentation/notification_circle_members_screen.dart';
import 'features/circles/presentation/screens/whispers/whispers_sheet.dart';
import 'features/auth/screens/login_screen.dart';
import 'features/home/home_screen.dart';
import 'features/onboarding/onboarding_screen.dart';
import 'features/nearby_mosques/presentation/nearby_mosques_screen.dart';
import 'features/notifications/screens/system_notifications_screen.dart';
import 'features/prayer/screens/prayer_notifications_screen.dart';
import 'features/quran_teacher/presentation/screens/memorization_screen.dart';
import 'features/quran_teacher/presentation/screens/quran_teacher_recitation_screen.dart';
import 'features/quran_teacher/presentation/screens/recitation_intro_screen.dart';
import 'features/quran_teacher/presentation/screens/recitation_result_screen.dart';
import 'features/quran_teacher/presentation/screens/quran_teacher_home_screen.dart';
import 'features/quran_teacher/presentation/screens/revision_screen.dart';
import 'features/quran_teacher/presentation/screens/tajweed_lessons_screen.dart';
import 'features/tajweed/tajweed_screen.dart';
import 'l10n/app_localizations.dart' as generated_l10n;

const List<LocalizationsDelegate<dynamic>> itqanLocalizationsDelegates = [
  AppLocalizations.delegate,
  _GeneratedFallbackLocalizationsDelegate(),
  GlobalMaterialLocalizations.delegate,
  GlobalWidgetsLocalizations.delegate,
  GlobalCupertinoLocalizations.delegate,
];

const List<Locale> itqanSupportedLocales = [
  Locale('ar'),
  Locale('en'),
  Locale('fr'),
  Locale('es'),
  Locale('ur'),
  Locale('id'),
  Locale('hi'),
  Locale('bn'),
  Locale('tr'),
  Locale('uz'),
];

class ItqanApp extends StatefulWidget {
  const ItqanApp({super.key});

  @override
  State<ItqanApp> createState() => _ItqanAppState();
}

class _ItqanAppState extends State<ItqanApp> with WidgetsBindingObserver {
  final AppSettingsProvider _settings = AppSettingsProvider();
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();
  bool _isLoaded = false;
  bool _showOnboarding = false;
  bool _isAuthenticated = false;
  Map<String, dynamic>? _pendingNotification;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    AuthService.setSessionExpiredHandler(_handleSessionExpired);
    FcmService.setNotificationTapHandler(_handleNotificationTap);
    _loadSettings();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    AuthService.setSessionExpiredHandler(null);
    super.dispose();
  }

  void _handleSessionExpired() {
    if (!mounted || !_isAuthenticated || _showOnboarding) return;
    setState(() => _isAuthenticated = false);
    _navigatorKey.currentState?.pushAndRemoveUntil<void>(
      MaterialPageRoute<void>(
        settings: const RouteSettings(name: '/login'),
        builder: (_) => const LoginScreen(sessionExpired: true),
      ),
      (route) => false,
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _refreshAuthState();
    }
  }

  Future<void> _refreshAuthState() async {
    final authenticated = await AuthService.isAuthenticated();
    if (!mounted) return;
    final wasAuthenticated = _isAuthenticated;
    setState(() => _isAuthenticated = authenticated);

    if (!authenticated && wasAuthenticated && !_showOnboarding) {
      _navigatorKey.currentState?.pushAndRemoveUntil<void>(
        MaterialPageRoute<void>(
          settings: const RouteSettings(name: '/login'),
          builder: (_) => const LoginScreen(),
        ),
        (route) => false,
      );
    }
    if (authenticated) {
      try {
        await FcmService.registerCurrentDevice(requestPermission: false);
      } catch (error) {
        debugPrint('FCM device registration failed: $error');
      }
      _openPendingNotification();
    }
  }

  void _handleNotificationTap(Map<String, dynamic> data) {
    _pendingNotification = data;
    _openPendingNotification();
  }

  void _openPendingNotification() {
    if (!_isLoaded ||
        !_isAuthenticated ||
        _showOnboarding ||
        _pendingNotification == null ||
        _navigatorKey.currentState == null) {
      return;
    }

    final data = _pendingNotification!;
    _pendingNotification = null;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final navigator = _navigatorKey.currentState;
      final routeContext = _navigatorKey.currentContext;
      if (navigator == null || routeContext == null) {
        _pendingNotification = data;
        return;
      }

      final type = data['type']?.toString().toLowerCase();
      final circleUuid =
          (data['circle_uuid'] ?? data['circleUuid'])?.toString();
      switch (type) {
        case 'whisper':
          if (circleUuid == null || circleUuid.isEmpty) {
            navigator.push<void>(
              MaterialPageRoute<void>(
                builder: (_) => const MyCirclesScreen(),
              ),
            );
            return;
          }
          showModalBottomSheet<void>(
            context: routeContext,
            isScrollControlled: true,
            builder: (_) => FractionallySizedBox(
              heightFactor: 0.8,
              child: WhispersModalSheet(circleUuid: circleUuid),
            ),
          );
          break;
        case 'task':
        case 'task_assigned':
        case 'task_completed':
        case 'collective_task_completed':
        case 'task_overdue':
        case 'chain_task_received':
          navigator.push<void>(
            MaterialPageRoute<void>(
              builder: (_) => const MyTasksScreen(),
            ),
          );
          break;
        case 'dua_created':
        case 'question_created':
        case 'study_created':
          if (circleUuid != null && circleUuid.isNotEmpty) {
            navigator.push<void>(
              MaterialPageRoute<void>(
                builder: (_) => CircleCommunityFeaturesScreen(
                  circleUuid: circleUuid,
                  canManage: false,
                ),
              ),
            );
          } else {
            navigator.push<void>(
              MaterialPageRoute<void>(
                builder: (_) => const MyCirclesScreen(),
              ),
            );
          }
          break;
        case 'lesson_created':
          if (circleUuid != null && circleUuid.isNotEmpty) {
            navigator.push<void>(
              MaterialPageRoute<void>(
                builder: (_) => CircleLessonsScreen(
                  circleUuid: circleUuid,
                  canManage: false,
                ),
              ),
            );
          } else {
            navigator.push<void>(
              MaterialPageRoute<void>(
                builder: (_) => const MyCirclesScreen(),
              ),
            );
          }
          break;
        case 'member_role_changed':
          if (circleUuid != null && circleUuid.isNotEmpty) {
            navigator.push<void>(
              MaterialPageRoute<void>(
                builder: (_) =>
                    NotificationCircleMembersScreen(circleUuid: circleUuid),
              ),
            );
          } else {
            navigator.push<void>(
              MaterialPageRoute<void>(
                builder: (_) => const MyCirclesScreen(),
              ),
            );
          }
          break;
        case 'ownership_transferred':
          navigator.push<void>(
            MaterialPageRoute<void>(
              builder: (_) => const HomeScreen(),
            ),
          );
          break;
        case 'member_removed':
          navigator.push<void>(
            MaterialPageRoute<void>(
              builder: (_) => const MyCirclesScreen(),
            ),
          );
          break;
        case 'invitation':
          navigator.push<void>(
            MaterialPageRoute<void>(
              builder: (_) => const InvitationsScreen(),
            ),
          );
          break;
        case 'khatmah':
          final khatmahUuid =
              (data['khatmah_uuid'] ?? data['khatmahUuid'] ?? data['uuid'])
                  ?.toString();
          if (khatmahUuid != null && khatmahUuid.isNotEmpty) {
            navigator.push<void>(
              MaterialPageRoute<void>(
                builder: (_) =>
                    CircleKhatmahDetailsScreen(khatmahUuid: khatmahUuid),
              ),
            );
          } else if (circleUuid != null && circleUuid.isNotEmpty) {
            navigator.push<void>(
              MaterialPageRoute<void>(
                builder: (_) => CircleKhatmahScreen(
                  circleUuid: circleUuid,
                  canCreate: false,
                ),
              ),
            );
          } else {
            navigator.push<void>(
              MaterialPageRoute<void>(
                builder: (_) => const MyCirclesScreen(),
              ),
            );
          }
          break;
        default:
          debugPrint('Unsupported FCM notification type: $type');
      }
    });
  }

  Future<void> _loadSettings() async {
    await _settings.load();
    final preferences = await SharedPreferences.getInstance();
    final authenticated = await AuthService.isAuthenticated();
    if (mounted) {
      setState(() {
        _isLoaded = true;
        _showOnboarding =
            !(preferences.getBool('onboarding_completed') ?? false);
        _isAuthenticated = authenticated;
      });
    }
    _openPendingNotification();
    if (authenticated) {
      try {
        await FcmService.registerCurrentDevice();
      } catch (error) {
        debugPrint('FCM device registration failed: $error');
      }
    }
  }

  ThemeData get _lightTheme => AppTheme.light;
  ThemeData get _darkTheme => AppTheme.dark;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _settings,
      builder: (context, _) {
        return AppSettingsScope(
          settings: _settings,
          child: MaterialApp(
            navigatorKey: _navigatorKey,
            title: 'إتقان',
            debugShowCheckedModeBanner: false,
            themeMode: ThemeMode.light,
            theme: _lightTheme,
            darkTheme: _darkTheme,
            locale: _settings.locale,
            supportedLocales: itqanSupportedLocales,
            localizationsDelegates: itqanLocalizationsDelegates,
            routes: {
              '/smart_quran_teacher': (context) => const QuranTeacherHomeScreen(),
              '/recitation_intro': (context) => const RecitationIntroScreen(),
              '/teacher_recitation': (context) => const QuranTeacherRecitationScreen(),
              '/recitation_result': (context) => const RecitationResultScreen(),
              '/memorization': (context) => const MemorizationScreen(),
              '/revision': (context) => const RevisionScreen(),
              '/tajweed': (context) => const TajweedLessonsScreen(),
              '/tajweed_mushaf': (context) => const TajweedScreen(),
              '/teacher_home': (context) => const QuranTeacherHomeScreen(),
              '/nearby_mosques': (context) => const NearbyMosquesScreen(),
              '/prayer_notifications': (context) => const PrayerNotificationsScreen(),
              '/system_notifications': (context) => const SystemNotificationsScreen(),
            },
            home: !_isLoaded
                ? const _SplashScreen()
                : _showOnboarding
                    ? const OnboardingScreen()
                    : _isAuthenticated
                        ? const HomeScreen()
                        : const LoginScreen(),
          ),
        );
      },
    );
  }
}

/// شاشة البداية — تظهر أثناء تحميل الإعدادات وتعرض اسم التطبيق بلغته المحفوظة
class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) {
    // AppLocalizations.tr يستخدم الـ locale المحدد تلقائياً
    final appName = AppLocalizations.tr(context, 'app_title');
    final displayName = appName == 'app_title' ? 'إتقان' : appName;

    return Scaffold(
      backgroundColor: const Color(0xFF1B5E20),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.menu_book_rounded, size: 72, color: Colors.white),
            const SizedBox(height: 18),
            Text(
              displayName,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Itqan',
              style: TextStyle(color: Colors.white54, fontSize: 16),
            ),
            const SizedBox(height: 32),
            const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GeneratedFallbackLocalizationsDelegate
    extends LocalizationsDelegate<generated_l10n.AppLocalizations> {
  const _GeneratedFallbackLocalizationsDelegate();

  static const _supportedLanguageCodes = {
    'ar',
    'en',
    'fr',
    'es',
    'ur',
    'id',
    'hi',
    'bn',
    'fa',
    'uz',
    'tr'
  };
  static const _generatedLanguageCodes = {
    'ar',
    'en',
    'fr',
    'es',
    'ur',
    'id',
    'hi',
    'bn',
    'tr',
    'uz'
  };

  @override
  bool isSupported(Locale locale) =>
      _supportedLanguageCodes.contains(locale.languageCode);

  @override
  Future<generated_l10n.AppLocalizations> load(Locale locale) {
    final resolvedLocale = _generatedLanguageCodes.contains(locale.languageCode)
        ? locale
        : const Locale('ar');
    return generated_l10n.AppLocalizations.delegate.load(resolvedLocale);
  }

  @override
  bool shouldReload(_GeneratedFallbackLocalizationsDelegate old) => false;
}
