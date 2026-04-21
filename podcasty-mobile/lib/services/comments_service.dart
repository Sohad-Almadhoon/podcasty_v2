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
    return Comment(
      id: json['id'] ?? '',
      podcastId: json['podcast_id'] ?? '',
      userId: json['user_id'] ?? '',
      userName: json['user_name'] ?? '',
      userImage: json['user_image'],
      content: json['content'] ?? '',
      createdAt: DateTime.parse(json['created_at'] ?? DateTime.now().toIso8601String()),
    );
  }
}

/// Service for comment-related API operations
class CommentsService {
  /// Fetch comments for a podcast
  static Future<List<Comment>> fetchComments(String podcastId) async {
    final data = await ApiClient.request(
      endpoint: '/api/podcasts/$podcastId/comments',
    );
    
    if (data is List) {
      return data.map((json) => Comment.fromJson(json)).toList();
    }
    
    return [];
  }
  
  /// Create a comment on a podcast
  static Future<Comment> createComment(String podcastId, String content) async {
    final data = await ApiClient.request(
      endpoint: '/api/podcasts/$podcastId/comments',
      method: 'POST',
      body: {'content': content},
    );
    
    return Comment.fromJson(data);
  }
  
  /// Delete a comment
  static Future<void> deleteComment(String commentId) async {
    await ApiClient.request(
      endpoint: '/api/comments/$commentId',
      method: 'DELETE',
    );
  }
}
