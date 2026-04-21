# API Services Documentation

The Flutter app uses a modular, domain-driven API structure for better organization and maintainability, connecting to the Go backend.

## 📁 Structure

```
lib/services/
├── api_client.dart           # Core API request functions
├── api_services.dart         # Barrel export file - import from here!
│
├── podcasts_service.dart     # Podcast CRUD operations
├── bookmarks_service.dart    # Bookmark management
├── likes_service.dart        # Like/unlike operations
├── playlists_service.dart    # Playlist management
├── comments_service.dart     # Comment operations
├── analytics_service.dart    # Analytics data
├── leaderboard_service.dart  # Leaderboard data
├── categories_service.dart   # Category operations
├── users_service.dart        # User data & user podcasts
├── generation_service.dart   # AI content generation
└── feed_service.dart         # Personalized feed
```

## 🎯 Usage

### Import Services

Import from the barrel file for simplicity:

```dart
import 'package:podcasty_flutter/services/api_services.dart';
```

Or import specific services:

```dart
import 'package:podcasty_flutter/services/podcasts_service.dart';
import 'package:podcasty_flutter/services/bookmarks_service.dart';
```

### Authentication

The API client automatically manages authentication tokens using SharedPreferences:

```dart
// Save token after login
await ApiClient.saveAuthToken(token);

// Clear token on logout
await ApiClient.clearAuthToken();
```

### Examples

#### Fetch Podcasts
```dart
// Fetch all podcasts
final podcasts = await PodcastsService.fetchPodcasts();

// Fetch with search
final searchResults = await PodcastsService.fetchPodcasts(
  search: 'flutter',
  limit: 20,
);

// Fetch trending
final trending = await PodcastsService.fetchTrendingPodcasts();

// Fetch single podcast
final podcast = await PodcastsService.fetchPodcastById(podcastId);
```

#### Create Podcast
```dart
final newPodcast = await PodcastsService.createPodcast(
  title: 'My Podcast',
  description: 'Description here',
  audioUrl: audioUrl,
  imageUrl: imageUrl,
  category: 'Technology',
  durationSeconds: 600,
);
```

#### Like/Unlike
```dart
// Like a podcast
await LikesService.likePodcast(podcastId);

// Unlike a podcast
await LikesService.unlikePodcast(podcastId);
```

#### Bookmarks
```dart
// Fetch bookmarks
final bookmarks = await BookmarksService.fetchBookmarks();

// Add bookmark
await BookmarksService.addBookmark(podcastId);

// Remove bookmark
await BookmarksService.removeBookmark(podcastId);
```

#### Playlists
```dart
// Fetch playlists
final playlists = await PlaylistsService.fetchPlaylists();

// Create playlist
final playlist = await PlaylistsService.createPlaylist(
  name: 'My Favorites',
  description: 'Best podcasts',
);

// Add to playlist
await PlaylistsService.addToPlaylist(playlistId, podcastId);

// Remove from playlist
await PlaylistsService.removeFromPlaylist(playlistId, podcastId);
```

#### Comments
```dart
// Fetch comments
final comments = await CommentsService.fetchComments(podcastId);

// Create comment
final comment = await CommentsService.createComment(
  podcastId,
  'Great podcast!',
);

// Delete comment
await CommentsService.deleteComment(commentId);
```

#### AI Generation
```dart
final result = await GenerationService.generatePodcastContent(
  prompt: 'Create a podcast about Flutter development',
  voice: 'professional',
  style: 'educational',
);

print('Audio URL: ${result.audioUrl}');
print('Image URL: ${result.imageUrl}');
```

#### User Profile
```dart
// Fetch current user
final currentUser = await UsersService.fetchCurrentUser();

// Fetch specific user
final user = await UsersService.fetchUser(userId);

// Fetch user's podcasts
final userPodcasts = await UsersService.fetchUserPodcasts(userId);
```

#### Leaderboard
```dart
final topCreators = await LeaderboardService.fetchLeaderboard(
  limit: 10,
  period: 'week',
);
```

#### Analytics
```dart
final analytics = await AnalyticsService.fetchAnalytics(podcastId);
print('Views: ${analytics.views}');
print('Likes: ${analytics.likes}');
```

#### Feed
```dart
final feedPodcasts = await FeedService.fetchFeed(
  page: 1,
  limit: 20,
);
```

#### Categories
```dart
final categories = await CategoriesService.fetchCategories();
```

### With State Management (Provider)

Here's how to use the services with Provider:

```dart
import 'package:flutter/foundation.dart';
import 'package:podcasty_flutter/services/api_services.dart';
import 'package:podcasty_flutter/models/podcast.dart';

class PodcastsProvider extends ChangeNotifier {
  List<Podcast> _podcasts = [];
  bool _isLoading = false;
  String? _error;
  
  List<Podcast> get podcasts => _podcasts;
  bool get isLoading => _isLoading;
  String? get error => _error;
  
  Future<void> loadPodcasts({String? search}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      _podcasts = await PodcastsService.fetchPodcasts(search: search);
    } on ApiException catch (e) {
      _error = e.message;
    } catch (e) {
      _error = 'An error occurred';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  Future<void> likePodcast(String podcastId) async {
    try {
      await LikesService.likePodcast(podcastId);
      
      // Update local state
      final index = _podcasts.indexWhere((p) => p.id == podcastId);
      if (index != -1) {
        // Note: You'd need to add a copyWith method to Podcast model
        // _podcasts[index] = _podcasts[index].copyWith(likes: _podcasts[index].likes + 1);
        notifyListeners();
      }
    } on ApiException catch (e) {
      _error = e.message;
      notifyListeners();
    }
  }
}
```

## 📦 Service Details

### `api_client.dart`
Core HTTP client with authentication handling.

**Methods:**
- `request()` - Make authenticated API request
- `publicRequest()` - Make public (unauthenticated) request
- `saveAuthToken()` - Save auth token
- `clearAuthToken()` - Clear auth token

**Configuration:**
- `baseUrl` - Set to `http://localhost:8080` by default
- Change this for production deployments

### `podcasts_service.dart`
**Methods:**
- `fetchPodcasts()` - List podcasts with filters
- `fetchPodcastById()` - Get single podcast
- `fetchTrendingPodcasts()` - Get trending
- `createPodcast()` - Create new podcast
- `deletePodcast()` - Delete podcast
- `incrementPlayCount()` - Track plays
- `fetchPodcastsPublic()` - Public endpoint
- `fetchPodcastByIdPublic()` - Public endpoint

### `bookmarks_service.dart`
**Methods:**
- `fetchBookmarks()` - Get user's bookmarks
- `addBookmark()` - Bookmark a podcast
- `removeBookmark()` - Remove bookmark

### `likes_service.dart`
**Methods:**
- `likePodcast()` - Like a podcast
- `unlikePodcast()` - Unlike a podcast

### `playlists_service.dart`
**Methods:**
- `fetchPlaylists()` - Get user's playlists
- `createPlaylist()` - Create playlist
- `addToPlaylist()` - Add podcast to playlist
- `removeFromPlaylist()` - Remove from playlist

### `comments_service.dart`
**Methods:**
- `fetchComments()` - Get podcast comments
- `createComment()` - Add comment
- `deleteComment()` - Delete comment

**Model:**
- `Comment` - Comment data model

### `analytics_service.dart`
**Methods:**
- `fetchAnalytics()` - Get podcast analytics

**Model:**
- `Analytics` - Analytics data model

### `leaderboard_service.dart`
**Methods:**
- `fetchLeaderboard()` - Get top creators

**Model:**
- `LeaderboardUser` - Leaderboard user model

### `categories_service.dart`
**Methods:**
- `fetchCategories()` - Get all categories
- `fetchCategoriesPublic()` - Public endpoint

### `users_service.dart`
**Methods:**
- `fetchUser()` - Get user profile
- `fetchUserPodcasts()` - Get user's podcasts
- `fetchCurrentUser()` - Get current user

### `generation_service.dart`
**Methods:**
- `generatePodcastContent()` - AI audio & cover generation

**Model:**
- `GenerationResult` - Generation result model

### `feed_service.dart`
**Methods:**
- `fetchFeed()` - Get personalized feed

## ⚠️ Error Handling

All services throw `ApiException` on errors:

```dart
try {
  final podcasts = await PodcastsService.fetchPodcasts();
} on ApiException catch (e) {
  print('API Error: ${e.message}');
  print('Status Code: ${e.statusCode}');
} catch (e) {
  print('Unexpected error: $e');
}
```

## 🔧 Configuration

### Change Backend URL

Edit `lib/services/api_client.dart`:

```dart
class ApiClient {
  // For production
  static const String baseUrl = 'https://api.podcasty.com';
  
  // For development
  // static const String baseUrl = 'http://localhost:8080';
  
  // For emulator
  // static const String baseUrl = 'http://10.0.2.2:8080'; // Android
  // static const String baseUrl = 'http://127.0.0.1:8080'; // iOS
}
```

## ✨ Benefits

1. **Modular Architecture** - Each domain in its own file
2. **Easy to Navigate** - Know exactly where to find API calls
3. **Type Safety** - Strongly typed models and responses
4. **Error Handling** - Consistent error handling with ApiException
5. **Authentication** - Automatic token management
6. **Public Endpoints** - Support for both authenticated and public requests
7. **Maintainable** - Easy to add new features or modify existing ones
8. **Testable** - Services can be easily mocked for testing

## 🎨 Best Practices

1. **Use try-catch** - Always wrap API calls in try-catch blocks
2. **Handle errors** - Display user-friendly error messages
3. **Loading states** - Show loading indicators during API calls
4. **Optimistic updates** - Update UI optimistically, revert on error
5. **State management** - Use Provider or other state management solutions
6. **Token management** - Handle token expiration and refresh
7. **Network detection** - Check network status before making requests

## 📱 Platform-Specific Notes

### Android
Use `http://10.0.2.2:8080` for localhost when running on emulator

### iOS
Use `http://127.0.0.1:8080` for localhost when running on simulator

### Web
Cannot access localhost - need actual IP or deployed backend

## 🔗 Related Files

- `lib/models/` - Data models (Podcast, User, Playlist)
- `lib/providers/` - State management with Provider
- `lib/screens/` - UI screens that use these services
- `pubspec.yaml` - Dependencies (http, shared_preferences)
