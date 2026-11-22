import 'dart:async';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

import '../../../../core/theme/colors.dart';
import '../../data/models/engagement_item.dart';
import '../../data/services/engagement_service.dart';

/// Interactive Carousel / Slider Widget for Engagement Banners.
/// Displays real-time banners fetched from the engagement API.
/// If count == 0, collapses completely with SizedBox.shrink().
class BannerSliderWidget extends StatefulWidget {
  final String placementKey;
  final void Function(String route)? onNavigateRoute;
  final EdgeInsetsGeometry padding;
  final EngagementService? service;

  const BannerSliderWidget({
    super.key,
    this.placementKey = 'home_top_desktop',
    this.onNavigateRoute,
    this.padding = const EdgeInsets.symmetric(horizontal: 16),
    this.service,
  });

  @override
  State<BannerSliderWidget> createState() => _BannerSliderWidgetState();
}

class _BannerSliderWidgetState extends State<BannerSliderWidget> {
  final PageController _pageController = PageController();
  List<EngagementItem> _banners = [];
  bool _isLoading = true;
  int _currentIndex = 0;
  Timer? _autoPlayTimer;
  int _loadGeneration = 0;

  EngagementService get _service =>
      widget.service ?? EngagementService.instance;

  @override
  void initState() {
    super.initState();
    _loadBanners();
  }

  @override
  void didUpdateWidget(covariant BannerSliderWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.placementKey != widget.placementKey ||
        oldWidget.service != widget.service) {
      _autoPlayTimer?.cancel();
      _isLoading = true;
      _banners = [];
      _currentIndex = 0;
      _loadBanners();
    }
  }

  @override
  void dispose() {
    _autoPlayTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _loadBanners() async {
    final generation = ++_loadGeneration;
    final placement = widget.placementKey;
    final items = await _service.fetchEngagementItems(placement);

    if (!mounted || generation != _loadGeneration) return;

    setState(() {
      _banners = items
          .where((item) => item.matchesPlacementAndType(placement, 'banner'))
          .toList();
      _isLoading = false;
    });

    if (_banners.isNotEmpty) {
      // Track view for the initially visible banner
      _service.trackView(_banners.first.uuid);

      // Start auto-play timer if more than one banner exists
      if (_banners.length > 1) {
        _startAutoPlay();
      }
    }
  }

  void _startAutoPlay() {
    _autoPlayTimer?.cancel();
    _autoPlayTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (!mounted || _banners.length <= 1 || !_pageController.hasClients) {
        return;
      }
      final nextPage = (_currentIndex + 1) % _banners.length;
      _pageController.animateToPage(
        nextPage,
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeInOutCubic,
      );
    });
  }

  void _onPageChanged(int index) {
    setState(() {
      _currentIndex = index;
    });
    if (index >= 0 && index < _banners.length) {
      _service.trackView(_banners[index].uuid);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return _buildShimmerPlaceholder();
    }

    if (_banners.isEmpty) {
      return const SizedBox.shrink();
    }

    final screenWidth = MediaQuery.of(context).size.width;
    // Calculate a balanced, responsive banner height
    final bannerHeight = (screenWidth > 600) ? 170.0 : 138.0;

    return Padding(
      padding: widget.padding,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            height: bannerHeight,
            child: PageView.builder(
              controller: _pageController,
              itemCount: _banners.length,
              onPageChanged: _onPageChanged,
              physics: const BouncingScrollPhysics(),
              itemBuilder: (context, index) {
                final item = _banners[index];
                return _buildBannerCard(item);
              },
            ),
          ),
          if (_banners.length > 1) ...[
            const SizedBox(height: 8),
            _buildIndicatorDots(),
          ],
        ],
      ),
    );
  }

  /// Shimmer loading placeholder matching the card design.
  Widget _buildShimmerPlaceholder() {
    final screenWidth = MediaQuery.of(context).size.width;
    final bannerHeight = (screenWidth > 600) ? 170.0 : 138.0;

    return Padding(
      padding: widget.padding,
      child: Shimmer.fromColors(
        baseColor: ItqanColors.surfaceSoft,
        highlightColor: ItqanColors.surface,
        child: Container(
          height: bannerHeight,
          decoration: BoxDecoration(
            color: ItqanColors.surfaceSoft,
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }

  /// Builds a single responsive banner card with Islamic emerald styling.
  Widget _buildBannerCard(EngagementItem item) {
    final hasImage =
        item.media.image != null && item.media.image!.trim().isNotEmpty;

    return GestureDetector(
      onTap: () {
        _service.executeAction(
          context,
          item.action,
          onNavigateRoute: widget.onNavigateRoute,
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 2),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: ItqanColors.emeraldDark.withValues(alpha: 0.12),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // 1. Background (Image or Luxury Emerald Gradient)
              if (hasImage)
                CachedNetworkImage(
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
                      _buildFallbackGradientBackground(),
                )
              else
                _buildFallbackGradientBackground(),

              // 2. Translucent dark overlay to guarantee contrast for Arabic text
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.centerRight,
                    end: Alignment.centerLeft,
                    colors: [
                      ItqanColors.emeraldDark
                          .withValues(alpha: hasImage ? 0.88 : 0.2),
                      ItqanColors.emeraldDark
                          .withValues(alpha: hasImage ? 0.65 : 0.0),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),

              // 3. Text and Action Content (RTL)
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                child: Directionality(
                  textDirection: TextDirection.rtl,
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (item.text.title.isNotEmpty)
                              Text(
                                item.text.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  height: 1.3,
                                ),
                              ),
                            if (item.text.subtitle.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(
                                item.text.subtitle,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.92),
                                  fontSize: 12.5,
                                  height: 1.35,
                                ),
                              ),
                            ],
                            if (item.action != null &&
                                ((item.action!.url != null &&
                                        item.action!.url!.isNotEmpty) ||
                                    (item.action!.screen != null &&
                                        item.action!.screen!.isNotEmpty))) ...[
                              const SizedBox(height: 8),
                              _buildActionPill(item.action!),
                            ],
                          ],
                        ),
                      ),
                      // Decorative Icon on left side if banner has no image
                      if (!hasImage)
                        Padding(
                          padding: const EdgeInsets.only(left: 8),
                          child: Icon(
                            Icons.auto_awesome_rounded,
                            size: 40,
                            color:
                                ItqanColors.goldBright.withValues(alpha: 0.85),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Fallback gradient when no image is provided or loading fails.
  Widget _buildFallbackGradientBackground() {
    return Container(
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
    );
  }

  /// Small golden pill button for the action
  Widget _buildActionPill(EngagementAction action) {
    final label = action.buttonText?.trim().isNotEmpty == true
        ? action.buttonText!
        : (action.type == 'url' ? 'عرض الرابط' : 'فتح الآن');

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: ItqanColors.goldWarm,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 4),
          const Icon(
            Icons.arrow_back_ios_new_rounded,
            size: 9,
            color: Colors.white,
          ),
        ],
      ),
    );
  }

  /// Carousel Dots Indicator
  Widget _buildIndicatorDots() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(_banners.length, (index) {
        final isActive = index == _currentIndex;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.symmetric(horizontal: 3),
          height: 6,
          width: isActive ? 18 : 6,
          decoration: BoxDecoration(
            color: isActive
                ? ItqanColors.goldWarm
                : ItqanColors.muted.withValues(alpha: 0.35),
            borderRadius: BorderRadius.circular(3),
          ),
        );
      }),
    );
  }
}
