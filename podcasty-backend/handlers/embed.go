package handlers

import "net/http"

// GetEmbedPlayer returns embed player HTML
func (h *Handler) GetEmbedPlayer(w http.ResponseWriter, r *http.Request) {
	// TODO: Implement embed player
	w.WriteHeader(http.StatusNotImplemented)
}
