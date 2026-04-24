import 'api_client.dart';

/// Model for a comment
class Comment {
  final String id;
  final String podcastId;
  final String userId;
  final String userName;
  final String? userImage;
  final String content;
  final DateTime createdAt;

  Comment({
    required this.id,
    required this.podcastId,
    required this.userId,
    required this.userName,
    this.userImage,
    required this.content,
    required this.createdAt,
  });

  factory Comment.fromJson(Map<String, dynamic> json) {
    final user = (json['users'] is Map) ? json['users'] as Map : const {};
    return Comment(
      id: json['id']?.toString() ?? '',
      podcastId: json['podcast_id']?.toString() ?? '',
      userId: json['user_id']?.toString() ?? '',
      userName: (user['username'] ?? json['user_name'] ?? '').toString(),
      userImage: (user['avatar_url'] ?? json['user_image']) as String?,
      content: (json['body'] ?? json['content'] ?? '').toString(),
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '') ?? DateTime.now(),
    );
  }
}

/// Service for comment-related API operations
class CommentsService {
  /// Fetch comments for a podcast
  static Future<List<Comment>> fetchComments(String podcastId) async {
    final data = await ApiClient.request(
      endpoint: '/api/podcasts/comments',
      queryParams: {'podcast_id': podcastId},
    );

    if (data is List) {
      return data.map((json) => Comment.fromJson(json)).toList();
    }

    return [];
  }

  /// Create a comment on a podcast
  static Future<Comment> createComment(String podcastId, String content) async {
    final data = await ApiClient.request(
      endpoint: '/api/podcasts/comments/create',
      method: 'POST',
      body: {
        'podcast_id': podcastId,
        'body': content,
      },
    );

    return Comment.fromJson(data);
  }

  /// Delete a comment
  static Future<void> deleteComment(String commentId) async {
    await ApiClient.request(
      endpoint: '/api/comments/delete',
      method: 'DELETE',
      queryParams: {'id': commentId},
    );
  }
}
