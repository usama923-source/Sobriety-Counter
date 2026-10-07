# FINAL_AUDIT.md — QuitDrink Ai
**Audit date:** October 5, 2026 · **Scope:** full `lib/` (61 Dart files), `assets/`, platform configs, git history
**Legend:** 🔴 Critical · 🟠 Moderate · 🟢 Minor / Informational

---

## 1. Security

### 🔴 1.1 Real Groq API key committed to git history
- **File:** `lib/config/api_config.dart` (local, untracked) → **history of `lib/config/api_config.dart`**
- Commit `453a8ec` ("just make some changes in colors") contains a **real Groq key** (`gsk_g7ks…`, redacted here). A later commit `75a9ef1` deleted the file and gitignored it, but **the key remains fully recoverable from local history** (`git show 453a8ec:lib/config/api_config.dart`).
- **Remote status:** `origin/main` was inspected — commit `453a8ec` is **NOT currently reachable from `origin/main`** (likely rewritten/force-pushed), but the repo `usama923-source/Sobriety-Counter` is public on GitHub. If the push ever happened before the rewrite, the key may be in GitHub's cached commits/PR refs — assume compromised.
- **Action (for you, not fixed here):** rotate/revoke the key at console.groq.com/keys immediately; verify via GitHub support whether the old commit is cached; a key placed in a Flutter client binary is extractable from APK/IPA anyway — consider a proxy backend for production.

### 🟠 1.2 Client-side API key shipping (by design)
- `lib/config/api_config.example.dart` documents embedding a Groq key in `lib/config/api_config.dart` at build time. Any API key compiled into a mobile app can be extracted (decompile APK). Fine for hobby/dev; not for production.

### 🟠 1.3 Firebase API keys in tracked file
- `lib/firebase_options.dart` + `android/app/google-services.json` contain Firebase Web/API keys (`AIzaSy…` — tracked, since `git ls-files` confirms). **This is normal and accepted for Firebase** (keys identify, not authorize) — but security depends entirely on your Firestore/Storage rules → see 1.5.

### 🟠 1.4 No Firestore security rules in the repo
- **No `firestore.rules` or `storage.rules` files exist anywhere in the project** (searched). `firebase.json` only contains Flutter platform config.
- The app writes to Firestore (`pro_purchases` collection, `lib/core/services/firebase_service.dart:65`). If default rules are "allow read/write if authenticated" or open in test mode, **anyone can write fake purchase records** (is_pro bypass, revenue corruption).
- **Action:** verify rules in Firebase Console; add a `firestore.rules` file to the repo.

### 🟠 1.5 Pro entitlement stored client-side (trivially spoofable)
- `lib/widgets/pro_upgrade_sheet.dart:204` — `prefs.setBool('is_pro', true)` grants Pro **without any payment verification** (the `in_app_purchase` package is in `pubspec.yaml` but **never imported or used** in `lib/`).
- `is_pro` is read in 4+ places (`home_screen.dart`, `craving_actions_screen.dart`, `theme_provider.dart`). Rooted devices/jailbreaks or pref editors unlock everything free. Firebase `logProPurchase` records `amount: 2.99` that was never actually charged.

### 🟢 1.6 Sensitive-ish data in unencrypted SharedPreferences
- All data is stored in plain SharedPreferences (plaintext XML on Android): **AI chat history** (`ai_chat_screen.dart:146`), **journal entries** (`core/providers/journal_provider.dart:100`), **personal quit reasons** (`services/reasons_service.dart:96`), **weight logs** (`core/providers/weight_tracker_provider.dart:149`), device UUID (`firebase_service.dart`).
- No passwords/tokens/auth stored — good. But journal + reasons + weight are **health-adjacent personal data**; on rooted devices or ADB backup they are readable. Consider `flutter_secure_storage` for journal/reasons, and note it in the privacy policy.
- ⚠️ Inconsistency: `settings_screen.dart` "Reset All Data" calls `prefs.clear()` but the **in-memory Riverpod services are not reset**, and the abstract `LocalStorage` (`core/storage/local_storage.dart`) is **never used by any service** — services talk to SharedPreferences directly.

### 🟢 1.7 HTTPS everywhere (pass)
- **Zero `http://` URLs in `lib/`**. All network egress is HTTPS: Groq API (`https://api.groq.com/...`), Play Store link, `mailto:`. No `NSAllowsArbitraryLoads` in iOS; no `usesCleartextTraffic` in Android manifests. ✅

### 🟠 1.8 AI chat input — no sanitization (only trimming)
- `ai_chat_screen.dart` `_sendMessage()`: user input is **only `.trim()`-ed**. It is then:
  - Sent verbatim to the Groq API in `messages[].content` (no length cap → token cost abuse; no strip of control chars/injection attempts).
  - **Saved to SharedPreferences as raw JSON** (`jsonEncode` of user text) and **decoded without validation** on load (`jsonDecode` + `as String? ?? ''`).
  - Rendered in `Text()` widget → **Flutter `Text` does not interpret HTML/JS, so XSS risk is inherently low** (no WebView). Main residual risks: oversized payloads in prefs, prompt-injection of the system prompt, and unbounded message length.
- Chat history capped at 50 messages — good.

---

## 2. Performance

### 🟠 2.1 Whole-screen rebuilds per second (by design, but heavy)
- `services/sobriety_service.dart` `_startTimer()` fires `notifyListeners()` **every second**, and `SobrietyCounterCard` watches it. Home screen mitigates with `RepaintBoundary` wrappers (good), but every Riverpod watch of `totalDaysProvider` re-evaluates each tick. Fine at this scale; consider ticking only when the displayed second actually changes... which it does — but the **entire card subtree rebuilds 1×/sec** unnecessarily for the day-only display on some cards.
- `main.dart` `_SplashScreenState` uses `AnimatedBuilder` wrapping the **entire Scaffold** — rebuilds the whole tree at 60fps for 800ms instead of scoping `FadeTransition`/`ScaleTransition` (which are already animated widgets and need no AnimatedBuilder at all).

### 🟠 2.2 `setState` rebuild scope issues
- `ai_chat_screen.dart:93` — `_textController.addListener(() => setState(() {}))` rebuilds the **entire chat screen on every keystroke** just to enable/disable the send button. Should scope to the input bar widget or use `ValueListenableBuilder`.
- `journal_screen.dart:25` — same pattern (`setState(() {})` on every keystroke of the journal TextField).
- Home `_buildBody` builds ~10 cards inline; any `setState` on the Home state (e.g. refresh flags) rebuilds all of them (partially mitigated by RepaintBoundary but **RepaintBoundary does not stop widget rebuilds**, only repaints).

### 🔴 2.3 Compile-blocking error found (blocks any perf work)
- `flutter analyze`: `error - const_with_non_const` at **`lib/core/providers/journal_provider.dart:59:29`** — the app does not currently compile. (`warning - unused_import` also at `home_screen.dart:20`.)

### 🟢 2.4 Main-thread heavy operations — none found
- No JSON parsing of large payloads on main thread is a concern at current data sizes (chat ≤50 msgs, journal string list). No isolates/`compute` used, none needed yet. SharedPreferences writes are async. ✅

### 🟢 2.5 Images — minimal usage, no caching issues
- Only 2 assets (`logo.png`, `logo_icon.png`), loaded via `Image.asset` in `main.dart` splash with `errorBuilder`. No network images → no caching needed. `logo.png` used at 200px but shipped at original resolution — check size; `assets/` in pubspec bundles **everything in the folder**.
- `google_fonts` fetches Montserrat/Lato at **runtime** on first launch (network dependency + flash of fallback font); bundling the .ttf files would improve startup and offline behavior.

### 🟠 2.6 Memory leaks — mostly clean, one risky pattern
- All 11 `AnimationController`s found are disposed. ✅ All Timers canceled on dispose. ✅
- **`home_screen.dart:94-128` — tooltip `fadeController` leaks on early unmount:** it's only disposed inside the 3-second Timer callback. If the HomeScreen is disposed before the timer fires (user backs out instantly), `dispose()` cancels `_tooltipTimer` but **never disposes `fadeController`** nor removes `_tooltipEntry` — leaked AnimationController + OverlayEntry. (Also `_tooltipEntry.dispose()` is called **twice** — line 74 and 126.)
- `memory_game_screen.dart` uses `Future.delayed(_flipDelay, …)` for flip-back — no cancel token; harmless at 2s but touches state after dispose guard (`mounted` check present ✅).

---

## 3. Code Structure

### 🔴 3.1 Compile error (structure-breaking)
- `lib/core/providers/journal_provider.dart:59` — `const` applied to a non-const constructor (`JournalState()` const in default-value position). Blocks build; analyzer-confirmed.

### 🟠 3.2 Dead/unused code (analyzer + search confirmed)
- **Dead import:** `home_screen.dart:20` — `breath_challenge_card.dart` imported, never used.
- **Dead module #1:** `core/storage/local_storage.dart` (abstract `LocalStorage` + `SharedPrefsStorage`, 180 lines) — **never imported by any file** except its own tests (`test/core/local_storage_repository_test.dart`). All services bypass it.
- **Dead module #2:** `core/utils/error_handler.dart` + `core/utils/result.dart` — `ErrorHandler.safeCall` and `Result<T>` **never used in app code** (only tests). Services use raw try/catch or none.
- **Dead module #3:** `utils/responsive_helper.dart` — `ResponsiveHelper` defined, **never imported** anywhere.
- **Dead widget:** `widgets/sober_button.dart` — `SoberButton` never used by any screen (all screens build buttons inline).
- **Dead dependency:** `in_app_purchase: ^3.3.1` in pubspec — **never imported in lib/** (see security 1.5).

### 🟠 3.3 Duplicate architecture — two parallel state systems
- **`lib/services/*` (7 files, ChangeNotifier) vs `lib/core/providers/*` (8 Riverpod files wrapping them)** — clean. **But** `journal_provider.dart` and `weight_tracker_provider.dart` implement StateNotifier **with persistence logic inline**, duplicating the service-layer pattern for no reason (no matching service file). Two idioms coexist: ChangeNotifier services + Riverpod wrappers, and StateNotifiers that do everything.
- **Duplicate type:** two unrelated `Result<T>`-style patterns: `core/utils/result.dart` (unused) vs ad-hoc try/catch in services.

### 🟠 3.4 Duplicated UI code
- `widgets/guided_breathing_card.dart` vs `screens/craving/breathing_screen.dart` — **near-complete duplicates**: same `_BreathPhase` logic, same phase timing (4s/4s/6s, 5 cycles), same `_progress` getter, same `_startPhase`/`_onPhaseComplete` structure, same phase-color getters. Two copies of the same feature (card version ~370 lines, screen version ~620 lines).
- `services/sobriety_service.dart` quit-date parsing/writing duplicated by `daily_checkin_card.dart:309` (writes ISO string directly with its own key format) — two writers to the same pref key with **different formats** (ISO string vs millis int) — the service handles both in `init()`, but it's fragile duplicated ownership.
- Repeated `isDark ? AppColors.textOnDark : AppColors.textPrimary` style pattern appears **hundreds** of times across 40+ files — a `context.textTheme` extension would remove ~most of it.

### 🟢 3.5 Files in wrong folders
- `services/breathing_service.dart`, `checkin_service.dart`, `quotes_service.dart`, `reasons_service.dart`, `savings_service.dart`, `sobriety_service.dart`, `theme_service.dart` live in `lib/services/`, while their siblings live in `lib/core/services/` (firebase, notification) and providers in `lib/core/providers/`. Two service folders, one purpose — pick one.
- `lib/data/quotes.dart` — fine. `lib/utils/responsive_helper.dart` — dead (3.2).
- `lib/config/api_config.dart` present locally with **secret value**, correctly gitignored ✅ (but see 1.1 for history).

### 🟠 3.6 Unused assets
- `assets/logo_icon.png` — **never referenced in code, pubspec, or native configs** (flutter_launcher_icons is a dev-dependency but has **no `flutter_icons:` config section** in pubspec, so launcher icons are defaults). Either wire it up or delete.
- `pubspec.yaml` declares `assets: [assets/]` (whole folder) — no resolution variants (no `2.0x/3.0x` folders) → logo.png ships at one density.

---

## 4. Crash Risks

### 🔴 4.1 Current build is broken
- `journal_provider.dart:59` const error — app **will not compile** until fixed (analyzer-verified).

### 🟠 4.2 Null-safety force-unwraps on user-controllable paths
- `services/checkin_service.dart:58,90,144` — `_history[key]!` after `containsKey` — safe today, but three force-unwraps in one file with manual string parsing of the persisted format (`split(',')`/`indexOf(':')`). A malformed pref value produces **wrong dates via `int.parse` in `_parseDateKey` (line ~199) with no try/catch → FormatException crash on startup init()**.
- `home_screen.dart:117` — `Overlay.of(_scaffoldKey.currentContext!)` — `currentContext!` throws if the scaffold isn't mounted yet (fast nav-away during first 800ms window when the tooltip triggers).
- `services/sobriety_service.dart:24,46,99,116` — `_quitDate!` — guarded by preceding null checks; safe but fragile under refactoring.
- `core/providers/weight_tracker_provider.dart:56,62-65` — `currentWeight!`, `goalWeight!` — guarded by getters; `progress` divides by `total` which can be **0 if `start == goalWeight` and start > goal is false** → division by zero → `Infinity`/`NaN` propagates to `LinearProgressIndicator` (value NaN throws in debug). Edge-case crash.
- `onboarding_screen.dart:51,469` — `_selectedDate!` — guarded by can-pop-up flag; OK.

### 🟠 4.3 Async gaps without try/catch
- **Firestore writes:** `firebase_service.dart` — ✅ wrapped.
- **HTTP call:** `ai_chat_screen.dart` — ✅ wrapped in try/catch with timeout + fallback. Good.
- **`SharedPreferences` reads/writes:** ~30 call sites, **none** wrapped (services, screens, providers). PlatformException on full disk / corrupted prefs would propagate as unhandled async exception. Low probability, high blast radius (e.g. `checkin_service._save` on every check-in).
- **`journal_provider._loadEntries`** — `JournalEntry.fromJson` parses `int.tryParse(parts[0]) ?? 0` ✅ but `_loadEntries` itself has **no try/catch** and is called from the constructor (unhandled async in StateNotifier constructor).
- **`jsonDecode` on chat history** — ✅ wrapped (`ai_chat_screen.dart:110`).
- **`int.parse` in `quotes_service.init()`** (line 41: `raw.map(int.parse)`) — a corrupted favorite index string crashes **app startup**; no tryParse.
- **`NotificationService.initialize()`** called with `await` in `main()` — **no try/catch**; a plugin failure on some devices blocks app launch entirely (contrast: Firebase init *is* protected).
- **`launchUrl`** in `settings_screen.dart:692` — guarded by `canLaunchUrl` ✅ but failures (rare) unhandled; acceptable.

### 🟢 4.4 No global error handlers
- `main()` has **no `runZonedGuarded`, no `FlutterError.onError`, no `PlatformDispatcher.instance.onError`** — any unhandled exception above escapes to the platform as a red screen/crash with no log capture. Firebase Crashlytics is not integrated (analytics only).

### 🟢 4.5 Overlay/entry double-dispose
- `home_screen.dart` disposes `_tooltipEntry` in both `dispose()` (line 74) and the timer callback (line 126) — `OverlayEntry.dispose()` is safe to call twice per Flutter docs, but removing after dispose would assert; the leak scenario in 2.6 is the real risk.

---

## 5. Accessibility

### 🟠 5.1 Semantic labels — mostly missing
- Only **4 `tooltip:`** in the entire app (`ai_chat_screen` clear-chat, `home_screen` theme + settings + AI FAB). Back `IconButton`s in app bars (9 screens) rely on Material's default "Back" semantics — acceptable.
- **No `Semantics` widgets anywhere** except inside `sober_card.dart` (optional `semanticLabel` param — **never passed** by any caller).
- **Unlabeled interactive `GestureDetector`s (invisible to TalkBack/VoiceOver):**
  - `ai_chat_screen.dart:626` — disclaimer close ✗
  - `ai_chat_screen.dart:751` — suggested prompt chips ✗
  - `breath_challenge_card.dart:231`, `daily_motivation_card.dart:184`, `recovery_timeline_card.dart:166` (expand/collapse) ✗
  - `memory_game_screen.dart:355` — game cards (no state semantics for "flipped/matched") ✗
  - `weight_tracker_screen.dart:882`, `my_reasons_screen.dart:392` (**delete via long-press only** — completely undiscoverable and unannounced to screen readers) ✗
  - `journal_screen.dart:534`, `motivation_screen.dart:357` ✗
- Icon-only buttons with no tooltip/label: sound toggle in `guided_breathing_card.dart` (InkWell+Icon, no label).

### 🟠 5.2 Text contrast — low-contrast combinations found
All ratios computed against stated backgrounds (WCAG AA = 4.5:1 normal, 3:1 large/18px+):
| Colors (light theme) | Ratio | Where |
|---|---|---|
| `textTertiary #A0AEC0` on `white` / `lightGray #F5F7FA` | **~2.5:1 / 2.3:1** 🔴 | hints, section headers (`settings_screen.dart` "APPEARANCE", timestamps, helper text) |
| `softTeal #7EC8C3` on `white` | **~1.9:1** 🔴 | "Soft sounds off" text, progress labels, icons-as-information |
| `softOrange #FFB74D` at alpha 0.9 on tinted banner | **~1.7:1** 🔴 | **AI crisis disclaimer text** (`ai_chat_screen.dart:662`) — the most safety-critical text in the app is the least readable |
| `gold #FFD700` on `white` | **~1.5:1** 🔴 | Pro badges text on gold gradient (white/navy mitigates partially) |
| `textSecondary #718096` on `white` | ~4.6:1 ✅ | body copy — passes |
| Dark theme: `textOnDarkSecondary #B0BEC5` on `darkSurface #121B28` | ~9:1 ✅ | body — passes |
- `alpha` fades compound the problem: `.withValues(alpha: 0.4–0.6)` applied to already-low-contrast tertiary text in ~15 places (footers, headers, chips).

### 🟠 5.3 Text scaling forcibly disabled
- `main.dart:83-89` — `textScaler: TextScaler.noScaling` via MediaQuery override **app-wide**: users with system-level large-text (accessibility setting) get **no enlarged text anywhere**. This is a significant a11y regression for low-vision users and a Play Store review risk. (Also breaks `MediaQuery.textScaleFactorOf`-dependent layouts.)

### 🟢 5.4 Touch targets
- A few icon hit-areas below 48×48dp: disclaimer close (~26dp), sound toggle (~32dp), drawer delete (long-press container ~34dp).

---

## Summary Counts
| Category | 🔴 | 🟠 | 🟢 |
|---|---|---|---|
| Security | 1 | 5 | 2 |
| Performance | 1 | 3 | 3 |
| Structure | 1 | 4 | 2 |
| Crash risks | 1 | 2 | 2 |
| Accessibility | 0 | 4 | 1 |
| **Total** | **4** | **18** | **10** |

**Top 5 to fix first:**
1. 🔴 Rotate the leaked Groq key (console.groq.com) — then check GitHub remote for cached history.
2. 🔴 Fix `journal_provider.dart:59` const error — build is broken.
3. 🔴 Add/verify Firestore security rules for `pro_purchases`.
4. 🟠 Add global error handlers + wrap prefs/`int.parse` startup paths.
5. 🟠 Remove `TextScaler.noScaling` + add semantic labels to GestureDetectors.

*Report-only audit as requested — nothing was modified.*
