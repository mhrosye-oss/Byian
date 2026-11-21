class CircleType {
  final int? id;
  final String key;
  final String name;
  final String? description;

  const CircleType({
    this.id,
    required this.key,
    required this.name,
    this.description,
  });

  factory CircleType.fromJson(Map<String, dynamic> json) {
    final rawId = json['id'];
    int? parsedId;
    if (rawId is int) {
      parsedId = rawId;
    } else if (rawId != null) {
      parsedId = int.tryParse(rawId.toString());
    }

    return CircleType(
      id: parsedId,
      key: json['key']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      description: json['description']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        if (id != null) 'id': id,
        'key': key,
        'name': name,
        if (description != null) 'description': description,
      };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CircleType &&
          runtimeType == other.runtimeType &&
          key == other.key;

  @override
  int get hashCode => key.hashCode;

  @override
  String toString() => name.isNotEmpty ? name : key;
}

