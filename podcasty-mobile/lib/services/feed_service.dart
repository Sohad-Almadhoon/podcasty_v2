import 'api_client.dart';
import '../models/podcast.dart';

/// Service for personalized feed API operations
class FeedService {
  /// Fetch personalized feed for the current user
  /// 
  /// [page] - Page number for pagination
  /// [limit] - Number of items per page
  static Future<List<Podcast>> fetchFeed({
    int? page,
    int? limit,
  }) async {
    final queryParams = <String, String>{};
    
    if (page != null) queryParams['page'] = page.toString();
    if (limit != null) queryParams['limit'] = limit.toString();
    
    final data = await ApiClient.request(
      endpoint: '/api/feed',
      queryParams: queryParams.isNotEmpty ? queryParams : null,
    );
    
    if (data is List) {
      return data.map((json) => Podcast.fromJson(json)).toList();
    }
    
    return [];
  }
}
