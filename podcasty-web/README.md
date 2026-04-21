# Podcasty — Web (Next.js)

The web client for Podcasty. Built with Next.js 15 (App Router), TypeScript, Tailwind, and shadcn/ui on top of Radix primitives. Auth and data are handled via Supabase; the Go service (`podcasty-go/`) powers the API.

## Stack

- Next.js 15 + React 18, App Router, TypeScript
- Tailwind CSS + shadcn/ui (Radix)
- Supabase (`@supabase/ssr`) for auth/session
- `react-hook-form` + `zod` for forms
- `axios` for API calls to the Go backend

## Getting started

```bash
npm install
cp .env.local.example .env.local   # fill in Supabase + backend URL
npm run dev                        # http://localhost:3000
```

Other scripts: `npm run build`, `npm start`, `npm run lint`.

## Environment

Set in `.env.local`:

- `NEXT_PUBLIC_SUPABASE_URL`
- `NEXT_PUBLIC_SUPABASE_ANON_KEY`
- `NEXT_PUBLIC_API_URL` — URL of the Go backend (default `http://localhost:8080`)

See `.env.local.example` for the full list.

## Layout

```
app/
  (pages)/        route groups — podcasts, feed, playlists, series,
                  bookmarks, analytics, leaderboard, profile, settings
  api/auth/       Supabase OAuth callback routes
  constants/      shared constants
  lib/            client helpers (supabase client, fetchers)
  providers/      React context providers (theme, auth, player)
  types/          shared TS types
  middleware.ts   auth/route protection
components/
  ui/             shadcn/ui primitives
  shared/         reusable composite components
  buttons/  forms/  modals/
lib/utils.ts      `cn()` helper
public/images/    static assets
```

## Related

- Backend API: [../podcasty-backend/](../podcasty-backend/)
- Mobile client: [../podcasty-mobile/](../podcasty-mobile/)
