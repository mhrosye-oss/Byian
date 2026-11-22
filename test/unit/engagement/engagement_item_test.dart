import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:itqan/features/engagement/data/models/engagement_item.dart';

void main() {
  test('parses an engagement API item with nested media image URL', () {
    const responseJson = '''
    {
      "success": true,
      "count": 1,
      "data": [
        {
          "id": 42,
          "uuid": "welcome-42",
          "key": "welcome",
          "type": "banner",
          "placement": "home_top_desktop",
          "media": {
            "image": {
              "url": "https://cdn.example.test/banner.webp",
              "alt": "Welcome banner",
              "mime": "image/webp"
            },
            "video": null,
            "gallery": []
          },
          "text": {
            "title": "مرحباً بك",
            "subtitle": "رحلتك تبدأ هنا"
          },
          "action": {
            "type": "url",
            "url": "https://example.test/start",
            "button_text": "ابدأ الآن"
          },
          "display_order": 3
        }
      ]
    }
    ''';

    final response = EngagementResponse.fromJson(
      jsonDecode(responseJson) as Map<String, dynamic>,
    );

    expect(response.success, isTrue);
    expect(response.count, 1);
    expect(response.data, hasLength(1));
    final item = response.data.single;
    expect(item.uuid, 'welcome-42');
    expect(item.media.image, 'https://cdn.example.test/banner.webp');
    expect(item.text.title, 'مرحباً بك');
    expect(item.action?.buttonText, 'ابدأ الآن');
    expect(item.displayOrder, 3);
  });
}
