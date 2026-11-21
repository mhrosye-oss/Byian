import 'dart:convert';
import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/services/auth_service.dart';
import '../models/engagement_item.dart';

/// Service responsible for fetching engagement banners and tracking views.
class EngagementService {
  EngagementService._();
  static final EngagementService instance = EngagementService._();

  static const String _baseUrl =
      'https://blueviolet-viper-439935.hostingersite.com/api/v1/engagement';

  // Cache of UUIDs tracked in the current session to prevent redundant POST calls.
  final Set<String> _trackedUuids = <String>{};

  /// Constructs common headers with authentication token if available.
  Future<Map<String, String>> _buildHeaders() async {
    final headers = <String, String>{
      'Accept': 'application/json',
    };
    try {
      final token = await AuthService.getToken();
      if (token != null && token.trim().isNotEmpty) {
        headers['Authorization'] = 'Bearer ${token.trim()}';
      }
    } catch (e) {
      developer.log('Error reading auth token: $e', name: 'EngagementService');
    }
    return headers;
  }

  /// Fetches engagement items for a specific placement key (e.g. "home_top_desktop", "welcome_popup").
  Future<List<EngagementItem>> fetchEngagementItems(String placementKey) async {
    try {
      final uri = Uri.parse('$_baseUrl/$placementKey');
      final headers = await _buildHeaders();

      final response = await http
          .get(uri, headers: headers)
          .timeout(const Duration(seconds: 10));

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final decoded = json.decode(utf8.decode(response.bodyBytes));
        if (decoded is Map<String, dynamic>) {
          final engagementResponse = EngagementResponse.fromJson(decoded);
          if (engagementResponse.success && engagementResponse.count > 0) {
            final items = engagementResponse.data;
            items.sort((a, b) => a.displayOrder.compareTo(b.displayOrder));
            return items;
          }
        }
      } else {
        developer.log(
          'Failed to fetch engagement for $placementKey: status ${response.statusCode}',
          name: 'EngagementService',
        );
      }
    } catch (e, stack) {
      developer.log(
        'Exception fetching engagement for $placementKey: $e',
        name: 'EngagementService',
        error: e,
        stackTrace: stack,
      );
    }
    return <EngagementItem>[];
  }

  /// Sends a track-view POST request when an item becomes visible on screen.
  Future<bool> trackView(String uuid) async {
    if (uuid.trim().isEmpty) return false;
    if (_trackedUuids.contains(uuid)) {
      return true; // Already tracked during this session
    }

    _trackedUuids.add(uuid);

    try {
      final uri = Uri.parse('$_baseUrl/$uuid/track-view');
      final headers = await _buildHeaders();
      headers['Content-Type'] = 'application/json';

      final response = await http
          .post(uri, headers: headers)
          .timeout(const Duration(seconds: 8));

      if (response.statusCode >= 200 && response.statusCode < 300) {
        developer.log('Successfully tracked view for $uuid', name: 'EngagementService');
        return true;
      } else {
        developer.log(
          'Failed tracking view for $uuid (status ${response.statusCode})',
          name: 'EngagementService',
        );
      }
    } catch (e) {
      developer.log('Error tracking view for $uuid: $e', name: 'EngagementService');
    }
    return false;
  }

  /// Executes the action configured on an engagement item.
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
        } catch (e) {
          developer.log('Could not launch URL $rawUrl: $e', name: 'EngagementService');
        }
      }
    } else if (type == 'screen') {
      final screenTarget = (action.screen ?? action.url)?.trim();
      if (screenTarget != null && screenTarget.isNotEmpty) {
        if (onNavigateRoute != null) {
          // Normalize route target (remove leading slash if present, or match home screen route keys)
          final normalizedRoute = screenTarget.startsWith('/')
              ? screenTarget.substring(1)
              : screenTarget;
          onNavigateRoute(normalizedRoute);
        } else {
          try {
            Navigator.of(context).pushNamed(screenTarget);
          } catch (e) {
            developer.log('Could not navigate to $screenTarget: $e', name: 'EngagementService');
          }
        }
      }
    }
  }
}
