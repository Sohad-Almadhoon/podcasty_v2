import 'api_client.dart';

/// Model for podcast analytics
class Analytics {
  final int views;
  final int likes;
  final int comments;
  final int bookmarks;
  final int shares;
  final Map<String, int>? viewsByDay;
  
  Analytics({
    required this.views,
    required this.likes,
    required this.comments,
    required this.bookmarks,
    required this.shares,
    this.viewsByDay,
  });
  
  factory Analytics.fromJson(Map<String, dynamic> json) {
    return Analytics(
      views: json['views'] ?? 0,
      likes: json['likes'] ?? 0,
      comments: json['comments'] ?? 0,
      bookmarks: json['bookmarks'] ?? 0,
      shares: json['shares'] ?? 0,
      viewsByDay: json['views_by_day'] != null 
        ? Map<String, int>.from(json['views_by_day'])
        : null,
    );
  }
}

/// Service for analytics-related API operations
class AnalyticsService {
  /// Fetch analytics for a podcast
  static Future<Analytics> fetchAnalytics(String podcastId) async {
    final data = await ApiClient.request(
      endpoint: '/api/podcasts/$podcastId/analytics',
    );
    
    return Analytics.fromJson(data);
  }
}
