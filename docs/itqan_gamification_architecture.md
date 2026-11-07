# Independent Itqan Journey feature

The new product surface is isolated under `lib/features/itqan_journey/`: journey dashboard, Quran journey, adhkar journey, dua journey, share journey and backend-backed gamification state. Legacy Quran, adhkar and dua screens remain intact; the feature reuses only licensed content assets and the existing QuranService, AuthService, Hive, Riverpod, HTTP and url_launcher APIs. Quran text is rendered verbatim from the bundled Tanzil source and no religious content was authored here.

## Layers
- `data/journey_content_repository.dart`: feature-owned access to existing bundled text assets and an independent `itqan_journey_quran` Hive box.
- `application/itqan_journey_provider.dart`: HTTP repository, API exception, Riverpod state and activity engine.
- `presentation/journey_dashboard_screen.dart`: journey, earned achievements and leaderboard surfaces.
- `quran_journey`, `adhkar_journey`, `dua_journey`, `share_journey`: standalone task experiences.
- `core`, `domain`, `shared`: focused implementation contracts/services are hosted at feature root until additional domain types are needed; no empty placeholder files are added.

## Existing dependencies and additions
Existing: `http ^1.2.0`, `flutter_riverpod ^2.4.9`, `hive_flutter ^1.1.0`, `url_launcher ^6.2.5`, Flutter Material and project Quran service. Added `uuid ^4.5.1` for RFC4122 v4 idempotency keys; no graphics, sharing or navigation packages added. `pubspec.lock` is committed. Flutter 3.24.0 resolves the dependencies and passes analysis/tests locally; GitHub Actions validates the same toolchain with Java 17 and Android SDK. The branch uses `flutter_timezone ^4.1.0` and does not change the existing record/speech-to-text overrides.

## API contract
The feature uses only the supplied endpoints: GET profile, tasks, journey, streak, achievements, leaderboard?limit=10 and POST activities. All requests use bearer auth. Server result data drives visible balances/rewards; client creates a unique UUID and never calculates XP. A 401 clears token and stored session identity; error responses retain status/code/retry_after. Live endpoint behavior has not been tested in this authoring session.

## Limitations
HomeScreen and auth login/register still require integration with the new independent entry point/session contract. The existing Drawer now opens the journey surfaces, but its profile entry currently points to the dashboard (there is no dedicated profile screen implementation here). Share uses the platform SMS app via existing url_launcher; launch success is not proof of sending, so the backend remains responsible for reward validation. Quran progress stores a private last position; the read-completion action currently records one page, because no reliable page count is derived from user's reading session. Adhkar sends one activity per completed item; backend acceptance controls rewards. Daily completion summary and loading/errors are server data only.

## Verification status
- [x] flutter pub get / analyze / test on Flutter 3.24 environment
- [x] Mock Contract tests cover bearer auth, activity payloads, UUID idempotency and HTTP 429 retry metadata
- [x] GitHub Actions validates Android debug and release APK compilation on an Android SDK runner
- [ ] Login endpoint stores token and protected endpoints read it
- [ ] Quran position survives route reopening; bundled Tanzil text is unchanged
- [ ] Adhkar/dua/share action returns server acceptance before reward shown
- [ ] API 401 clears session; rate limit and validation errors are presented
- [ ] Drawer destinations navigate; four bottom destinations are unchanged
- [ ] Verify RTL on device and run legacy test suite
