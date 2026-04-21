package routes

import (
	"net/http"

	"github.com/podcasty-go/handlers"
	"github.com/podcasty-go/middleware"
)

func RegisterRoutes(h *handlers.Handler) {

	// ======================
	// Auth
	// ======================
	http.HandleFunc("/auth/login", middleware.CORS(h.Login))
	http.HandleFunc("/auth/callback", middleware.CORS(h.Callback))
	http.HandleFunc("/auth/logout", middleware.CORS(h.Logout))

	// ======================
	// Podcasts (Public - Optional Auth)
	// ======================
	// IMPORTANT: Specific routes must come before generic ones
	http.HandleFunc("/api/podcasts/trending", middleware.CORS(middleware.OptionalAuthMiddleware(h.GetTrendingPodcasts)))
	http.HandleFunc("/api/podcasts/", middleware.CORS(middleware.OptionalAuthMiddleware(h.PodcastsHandler)))
	http.HandleFunc("/api/podcasts", middleware.CORS(middleware.OptionalAuthMiddleware(h.PodcastsHandler)))

	// ======================
	// Podcasts (Protected - Requires Auth)
	// ======================
	http.HandleFunc("/api/podcasts/create", middleware.CORS(middleware.AuthMiddleware(h.CreatePodcast)))
	http.HandleFunc("/api/podcasts/delete", middleware.CORS(middleware.AuthMiddleware(h.DeletePodcast)))

	// ======================
	// Likes (Protected)
	// ======================
	http.HandleFunc("/api/likes/status", middleware.CORS(middleware.OptionalAuthMiddleware(h.GetLikeStatus)))
	http.HandleFunc("/api/podcasts/like", middleware.CORS(middleware.AuthMiddleware(h.LikePodcast)))
	http.HandleFunc("/api/podcasts/unlike", middleware.CORS(middleware.AuthMiddleware(h.UnlikePodcast)))

	// ======================
	// Play Count (Optional Auth for tracking)
	// ======================
	http.HandleFunc("/api/podcasts/play", middleware.CORS(middleware.OptionalAuthMiddleware(h.PlayPodcast)))

	// ======================
	// Comments (Protected for create/delete)
	// ======================
	http.HandleFunc("/api/podcasts/comments", middleware.CORS(middleware.OptionalAuthMiddleware(h.GetComments)))
	http.HandleFunc("/api/podcasts/comments/create", middleware.CORS(middleware.AuthMiddleware(h.CreateComment)))
	http.HandleFunc("/api/comments/delete", middleware.CORS(middleware.AuthMiddleware(h.DeleteComment)))

	// ======================
	// Bookmarks (Protected)
	// ======================
	http.HandleFunc("/api/bookmarks/status", middleware.CORS(middleware.OptionalAuthMiddleware(h.GetBookmarkStatus)))
	http.HandleFunc("/api/bookmarks", middleware.CORS(middleware.AuthMiddleware(h.GetBookmarks)))
	http.HandleFunc("/api/bookmarks/add", middleware.CORS(middleware.AuthMiddleware(h.AddBookmark)))
	http.HandleFunc("/api/bookmarks/remove", middleware.CORS(middleware.AuthMiddleware(h.RemoveBookmark)))

	// ======================
	// Categories (Public)
	// ======================
	http.HandleFunc("/api/categories", middleware.CORS(h.GetCategories))
	http.HandleFunc("/api/categories/podcasts", middleware.CORS(h.GetPodcastsByCategory))

	// ======================
	// Playlists (Protected)
	// ======================
	http.HandleFunc("/api/playlists", middleware.CORS(middleware.AuthMiddleware(h.GetPlaylists)))
	http.HandleFunc("/api/playlists/create", middleware.CORS(middleware.AuthMiddleware(h.CreatePlaylist)))
	http.HandleFunc("/api/playlists/delete", middleware.CORS(middleware.AuthMiddleware(h.DeletePlaylist)))
	http.HandleFunc("/api/playlists/items", middleware.CORS(middleware.OptionalAuthMiddleware(h.GetPlaylistItems)))
	http.HandleFunc("/api/playlists/items/add", middleware.CORS(middleware.AuthMiddleware(h.AddPlaylistItem)))
	http.HandleFunc("/api/playlists/items/remove", middleware.CORS(middleware.AuthMiddleware(h.RemovePlaylistItem)))

	// ======================
	// Follows (Protected)
	// ======================
	http.HandleFunc("/api/users/follow/status", middleware.CORS(middleware.OptionalAuthMiddleware(h.GetFollowStatus)))
	http.HandleFunc("/api/users/follows", middleware.CORS(middleware.AuthMiddleware(h.GetFollows)))
	http.HandleFunc("/api/users/follow", middleware.CORS(middleware.AuthMiddleware(h.FollowUser)))
	http.HandleFunc("/api/users/unfollow", middleware.CORS(middleware.AuthMiddleware(h.UnfollowUser)))

	// ======================
	// Feed (Protected)
	// ======================
	http.HandleFunc("/api/feed", middleware.CORS(middleware.AuthMiddleware(h.GetFeed)))

	// ======================
	// Users (Public GET, Protected PUT/PATCH)
	// ======================
	http.HandleFunc("/api/users/", middleware.CORS(middleware.OptionalAuthMiddleware(h.GetUser)))

	// ======================
	// Leaderboard (Public)
	// ======================
	http.HandleFunc("/api/leaderboard", middleware.CORS(h.GetLeaderboard))

	// ======================
	// Transcript (Public)
	// ======================
	http.HandleFunc("/api/podcasts/transcript", middleware.CORS(h.GetTranscript))

	// ======================
	// Generate (AI) (Protected)
	// ======================
	http.HandleFunc("/api/generate", middleware.CORS(middleware.AuthMiddleware(h.GeneratePodcast)))
	http.HandleFunc("/api/generate/image", middleware.CORS(middleware.AuthMiddleware(h.GenerateImage)))
	http.HandleFunc("/api/generate/audio", middleware.CORS(middleware.AuthMiddleware(h.GenerateAudio)))

	// ======================
	// RSS (Public)
	// ======================
	http.HandleFunc("/rss", h.GetRSS)

	// ======================
	// Analytics (Optional Auth)
	// ======================
	http.HandleFunc("/api/podcasts/analytics", middleware.CORS(middleware.OptionalAuthMiddleware(h.GetAnalytics)))

	// ======================
	// Embed Player (Public)
	// ======================
	http.HandleFunc("/embed", h.GetEmbedPlayer)

	// ======================
	// Download (Public)
	// ======================
	http.HandleFunc("/api/podcasts/download", middleware.CORS(h.DownloadPodcast))

	// ======================
	// Notification Preferences (Protected)
	// ======================
	http.HandleFunc("/api/notifications/preferences", middleware.CORS(middleware.AuthMiddleware(h.NotificationPreferencesRouter)))

	// ======================
	// Badges (Public GET, Protected refresh)
	// ======================
	http.HandleFunc("/api/badges", middleware.CORS(middleware.OptionalAuthMiddleware(h.GetUserBadges)))

	// ======================
	// Series (Public GET, Protected create/delete/manage)
	// ======================
	http.HandleFunc("/api/series/create", middleware.CORS(middleware.AuthMiddleware(h.CreateSeries)))
	http.HandleFunc("/api/series/delete", middleware.CORS(middleware.AuthMiddleware(h.DeleteSeries)))
	http.HandleFunc("/api/series/episodes/add", middleware.CORS(middleware.AuthMiddleware(h.AddSeriesEpisode)))
	http.HandleFunc("/api/series/episodes/remove", middleware.CORS(middleware.AuthMiddleware(h.RemoveSeriesEpisode)))
	http.HandleFunc("/api/series/", middleware.CORS(h.GetSeries))
	http.HandleFunc("/api/series", middleware.CORS(h.ListSeries))
}
