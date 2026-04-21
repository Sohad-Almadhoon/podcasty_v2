import 'api_client.dart';
import '../models/podcast.dart';

/// Service for bookmark-related API operations
class BookmarksService {
  /// Fetch user's bookmarks
  static Future<List<Podcast>> fetchBookmarks() async {
    final data = await ApiClient.request(
      endpoint: '/api/bookmarks',
    );
    
    if (data is List) {
      return data.map((json) => Podcast.fromJson(json)).toList();
    }
    
    return [];
  }
  
  /// Add a podcast to bookmarks
  static Future<void> addBookmark(String podcastId) async {
    await ApiClient.request(
      endpoint: '/api/bookmarks',
      method: 'POST',
      body: {'podcast_id': podcastId},
    );
  }
  
  /// Remove a podcast from bookmarks
  static Future<void> removeBookmark(String podcastId) async {
    await ApiClient.request(
      endpoint: '/api/bookmarks/$podcastId',
      method: 'DELETE',
    );
  }
}
