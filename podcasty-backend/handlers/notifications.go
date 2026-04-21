package handlers

import (
	"encoding/json"
	"fmt"
	"net/http"
	"net/url"
	"strings"

	"github.com/podcasty-go/middleware"
)

// NotificationPreferences mirrors public.notification_preferences
type NotificationPreferences struct {
	UserID             string  `json:"user_id"`
	EmailOnNewComment  bool    `json:"email_on_new_comment"`
	EmailOnNewFollower bool    `json:"email_on_new_follower"`
	EmailOnNewLike     bool    `json:"email_on_new_like"`
	EmailWeeklyDigest  bool    `json:"email_weekly_digest"`
	LastDigestSentAt   *string `json:"last_digest_sent_at,omitempty"`
}

func defaultPreferences(userID string) NotificationPreferences {
	return NotificationPreferences{
		UserID:             userID,
		EmailOnNewComment:  true,
		EmailOnNewFollower: true,
		EmailOnNewLike:     false,
		EmailWeeklyDigest:  false,
	}
}

// loadPreferences fetches preferences for a user, returning defaults if no row exists.
func (h *Handler) loadPreferences(userID string) (NotificationPreferences, error) {
	if userID == "" {
		return NotificationPreferences{}, fmt.Errorf("empty user id")
	}
	query := fmt.Sprintf("notification_preferences?user_id=eq.%s&select=*", url.QueryEscape(userID))
	data, err := h.DB.Query(query, http.MethodGet, nil)
	if err != nil {
		return NotificationPreferences{}, err
	}
	var rows []NotificationPreferences
	if err := json.Unmarshal(data, &rows); err != nil {
		return NotificationPreferences{}, err
	}
	if len(rows) == 0 {
		return defaultPreferences(userID), nil
	}
	return rows[0], nil
}

// NotificationPreferencesRouter dispatches GET / PUT / POST / PATCH on the same path.
func (h *Handler) NotificationPreferencesRouter(w http.ResponseWriter, r *http.Request) {
	switch r.Method {
	case http.MethodGet:
		h.GetNotificationPreferences(w, r)
	case http.MethodPut, http.MethodPost, http.MethodPatch:
		h.UpdateNotificationPreferences(w, r)
	default:
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
	}
}

// GetNotificationPreferences returns preferences for the current user.
func (h *Handler) GetNotificationPreferences(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodGet {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}
	userID, ok := middleware.GetUserID(r)
	if !ok || userID == "" {
		http.Error(w, "Unauthorized", http.StatusUnauthorized)
		return
	}
	prefs, err := h.loadPreferences(userID)
	if err != nil {
		http.Error(w, fmt.Sprintf("Failed to load preferences: %v", err), http.StatusInternalServerError)
		return
	}
	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(prefs)
}

// fetchUserByID returns username + email for a given user id (best effort).
func (h *Handler) fetchUserByID(userID string) (*User, error) {
	if userID == "" {
		return nil, fmt.Errorf("empty user id")
	}
	query := fmt.Sprintf("users?id=eq.%s&select=id,username,email,avatar_url", url.QueryEscape(userID))
	data, err := h.DB.Query(query, http.MethodGet, nil)
	if err != nil {
		return nil, err
	}
	var users []User
	if err := json.Unmarshal(data, &users); err != nil {
		return nil, err
	}
	if len(users) == 0 {
		return nil, fmt.Errorf("user not found")
	}
	return &users[0], nil
}

// notifyOnNewComment sends an email to the podcast owner if their preferences allow it.
// All errors are logged but never propagated to the caller — notifications are best-effort.
func (h *Handler) notifyOnNewComment(podcastID, commenterID, body string) {
	if h.Notifier == nil {
		return
	}

	// Look up the podcast to find the owner.
	pq := fmt.Sprintf("podcasts?id=eq.%s&select=id,podcast_name,user_id", url.QueryEscape(podcastID))
	pdata, err := h.DB.Query(pq, http.MethodGet, nil)
	if err != nil {
		return
	}
	var podcasts []struct {
		ID          string `json:"id"`
		PodcastName string `json:"podcast_name"`
		UserID      string `json:"user_id"`
	}
	if err := json.Unmarshal(pdata, &podcasts); err != nil || len(podcasts) == 0 {
		return
	}
	owner := podcasts[0]
	// Don't email yourself for your own comments.
	if owner.UserID == commenterID {
		return
	}

	prefs, err := h.loadPreferences(owner.UserID)
	if err != nil || !prefs.EmailOnNewComment {
		return
	}
	user, err := h.fetchUserByID(owner.UserID)
	if err != nil || user.Email == "" {
		return
	}
	commenter, _ := h.fetchUserByID(commenterID)
	commenterName := "Someone"
	if commenter != nil && commenter.Username != "" {
		commenterName = commenter.Username
	}

	link := fmt.Sprintf("%s/podcasts/%s", h.Config.FrontendURL, podcastID)
	subject := fmt.Sprintf("New comment on %q", owner.PodcastName)
	html := fmt.Sprintf(
		`<p>Hi %s,</p><p><strong>%s</strong> just left a comment on your podcast <em>%s</em>:</p><blockquote>%s</blockquote><p><a href="%s">Open the discussion</a></p>`,
		htmlEscape(user.Username), htmlEscape(commenterName), htmlEscape(owner.PodcastName), htmlEscape(body), link,
	)
	h.Notifier.SendAsync(user.Email, subject, html)
}

// notifyOnNewFollower sends an email to a user who has just been followed.
func (h *Handler) notifyOnNewFollower(followedUserID, followerID string) {
	if h.Notifier == nil || followedUserID == "" || followedUserID == followerID {
		return
	}
	prefs, err := h.loadPreferences(followedUserID)
	if err != nil || !prefs.EmailOnNewFollower {
		return
	}
	user, err := h.fetchUserByID(followedUserID)
	if err != nil || user.Email == "" {
		return
	}
	follower, _ := h.fetchUserByID(followerID)
	followerName := "Someone"
	if follower != nil && follower.Username != "" {
		followerName = follower.Username
	}
	link := fmt.Sprintf("%s/profile/%s", h.Config.FrontendURL, followerID)
	subject := fmt.Sprintf("%s started following you on Podcasty", followerName)
	html := fmt.Sprintf(
		`<p>Hi %s,</p><p><strong>%s</strong> just followed you on Podcasty.</p><p><a href="%s">View their profile</a></p>`,
		htmlEscape(user.Username), htmlEscape(followerName), link,
	)
	h.Notifier.SendAsync(user.Email, subject, html)
}

// htmlEscape minimally escapes user-supplied content for use in our small HTML email templates.
func htmlEscape(s string) string {
	r := s
	r = strings.ReplaceAll(r, "&", "&amp;")
	r = strings.ReplaceAll(r, "<", "&lt;")
	r = strings.ReplaceAll(r, ">", "&gt;")
	r = strings.ReplaceAll(r, "\"", "&quot;")
	return r
}

// UpdateNotificationPreferences upserts preferences for the current user.
func (h *Handler) UpdateNotificationPreferences(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPut && r.Method != http.MethodPost && r.Method != http.MethodPatch {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}
	userID, ok := middleware.GetUserID(r)
	if !ok || userID == "" {
		http.Error(w, "Unauthorized", http.StatusUnauthorized)
		return
	}

	var req NotificationPreferences
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		http.Error(w, fmt.Sprintf("Invalid request body: %v", err), http.StatusBadRequest)
		return
	}
	req.UserID = userID // ignore any client-supplied user_id

	// Upsert via PostgREST: POST with on_conflict + Prefer: resolution=merge-duplicates
	endpoint := "notification_preferences?on_conflict=user_id"
	body := map[string]any{
		"user_id":               req.UserID,
		"email_on_new_comment":  req.EmailOnNewComment,
		"email_on_new_follower": req.EmailOnNewFollower,
		"email_on_new_like":     req.EmailOnNewLike,
		"email_weekly_digest":   req.EmailWeeklyDigest,
	}

	// The DB.Query helper sends `Prefer: return=representation` for POST already.
	// For an upsert we'd ideally also send `resolution=merge-duplicates`. Since we
	// don't want to widen the helper API just for this, attempt POST first and
	// fall back to PATCH if a unique-constraint conflict comes back.
	if _, err := h.DB.Query(endpoint, http.MethodPost, body); err != nil {
		// Try PATCH update by user_id
		patchEndpoint := fmt.Sprintf("notification_preferences?user_id=eq.%s", url.QueryEscape(userID))
		if _, perr := h.DB.Query(patchEndpoint, http.MethodPatch, body); perr != nil {
			http.Error(w, fmt.Sprintf("Failed to save preferences: %v / %v", err, perr), http.StatusInternalServerError)
			return
		}
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(req)
}
