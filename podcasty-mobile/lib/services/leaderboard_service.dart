import 'api_client.dart';

/// Model for a leaderboard user
class LeaderboardUser {
  final String id;
  final String name;
  final String? imageUrl;
  final int podcastCount;
  final int totalViews;
  final int totalLikes;
  final int rank;
  
  LeaderboardUser({
    required this.id,
    required this.name,
    this.imageUrl,
    required this.podcastCount,
    required this.totalViews,
    required this.totalLikes,
    required this.rank,
  });
  
  factory LeaderboardUser.fromJson(Map<String, dynamic> json) {
    return LeaderboardUser(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      imageUrl: json['image_url'],
      podcastCount: json['podcast_count'] ?? 0,
      totalViews: json['total_views'] ?? 0,
      totalLikes: json['total_likes'] ?? 0,
      rank: json['rank'] ?? 0,
    );
  }
}

/// Service for leaderboard-related API operations
class LeaderboardService {
  /// Fetch leaderboard
  /// 
  /// [limit] - Maximum number of users to return
  /// [period] - Time period (week, month, all)
  static Future<List<LeaderboardUser>> fetchLeaderboard({
    int? limit,
    String? period,
  }) async {
    final queryParams = <String, String>{};
    
    if (limit != null) queryParams['limit'] = limit.toString();
    if (period != null) queryParams['period'] = period;
    
    final data = await ApiClient.request(
      endpoint: '/api/leaderboard',
      queryParams: queryParams.isNotEmpty ? queryParams : null,
    );
    
    if (data is List) {
      return data.map((json) => LeaderboardUser.fromJson(json)).toList();
    }
    
    return [];
  }
}
