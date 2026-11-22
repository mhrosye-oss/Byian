import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'core/notification/notification_service.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ProviderScope(child: ItqanApp()));
  WidgetsBinding.instance.addPostFrameCallback((_) {
    unawaited(_initializeNotifications());
  });
}

Future<void> _initializeNotifications() async {
  try {
    await NotificationService().init();
  } catch (error, stackTrace) {
    debugPrint('Notification initialization failed: $error\n$stackTrace');
  }
}
