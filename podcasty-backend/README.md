# Podcasty — Backend (Go)

HTTP API for Podcasty. Written in plain Go (no web framework), backed by Supabase for Postgres + auth, with OpenAI for podcast generation and SMTP for the weekly digest.

## Stack

- Go 1.22, `net/http` standard library router
- Supabase (PostgREST + Auth) via the service-role key
- OpenAI API (podcast script + audio generation)
- Optional SMTP for weekly-digest emails

## Getting started

```bash
cp .env.example .env                 # fill in Supabase + OpenAI keys
go mod download
go run .                             # listens on :8080
```

Build: `go build -o podcasty-go .`

## Environment

See `.env.example`. Required: `SUPABASE_URL`, `SUPABASE_ANON_KEY`, `SUPABASE_SERVICE_KEY`, `OPENAI_API_KEY`. Optional: `GOOGLE_CLIENT_ID/SECRET` (OAuth), `SMTP_*` (digest email), `PORT`, `FRONTEND_URL`.

## Layout

```
main.go            entry point; wires config, db, handlers, routes, digest worker
config/            env loading + validation
db/supabase.go     thin Supabase REST client
handlers/          one file per resource (podcasts, feed, playlists,
                   series, comments, bookmarks, follows, likes,
                   notifications, badges, leaderboard, analytics,
                   auth, users, generate, transcript, rss, embed, …)
middleware/        auth middleware (JWT verification)
routes/            route registration (all endpoints live here)
digest/            weekly-digest background worker
notifier/          SMTP sender (no-op when SMTP unset)
migrations/        ordered SQL migrations (apply in numeric order)
schema.sql         canonical schema reference
templates/         server-rendered HTML (embed, RSS)
static/            static files served by the Go binary
```

## Database

Apply migrations in order from `migrations/` against your Supabase Postgres. `schema.sql` is the full reference schema.

## Digest worker

`main.go` starts `digest.Worker` in-process. It no-ops when SMTP is unconfigured. If you scale horizontally, move it to an external cron hitting an admin endpoint.

## Related

- Web client: [../podcasty-web/](../podcasty-web/)
- Mobile client: [../podcasty-mobile/](../podcasty-mobile/)
