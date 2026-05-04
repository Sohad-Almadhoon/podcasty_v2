import 'api_client.dart';
import '../models/podcast.dart';

/// Service for bookmark-related API operations
class BookmarksService {
  /// Fetch user's bookmarks. The API returns Bookmark rows with the embedded
  /// podcast under `podcasts`; unwrap it so callers get podcasts directly.
  static Future<List<Podcast>> fetchBookmarks() async {
    final data = await ApiClient.request(
      endpoint: '/api/bookmarks',
    );

    if (data is List) {
      return data
          .map((row) {
            if (row is Map && row['podcasts'] is Map) {
              return Podcast.fromJson(Map<String, dynamic>.from(row['podcasts']));
            }
            // Fall back to treating the row itself as a podcast for forward
            // compatibility with shape changes.
            return row is Map ? Podcast.fromJson(Map<String, dynamic>.from(row)) : null;
          })
          .whereType<Podcast>()
          .where((p) => p.id.isNotEmpty)
          .toList();
    }

    return [];
  }

  /// Add a podcast to bookmarks
  static Future<void> addBookmark(String podcastId) async {
    await ApiClient.request(
      endpoint: '/api/bookmarks/add',
      method: 'POST',
      body: {'podcast_id': podcastId},
    );
  }

  /// Remove a podcast from bookmarks
  static Future<void> removeBookmark(String podcastId) async {
    await ApiClient.request(
      endpoint: '/api/bookmarks/remove',
      method: 'DELETE',
      queryParams: {'podcast_id': podcastId},
    );
  }

  /// Whether the current user has bookmarked the podcast.
  static Future<bool> getBookmarkStatus(String podcastId) async {
    final data = await ApiClient.request(
      endpoint: '/api/bookmarks/status',
      queryParams: {'podcast_id': podcastId},
    );
    if (data is Map) return data['bookmarked'] == true;
    return false;
  }
}
