import 'api_client.dart';

/// Service for like-related API operations
class LikesService {
  /// Like a podcast
  static Future<void> likePodcast(String podcastId) async {
    await ApiClient.request(
      endpoint: '/api/likes',
      method: 'POST',
      body: {'podcast_id': podcastId},
    );
  }
  
  /// Unlike a podcast
  static Future<void> unlikePodcast(String podcastId) async {
    await ApiClient.request(
      endpoint: '/api/likes/$podcastId',
      method: 'DELETE',
    );
  }
}
