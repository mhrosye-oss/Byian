# Itqan gamification implementation notes

## Architecture
Feature-first layers live under `lib/features/gamification`: JSON models, a repository contract, HTTP API/repository implementation, a Riverpod `StateNotifier`, and presentation widgets/screens. The repository uses the existing `http` and `flutter_riverpod` dependencies.

## SDK and dependencies
The existing workflow pins Flutter 3.24.0 (stable). The repository pubspec has Dart `>=3.0.0 <4.0.0`, `http ^1.2.0`, and `flutter_riverpod ^2.4.9`. `flutter_secure_storage ^9.2.4` was added for bearer token storage. Flutter/Dart executables were not available in the editing session; exact installed versions and solver compatibility remain unverified. No `pubspec.lock` was present at the inspected branch root. The previously observed CI solver conflict between SDK `integration_test` and `flutter_timezone 5.1.1` was not changed; current pubspec pins flutter_timezone `^4.1.0`.

## API/source table
| Feature | Endpoint | Source |
|---|---|---|
| Profile | GET `/api/v1/gamification/profile` | API response |
| Journey | GET `/api/v1/gamification/journey` | API response |
| Tasks | GET `/api/v1/gamification/tasks` | API response |
| Streak | GET `/api/v1/gamification/streak` | API response |
| Achievements | GET `/api/v1/gamification/achievements` | API response |
| Leaderboard | GET `/api/v1/gamification/leaderboard?limit=10` | API response |
| Activity | POST `/api/v1/gamification/activities` | API response |

## Design tokens
Widgets use the active Material `Theme.of(context)` color scheme/text theme, 16–20px rounded cards, regular 8/12/16px spacing, and RTL-friendly Flutter layout. Existing app palette is preserved. No new font or image dependency is used.

## Idempotency and error handling
Each `recordActivity` call creates an RFC 4122 version-4 key from `Random.secure()` bytes. Activity result reward/balance values are parsed from the server; the client does not calculate XP or coins. Duplicate responses retain server-returned balances. HTTP 401 clears token and stored user identity and raises a session-expired exception; 422/429/5xx/network errors are surfaced with server message/status, and rate-limit `retry_after` is retained. A global navigation redirect is not yet wired.

## Storage
Bearer token is held in `flutter_secure_storage`; name/email labels remain in existing SharedPreferences integration. XP, coins, level, achievements, streak and leaderboard are fetched from server and never persisted as local authority.

## Contract coverage and gaps
Model and API fields follow the supplied contract. API requests use `/api/v1/` paths and bearer authorization. The current task screen route uses existing Quran, adhkar and dua screens. Activity submission has not yet been connected to task completion interactions; neither login/register UI nor the existing HomeScreen/ProfileScreen/Drawer integration has been changed in this commit. No live endpoint calls were made, so no 404/500 result is known. Leaderboard period remains server-provided (`all_time` per contract); no period selector is provided.

## E2E checklist
- [ ] Login response token persisted from login screen
- [ ] Home JourneyBanner loaded from backend
- [ ] Activity POST accepted and server balance displayed
- [ ] Journey refreshed after activity
- [ ] Profile extended with server stats
- [ ] Leaderboard reachable from existing Drawer
- [ ] All Drawer links operational
- [ ] RTL verified on target devices
- [ ] `flutter test` and `flutter analyze` run in Flutter-enabled environment
