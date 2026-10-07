# 🔍 CODE_AUDIT.md — Full Code Quality Audit of `lib/`

**Project:** QuitDrink Ai (`quit_drinking`)
**Audited:** September 29, 2026
**Scope:** `lib/` — 67 Dart files, ~18,600 lines
**Verdict:** `flutter analyze` is essentially clean (1 info). The real issues are **architectural**: massive screen-level duplication, a dead "clean architecture" layer, and inconsistent state management.

---

## 🚨 Critical Findings (Fix First)

### 0. Hardcoded API key committed to source — `lib/config/api_config.dart:26`
```dart
static const String apiKey =
    '<REDACTED_GROQ_KEY>';
```
The file claims it's gitignored, but it **exists in the project and is imported** by `ai_chat_screen.dart`. If it has ever been committed, the Groq key is exposed. In a Flutter APK the key is also extractable from the binary regardless. **Rotate this key and move it behind a backend proxy or at minimum out of version control.**

---

## 1. Duplicate Code — Same Logic in Multiple Places

### 🔴 CRITICAL: Two near-identical "craving actions" screens (~600 duplicated lines)

| | `craving_actions_screen.dart` (374 lines) | `calming_activities_screen.dart` (612 lines) |
|---|---|---|
| `_CravingAction` model class | ✅ | ✅ (identical + `isPro` field) |
| `_cravingActions` list (7 items: Drink Water, Walk, My Reasons, Breathing, Journal, AI Friend, Motivation) | ✅ | ✅ — **same icons, labels, descriptions, colors** |
| `_onActionTap` switch (cases 0–6) | ✅ | ✅ — identical navigation targets |
| `_handleAIFriend` (SharedPreferences `is_pro` check → navigate or upgrade sheet) | ✅ | ✅ — same logic |
| Staggered fade+slide `_ActivityTile` animation | ✅ (`_CravingActionTile`) | ✅ (`_ActivityTile`) |
| `_ProPromptSheet` / `ProUpgradeSheet` | uses shared `ProUpgradeSheet` | rolls its **own** `_ProPromptSheet` + inline confirm dialog |

**`CalmingActivitiesScreen` is referenced NOWHERE** — `home_screen.dart` and `craving_help_card.dart` both open `CravingActionsScreen`. The entire 612-line file is a dead duplicate. **Delete it** (or keep it and delete the other, but only one can remain).

### 🔴 HIGH: `walk_screen.dart` vs `drink_water_screen.dart` — ~90% identical (430 vs 429 lines)
Both implement independently:
- `_totalSeconds` countdown, `_remainingSeconds`, `_isRunning`, `_isComplete`, `Timer? _timer`
- Identical `_startTimer()` / `_resetTimer()` bodies (same haptics, same timer-cancel logic)
- Identical `_formattedTime` / `_progress` getters
- Identical pulsing `AnimationController` (2s, `1.0→1.06`, reverse)
- Identical Start/Reset gradient buttons and completion `SoberCard` with 🎉

Only constants differ: duration (10 min vs 5 min), icon, colors, copy. This is one parameterizable `CravingTimerScreen` (title, icon, color, duration, completion message).

### 🟠 MEDIUM: Pro-gating logic duplicated 3×
`SharedPreferences.getBool('is_pro') ?? false` → navigate-or-upgrade flow appears in:
1. `home_screen.dart` → `_navigateToPro()` + `_onAIFabTap()` (twice in the same file!)
2. `craving_actions_screen.dart` → `_handleAIFriend()`
3. `calming_activities_screen.dart` → `_handleAIFriend()`

Should be a single `ProGate.navigateTo(context, screen)` helper.

### 🟠 MEDIUM: "isDark ternary" repeated 200+ times
`final isDark = Theme.of(context).brightness == Brightness.dark;` is hand-rolled in every file, and then `isDark ? AppColors.textOnDark : AppColors.textPrimary` appears hundreds of times across all screens/widgets. The app has a `ThemeData` with proper `ColorScheme` + `TextTheme` that almost nothing uses. An extension like `BuildContext.textPrimary` or using `Theme.of(context).textTheme` would delete hundreds of lines.

### 🟡 LOW: Quote logic duplicated
- `motivation_screen.dart` re-implements quote seeding/cycling/favorites (`_seedFromDate`, `_nextQuote`, `_toggleFavorite`) — a private copy of `QuotesService` logic, **but its favorites are never persisted** (in-memory `Set<int>` only), and it imports `data/quotes.dart` directly instead of using `quotesServiceProvider`.
- Month-array date formatting (`'Jan', 'Feb', ...`) duplicated in `sobriety_service.dart:34` and `weight_tracker_screen.dart` (~line 760).
- `mm:ss` / time formatting duplicated in `breathing_service.dart:_formatSeconds`, `memory_game_screen.dart:_formattedTime`, `walk_screen.dart`, `drink_water_screen.dart`.
- Confirmation `AlertDialog` with Cancel/danger-button pattern duplicated in `ai_chat_screen.dart:_confirmClearHistory`, `journal_screen.dart:_confirmDelete`, `my_reasons_screen.dart:_confirmDelete`, `settings_screen.dart:_resetAllData` — all hand-build the same dialog skeleton.

---

## 2. Unused Imports

`flutter analyze` reports **no unused imports** (with `unnecessary_brace_in_string_interps` being the only lint). Verified manually — the analyzer is correct here. However, note these imports only exist *because of* the dead files in §3; deleting dead code will cascade-remove imports.

Worth flagging (not analyzer errors, but misleading):
- `memory_game_screen.dart:2` imports `dart:math` — used only for `Random()` shuffle, fine — but `walk_screen.dart` imports `dart:async` purely for the timer pattern that's duplicated in `drink_water_screen.dart`.

---

## 3. Unused Variables / Functions — Dead Code

### 🔴 Entire dead "clean architecture" layer (~470 lines, used only by each other + tests)

| File | Lines | Referenced by production code? |
|---|---|---|
| `core/storage/local_storage.dart` (`LocalStorage`, `SharedPrefsStorage`) | 175 | ❌ Only `test/core/local_storage_repository_test.dart` |
| `core/utils/result.dart` (`Result`, `Success`, `Failure`, extension) | 55 | ❌ Only dead layer + `test/core/result_test.dart` |
| `core/utils/error_handler.dart` (`ErrorHandler.safeCall/logError/showError`) | 50 | ❌ Nothing |
| `features/checkin/data/repositories/checkin_repository.dart` | 17 | ❌ Only tests |
| `features/sobriety/data/repositories/sobriety_repository.dart` | 31 | ❌ Only tests |
| `features/sobriety/`, `features/checkin/` folder shells | — | ❌ Only contain the repositories above |

Meanwhile the *real* services (`SobrietyService`, `CheckInService`, etc.) bypass this entirely and call `SharedPreferences` directly with **no** error handling — the abstraction was built and never wired in. **Either migrate the services to use `LocalStorage`/`Result`, or delete the whole `features/` + `core/storage` + `core/utils` layer.**

### 🔴 Entire dead screen
- `screens/craving/calming_activities_screen.dart` — 612 lines, **zero references** (see §1).

### 🟠 Unused widget components
| Symbol | File | Status |
|---|---|---|
| `SectionHeader` | `widgets/section_header.dart` (76 lines) | ❌ Never instantiated — settings screen defines its own private `_SectionHeader` |
| `EmptyState` | `widgets/empty_state.dart` (117 lines) | ⚠️ Only referenced by `test/widgets/empty_state_test.dart`; every screen has its own private `_EmptyState`/`_EmptyJournalState`/`_EmptyReasonsState` |
| `StatCard` | `widgets/sober_card.dart:144` | ❌ Never instantiated |
| `SoberOutlineButton`, `SoberTextButton` | `widgets/sober_button.dart:76,129` | ❌ Never instantiated (only `SoberButton` is used, once, in `empty_state.dart`) |
| `AIChatProCard` | `widgets/ai_chat_pro_card.dart` (402 lines) | ❌ Never imported/instantiated anywhere |

### 🟠 Unused providers (defined, never watched/read)
- `core/providers/quotes_provider.dart`: `currentQuoteProvider`, `currentQuoteAuthorProvider`, `isCurrentFavoriteProvider`, `isDailyQuoteProvider` — widgets watch the service directly instead.
- `core/providers/reasons_provider.dart`: `reasonsListProvider`, `reasonsIsEmptyProvider`.
- `core/providers/theme_provider.dart`: `isDarkModeProvider`.
- `core/providers/sobriety_provider.dart`: `startDateProvider`, `nextMilestoneProvider`, `milestonesWithStatusProvider` (only `totalDaysProvider` and `hasQuitDateProvider` are used).

### 🟡 Unused service members (dead getters)
- `QuotesService.dailyQuote`, `favoriteIndices`, `isFavorite(index)` — never called.
- `CheckInService.totalCheckins`, `drankDays` — never called.
- `SobrietyService` — `hours/minutes/seconds` only used via service; fine — but note the 1-second `Timer.periodic` rebuilds `SobrietyCounterCard` **even when only days are displayed**, a battery/perf smell rather than dead code.

---

## 4. Wrong Structure — Files in Wrong Folders

1. **`lib/config/api_config.example.dart` is inside `lib/`** → it gets compiled and analyzed with the app (duplicate `ApiConfig` class). Convention is `tool/`, root, or a `doc/` example — and it's only a "template" because of gitignore trickery. If the gitignore approach is kept, it should be outside `lib/`.
2. **`lib/services/` vs `lib/core/services/` split is inconsistent.** Plain services live in `lib/services/`, but `firebase_service.dart` and `notification_service.dart` live in `lib/core/services/`. Same layer, two homes.
3. **`lib/features/` contains only repositories** with no presentation/domain around them — it's a skeleton that isn't real feature-first architecture (and nothing uses it, see §3).
4. **`lib/utils/responsive_helper.dart` defines `Breakpoints`** — layout constants belong in `constants/`.
5. **`lib/data/quotes.dart`** is content data living outside any data layer; if `features/` were real, quotes belong under a feature or `core/data/`.
6. Minor: `models/milestone.dart` imports `flutter/material.dart` just for `IconData` — mixing UI into a model; icons would better live in the widget that renders milestones.

---

## 5. Repeated Widgets That Should Be Shared Components

| Duplicated pattern | Locations | Proposed shared widget |
|---|---|---|
| Icon-in-tinted-circle header (36–88px circle, `withValues(alpha:0.1–0.15)`) | breathing, walk, drink_water, motivation, journal, memory_game, weight_tracker, settings, calming/craving actions, money_saved, daily_checkin, pro_upgrade_sheet, craving_actions header | `IconBadge(icon, color, size)` |
| Private empty states | `_EmptyState` (my_reasons_card), `_EmptyJournalState` (journal), `_EmptyReasonsState` (my_reasons_screen), `_buildEmptyState` (ai_chat) | The **existing unused `EmptyState` widget** would cover all of them |
| Start/Reset gradient pill buttons | walk, drink_water, breathing (3× identical `InkWell`+`AnimatedContainer`+gradient+shadow blocks) | `GradientPillButton` |
| Gradient "Add/Save" pill | journal save, my_reasons add, onboarding | Same `GradientPillButton` |
| Completion celebration card (green circle + 🎉 + message) | walk, drink_water, breathing | `CelebrationCard(message)` |
| Section headers | settings `_SectionHeader` vs public `SectionHeader` | Consolidate into `SectionHeader` |
| AlertDialog w/ cancel + destructive confirm | ai_chat, journal, my_reasons, settings | `confirmDialog(context, title, message, destructive:)` |
| Time-picker theming wrapper | settings (2×, 30 lines each) | extract `_timePickerTheme(context)` helper |
| `_UnitToggleChip`-style segmented pill | weight tracker; similar chips in motivation/ai_chat | `PillToggle` |
| Typing-dot animation, message bubble | ai_chat private widgets — fine as private, but `_MessageBubble` hardcodes `MediaQuery.of(context).size.width` (deprecated pattern; screen uses `MediaQuery` elsewhere) | — |

The project already *has* `SoberCard`/`SoberButton` abstractions but screens constantly bypass them with raw `Material`+`InkWell`+`Container` (journal, my_reasons, walk, drink_water, breathing) — inconsistent with the design-system intent.

---

## 6. Inconsistent Patterns — Riverpod vs setState

The codebase has **two coexisting architectures**, roughly split by file age:

**Riverpod (correct pattern):**
- `main.dart`, `home_screen.dart`, `settings_screen.dart` (theme only), `my_reasons_screen.dart`, `daily_checkin_card.dart`, `daily_motivation_card.dart`, `sobriety_counter_card.dart`, `money_saved_card.dart`, `recovery_timeline_card.dart`, `breath_challenge_card.dart`, `my_reasons_card.dart`
- Pattern: `ChangeNotifierProvider` per service in `core/providers/`, widgets watch via small derived providers.

**Raw setState + direct SharedPreferences (bypasses the whole architecture):**
- `ai_chat_screen.dart` (1124 lines — chat history, pro flag, disclaimer all via raw prefs)
- `weight_tracker_screen.dart` (993 lines — own persistence keys)
- `journal_screen.dart` (621 lines — own `craving_journal_entries` key)
- `motivation_screen.dart` (491 lines — re-implements QuotesService without persistence)
- `memory_game_screen.dart`, `breathing_screen.dart`, `walk_screen.dart`, `drink_water_screen.dart`, `onboarding_screen.dart` (writes quit date + currency directly)

**Concrete inconsistencies:**
- Same concept, two storage paths: reasons screen uses `reasonsServiceProvider`, journal uses raw prefs — both are "user text entries."
- Same concept, two quote implementations: `DailyMotivationCard` (Riverpod + persisted favorites) vs `MotivationScreen` (setState + ephemeral favorites).
- Theme toggling goes through Riverpod (`themeServiceProvider`) but currency is raw `prefs.setString('currency')` read in `money_saved_card.build()` on **every rebuild** instead of a provider.
- `SavingsService.totalDays` is a **public mutable field** set imperatively by `MoneySavedCard._syncDays()` — state should flow the other way (watch `sobrietyServiceProvider` inside the service/provider).
- Widgets receive services as constructor params (`SobrietyCounterCard(service: ...)`) *and* also could watch providers — a hybrid anti-pattern.
- `main.dart` gates onboarding via a `showOnboarding` constructor flag instead of Riverpod; `SoberTodayApp` keeps a `_showSplash` bool via setState with a 2s `Future.delayed`.

---

## 7. Missing Error Handling

### API calls
- ✅ `ai_chat_screen.dart` — has try/catch around `http.post`, fallback to simulated replies. **But:**
  - ❌ No `http.Client` reuse, no **timeout** (a hung request leaves `_isSending` stuck until `Future` never resolves — actually it does resolve only on error/response; a stalled socket can hang the send button indefinitely).
  - ❌ Full chat history is sent with the request and **the API key is exposed client-side** (see Critical #0).

### shared_preferences reads/writes — **zero try/catch in app code**
Every service does raw `await SharedPreferences.getInstance()` + `get/set` with no protection:
- `sobriety_service.dart` — `init()`, `setQuitDate()`, `clearQuitDate()`, `resetSobriety()`
- `checkin_service.dart` — `init()`, `_save()` (also a fragile custom `key:val,key:val` serialization format instead of JSON)
- `quotes_service.dart` — `init()` does `raw.map(int.parse)` — **an unparseable stored value throws and breaks quote favorites forever** (no try/catch)
- `savings_service.dart`, `breathing_service.dart`, `reasons_service.dart` (this one is the only service with a proper try/catch in `_decode` — the model to follow)
- `settings_screen._loadPreferences()` — `int.tryParse` used ✅ but `getInstance()` unguarded
- `weight_tracker_screen._loadData()` — `jsonDecode(logJson)` **inside `setState` with no try/catch** → corrupt data crashes the screen on open
- `ai_chat_screen._loadHistory()` — ✅ has try/catch (good)
- `journal_screen._loadEntries()` — `fromJson` is defensive ✅ but `getInstance()` unguarded

### The irony
`core/storage/local_storage.dart` (`SharedPrefsStorage`) was **built specifically to wrap every prefs call in try/catch returning `Result`** — and then never used (§3). `ErrorHandler.showError()` SnackBar helper also exists, unused; instead `ai_chat_screen.dart` and ` ErrorHandler`-style SnackBars are hand-built twice (`_showError` in ai_chat + `weight_tracker` inline).

### Other unguarded async
- `notification_service.dart` — `scheduleDailyReminder`/`cancelReminder` have no try/catch; a plugin failure propagates into settings UI (`_setDailyReminder`).
- `main.dart` — `Firebase.initializeApp()` and `NotificationService().initialize()` unguarded: if Firebase config is broken, **the app never launches**.
- `money_saved_card._loadPrefs`, `journal_screen._persistEntries`, `checkin_service._save` — fire-and-forget with no failure feedback.

---

## 8. `flutter analyze` Output (full)

```
Analyzing quit_drinking...

   info - Unnecessary braces in a string interpolation. Try removing the braces
          - lib\screens\ai_chat_screen.dart:177:33 - unnecessary_brace_in_string_interps

1 issue found. (ran in 35.7s)
```

- **0 errors, 0 warnings, 1 info lint.**
- No unused imports/variables flagged (the dead code in §3 is *referenced by tests* or fully self-contained, so the analyzer can't see it).

---

## 📊 Summary Scorecard

| Category | Severity | Count |
|---|---|---|
| Hardcoded API key | 🔴 Critical | 1 |
| Duplicate screens/files | 🔴 Critical | 2 (calming_activities ~612 lines dead; walk≈drink_water ~430 lines) |
| Dead architecture layer (`features/`, `LocalStorage`, `Result`, `ErrorHandler`) | 🔴 High | ~770 lines incl. tests kept alive |
| Dead widgets/providers | 🟠 Medium | 6 widgets + 10 providers |
| State management inconsistency | 🟠 Medium | ~9 screens bypass Riverpod |
| Missing error handling | 🟠 Medium | ~15 sites |
| Repeated widget patterns | 🟡 Low | 8 extractable components |
| Analyzer issues | 🟢 | 1 info |

### Suggested fix order (when you're ready)
1. **Rotate/remove the leaked API key.**
2. Delete `calming_activities_screen.dart` (dead duplicate).
3. Merge `walk_screen` + `drink_water` into one parameterized timer screen.
4. Decide: adopt `LocalStorage`+`Result` everywhere **or** delete the unused architecture layer.
5. Delete dead widgets (`section_header`, `ai_chat_pro_card`, `StatCard`, `SoberOutlineButton/TextButton`) and unused providers.
6. Extract `ProGate`, `IconBadge`, `GradientPillButton`, `CelebrationCard`, `confirmDialog`.
7. Add try/catch (or adopt `LocalStorage`) around all prefs access; add timeout to the chat HTTP call; guard `main()` Firebase init.
8. Replace `isDark` ternaries with theme/extension helpers.

*Report only — no code was changed.*
