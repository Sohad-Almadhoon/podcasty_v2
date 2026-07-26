package handlers

import (
	"bytes"
	"encoding/base64"
	"encoding/json"
	"errors"
	"fmt"
	"io"
	"log"
	"net/http"
	"sort"
	"strconv"
	"strings"
	"time"
)

// openAIMaxAttempts bounds how many times a single OpenAI call is retried when
// the API answers 429 or 5xx. Keep it small: the caller is a user sitting on a
// form submission, and image + audio generation is already slow.
const openAIMaxAttempts = 3

// ttsMaxInput is the input ceiling for the tts-1 model. Anything longer is
// rejected by OpenAI with a 400 that reads like a generic bad request.
const ttsMaxInput = 4096

// Shared clients so connections are reused. The zero http.Client has no timeout
// at all, which lets a stalled call hold the request open indefinitely — the
// kind of long-lived connection that upstream proxies throttle.
var (
	openAIClient        = &http.Client{Timeout: 2 * time.Minute}
	imageDownloadClient = &http.Client{Timeout: 60 * time.Second}
)

// upstreamError carries the status a third-party API responded with, so the
// handler can relay it rather than flattening every failure into a 500. A
// client that receives 429 can back off; one that receives 500 cannot tell
// whether to retry, fix its input, or top up an account.
type upstreamError struct {
	Status    int
	Message   string
	Retryable bool
}

func (e *upstreamError) Error() string { return e.Message }

// statusOf reports the status an error should be relayed to the client as,
// defaulting to 500 for anything that isn't an upstream failure.
func statusOf(err error) int {
	var ue *upstreamError
	if errors.As(err, &ue) {
		return ue.Status
	}
	return http.StatusInternalServerError
}

// openAIError turns an OpenAI failure payload into a message worth showing.
// The API wraps errors in {"error": {"message": ..., "code": ...}}; the raw
// body is the fallback for anything that doesn't parse.
func openAIError(status int, body []byte) *upstreamError {
	var parsed struct {
		Error struct {
			Message string `json:"message"`
			Code    string `json:"code"`
			Type    string `json:"type"`
		} `json:"error"`
	}

	msg := strings.TrimSpace(string(body))
	retryable := status == http.StatusTooManyRequests || status >= 500

	if err := json.Unmarshal(body, &parsed); err == nil && parsed.Error.Message != "" {
		msg = parsed.Error.Message
		// A 429 means two different things and the fixes are unrelated: a rate
		// limit clears on its own, an exhausted account never will.
		if parsed.Error.Code == "insufficient_quota" {
			msg = "OpenAI account has no remaining credit: " + msg
			retryable = false
		}
	}

	if msg == "" {
		msg = http.StatusText(status)
	}
	if r := []rune(msg); len(r) > 500 {
		msg = string(r[:500]) + "..."
	}

	return &upstreamError{Status: status, Message: msg, Retryable: retryable}
}

// backoffFor reports how long to wait before retrying attempt n. OpenAI's
// Retry-After wins when present, capped so a long hint can't stall the request
// past the client's own patience.
func backoffFor(attempt int, retryAfter string) time.Duration {
	if secs, err := strconv.Atoi(strings.TrimSpace(retryAfter)); err == nil && secs > 0 {
		if d := time.Duration(secs) * time.Second; d < 30*time.Second {
			return d
		}
		return 30 * time.Second
	}
	return time.Duration(1<<uint(attempt-1)) * time.Second
}

// callOpenAI POSTs payload to an OpenAI endpoint and returns the response body,
// retrying transient failures with backoff. The body is read in full either
// way: image responses are JSON, audio responses are the raw MP3.
func callOpenAI(apiKey, url string, payload any) ([]byte, error) {
	reqBody, err := json.Marshal(payload)
	if err != nil {
		return nil, err
	}

	var lastErr error

	for attempt := 1; attempt <= openAIMaxAttempts; attempt++ {
		httpReq, err := http.NewRequest("POST", url, bytes.NewReader(reqBody))
		if err != nil {
			return nil, err
		}
		httpReq.Header.Set("Content-Type", "application/json")
		httpReq.Header.Set("Authorization", "Bearer "+apiKey)

		resp, err := openAIClient.Do(httpReq)
		if err != nil {
			lastErr = err
			if attempt == openAIMaxAttempts {
				break
			}
			time.Sleep(backoffFor(attempt, ""))
			continue
		}

		body, readErr := io.ReadAll(resp.Body)
		retryAfter := resp.Header.Get("Retry-After")
		status := resp.StatusCode
		resp.Body.Close()

		if readErr != nil {
			lastErr = readErr
			if attempt == openAIMaxAttempts {
				break
			}
			time.Sleep(backoffFor(attempt, ""))
			continue
		}

		if status == http.StatusOK {
			return body, nil
		}

		apiErr := openAIError(status, body)
		lastErr = apiErr

		// A bad prompt, revoked key, or content-policy rejection fails
		// identically no matter how many times it is sent.
		if !apiErr.Retryable || attempt == openAIMaxAttempts {
			break
		}
		time.Sleep(backoffFor(attempt, retryAfter))
	}

	return nil, lastErr
}

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

	// The prompt doubles as the TTS input, so reject anything the speech model
	// will refuse before spending a DALL-E call on it.
	if len(req.Prompt) > ttsMaxInput {
		http.Error(w, fmt.Sprintf("prompt must be %d characters or fewer", ttsMaxInput), http.StatusBadRequest)
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
		log.Printf("⚠️ [generate] image failed (%d): %v", statusOf(err), err)
		http.Error(w, fmt.Sprintf("Failed to generate image: %v", err), statusOf(err))
		return
	}

	// 2. Generate audio using TTS
	audioURL, err := h.generateAudioInternal(req.Prompt, req.Voice)
	if err != nil {
		log.Printf("⚠️ [generate] audio failed (%d): %v", statusOf(err), err)
		http.Error(w, fmt.Sprintf("Failed to generate audio: %v", err), statusOf(err))
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

// imageModelCandidates lists the image models to try, in order. An explicit
// OPENAI_IMAGE_MODEL is used on its own: if an operator named a model,
// quietly substituting another would hide their mistake. With nothing set,
// walk OpenAI's image models newest-first, because which ones a given key can
// reach depends on the account and on what OpenAI has since retired.
func (h *Handler) imageModelCandidates() []string {
	if m := strings.TrimSpace(h.Config.OpenAIImageModel); m != "" {
		return []string{m}
	}
	return []string{"gpt-image-1", "dall-e-3", "dall-e-2"}
}

// isModelUnavailable reports whether a failure means "this key cannot use this
// model". A retired model and a project-scoped key lacking permission for a
// live one are indistinguishable in OpenAI's response, and both are worth
// trying the next candidate for.
func isModelUnavailable(err error) bool {
	var ue *upstreamError
	if !errors.As(err, &ue) {
		return false
	}
	switch ue.Status {
	case http.StatusBadRequest, http.StatusNotFound, http.StatusForbidden:
	default:
		return false
	}
	msg := strings.ToLower(ue.Message)
	return strings.Contains(msg, "does not exist") ||
		strings.Contains(msg, "model_not_found") ||
		strings.Contains(msg, "do not have access")
}

// accessibleImageModels asks OpenAI which models this key can actually reach,
// so a model-unavailable failure can name the alternatives instead of leaving
// whoever reads the error to guess. Best-effort: any failure yields no names.
func accessibleImageModels(apiKey string) []string {
	req, err := http.NewRequest("GET", "https://api.openai.com/v1/models", nil)
	if err != nil {
		return nil
	}
	req.Header.Set("Authorization", "Bearer "+apiKey)

	resp, err := openAIClient.Do(req)
	if err != nil {
		return nil
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		return nil
	}

	var parsed struct {
		Data []struct {
			ID string `json:"id"`
		} `json:"data"`
	}
	if err := json.NewDecoder(resp.Body).Decode(&parsed); err != nil {
		return nil
	}

	var out []string
	for _, m := range parsed.Data {
		if strings.Contains(m.ID, "image") || strings.HasPrefix(m.ID, "dall-e") {
			out = append(out, m.ID)
		}
	}
	sort.Strings(out)
	return out
}

// generateImageInternal generates a cover image, falling through the candidate
// models until one is reachable.
func (h *Handler) generateImageInternal(prompt string) (string, error) {
	candidates := h.imageModelCandidates()

	var lastErr error
	for _, model := range candidates {
		url, err := h.requestImage(model, prompt)
		if err == nil {
			return url, nil
		}
		lastErr = err
		if !isModelUnavailable(err) {
			return "", err
		}
		log.Printf("⚠️ [generate] image model %q unavailable: %v", model, err)
	}

	// Every candidate was rejected. Say what the key can actually reach — that
	// is the one thing the operator needs and cannot see from here.
	suffix := fmt.Sprintf("tried %s", strings.Join(candidates, ", "))
	if models := accessibleImageModels(h.Config.OpenAIAPIKey); len(models) > 0 {
		suffix += fmt.Sprintf("; this API key can use: %s — set OPENAI_IMAGE_MODEL to one of them",
			strings.Join(models, ", "))
	} else {
		suffix += "; this API key lists no image models at all — check the project's model permissions"
	}

	return "", &upstreamError{
		Status:  statusOf(lastErr),
		Message: fmt.Sprintf("%v (%s)", lastErr, suffix),
	}
}

// requestImage generates one image with a specific model and stores it.
func (h *Handler) requestImage(model, prompt string) (string, error) {
	body, err := callOpenAI(h.Config.OpenAIAPIKey, "https://api.openai.com/v1/images/generations", map[string]any{
		"model":  model,
		"prompt": prompt,
		"n":      1,
		"size":   "1024x1024",
	})
	if err != nil {
		return "", err
	}

	// dall-e-3 answers with a temporary URL; the newer image models return the
	// bytes inline as base64 and never populate url. Handle both so switching
	// OPENAI_IMAGE_MODEL doesn't need a code change.
	var openAIResp struct {
		Data []struct {
			URL     string `json:"url"`
			B64JSON string `json:"b64_json"`
		} `json:"data"`
	}

	if err := json.Unmarshal(body, &openAIResp); err != nil {
		return "", err
	}

	if len(openAIResp.Data) == 0 {
		return "", fmt.Errorf("no image generated")
	}

	var imageData []byte
	switch {
	case openAIResp.Data[0].URL != "":
		imageData, err = downloadImage(openAIResp.Data[0].URL)
		if err != nil {
			return "", fmt.Errorf("failed to download image: %v", err)
		}
	case openAIResp.Data[0].B64JSON != "":
		imageData, err = base64.StdEncoding.DecodeString(openAIResp.Data[0].B64JSON)
		if err != nil {
			return "", fmt.Errorf("failed to decode image: %v", err)
		}
	default:
		return "", fmt.Errorf("image response contained neither url nor b64_json")
	}

	// Generate a unique filename. Second precision collides when two podcasts
	// are created in the same second, silently overwriting the first cover.
	filename := fmt.Sprintf("podcast-covers/%d.png", time.Now().UnixNano())

	// Upload to Supabase Storage
	permanentURL, err := h.DB.UploadToStorage("podcasty", filename, imageData, "image/png")
	if err != nil {
		return "", fmt.Errorf("failed to upload to storage: %v", err)
	}

	return permanentURL, nil
}

// generateAudioInternal is a helper function to generate audio and return as data URL
func (h *Handler) generateAudioInternal(text, voice string) (string, error) {
	audioData, err := callOpenAI(h.Config.OpenAIAPIKey, "https://api.openai.com/v1/audio/speech", map[string]any{
		"model": h.Config.OpenAITTSModel,
		"input": text,
		"voice": voice,
		"speed": 1.0,
	})
	if err != nil {
		return "", err
	}

	// Upload to Supabase Storage and store a URL, the same way cover art is
	// handled. Returning a base64 data URL instead would put the whole MP3 in
	// the podcasts row, where every query that touches the table pays for it.
	filename := fmt.Sprintf("podcast-audio/%d.mp3", time.Now().UnixNano())

	permanentURL, err := h.DB.UploadToStorage("podcasty", filename, audioData, "audio/mpeg")
	if err != nil {
		return "", fmt.Errorf("failed to upload audio to storage: %v", err)
	}

	return permanentURL, nil
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
		"model":  h.Config.OpenAIImageModel,
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
	resp, err := imageDownloadClient.Get(url)
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
		"model": h.Config.OpenAITTSModel,
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
