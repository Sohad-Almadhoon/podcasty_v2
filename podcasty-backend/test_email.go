//go:build ignore

package main

import (
	"fmt"
	"log"

	"github.com/podcasty-go/config"
	"github.com/podcasty-go/notifier"
)

func main() {
	cfg, err := config.Load()
	if err != nil {
		log.Fatal(err)
	}

	n := notifier.New(cfg)
	fmt.Printf("SMTP Host: %s\n", cfg.SMTPHost)
	fmt.Printf("SMTP Port: %s\n", cfg.SMTPPort)
	fmt.Printf("SMTP From: %s\n", cfg.SMTPFrom)
	fmt.Printf("Notifier enabled: %v\n", n.Enabled())

	if !n.Enabled() {
		log.Fatal("Notifier is not enabled — check your SMTP_HOST in .env")
	}

	err = n.Send(
		"sohadmadhoon2021@gmail.com",
		"Podcasty test email",
		`<div style="font-family: sans-serif; max-width: 400px;">
			<h2 style="color: #9333ea;">It works!</h2>
			<p>Your Podcasty email notifications are set up correctly.</p>
			<p style="color: #888; font-size: 12px;">You can delete test_email.go now.</p>
		</div>`,
	)

	if err != nil {
		log.Fatalf("FAILED: %v", err)
	}

	fmt.Println("Email sent successfully! Check your inbox.")
}
