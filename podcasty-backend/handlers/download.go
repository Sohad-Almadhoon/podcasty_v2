package handlers

import (
	"encoding/base64"
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"net/url"
	"path"
	"strings"
)

// DownloadPodcast serves the podcast audio as a downloadable file.
// Handles both HTTP URLs (proxied from Supabase Storage) and base64 data URIs.
func (h *Handler) DownloadPodcast(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodGet {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}

	podcastID := r.URL.Query().Get("id")
	if podcastID == "" {
		http.Error(w, "Missing podcast id", http.StatusBadRequest)
		return
	}

	// Look up the podcast to get audio_url and podcast_name for the filename.
	query := fmt.Sprintf("podcasts?id=eq.%s&select=id,podcast_name,audio_url", url.QueryEscape(podcastID))
	data, err := h.DB.Query(query, http.MethodGet, nil)
	if err != nil {
		http.Error(w, "Database error", http.StatusInternalServerError)
		return
	}

	var podcasts []struct {
		ID          string `json:"id"`
		PodcastName string `json:"podcast_name"`
		AudioURL    string `json:"audio_url"`
	}
	if err := json.Unmarshal(data, &podcasts); err != nil || len(podcasts) == 0 {
		http.Error(w, "Podcast not found", http.StatusNotFound)
		return
	}
	podcast := podcasts[0]

	if podcast.AudioURL == "" {
		http.Error(w, "No audio available for this podcast", http.StatusNotFound)
		return
	}

	safeName := sanitizeFilename(podcast.PodcastName)
	if safeName == "" {
		safeName = "podcast"
	}

	// Data URI: "data:audio/mpeg;base64,//PkxAB..."
	if strings.HasPrefix(podcast.AudioURL, "data:") {
		h.serveDataURI(w, podcast.AudioURL, safeName)
		return
	}

	// Regular HTTP URL: proxy the file
	h.serveHTTPURL(w, podcast.AudioURL, safeName)
}

// serveDataURI decodes a base64 data URI and streams it as a download.
func (h *Handler) serveDataURI(w http.ResponseWriter, dataURI, safeName string) {
	// Parse "data:audio/mpeg;base64,<data>"
	// Find the comma that separates metadata from content
	commaIdx := strings.Index(dataURI, ",")
	if commaIdx < 0 {
		http.Error(w, "Invalid audio data", http.StatusInternalServerError)
		return
	}

	header := dataURI[:commaIdx]  // "data:audio/mpeg;base64"
	encoded := dataURI[commaIdx+1:]

	// Extract content type from header
	contentType := "audio/mpeg" // default
	headerParts := strings.TrimPrefix(header, "data:")
	if ctEnd := strings.Index(headerParts, ";"); ctEnd > 0 {
		contentType = headerParts[:ctEnd]
	}

	// Determine file extension from content type
	ext := ".mp3"
	switch contentType {
	case "audio/wav", "audio/wave":
		ext = ".wav"
	case "audio/ogg":
		ext = ".ogg"
	case "audio/mp4", "audio/m4a":
		ext = ".m4a"
	case "audio/webm":
		ext = ".webm"
	}

	// Decode base64
	audioBytes, err := base64.StdEncoding.DecodeString(encoded)
	if err != nil {
		// Try RawStdEncoding (no padding) as a fallback
		audioBytes, err = base64.RawStdEncoding.DecodeString(encoded)
		if err != nil {
			http.Error(w, "Failed to decode audio data", http.StatusInternalServerError)
			return
		}
	}

	w.Header().Set("Content-Disposition", fmt.Sprintf(`attachment; filename="%s%s"`, safeName, ext))
	w.Header().Set("Content-Type", contentType)
	w.Header().Set("Content-Length", fmt.Sprintf("%d", len(audioBytes)))
	w.Write(audioBytes)
}

// serveHTTPURL fetches audio from a remote URL and streams it as a download.
func (h *Handler) serveHTTPURL(w http.ResponseWriter, audioURL, safeName string) {
	ext := path.Ext(audioURL)
	if ext == "" || len(ext) > 5 {
		ext = ".mp3"
	}

	resp, err := http.Get(audioURL)
	if err != nil {
		http.Error(w, "Failed to fetch audio file", http.StatusBadGateway)
		return
	}
	defer resp.Body.Close()

	if resp.StatusCode >= 400 {
		http.Error(w, "Audio file not available", http.StatusBadGateway)
		return
	}

	w.Header().Set("Content-Disposition", fmt.Sprintf(`attachment; filename="%s%s"`, safeName, ext))
	if ct := resp.Header.Get("Content-Type"); ct != "" {
		w.Header().Set("Content-Type", ct)
	} else {
		w.Header().Set("Content-Type", "audio/mpeg")
	}
	if cl := resp.Header.Get("Content-Length"); cl != "" {
		w.Header().Set("Content-Length", cl)
	}

	io.Copy(w, resp.Body)
}

// sanitizeFilename removes characters that aren't safe in a downloaded filename.
func sanitizeFilename(name string) string {
	if name == "" {
		return "podcast"
	}
	var b strings.Builder
	for _, r := range name {
		switch {
		case r >= 'a' && r <= 'z', r >= 'A' && r <= 'Z', r >= '0' && r <= '9',
			r == ' ', r == '-', r == '_':
			b.WriteRune(r)
		default:
			b.WriteRune('_')
		}
	}
	result := strings.TrimSpace(b.String())
	if result == "" {
		return "podcast"
	}
	return result
}
