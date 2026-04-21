class Podcast {
  final String id;
  final String title;
  final String description;
  final String audioUrl;
  final String imageUrl;
  final String authorId;
  final String authorName;
  final String? authorImage;
  final int views;
  final int likes;
  final String category;
  final Duration duration;
  final DateTime createdAt;

  Podcast({
    required this.id,
    required this.title,
    required this.description,
    required this.audioUrl,
    required this.imageUrl,
    required this.authorId,
    required this.authorName,
    this.authorImage,
    required this.views,
    required this.likes,
    required this.category,
    required this.duration,
    required this.createdAt,
  });

  factory Podcast.fromJson(Map<String, dynamic> json) {
    final users = json['users'];
    final likesField = json['likes'];
    int parsedLikes = 0;
    if (likesField is int) {
      parsedLikes = likesField;
    } else if (likesField is Map && likesField['count'] is int) {
      parsedLikes = likesField['count'] as int;
    } else if (likesField is List) {
      parsedLikes = likesField.length;
    }

    return Podcast(
      id: json['id'] ?? '',
      title: json['title'] ?? json['podcast_name'] ?? '',
      description: json['description'] ?? '',
      audioUrl: json['audio_url'] ?? '',
      imageUrl: json['image_url'] ?? '',
      authorId: json['author_id'] ?? json['user_id'] ?? (users is Map ? users['id'] ?? '' : ''),
      authorName: json['author_name'] ?? (users is Map ? (users['username'] ?? '') : ''),
      authorImage: json['author_image'] ?? (users is Map ? users['avatar_url'] : null),
      views: json['views'] ?? json['play_count'] ?? 0,
      likes: parsedLikes,
      category: json['category'] ?? '',
      duration: Duration(seconds: json['duration_seconds'] ?? 0),
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'audio_url': audioUrl,
      'image_url': imageUrl,
      'author_id': authorId,
      'author_name': authorName,
      'author_image': authorImage,
      'views': views,
      'likes': likes,
      'category': category,
      'duration_seconds': duration.inSeconds,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
