# Itqan Journey feature

The journey product surface is under `lib/features/itqan_journey/`. It uses the existing `AuthService`, Riverpod, Hive, HTTP client, local Quran data and reader, prayer/notification services, and `url_launcher`. Bundled Uthmani text is displayed verbatim from the licensed Tanzil source; the existing Tanzil metadata provides the page, juz and hizb-quarter boundaries. Existing Quran, adhkar and dua screens remain available.

## Layers and user flows

- `data/journey_content_repository.dart` reads bundled dua/adhkar text and retains the feature-local Quran position store.
- `application/itqan_journey_provider.dart` owns the protected API calls, typed API failures, Riverpod state, idempotent activity requests, and a local pending-activity outbox.
- `presentation/journey_dashboard_screen.dart` displays backend profile/task data and links the Quran, adhkar, dua, sharing, achievement, leaderboard and profile surfaces.
- `presentation/achievements_screen.dart` is shared by the dashboard, profile and drawer. `profile_screen.dart` shows server-reported XP, Coins, level, streak, task and achievement summaries.
- The Quran journey opens the existing 604-page reader at the last locally saved page. Browsing does not submit an activity; only the explicit page-completion action does. Server-confirmed pages and pending page UUIDs are stored separately on-device, and pending events retry with the same idempotency key.
- Adhkar counters, daily completions and pending confirmations persist by local date and category. A counter tap is local progress; the activity is submitted only when its target is reached. Dua categories are filterable, daily read confirmations persist by stable dua key, and favorites persist across dates. None of these local values award XP or Coins; the server acceptance response is the only reward source.
- The share screen offers an app link and user-provided content. A share activity is submitted only when `share_plus` reports `ShareResultStatus.success`; cancel/unavailable results do not count. On Android this confirms a chooser destination was selected, not that the recipient received or opened the content. Rewards remain server-authoritative.

## API and data integrity

All journey requests use bearer authentication and the existing `/api/v1/` endpoints. Activity requests use UUID idempotency keys. Transient network/server failures retain queued events in Hive for later retry with the same key; queued events are scoped to the saved account identity and do not affect displayed balances. Permanent validation failures remain marked as blocked for inspection rather than being retried or silently discarded. A 401 clears the active token and identity. Live endpoint behavior and the exact server-side metadata validation have not been exercised in this authoring session.

The runtime packages include Hive, secure storage, local notifications, timezone, HTTP, URL launcher and `share_plus` for the native share sheet. `uuid ^4.5.1` is declared directly because the journey code imports it. The repository initially had no `pubspec.lock`.

## Validation completed

- `flutter pub get` completed on Flutter 3.47.9 / Dart 3.13.7 in the isolated work copy.
- The earlier full-suite run passed 143 tests. This focused review added and passed 10 Outbox/Quran progress and Adhkar/Dua/Share screen tests; the full suite was not rerun. Analysis of the edited files found no errors or warnings (informational lints only).
- No APK/AAB build, device test, release signing or deployment was performed. Changes remain on the independent review branch and are not merged into `main`.

## Remaining external/manual work

- Verify login, all protected API response shapes, activities, rate limits, 401 handling, and queued-event idempotency against the live backend and its current metadata validator.
- Test RTL, Android back behavior, permission flows, notification scheduling, and reader active-time behavior on physical devices.
- The legacy contributor registration screen still contains a client-side bearer credential. A client-embedded credential cannot be made secret; rotate it and move that operation behind a server-side endpoint before production use. The backend is not present in this Flutter repository, and no contribution/payment flow was altered here.
- The app can verify only that Android's share chooser selected a destination, not delivery or recipient engagement. If the product requires proof of delivery, the backend must define a separate verifiable/server-mediated event.
- Release build remains intentionally unrun pending explicit user approval.
