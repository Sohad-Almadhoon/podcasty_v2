package handlers

import (
	"encoding/json"
	"fmt"
	"net/http"
	"net/url"
	"strings"

	"github.com/podcasty-go/middleware"
)

// LikeRequest represents the request body for liking a podcast
type LikeRequest struct {
	PodcastID string `json:"podcast_id"`
}

// LikeResponse represents the like status response
type LikeResponse struct {
	Liked bool `json:"liked"`
	Count int  `json:"count"`
}

// LikePodcast likes a podcast (adds a like)
func (h *Handler) LikePodcast(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}

	// Get user ID from context
	userID, ok := middleware.GetUserID(r)
	if !ok || userID == "" {
		http.Error(w, "Unauthorized", http.StatusUnauthorized)
		return
	}

	// Parse request body
	var req LikeRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		http.Error(w, fmt.Sprintf("Invalid request body: %v", err), http.StatusBadRequest)
		return
	}

	// Validate podcast ID
	if req.PodcastID == "" {
		http.Error(w, "Missing podcast_id", http.StatusBadRequest)
		return
	}

	// Check if podcast exists
	checkQuery := fmt.Sprintf("podcasts?id=eq.%s&select=id", url.QueryEscape(req.PodcastID))
	data, err := h.DB.Query(checkQuery, http.MethodGet, nil)
	if err != nil {
		http.Error(w, fmt.Sprintf("Failed to check podcast: %v", err), http.StatusInternalServerError)
		return
	}

	var podcasts []map[string]any
	if err := json.Unmarshal(data, &podcasts); err != nil || len(podcasts) == 0 {
		http.Error(w, "Podcast not found", http.StatusNotFound)
		return
	}

	// Insert like
	like := map[string]any{
		"podcast_id": req.PodcastID,
		"user_id":    userID,
	}

	data, err = h.DB.Query("likes", http.MethodPost, like)
	if err != nil {
		if strings.Contains(err.Error(), "duplicate") || strings.Contains(err.Error(), "unique") {
			http.Error(w, "You have already liked this podcast", http.StatusConflict)
			return
		}
		http.Error(w, fmt.Sprintf("Failed to like podcast: %v", err), http.StatusInternalServerError)
		return
	}

	// Get updated like count
	countQuery := fmt.Sprintf("likes?podcast_id=eq.%s&select=id", url.QueryEscape(req.PodcastID))
	countData, _ := h.DB.Query(countQuery, http.MethodGet, nil)
	var likes []map[string]any
	json.Unmarshal(countData, &likes)

	// Return response
	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(map[string]any{
		"message": "Podcast liked successfully",
		"liked":   true,
		"count":   len(likes),
	})
}

// UnlikePodcast unlikes a podcast (removes a like)
func (h *Handler) UnlikePodcast(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodDelete && r.Method != http.MethodPost {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}

	// Get user ID from context
	userID, ok := middleware.GetUserID(r)
	if !ok || userID == "" {
		http.Error(w, "Unauthorized", http.StatusUnauthorized)
		return
	}

	// Get podcast ID from query param or body
	podcastID := r.URL.Query().Get("podcast_id")
	if podcastID == "" && r.Method == http.MethodPost {
		var req LikeRequest
		if err := json.NewDecoder(r.Body).Decode(&req); err == nil {
			podcastID = req.PodcastID
		}
	}

	if podcastID == "" {
		http.Error(w, "Missing podcast_id", http.StatusBadRequest)
		return
	}

	// Delete the like
	deleteQuery := fmt.Sprintf("likes?podcast_id=eq.%s&user_id=eq.%s",
		url.QueryEscape(podcastID), url.QueryEscape(userID))
	_, err := h.DB.Query(deleteQuery, http.MethodDelete, nil)
	if err != nil {
		http.Error(w, fmt.Sprintf("Failed to unlike podcast: %v", err), http.StatusInternalServerError)
		return
	}

	// Get updated like count
	countQuery := fmt.Sprintf("likes?podcast_id=eq.%s&select=id", url.QueryEscape(podcastID))
	countData, _ := h.DB.Query(countQuery, http.MethodGet, nil)
	var likes []map[string]any
	json.Unmarshal(countData, &likes)

	// Return response
	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(map[string]any{
		"message": "Podcast unliked successfully",
		"liked":   false,
		"count":   len(likes),
	})
}

// GetLikeStatus returns whether the current user has liked a podcast
func (h *Handler) GetLikeStatus(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodGet {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}

	podcastID := r.URL.Query().Get("podcast_id")
	if podcastID == "" {
		http.Error(w, "Missing podcast_id", http.StatusBadRequest)
		return
	}

	userID, _ := middleware.GetUserID(r)

	// Total likes is public information — fetch it regardless of auth.
	countQuery := fmt.Sprintf("likes?podcast_id=eq.%s&select=id", url.QueryEscape(podcastID))
	countData, _ := h.DB.Query(countQuery, http.MethodGet, nil)
	var allLikes []map[string]any
	json.Unmarshal(countData, &allLikes)

	// Whether *this* user has liked it requires auth. Anonymous viewers haven't.
	liked := false
	if userID != "" {
		likeQuery := fmt.Sprintf("likes?podcast_id=eq.%s&user_id=eq.%s",
			url.QueryEscape(podcastID), url.QueryEscape(userID))
		likeData, _ := h.DB.Query(likeQuery, http.MethodGet, nil)
		var userLikes []map[string]any
		json.Unmarshal(likeData, &userLikes)
		liked = len(userLikes) > 0
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(LikeResponse{
		Liked: liked,
		Count: len(allLikes),
	})
}
