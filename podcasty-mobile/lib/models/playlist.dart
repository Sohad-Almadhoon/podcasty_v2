class Playlist {
  final String id;
  final String name;
  final String? description;
  final String userId;
  final List<String> podcastIds;
  final DateTime createdAt;

  Playlist({
    required this.id,
    required this.name,
    this.description,
    required this.userId,
    required this.podcastIds,
    required this.createdAt,
  });

  factory Playlist.fromJson(Map<String, dynamic> json) {
    return Playlist(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'],
      userId: json['user_id'] ?? '',
      podcastIds: List<String>.from(json['podcast_ids'] ?? []),
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
      'created_at': createdAt.toIso8601String(),
    };
  }
}
