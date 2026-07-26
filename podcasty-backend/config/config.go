package config

import (
	"fmt"
	"log"
	"os"

	"github.com/joho/godotenv"
)

// Config holds all application configuration
type Config struct {
	// Server
	Port string

	// Supabase
	SupabaseURL        string
	SupabaseAnonKey    string
	SupabaseServiceKey string

	// OpenAI. The model names are configurable because OpenAI retires models on
	// its own schedule, and a project-scoped key may simply lack access to one —
	// both surface as "the model does not exist". Swapping a model should not
	// require a code change.
	//
	// OpenAIImageModel is deliberately left empty by default: an empty value
	// means "try the known image models in order", which keeps generation
	// working through a retirement. Setting it pins one model and disables the
	// fallback.
	OpenAIAPIKey     string
	OpenAIImageModel string
	OpenAITTSModel   string

	// Google OAuth
	GoogleClientID     string
	GoogleClientSecret string
	RedirectURL        string

	// Frontend
	FrontendURL string

	// SMTP / Email
	SMTPHost     string
	SMTPPort     string
	SMTPUsername string
	SMTPPassword string
	SMTPFrom     string
}

// Load reads environment variables and returns a Config
func Load() (*Config, error) {
	// Try to load .env file from current directory or parent directories
	// Ignore error if file doesn't exist - env vars might be set directly
	if err := godotenv.Load(); err != nil {
		log.Println("Warning: .env file not found, using environment variables")
	} else {
		log.Println(".env file loaded successfully")
	}

	config := &Config{
		Port:               getEnv("PORT", "8080"),
		SupabaseURL:        os.Getenv("SUPABASE_URL"),
		SupabaseAnonKey:    os.Getenv("SUPABASE_ANON_KEY"),
		SupabaseServiceKey: os.Getenv("SUPABASE_SERVICE_KEY"),
		OpenAIAPIKey:       os.Getenv("OPENAI_API_KEY"),
		OpenAIImageModel:   os.Getenv("OPENAI_IMAGE_MODEL"),
		OpenAITTSModel:     getEnv("OPENAI_TTS_MODEL", "tts-1"),
		GoogleClientID:     os.Getenv("GOOGLE_CLIENT_ID"),
		GoogleClientSecret: os.Getenv("GOOGLE_CLIENT_SECRET"),
		RedirectURL:        getEnv("REDIRECT_URL", "http://localhost:8080/auth/callback"),
		FrontendURL:        getEnv("FRONTEND_URL", "http://localhost:3000"),
		SMTPHost:           os.Getenv("SMTP_HOST"),
		SMTPPort:           getEnv("SMTP_PORT", "587"),
		SMTPUsername:       os.Getenv("SMTP_USERNAME"),
		SMTPPassword:       os.Getenv("SMTP_PASSWORD"),
		SMTPFrom:           getEnv("SMTP_FROM", "Podcasty <no-reply@podcasty.local>"),
	}

	// Validate required fields
	if err := config.Validate(); err != nil {
		return nil, err
	}

	return config, nil
}

// Validate checks that all required configuration is present
func (c *Config) Validate() error {
	if c.SupabaseURL == "" {
		return fmt.Errorf("SUPABASE_URL is required")
	}
	if c.SupabaseServiceKey == "" {
		return fmt.Errorf("SUPABASE_SERVICE_KEY is required")
	}
	// Note: Other fields are optional or have defaults
	return nil
}

// LogConfig prints non-sensitive configuration for debugging
func (c *Config) LogConfig() {
	log.Println("=== Configuration ===")
	log.Printf("Port: %s", c.Port)
	log.Printf("Supabase URL: %s", c.SupabaseURL)
	log.Printf("Supabase Anon Key: %s", maskString(c.SupabaseAnonKey))

	// Validate and log Service Key
	if c.SupabaseServiceKey == "" {
		log.Println("❌ Supabase Service Key: NOT SET - User auto-creation will NOT work!")
		log.Println("   Get it from: Supabase Dashboard > Project Settings > API > service_role (secret)")
	} else if len(c.SupabaseServiceKey) < 100 {
		log.Printf("⚠️  Supabase Service Key: SET but seems INVALID (%d chars - should be 200+)", len(c.SupabaseServiceKey))
		log.Printf("   Current value: %s", maskString(c.SupabaseServiceKey))
		log.Println("   Expected: Long JWT token starting with 'eyJ...'")
	} else {
		log.Printf("✅ Supabase Service Key: %s (%d chars)", maskString(c.SupabaseServiceKey), len(c.SupabaseServiceKey))
	}

	log.Printf("OpenAI API Key: %s", maskString(c.OpenAIAPIKey))
	if c.OpenAIImageModel == "" {
		log.Println("OpenAI Image Model: <auto> (falls back through known image models)")
	} else {
		log.Printf("OpenAI Image Model: %s (pinned, no fallback)", c.OpenAIImageModel)
	}
	log.Printf("OpenAI TTS Model: %s", c.OpenAITTSModel)
	log.Printf("Google Client ID: %s", maskString(c.GoogleClientID))
	log.Printf("Frontend URL: %s", c.FrontendURL)
	log.Println("====================")
}

// getEnv gets an environment variable or returns a default value
func getEnv(key, defaultValue string) string {
	if value := os.Getenv(key); value != "" {
		return value
	}
	return defaultValue
}

// maskString masks sensitive strings for logging
func maskString(s string) string {
	if s == "" {
		return "<not set>"
	}
	if len(s) <= 8 {
		return "****"
	}
	return s[:4] + "****" + s[len(s)-4:]
}
