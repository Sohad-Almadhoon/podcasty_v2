package handlers

import (
	"github.com/podcasty-go/config"
	"github.com/podcasty-go/db"
	"github.com/podcasty-go/notifier"
)

// Handler holds dependencies for all HTTP handlers
type Handler struct {
	DB       *db.SupabaseClient
	Config   *config.Config
	Notifier *notifier.Notifier
}

// NewHandler creates a new Handler instance
func NewHandler(supabase *db.SupabaseClient, cfg *config.Config) *Handler {
	return &Handler{
		DB:       supabase,
		Config:   cfg,
		Notifier: notifier.New(cfg),
	}
}
