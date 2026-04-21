# Podcasty — Mobile (Flutter)

Cross-platform mobile client for Podcasty. Targets Android and iOS, talks to the Go backend, and uses Supabase for auth.

## Stack

- Flutter (Dart SDK `>=3.0.0 <4.0.0`)
- `provider` for state
- `just_audio` + `audio_service` for background playback
- `supabase_flutter` + `google_sign_in` for auth
- `http` for backend calls, `shared_preferences` for local cache

## Getting started

```bash
flutter pub get
flutter run                        # picks up a connected device / emulator
```

Build: `flutter build apk` / `flutter build ios`.

## Configuration

Backend URL and Supabase keys are read from the app's config (see `lib/services/`). Update them to point at your running `podcasty-go` instance and Supabase project.

## Layout

```
lib/
  main.dart       app entry
  screens/        full-page UIs (feed, player, library, profile, …)
  widgets/        reusable UI components
  providers/      state (auth, player, library)
  services/       API clients + Supabase/auth integration
  models/         DTOs mirroring the backend JSON
  theme/          colors, typography
  examples/       scratch code — safe to ignore
assets/
  images/  icons/
android/  ios/    platform projects
test/             widget tests
```

## Related

- Web client: [../podcasty-web/](../podcasty-web/)
- Backend API: [../podcasty-backend/](../podcasty-backend/)
