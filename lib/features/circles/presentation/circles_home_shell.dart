import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/colors.dart';
import '../application/circle_providers.dart';
import '../data/circle_fcm_service.dart';
import '../domain/circle_models.dart';
import 'screens/circle_dashboard_screen.dart';
import 'screens/circle_notifications_screen.dart';
import 'screens/circle_profile_screen.dart';
import 'screens/my_circles_screen.dart';
import 'screens/my_tasks_screen.dart';
import 'screens/owner_dashboard_screen.dart';

class CirclesHomeShell extends ConsumerStatefulWidget {
  const CirclesHomeShell({
    super.key,
    required this.user,
    required this.onLogout,
  });

  final AppUser user;
  final VoidCallback onLogout;

  @override
  ConsumerState<CirclesHomeShell> createState() => _CirclesHomeShellState();
}

class _CirclesHomeShellState extends ConsumerState<CirclesHomeShell> {
  int _index = 0;
  StreamSubscription<RemoteMessage>? _tapSubscription;

  @override
  void initState() {
    super.initState();
    _tapSubscription =
        CircleFcmService.instance.notificationTaps.listen(_onTap);
  }

  @override
  void dispose() {
    _tapSubscription?.cancel();
    super.dispose();
  }

  void _onTap(RemoteMessage message) {
    final template = message.data['template']?.toString() ?? '';
    if (!mounted) return;
    if (template.startsWith('task_')) {
      setState(() => _index = 1);
      return;
    }
    final circleUuid = message.data['circle_uuid']?.toString();
    if (circleUuid != null && circleUuid.isNotEmpty) {
      final circleName = message.data['circle_name']?.toString() ?? 'الدائرة';
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => CircleDashboardScreen(
            circle: Circle(id: 0, uuid: circleUuid, name: circleName),
          ),
        ),
      );
      return;
    }
    setState(() => _index = 2);
  }

  @override
  Widget build(BuildContext context) {
    final circlesAsync = ref.watch(myCirclesProvider);
    final circles = circlesAsync.valueOrNull ?? const <Circle>[];
    final owned = circles.where((circle) => circle.isOwner).toList();
    final hasOwner = owned.isNotEmpty;
    final itemCount = hasOwner ? 5 : 4;
    if (_index >= itemCount) _index = 0;

    final pages = <Widget>[
      MyCirclesScreen(user: widget.user),
      const MyTasksScreen(),
      const CircleNotificationsScreen(),
      CircleProfileScreen(user: widget.user, onLogout: widget.onLogout),
      if (hasOwner)
        OwnerDashboardScreen(
          onOpenCircle: (circle) => Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => CircleDashboardScreen(circle: circle),
            ),
          ),
        ),
    ];

    return Scaffold(
      backgroundColor: ItqanColors.cream,
      body: IndexedStack(index: _index, children: pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (value) => setState(() => _index = value),
        destinations: [
          const NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded),
            label: 'دوائري',
          ),
          const NavigationDestination(
            icon: Icon(Icons.task_alt_outlined),
            selectedIcon: Icon(Icons.task_alt_rounded),
            label: 'مهامي',
          ),
          const NavigationDestination(
            icon: Icon(Icons.notifications_none_rounded),
            selectedIcon: Icon(Icons.notifications_rounded),
            label: 'الإشعارات',
          ),
          const NavigationDestination(
            icon: Icon(Icons.person_outline_rounded),
            selectedIcon: Icon(Icons.person_rounded),
            label: 'الملف',
          ),
          if (hasOwner)
            const NavigationDestination(
              icon: Icon(Icons.workspace_premium_outlined),
              selectedIcon: Icon(Icons.workspace_premium_rounded),
              label: 'القائد',
            ),
        ],
      ),
    );
  }
}
