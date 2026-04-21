package handlers

import (
	"encoding/json"
	"fmt"
	"net/http"
	"net/url"
	"strings"

	"github.com/podcasty-go/middleware"
)

// Bookmark represents a bookmark in the database
type Bookmark struct {
	ID        string   `json:"id"`
	UserID    string   `json:"user_id"`
	PodcastID string   `json:"podcast_id"`
	CreatedAt string   `json:"created_at"`
	Podcast   *Podcast `json:"podcasts,omitempty"`
}

// BookmarkRequest represents the request body for bookmarking
type BookmarkRequest struct {
	PodcastID string `json:"podcast_id"`
}

// GetBookmarks returns all bookmarks for the current user
func (h *Handler) GetBookmarks(w http.ResponseWriter, r *http.Request) {
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

	// Query bookmarks with podcast details
	query := fmt.Sprintf("bookmarks?user_id=eq.%s&select=*,podcasts(*,users(username,avatar_url),likes:likes(count))&order=created_at.desc",
		url.QueryEscape(userID))
	data, err := h.DB.Query(query, http.MethodGet, nil)
	if err != nil {
		http.Error(w, fmt.Sprintf("Failed to fetch bookmarks: %v", err), http.StatusInternalServerError)
		return
	}

	// Parse response
	var bookmarks []Bookmark
	if err := json.Unmarshal(data, &bookmarks); err != nil {
		http.Error(w, fmt.Sprintf("Failed to parse bookmarks: %v", err), http.StatusInternalServerError)
		return
	}

	// Return response
	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(bookmarks)
}

// AddBookmark adds a podcast to bookmarks
func (h *Handler) AddBookmark(w http.ResponseWriter, r *http.Request) {
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
	var req BookmarkRequest
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

	// Insert bookmark
	bookmark := map[string]any{
		"podcast_id": req.PodcastID,
		"user_id":    userID,
	}

	data, err = h.DB.Query("bookmarks", http.MethodPost, bookmark)
	if err != nil {
		if strings.Contains(err.Error(), "duplicate") || strings.Contains(err.Error(), "unique") {
			http.Error(w, "Podcast already bookmarked", http.StatusConflict)
			return
		}
		http.Error(w, fmt.Sprintf("Failed to add bookmark: %v", err), http.StatusInternalServerError)
		return
	}

	// Return response
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusCreated)
	json.NewEncoder(w).Encode(map[string]any{
		"message":    "Podcast bookmarked successfully",
		"podcast_id": req.PodcastID,
	})
}

// RemoveBookmark removes a podcast from bookmarks
func (h *Handler) RemoveBookmark(w http.ResponseWriter, r *http.Request) {
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
		var req BookmarkRequest
		if err := json.NewDecoder(r.Body).Decode(&req); err == nil {
			podcastID = req.PodcastID
		}
	}

	if podcastID == "" {
		http.Error(w, "Missing podcast_id", http.StatusBadRequest)
		return
	}

	// Delete the bookmark
	deleteQuery := fmt.Sprintf("bookmarks?podcast_id=eq.%s&user_id=eq.%s",
		url.QueryEscape(podcastID), url.QueryEscape(userID))
	_, err := h.DB.Query(deleteQuery, http.MethodDelete, nil)
	if err != nil {
		http.Error(w, fmt.Sprintf("Failed to remove bookmark: %v", err), http.StatusInternalServerError)
		return
	}

	// Return response
	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(map[string]any{
		"message":    "Bookmark removed successfully",
		"podcast_id": podcastID,
	})
}

// GetBookmarkStatus checks if a podcast is bookmarked by the current user
func (h *Handler) GetBookmarkStatus(w http.ResponseWriter, r *http.Request) {
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
	// Anonymous viewers don't have a bookmark — short-circuit to false rather
	// than leaking some other user's bookmark state.
	if userID == "" {
		w.Header().Set("Content-Type", "application/json")
		json.NewEncoder(w).Encode(map[string]any{"bookmarked": false})
		return
	}

	query := fmt.Sprintf("bookmarks?podcast_id=eq.%s&user_id=eq.%s",
		url.QueryEscape(podcastID), url.QueryEscape(userID))
	data, _ := h.DB.Query(query, http.MethodGet, nil)
	var bookmarks []map[string]any
	json.Unmarshal(data, &bookmarks)

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(map[string]any{
		"bookmarked": len(bookmarks) > 0,
	})
}
