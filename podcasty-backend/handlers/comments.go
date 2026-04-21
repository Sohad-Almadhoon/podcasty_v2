package handlers

import (
	"encoding/json"
	"fmt"
	"net/http"
	"net/url"
	"strings"

	"github.com/podcasty-go/middleware"
)

// CommentType represents a comment in the database
type CommentType struct {
	ID        string `json:"id"`
	PodcastID string `json:"podcast_id"`
	UserID    string `json:"user_id"`
	Body      string `json:"body"`
	CreatedAt string `json:"created_at"`
	UpdatedAt string `json:"updated_at"`
	User      *User  `json:"users,omitempty"`
}

// CreateCommentRequest represents the request body for creating a comment
type CreateCommentRequest struct {
	PodcastID string `json:"podcast_id"`
	Body      string `json:"body"`
}

// GetComments returns all comments for a podcast
func (h *Handler) GetComments(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodGet {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}

	// Get podcast ID from query param
	podcastID := r.URL.Query().Get("podcast_id")
	if podcastID == "" {
		http.Error(w, "Missing podcast_id", http.StatusBadRequest)
		return
	}

	// Query comments with user info
	query := fmt.Sprintf("comments?podcast_id=eq.%s&select=*,users(username,avatar_url)&order=created_at.desc",
		url.QueryEscape(podcastID))
	data, err := h.DB.Query(query, http.MethodGet, nil)
	if err != nil {
		http.Error(w, fmt.Sprintf("Failed to fetch comments: %v", err), http.StatusInternalServerError)
		return
	}

	// Parse response
	var comments []CommentType
	if err := json.Unmarshal(data, &comments); err != nil {
		http.Error(w, fmt.Sprintf("Failed to parse comments: %v", err), http.StatusInternalServerError)
		return
	}

	// Return response
	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(comments)
}

// CreateComment creates a new comment on a podcast
func (h *Handler) CreateComment(w http.ResponseWriter, r *http.Request) {
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
	var req CreateCommentRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		http.Error(w, fmt.Sprintf("Invalid request body: %v", err), http.StatusBadRequest)
		return
	}

	// Validate required fields
	if req.PodcastID == "" {
		http.Error(w, "Missing podcast_id", http.StatusBadRequest)
		return
	}
	if req.Body == "" {
		http.Error(w, "Missing comment body", http.StatusBadRequest)
		return
	}
	if len(req.Body) > 1000 {
		http.Error(w, "Comment body too long (max 1000 characters)", http.StatusBadRequest)
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

	// Create comment
	comment := map[string]any{
		"podcast_id": req.PodcastID,
		"user_id":    userID,
		"body":       req.Body,
	}

	data, err = h.DB.Query("comments?select=*,users(username,avatar_url)", http.MethodPost, comment)
	if err != nil {
		http.Error(w, fmt.Sprintf("Failed to create comment: %v", err), http.StatusInternalServerError)
		return
	}

	// Parse response
	var createdComments []CommentType
	if err := json.Unmarshal(data, &createdComments); err != nil || len(createdComments) == 0 {
		http.Error(w, "Failed to parse created comment", http.StatusInternalServerError)
		return
	}

	// Fire-and-forget email notification to the podcast owner.
	h.notifyOnNewComment(req.PodcastID, userID, req.Body)

	// Return created comment
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusCreated)
	json.NewEncoder(w).Encode(createdComments[0])
}

// DeleteComment deletes a comment (owner only)
func (h *Handler) DeleteComment(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodDelete {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}

	// Get user ID from context
	userID, ok := middleware.GetUserID(r)
	if !ok || userID == "" {
		http.Error(w, "Unauthorized", http.StatusUnauthorized)
		return
	}

	// Get comment ID from query param
	commentID := r.URL.Query().Get("id")
	if commentID == "" {
		pathParts := strings.Split(r.URL.Path, "/")
		if len(pathParts) >= 4 {
			commentID = pathParts[len(pathParts)-1]
		}
	}

	if commentID == "" {
		http.Error(w, "Missing comment ID", http.StatusBadRequest)
		return
	}

	// Check ownership
	checkQuery := fmt.Sprintf("comments?id=eq.%s&select=user_id", url.QueryEscape(commentID))
	data, err := h.DB.Query(checkQuery, http.MethodGet, nil)
	if err != nil {
		http.Error(w, fmt.Sprintf("Failed to check comment: %v", err), http.StatusInternalServerError)
		return
	}

	var comments []map[string]any
	if err := json.Unmarshal(data, &comments); err != nil || len(comments) == 0 {
		http.Error(w, "Comment not found", http.StatusNotFound)
		return
	}

	ownerID, _ := comments[0]["user_id"].(string)
	if ownerID != userID {
		http.Error(w, "Forbidden: You can only delete your own comments", http.StatusForbidden)
		return
	}

	// Delete comment
	deleteQuery := fmt.Sprintf("comments?id=eq.%s", url.QueryEscape(commentID))
	_, err = h.DB.Query(deleteQuery, http.MethodDelete, nil)
	if err != nil {
		http.Error(w, fmt.Sprintf("Failed to delete comment: %v", err), http.StatusInternalServerError)
		return
	}

	// Return response
	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(map[string]any{
		"message": "Comment deleted successfully",
		"id":      commentID,
	})
}
