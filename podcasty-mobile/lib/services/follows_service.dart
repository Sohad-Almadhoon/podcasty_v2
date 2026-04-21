import 'api_client.dart';

class FollowsService {
  static Future<void> followUser(String userId) async {
    await ApiClient.request(
      endpoint: '/api/follows',
      method: 'POST',
      body: {'following_id': userId},
    );
  }

  static Future<void> unfollowUser(String userId) async {
    await ApiClient.request(
      endpoint: '/api/follows/$userId',
      method: 'DELETE',
    );
  }

  static Future<bool> isFollowing(String userId) async {
    try {
      final data = await ApiClient.request(
        endpoint: '/api/follows/check/$userId',
      );
      return data['is_following'] == true;
    } catch (e) {
      return false;
    }
  }

  static Future<List<Map<String, dynamic>>> fetchFollowers(String userId) async {
    final data = await ApiClient.request(
      endpoint: '/api/users/$userId/followers',
    );

    if (data is List) {
      return data.cast<Map<String, dynamic>>();
    }

    return [];
  }

  static Future<List<Map<String, dynamic>>> fetchFollowing(String userId) async {
    final data = await ApiClient.request(
      endpoint: '/api/users/$userId/following',
    );

    if (data is List) {
      return data.cast<Map<String, dynamic>>();
    }

    return [];
  }
}
