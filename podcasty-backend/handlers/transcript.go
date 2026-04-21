package handlers

import (
	"encoding/json"
	"fmt"
	"net/http"
	"net/url"
)

// GetTranscript returns podcast transcript
func (h *Handler) GetTranscript(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodGet {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}

	podcastID := r.URL.Query().Get("podcast_id")
	if podcastID == "" {
		http.Error(w, "podcast_id parameter is required", http.StatusBadRequest)
		return
	}

	// Check if podcast exists and get its audio URL
	query := fmt.Sprintf("podcasts?id=eq.%s&select=audio_url,podcast_name", url.QueryEscape(podcastID))
	data, err := h.DB.Query(query, http.MethodGet, nil)
	if err != nil {
		http.Error(w, "Database error", http.StatusInternalServerError)
		return
	}

	type PodcastInfo struct {
		AudioURL    string `json:"audio_url"`
		PodcastName string `json:"podcast_name"`
	}

	var podcasts []PodcastInfo
	if err := json.Unmarshal(data, &podcasts); err != nil || len(podcasts) == 0 {
		http.Error(w, "Podcast not found", http.StatusNotFound)
		return
	}

	podcast := podcasts[0]

	// TODO: In production, you would:
	// 1. Check if transcript exists in database
	// 2. If not, generate transcript using OpenAI Whisper API
	// 3. Cache the transcript in database
	// For now, return a placeholder response

	response := map[string]any{
		"podcast_id":   podcastID,
		"podcast_name": podcast.PodcastName,
		"audio_url":    podcast.AudioURL,
		"transcript":   "",
		"status":       "not_available",
		"message":      "Transcript generation not yet implemented. In production, this would use OpenAI Whisper API to transcribe the audio.",
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(response)
}
