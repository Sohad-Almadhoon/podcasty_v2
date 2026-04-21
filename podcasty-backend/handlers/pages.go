package handlers

import "net/http"

// Serve HTML pages (if needed for server-side rendering)
// These can be removed if you're only using the Go backend as an API

func (h *Handler) HomePage(w http.ResponseWriter, r *http.Request) {
	// TODO: Serve home page or redirect to Next.js frontend
	w.WriteHeader(http.StatusNotImplemented)
}
