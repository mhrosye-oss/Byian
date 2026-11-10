import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../application/circle_providers.dart';
import '../data/circle_api_client.dart';
import '../data/circle_api_config.dart';
import '../data/circle_fcm_service.dart';
import '../data/circle_session_store.dart';
import '../domain/circle_models.dart';
import 'circles_home_shell.dart';
import 'circles_login_screen.dart';

class CirclesEntryScreen extends ConsumerStatefulWidget {
  const CirclesEntryScreen({super.key});

  @override
  ConsumerState<CirclesEntryScreen> createState() => _CirclesEntryScreenState();
}

class _CirclesEntryScreenState extends ConsumerState<CirclesEntryScreen> {
  final CircleApiClient _api = CircleApiClient.instance;
  final CircleSessionStore _session = SecureCircleSessionStore();
  StreamSubscription<void>? _expiredSubscription;
  AppUser? _user;
  String? _error;
  bool _checking = true;

  @override
  void initState() {
    super.initState();
    _expiredSubscription = _api.sessionExpired.listen((_) {
      if (!mounted) return;
      ref.read(currentCircleUserProvider.notifier).state = null;
      setState(() {
        _user = null;
        _error = null;
      });
    });
    _restoreSession();
  }

  @override
  void dispose() {
    _expiredSubscription?.cancel();
    super.dispose();
  }

  Future<void> _restoreSession() async {
    setState(() {
      _checking = true;
      _error = null;
    });
    try {
      final token = await _session.readToken();
      if (token == null || token.isEmpty) {
        if (mounted) setState(() => _checking = false);
        return;
      }
      final user = await _api.getMe();
      if (!mounted) return;
      _setUser(user);
      try {
        await CircleFcmService.instance.registerAfterLogin(_api);
      } catch (error) {
        debugPrint('FCM registration failed after session restore: $error');
      }
      setState(() => _checking = false);
    } on CircleApiException catch (error) {
      if (!mounted) return;
      if (error.isUnauthenticatedBug) {
        setState(() {
          _checking = false;
          _error = error.message;
        });
        return;
      }
      final token = await _session.readToken();
      if (token == null || token.isEmpty) {
        setState(() {
          _user = null;
          _checking = false;
        });
      } else {
        setState(() {
          _checking = false;
          _error = error.message;
        });
      }
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _checking = false;
        _error = 'تعذر استعادة الجلسة: $error';
      });
    }
  }

  void _setUser(AppUser user) {
    _user = user;
    ref.read(currentCircleUserProvider.notifier).state = user;
  }

  Future<void> _onSignedIn(AppUser user) async {
    if (!mounted) return;
    setState(() {
      _setUser(user);
      _error = null;
    });
    try {
      await CircleFcmService.instance.registerAfterLogin(_api);
    } catch (error) {
      debugPrint('FCM registration failed after sign-in: $error');
    }
  }

  void _onLogout() {
    if (!mounted) return;
    ref.read(currentCircleUserProvider.notifier).state = null;
    setState(() {
      _user = null;
      _error = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_checking) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    if (_user != null) {
      return CirclesHomeShell(user: _user!, onLogout: _onLogout);
    }
    if (_error != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('التحقق من الجلسة')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.cloud_off_outlined, size: 48),
                const SizedBox(height: 12),
                Text(_error!, textAlign: TextAlign.center),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: _restoreSession,
                  icon: const Icon(Icons.refresh),
                  label: const Text('إعادة المحاولة'),
                ),
              ],
            ),
          ),
        ),
      );
    }
    return CirclesLoginScreen(onSignedIn: _onSignedIn);
  }
}
