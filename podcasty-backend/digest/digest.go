// Package digest implements the weekly email digest worker.
//
// Design decisions (locked in here so they're easy to find when revisiting):
//
//   - Single in-process scheduler. Designed for single-instance deployments.
//     If you scale horizontally, replace Run() with an HTTP endpoint that an
//     external cron hits — the per-user digest logic in BuildAndSend stays
//     unchanged.
//
//   - Send window: Mondays, 09:00–10:00 UTC. The hourly Tick() means each
//     opted-in user gets exactly one delivery in that window.
//
//   - Idempotency: notification_preferences.last_digest_sent_at gates sends.
//     A user is only eligible if last_digest_sent_at is NULL or older than
//     6 days. After a successful send we PATCH the column to NOW(). A restart
//     mid-window cannot double-send.
//
//   - Failures: per-user errors are logged and skipped. The worker never
//     panics or stops the loop.
package digest

import (
	"encoding/json"
	"fmt"
	"log"
	"net/http"
	"net/url"
	"strings"
	"time"

	"github.com/podcasty-go/config"
	"github.com/podcasty-go/db"
	"github.com/podcasty-go/notifier"
)

// Send window in UTC.
const (
	digestWeekday   = time.Monday
	digestStartHour = 9  // 09:00 UTC
	digestEndHour   = 10 // strictly less than 10:00 UTC
	minIntervalDays = 6  // skip if last_digest_sent_at < 6 days ago
	tickInterval    = time.Hour
)

// Worker runs the weekly digest scheduler.
type Worker struct {
	DB       *db.SupabaseClient
	Notifier *notifier.Notifier
	Config   *config.Config
	// now is overridable for tests.
	now func() time.Time
}

// New constructs a Worker.
func New(database *db.SupabaseClient, n *notifier.Notifier, cfg *config.Config) *Worker {
	return &Worker{DB: database, Notifier: n, Config: cfg, now: func() time.Time { return time.Now().UTC() }}
}

// Run starts the worker loop in the calling goroutine. Blocks forever; spawn
// it from main with `go worker.Run()`.
func (w *Worker) Run() {
	if w.Notifier == nil || !w.Notifier.Enabled() {
		log.Printf("📭 [digest] notifier disabled, weekly digest worker not started")
		return
	}
	log.Printf("📰 [digest] weekly digest worker started (window: %s %02d:00–%02d:00 UTC)",
		digestWeekday, digestStartHour, digestEndHour)

	// Tick once on startup so that a deploy inside the window still delivers,
	// then tick every hour.
	w.Tick()
	ticker := time.NewTicker(tickInterval)
	defer ticker.Stop()
	for range ticker.C {
		w.Tick()
	}
}

// Tick checks the clock and runs a delivery pass if we're inside the window.
// Exposed for tests and for an optional admin "run now" endpoint later.
func (w *Worker) Tick() {
	now := w.now()
	if now.Weekday() != digestWeekday {
		return
	}
	if now.Hour() < digestStartHour || now.Hour() >= digestEndHour {
		return
	}
	if err := w.deliverAll(); err != nil {
		log.Printf("❌ [digest] delivery pass failed: %v", err)
	}
}

// digestRecipient is what we read from notification_preferences joined with users.
type digestRecipient struct {
	UserID           string  `json:"user_id"`
	LastDigestSentAt *string `json:"last_digest_sent_at"`
	Users            *struct {
		ID       string `json:"id"`
		Username string `json:"username"`
		Email    string `json:"email"`
	} `json:"users"`
}

func (w *Worker) deliverAll() error {
	cutoff := w.now().AddDate(0, 0, -minIntervalDays).Format(time.RFC3339)

	// Fetch opted-in users whose last digest is null or older than the cutoff.
	// PostgREST `or=` lets us combine the two conditions.
	q := fmt.Sprintf(
		"notification_preferences?email_weekly_digest=eq.true&or=(last_digest_sent_at.is.null,last_digest_sent_at.lt.%s)&select=user_id,last_digest_sent_at,users(id,username,email)",
		url.QueryEscape(cutoff),
	)
	data, err := w.DB.Query(q, http.MethodGet, nil)
	if err != nil {
		return fmt.Errorf("fetch eligible recipients: %w", err)
	}
	var recipients []digestRecipient
	if err := json.Unmarshal(data, &recipients); err != nil {
		return fmt.Errorf("parse recipients: %w", err)
	}

	if len(recipients) == 0 {
		log.Printf("📰 [digest] no eligible recipients this tick")
		return nil
	}

	log.Printf("📰 [digest] preparing digests for %d recipient(s)", len(recipients))
	for _, r := range recipients {
		if r.Users == nil || r.Users.Email == "" {
			continue
		}
		if err := w.deliverOne(r); err != nil {
			log.Printf("❌ [digest] failed for user %s: %v", r.UserID, err)
		}
	}
	return nil
}

// digestStats is the per-user weekly tally.
type digestStats struct {
	NewPlays     int
	NewLikes     int
	NewComments  int
	NewFollowers int
}

func (w *Worker) deliverOne(r digestRecipient) error {
	since := w.now().AddDate(0, 0, -7).Format(time.RFC3339)

	// 1. Find this user's podcast IDs (so we can scope plays/likes/comments).
	podcastIDs, err := w.fetchPodcastIDs(r.UserID)
	if err != nil {
		return fmt.Errorf("fetch podcasts: %w", err)
	}

	stats := digestStats{}

	// 2. Count last-7-day plays across the user's podcasts.
	if len(podcastIDs) > 0 {
		stats.NewPlays = w.countWithFilter("plays_log", since, "played_at", podcastIDs, "podcast_id")
		stats.NewLikes = w.countWithFilter("likes", since, "created_at", podcastIDs, "podcast_id")
		stats.NewComments = w.countWithFilter("comments", since, "created_at", podcastIDs, "podcast_id")
	}

	// 3. New followers in the last 7 days.
	stats.NewFollowers = w.countSimple(
		fmt.Sprintf("follows?following_id=eq.%s&created_at=gte.%s",
			url.QueryEscape(r.UserID), url.QueryEscape(since)),
	)

	// If absolutely nothing happened, skip the email — no one wants a "0/0/0/0"
	// digest. We still update last_digest_sent_at so we don't try again until
	// next week.
	if stats.NewPlays == 0 && stats.NewLikes == 0 && stats.NewComments == 0 && stats.NewFollowers == 0 {
		log.Printf("📰 [digest] %s had no activity this week, marking sent", r.UserID)
		return w.markSent(r.UserID)
	}

	subject := "Your weekly Podcasty digest"
	html := w.renderHTML(r.Users.Username, stats)
	// Send synchronously so we only mark "sent" on success.
	if err := w.Notifier.Send(r.Users.Email, subject, html); err != nil {
		return fmt.Errorf("send: %w", err)
	}
	return w.markSent(r.UserID)
}

func (w *Worker) fetchPodcastIDs(userID string) ([]string, error) {
	q := fmt.Sprintf("podcasts?user_id=eq.%s&select=id", url.QueryEscape(userID))
	data, err := w.DB.Query(q, http.MethodGet, nil)
	if err != nil {
		return nil, err
	}
	var rows []struct {
		ID string `json:"id"`
	}
	if err := json.Unmarshal(data, &rows); err != nil {
		return nil, err
	}
	ids := make([]string, 0, len(rows))
	for _, row := range rows {
		ids = append(ids, row.ID)
	}
	return ids, nil
}

// countWithFilter counts rows in `table` where `dateCol >= since` and
// `idCol IN podcastIDs`. Returns 0 on any error (best-effort).
func (w *Worker) countWithFilter(table, since, dateCol string, podcastIDs []string, idCol string) int {
	if len(podcastIDs) == 0 {
		return 0
	}
	// PostgREST: id_col=in.(uuid1,uuid2,...)
	inList := strings.Join(podcastIDs, ",")
	q := fmt.Sprintf("%s?%s=in.(%s)&%s=gte.%s&select=id",
		table, idCol, url.QueryEscape(inList), dateCol, url.QueryEscape(since))
	return w.countSimple(q)
}

func (w *Worker) countSimple(q string) int {
	data, err := w.DB.Query(q, http.MethodGet, nil)
	if err != nil {
		return 0
	}
	var rows []map[string]any
	if err := json.Unmarshal(data, &rows); err != nil {
		return 0
	}
	return len(rows)
}

func (w *Worker) markSent(userID string) error {
	body := map[string]any{
		"last_digest_sent_at": w.now().Format(time.RFC3339),
	}
	endpoint := fmt.Sprintf("notification_preferences?user_id=eq.%s", url.QueryEscape(userID))
	_, err := w.DB.Query(endpoint, http.MethodPatch, body)
	return err
}

func (w *Worker) renderHTML(username string, s digestStats) string {
	frontend := w.Config.FrontendURL
	if frontend == "" {
		frontend = "https://podcasty.local"
	}
	settingsLink := frontend + "/settings/notifications"
	libraryLink := frontend + "/podcasts"

	name := escape(username)
	if name == "" {
		name = "there"
	}

	return fmt.Sprintf(
		`<div style="font-family: -apple-system,Segoe UI,sans-serif; max-width: 560px;">
  <h2 style="margin: 0 0 12px;">Hi %s,</h2>
  <p style="margin: 0 0 16px;">Here's what happened on your Podcasty in the last 7 days:</p>
  <ul style="line-height: 1.7; padding-left: 20px;">
    <li><strong>%d</strong> new plays across your podcasts</li>
    <li><strong>%d</strong> new likes</li>
    <li><strong>%d</strong> new comments</li>
    <li><strong>%d</strong> new followers</li>
  </ul>
  <p style="margin: 20px 0;"><a href="%s" style="background:#9333ea;color:#fff;padding:10px 16px;border-radius:8px;text-decoration:none;font-weight:600;">Open your library</a></p>
  <hr style="border:none;border-top:1px solid #eee;margin:24px 0;">
  <p style="font-size: 12px; color: #888;">You're receiving this because the weekly digest is on. <a href="%s" style="color:#9333ea;">Manage notification preferences</a>.</p>
</div>`,
		name, s.NewPlays, s.NewLikes, s.NewComments, s.NewFollowers, libraryLink, settingsLink,
	)
}

// escape minimally HTML-escapes a string for safe interpolation.
func escape(s string) string {
	r := s
	r = strings.ReplaceAll(r, "&", "&amp;")
	r = strings.ReplaceAll(r, "<", "&lt;")
	r = strings.ReplaceAll(r, ">", "&gt;")
	r = strings.ReplaceAll(r, "\"", "&quot;")
	return r
}
