import 'package:supabase_flutter/supabase_flutter.dart' show Supabase;
import 'api_client.dart';
import '../models/user.dart';
import '../models/podcast.dart';

/// Service for user-related API operations
class UsersService {
  /// Fetch user profile
  static Future<User> fetchUser(String userId) async {
    final data = await ApiClient.request(
      endpoint: '/api/users/$userId',
    );

    return User.fromJson(data);
  }

  /// Fetch user's podcasts
  static Future<List<Podcast>> fetchUserPodcasts(String userId) async {
    final data = await ApiClient.request(
      endpoint: '/api/users/$userId/podcasts',
    );

    if (data is List) {
      return data.map((json) => Podcast.fromJson(json)).toList();
    }

    return [];
  }

  /// Fetch current user's profile.
  /// The backend has no /api/users/me route — use the Supabase session's user id.
  static Future<User> fetchCurrentUser() async {
    final supaUser = Supabase.instance.client.auth.currentUser;
    if (supaUser == null) {
      throw ApiException('Not authenticated', statusCode: 401);
    }
    return fetchUser(supaUser.id);
  }

  /// Update the current user's profile. Only non-null fields are sent.
  static Future<User> updateUser(
    String userId, {
    String? username,
    String? avatarUrl,
  }) async {
    final body = <String, dynamic>{};
    if (username != null) body['username'] = username;
    if (avatarUrl != null) body['avatar_url'] = avatarUrl;
    if (body.isEmpty) {
      throw ApiException('Nothing to update');
    }
    final data = await ApiClient.request(
      endpoint: '/api/users/$userId',
      method: 'PUT',
      body: body,
    );
    return User.fromJson(data);
  }
}
