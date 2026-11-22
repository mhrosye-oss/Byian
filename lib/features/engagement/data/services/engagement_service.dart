import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/services/auth_service.dart';
import '../models/engagement_item.dart';

/// Fetches engagement placements and tracks views using the existing API.
class EngagementService {
  EngagementService(
      {http.Client? client, Future<String?> Function()? tokenProvider})
      : _client = client ?? http.Client(),
        _tokenProvider = tokenProvider ?? AuthService.getToken;

  static final EngagementService instance = EngagementService();
  static const String _baseUrl =
      'https://blueviolet-viper-439935.hostingersite.com/api/v1/engagement';

  final http.Client _client;
  final Future<String?> Function() _tokenProvider;
  final Set<String> _trackedUuids = <String>{};
  final Map<String, Future<bool>> _tracking = <String, Future<bool>>{};

  Future<Map<String, String>> _buildHeaders() async {
    final headers = <String, String>{'Accept': 'application/json'};
    try {
      final token = await _tokenProvider();
      if (token != null && token.trim().isNotEmpty) {
        headers['Authorization'] = 'Bearer ${token.trim()}';
      }
    } catch (_) {
      if (kDebugMode) debugPrint('Engagement: authentication unavailable');
    }
    return headers;
  }

  // Only known non-sensitive scalar metadata may be logged. All other body
  // contents, including non-JSON and arbitrary text, are redacted by default.
  void _debugResponse(String operation, http.Response response) {
    if (!kDebugMode) return;
    var body = '[REDACTED]';
    try {
      final decoded = json.decode(utf8.decode(response.bodyBytes));
      if (decoded is Map<String, dynamic>) {
        final safe = <String, Object>{};
        if (decoded['success'] is bool) safe['success'] = decoded['success'];
        if (decoded['count'] is int) safe['count'] = decoded['count'];
        safe['remaining_body'] = '[REDACTED]';
        body = json.encode(safe);
      }
    } catch (_) {
      // The entire body remains redacted.
    }
    debugPrint(
        'Engagement $operation: status ${response.statusCode}, body: $body');
  }

  Future<List<EngagementItem>> fetchEngagementItems(String placementKey) async {
    try {
      final uri = Uri.parse('$_baseUrl/$placementKey');
      final response = await _client
          .get(uri, headers: await _buildHeaders())
          .timeout(const Duration(seconds: 10));
      _debugResponse('fetch', response);
      if (response.statusCode >= 200 && response.statusCode < 300) {
        final decoded = json.decode(utf8.decode(response.bodyBytes));
        if (decoded is Map<String, dynamic>) {
          final result = EngagementResponse.fromJson(decoded);
          if (result.success && result.count > 0) {
            final items = result.data;
            items.sort((a, b) => a.displayOrder.compareTo(b.displayOrder));
            return items;
          }
        }
      }
    } catch (_) {
      if (kDebugMode) debugPrint('Engagement fetch failed');
    }
    return <EngagementItem>[];
  }

  /// Concurrent callers share a request; failed views may be retried.
  Future<bool> trackView(String uuid) {
    if (uuid.trim().isEmpty) return Future.value(false);
    if (_trackedUuids.contains(uuid)) return Future.value(true);
    return _tracking.putIfAbsent(uuid, () async {
      try {
        final uri = Uri.parse('$_baseUrl/$uuid/track-view');
        final headers = await _buildHeaders();
        headers['Content-Type'] = 'application/json';
        final response = await _client
            .post(uri, headers: headers)
            .timeout(const Duration(seconds: 8));
        _debugResponse('track-view', response);
        if (response.statusCode >= 200 && response.statusCode < 300) {
          _trackedUuids.add(uuid);
          return true;
        }
      } catch (_) {
        if (kDebugMode) debugPrint('Engagement track-view failed');
      } finally {
        _tracking.remove(uuid);
      }
      return false;
    });
  }

  Future<void> executeAction(
    BuildContext context,
    EngagementAction? action, {
    void Function(String route)? onNavigateRoute,
  }) async {
    if (action == null) return;
    final type = action.type.trim().toLowerCase();
    if (type == 'url') {
      final rawUrl = action.url?.trim();
      if (rawUrl != null && rawUrl.isNotEmpty) {
        try {
          final uri = Uri.parse(rawUrl);
          if (await canLaunchUrl(uri)) {
            await launchUrl(uri, mode: LaunchMode.externalApplication);
          }
        } catch (_) {
          if (kDebugMode) debugPrint('Engagement URL action failed');
        }
      }
    } else if (type == 'screen') {
      final target = (action.screen ?? action.url)?.trim();
      if (target == null || target.isEmpty || !context.mounted) return;
      if (onNavigateRoute != null) {
        onNavigateRoute(target.startsWith('/') ? target.substring(1) : target);
      } else {
        try {
          Navigator.of(context).pushNamed(target);
        } catch (_) {
          if (kDebugMode) debugPrint('Engagement screen action failed');
        }
      }
    }
  }
}
