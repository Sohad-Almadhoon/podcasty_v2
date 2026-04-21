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
  
  /// Fetch current user's profile
  static Future<User> fetchCurrentUser() async {
    final data = await ApiClient.request(
      endpoint: '/api/users/me',
    );
    
    return User.fromJson(data);
  }
}
