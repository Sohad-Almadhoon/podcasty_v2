package handlers

import "net/http"

// Auth handlers
func (h *Handler) Login(w http.ResponseWriter, r *http.Request) {
	// TODO: Implement login
	w.WriteHeader(http.StatusNotImplemented)
}

func (h *Handler) Callback(w http.ResponseWriter, r *http.Request) {
	// TODO: Implement auth callback
	w.WriteHeader(http.StatusNotImplemented)
}

func (h *Handler) Logout(w http.ResponseWriter, r *http.Request) {
	// TODO: Implement logout
	w.WriteHeader(http.StatusNotImplemented)
}
