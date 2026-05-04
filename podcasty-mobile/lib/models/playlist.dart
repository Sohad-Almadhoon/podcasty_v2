class Playlist {
  final String id;
  final String name;
  final String? description;
  final String userId;
  final List<String> podcastIds;
  final int itemCount;
  final DateTime createdAt;

  Playlist({
    required this.id,
    required this.name,
    this.description,
    required this.userId,
    required this.podcastIds,
    required this.itemCount,
    required this.createdAt,
  });

  factory Playlist.fromJson(Map<String, dynamic> json) {
    final ids = List<String>.from(json['podcast_ids'] ?? []);
    final count = json['item_count'];
    return Playlist(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'],
      userId: json['user_id'] ?? '',
      podcastIds: ids,
      itemCount: count is int ? count : ids.length,
      createdAt: DateTime.parse(json['created_at'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'user_id': userId,
      'podcast_ids': podcastIds,
      'item_count': itemCount,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
