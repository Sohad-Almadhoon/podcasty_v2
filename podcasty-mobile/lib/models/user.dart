class User {
  final String id;
  final String name;
  final String email;
  final String? imageUrl;
  final String? bio;
  final int followers;
  final int following;
  final int podcastCount;
  final DateTime createdAt;

  User({
    required this.id,
    required this.name,
    required this.email,
    this.imageUrl,
    this.bio,
    required this.followers,
    required this.following,
    required this.podcastCount,
    required this.createdAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id']?.toString() ?? '',
      name: (json['username'] ?? json['name'] ?? '').toString(),
      email: (json['email'] ?? '').toString(),
      imageUrl: (json['avatar_url'] ?? json['image_url']) as String?,
      bio: json['bio'] as String?,
      followers: (json['followers'] ?? 0) as int,
      following: (json['following'] ?? 0) as int,
      podcastCount: (json['podcast_count'] ?? 0) as int,
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'image_url': imageUrl,
      'bio': bio,
      'followers': followers,
      'following': following,
      'podcast_count': podcastCount,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
