/// Model representing an engagement media object.
class EngagementMedia {
  final String? image;
  final String? video;
  final List<dynamic> gallery;

  const EngagementMedia({
    this.image,
    this.video,
    this.gallery = const [],
  });

  factory EngagementMedia.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const EngagementMedia();
    return EngagementMedia(
      image: json['image'] as String?,
      video: json['video'] as String?,
      gallery: (json['gallery'] as List<dynamic>?) ?? const [],
    );
  }

  Map<String, dynamic> toJson() => {
        'image': image,
        'video': video,
        'gallery': gallery,
      };
}

/// Model representing engagement text content.
class EngagementText {
  final String title;
  final String subtitle;

  const EngagementText({
    required this.title,
    required this.subtitle,
  });

  factory EngagementText.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return const EngagementText(title: '', subtitle: '');
    }
    return EngagementText(
      title: (json['title'] ?? '').toString(),
      subtitle: (json['subtitle'] ?? '').toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'title': title,
        'subtitle': subtitle,
      };
}

/// Model representing the target action for an engagement item.
class EngagementAction {
  final String type; // "url" | "screen"
  final String? url;
  final String? screen;
  final String? buttonText;

  const EngagementAction({
    required this.type,
    this.url,
    this.screen,
    this.buttonText,
  });

  factory EngagementAction.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return const EngagementAction(type: '');
    }
    final rawType = (json['type'] ?? '').toString().toLowerCase();
    final rawUrl = json['url'] as String?;
    final rawScreen = (json['screen'] ?? json['target']) as String?;
    final rawButtonText = (json['button_text'] ?? json['label']) as String?;

    return EngagementAction(
      type: rawType,
      url: rawUrl,
      screen: rawScreen ?? (rawType == 'screen' ? rawUrl : null),
      buttonText: rawButtonText,
    );
  }

  Map<String, dynamic> toJson() => {
        'type': type,
        'url': url,
        'screen': screen,
        if (buttonText != null) 'button_text': buttonText,
      };
}

/// Main model representing an Engagement item (Banner or Popup).
class EngagementItem {
  final String id;
  final String uuid;
  final String key;
  final String type; // "banner" | "popup" | etc.
  final String placement;
  final EngagementMedia media;
  final EngagementText text;
  final EngagementAction? action;
  final int displayOrder;

  const EngagementItem({
    required this.id,
    required this.uuid,
    required this.key,
    required this.type,
    required this.placement,
    required this.media,
    required this.text,
    this.action,
    this.displayOrder = 0,
  });

  factory EngagementItem.fromJson(Map<String, dynamic> json) {
    return EngagementItem(
      id: (json['id'] ?? '').toString(),
      uuid: (json['uuid'] ?? '').toString(),
      key: (json['key'] ?? '').toString(),
      type: (json['type'] ?? 'banner').toString(),
      placement: (json['placement'] ?? '').toString(),
      media: EngagementMedia.fromJson(json['media'] as Map<String, dynamic>?),
      text: EngagementText.fromJson(json['text'] as Map<String, dynamic>?),
      action: json['action'] != null
          ? EngagementAction.fromJson(json['action'] as Map<String, dynamic>?)
          : null,
      displayOrder: (json['display_order'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'uuid': uuid,
        'key': key,
        'type': type,
        'placement': placement,
        'media': media.toJson(),
        'text': text.toJson(),
        if (action != null) 'action': action!.toJson(),
        'display_order': displayOrder,
      };
}

/// Response wrapper for the engagement API.
class EngagementResponse {
  final bool success;
  final int count;
  final List<EngagementItem> data;

  const EngagementResponse({
    required this.success,
    required this.count,
    required this.data,
  });

  factory EngagementResponse.fromJson(Map<String, dynamic> json) {
    final list = (json['data'] as List<dynamic>?)
            ?.map((e) => EngagementItem.fromJson(e as Map<String, dynamic>))
            .toList() ??
        [];
    return EngagementResponse(
      success: json['success'] == true,
      count: (json['count'] as num?)?.toInt() ?? list.length,
      data: list,
    );
  }
}
