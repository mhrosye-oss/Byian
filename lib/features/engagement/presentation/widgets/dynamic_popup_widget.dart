import 'dart:developer' as developer;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/theme/colors.dart';
import '../../data/models/engagement_item.dart';
import '../../data/services/engagement_service.dart';

/// Dynamic Modal Popup Dialog for Engagement / Welcome Popups.
/// Automatically shown once based on SharedPreferences state.
class DynamicPopupWidget extends StatelessWidget {
  final EngagementItem item;
  final void Function(String route)? onNavigateRoute;

  const DynamicPopupWidget({
    super.key,
    required this.item,
    this.onNavigateRoute,
  });

  /// Checks if a popup should be displayed and opens the dialog if so.
  /// Uses SharedPreferences to ensure it is only shown once.
  static Future<void> showIfAvailable(
    BuildContext context, {
    String placementKey = 'welcome_popup',
    void Function(String route)? onNavigateRoute,
  }) async {
    try {
      final items =
          await EngagementService.instance.fetchEngagementItems(placementKey);
      if (items.isEmpty) return;

      final targetItem = items.first;
      final prefs = await SharedPreferences.getInstance();
      final storageKey = 'shown_engagement_popup_${targetItem.uuid}';

      // Check if this specific popup has already been displayed
      final alreadyShown = prefs.getBool(storageKey) ?? false;
      if (alreadyShown) return;

      if (!context.mounted) return;

      // Mark as shown in SharedPreferences
      await prefs.setBool(storageKey, true);

      // Track view analytics
      EngagementService.instance.trackView(targetItem.uuid);

      if (!context.mounted) return;

      // Show Dialog
      await showDialog<void>(
        context: context,
        barrierDismissible: true,
        barrierColor: Colors.black.withValues(alpha: 0.65),
        builder: (ctx) => DynamicPopupWidget(
          item: targetItem,
          onNavigateRoute: onNavigateRoute,
        ),
      );
    } catch (e, stackTrace) {
      developer.log(
        'Failed to show engagement popup for $placementKey: $e',
        name: 'DynamicPopupWidget',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasImage =
        item.media.image != null && item.media.image!.trim().isNotEmpty;
    final screenWidth = MediaQuery.of(context).size.width;
    final dialogWidth = screenWidth > 500 ? 420.0 : screenWidth * 0.88;

    return Center(
      child: Material(
        color: Colors.transparent,
        child: Container(
          width: dialogWidth,
          margin: const EdgeInsets.symmetric(horizontal: 20),
          decoration: BoxDecoration(
            color: ItqanColors.surface,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Stack(
              children: [
                Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // 1. Popup Image (if available) or Decorative Header
                    if (hasImage)
                      SizedBox(
                        height: 180,
                        width: double.infinity,
                        child: CachedNetworkImage(
                          imageUrl: item.media.image!.trim(),
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Container(
                            color: ItqanColors.emeraldDark,
                            child: const Center(
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                    ItqanColors.goldBright),
                              ),
                            ),
                          ),
                          errorWidget: (context, url, error) =>
                              _buildDefaultHeader(),
                        ),
                      )
                    else
                      _buildDefaultHeader(),

                    // 2. Text and Action Content (RTL)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
                      child: Directionality(
                        textDirection: TextDirection.rtl,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (item.text.title.isNotEmpty)
                              Text(
                                item.text.title,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: ItqanColors.emeraldDark,
                                  height: 1.3,
                                ),
                              ),
                            if (item.text.subtitle.isNotEmpty) ...[
                              const SizedBox(height: 10),
                              Text(
                                item.text.subtitle,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: ItqanColors.inkSoft,
                                  height: 1.45,
                                ),
                              ),
                            ],
                            const SizedBox(height: 20),

                            // 3. Action Button (Gold / Emerald)
                            if (item.action != null &&
                                ((item.action!.url != null &&
                                        item.action!.url!.isNotEmpty) ||
                                    (item.action!.screen != null &&
                                        item.action!.screen!.isNotEmpty)))
                              SizedBox(
                                width: double.infinity,
                                height: 46,
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: ItqanColors.goldWarm,
                                    foregroundColor: Colors.white,
                                    elevation: 2,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  onPressed: () {
                                    Navigator.of(context).pop();
                                    EngagementService.instance.executeAction(
                                      context,
                                      item.action,
                                      onNavigateRoute: onNavigateRoute,
                                    );
                                  },
                                  child: Text(
                                    item.action!.buttonText?.trim().isNotEmpty ==
                                            true
                                        ? item.action!.buttonText!
                                        : (item.action!.type == 'url'
                                            ? 'عرض الرابط'
                                            : 'استكشف الآن'),
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),

                // 4. Close (X) Button in top-left (for RTL friendly layout)
                Positioned(
                  top: 8,
                  left: 8,
                  child: InkWell(
                    onTap: () => Navigator.of(context).pop(),
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.45),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.close_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Default header when no image is provided
  Widget _buildDefaultHeader() {
    return Container(
      height: 100,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            ItqanColors.emeraldDark,
            ItqanColors.emerald,
          ],
        ),
      ),
      child: Center(
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.12),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.celebration_rounded,
            size: 40,
            color: ItqanColors.goldBright,
          ),
        ),
      ),
    );
  }
}
