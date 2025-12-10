class MediaItem {
  final String id;
  final String url;
  final String type; // 'video' or 'photo'
  final String name;
  final List<String> tags;
  final DateTime uploadedAt;

  MediaItem({
    required this.id,
    required this.url,
    required this.type,
    required this.name,
    required this.tags,
    required this.uploadedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'url': url,
      'type': type,
      'name': name,
      'tags': tags,
      'uploadedAt': uploadedAt.toIso8601String(),
    };
  }

  factory MediaItem.fromMap(Map<String, dynamic> map) {
    return MediaItem(
      id: map['id'] ?? '',
      url: map['url'] ?? '',
      type: map['type'] ?? 'photo',
      name: map['name'] ?? '',
      tags: List<String>.from(map['tags'] ?? []),
      uploadedAt: DateTime.parse(
        map['uploadedAt'] ?? DateTime.now().toIso8601String(),
      ),
    );
  }
}
