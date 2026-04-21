package handlers

import "net/http"

// GetRSS returns RSS feed
func (h *Handler) GetRSS(w http.ResponseWriter, r *http.Request) {
	// TODO: Implement RSS feed
	w.WriteHeader(http.StatusNotImplemented)
}
