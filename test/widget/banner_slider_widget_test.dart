import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:itqan/features/engagement/data/models/engagement_item.dart';
import 'package:itqan/features/engagement/presentation/widgets/banner_slider_widget.dart';

void main() {
  testWidgets('shows a banner when engagement data is available', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: BannerSliderWidget(
            placementKey: 'home_top_desktop',
            fetchItems: _loadItems,
            onBannerViewed: _ignoreView,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('اختبار البنر'), findsOneWidget);
    expect(find.text('بيانات تجريبية'), findsOneWidget);
  });
}

Future<List<EngagementItem>> _loadItems(String placementKey) async {
  expect(placementKey, 'home_top_desktop');
  return const [
    EngagementItem(
      id: '1',
      uuid: 'banner-1',
      key: 'home-banner',
      type: 'banner',
      placement: 'home_top_desktop',
      media: EngagementMedia(),
      text: EngagementText(title: 'اختبار البنر', subtitle: 'بيانات تجريبية'),
    ),
  ];
}

void _ignoreView(String uuid) {}
