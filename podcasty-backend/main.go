package main

import (
	"fmt"
	"log"
	"net/http"

	"github.com/podcasty-go/config"
	"github.com/podcasty-go/db"
	"github.com/podcasty-go/digest"
	"github.com/podcasty-go/handlers"
	"github.com/podcasty-go/routes"
)

func main() {
	// Load configuration
	cfg, err := config.Load()
	if err != nil {
		log.Fatalf("Failed to load configuration: %v", err)
	}

	// Log configuration (with sensitive data masked)
	cfg.LogConfig()

	// Initialize Supabase client
	supabaseClient := db.NewSupabaseClient(cfg.SupabaseURL, cfg.SupabaseServiceKey)

	// Create handler with dependencies
	handler := handlers.NewHandler(supabaseClient, cfg)

	// Register all routes
	routes.RegisterRoutes(handler)

	// Start the weekly-digest worker in the background. It no-ops if SMTP is
	// not configured. NOTE: this is single-instance only — if you scale
	// horizontally, replace this with an external cron hitting an admin
	// endpoint that calls digest.Worker.Tick().
	go digest.New(supabaseClient, handler.Notifier, cfg).Run()

	// Start server
	addr := ":" + cfg.Port
	fmt.Printf("Server starting on %s\n", addr)
	log.Fatal(http.ListenAndServe(addr, nil))
}
