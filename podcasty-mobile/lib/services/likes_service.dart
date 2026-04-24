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
}
