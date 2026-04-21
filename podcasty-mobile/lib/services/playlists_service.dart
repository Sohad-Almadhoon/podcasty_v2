import 'api_client.dart';
import '../models/playlist.dart';

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
  
  /// Create a new playlist
  static Future<Playlist> createPlaylist({
    required String name,
    String? description,
  }) async {
    final data = await ApiClient.request(
      endpoint: '/api/playlists',
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
      endpoint: '/api/playlists/$playlistId/podcasts',
      method: 'POST',
      body: {'podcast_id': podcastId},
    );
  }
  
  /// Remove a podcast from a playlist
  static Future<void> removeFromPlaylist(String playlistId, String podcastId) async {
    await ApiClient.request(
      endpoint: '/api/playlists/$playlistId/podcasts/$podcastId',
      method: 'DELETE',
    );
  }
}
