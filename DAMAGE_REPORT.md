# DAMAGE_REPORT.md

**Project:** QuitDrinking Ai (Flutter)
**Date:** August 15, 2026
**Scope:** Full project audit — structure, config, permissions, dependencies, Firebase, onboarding.

---

## Summary

| # | Check | Status |
|---|-------|--------|
| 1 | `lib/screens/` — screens exist | ✅ All present |
| 2 | `lib/widgets/` — widgets exist | ✅ All present |
| 3 | `lib/config/api_config.dart` — exists & proper structure | ✅ Present |
| 4 | AndroidManifest.xml — INTERNET permission | ✅ Present |
| 5 | pubspec.yaml — required packages | ✅ **Fixed** — all 4 added |
| 6 | `lib/core/services/firebase_service.dart` — exists | ✅ **Fixed** — compiles clean |
| 7 | `main.dart` — Firebase initialized / async main | ✅ **Fixed** — async main + Firebase init |
| 8 | `.gitignore` — `api_config.dart` ignored | ✅ Present |
| 9 | Onboarding flow in `main.dart` — `onboarding_complete` check | ✅ **Fixed** — first-run → OnboardingScreen |

**Status: all 9 checks now pass.** The original Firebase breakage is fixed; `firebase_service.dart` compiles clean. A separate pre-existing breakage remains in `notification_service.dart` and `calming_activities_screen.dart` (see §10).

---

## Fixes applied (this session)

1. **pubspec.yaml** — added `firebase_core ^4.13.0`, `firebase_analytics ^12.4.6`, `cloud_firestore ^6.8.0`, `uuid ^4.6.0` via `flutter pub add`; `flutter pub get` ran.
2. **firebase_service.dart** — fixed `getOrCreateDeviceId` nullability (`storedId ?? newId`); file now analyzes with zero issues.
3. **main.dart** — `Future<void> main() async` with `await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform)`; reads `onboarding_complete` from SharedPreferences and routes first-run users to `OnboardingScreen`, returning users to `HomeScreen` (splash shown first either way).
4. **Android Gradle** — added `com.google.gms.google-services` plugin (settings + app `build.gradle.kts`) so Firebase can read `android/app/google-services.json` on Android. (Required for Firebase init to work; was missing.)
5. **settings_screen.dart** — added **Terms of Service** tile to the About section (between Privacy Policy and Rate the App).
6. **craving_actions_screen.dart** — removed the duplicated private `_ProUpgradeSheet`; now uses the shared `ProUpgradeSheet.show()` from `lib/widgets/pro_upgrade_sheet.dart`; upgraded users are still routed to AI Chat.

---

## 1. lib/screens/ — all present ✅

16 screens found, every one exists on disk:

| Screen | Path |
|--------|------|
| AI Chat | `lib/screens/ai_chat_screen.dart` |
| Home | `lib/screens/home_screen.dart` |
| Settings | `lib/screens/settings_screen.dart` |
| Memory Game | `lib/screens/memory_game_screen.dart` |
| Weight Tracker | `lib/screens/weight_tracker_screen.dart` |
| Privacy Policy | `lib/screens/privacy_policy_screen.dart` |
| Terms of Service | `lib/screens/terms_of_service_screen.dart` |
| Onboarding | `lib/screens/onboarding/onboarding_screen.dart` |
| Craving — Actions | `lib/screens/craving/craving_actions_screen.dart` |
| Craving — Breathing | `lib/screens/craving/breathing_screen.dart` |
| Craving — Calming Activities | `lib/screens/craving/calming_activities_screen.dart` |
| Craving — Drink Water | `lib/screens/craving/drink_water_screen.dart` |
| Craving — Journal | `lib/screens/craving/journal_screen.dart` |
| Craving — Motivation | `lib/screens/craving/motivation_screen.dart` |
| Craving — My Reasons | `lib/screens/craving/my_reasons_screen.dart` |
| Craving — Walk | `lib/screens/craving/walk_screen.dart` |

## 2. lib/widgets/ — all present ✅

19 widgets found, every one exists:

`ai_chat_pro_card`, `breath_challenge_card`, `confetti_celebration`, `craving_help_card`, `daily_checkin_card`, `daily_motivation_card`, `empty_state`, `guided_breathing_card`, `home_footer`, `home_header`, `milestone_badges`, `money_saved_card`, `my_reasons_card`, `pro_upgrade_sheet`, `recovery_timeline_card`, `section_header`, `sober_button`, `sober_card`, `sobriety_counter_card`

## 3. lib/config/api_config.dart — ✅ present, correct structure

File exists (1.6 KB). Structure is sound:

- `class ApiConfig` with private constructor
- `apiUrl` → `https://api.groq.com/openai/v1/chat/completions` (correct Groq endpoint)
- `apiKey` → real `gsk_...` key (local only; see §8)
- `model` → `llama-3.1-8b-instant` (valid Groq model)
- `aiName` → `AI Friend`

## 4. AndroidManifest.xml — ✅ INTERNET permission present

`android/app/src/main/AndroidManifest.xml` line 2:

```xml
<uses-permission android:name="android.permission.INTERNET"/>
```

## 5. pubspec.yaml — ✅ FIXED

All required packages present: `firebase_core ^4.13.0`, `firebase_analytics ^12.4.6`, `cloud_firestore ^6.8.0`, `uuid ^4.6.0`, plus existing `http ^1.6.0` and `shared_preferences ^2.3.4`.

## 6. lib/core/services/firebase_service.dart — ✅ FIXED

Singleton for device ID + `app_open` analytics + Firestore `pro_purchases`. After adding the packages and fixing the nullability in `getOrCreateDeviceId` (`storedId ?? newId`), the file analyzes with **zero issues**.

Notes:
- Nothing in `lib/` imports `FirebaseService` yet — it's wired up but unused.
- `android/app/google-services.json` exists; the Gradle plugin is now added so Android builds can consume it.

## 7. main.dart — ✅ FIXED

```dart
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  final prefs = await SharedPreferences.getInstance();
  final onboardingDone = prefs.getBool('onboarding_complete') ?? false;
  runApp(ProviderScope(child: SoberTodayApp(showOnboarding: !onboardingDone)));
}
```

- `Future<void> main()` ✅
- `Firebase.initializeApp` with `DefaultFirebaseOptions.currentPlatform` ✅
- Onboarding routing via `SoberTodayApp.showOnboarding` ✅

## 8. .gitignore — ✅ api_config.dart ignored

`.gitignore` line 37: `lib/config/api_config.dart` (added during the Groq key fix). The key file is now untracked. Note: the old key is still visible in git **history** — rotate it.

## 9. Onboarding flow — ✅ FIXED

- `main()` now reads `onboarding_complete` from SharedPreferences and passes `showOnboarding` to `SoberTodayApp`.
- Flow: Splash (1.2 s) → **OnboardingScreen** (first run) or **HomeScreen** (returning users).
- `OnboardingScreen` still sets `onboarding_complete = true` on finish.

---

## 10. Remaining issues — ✅ all resolved, zero errors

A full `flutter analyze` now reports **No issues found** across the entire project. The two pre-existing broken files were fixed:

1. **`lib/services/notification_service.dart`** — **deleted** (notifications are out of V1). Verified nothing imported it; no other file referenced it.
2. **`lib/screens/craving/calming_activities_screen.dart`** — fixed:
   - Added `AppColors.gold = Color(0xFFFFD700)` and `AppColors.goldDark = Color(0xFFFFA500)` to `lib/constants/app_colors.dart` (they were referenced but missing).
   - Removed the bogus `service` plumbing: the `MyReasonsScreen(service: ...)` call now uses `const MyReasonsScreen()` (matching its actual constructor), and the unused `reasonsService` field/import on `CalmingActivitiesScreen` / `_ActivityTile` were deleted.

Other notes:
- **API key in git history** — rotate `gsk_g7ks...`; it was committed before the gitignore fix.
- `FirebaseService` is wired up but not yet imported anywhere — consider calling `logAppOpen()` on app start.
- The Settings screen still shows the **Daily Reminder** toggle, but with `notification_service.dart` gone it has no effect — remove the UI (or wire it to a future notifications implementation) before shipping V1.
