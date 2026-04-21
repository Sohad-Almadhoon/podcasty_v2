package handlers

import (
	"encoding/json"
	"fmt"
	"net/http"
	"net/url"

	"github.com/podcasty-go/middleware"
)

// PlayPodcast increments play count and logs the play
func (h *Handler) PlayPodcast(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}

	// Get user ID (optional - can track anonymous plays)
	userID, _ := middleware.GetUserID(r)

	// Parse request body
	var requestBody struct {
		PodcastID string `json:"podcast_id"`
	}

	if err := json.NewDecoder(r.Body).Decode(&requestBody); err != nil {
		http.Error(w, "Invalid request body", http.StatusBadRequest)
		return
	}

	if requestBody.PodcastID == "" {
		http.Error(w, "podcast_id is required", http.StatusBadRequest)
		return
	}

	// First, verify the podcast exists
	query := fmt.Sprintf("podcasts?id=eq.%s&select=id,play_count", url.QueryEscape(requestBody.PodcastID))
	data, err := h.DB.Query(query, http.MethodGet, nil)
	if err != nil {
		http.Error(w, "Error checking podcast: "+err.Error(), http.StatusInternalServerError)
		return
	}

	var existingPodcast []map[string]any
	if err := json.Unmarshal(data, &existingPodcast); err != nil {
		http.Error(w, "Error parsing response: "+err.Error(), http.StatusInternalServerError)
		return
	}

	if len(existingPodcast) == 0 {
		http.Error(w, "Podcast not found", http.StatusNotFound)
		return
	}

	// Get current play count
	currentCount := 0
	if count, ok := existingPodcast[0]["play_count"].(float64); ok {
		currentCount = int(count)
	}

	// Increment play count
	newCount := currentCount + 1
	updateData := map[string]any{
		"play_count": newCount,
	}

	updateQuery := fmt.Sprintf("podcasts?id=eq.%s", url.QueryEscape(requestBody.PodcastID))
	updateResp, err := h.DB.Query(updateQuery, http.MethodPatch, updateData)
	if err != nil {
		http.Error(w, "Error incrementing play count: "+err.Error(), http.StatusInternalServerError)
		return
	}

	var updatedPodcast []map[string]any
	if err := json.Unmarshal(updateResp, &updatedPodcast); err != nil {
		http.Error(w, "Error parsing update response: "+err.Error(), http.StatusInternalServerError)
		return
	}

	// Log the play to plays_log table (optional - only if user is logged in)
	if userID != "" {
		playLog := map[string]any{
			"podcast_id": requestBody.PodcastID,
			"user_id":    userID,
		}

		// Ignore errors for play log - it's not critical
		_, _ = h.DB.Query("plays_log", http.MethodPost, playLog)
	}

	// Return success response
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusOK)
	json.NewEncoder(w).Encode(map[string]any{
		"message":    "Play count incremented",
		"podcast_id": requestBody.PodcastID,
		"play_count": newCount,
	})
}
