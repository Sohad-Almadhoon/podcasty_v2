package handlers

import (
	"encoding/json"
	"fmt"
	"net/http"
	"net/url"
	"time"
)

// GetAnalytics returns podcast analytics
func (h *Handler) GetAnalytics(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodGet {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}

	podcastID := r.URL.Query().Get("podcast_id")
	if podcastID == "" {
		http.Error(w, "podcast_id parameter is required", http.StatusBadRequest)
		return
	}

	// Check if podcast exists and get basic info
	podcastQuery := fmt.Sprintf("podcasts?id=eq.%s&select=id,play_count", url.QueryEscape(podcastID))
	data, err := h.DB.Query(podcastQuery, http.MethodGet, nil)
	if err != nil {
		http.Error(w, "Database error", http.StatusInternalServerError)
		return
	}

	type PodcastInfo struct {
		ID        string `json:"id"`
		PlayCount int    `json:"play_count"`
	}

	var podcasts []PodcastInfo
	if err := json.Unmarshal(data, &podcasts); err != nil || len(podcasts) == 0 {
		http.Error(w, "Podcast not found", http.StatusNotFound)
		return
	}

	podcast := podcasts[0]

	// Get likes count
	likesQuery := fmt.Sprintf("likes?podcast_id=eq.%s&select=id", url.QueryEscape(podcastID))
	likesData, err := h.DB.Query(likesQuery, http.MethodGet, nil)
	likeCount := 0
	if err == nil {
		var likes []map[string]any
		if err := json.Unmarshal(likesData, &likes); err == nil {
			likeCount = len(likes)
		}
	}

	// Get comments count
	commentsQuery := fmt.Sprintf("comments?podcast_id=eq.%s&select=id", url.QueryEscape(podcastID))
	commentsData, err := h.DB.Query(commentsQuery, http.MethodGet, nil)
	commentCount := 0
	if err == nil {
		var comments []map[string]any
		if err := json.Unmarshal(commentsData, &comments); err == nil {
			commentCount = len(comments)
		}
	}

	// Get plays log for analytics
	// Note: This requires plays_log table. For now, we'll use simplified data
	type PlayLog struct {
		PlayedDate string `json:"played_date"`
		UserID     string `json:"user_id"`
	}

	playsQuery := fmt.Sprintf("plays_log?podcast_id=eq.%s&select=played_date,user_id&order=played_date.desc", url.QueryEscape(podcastID))
	playsData, _ := h.DB.Query(playsQuery, http.MethodGet, nil)

	var playsLog []PlayLog
	playsOverTime := []map[string]any{}
	uniqueListeners := 0

	if playsData != nil {
		json.Unmarshal(playsData, &playsLog)

		// Aggregate plays by date
		dateCount := make(map[string]int)
		uniqueUsers := make(map[string]bool)

		for _, play := range playsLog {
			dateCount[play.PlayedDate]++
			if play.UserID != "" {
				uniqueUsers[play.UserID] = true
			}
		}

		// Convert to array
		for date, count := range dateCount {
			playsOverTime = append(playsOverTime, map[string]any{
				"date":  date,
				"count": count,
			})
		}

		uniqueListeners = len(uniqueUsers)
	}

	// Build response
	analytics := map[string]any{
		"podcast_id":       podcastID,
		"total_plays":      podcast.PlayCount,
		"total_likes":      likeCount,
		"total_comments":   commentCount,
		"unique_listeners": uniqueListeners,
		"plays_over_time":  playsOverTime,
		"last_updated":     time.Now().Format(time.RFC3339),
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(analytics)
}
