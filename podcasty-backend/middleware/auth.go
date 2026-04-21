package middleware

import (
	"context"
	"encoding/base64"
	"encoding/json"
	"net/http"
	"strings"
)

// ContextKey is a custom type for context keys
type ContextKey string

const (
	// UserIDKey is the context key for user ID
	UserIDKey ContextKey = "userID"
	// UserEmailKey is the context key for user email
	UserEmailKey ContextKey = "userEmail"
)

// AuthMiddleware verifies the Supabase JWT token
func AuthMiddleware(next http.HandlerFunc) http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		// Get token from Authorization header
		authHeader := r.Header.Get("Authorization")
		if authHeader == "" {
			respondError(w, "Missing authorization header", http.StatusUnauthorized)
			return
		}

		// Extract Bearer token
		parts := strings.Split(authHeader, " ")
		if len(parts) != 2 || parts[0] != "Bearer" {
			respondError(w, "Invalid authorization header format", http.StatusUnauthorized)
			return
		}

		token := parts[1]
		if token == "" {
			respondError(w, "Missing token", http.StatusUnauthorized)
			return
		}

		// Parse the JWT payload (simplified - in production use a JWT library)
		claims, err := parseJWT(token)
		if err != nil {
			println("⚠️  JWT parsing error:", err.Error())
			respondError(w, "Invalid token", http.StatusUnauthorized)
			return
		}

		// Extract user ID from claims
		userID, ok := claims["sub"].(string)
		if !ok || userID == "" {
			respondError(w, "Invalid token claims", http.StatusUnauthorized)
			return
		}

		// Add user info to context
		ctx := context.WithValue(r.Context(), UserIDKey, userID)
		if email, ok := claims["email"].(string); ok {
			ctx = context.WithValue(ctx, UserEmailKey, email)
		}

		// Call next handler with updated context
		next.ServeHTTP(w, r.WithContext(ctx))
	}
}

// OptionalAuthMiddleware adds user info to context if token is present, but doesn't require it
func OptionalAuthMiddleware(next http.HandlerFunc) http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		authHeader := r.Header.Get("Authorization")
		if authHeader != "" {
			parts := strings.Split(authHeader, " ")
			if len(parts) == 2 && parts[0] == "Bearer" {
				token := parts[1]
				if claims, err := parseJWT(token); err == nil {
					if userID, ok := claims["sub"].(string); ok && userID != "" {
						ctx := context.WithValue(r.Context(), UserIDKey, userID)
						if email, ok := claims["email"].(string); ok {
							ctx = context.WithValue(ctx, UserEmailKey, email)
						}
						r = r.WithContext(ctx)
					}
				} else {
					println("⚠️  Optional auth JWT parsing error:", err.Error())
				}
			}
		}
		next.ServeHTTP(w, r)
	}
}

// GetUserID extracts user ID from request context
func GetUserID(r *http.Request) (string, bool) {
	userID, ok := r.Context().Value(UserIDKey).(string)
	return userID, ok
}

// GetUserEmail extracts user email from request context
func GetUserEmail(r *http.Request) (string, bool) {
	email, ok := r.Context().Value(UserEmailKey).(string)
	return email, ok
}

// parseJWT is a simplified JWT parser
// TODO: Replace with proper JWT verification using a library like github.com/golang-jwt/jwt
func parseJWT(token string) (map[string]any, error) {
	// Split token into parts
	parts := strings.Split(token, ".")
	if len(parts) != 3 {
		return nil, http.ErrNotSupported
	}

	// Decode payload (base64 URL encoded)
	payload := parts[1]

	// Add padding if needed
	switch len(payload) % 4 {
	case 2:
		payload += "=="
	case 3:
		payload += "="
	}

	// Decode base64 URL encoding
	decoded, err := base64.RawURLEncoding.DecodeString(parts[1])
	if err != nil {
		// Try with padding if RawURLEncoding fails
		decoded, err = base64.URLEncoding.DecodeString(payload)
		if err != nil {
			return nil, err
		}
	}

	// Parse JSON
	var claims map[string]any
	if err := json.Unmarshal(decoded, &claims); err != nil {
		return nil, err
	}

	return claims, nil
}

// respondError sends a JSON error response
func respondError(w http.ResponseWriter, message string, statusCode int) {
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(statusCode)
	json.NewEncoder(w).Encode(map[string]string{
		"error": message,
	})
}

// CORS middleware to allow Next.js frontend to call the API
func CORS(next http.HandlerFunc) http.HandlerFunc {
	return CORSWithOrigin("*")(next)
}

// CORSWithOrigin creates a CORS middleware with a specific allowed origin
func CORSWithOrigin(allowedOrigin string) func(http.HandlerFunc) http.HandlerFunc {
	return func(next http.HandlerFunc) http.HandlerFunc {
		return func(w http.ResponseWriter, r *http.Request) {
			origin := r.Header.Get("Origin")

			// If specific origin is set and matches, use it; otherwise use the allowed origin
			if allowedOrigin == "*" || origin == allowedOrigin {
				w.Header().Set("Access-Control-Allow-Origin", allowedOrigin)
			} else if origin != "" {
				// If an origin is provided but doesn't match, still allow it if allowedOrigin is "*"
				w.Header().Set("Access-Control-Allow-Origin", origin)
			}

			w.Header().Set("Access-Control-Allow-Methods", "GET, POST, PUT, DELETE, OPTIONS")
			w.Header().Set("Access-Control-Allow-Headers", "Content-Type, Authorization")
			w.Header().Set("Access-Control-Allow-Credentials", "true")
			w.Header().Set("Access-Control-Max-Age", "3600")

			// Handle preflight requests
			if r.Method == "OPTIONS" {
				w.WriteHeader(http.StatusOK)
				return
			}

			next.ServeHTTP(w, r)
		}
	}
}
