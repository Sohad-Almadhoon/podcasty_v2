package handlers

import (
	"encoding/json"
	"fmt"
	"net/http"
	"net/url"
	"strings"

	"github.com/podcasty-go/middleware"
)

// Follow represents a follow relationship
type Follow struct {
	ID          string `json:"id"`
	FollowerID  string `json:"follower_id"`
	FollowingID string `json:"following_id"`
	CreatedAt   string `json:"created_at"`
}

// FollowUser follows a user
func (h *Handler) FollowUser(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}

	// Get user ID from context (set by auth middleware)
	userID, ok := middleware.GetUserID(r)
	if !ok || userID == "" {
		http.Error(w, "Unauthorized", http.StatusUnauthorized)
		return
	}

	// Parse request body
	var req struct {
		UserID string `json:"user_id"` // User to follow
	}
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		http.Error(w, "Invalid request body", http.StatusBadRequest)
		return
	}

	if req.UserID == "" {
		http.Error(w, "user_id is required", http.StatusBadRequest)
		return
	}

	// Don't allow following yourself
	if req.UserID == userID {
		http.Error(w, "Cannot follow yourself", http.StatusBadRequest)
		return
	}

	// Check if user to follow exists
	checkQuery := fmt.Sprintf("users?id=eq.%s&select=id", url.QueryEscape(req.UserID))
	data, err := h.DB.Query(checkQuery, http.MethodGet, nil)
	if err != nil {
		http.Error(w, "Database error", http.StatusInternalServerError)
		return
	}

	var users []map[string]any
	if err := json.Unmarshal(data, &users); err != nil || len(users) == 0 {
		http.Error(w, "User not found", http.StatusNotFound)
		return
	}

	// Create follow record
	followData := map[string]any{
		"follower_id":  userID,
		"following_id": req.UserID,
	}

	_, err = h.DB.Query("follows", http.MethodPost, followData)
	if err != nil {
		// Check if already following (conflict)
		if contains(err.Error(), "duplicate") || contains(err.Error(), "unique") {
			http.Error(w, "Already following this user", http.StatusConflict)
			return
		}
		http.Error(w, fmt.Sprintf("Failed to follow user: %v", err), http.StatusInternalServerError)
		return
	}

	// Fire-and-forget email notification.
	h.notifyOnNewFollower(req.UserID, userID)

	response := map[string]any{
		"message":   "User followed successfully",
		"user_id":   req.UserID,
		"following": true,
	}

	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusCreated)
	json.NewEncoder(w).Encode(response)
}

// UnfollowUser unfollows a user
func (h *Handler) UnfollowUser(w http.ResponseWriter, r *http.Request) {
	// Get user ID from context (set by auth middleware)
	userID, ok := middleware.GetUserID(r)
	if !ok || userID == "" {
		http.Error(w, "Unauthorized", http.StatusUnauthorized)
		return
	}

	var followingUserID string

	switch r.Method {
	case http.MethodDelete:
		// Get user_id from query parameter
		followingUserID = r.URL.Query().Get("user_id")
		if followingUserID == "" {
			http.Error(w, "user_id query parameter is required", http.StatusBadRequest)
			return
		}
	case http.MethodPost:
		// Parse request body
		var req struct {
			UserID string `json:"user_id"`
		}
		if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
			http.Error(w, "Invalid request body", http.StatusBadRequest)
			return
		}
		followingUserID = req.UserID
		if followingUserID == "" {
			http.Error(w, "user_id is required", http.StatusBadRequest)
			return
		}
	default:
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}

	// Delete follow record
	query := fmt.Sprintf("follows?follower_id=eq.%s&following_id=eq.%s",
		url.QueryEscape(userID), url.QueryEscape(followingUserID))

	_, err := h.DB.Query(query, http.MethodDelete, nil)
	if err != nil {
		http.Error(w, fmt.Sprintf("Failed to unfollow user: %v", err), http.StatusInternalServerError)
		return
	}

	response := map[string]any{
		"message":   "User unfollowed successfully",
		"user_id":   followingUserID,
		"following": false,
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(response)
}

// GetFollowStatus checks if the current user is following a specific user
func (h *Handler) GetFollowStatus(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodGet {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}

	targetUserID := r.URL.Query().Get("user_id")
	if targetUserID == "" {
		http.Error(w, "user_id query parameter is required", http.StatusBadRequest)
		return
	}

	userID, _ := middleware.GetUserID(r)
	if userID == "" {
		w.Header().Set("Content-Type", "application/json")
		json.NewEncoder(w).Encode(map[string]any{"following": false})
		return
	}

	// Check if following
	query := fmt.Sprintf("follows?follower_id=eq.%s&following_id=eq.%s",
		url.QueryEscape(userID), url.QueryEscape(targetUserID))
	data, _ := h.DB.Query(query, http.MethodGet, nil)

	var follows []map[string]any
	json.Unmarshal(data, &follows)

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(map[string]any{
		"following": len(follows) > 0,
	})
}

// GetFollows returns the list of users that the current user is following
func (h *Handler) GetFollows(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodGet {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}

	// Get user ID from context
	userID, ok := middleware.GetUserID(r)
	if !ok || userID == "" {
		http.Error(w, "Unauthorized", http.StatusUnauthorized)
		return
	}

	// Query follows with user details
	query := fmt.Sprintf("follows?follower_id=eq.%s&select=*,users!follows_following_id_fkey(id,username,avatar_url)&order=created_at.desc",
		url.QueryEscape(userID))
	data, err := h.DB.Query(query, http.MethodGet, nil)
	if err != nil {
		http.Error(w, fmt.Sprintf("Failed to fetch follows: %v", err), http.StatusInternalServerError)
		return
	}

	// Parse response
	var follows []map[string]any
	if err := json.Unmarshal(data, &follows); err != nil {
		http.Error(w, fmt.Sprintf("Failed to parse follows: %v", err), http.StatusInternalServerError)
		return
	}

	// Return follows (even if empty array)
	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(follows)
}

// Helper function to check if string contains substring (case-insensitive)
func contains(s, substr string) bool {
	return len(s) > 0 && len(substr) > 0 && strings.Contains(strings.ToLower(s), strings.ToLower(substr))
}
