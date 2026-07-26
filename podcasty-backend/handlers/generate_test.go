package handlers

import (
	"errors"
	"net/http"
	"testing"
)

// The fallback chain hinges entirely on this classification: misjudge it and
// generation either gives up on a model that was merely rate-limited, or
// hammers every candidate with a prompt OpenAI will always reject.
func TestIsModelUnavailable(t *testing.T) {
	cases := []struct {
		name string
		err  error
		want bool
	}{
		{
			name: "retired model",
			err:  &upstreamError{Status: http.StatusBadRequest, Message: "The model 'dall-e-3' does not exist."},
			want: true,
		},
		{
			name: "key lacks permission",
			err:  &upstreamError{Status: http.StatusNotFound, Message: "The model 'gpt-image-1' does not exist or you do not have access to it."},
			want: true,
		},
		{
			name: "project forbidden",
			err:  &upstreamError{Status: http.StatusForbidden, Message: "Project does not have access to model_not_found"},
			want: true,
		},
		{
			name: "rate limited",
			err:  &upstreamError{Status: http.StatusTooManyRequests, Message: "Rate limit reached"},
			want: false,
		},
		{
			name: "no credit",
			err:  &upstreamError{Status: http.StatusTooManyRequests, Message: "OpenAI account has no remaining credit"},
			want: false,
		},
		{
			name: "content policy rejection is a 400 but not a model problem",
			err:  &upstreamError{Status: http.StatusBadRequest, Message: "Your request was rejected by our safety system."},
			want: false,
		},
		{
			name: "transport failure",
			err:  errors.New("dial tcp: i/o timeout"),
			want: false,
		},
	}

	for _, tc := range cases {
		t.Run(tc.name, func(t *testing.T) {
			if got := isModelUnavailable(tc.err); got != tc.want {
				t.Errorf("isModelUnavailable(%v) = %v, want %v", tc.err, got, tc.want)
			}
		})
	}
}

// Generation and publish validated voices from separate lists, so a voice one
// accepted the other rejected — producing a finished episode that refused to
// save. Both now read ttsVoices; this pins the set so shrinking it is
// deliberate rather than a silent break of whatever the clients offer.
func TestVoicesCoverWhatClientsOffer(t *testing.T) {
	// The voices the web form and the Flutter app put in their dropdowns.
	clientOffered := []string{"alloy", "coral", "echo", "fable", "onyx", "nova", "shimmer"}

	for _, v := range clientOffered {
		if !isValidVoice(v) {
			t.Errorf("voice %q is offered by the clients but rejected by the API", v)
		}
	}

	if isValidVoice("nonexistent-voice") {
		t.Error("isValidVoice accepted a voice that does not exist")
	}
	if isValidVoice("") {
		t.Error("isValidVoice accepted an empty voice; callers must default it explicitly")
	}
}

// An exhausted account and a rate limit share status 429 but need opposite
// responses: one is worth retrying, the other never is.
func TestOpenAIErrorDistinguishesQuotaFromRateLimit(t *testing.T) {
	quota := openAIError(http.StatusTooManyRequests,
		[]byte(`{"error":{"message":"You exceeded your current quota.","code":"insufficient_quota"}}`))
	if quota.Retryable {
		t.Error("insufficient_quota must not be retryable")
	}

	limit := openAIError(http.StatusTooManyRequests,
		[]byte(`{"error":{"message":"Rate limit reached for requests","code":"rate_limit_exceeded"}}`))
	if !limit.Retryable {
		t.Error("rate_limit_exceeded must be retryable")
	}

	// A body that isn't the documented envelope must still yield a usable message.
	plain := openAIError(http.StatusBadGateway, []byte("upstream unavailable"))
	if plain.Message != "upstream unavailable" || !plain.Retryable {
		t.Errorf("unparseable body: got %+v", plain)
	}
}
