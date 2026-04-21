package handlers

import (
	"encoding/json"
	"fmt"
	"net/http"
	"net/url"
)

// GetCategories returns all categories with podcast counts
func (h *Handler) GetCategories(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodGet {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}

	// Get distinct categories with counts
	// Using a simple query to get all podcasts and group by category in Go
	query := "podcasts?select=category"
	data, err := h.DB.Query(query, http.MethodGet, nil)
	if err != nil {
		http.Error(w, "Error fetching categories: "+err.Error(), http.StatusInternalServerError)
		return
	}

	var allPodcasts []map[string]any
	if err := json.Unmarshal(data, &allPodcasts); err != nil {
		http.Error(w, "Error parsing response: "+err.Error(), http.StatusInternalServerError)
		return
	}

	// Count podcasts per category
	categoryMap := make(map[string]int)
	for _, podcast := range allPodcasts {
		if cat, ok := podcast["category"].(string); ok && cat != "" {
			categoryMap[cat]++
		}
	}

	// Convert to array of category objects
	type Category struct {
		Name  string `json:"name"`
		Count int    `json:"count"`
	}

	categories := []Category{}
	for name, count := range categoryMap {
		categories = append(categories, Category{
			Name:  name,
			Count: count,
		})
	}

	// If no categories, return empty array
	if len(categories) == 0 {
		categories = []Category{}
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(categories)
}

// GetPodcastsByCategory returns podcasts filtered by category
func (h *Handler) GetPodcastsByCategory(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodGet {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}

	// Get category from query params
	category := r.URL.Query().Get("category")
	if category == "" {
		http.Error(w, "category parameter is required", http.StatusBadRequest)
		return
	}

	// Get limit and offset for pagination
	limit := r.URL.Query().Get("limit")
	if limit == "" {
		limit = "50"
	}
	offset := r.URL.Query().Get("offset")
	if offset == "" {
		offset = "0"
	}

	// Build query
	query := fmt.Sprintf(
		"podcasts?category=eq.%s&select=*,users(username,avatar_url)&order=created_at.desc&limit=%s&offset=%s",
		url.QueryEscape(category),
		limit,
		offset,
	)

	data, err := h.DB.Query(query, http.MethodGet, nil)
	if err != nil {
		http.Error(w, "Error fetching podcasts: "+err.Error(), http.StatusInternalServerError)
		return
	}

	var podcasts []map[string]any
	if err := json.Unmarshal(data, &podcasts); err != nil {
		http.Error(w, "Error parsing response: "+err.Error(), http.StatusInternalServerError)
		return
	}

	if podcasts == nil {
		podcasts = []map[string]any{}
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(podcasts)
}
