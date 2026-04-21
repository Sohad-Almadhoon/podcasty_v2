// Package notifier handles sending email notifications using net/smtp.
//
// If SMTP_HOST is not configured, Send becomes a no-op (logs only) so the rest
// of the application keeps working in dev. This avoids hard-coupling to an
// external mail provider.
package notifier

import (
	"fmt"
	"log"
	"net/smtp"
	"strings"

	"github.com/podcasty-go/config"
)

// Notifier sends transactional emails.
type Notifier struct {
	cfg *config.Config
}

// New creates a new Notifier.
func New(cfg *config.Config) *Notifier {
	return &Notifier{cfg: cfg}
}

// Enabled reports whether SMTP is configured.
func (n *Notifier) Enabled() bool {
	return n.cfg != nil && n.cfg.SMTPHost != "" && n.cfg.SMTPFrom != ""
}

// Send delivers a single plain-text or HTML email.
//
// `to` is the recipient address. `subject` and `body` are the email subject
// and HTML body. If `Enabled()` is false, this logs and returns nil.
func (n *Notifier) Send(to, subject, body string) error {
	if !n.Enabled() {
		log.Printf("📭 [notifier] SMTP not configured, skipping email to %s (subject: %q)", to, subject)
		return nil
	}
	if strings.TrimSpace(to) == "" {
		return fmt.Errorf("notifier: empty recipient")
	}

	addr := fmt.Sprintf("%s:%s", n.cfg.SMTPHost, n.cfg.SMTPPort)

	headers := map[string]string{
		"From":         n.cfg.SMTPFrom,
		"To":           to,
		"Subject":      subject,
		"MIME-Version": "1.0",
		"Content-Type": "text/html; charset=UTF-8",
	}

	var msg strings.Builder
	for k, v := range headers {
		fmt.Fprintf(&msg, "%s: %s\r\n", k, v)
	}
	msg.WriteString("\r\n")
	msg.WriteString(body)

	var auth smtp.Auth
	if n.cfg.SMTPUsername != "" {
		auth = smtp.PlainAuth("", n.cfg.SMTPUsername, n.cfg.SMTPPassword, n.cfg.SMTPHost)
	}

	if err := smtp.SendMail(addr, auth, n.cfg.SMTPFrom, []string{to}, []byte(msg.String())); err != nil {
		log.Printf("❌ [notifier] SendMail failed for %s: %v", to, err)
		return err
	}

	log.Printf("📨 [notifier] Sent email to %s (subject: %q)", to, subject)
	return nil
}

// SendAsync runs Send in a goroutine and logs any error. Use this from request
// handlers so a slow SMTP server can't block the HTTP response.
func (n *Notifier) SendAsync(to, subject, body string) {
	go func() {
		if err := n.Send(to, subject, body); err != nil {
			log.Printf("❌ [notifier] async send failed: %v", err)
		}
	}()
}
