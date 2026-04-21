import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user.dart' as app;
import '../services/api_client.dart';
import '../services/users_service.dart';

class AuthProvider extends ChangeNotifier {
  final SupabaseClient _supabase = Supabase.instance.client;

  app.User? _currentUser;
  bool _isLoading = false;
  bool _isLoggedIn = false;

  app.User? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  bool get isLoggedIn => _isLoggedIn;
  String? get userId => _supabase.auth.currentUser?.id ?? _currentUser?.id;
  String? get accessToken => _supabase.auth.currentSession?.accessToken;

  AuthProvider() {
    // Listen to auth state changes
    _supabase.auth.onAuthStateChange.listen((data) {
      final session = data.session;
      if (session != null) {
        _isLoggedIn = true;
        // Save the Supabase access token for API calls
        ApiClient.saveAuthToken(session.accessToken);
        _fetchUserProfile();
      } else {
        _isLoggedIn = false;
        _currentUser = null;
        ApiClient.clearAuthToken();
      }
      notifyListeners();
    });
  }

  /// Sign in with Google via Supabase browser OAuth (Chrome Custom Tabs on Android).
  /// Returns immediately after launching the browser — the auth state listener
  /// in the constructor picks up the session when the deep link returns.
  Future<void> signInWithGoogle() async {
    _isLoading = true;
    notifyListeners();

    try {
      debugPrint('[OAuth] starting (kIsWeb=$kIsWeb)');
      await _supabase.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: kIsWeb ? null : 'podcasty://login-callback',
        authScreenLaunchMode: kIsWeb
            ? LaunchMode.platformDefault
            : LaunchMode.externalApplication,
      );
      debugPrint('[OAuth] browser launched; awaiting deep-link callback');
    } catch (e, st) {
      debugPrint('[OAuth] ERROR: $e');
      debugPrint('[OAuth] STACK: $st');
      _isLoading = false;
      notifyListeners();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Sign in with email and password via Supabase
  Future<void> login(String email, String password) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.session != null) {
        await ApiClient.saveAuthToken(response.session!.accessToken);
        _isLoggedIn = true;
        await _fetchUserProfile();
      }
    } catch (e) {
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Sign up with email and password
  Future<void> signUp(String email, String password, String name) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await _supabase.auth.signUp(
        email: email,
        password: password,
        data: {'full_name': name},
      );

      if (response.session != null) {
        await ApiClient.saveAuthToken(response.session!.accessToken);
        _isLoggedIn = true;
        await _fetchUserProfile();
      }
    } catch (e) {
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Try to restore existing session
  Future<void> restoreSession() async {
    _isLoading = true;
    notifyListeners();

    try {
      final session = _supabase.auth.currentSession;
      if (session != null) {
        await ApiClient.saveAuthToken(session.accessToken);
        _isLoggedIn = true;
        await _fetchUserProfile();
      }
    } catch (e) {
      _isLoggedIn = false;
      _currentUser = null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Fetch user profile from the Go backend
  Future<void> _fetchUserProfile() async {
    try {
      _currentUser = await UsersService.fetchCurrentUser();
    } catch (e) {
      // Profile might not exist yet - create from Supabase user data
      final supaUser = _supabase.auth.currentUser;
      if (supaUser != null) {
        _currentUser = app.User(
          id: supaUser.id,
          name: supaUser.userMetadata?['full_name'] ?? supaUser.email?.split('@').first ?? 'User',
          email: supaUser.email ?? '',
          imageUrl: supaUser.userMetadata?['avatar_url'],
          followers: 0,
          following: 0,
          podcastCount: 0,
          createdAt: DateTime.now(),
        );
      }
    }
    notifyListeners();
  }

  /// Fetch current user profile (called from login screen)
  Future<void> fetchCurrentUser() async {
    await restoreSession();
  }

  /// Log out
  Future<void> logout() async {
    try {
      await _supabase.auth.signOut(scope: SignOutScope.local);
    } catch (_) {}

    await ApiClient.clearAuthToken();
    _currentUser = null;
    _isLoggedIn = false;
    notifyListeners();
  }
}
