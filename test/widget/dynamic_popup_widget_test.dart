import 'dart:convert';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:itqan/features/engagement/data/models/engagement_item.dart';
import 'package:itqan/features/engagement/presentation/widgets/dynamic_popup_widget.dart';

void main() {
  testWidgets('renders popup text and nested image URL from API data', (
    tester,
  ) async {
    const responseJson = '''
    {
      "success": true,
      "placement": "welcome_popup",
      "count": 1,
      "data": [
        {
          "id": 7,
          "uuid": "guest-welcome-7",
          "key": "guest-welcome",
          "type": "popup",
          "placement": "welcome_popup",
          "media": {
            "image": {
              "url": "https://cdn.example.test/welcome.webp",
              "alt": "Welcome"
            }
          },
          "text": {
            "title": "مرحباً بك",
            "subtitle": "اكتشف خدمات إتقان"
          }
        }
      ]
    }
    ''';
    final response = EngagementResponse.fromJson(
      jsonDecode(responseJson) as Map<String, dynamic>,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DynamicPopupWidget(item: response.data.single),
        ),
      ),
    );

    expect(find.text('مرحباً بك'), findsOneWidget);
    expect(find.text('اكتشف خدمات إتقان'), findsOneWidget);
    final image = tester.widget<CachedNetworkImage>(
      find.byType(CachedNetworkImage),
    );
    expect(image.imageUrl, 'https://cdn.example.test/welcome.webp');
  });
}
