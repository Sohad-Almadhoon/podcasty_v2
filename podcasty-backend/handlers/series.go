package handlers

import (
	"encoding/json"
	"fmt"
	"net/http"
	"net/url"
	"strings"

	"github.com/podcasty-go/middleware"
)

// Series represents a podcast series
type Series struct {
	ID          string           `json:"id"`
	UserID      string           `json:"user_id"`
	Title       string           `json:"title"`
	Description string           `json:"description,omitempty"`
	CoverURL    string           `json:"cover_url,omitempty"`
	CreatedAt   string           `json:"created_at"`
	User        *User            `json:"users,omitempty"`
	Episodes    []SeriesEpisode  `json:"series_episodes,omitempty"`
}

// SeriesEpisode links a podcast to a series with season/episode numbers
type SeriesEpisode struct {
	ID            string   `json:"id"`
	SeriesID      string   `json:"series_id"`
	PodcastID     string   `json:"podcast_id"`
	SeasonNumber  int      `json:"season_number"`
	EpisodeNumber int      `json:"episode_number"`
	Podcast       *Podcast `json:"podcasts,omitempty"`
}

// CreateSeriesRequest is the request body for creating a series
type CreateSeriesRequest struct {
	Title       string `json:"title"`
	Description string `json:"description"`
	CoverURL    string `json:"cover_url"`
}

// AddEpisodeRequest is the request body for adding a podcast to a series
type AddEpisodeRequest struct {
	SeriesID      string `json:"series_id"`
	PodcastID     string `json:"podcast_id"`
	SeasonNumber  int    `json:"season_number"`
	EpisodeNumber int    `json:"episode_number"`
}

// SeriesRouter dispatches series endpoints based on path
func (h *Handler) SeriesRouter(w http.ResponseWriter, r *http.Request) {
	path := r.URL.Path

	switch {
	case path == "/api/series/create" && r.Method == http.MethodPost:
		h.CreateSeries(w, r)
	case path == "/api/series/delete" && r.Method == http.MethodDelete:
		h.DeleteSeries(w, r)
	case path == "/api/series/episodes/add" && r.Method == http.MethodPost:
		h.AddSeriesEpisode(w, r)
	case path == "/api/series/episodes/remove" && r.Method == http.MethodDelete:
		h.RemoveSeriesEpisode(w, r)
	case strings.HasPrefix(path, "/api/series/") && len(path) > len("/api/series/"):
		h.GetSeries(w, r)
	default:
		h.ListSeries(w, r)
	}
}

// ListSeries returns all series, optionally filtered by user_id
func (h *Handler) ListSeries(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodGet {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}

	userID := r.URL.Query().Get("user_id")
	query := "series?select=*,users(username,avatar_url),series_episodes(count)&order=created_at.desc"
	if userID != "" {
		query += fmt.Sprintf("&user_id=eq.%s", url.QueryEscape(userID))
	}

	data, err := h.DB.Query(query, http.MethodGet, nil)
	if err != nil {
		http.Error(w, fmt.Sprintf("Failed to fetch series: %v", err), http.StatusInternalServerError)
		return
	}

	var series []json.RawMessage
	if err := json.Unmarshal(data, &series); err != nil {
		http.Error(w, "Failed to parse series", http.StatusInternalServerError)
		return
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(series)
}

// GetSeries returns a single series with all its episodes (including podcast details)
func (h *Handler) GetSeries(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodGet {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}

	pathParts := strings.Split(r.URL.Path, "/")
	if len(pathParts) < 4 {
		http.Error(w, "Invalid series ID", http.StatusBadRequest)
		return
	}
	seriesID := pathParts[3]

	query := fmt.Sprintf(
		"series?id=eq.%s&select=*,users(username,avatar_url),series_episodes(*,podcasts(*,users(username,avatar_url),likes:likes(count)))&series_episodes.order=season_number.asc,episode_number.asc",
		url.QueryEscape(seriesID),
	)

	data, err := h.DB.Query(query, http.MethodGet, nil)
	if err != nil {
		http.Error(w, fmt.Sprintf("Failed to fetch series: %v", err), http.StatusInternalServerError)
		return
	}

	var results []json.RawMessage
	if err := json.Unmarshal(data, &results); err != nil || len(results) == 0 {
		http.Error(w, "Series not found", http.StatusNotFound)
		return
	}

	w.Header().Set("Content-Type", "application/json")
	w.Write(results[0])
}

// CreateSeries creates a new podcast series
func (h *Handler) CreateSeries(w http.ResponseWriter, r *http.Request) {
	userID, ok := middleware.GetUserID(r)
	if !ok || userID == "" {
		http.Error(w, "Unauthorized", http.StatusUnauthorized)
		return
	}

	var req CreateSeriesRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		http.Error(w, "Invalid request body", http.StatusBadRequest)
		return
	}
	if strings.TrimSpace(req.Title) == "" {
		http.Error(w, "Title is required", http.StatusBadRequest)
		return
	}

	body := map[string]any{
		"user_id":     userID,
		"title":       strings.TrimSpace(req.Title),
		"description": strings.TrimSpace(req.Description),
		"cover_url":   strings.TrimSpace(req.CoverURL),
	}

	data, err := h.DB.Query("series?select=*", http.MethodPost, body)
	if err != nil {
		http.Error(w, fmt.Sprintf("Failed to create series: %v", err), http.StatusInternalServerError)
		return
	}

	var created []json.RawMessage
	if err := json.Unmarshal(data, &created); err != nil || len(created) == 0 {
		http.Error(w, "Failed to parse created series", http.StatusInternalServerError)
		return
	}

	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusCreated)
	w.Write(created[0])
}

// DeleteSeries deletes a series (owner only)
func (h *Handler) DeleteSeries(w http.ResponseWriter, r *http.Request) {
	userID, ok := middleware.GetUserID(r)
	if !ok || userID == "" {
		http.Error(w, "Unauthorized", http.StatusUnauthorized)
		return
	}

	seriesID := r.URL.Query().Get("id")
	if seriesID == "" {
		http.Error(w, "Missing series id", http.StatusBadRequest)
		return
	}

	// Verify ownership
	checkQuery := fmt.Sprintf("series?id=eq.%s&select=user_id", url.QueryEscape(seriesID))
	data, err := h.DB.Query(checkQuery, http.MethodGet, nil)
	if err != nil {
		http.Error(w, "Database error", http.StatusInternalServerError)
		return
	}
	var rows []map[string]any
	if err := json.Unmarshal(data, &rows); err != nil || len(rows) == 0 {
		http.Error(w, "Series not found", http.StatusNotFound)
		return
	}
	if owner, _ := rows[0]["user_id"].(string); owner != userID {
		http.Error(w, "Forbidden", http.StatusForbidden)
		return
	}

	deleteQuery := fmt.Sprintf("series?id=eq.%s", url.QueryEscape(seriesID))
	if _, err := h.DB.Query(deleteQuery, http.MethodDelete, nil); err != nil {
		http.Error(w, fmt.Sprintf("Failed to delete series: %v", err), http.StatusInternalServerError)
		return
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(map[string]any{"message": "Series deleted", "id": seriesID})
}

// AddSeriesEpisode adds a podcast to a series
func (h *Handler) AddSeriesEpisode(w http.ResponseWriter, r *http.Request) {
	userID, ok := middleware.GetUserID(r)
	if !ok || userID == "" {
		http.Error(w, "Unauthorized", http.StatusUnauthorized)
		return
	}

	var req AddEpisodeRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		http.Error(w, "Invalid request body", http.StatusBadRequest)
		return
	}
	if req.SeriesID == "" || req.PodcastID == "" {
		http.Error(w, "series_id and podcast_id are required", http.StatusBadRequest)
		return
	}
	if req.SeasonNumber < 1 {
		req.SeasonNumber = 1
	}
	if req.EpisodeNumber < 1 {
		req.EpisodeNumber = 1
	}

	body := map[string]any{
		"series_id":      req.SeriesID,
		"podcast_id":     req.PodcastID,
		"season_number":  req.SeasonNumber,
		"episode_number": req.EpisodeNumber,
	}

	data, err := h.DB.Query("series_episodes?select=*", http.MethodPost, body)
	if err != nil {
		if strings.Contains(err.Error(), "duplicate") || strings.Contains(err.Error(), "unique") {
			http.Error(w, "This podcast is already in the series or the season/episode number is taken", http.StatusConflict)
			return
		}
		http.Error(w, fmt.Sprintf("Failed to add episode: %v", err), http.StatusInternalServerError)
		return
	}

	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusCreated)
	w.Write(data)
}

// RemoveSeriesEpisode removes a podcast from a series
func (h *Handler) RemoveSeriesEpisode(w http.ResponseWriter, r *http.Request) {
	userID, ok := middleware.GetUserID(r)
	if !ok || userID == "" {
		http.Error(w, "Unauthorized", http.StatusUnauthorized)
		return
	}

	seriesID := r.URL.Query().Get("series_id")
	podcastID := r.URL.Query().Get("podcast_id")
	if seriesID == "" || podcastID == "" {
		http.Error(w, "series_id and podcast_id are required", http.StatusBadRequest)
		return
	}

	query := fmt.Sprintf("series_episodes?series_id=eq.%s&podcast_id=eq.%s",
		url.QueryEscape(seriesID), url.QueryEscape(podcastID))
	if _, err := h.DB.Query(query, http.MethodDelete, nil); err != nil {
		http.Error(w, fmt.Sprintf("Failed to remove episode: %v", err), http.StatusInternalServerError)
		return
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(map[string]any{"message": "Episode removed"})
}
