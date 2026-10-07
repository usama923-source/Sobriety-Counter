# STYLE AUDIT — lib/ Directory

**Audited:** `lib/` (all Dart files, ~60 files)
**Tool:** `flutter analyze lib`
**Date:** 2026-10-04

---

## 🔴 Critical / High Severity

### 🔴 R1 — Hardcoded `Color` values in 6 files (should use `AppColors.*`)
Multiple files use literal `Color(0xFFxxxxxx)` values instead of referencing the centralized `AppColors` palette. This breaks the single source of truth and makes theming changes error-prone.

| File | Lines | Issue |
|---|---|---|
| `widgets/pro_teaser_card.dart` | 67, 88, 95 | Uses `Color(0xFF1E3A5F)`, `Color(0xFFFFD700)`, `Color(0xFFFFD700).withValues(alpha: 0.4)` — should be `AppColors.navyBlue`, `AppColors.gold`, `AppColors.gold` |
| `widgets/confetti_celebration.dart` | 59–64 | Uses literal `Color(0xFF5BB4AE)`, `0xFFEF5350`, etc. — should reference `AppColors.softTealDark`, `softRed`, `softOrange`, etc. |
| `widgets/pro_upgrade_sheet.dart` | 70, 76, 145, 152 | Uses `Color(0xFFFFD700)` / gold values — should reference `AppColors.gold` |
| `widgets/guided_breathing_card.dart` | 44–45 | Uses `Color(0xFF7EC8C3)`, `Color(0xFFA8DCD8)` — should reference `AppColors.softTeal`, `softTealLight` |
| `screens/craving/breathing_screen.dart` | 46 | Uses `const Color(0xFF7EC8C3)` — should reference `AppColors.softTeal` |
| `screens/home_screen.dart` | 143, 147, 160, 561, 569, 934, 941 | Uses `Color(0xFF1E3A5F)`, `Color(0xFFFFD700)`, gold variants — should reference `AppColors.navyBlue`, `AppColors.gold` |

**Fix:** Replace all hardcoded `Color(...)` with `AppColors.*` equivalents.

---

### 🔴 R2 — `fontFamily` and `GoogleFonts.*` applied per-widget instead of globally via `Theme`
`app_theme.dart` correctly sets `fontFamily` for headings and body. However:

- `lib/constants/app_text_styles.dart` **hardcodes** `GoogleFonts.inter` for every `static TextStyle` field (display, headline, body, label, counter, quote). This is a **centralized polyfill** — it should delegate to `AppTheme.textTheme` or `GoogleFonts` family fields instead of hardcoding `inter` everywhere.
- Several screens and widgets build `TextStyle` with `GoogleFonts.inter(...)` directly instead of using `Theme.of(context).textTheme`. This means:
  - **Font switching** would require editing every file.
  - `Brightness`-aware textTheme (from `app_theme.dart`) is **not used** in these files.
  - `AppTextStyles` (line 11–153 of `app_text_styles.dart`) is **never imported** anywhere in the codebase — it's dead code.

**Fix:** Remove `AppTextStyles` (dead code), use `Theme.of(context).textTheme` in all widgets, and reference `GoogleFonts.montserrat` / `GoogleFonts.lato` via theme or a central `AppTypography` helper.

---

### 🔴 R3 — 4 screen files misuse `setState` for state that Riverpod should own
These screens hold UI state in `setState` that should be in Riverpod providers:

| File | setState usage | Should be in Riverpod |
|---|---|---|
| `screens/craving/journal_screen.dart` | Line 42: `_isSaving = true/false` | `checkinServiceProvider` state |
| `screens/craving/timed_activity_screen.dart` | Lines 86, 95, 102, 109: timer countdown, remaining seconds | `breathingServiceProvider` + `tickerProvider` |
| `screens/memory_game_screen.dart` | Lines 98, 111, 130, 145, 160, 164: `_elapsedSeconds`, `_isComplete`, `_isLoading`, etc. | `memoryGameServiceProvider` |
| `screens/weight_tracker_screen.dart` | Lines 100, 133, 139, 176, 200: weight values, goal, `_showWeightDialog` | `weightTrackerServiceProvider` |

**Fix:** Move mutable state to Riverpod providers and dispatch updates. Keep `setState` only for UI-only toggles (e.g., dialog open/close).

---

### 🔴 R4 — Top-level `setState` in non-StatefulWidget classes
`widgets/guided_breathing_card.dart` has 5 `setState` calls at lines 113, 124, 165, 171, 197, and line 247 — all in a **StatelessWidget** (`_BreathingCardState` is stateful, but `setState` is called on `this` which is a `StatelessWidget` subclass). This causes a `setState() called on a widget that is not a State` runtime error.

**Fix:** Convert `_BreathingCard` to a `StatefulWidget` (or `_BreathingCardState`) and move all `setState` calls into the proper state class.

---

## 🟠 Medium Severity

### 🟠 M1 — `_CalmCravingButton` uses `setState` on a StatelessWidget
`lib/widgets/craving_help_card.dart` — `_CalmCravingButton` is a `StatelessWidget` but uses `setState` (in prior audit it was flagged). Currently fixed by making it a `StatefulWidget` with `SingleTickerProviderStateMixin`. **Verify** the fix is correct after the conversion.

---

### 🟠 M2 — Unused imports (2 findings)
| File | Unused import |
|---|---|
| `lib/screens/home_screen.dart` | `package:quit_drinking/widgets/breath_challenge_card.dart` |
| `lib/widgets/pro_teaser_card.dart` | `package:quit_drinking/widgets/pro_upgrade_sheet.dart` |

**Fix:** Remove both imports.

---

### 🟠 M3 — `app_text_styles.dart` is dead code
`lib/constants/app_text_styles.dart` defines `AppTextStyles` with `static TextStyle` fields, but **no file imports it**. It was intended as a centralized font style helper but was never wired up. `app_theme.dart` does the actual theming directly.

**Fix:** Either delete `app_text_styles.dart` or wire it up as the single source of truth (e.g., `GoogleFonts.montserratTextTheme()` + `latoTextTheme()`).

---

### 🟠 M4 — File structure: `core/utils/error_handler.dart` in `core/utils/` is not a clean separation
| File | Concern | Better location |
|---|---|---|
| `lib/core/utils/error_handler.dart` | Error handling utilities | `lib/core/utils/` (OK, but depends on `package:flutter/foundation.dart`) |
| `lib/core/utils/result.dart` | `Result<T>` monad | `lib/core/utils/` (OK) |
| `lib/core/storage/local_storage.dart` | File I/O abstraction over SharedPreferences | `lib/core/storage/` (OK) |
| `lib/data/quotes.dart` | Static quote data | `lib/data/` (OK) |

**Candidates for restructuring:**
- `lib/services/breathing_service.dart` — service logic + SharedPreferences — OK as service
- `lib/core/services/notification_service.dart` — platform-specific notification logic — OK as service

No critical architectural issue. The folder structure is reasonable: `constants/`, `core/providers/`, `core/services/`, `core/storage/`, `core/utils/`, `data/`, `models/`, `screens/`, `theme/`, `utils/`, `widgets/`, `config/`, `services/` (shared by screens).

---

### 🟠 M5 — `main.dart` imports `theme_provider.dart` but doesn't use it
`main.dart` imports `package:quit_drinking/core/providers/theme_provider.dart` but the `SoberTodayApp` widget is the actual provider consumer. The import of `theme_provider.dart` is **not used** in `main.dart` (the app reads `themeModeProvider` via `ref.watch` in `_SoberTodayAppState`).

**Fix:** Remove `import 'package:quit_drinking/core/providers/theme_provider.dart';` from `main.dart` (or keep it if the app is expected to consume it later).

---

### 🟠 M6 — `app_theme.dart` uses both `GoogleFonts.inter` and `GoogleFonts.montserrat`
The theme correctly uses `montserrat` for headings and `lato` for body in the new design, but `app_text_styles.dart` (which we flagged as dead code) uses `inter`. This creates a **3-font system** if `AppTextStyles` were ever wired up: **Inter (old centralized), Montserrat (headings), Lato (body)**. The fix is to remove `AppTextStyles` and rely solely on `AppTheme.textTheme`.

---

## 🟢 Low Severity / Observations

### 🟢 L1 — Font usage is 100% centralized in `app_theme.dart`
- `app_theme.dart` (lines 44–535) uses `GoogleFonts.montserratTextTheme()` + `.copyWith()` for headings, `GoogleFonts.lato()` for body, and `GoogleFonts.inter()` for text fields, buttons, inputs, etc.
- `app_text_styles.dart` (lines 11–153) uses `GoogleFonts.inter` for all 17 style fields — but it's **never imported**. If wired up, it would create a 3-font system.
- **Recommendation:** Wire `AppTextStyles` to delegate to `AppTheme.textTheme` or `GoogleFonts` families, or delete it.

---

### 🟢 L2 — `app_colors.dart` is the single source of truth
All color values are centralized in `lib/constants/app_colors.dart`. The only exceptions are the hardcoded `Color()` values listed in R1 (6 files). Once R1 is fixed, the color palette is fully centralized.

---

### 🟢 L3 — `app_constants.dart` is used consistently for spacing/padding
`AppConstants` is referenced in `app_theme.dart`, `sobriety_counter_card.dart`, `my_reasons_card.dart`, `breath_challenge_card.dart`, `guided_breathing_card.dart`, `recovery_timeline_card.dart`, `weight_tracker_screen.dart`, `sober_card.dart`, `home_footer.dart`, `pro_teaser_card.dart`, `sober_button.dart`, `craving_help_card.dart`, `daily_checkin_card.dart`, `money_saved_card.dart`, `breath_challenge_card.dart`, `pro_teaser_card.dart`, `sober_card.dart`, `sober_button.dart`, etc.

**Any hardcoded spacing values** (e.g., `EdgeInsets.all(2)` in `sobriety_counter_card.dart:259`, `padding: const EdgeInsets.only(top: 6)` in `my_reasons_card.dart:419`, `padding: const EdgeInsets.all(6)` in `my_reasons_card.dart:449/467`, `padding: const EdgeInsets.only(bottom: 6)` in `my_reasons_card.dart:406`) should be converted to `AppConstants.spacing*` equivalents.

---

### 🟢 L4 — Widget duplication candidates
The following UI patterns appear in multiple files and could be extracted into shared widgets:

| Pattern | Files | Suggestion |
|---|---|---|
| `SoberCard` wrapper | `craving_help_card.dart`, `breath_challenge_card.dart`, `my_reasons_card.dart`, `daily_checkin_card.dart`, `recovery_timeline_card.dart`, `money_saved_card.dart` | Already extracted as `SoberCard` — **good** |
| Pro teaser card | `pro_teaser_card.dart` + inline usage in `home_screen.dart` | Already extracted as `ProTeaserCard` — **good** |
| `SizedBox(height: AppConstants.spacingLg)` | Multiple screen files, widget files | Could be `const Spacer()` with `AppConstants` — already using `AppConstants` |
| `RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppConstants.radiusLg))` | `app_theme.dart`, `weight_tracker_screen.dart`, `my_reasons_card.dart`, etc. | Already using `AppConstants.radiusLg` — **good** |

**Recommendation:** Extract `_CalmCravingButton` into a shared `CalmButton` widget (currently duplicated per-screen if screens have similar full-width buttons).

---

### 🟢 L5 — Import hygiene: 2 unused imports found
| File | Unused import |
|---|---|
| `lib/screens/home_screen.dart` | `package:quit_drinking/widgets/breath_challenge_card.dart` |
| `lib/widgets/pro_teaser_card.dart` | `package:quit_drinking/widgets/pro_upgrade_sheet.dart` |

---

### 🟢 L6 — `app_text_styles.dart` colors mismatch with `app_colors.dart`
`app_text_styles.dart` uses `GoogleFonts.inter` for text colors, but `app_colors.dart` defines `textPrimary`/`textSecondary` etc. `AppTextStyles` is dead code — no file references it. If it were live, `counter` color `AppColors.navyBlue` and `quote` color `AppColors.textSecondary` align with the palette, but the font would conflict with the new Montserrat/Lato design.

---

## Summary

| Severity | Count | Issues |
|---|---|---|
| 🔴 | 4 | `Color()` hardcoding (R1), font usage per-widget (R2), `setState` in Riverpod-owned state (R3), `setState` in StatelessWidget (R4) |
| 🟠 | 6 | Unused imports (M2), dead code `app_text_styles.dart` (M3), file structure (M4), unused theme_provider import (M5), 3-font system (M6) |
| 🟢 | 6 | Font centralization (L1), color centralization (L2), `AppConstants` usage (L3), widget duplication (L4), import hygiene (L5), dead code (L6) |

**Total:** 16 findings across 3 severity tiers.

**Priority order for fixes:** R1 → R2 → R3 → R4 → M2 → M3 → M5 → M4 → L1–L6
