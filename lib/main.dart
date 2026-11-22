import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'app.dart';
import 'core/notification/notification_service.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ProviderScope(child: StartupGate()));
}

/// Opens the boxes required by the app before any feature can use them.
/// An already-open box is left intact when retrying after a partial failure.
@visibleForTesting
Future<void> initializeAppStorage({Future<void> Function()? initializeHive}) async {
  if (initializeHive != null) {
    await initializeHive();
  } else {
    await Hive.initFlutter();
  }
  for (final name in ['settings', 'reading_positions', 'sessions']) {
    if (!Hive.isBoxOpen(name)) {
      await Hive.openBox<dynamic>(name);
    }
  }
}

Future<void> _configureOrientation() =>
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

Future<void> _initializeNotifications() => NotificationService().init();

/// Shows a first frame before storage and platform services are initialized.
class StartupGate extends StatefulWidget {
  const StartupGate({
    super.key,
    this.initializeStorage = initializeAppStorage,
    this.configureOrientation = _configureOrientation,
    this.initializeNotifications = _initializeNotifications,
    this.child = const ItqanApp(),
  });

  final Future<void> Function() initializeStorage;
  final Future<void> Function() configureOrientation;
  final Future<void> Function() initializeNotifications;
  final Widget child;

  @override
  State<StartupGate> createState() => _StartupGateState();
}

class _StartupGateState extends State<StartupGate> {
  bool _storageReady = false;
  bool _storageFailed = false;
  bool _storageTakingLong = false;
  Timer? _storageTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      unawaited(_initializeStorage());
      unawaited(_runOptional('Orientation', widget.configureOrientation));
      unawaited(_runOptional('Notifications', widget.initializeNotifications));
    });
  }

  @override
  void dispose() {
    _storageTimer?.cancel();
    super.dispose();
  }

  Future<void> _initializeStorage() async {
    _storageTimer = Timer(const Duration(seconds: 15), () {
      if (mounted) setState(() => _storageTakingLong = true);
    });
    try {
      await widget.initializeStorage();
      if (mounted) setState(() => _storageReady = true);
    } catch (error, stackTrace) {
      debugPrint('App storage initialization failed: $error\n$stackTrace');
      if (mounted) setState(() => _storageFailed = true);
    } finally {
      _storageTimer?.cancel();
    }
  }

  Future<void> _runOptional(
    String name,
    Future<void> Function() initialize,
  ) async {
    try {
      await initialize();
    } catch (error, stackTrace) {
      // A platform service failure must not stop storage or the first screen.
      debugPrint('$name initialization failed: $error\n$stackTrace');
    }
  }

  void _retryStorage() {
    if (!_storageFailed) return;
    setState(() {
      _storageFailed = false;
      _storageTakingLong = false;
    });
    unawaited(_initializeStorage());
  }

  @override
  Widget build(BuildContext context) {
    if (_storageReady) return widget.child;

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: const Color(0xFF1B5E20),
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Directionality(
                textDirection: TextDirection.rtl,
                child: _storageFailed
                    ? Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.error_outline,
                              color: Colors.white, size: 48),
                          const SizedBox(height: 16),
                          const Text(
                            'تعذّر تجهيز بيانات التطبيق. تحقق من مساحة التخزين ثم أعد المحاولة.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.white, fontSize: 18),
                          ),
                          const SizedBox(height: 20),
                          FilledButton(
                            onPressed: _retryStorage,
                            child: const Text('إعادة المحاولة'),
                          ),
                        ],
                      )
                    : Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.menu_book_rounded,
                              color: Colors.white, size: 72),
                          const SizedBox(height: 18),
                          const Text('إتقان',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 32,
                                  fontWeight: FontWeight.bold)),
                          const SizedBox(height: 24),
                          const CircularProgressIndicator(color: Colors.white),
                          if (_storageTakingLong) ...[
                            const SizedBox(height: 20),
                            const Text(
                              'يستغرق تجهيز البيانات وقتًا أطول من المتوقع. انتظر قليلًا أو أعد فتح التطبيق.',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.white),
                            ),
                          ],
                        ],
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
