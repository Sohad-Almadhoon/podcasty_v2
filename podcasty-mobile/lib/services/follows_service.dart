import 'api_client.dart';

class FollowsService {
  static Future<void> followUser(String userId) async {
    await ApiClient.request(
      endpoint: '/api/users/follow',
      method: 'POST',
      body: {'user_id': userId},
    );
  }

  static Future<void> unfollowUser(String userId) async {
    await ApiClient.request(
      endpoint: '/api/users/unfollow',
      method: 'DELETE',
      queryParams: {'user_id': userId},
    );
  }

  static Future<bool> isFollowing(String userId) async {
    try {
      final data = await ApiClient.request(
        endpoint: '/api/users/follow/status',
        queryParams: {'user_id': userId},
      );
      return data['following'] == true;
    } catch (e) {
      return false;
    }
  }

  /// Returns the list of users that the current user is following.
  /// Backend endpoint returns only the caller's own following list.
  static Future<List<Map<String, dynamic>>> fetchMyFollowing() async {
    final data = await ApiClient.request(
      endpoint: '/api/users/follows',
    );

    if (data is List) {
      return data.cast<Map<String, dynamic>>();
    }

    return [];
  }
}
