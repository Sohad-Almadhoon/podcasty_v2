package handlers

import (
	"encoding/json"
	"fmt"
	"log"
	"net/http"
	"net/url"
	"strings"

	"github.com/podcasty-go/middleware"
)

// BadgeDefinition describes a badge and its unlock criteria.
type BadgeDefinition struct {
	Key         string `json:"key"`
	Name        string `json:"name"`
	Description string `json:"description"`
	Icon        string `json:"icon"` // emoji
}

// UserBadge is a badge a user has earned.
type UserBadge struct {
	ID       string          `json:"id"`
	UserID   string          `json:"user_id"`
	BadgeKey string          `json:"badge_key"`
	EarnedAt string          `json:"earned_at"`
	Badge    BadgeDefinition `json:"badge"` // enriched client-side from the catalog
}

// Badge catalog — all possible badges. The logic for each is in checkBadges().
var badgeCatalog = map[string]BadgeDefinition{
	"first_podcast": {
		Key: "first_podcast", Name: "Creator",
		Description: "Published your first podcast", Icon: "🎙️",
	},
	"five_podcasts": {
		Key: "five_podcasts", Name: "Prolific",
		Description: "Published 5 podcasts", Icon: "📚",
	},
	"ten_podcasts": {
		Key: "ten_podcasts", Name: "Veteran",
		Description: "Published 10 podcasts", Icon: "🏆",
	},
	"hundred_plays": {
		Key: "hundred_plays", Name: "Rising Star",
		Description: "Your podcasts reached 100 total plays", Icon: "⭐",
	},
	"thousand_plays": {
		Key: "thousand_plays", Name: "Trending",
		Description: "Your podcasts reached 1,000 total plays", Icon: "🔥",
	},
	"first_like": {
		Key: "first_like", Name: "Liked",
		Description: "Received your first like", Icon: "❤️",
	},
	"fifty_likes": {
		Key: "fifty_likes", Name: "Fan Favorite",
		Description: "Received 50 likes across your podcasts", Icon: "💎",
	},
	"first_follower": {
		Key: "first_follower", Name: "Social",
		Description: "Got your first follower", Icon: "👋",
	},
	"ten_followers": {
		Key: "ten_followers", Name: "Influencer",
		Description: "Reached 10 followers", Icon: "🌟",
	},
	"first_comment": {
		Key: "first_comment", Name: "Conversationalist",
		Description: "Left your first comment", Icon: "💬",
	},
	"bookworm": {
		Key: "bookworm", Name: "Bookworm",
		Description: "Bookmarked 10 podcasts", Icon: "🔖",
	},
}

// GetUserBadges returns badges for a user and optionally refreshes them.
func (h *Handler) GetUserBadges(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodGet {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}

	userID := r.URL.Query().Get("user_id")
	// If no user_id param, use the authenticated user
	if userID == "" {
		uid, _ := middleware.GetUserID(r)
		userID = uid
	}
	if userID == "" {
		http.Error(w, "user_id is required", http.StatusBadRequest)
		return
	}

	// Refresh badges for this user (compute new ones they may have earned)
	h.refreshBadges(userID)

	// Fetch earned badges
	query := fmt.Sprintf("user_badges?user_id=eq.%s&select=*&order=earned_at.asc",
		url.QueryEscape(userID))
	data, err := h.DB.Query(query, http.MethodGet, nil)
	if err != nil {
		http.Error(w, "Failed to fetch badges", http.StatusInternalServerError)
		return
	}

	var earned []UserBadge
	if err := json.Unmarshal(data, &earned); err != nil {
		http.Error(w, "Failed to parse badges", http.StatusInternalServerError)
		return
	}

	// Enrich with badge metadata from the catalog
	for i := range earned {
		if def, ok := badgeCatalog[earned[i].BadgeKey]; ok {
			earned[i].Badge = def
		}
	}

	// Build response: all possible badges + which ones this user has
	type BadgeResponse struct {
		Earned  []UserBadge       `json:"earned"`
		Catalog []BadgeDefinition `json:"catalog"`
	}

	catalog := make([]BadgeDefinition, 0, len(badgeCatalog))
	for _, def := range badgeCatalog {
		catalog = append(catalog, def)
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(BadgeResponse{
		Earned:  earned,
		Catalog: catalog,
	})
}

// refreshBadges checks all badge criteria for a user and awards any new ones.
func (h *Handler) refreshBadges(userID string) {
	// Gather stats
	podcastCount := h.countRows(fmt.Sprintf("podcasts?user_id=eq.%s&select=id", url.QueryEscape(userID)))
	totalPlays := h.sumPlays(userID)
	totalLikes := h.countLikesReceived(userID)
	followerCount := h.countRows(fmt.Sprintf("follows?following_id=eq.%s&select=id", url.QueryEscape(userID)))
	commentsMade := h.countRows(fmt.Sprintf("comments?user_id=eq.%s&select=id", url.QueryEscape(userID)))
	bookmarkCount := h.countRows(fmt.Sprintf("bookmarks?user_id=eq.%s&select=id", url.QueryEscape(userID)))

	// Check each badge
	checks := map[string]bool{
		"first_podcast":  podcastCount >= 1,
		"five_podcasts":  podcastCount >= 5,
		"ten_podcasts":   podcastCount >= 10,
		"hundred_plays":  totalPlays >= 100,
		"thousand_plays": totalPlays >= 1000,
		"first_like":     totalLikes >= 1,
		"fifty_likes":    totalLikes >= 50,
		"first_follower": followerCount >= 1,
		"ten_followers":  followerCount >= 10,
		"first_comment":  commentsMade >= 1,
		"bookworm":       bookmarkCount >= 10,
	}

	// Fetch already-earned badge keys
	existing := h.existingBadgeKeys(userID)

	// Award new ones
	for key, earned := range checks {
		if earned && !existing[key] {
			h.awardBadge(userID, key)
		}
	}
}

func (h *Handler) countRows(query string) int {
	data, err := h.DB.Query(query, http.MethodGet, nil)
	if err != nil {
		return 0
	}
	var rows []map[string]any
	if err := json.Unmarshal(data, &rows); err != nil {
		return 0
	}
	return len(rows)
}

func (h *Handler) sumPlays(userID string) int {
	query := fmt.Sprintf("podcasts?user_id=eq.%s&select=play_count", url.QueryEscape(userID))
	data, err := h.DB.Query(query, http.MethodGet, nil)
	if err != nil {
		return 0
	}
	var rows []struct {
		PlayCount int `json:"play_count"`
	}
	if err := json.Unmarshal(data, &rows); err != nil {
		return 0
	}
	total := 0
	for _, r := range rows {
		total += r.PlayCount
	}
	return total
}

func (h *Handler) countLikesReceived(userID string) int {
	// First get this user's podcast IDs, then count likes on them
	podcastQuery := fmt.Sprintf("podcasts?user_id=eq.%s&select=id", url.QueryEscape(userID))
	data, err := h.DB.Query(podcastQuery, http.MethodGet, nil)
	if err != nil {
		return 0
	}
	var podcasts []struct {
		ID string `json:"id"`
	}
	if err := json.Unmarshal(data, &podcasts); err != nil || len(podcasts) == 0 {
		return 0
	}

	ids := make([]string, 0, len(podcasts))
	for _, p := range podcasts {
		ids = append(ids, p.ID)
	}

	likesQuery := fmt.Sprintf("likes?podcast_id=in.(%s)&select=id", url.QueryEscape(strings.Join(ids, ",")))
	return h.countRows(likesQuery)
}

func (h *Handler) existingBadgeKeys(userID string) map[string]bool {
	query := fmt.Sprintf("user_badges?user_id=eq.%s&select=badge_key", url.QueryEscape(userID))
	data, err := h.DB.Query(query, http.MethodGet, nil)
	if err != nil {
		return nil
	}
	var rows []struct {
		BadgeKey string `json:"badge_key"`
	}
	if err := json.Unmarshal(data, &rows); err != nil {
		return nil
	}
	result := make(map[string]bool, len(rows))
	for _, r := range rows {
		result[r.BadgeKey] = true
	}
	return result
}

func (h *Handler) awardBadge(userID, badgeKey string) {
	body := map[string]any{
		"user_id":   userID,
		"badge_key": badgeKey,
	}
	if _, err := h.DB.Query("user_badges", http.MethodPost, body); err != nil {
		log.Printf("⚠️ [badges] failed to award %s to %s: %v", badgeKey, userID, err)
	} else {
		log.Printf("🏅 [badges] awarded %s to %s", badgeKey, userID)
	}
}
