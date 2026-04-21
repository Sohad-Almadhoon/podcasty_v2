package handlers

import (
	"encoding/json"
	"fmt"
	"net/http"
	"net/url"
	"strings"

	"github.com/podcasty-go/middleware"
)

// User represents a user in the database
type User struct {
	ID        string `json:"id"`
	Username  string `json:"username"`
	Email     string `json:"email"`
	AvatarURL string `json:"avatar_url"`
	CreatedAt string `json:"created_at"`
}

// GetUser returns a user by ID
func (h *Handler) GetUser(w http.ResponseWriter, r *http.Request) {
	// Handle different HTTP methods
	if r.Method == http.MethodPut || r.Method == http.MethodPatch {
		h.UpdateUser(w, r)
		return
	}

	if r.Method != http.MethodGet {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}

	// Extract user ID from URL path
	// Expected format: /api/users/{id}
	pathParts := strings.Split(r.URL.Path, "/")
	if len(pathParts) < 4 {
		http.Error(w, "Invalid user ID", http.StatusBadRequest)
		return
	}
	userID := pathParts[3]

	// If there are more path parts, this might be a different endpoint
	if len(pathParts) > 4 {
		// Check if it's the podcasts endpoint
		if pathParts[4] == "podcasts" {
			h.GetUserPodcasts(w, r)
			return
		}
		http.Error(w, "Invalid endpoint", http.StatusNotFound)
		return
	}

	// Query Supabase for the user
	query := fmt.Sprintf("users?id=eq.%s&select=*", url.QueryEscape(userID))
	data, err := h.DB.Query(query, http.MethodGet, nil)
	if err != nil {
		http.Error(w, fmt.Sprintf("Failed to fetch user: %v", err), http.StatusInternalServerError)
		return
	}

	// Parse response
	var users []User
	if err := json.Unmarshal(data, &users); err != nil {
		http.Error(w, fmt.Sprintf("Failed to parse user: %v", err), http.StatusInternalServerError)
		return
	}

	if len(users) == 0 {
		// User not in public.users - try to auto-create from auth
		fmt.Printf("ℹ️  User %s not found in public.users, attempting auto-creation from auth...\n", userID)
		authUser, err := h.DB.GetAuthUser(userID)
		if err != nil {
			fmt.Printf("❌ Failed to fetch auth user %s: %v\n", userID, err)
			http.Error(w, "User not found", http.StatusNotFound)
			return
		}

		// Extract user metadata
		email, _ := authUser["email"].(string)
		username := email
		avatarURL := ""

		if meta, ok := authUser["user_metadata"].(map[string]any); ok {
			if name, ok := meta["full_name"].(string); ok && name != "" {
				username = name
			}
			if avatar, ok := meta["avatar_url"].(string); ok {
				avatarURL = avatar
			} else if avatar, ok := meta["picture"].(string); ok {
				avatarURL = avatar
			}
		}
		if username == "" {
			username = "User"
		}

		fmt.Printf("ℹ️  Creating user in public.users: %s (%s)\n", username, email)

		// Insert into public.users
		newUser := map[string]any{
			"id":         userID,
			"email":      email,
			"username":   username,
			"avatar_url": avatarURL,
		}
		insertData, err := h.DB.Query("users", http.MethodPost, newUser)
		if err != nil {
			fmt.Printf("❌ Failed to auto-create user %s: %v\n", userID, err)
			http.Error(w, fmt.Sprintf("Failed to create user: %v", err), http.StatusInternalServerError)
			return
		}

		var createdUsers []User
		if err := json.Unmarshal(insertData, &createdUsers); err != nil || len(createdUsers) == 0 {
			fmt.Printf("❌ Failed to parse created user %s: %v\n", userID, err)
			http.Error(w, "Failed to create user", http.StatusInternalServerError)
			return
		}

		fmt.Printf("✅ Successfully auto-created user %s\n", userID)
		w.Header().Set("Content-Type", "application/json")
		json.NewEncoder(w).Encode(createdUsers[0])
		return
	}

	// Return single user
	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(users[0])
}

// GetUserPodcasts returns all podcasts by a specific user
func (h *Handler) GetUserPodcasts(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodGet {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}

	// Extract user ID from URL path
	// Expected format: /api/users/{id}/podcasts
	pathParts := strings.Split(r.URL.Path, "/")
	if len(pathParts) < 5 {
		http.Error(w, "Invalid user ID", http.StatusBadRequest)
		return
	}
	userID := pathParts[3]

	// Query Supabase for podcasts by this user
	query := fmt.Sprintf("podcasts?user_id=eq.%s&select=*,users(username,avatar_url),likes:likes(count)&order=created_at.desc",
		url.QueryEscape(userID))
	data, err := h.DB.Query(query, http.MethodGet, nil)
	if err != nil {
		http.Error(w, fmt.Sprintf("Failed to fetch user podcasts: %v", err), http.StatusInternalServerError)
		return
	}

	// Parse response
	var podcasts []Podcast
	if err := json.Unmarshal(data, &podcasts); err != nil {
		http.Error(w, fmt.Sprintf("Failed to parse podcasts: %v", err), http.StatusInternalServerError)
		return
	}

	// Return podcasts (even if empty array)
	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(podcasts)
}

// UpdateUserRequest represents the request body for updating a user profile
type UpdateUserRequest struct {
	Username  string `json:"username"`
	AvatarURL string `json:"avatar_url"`
}

// UpdateUser updates a user's profile (username and avatar)
func (h *Handler) UpdateUser(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPut && r.Method != http.MethodPatch {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}

	// Extract user ID from URL path
	// Expected format: /api/users/{id}
	pathParts := strings.Split(r.URL.Path, "/")
	if len(pathParts) < 4 {
		http.Error(w, "Invalid user ID", http.StatusBadRequest)
		return
	}
	userID := pathParts[3]

	// Get authenticated user ID from context
	authUserID, ok := middleware.GetUserID(r)
	if !ok || authUserID == "" {
		http.Error(w, "Unauthorized: Authentication required", http.StatusUnauthorized)
		return
	}

	// Verify user can only update their own profile
	if authUserID != userID {
		http.Error(w, "Forbidden: You can only update your own profile", http.StatusForbidden)
		return
	}

	// Parse request body
	var req UpdateUserRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		http.Error(w, fmt.Sprintf("Invalid request body: %v", err), http.StatusBadRequest)
		return
	}

	// Validate at least one field is provided
	if req.Username == "" && req.AvatarURL == "" {
		http.Error(w, "At least one field (username or avatar_url) must be provided", http.StatusBadRequest)
		return
	}

	// Build update payload
	updateData := make(map[string]any)
	if req.Username != "" {
		updateData["username"] = req.Username
	}
	if req.AvatarURL != "" {
		updateData["avatar_url"] = req.AvatarURL
	}

	// First, check if user exists
	checkQuery := fmt.Sprintf("users?id=eq.%s&select=*", url.QueryEscape(userID))
	checkData, err := h.DB.Query(checkQuery, http.MethodGet, nil)
	if err != nil {
		http.Error(w, fmt.Sprintf("Failed to check user: %v", err), http.StatusInternalServerError)
		return
	}

	var existingUsers []User
	if err := json.Unmarshal(checkData, &existingUsers); err != nil {
		http.Error(w, "Failed to check user", http.StatusInternalServerError)
		return
	}

	// If user doesn't exist, auto-create from auth
	if len(existingUsers) == 0 {
		fmt.Printf("ℹ️  User %s not found in public.users during update, attempting auto-creation from auth...\n", userID)

		// Check if service key is configured
		if h.DB.ServiceKey == "" {
			http.Error(w, "User not found. Service key not configured for auto-creation. Please run user-autocreate-trigger.sql or visit your profile page first.", http.StatusNotFound)
			return
		}

		authUser, err := h.DB.GetAuthUser(userID)
		if err != nil {
			fmt.Printf("❌ Failed to fetch auth user %s for update: %v\n", userID, err)
			http.Error(w, "User not found. Please ensure you're logged in and try viewing your profile page first, or contact support.", http.StatusNotFound)
			return
		}

		// Extract user metadata
		email, _ := authUser["email"].(string)
		username := email
		avatarURL := ""

		if meta, ok := authUser["user_metadata"].(map[string]any); ok {
			if name, ok := meta["full_name"].(string); ok && name != "" {
				username = name
			}
			if avatar, ok := meta["avatar_url"].(string); ok {
				avatarURL = avatar
			} else if avatar, ok := meta["picture"].(string); ok {
				avatarURL = avatar
			}
		}
		if username == "" {
			username = "User"
		}

		// Apply update data to the new user
		if req.Username != "" {
			username = req.Username
		}
		if req.AvatarURL != "" {
			avatarURL = req.AvatarURL
		}

		fmt.Printf("ℹ️  Creating user in public.users during update: %s (%s)\n", username, email)

		// Insert into public.users
		newUser := map[string]any{
			"id":         userID,
			"email":      email,
			"username":   username,
			"avatar_url": avatarURL,
		}
		insertData, err := h.DB.Query("users", http.MethodPost, newUser)
		if err != nil {
			fmt.Printf("❌ Failed to auto-create user %s during update: %v\n", userID, err)
			http.Error(w, fmt.Sprintf("Failed to create user: %v", err), http.StatusInternalServerError)
			return
		}

		var createdUsers []User
		if err := json.Unmarshal(insertData, &createdUsers); err != nil || len(createdUsers) == 0 {
			fmt.Printf("❌ Failed to parse created user %s during update\n", userID)
			http.Error(w, "Failed to create user", http.StatusInternalServerError)
			return
		}

		fmt.Printf("✅ Successfully auto-created user %s during update\n", userID)
		// Return newly created/updated user
		w.Header().Set("Content-Type", "application/json")
		json.NewEncoder(w).Encode(createdUsers[0])
		return
	}

	// Update existing user in database
	query := fmt.Sprintf("users?id=eq.%s", url.QueryEscape(userID))
	data, err := h.DB.Query(query, http.MethodPatch, updateData)
	if err != nil {
		http.Error(w, fmt.Sprintf("Failed to update user: %v", err), http.StatusInternalServerError)
		return
	}

	// Parse response
	var users []User
	if err := json.Unmarshal(data, &users); err != nil {
		http.Error(w, fmt.Sprintf("Failed to parse updated user: %v", err), http.StatusInternalServerError)
		return
	}

	if len(users) == 0 {
		http.Error(w, "User not found", http.StatusNotFound)
		return
	}

	// Return updated user
	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(users[0])
}
