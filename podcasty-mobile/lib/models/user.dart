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
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      imageUrl: json['image_url'],
      bio: json['bio'],
      followers: json['followers'] ?? 0,
      following: json['following'] ?? 0,
      podcastCount: json['podcast_count'] ?? 0,
      createdAt: DateTime.parse(json['created_at'] ?? DateTime.now().toIso8601String()),
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
