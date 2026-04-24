import 'api_client.dart';

/// Model for podcast analytics
class Analytics {
  final int views;
  final int likes;
  final int comments;
  final int bookmarks;
  final int shares;
  final int uniqueListeners;
  final Map<String, int>? viewsByDay;

  Analytics({
    required this.views,
    required this.likes,
    required this.comments,
    required this.bookmarks,
    required this.shares,
    this.uniqueListeners = 0,
    this.viewsByDay,
  });

  factory Analytics.fromJson(Map<String, dynamic> json) {
    // Backend returns keys: total_plays, total_likes, total_comments,
    // unique_listeners, plays_over_time. Older/alternate shape also supported.
    Map<String, int>? viewsByDay;
    final plays = json['plays_over_time'] ?? json['views_by_day'];
    if (plays is List) {
      final map = <String, int>{};
      for (final entry in plays) {
        if (entry is Map) {
          final date = entry['date']?.toString();
          final count = entry['count'];
          if (date != null && count is num) {
            map[date] = count.toInt();
          }
        }
      }
      if (map.isNotEmpty) viewsByDay = map;
    } else if (plays is Map) {
      viewsByDay = plays.map((k, v) => MapEntry(k.toString(), (v as num).toInt()));
    }

    return Analytics(
      views: (json['total_plays'] ?? json['views'] ?? 0) as int,
      likes: (json['total_likes'] ?? json['likes'] ?? 0) as int,
      comments: (json['total_comments'] ?? json['comments'] ?? 0) as int,
      bookmarks: (json['total_bookmarks'] ?? json['bookmarks'] ?? 0) as int,
      shares: (json['total_shares'] ?? json['shares'] ?? 0) as int,
      uniqueListeners: (json['unique_listeners'] ?? 0) as int,
      viewsByDay: viewsByDay,
    );
  }
}

/// Service for analytics-related API operations
class AnalyticsService {
  /// Fetch analytics for a podcast
  static Future<Analytics> fetchAnalytics(String podcastId) async {
    final data = await ApiClient.request(
      endpoint: '/api/podcasts/analytics',
      queryParams: {'podcast_id': podcastId},
    );

    return Analytics.fromJson(data);
  }
}
