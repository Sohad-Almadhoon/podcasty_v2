package handlers

import (
	"encoding/json"
	"fmt"
	"net/http"
	"net/url"
	"slices"
	"sort"
	"strings"
	"time"

	"github.com/podcasty-go/middleware"
)

// Chapter represents a single chapter timestamp on a podcast
type Chapter struct {
	Title string  `json:"title"`
	Start float64 `json:"start"`
}

// LikesAggregate represents the {count: N} object PostgREST returns when you
// select a related table as a count, e.g. `select=likes:likes(count)`.
type LikesAggregate struct {
	Count int `json:"count"`
}

// Podcast represents a podcast in the database
type Podcast struct {
	ID              string           `json:"id"`
	PodcastName     string           `json:"podcast_name"`
	Description     string           `json:"description"`
	ImageURL        string           `json:"image_url"`
	AudioURL        string           `json:"audio_url"`
	PlayCount       int              `json:"play_count"`
	AIVoice         string           `json:"ai_voice"`
	UserID          string           `json:"user_id"`
	Category        string           `json:"category,omitempty"`
	DurationSeconds int              `json:"duration_seconds,omitempty"`
	Chapters        []Chapter        `json:"chapters,omitempty"`
	CreatedAt       time.Time        `json:"created_at"`
	User            *User            `json:"users,omitempty"`
	Likes           []LikesAggregate `json:"likes,omitempty"`
}

// LikeCount returns the embedded aggregate likes count from PostgREST.
func (p Podcast) LikeCount() int {
	if len(p.Likes) == 0 {
		return 0
	}
	return p.Likes[0].Count
}

// CreatePodcastRequest represents the request body for creating a podcast
type CreatePodcastRequest struct {
	PodcastName string    `json:"podcast_name"`
	Description string    `json:"description"`
	AIVoice     string    `json:"ai_voice"`
	ImageURL    string    `json:"image_url"`
	AudioURL    string    `json:"audio_url"`
	Category    string    `json:"category"`
	Chapters    []Chapter `json:"chapters"`
}

// PodcastsHandler routes between list and single podcast endpoints
func (h *Handler) PodcastsHandler(w http.ResponseWriter, r *http.Request) {
	path := r.URL.Path

	// Check if it's a specific podcast request (has ID after /api/podcasts/)
	if len(path) > len("/api/podcasts/") && path != "/api/podcasts/" && path != "/api/podcasts" {
		// Single podcast by ID
		h.GetPodcast(w, r)
	} else {
		// List all podcasts
		h.ListPodcasts(w, r)
	}
}

// ListPodcasts returns all podcasts with optional filtering
// Supports query params: search, category, sort, min_duration, max_duration,
// date_from, date_to, limit, offset
func (h *Handler) ListPodcasts(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodGet {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}

	// Parse query parameters
	query := r.URL.Query()
	search := query.Get("search")
	category := query.Get("category")
	sort := query.Get("sort")
	minDuration := query.Get("min_duration")
	maxDuration := query.Get("max_duration")
	dateFrom := query.Get("date_from")
	dateTo := query.Get("date_to")
	limit := query.Get("limit")
	offset := query.Get("offset")

	// Determine sort order
	// Supported: newest (default), oldest, most_played, most_liked
	orderClause := "created_at.desc"
	switch sort {
	case "oldest":
		orderClause = "created_at.asc"
	case "most_played":
		orderClause = "play_count.desc,created_at.desc"
	case "most_liked":
		// PostgREST can't ORDER BY an aggregated relation count, so we fetch in
		// a sensible default order and post-sort by likes count in Go below.
		orderClause = "play_count.desc,created_at.desc"
	case "newest", "":
		orderClause = "created_at.desc"
	}

	// Build Supabase query
	// Use count for likes instead of fetching all records for better performance
	supabaseQuery := fmt.Sprintf("select=*,users(username,avatar_url),likes:likes(count)&order=%s", orderClause)

	// Add search filter
	if search != "" {
		searchFilter := fmt.Sprintf("&or=(podcast_name.ilike.%%25%s%%25,description.ilike.%%25%s%%25)",
			url.QueryEscape(search), url.QueryEscape(search))
		supabaseQuery += searchFilter
	}

	// Add category filter
	if category != "" {
		supabaseQuery += fmt.Sprintf("&category=eq.%s", url.QueryEscape(category))
	}

	// Duration filters (seconds)
	if minDuration != "" {
		supabaseQuery += fmt.Sprintf("&duration_seconds=gte.%s", url.QueryEscape(minDuration))
	}
	if maxDuration != "" {
		supabaseQuery += fmt.Sprintf("&duration_seconds=lte.%s", url.QueryEscape(maxDuration))
	}

	// Date range filters (ISO 8601: YYYY-MM-DD or full timestamp)
	if dateFrom != "" {
		supabaseQuery += fmt.Sprintf("&created_at=gte.%s", url.QueryEscape(dateFrom))
	}
	if dateTo != "" {
		supabaseQuery += fmt.Sprintf("&created_at=lte.%s", url.QueryEscape(dateTo))
	}

	// Add pagination
	if limit != "" {
		supabaseQuery += fmt.Sprintf("&limit=%s", limit)
	} else {
		supabaseQuery += "&limit=50" // Default limit
	}

	if offset != "" {
		supabaseQuery += fmt.Sprintf("&offset=%s", offset)
	}

	// Query Supabase
	data, err := h.DB.Query(fmt.Sprintf("podcasts?%s", supabaseQuery), http.MethodGet, nil)
	if err != nil {
		http.Error(w, fmt.Sprintf("Failed to fetch podcasts: %v", err), http.StatusInternalServerError)
		return
	}

	// Parse response
	var podcasts []Podcast
	if err := json.Unmarshal(data, &podcasts); err != nil {
		http.Error(w, fmt.Sprintf("Failed to parse podcasts: %v", err), http.StatusInternalServerError)
		return
	}

	// Post-process sort: most_liked needs the aggregated likes count
	if sort == "most_liked" {
		sortPodcastsByLikes(podcasts)
	}

	// Return response
	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(podcasts)
}

// sortPodcastsByLikes orders podcasts in-place by likes count desc, then
// play_count desc as a tiebreaker.
func sortPodcastsByLikes(podcasts []Podcast) {
	sort.SliceStable(podcasts, func(i, j int) bool {
		li, lj := podcasts[i].LikeCount(), podcasts[j].LikeCount()
		if li != lj {
			return li > lj
		}
		return podcasts[i].PlayCount > podcasts[j].PlayCount
	})
}

// GetPodcast returns a single podcast by ID
func (h *Handler) GetPodcast(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodGet {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}

	// Extract podcast ID from URL path
	// Expected format: /api/podcasts/{id}
	pathParts := strings.Split(r.URL.Path, "/")
	if len(pathParts) < 4 {
		http.Error(w, "Invalid podcast ID", http.StatusBadRequest)
		return
	}
	podcastID := pathParts[3]

	// Query Supabase for the podcast with user info and likes
	// Use count for likes instead of fetching all records
	query := fmt.Sprintf("podcasts?id=eq.%s&select=*,users(username,avatar_url),likes:likes(count)", url.QueryEscape(podcastID))
	data, err := h.DB.Query(query, http.MethodGet, nil)
	if err != nil {
		http.Error(w, fmt.Sprintf("Failed to fetch podcast: %v", err), http.StatusInternalServerError)
		return
	}

	// Parse response
	var podcasts []Podcast
	if err := json.Unmarshal(data, &podcasts); err != nil {
		http.Error(w, fmt.Sprintf("Failed to parse podcast: %v", err), http.StatusInternalServerError)
		return
	}

	if len(podcasts) == 0 {
		http.Error(w, "Podcast not found", http.StatusNotFound)
		return
	}

	// Return the podcast
	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(podcasts[0])
}

// CreatePodcast creates a new podcast
func (h *Handler) CreatePodcast(w http.ResponseWriter, r *http.Request) {
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
	var req CreatePodcastRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		http.Error(w, fmt.Sprintf("Invalid request body: %v", err), http.StatusBadRequest)
		return
	}

	// Validate required fields
	if req.PodcastName == "" || req.Description == "" || req.ImageURL == "" || req.AudioURL == "" {
		http.Error(w, "Missing required fields: podcast_name, description, image_url, audio_url", http.StatusBadRequest)
		return
	}

	// Validate AI voice if provided
	validVoices := []string{"alloy", "echo", "fable", "onyx", "nova", "shimmer"}
	if req.AIVoice != "" {
		if !slices.Contains(validVoices, req.AIVoice) {
			http.Error(w, fmt.Sprintf("Invalid ai_voice. Must be one of: %s", strings.Join(validVoices, ", ")), http.StatusBadRequest)
			return
		}
	} else {
		req.AIVoice = "alloy" // Default voice
	}

	// Create podcast object
	podcast := map[string]any{
		"podcast_name": req.PodcastName,
		"description":  req.Description,
		"image_url":    req.ImageURL,
		"audio_url":    req.AudioURL,
		"ai_voice":     req.AIVoice,
		"user_id":      userID,
		"play_count":   0,
	}

	if req.Category != "" {
		podcast["category"] = req.Category
	}

	// Validate and attach chapters
	if len(req.Chapters) > 0 {
		cleaned := make([]Chapter, 0, len(req.Chapters))
		for _, ch := range req.Chapters {
			title := strings.TrimSpace(ch.Title)
			if title == "" || ch.Start < 0 {
				continue
			}
			cleaned = append(cleaned, Chapter{Title: title, Start: ch.Start})
		}
		if len(cleaned) > 0 {
			podcast["chapters"] = cleaned
		}
	}

	// Insert into Supabase
	data, err := h.DB.Query("podcasts?select=*", http.MethodPost, podcast)
	if err != nil {
		http.Error(w, fmt.Sprintf("Failed to create podcast: %v", err), http.StatusInternalServerError)
		return
	}

	// Debug: Log the raw response
	fmt.Printf("📝 Supabase Response: %s\n", string(data))
	fmt.Printf("📝 Response Length: %d bytes\n", len(data))

	// Check if response is empty
	if len(data) == 0 {
		http.Error(w, "Supabase returned empty response - check RLS policies and table exists", http.StatusInternalServerError)
		return
	}

	// Parse response - Supabase might return either an array or a single object
	var createdPodcast Podcast

	// Try to unmarshal as array first
	var createdPodcasts []Podcast
	if err := json.Unmarshal(data, &createdPodcasts); err == nil && len(createdPodcasts) > 0 {
		createdPodcast = createdPodcasts[0]
	} else {
		// Try to unmarshal as single object
		if err := json.Unmarshal(data, &createdPodcast); err != nil {
			http.Error(w, fmt.Sprintf("Failed to parse created podcast: %v. Raw response: %s", err, string(data)), http.StatusInternalServerError)
			return
		}
	}

	// Return created podcast
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusCreated)
	json.NewEncoder(w).Encode(createdPodcast)
}

// DeletePodcast deletes a podcast (owner only)
func (h *Handler) DeletePodcast(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodDelete {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}

	// Get user ID from context (set by auth middleware)
	userID, ok := middleware.GetUserID(r)
	if !ok || userID == "" {
		http.Error(w, "Unauthorized", http.StatusUnauthorized)
		return
	}

	// Extract podcast ID from URL path or query parameter
	podcastID := r.URL.Query().Get("id")
	if podcastID == "" {
		// Try to get from path: /api/podcasts/{id}
		pathParts := strings.Split(r.URL.Path, "/")
		if len(pathParts) >= 4 {
			podcastID = pathParts[3]
		}
	}

	if podcastID == "" {
		http.Error(w, "Missing podcast ID", http.StatusBadRequest)
		return
	}

	// First, check if the podcast exists and belongs to the user
	query := fmt.Sprintf("podcasts?id=eq.%s&select=user_id", url.QueryEscape(podcastID))
	data, err := h.DB.Query(query, http.MethodGet, nil)
	if err != nil {
		http.Error(w, fmt.Sprintf("Failed to fetch podcast: %v", err), http.StatusInternalServerError)
		return
	}

	var podcasts []map[string]any
	if err := json.Unmarshal(data, &podcasts); err != nil {
		http.Error(w, fmt.Sprintf("Failed to parse podcast: %v", err), http.StatusInternalServerError)
		return
	}

	if len(podcasts) == 0 {
		http.Error(w, "Podcast not found", http.StatusNotFound)
		return
	}

	// Check ownership
	ownerID, ok := podcasts[0]["user_id"].(string)
	if !ok || ownerID != userID {
		http.Error(w, "Forbidden: You can only delete your own podcasts", http.StatusForbidden)
		return
	}

	// Delete the podcast
	deleteQuery := fmt.Sprintf("podcasts?id=eq.%s", url.QueryEscape(podcastID))
	_, err = h.DB.Query(deleteQuery, http.MethodDelete, nil)
	if err != nil {
		http.Error(w, fmt.Sprintf("Failed to delete podcast: %v", err), http.StatusInternalServerError)
		return
	}

	// Return success
	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(map[string]any{
		"message": "Podcast deleted successfully",
		"id":      podcastID,
	})
}

// GetTrendingPodcasts returns trending podcasts sorted by play count and likes
func (h *Handler) GetTrendingPodcasts(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodGet {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}

	// Get limit from query params (default: 20)
	limitStr := r.URL.Query().Get("limit")
	limit := 20
	if limitStr != "" {
		if parsedLimit, err := fmt.Sscanf(limitStr, "%d", &limit); err == nil && parsedLimit == 1 {
			if limit < 1 {
				limit = 1
			} else if limit > 100 {
				limit = 100
			}
		}
	}

	// Build Supabase query for trending podcasts
	// Order by play_count descending, limit to recent podcasts
	// Use count for likes instead of fetching all records
	supabaseQuery := fmt.Sprintf("select=*,users(username,avatar_url),likes:likes(count)&order=play_count.desc,created_at.desc&limit=%d", limit)

	// Query Supabase
	data, err := h.DB.Query(fmt.Sprintf("podcasts?%s", supabaseQuery), http.MethodGet, nil)
	if err != nil {
		http.Error(w, fmt.Sprintf("Failed to fetch trending podcasts: %v", err), http.StatusInternalServerError)
		return
	}

	// Parse response
	var podcasts []Podcast
	if err := json.Unmarshal(data, &podcasts); err != nil {
		http.Error(w, fmt.Sprintf("Failed to parse trending podcasts: %v", err), http.StatusInternalServerError)
		return
	}

	// Return response
	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(podcasts)
}
