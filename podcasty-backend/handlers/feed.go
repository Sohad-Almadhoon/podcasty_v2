package handlers

import (
	"encoding/json"
	"fmt"
	"net/http"
	"net/url"
	"strings"

	"github.com/podcasty-go/middleware"
)

// GetFeed returns podcasts from users that the current user is following
func (h *Handler) GetFeed(w http.ResponseWriter, r *http.Request) {
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

	// Get limit from query params
	limit := r.URL.Query().Get("limit")
	if limit == "" {
		limit = "20"
	}

	// First, get the list of users the current user is following
	followsQuery := fmt.Sprintf("follows?follower_id=eq.%s&select=following_id", url.QueryEscape(userID))
	followsData, err := h.DB.Query(followsQuery, http.MethodGet, nil)
	if err != nil {
		http.Error(w, fmt.Sprintf("Failed to fetch follows: %v", err), http.StatusInternalServerError)
		return
	}

	var follows []map[string]any
	if err := json.Unmarshal(followsData, &follows); err != nil {
		http.Error(w, fmt.Sprintf("Failed to parse follows: %v", err), http.StatusInternalServerError)
		return
	}

	// If not following anyone, return empty array
	if len(follows) == 0 {
		w.Header().Set("Content-Type", "application/json")
		json.NewEncoder(w).Encode([]any{})
		return
	}

	// Build a query to get podcasts from followed users
	// Use "or" filter for multiple user IDs
	userIDs := make([]string, 0, len(follows))
	for _, follow := range follows {
		if followingID, ok := follow["following_id"].(string); ok {
			userIDs = append(userIDs, fmt.Sprintf("user_id.eq.%s", url.QueryEscape(followingID)))
		}
	}
	orFilter := strings.Join(userIDs, ",")

	// Query podcasts from followed users
	query := fmt.Sprintf("podcasts?or=(%s)&select=*,users(username,avatar_url),likes:likes(count)&order=created_at.desc&limit=%s",
		orFilter, limit)

	data, err := h.DB.Query(query, http.MethodGet, nil)
	if err != nil {
		http.Error(w, fmt.Sprintf("Failed to fetch feed: %v", err), http.StatusInternalServerError)
		return
	}

	// Parse response
	var podcasts []Podcast
	if err := json.Unmarshal(data, &podcasts); err != nil {
		http.Error(w, fmt.Sprintf("Failed to parse podcasts: %v", err), http.StatusInternalServerError)
		return
	}

	// Return podcasts (even if empty array)
	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(podcasts)
}
