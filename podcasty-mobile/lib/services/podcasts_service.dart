import 'api_client.dart';
import '../models/podcast.dart';

/// Service for podcast-related API operations
class PodcastsService {
  /// Fetch podcasts with optional filters
  /// 
  /// [search] - Search query for podcast title or description
  /// [category] - Filter by category
  /// [userId] - Filter by user ID
  /// [limit] - Maximum number of podcasts to return
  static Future<List<Podcast>> fetchPodcasts({
    String? search,
    String? category,
    String? userId,
    int? limit,
  }) async {
    final queryParams = <String, String>{};
    
    if (search != null) queryParams['search'] = search;
    if (category != null) queryParams['category'] = category;
    if (userId != null) queryParams['user_id'] = userId;
    if (limit != null) queryParams['limit'] = limit.toString();
    
    final data = await ApiClient.request(
      endpoint: '/api/podcasts',
      queryParams: queryParams.isNotEmpty ? queryParams : null,
    );
    
    if (data is List) {
      return data.map((json) => Podcast.fromJson(json)).toList();
    }
    
    return [];
  }
  
  /// Fetch a single podcast by ID
  static Future<Podcast> fetchPodcastById(String id) async {
    final data = await ApiClient.request(
      endpoint: '/api/podcasts/$id',
    );
    
    return Podcast.fromJson(data);
  }
  
  /// Fetch trending podcasts
  static Future<List<Podcast>> fetchTrendingPodcasts() async {
    final data = await ApiClient.request(
      endpoint: '/api/podcasts/trending',
    );
    
    if (data is List) {
      return data.map((json) => Podcast.fromJson(json)).toList();
    }
    
    return [];
  }
  
  /// Create a new podcast
  static Future<Podcast> createPodcast({
    required String title,
    required String description,
    required String audioUrl,
    required String imageUrl,
    required String category,
    int? durationSeconds,
  }) async {
    final data = await ApiClient.request(
      endpoint: '/api/podcasts',
      method: 'POST',
      body: {
        'title': title,
        'description': description,
        'audio_url': audioUrl,
        'image_url': imageUrl,
        'category': category,
        if (durationSeconds != null) 'duration_seconds': durationSeconds,
      },
    );
    
    return Podcast.fromJson(data);
  }
  
  /// Delete a podcast
  static Future<void> deletePodcast(String podcastId) async {
    await ApiClient.request(
      endpoint: '/api/podcasts/$podcastId',
      method: 'DELETE',
    );
  }
  
  /// Increment play count for a podcast
  static Future<void> incrementPlayCount(String podcastId) async {
    await ApiClient.request(
      endpoint: '/api/podcasts/$podcastId/play',
      method: 'POST',
    );
  }
  
  /// Fetch podcasts (public endpoint, no auth required)
  static Future<List<Podcast>> fetchPodcastsPublic({
    String? search,
    String? category,
    int? limit,
  }) async {
    final queryParams = <String, String>{};
    
    if (search != null) queryParams['search'] = search;
    if (category != null) queryParams['category'] = category;
    if (limit != null) queryParams['limit'] = limit.toString();
    
    final data = await ApiClient.publicRequest(
      endpoint: '/api/podcasts',
      queryParams: queryParams.isNotEmpty ? queryParams : null,
    );
    
    if (data is List) {
      return data.map((json) => Podcast.fromJson(json)).toList();
    }
    
    return [];
  }
  
  /// Fetch a single podcast by ID (public endpoint)
  static Future<Podcast> fetchPodcastByIdPublic(String id) async {
    final data = await ApiClient.publicRequest(
      endpoint: '/api/podcasts/$id',
    );
    
    return Podcast.fromJson(data);
  }
}
