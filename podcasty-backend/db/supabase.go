package db

import (
	"bytes"
	"encoding/json"
	"fmt"
	"io"
	"net/http"
)

// SupabaseClient holds the Supabase connection details
type SupabaseClient struct {
	URL        string
	ServiceKey string
	HTTPClient *http.Client
}

// NewSupabaseClient creates a new Supabase client
func NewSupabaseClient(url, serviceKey string) *SupabaseClient {
	return &SupabaseClient{
		URL:        url,
		ServiceKey: serviceKey,
		HTTPClient: &http.Client{},
	}
}

// Query executes a query against Supabase REST API
func (c *SupabaseClient) Query(table string, method string, body any) ([]byte, error) {
	var reqBody io.Reader
	if body != nil {
		jsonData, err := json.Marshal(body)
		if err != nil {
			return nil, err
		}
		reqBody = bytes.NewBuffer(jsonData)
		fmt.Printf("🔵 Supabase %s Request to %s\n", method, table)
		fmt.Printf("🔵 Body: %s\n", string(jsonData))
	}

	req, err := http.NewRequest(method, fmt.Sprintf("%s/rest/v1/%s", c.URL, table), reqBody)
	if err != nil {
		return nil, err
	}

	req.Header.Set("apikey", c.ServiceKey)
	req.Header.Set("Authorization", "Bearer "+c.ServiceKey)
	req.Header.Set("Content-Type", "application/json")

	// For POST/PATCH/DELETE, request the representation to be returned
	if method == http.MethodPost || method == http.MethodPatch {
		req.Header.Set("Prefer", "return=representation")
	}

	fmt.Printf("🔵 Full URL: %s\n", req.URL.String())

	resp, err := c.HTTPClient.Do(req)
	if err != nil {
		return nil, err
	}
	defer resp.Body.Close()

	respData, err := io.ReadAll(resp.Body)
	if err != nil {
		return nil, err
	}

	fmt.Printf("🔵 Response Status: %d\n", resp.StatusCode)
	fmt.Printf("🔵 Response Body: %s\n", string(respData))

	// Check for error status codes
	if resp.StatusCode >= 400 {
		return nil, fmt.Errorf("supabase error (status %d): %s", resp.StatusCode, string(respData))
	}

	return respData, nil
}

// GetAuthUser fetches a user from Supabase Auth admin API by ID
func (c *SupabaseClient) GetAuthUser(userID string) (map[string]any, error) {
	if c.ServiceKey == "" {
		return nil, fmt.Errorf("SUPABASE_SERVICE_KEY not configured - cannot access auth admin API")
	}

	authAdminURL := fmt.Sprintf("%s/auth/v1/admin/users/%s", c.URL, userID)
	fmt.Printf("🔐 Fetching auth user from: %s\n", authAdminURL)

	req, err := http.NewRequest(http.MethodGet, authAdminURL, nil)
	if err != nil {
		return nil, err
	}

	req.Header.Set("apikey", c.ServiceKey)
	req.Header.Set("Authorization", "Bearer "+c.ServiceKey)

	resp, err := c.HTTPClient.Do(req)
	if err != nil {
		fmt.Printf("❌ HTTP request failed: %v\n", err)
		return nil, err
	}
	defer resp.Body.Close()

	respData, err := io.ReadAll(resp.Body)
	if err != nil {
		return nil, err
	}

	fmt.Printf("🔐 Auth API Response Status: %d\n", resp.StatusCode)

	if resp.StatusCode >= 400 {
		fmt.Printf("❌ Auth API Error: %s\n", string(respData))
		return nil, fmt.Errorf("auth user not found (status %d): %s", resp.StatusCode, string(respData))
	}

	var authUser map[string]any
	if err := json.Unmarshal(respData, &authUser); err != nil {
		return nil, err
	}

	fmt.Printf("✅ Auth user fetched successfully\n")
	return authUser, nil
}

// UploadToStorage uploads a file to Supabase Storage and returns the public URL
func (c *SupabaseClient) UploadToStorage(bucket, filePath string, fileData []byte, contentType string) (string, error) {
	if c.ServiceKey == "" {
		return "", fmt.Errorf("SUPABASE_SERVICE_KEY not configured")
	}

	// Storage API endpoint
	storageURL := fmt.Sprintf("%s/storage/v1/object/%s/%s", c.URL, bucket, filePath)
	fmt.Printf("📤 Uploading to storage: %s\n", storageURL)

	req, err := http.NewRequest(http.MethodPost, storageURL, bytes.NewBuffer(fileData))
	if err != nil {
		return "", err
	}

	req.Header.Set("apikey", c.ServiceKey)
	req.Header.Set("Authorization", "Bearer "+c.ServiceKey)
	req.Header.Set("Content-Type", contentType)
	req.Header.Set("Cache-Control", "3600")

	resp, err := c.HTTPClient.Do(req)
	if err != nil {
		return "", err
	}
	defer resp.Body.Close()

	respData, err := io.ReadAll(resp.Body)
	if err != nil {
		return "", err
	}

	fmt.Printf("📤 Storage Response Status: %d\n", resp.StatusCode)
	fmt.Printf("📤 Storage Response: %s\n", string(respData))

	if resp.StatusCode >= 400 {
		return "", fmt.Errorf("storage upload error (status %d): %s", resp.StatusCode, string(respData))
	}

	// Return the public URL
	publicURL := fmt.Sprintf("%s/storage/v1/object/public/%s/%s", c.URL, bucket, filePath)
	fmt.Printf("✅ File uploaded successfully: %s\n", publicURL)
	return publicURL, nil
}
