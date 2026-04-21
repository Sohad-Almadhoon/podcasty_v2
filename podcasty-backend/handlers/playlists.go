package handlers

import (
	"encoding/json"
	"fmt"
	"net/http"
	"net/url"

	"github.com/podcasty-go/middleware"
)

// GetPlaylists returns user's playlists
func (h *Handler) GetPlaylists(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodGet {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}

	userID, ok := middleware.GetUserID(r)
	if !ok || userID == "" {
		http.Error(w, "Unauthorized", http.StatusUnauthorized)
		return
	}

	// Get playlists with item counts
	query := fmt.Sprintf("playlists?user_id=eq.%s&select=*&order=created_at.desc", url.QueryEscape(userID))

	data, err := h.DB.Query(query, http.MethodGet, nil)
	if err != nil {
		http.Error(w, "Error fetching playlists: "+err.Error(), http.StatusInternalServerError)
		return
	}

	var playlists []map[string]any
	if err := json.Unmarshal(data, &playlists); err != nil {
		http.Error(w, "Error parsing playlists: "+err.Error(), http.StatusInternalServerError)
		return
	}

	// For each playlist, get the count of items
	for i := range playlists {
		if playlistID, ok := playlists[i]["id"].(string); ok {
			itemQuery := fmt.Sprintf("playlist_items?playlist_id=eq.%s&select=id", url.QueryEscape(playlistID))
			itemData, err := h.DB.Query(itemQuery, http.MethodGet, nil)
			if err == nil {
				var items []map[string]any
				if err := json.Unmarshal(itemData, &items); err == nil {
					playlists[i]["item_count"] = len(items)
				} else {
					playlists[i]["item_count"] = 0
				}
			} else {
				playlists[i]["item_count"] = 0
			}
		}
	}

	if playlists == nil {
		playlists = []map[string]any{}
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(playlists)
}

// CreatePlaylist creates a new playlist
func (h *Handler) CreatePlaylist(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}

	userID, ok := middleware.GetUserID(r)
	if !ok || userID == "" {
		http.Error(w, "Unauthorized", http.StatusUnauthorized)
		return
	}

	var requestBody struct {
		Name        string `json:"name"`
		Description string `json:"description"`
	}

	if err := json.NewDecoder(r.Body).Decode(&requestBody); err != nil {
		http.Error(w, "Invalid request body", http.StatusBadRequest)
		return
	}

	if requestBody.Name == "" {
		http.Error(w, "name is required", http.StatusBadRequest)
		return
	}

	// Create playlist
	playlistData := map[string]any{
		"user_id":     userID,
		"name":        requestBody.Name,
		"description": requestBody.Description,
	}

	data, err := h.DB.Query("playlists", http.MethodPost, playlistData)
	if err != nil {
		http.Error(w, "Error creating playlist: "+err.Error(), http.StatusInternalServerError)
		return
	}

	var createdPlaylist []map[string]any
	if err := json.Unmarshal(data, &createdPlaylist); err != nil || len(createdPlaylist) == 0 {
		http.Error(w, "Failed to create playlist", http.StatusInternalServerError)
		return
	}

	// Add item_count to response
	createdPlaylist[0]["item_count"] = 0

	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusCreated)
	json.NewEncoder(w).Encode(createdPlaylist[0])
}

// DeletePlaylist deletes a playlist and all its items
func (h *Handler) DeletePlaylist(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodDelete && r.Method != http.MethodPost {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}

	userID, ok := middleware.GetUserID(r)
	if !ok || userID == "" {
		http.Error(w, "Unauthorized", http.StatusUnauthorized)
		return
	}

	// Get playlist_id from query params or request body
	playlistID := r.URL.Query().Get("id")

	if playlistID == "" && r.Method == http.MethodPost {
		var requestBody struct {
			PlaylistID string `json:"playlist_id"`
		}
		if err := json.NewDecoder(r.Body).Decode(&requestBody); err == nil {
			playlistID = requestBody.PlaylistID
		}
	}

	if playlistID == "" {
		http.Error(w, "playlist_id is required", http.StatusBadRequest)
		return
	}

	// Verify playlist exists and belongs to user
	query := fmt.Sprintf("playlists?id=eq.%s&user_id=eq.%s", url.QueryEscape(playlistID), url.QueryEscape(userID))
	data, err := h.DB.Query(query, http.MethodGet, nil)
	if err != nil {
		http.Error(w, "Error checking playlist: "+err.Error(), http.StatusInternalServerError)
		return
	}

	var existingPlaylist []map[string]any
	if err := json.Unmarshal(data, &existingPlaylist); err != nil || len(existingPlaylist) == 0 {
		http.Error(w, "Playlist not found or you don't have permission", http.StatusNotFound)
		return
	}

	// Delete all playlist items first (cascade delete)
	itemQuery := fmt.Sprintf("playlist_items?playlist_id=eq.%s", url.QueryEscape(playlistID))
	_, _ = h.DB.Query(itemQuery, http.MethodDelete, nil)

	// Delete the playlist
	deleteQuery := fmt.Sprintf("playlists?id=eq.%s", url.QueryEscape(playlistID))
	if _, err := h.DB.Query(deleteQuery, http.MethodDelete, nil); err != nil {
		http.Error(w, "Error deleting playlist: "+err.Error(), http.StatusInternalServerError)
		return
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(map[string]any{
		"message": "Playlist deleted successfully",
		"id":      playlistID,
	})
}

// GetPlaylistItems returns all items in a playlist
func (h *Handler) GetPlaylistItems(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodGet {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}

	playlistID := r.URL.Query().Get("playlist_id")
	if playlistID == "" {
		http.Error(w, "playlist_id is required", http.StatusBadRequest)
		return
	}

	// Get playlist items with podcast details, ordered by position
	query := fmt.Sprintf(
		"playlist_items?playlist_id=eq.%s&select=*,podcasts(*)&order=position.asc",
		url.QueryEscape(playlistID),
	)

	data, err := h.DB.Query(query, http.MethodGet, nil)
	if err != nil {
		http.Error(w, "Error fetching playlist items: "+err.Error(), http.StatusInternalServerError)
		return
	}

	var items []map[string]any
	if err := json.Unmarshal(data, &items); err != nil {
		http.Error(w, "Error parsing items: "+err.Error(), http.StatusInternalServerError)
		return
	}

	if items == nil {
		items = []map[string]any{}
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(items)
}

// AddPlaylistItem adds a podcast to a playlist
func (h *Handler) AddPlaylistItem(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}

	userID, ok := middleware.GetUserID(r)
	if !ok || userID == "" {
		http.Error(w, "Unauthorized", http.StatusUnauthorized)
		return
	}

	var requestBody struct {
		PlaylistID string `json:"playlist_id"`
		PodcastID  string `json:"podcast_id"`
	}

	if err := json.NewDecoder(r.Body).Decode(&requestBody); err != nil {
		http.Error(w, "Invalid request body", http.StatusBadRequest)
		return
	}

	if requestBody.PlaylistID == "" || requestBody.PodcastID == "" {
		http.Error(w, "playlist_id and podcast_id are required", http.StatusBadRequest)
		return
	}

	// Verify playlist belongs to user
	playlistQuery := fmt.Sprintf("playlists?id=eq.%s&user_id=eq.%s", url.QueryEscape(requestBody.PlaylistID), url.QueryEscape(userID))
	playlistData, err := h.DB.Query(playlistQuery, http.MethodGet, nil)
	if err != nil {
		http.Error(w, "Error checking playlist: "+err.Error(), http.StatusInternalServerError)
		return
	}

	var existingPlaylist []map[string]any
	if err := json.Unmarshal(playlistData, &existingPlaylist); err != nil || len(existingPlaylist) == 0 {
		http.Error(w, "Playlist not found or you don't have permission", http.StatusNotFound)
		return
	}

	// Check if podcast exists
	podcastQuery := fmt.Sprintf("podcasts?id=eq.%s", url.QueryEscape(requestBody.PodcastID))
	podcastData, err := h.DB.Query(podcastQuery, http.MethodGet, nil)
	if err != nil {
		http.Error(w, "Error checking podcast: "+err.Error(), http.StatusInternalServerError)
		return
	}

	var existingPodcast []map[string]any
	if err := json.Unmarshal(podcastData, &existingPodcast); err != nil || len(existingPodcast) == 0 {
		http.Error(w, "Podcast not found", http.StatusNotFound)
		return
	}

	// Check if already in playlist
	itemCheckQuery := fmt.Sprintf("playlist_items?playlist_id=eq.%s&podcast_id=eq.%s",
		url.QueryEscape(requestBody.PlaylistID),
		url.QueryEscape(requestBody.PodcastID))
	checkData, err := h.DB.Query(itemCheckQuery, http.MethodGet, nil)
	if err == nil {
		var existingItem []map[string]any
		if err := json.Unmarshal(checkData, &existingItem); err == nil && len(existingItem) > 0 {
			http.Error(w, "Podcast already in playlist", http.StatusConflict)
			return
		}
	}

	// Get max position in playlist
	posQuery := fmt.Sprintf("playlist_items?playlist_id=eq.%s&select=position&order=position.desc&limit=1", url.QueryEscape(requestBody.PlaylistID))
	maxPosition := 0
	posData, err := h.DB.Query(posQuery, http.MethodGet, nil)
	if err == nil {
		var allItems []map[string]any
		if err := json.Unmarshal(posData, &allItems); err == nil && len(allItems) > 0 {
			if pos, ok := allItems[0]["position"].(float64); ok {
				maxPosition = int(pos)
			}
		}
	}

	// Add to playlist
	itemData := map[string]any{
		"playlist_id": requestBody.PlaylistID,
		"podcast_id":  requestBody.PodcastID,
		"position":    maxPosition + 1,
	}

	if _, err := h.DB.Query("playlist_items", http.MethodPost, itemData); err != nil {
		http.Error(w, "Error adding to playlist: "+err.Error(), http.StatusInternalServerError)
		return
	}

	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusCreated)
	json.NewEncoder(w).Encode(map[string]any{
		"message":     "Podcast added to playlist",
		"playlist_id": requestBody.PlaylistID,
		"podcast_id":  requestBody.PodcastID,
	})
}

// RemovePlaylistItem removes a podcast from a playlist
func (h *Handler) RemovePlaylistItem(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodDelete && r.Method != http.MethodPost {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}

	userID, ok := middleware.GetUserID(r)
	if !ok || userID == "" {
		http.Error(w, "Unauthorized", http.StatusUnauthorized)
		return
	}

	// Get item_id from query params or request body
	itemID := r.URL.Query().Get("id")

	if itemID == "" && r.Method == http.MethodPost {
		var requestBody struct {
			ItemID string `json:"item_id"`
		}
		if err := json.NewDecoder(r.Body).Decode(&requestBody); err == nil {
			itemID = requestBody.ItemID
		}
	}

	if itemID == "" {
		http.Error(w, "item_id is required", http.StatusBadRequest)
		return
	}

	// Get the item to verify ownership through playlist
	itemQuery := fmt.Sprintf("playlist_items?id=eq.%s&select=*,playlists(user_id)", url.QueryEscape(itemID))
	data, err := h.DB.Query(itemQuery, http.MethodGet, nil)
	if err != nil {
		http.Error(w, "Error checking item: "+err.Error(), http.StatusInternalServerError)
		return
	}

	var item []map[string]any
	if err := json.Unmarshal(data, &item); err != nil || len(item) == 0 {
		http.Error(w, "Item not found", http.StatusNotFound)
		return
	}

	// Verify ownership (check if playlist belongs to user)
	if playlist, ok := item[0]["playlists"].(map[string]any); ok {
		if playlistUserID, ok := playlist["user_id"].(string); !ok || playlistUserID != userID {
			http.Error(w, "Not authorized to remove this item", http.StatusForbidden)
			return
		}
	}

	// Delete the item
	deleteQuery := fmt.Sprintf("playlist_items?id=eq.%s", url.QueryEscape(itemID))
	if _, err := h.DB.Query(deleteQuery, http.MethodDelete, nil); err != nil {
		http.Error(w, "Error removing item: "+err.Error(), http.StatusInternalServerError)
		return
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(map[string]any{
		"message": "Item removed from playlist",
		"id":      itemID,
	})
}
