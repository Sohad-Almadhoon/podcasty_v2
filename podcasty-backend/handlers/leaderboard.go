package handlers

import (
	"encoding/json"
	"fmt"
	"net/http"
	"sort"
	"strconv"
)

// LeaderboardEntry represents a creator's stats
type LeaderboardEntry struct {
	ID           string `json:"user_id"`
	Username     string `json:"username"`
	AvatarURL    string `json:"avatar_url"`
	PodcastCount int    `json:"podcast_count"`
	TotalPlays   int    `json:"total_plays"`
	TotalLikes   int    `json:"total_likes"`
}

// GetLeaderboard returns the leaderboard
func (h *Handler) GetLeaderboard(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodGet {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}

	// Get query parameters
	limitStr := r.URL.Query().Get("limit")
	orderBy := r.URL.Query().Get("order_by") // "plays", "podcasts", "likes"

	limit := 10 // default limit
	if limitStr != "" {
		if parsedLimit, err := strconv.Atoi(limitStr); err == nil && parsedLimit > 0 {
			limit = parsedLimit
			if limit > 100 {
				limit = 100 // max limit
			}
		}
	}

	// Default to sorting by total plays
	if orderBy == "" {
		orderBy = "plays"
	}

	// Fetch all podcasts with user and likes data
	query := "podcasts?select=user_id,play_count,users(id,username,avatar_url),likes(id)"
	data, err := h.DB.Query(query, http.MethodGet, nil)
	if err != nil {
		http.Error(w, fmt.Sprintf("Failed to fetch podcasts: %v", err), http.StatusInternalServerError)
		return
	}

	// Parse podcasts
	type PodcastWithUser struct {
		UserID    string `json:"user_id"`
		PlayCount int    `json:"play_count"`
		Users     struct {
			ID        string `json:"id"`
			Username  string `json:"username"`
			AvatarURL string `json:"avatar_url"`
		} `json:"users"`
		Likes []map[string]any `json:"likes"`
	}

	var podcasts []PodcastWithUser
	if err := json.Unmarshal(data, &podcasts); err != nil {
		http.Error(w, fmt.Sprintf("Failed to parse podcasts: %v", err), http.StatusInternalServerError)
		return
	}

	// Aggregate stats by user
	userStats := make(map[string]*LeaderboardEntry)
	for _, p := range podcasts {
		if _, exists := userStats[p.UserID]; !exists {
			userStats[p.UserID] = &LeaderboardEntry{
				ID:           p.Users.ID,
				Username:     p.Users.Username,
				AvatarURL:    p.Users.AvatarURL,
				PodcastCount: 0,
				TotalPlays:   0,
				TotalLikes:   0,
			}
		}
		stats := userStats[p.UserID]
		stats.PodcastCount++
		stats.TotalPlays += p.PlayCount
		stats.TotalLikes += len(p.Likes)
	}

	// Convert map to slice
	leaderboard := make([]LeaderboardEntry, 0, len(userStats))
	for _, entry := range userStats {
		leaderboard = append(leaderboard, *entry)
	}

	// Sort based on order_by parameter
	sort.Slice(leaderboard, func(i, j int) bool {
		switch orderBy {
		case "podcasts":
			return leaderboard[i].PodcastCount > leaderboard[j].PodcastCount
		case "likes":
			return leaderboard[i].TotalLikes > leaderboard[j].TotalLikes
		default: // "plays"
			return leaderboard[i].TotalPlays > leaderboard[j].TotalPlays
		}
	})

	// Limit results
	if len(leaderboard) > limit {
		leaderboard = leaderboard[:limit]
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(leaderboard)
}
