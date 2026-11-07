# Itqan Journey feature

The journey product surface is under `lib/features/itqan_journey/`. It uses the existing `AuthService`, Riverpod, Hive, HTTP client, local Quran data and reader, prayer/notification services, and `url_launcher`. Bundled Uthmani text is displayed verbatim from the licensed Tanzil source; the existing Tanzil metadata provides the page, juz and hizb-quarter boundaries. Existing Quran, adhkar and dua screens remain available.

## Layers and user flows

- `data/journey_content_repository.dart` reads bundled dua/adhkar text and retains the feature-local Quran position store.
- `application/itqan_journey_provider.dart` owns the protected API calls, typed API failures, Riverpod state, idempotent activity requests, and a local pending-activity outbox.
- `presentation/journey_dashboard_screen.dart` displays backend profile/task data and links the Quran, adhkar, dua, sharing, achievement, leaderboard and profile surfaces.
- `presentation/achievements_screen.dart` is shared by the dashboard, profile and drawer. `profile_screen.dart` shows server-reported XP, Coins, level, streak, task and achievement summaries.
- The Quran journey opens the existing 604-page reader at the last locally saved page. A reading session is only submitted after active foreground time and unique-page thresholds; the server remains authoritative for acceptance and rewards.
- Adhkar counts and dua favorites/read confirmations persist locally by local calendar day. These local values do not award XP or Coins. The server acceptance response is the only reward source.
- Share-by-email and copy are best-effort user actions. Opening another app or copying text does not prove that content was sent, so the current screen explicitly does not award a share activity.

## API and data integrity

All journey requests use bearer authentication and the existing `/api/v1/` endpoints. Activity requests use UUID idempotency keys. Network/server failures retain queued events in Hive for later retry with the same key; queued events are scoped to the saved account email and do not affect displayed balances. Permanent client validation errors are removed from the outbox. A 401 clears the active token and identity. Live endpoint behavior and the exact server-side metadata validation have not been exercised in this authoring session.

The runtime packages already include Hive, secure storage, local notifications, timezone, HTTP and URL launcher. `uuid ^4.5.1` is now declared directly because the journey code imports it; resolution in this environment selected a compatible 4.x release. No other runtime package was added. The repository initially had no `pubspec.lock`.

## Validation completed

- `flutter pub get` completed on Flutter 3.47.9 / Dart 3.13.7 in the isolated work copy.
- `flutter analyze --no-pub` reported 75 informational lint/deprecation findings, 0 warnings and 0 errors (Flutter exits non-zero when informational findings are present). The full Flutter test suite passed: 143 tests.
- The full Flutter test suite and targeted secure-storage/outbox tests pass in the isolated work copy.
- No APK/AAB build, device test, release signing, deployment or repository push was performed.

## Remaining external/manual work

- Verify login, all protected API response shapes, activities, rate limits, 401 handling, and queued-event idempotency against the live backend and its current metadata validator.
- Test RTL, Android back behavior, permission flows, notification scheduling, and reader active-time behavior on physical devices.
- The legacy contributor registration screen still contains a client-side bearer credential. A client-embedded credential cannot be made secret; rotate it and move that operation behind a server-side endpoint before production use. The backend is not present in this Flutter repository, and no contribution/payment flow was altered here.
- Share delivery cannot be independently verified through the current URL launcher flow; rewards must remain disabled until a verifiable server-mediated flow exists.
- Release build remains intentionally unrun pending explicit user approval.
