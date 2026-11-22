import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';

class AppStartup {
  AppStartup({
    Future<void> Function()? orientationSetup,
    Future<void> Function()? storageSetup,
    Future<void> Function(String name)? boxOpener,
    bool Function(String name)? isBoxOpen,
  })  : _orientationSetup = orientationSetup ?? _configureOrientation,
        _storageSetup = storageSetup ?? _initializeHive,
        _boxOpener = boxOpener ?? _openHiveBox,
        _isBoxOpen = isBoxOpen ?? Hive.isBoxOpen;

  static const _boxNames = <String>[
    'settings',
    'reading_positions',
    'sessions',
  ];

  final Future<void> Function() _orientationSetup;
  final Future<void> Function() _storageSetup;
  final Future<void> Function(String name) _boxOpener;
  final bool Function(String name) _isBoxOpen;

  bool _storageInitialized = false;
  Future<void>? _initialization;

  Future<void> initialize() async {
    final current = _initialization;
    if (current != null) {
      return current;
    }

    final operation = _initialize();
    _initialization = operation;
    try {
      await operation;
    } catch (_) {
      _initialization = null;
      rethrow;
    }
  }

  Future<void> _initialize() async {
    await _orientationSetup();
    if (!_storageInitialized) {
      await _storageSetup();
      _storageInitialized = true;
    }

    for (final name in _boxNames) {
      if (!_isBoxOpen(name)) {
        await _boxOpener(name);
      }
    }
  }

  static Future<void> _configureOrientation() async {
    await SystemChrome.setPreferredOrientations(
      const [DeviceOrientation.portraitUp],
    );
  }

  static Future<void> _initializeHive() async {
    await Hive.initFlutter();
  }

  static Future<void> _openHiveBox(String name) async {
    await Hive.openBox<dynamic>(name);
  }
}
