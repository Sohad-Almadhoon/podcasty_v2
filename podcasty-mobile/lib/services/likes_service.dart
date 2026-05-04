import 'api_client.dart';

/// Service for like-related API operations
class LikesService {
  /// Like a podcast
  static Future<void> likePodcast(String podcastId) async {
    await ApiClient.request(
      endpoint: '/api/podcasts/like',
      method: 'POST',
      body: {'podcast_id': podcastId},
    );
  }

  /// Unlike a podcast
  static Future<void> unlikePodcast(String podcastId) async {
    await ApiClient.request(
      endpoint: '/api/podcasts/unlike',
      method: 'DELETE',
      queryParams: {'podcast_id': podcastId},
    );
  }

  /// Whether the current user has liked the podcast, plus the public total.
  static Future<({bool liked, int count})> getLikeStatus(String podcastId) async {
    final data = await ApiClient.request(
      endpoint: '/api/likes/status',
      queryParams: {'podcast_id': podcastId},
    );
    if (data is Map) {
      return (
        liked: data['liked'] == true,
        count: (data['count'] as num?)?.toInt() ?? 0,
      );
    }
    return (liked: false, count: 0);
  }
}
