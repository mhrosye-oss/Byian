import 'dart:async';

import 'package:flutter/material.dart';

import '../../data/services/engagement_service.dart';
import 'dynamic_popup_widget.dart';

/// In-memory state shared by all home-screen instances in this app process.
/// An unavailable popup is not counted as shown and may be retried on re-entry.
class EngagementPopupSession {
  EngagementPopupSession();

  static final EngagementPopupSession instance = EngagementPopupSession();
  bool _shown = false;
  Completer<void>? _pending;

  Future<void> showIfAvailable(
    BuildContext context, {
    required EngagementService service,
    required void Function(DialogRoute<void> route) onRoutePushed,
    void Function(String route)? onNavigateRoute,
  }) async {
    while (_pending != null && !_shown) {
      await _pending!.future;
      if (!context.mounted) return;
    }
    if (_shown || !context.mounted) return;

    final reservation = Completer<void>();
    _pending = reservation;
    try {
      const placement = 'welcome_popup';
      final items = await service.fetchEngagementItems(placement);
      if (!context.mounted || ModalRoute.of(context)?.isCurrent == false) {
        return;
      }
      final popups = items.where(
        (item) => item.matchesPlacementAndType(placement, 'popup'),
      );
      if (popups.isEmpty) return;

      final item = popups.first;
      final route = DialogRoute<void>(
        context: context,
        barrierDismissible: true,
        barrierColor: Colors.black.withValues(alpha: 0.65),
        builder: (_) => DynamicPopupWidget(
          item: item,
          service: service,
          homeContext: context,
          onNavigateRoute: onNavigateRoute,
        ),
      );
      final navigator = Navigator.of(context, rootNavigator: true);
      final closed = navigator.push(route);
      _shown = true;
      onRoutePushed(route);
      unawaited(service.trackView(item.uuid));
      await closed;
    } catch (_) {
      // An unavailable placement or navigator must not interrupt the home UI.
    } finally {
      _pending = null;
      reservation.complete();
    }
  }
}

/// Owns popup scheduling and lifecycle independently of the banner carousel.
class EngagementPopupWidget extends StatefulWidget {
  const EngagementPopupWidget({
    super.key,
    required this.child,
    this.onNavigateRoute,
    this.service,
    this.session,
  });

  final Widget child;
  final void Function(String route)? onNavigateRoute;
  final EngagementService? service;
  final EngagementPopupSession? session;

  @override
  State<EngagementPopupWidget> createState() => _EngagementPopupWidgetState();
}

class _EngagementPopupWidgetState extends State<EngagementPopupWidget> {
  DialogRoute<void>? _dialogRoute;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      unawaited(
          (widget.session ?? EngagementPopupSession.instance).showIfAvailable(
        context,
        service: widget.service ?? EngagementService.instance,
        onNavigateRoute: widget.onNavigateRoute == null
            ? null
            : (route) {
                if (mounted) widget.onNavigateRoute?.call(route);
              },
        onRoutePushed: (route) => _dialogRoute = route,
      ));
    });
  }

  @override
  void dispose() {
    final route = _dialogRoute;
    final navigator = route?.navigator;
    if (route != null && navigator != null && route.isActive) {
      // Avoid mutating the navigator while it may be disposing a route.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (navigator.mounted && route.isActive) navigator.removeRoute(route);
      });
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
