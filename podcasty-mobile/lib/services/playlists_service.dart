import 'api_client.dart';
import '../models/playlist.dart';
import '../models/podcast.dart';

/// Service for playlist-related API operations
class PlaylistsService {
  /// Fetch user's playlists
  static Future<List<Playlist>> fetchPlaylists() async {
    final data = await ApiClient.request(
      endpoint: '/api/playlists',
    );

    if (data is List) {
      return data.map((json) => Playlist.fromJson(json)).toList();
    }

    return [];
  }

  /// Fetch the podcasts inside a playlist, in playlist order.
  ///
  /// The backend keeps items in a separate `playlist_items` table joined to
  /// podcasts, so we hit that endpoint instead of relying on a `podcast_ids`
  /// field on the playlist record (which the API never returns).
  static Future<List<Podcast>> fetchPlaylistItems(String playlistId) async {
    final data = await ApiClient.request(
      endpoint: '/api/playlists/items',
      queryParams: {'playlist_id': playlistId},
    );

    if (data is! List) return [];

    return data
        .map((item) {
          if (item is Map && item['podcasts'] is Map) {
            return Podcast.fromJson(Map<String, dynamic>.from(item['podcasts']));
          }
          return null;
        })
        .whereType<Podcast>()
        .toList();
  }

  /// Create a new playlist
  static Future<Playlist> createPlaylist({
    required String name,
    String? description,
  }) async {
    final data = await ApiClient.request(
      endpoint: '/api/playlists/create',
      method: 'POST',
      body: {
        'name': name,
        if (description != null) 'description': description,
      },
    );

    return Playlist.fromJson(data);
  }

  /// Add a podcast to a playlist
  static Future<void> addToPlaylist(String playlistId, String podcastId) async {
    await ApiClient.request(
      endpoint: '/api/playlists/items/add',
      method: 'POST',
      body: {
        'playlist_id': playlistId,
        'podcast_id': podcastId,
      },
    );
  }

  /// Remove a podcast from a playlist
  static Future<void> removeFromPlaylist(String playlistId, String podcastId) async {
    await ApiClient.request(
      endpoint: '/api/playlists/items/remove',
      method: 'DELETE',
      queryParams: {
        'playlist_id': playlistId,
        'podcast_id': podcastId,
      },
    );
  }
}
