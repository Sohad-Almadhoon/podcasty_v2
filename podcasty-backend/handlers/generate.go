package handlers

import (
	"bytes"
	"encoding/base64"
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"time"
)

// GeneratePodcast generates both AI cover image and audio in one request
func (h *Handler) GeneratePodcast(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}

	// Parse request
	var req struct {
		Prompt string `json:"prompt"`
		Voice  string `json:"voice"`
	}

	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		http.Error(w, "Invalid request body", http.StatusBadRequest)
		return
	}

	if req.Prompt == "" {
		http.Error(w, "prompt is required", http.StatusBadRequest)
		return
	}

	if req.Voice == "" {
		req.Voice = "alloy"
	}

	// Check if OpenAI API key is configured
	if h.Config.OpenAIAPIKey == "" {
		http.Error(w, "OpenAI API key not configured", http.StatusInternalServerError)
		return
	}

	// 1. Generate image using DALL-E
	imageURL, err := h.generateImageInternal(req.Prompt)
	if err != nil {
		http.Error(w, fmt.Sprintf("Failed to generate image: %v", err), http.StatusInternalServerError)
		return
	}

	// 2. Generate audio using TTS
	audioURL, err := h.generateAudioInternal(req.Prompt, req.Voice)
	if err != nil {
		http.Error(w, fmt.Sprintf("Failed to generate audio: %v", err), http.StatusInternalServerError)
		return
	}

	// Return both URLs
	response := map[string]any{
		"image_url": imageURL,
		"audio_url": audioURL,
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(response)
}

// generateImageInternal is a helper function to generate image
func (h *Handler) generateImageInternal(prompt string) (string, error) {
	openAIReq := map[string]any{
		"model":  "dall-e-3",
		"prompt": prompt,
		"n":      1,
		"size":   "1024x1024",
	}

	reqBody, _ := json.Marshal(openAIReq)
	openAIURL := "https://api.openai.com/v1/images/generations"

	httpReq, err := http.NewRequest("POST", openAIURL, bytes.NewBuffer(reqBody))
	if err != nil {
		return "", err
	}

	httpReq.Header.Set("Content-Type", "application/json")
	httpReq.Header.Set("Authorization", "Bearer "+h.Config.OpenAIAPIKey)

	client := &http.Client{}
	resp, err := client.Do(httpReq)
	if err != nil {
		return "", err
	}
	defer resp.Body.Close()

	body, _ := io.ReadAll(resp.Body)

	if resp.StatusCode != http.StatusOK {
		return "", fmt.Errorf("OpenAI API error: %s", string(body))
	}

	var openAIResp struct {
		Data []struct {
			URL string `json:"url"`
		} `json:"data"`
	}

	if err := json.Unmarshal(body, &openAIResp); err != nil {
		return "", err
	}

	if len(openAIResp.Data) == 0 {
		return "", fmt.Errorf("no image generated")
	}

	tempImageURL := openAIResp.Data[0].URL

	// Download the image from OpenAI's temporary URL
	imageData, err := downloadImage(tempImageURL)
	if err != nil {
		return "", fmt.Errorf("failed to download image: %v", err)
	}

	// Generate a unique filename
	timestamp := time.Now().Unix()
	filename := fmt.Sprintf("podcast-covers/%d.png", timestamp)

	// Upload to Supabase Storage
	permanentURL, err := h.DB.UploadToStorage("podcasty", filename, imageData, "image/png")
	if err != nil {
		return "", fmt.Errorf("failed to upload to storage: %v", err)
	}

	return permanentURL, nil
}

// generateAudioInternal is a helper function to generate audio and return as data URL
func (h *Handler) generateAudioInternal(text, voice string) (string, error) {
	openAIReq := map[string]any{
		"model": "tts-1",
		"input": text,
		"voice": voice,
		"speed": 1.0,
	}

	reqBody, _ := json.Marshal(openAIReq)
	openAIURL := "https://api.openai.com/v1/audio/speech"

	httpReq, err := http.NewRequest("POST", openAIURL, bytes.NewBuffer(reqBody))
	if err != nil {
		return "", err
	}

	httpReq.Header.Set("Content-Type", "application/json")
	httpReq.Header.Set("Authorization", "Bearer "+h.Config.OpenAIAPIKey)

	client := &http.Client{}
	resp, err := client.Do(httpReq)
	if err != nil {
		return "", err
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		body, _ := io.ReadAll(resp.Body)
		return "", fmt.Errorf("OpenAI API error: %s", string(body))
	}

	// Read audio data
	audioData, err := io.ReadAll(resp.Body)
	if err != nil {
		return "", err
	}

	// Convert to base64 data URL
	base64Audio := base64.StdEncoding.EncodeToString(audioData)
	dataURL := fmt.Sprintf("data:audio/mpeg;base64,%s", base64Audio)

	return dataURL, nil
}

// GenerateImage generates AI cover image using DALL-E
func (h *Handler) GenerateImage(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}

	// Parse request
	var req struct {
		Prompt string `json:"prompt"`
		Size   string `json:"size"` // "1024x1024", "1792x1024", "1024x1792"
	}

	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		http.Error(w, "Invalid request body", http.StatusBadRequest)
		return
	}

	if req.Prompt == "" {
		http.Error(w, "prompt is required", http.StatusBadRequest)
		return
	}

	// Default size
	if req.Size == "" {
		req.Size = "1024x1024"
	}

	// Validate size
	validSizes := map[string]bool{
		"1024x1024": true,
		"1792x1024": true,
		"1024x1792": true,
	}
	if !validSizes[req.Size] {
		http.Error(w, "Invalid size. Must be 1024x1024, 1792x1024, or 1024x1792", http.StatusBadRequest)
		return
	}

	// Check if OpenAI API key is configured
	if h.Config.OpenAIAPIKey == "" {
		http.Error(w, "OpenAI API key not configured", http.StatusInternalServerError)
		return
	}

	// Call OpenAI DALL-E API
	openAIReq := map[string]any{
		"model":  "dall-e-3",
		"prompt": req.Prompt,
		"n":      1,
		"size":   req.Size,
	}

	reqBody, _ := json.Marshal(openAIReq)
	openAIURL := "https://api.openai.com/v1/images/generations"

	httpReq, err := http.NewRequest("POST", openAIURL, bytes.NewBuffer(reqBody))
	if err != nil {
		http.Error(w, "Failed to create request", http.StatusInternalServerError)
		return
	}

	httpReq.Header.Set("Content-Type", "application/json")
	httpReq.Header.Set("Authorization", "Bearer "+h.Config.OpenAIAPIKey)

	client := &http.Client{}
	resp, err := client.Do(httpReq)
	if err != nil {
		http.Error(w, "Failed to call OpenAI API", http.StatusInternalServerError)
		return
	}
	defer resp.Body.Close()

	body, _ := io.ReadAll(resp.Body)

	if resp.StatusCode != http.StatusOK {
		http.Error(w, fmt.Sprintf("OpenAI API error: %s", string(body)), resp.StatusCode)
		return
	}

	// Parse response
	var openAIResp struct {
		Data []struct {
			URL string `json:"url"`
		} `json:"data"`
	}

	if err := json.Unmarshal(body, &openAIResp); err != nil {
		http.Error(w, "Failed to parse OpenAI response", http.StatusInternalServerError)
		return
	}

	if len(openAIResp.Data) == 0 {
		http.Error(w, "No image generated", http.StatusInternalServerError)
		return
	}

	tempImageURL := openAIResp.Data[0].URL

	// Download the image from OpenAI's temporary URL
	imageData, err := downloadImage(tempImageURL)
	if err != nil {
		http.Error(w, fmt.Sprintf("Failed to download image: %v", err), http.StatusInternalServerError)
		return
	}

	// Generate a unique filename
	timestamp := time.Now().Unix()
	filename := fmt.Sprintf("podcast-covers/%d.png", timestamp)

	// Upload to Supabase Storage
	permanentURL, err := h.DB.UploadToStorage("podcasty", filename, imageData, "image/png")
	if err != nil {
		http.Error(w, fmt.Sprintf("Failed to upload to storage: %v", err), http.StatusInternalServerError)
		return
	}

	response := map[string]any{
		"image_url": permanentURL,
		"prompt":    req.Prompt,
		"size":      req.Size,
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(response)
}

// downloadImage downloads an image from a URL and returns the image data
func downloadImage(url string) ([]byte, error) {
	resp, err := http.Get(url)
	if err != nil {
		return nil, err
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		return nil, fmt.Errorf("failed to download image: status code %d", resp.StatusCode)
	}

	return io.ReadAll(resp.Body)
}

// GenerateAudio generates AI audio using OpenAI TTS
func (h *Handler) GenerateAudio(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}

	// Parse request
	var req struct {
		Text  string  `json:"text"`
		Voice string  `json:"voice"` // alloy, echo, fable, onyx, nova, shimmer
		Speed float64 `json:"speed"` // 0.25 to 4.0
	}

	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		http.Error(w, "Invalid request body", http.StatusBadRequest)
		return
	}

	if req.Text == "" {
		http.Error(w, "text is required", http.StatusBadRequest)
		return
	}

	// Default voice
	if req.Voice == "" {
		req.Voice = "alloy"
	}

	// Default speed
	if req.Speed == 0 {
		req.Speed = 1.0
	}

	// Validate voice
	validVoices := map[string]bool{
		"alloy":   true,
		"echo":    true,
		"fable":   true,
		"onyx":    true,
		"nova":    true,
		"shimmer": true,
	}
	if !validVoices[req.Voice] {
		http.Error(w, "Invalid voice. Must be one of: alloy, echo, fable, onyx, nova, shimmer", http.StatusBadRequest)
		return
	}

	// Validate speed
	if req.Speed < 0.25 || req.Speed > 4.0 {
		http.Error(w, "Invalid speed. Must be between 0.25 and 4.0", http.StatusBadRequest)
		return
	}

	// Check if OpenAI API key is configured
	if h.Config.OpenAIAPIKey == "" {
		http.Error(w, "OpenAI API key not configured", http.StatusInternalServerError)
		return
	}

	// Call OpenAI TTS API
	openAIReq := map[string]any{
		"model": "tts-1",
		"input": req.Text,
		"voice": req.Voice,
		"speed": req.Speed,
	}

	reqBody, _ := json.Marshal(openAIReq)
	openAIURL := "https://api.openai.com/v1/audio/speech"

	httpReq, err := http.NewRequest("POST", openAIURL, bytes.NewBuffer(reqBody))
	if err != nil {
		http.Error(w, "Failed to create request", http.StatusInternalServerError)
		return
	}

	httpReq.Header.Set("Content-Type", "application/json")
	httpReq.Header.Set("Authorization", "Bearer "+h.Config.OpenAIAPIKey)

	client := &http.Client{}
	resp, err := client.Do(httpReq)
	if err != nil {
		http.Error(w, "Failed to call OpenAI API", http.StatusInternalServerError)
		return
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		body, _ := io.ReadAll(resp.Body)
		http.Error(w, fmt.Sprintf("OpenAI API error: %s", string(body)), resp.StatusCode)
		return
	}

	// Return the audio file directly
	// Note: In production, you would upload this to storage (Supabase, S3, etc.)
	// and return the URL instead of streaming the audio
	w.Header().Set("Content-Type", "audio/mpeg")
	w.Header().Set("Content-Disposition", "attachment; filename=\"podcast.mp3\"")

	_, err = io.Copy(w, resp.Body)
	if err != nil {
		// Error already sent to client at this point
		return
	}
}
