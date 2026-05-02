import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// Core API client for making HTTP requests to the Go backend
class ApiClient {
  /// Number of in-flight requests that have exceeded the warmup threshold.
  /// UI listens to this to show a "waking server up" banner during Render
  /// free-tier cold starts.
  static final ValueNotifier<int> warmingRequests = ValueNotifier<int>(0);
  static const Duration _warmupThreshold = Duration(seconds: 2);

  /// Base URL resolution order:
  /// 1. `--dart-define=API_BASE_URL=...` at build/run time (e.g. local dev:
  ///    `http://10.0.2.2:8080` for Android emulator, `http://localhost:8080` otherwise)
  /// 2. Default → deployed backend on Render
  static const String _apiBaseUrlOverride = String.fromEnvironment('API_BASE_URL');
  static const String _defaultBaseUrl = 'https://podcasty-backend.onrender.com';

  static String get baseUrl {
    if (_apiBaseUrlOverride.isNotEmpty) {
      return _apiBaseUrlOverride;
    }
    return _defaultBaseUrl;
  }
  
  // Shared preferences key for storing auth token
  static const String _tokenKey = 'auth_token';
  
  /// Get the stored authentication token from SharedPreferences
  static Future<String?> _getAuthToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }
  
  /// Save authentication token to SharedPreferences
  static Future<void> saveAuthToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
  }
  
  /// Clear authentication token from SharedPreferences
  static Future<void> clearAuthToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
  }
  
  /// Make an authenticated API request
  /// 
  /// [endpoint] - API endpoint (e.g., '/api/podcasts')
  /// [method] - HTTP method (GET, POST, PUT, DELETE)
  /// [body] - Request body (optional, will be JSON encoded)
  /// [queryParams] - URL query parameters (optional)
  /// 
  /// Returns the parsed JSON response
  /// Throws [ApiException] on error
  static Future<dynamic> request({
    required String endpoint,
    String method = 'GET',
    Map<String, dynamic>? body,
    Map<String, String>? queryParams,
  }) async {
    return _withWarmupTracking(() async {
      try {
        final token = await _getAuthToken();

        // Build the URL with query parameters
        final uri = _buildUri(endpoint, queryParams);

        // Build headers
        final headers = <String, String>{
          'Content-Type': 'application/json',
        };

        if (token != null) {
          headers['Authorization'] = 'Bearer $token';
        }

        // Make the request
        http.Response response;

        switch (method.toUpperCase()) {
          case 'GET':
            response = await http.get(uri, headers: headers);
            break;
          case 'POST':
            response = await http.post(
              uri,
              headers: headers,
              body: body != null ? jsonEncode(body) : null,
            );
            break;
          case 'PUT':
            response = await http.put(
              uri,
              headers: headers,
              body: body != null ? jsonEncode(body) : null,
            );
            break;
          case 'DELETE':
            response = await http.delete(uri, headers: headers);
            break;
          default:
            throw ApiException('Unsupported HTTP method: $method');
        }

        return _handleResponse(response);
      } catch (e) {
        if (e is ApiException) rethrow;
        throw ApiException('Network error: $e');
      }
    });
  }
  
  /// Make a public API request (no authentication required)
  static Future<dynamic> publicRequest({
    required String endpoint,
    String method = 'GET',
    Map<String, String>? queryParams,
  }) async {
    return _withWarmupTracking(() async {
      try {
        final uri = _buildUri(endpoint, queryParams);

        final headers = <String, String>{
          'Content-Type': 'application/json',
        };

        http.Response response;

        switch (method.toUpperCase()) {
          case 'GET':
            response = await http.get(uri, headers: headers);
            break;
          default:
            throw ApiException('Unsupported HTTP method for public request: $method');
        }

        return _handleResponse(response);
      } catch (e) {
        if (e is ApiException) rethrow;
        throw ApiException('Network error: $e');
      }
    });
  }

  /// Wraps an async API call with cold-start tracking. If the call exceeds
  /// [_warmupThreshold] the [warmingRequests] counter is incremented so the UI
  /// can surface a "waking server up" banner; the counter is decremented in a
  /// finally block once the call completes (success or failure).
  static Future<T> _withWarmupTracking<T>(Future<T> Function() action) async {
    var warming = false;
    final timer = Timer(_warmupThreshold, () {
      warming = true;
      warmingRequests.value = warmingRequests.value + 1;
    });
    try {
      return await action();
    } finally {
      timer.cancel();
      if (warming) {
        warmingRequests.value = warmingRequests.value - 1;
      }
    }
  }
  
  /// Build URI with query parameters
  static Uri _buildUri(String endpoint, Map<String, String>? queryParams) {
    final url = '$baseUrl$endpoint';
    
    if (queryParams != null && queryParams.isNotEmpty) {
      return Uri.parse(url).replace(queryParameters: queryParams);
    }
    
    return Uri.parse(url);
  }
  
  /// Handle HTTP response
  static dynamic _handleResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) {
        return null;
      }
      return jsonDecode(response.body);
    } else {
      String errorMessage = 'Request failed with status ${response.statusCode}';
      
      try {
        final errorData = jsonDecode(response.body);
        if (errorData['error'] != null) {
          errorMessage = errorData['error'];
        } else if (errorData['message'] != null) {
          errorMessage = errorData['message'];
        }
      } catch (_) {
        // If error response is not JSON, use default message
      }
      
      throw ApiException(
        errorMessage,
        statusCode: response.statusCode,
      );
    }
  }
}

/// Custom exception for API errors
class ApiException implements Exception {
  final String message;
  final int? statusCode;
  
  ApiException(this.message, {this.statusCode});
  
  @override
  String toString() => message;
}
