# 🎨 Color Usage Audit

**Scope:** `lib/widgets/` (19 files) and `lib/screens/` (15 files, incl. `craving/` and `onboarding/`)
**Source of truth:** `lib/constants/app_colors.dart` (33 tokens)
**Method:** static grep of `AppColors.*`, `Colors.*`, `Color(0x…)`, `withValues`, `withOpacity`

---

## Part 1 — Per-file audit

### `lib/widgets/`

#### 1. `ai_chat_pro_card.dart`
- **AppColors:** `navyBlue`, `navyBlueDark`, `darkCard`, `white`, `textOnDark`, `textOnDarkSecondary`, `textPrimary`, `textSecondary`, `textTertiary`
- **Material:** `Colors.white`
- **Hardcoded:** `Color(0xFFFFD700)` gold, `Color(0xFFFFA500)` amber (star rating gradient, L94–95, L103)
- **Flags:** ⚠️ Gold/amber hardcoded — repeated in 3 other files (see summary). Everything else is clean navy/blue branding.

#### 2. `breath_challenge_card.dart`
- **AppColors:** `softTeal`, `softOrange`, `softRed`, `successGreen`, `skyBlueLight`, `navyBlue`, `textOnDark`, `textOnDarkSecondary`, `textPrimary`, `textSecondary`, `textTertiary`, `darkCardAlt`, `lightGray`, `lightGrayAlt`
- **Material:** `Colors.transparent`
- **Hardcoded:** none
- **Flags:** ✅ Consistent — teal primary, orange streak, red/green pass-fail semantics.

#### 3. `confetti_celebration.dart`
- **AppColors:** none
- **Hardcoded (ALL of them):**
  - `Color(0xFF4CAF50)` = successGreen (L59)
  - `Color(0xFFFFB74D)` = softOrange (L60)
  - `Color(0xFF7FB3D5)` = skyBlue (L61)
  - `Color(0xFF7EC8C3)` = softTeal (L62)
  - `Color(0xFFEF5350)` = softRed (L63)
  - `Color(0xFFFFD89B)` = softOrangeLight (L64)
  - `Color(0xFF81C784)` = successGreenLight (L65)
  - `Color(0xFFA8D0E6)` = skyBlueLight (L66)
- **Flags:** 🚩 **Worst offender.** Every single color is a literal duplicate of an `AppColors` token — the comments even name them (`// successGreen`, etc.). Replace all 8 with `AppColors.*`.

#### 4. `craving_help_card.dart`
- **AppColors:** `softTeal`, `mintLight`, `skyBlue`, `textOnDark`, `textOnDarkSecondary`, `textPrimary`, `textSecondary`, `textTertiary`
- **Material:** `Colors.white`, `Colors.transparent`
- **Hardcoded:** none
- **Flags:** ✅ Consistent teal theme; skyBlue only in the CTA gradient.

#### 5. `daily_checkin_card.dart`
- **AppColors:** `softOrange`, `successGreen`, `softRed`, `softTeal`, `textOnDark`, `textOnDarkSecondary`, `textPrimary`, `textTertiary`, `darkCardAlt`, `lightGrayAlt`
- **Material:** `Colors.white` (L273, L377), `Colors.transparent`
- **Hardcoded:** none
- **Flags:** ⚠️ Uses `Colors.white` instead of `AppColors.white` in two spots. Orange accent + green/red status semantics are consistent.

#### 6. `daily_motivation_card.dart`
- **AppColors:** `softOrange`, `skyBlue`, `skyBlueLight`, `navyBlue`, `mint`, `softRed`, `textOnDark`, `textOnDarkSecondary`, `textPrimary`, `textSecondary`, `textTertiary`, `darkCardAlt`, `lightGray`
- **Material:** `Colors.transparent`
- **Hardcoded:** none
- **Flags:** ✅ Orange accent, blue iconography, red favorite heart — semantic and consistent.

#### 7. `empty_state.dart`
- **AppColors:** `textOnDark`, `textOnDarkSecondary`, `textPrimary`, `textSecondary`, `textTertiary`
- **Hardcoded:** none
- **Flags:** ✅ Clean, text-only palette.

#### 8. `guided_breathing_card.dart`
- **AppColors:** `skyBlue`, `softTeal`, `softRed`, `textOnDark`, `textOnDarkSecondary`, `textPrimary`, `textSecondary`, `textTertiary`, `darkCardAlt`, `lightGrayAlt`
- **Material:** `Colors.white`, `Colors.transparent`
- **Hardcoded:**
  - `Color(0xFF7EC8C3)` = softTeal (`_inhaleColor`, L44)
  - `Color(0xFFA8D0E6)` = skyBlueLight (`_holdColor`, L45)
  - `Color(0xFF81C784)` = successGreenLight (`_exhaleColor`, L46)
- **Flags:** 🚩 Three `static const` colors duplicate `AppColors` tokens exactly (comments confirm). `successGreenLight` isn't even used elsewhere in the file. Replace with `AppColors.*`.

#### 9. `home_footer.dart`
- **AppColors:** `textOnDarkSecondary`, `textTertiary`, `darkCardAlt`, `lightGrayAlt`
- **Hardcoded:** none
- **Flags:** ✅ Clean.

#### 10. `home_header.dart`
- **AppColors:** `navyBlue`, `skyBlue`, `skyBlueLight`, `mint`, `textOnDark`, `textOnDarkSecondary`, `textPrimary`, `textSecondary`
- **Hardcoded:** none
- **Flags:** ✅ Clean navy/sky branding.

#### 11. `milestone_badges.dart`
- **AppColors:** `successGreen`, `textOnDarkSecondary`, `textTertiary`, `darkCardAlt`, `lightGrayAlt`
- **Hardcoded:** none
- **Flags:** ✅ Clean green accent.

#### 12. `money_saved_card.dart`
- **AppColors:** `successGreen`, `skyBlue`, `softOrange`, `softTeal`, `textOnDark`, `textOnDarkSecondary`, `textPrimary`, `textSecondary`, `textTertiary`, `darkCardAlt`, `lightGray`, `lightGrayAlt`
- **Material:** `Colors.transparent`
- **Hardcoded:** none
- **Flags:** ⚠️ Four different hues (`skyBlue`, `softOrange`, `softTeal`, `successGreen`) used for the four stat icons — a rainbow where other cards use a single accent. Intentional-looking but inconsistent with the rest of the app.

#### 13. `my_reasons_card.dart`
- **AppColors:** `navyBlue`, `skyBlue`, `skyBlueLight`, `navyBlueDark`, `softRed`, `white`, `darkSurfaceAlt`, `darkCardAlt`, `lightGray`, `textOnDark`, `textOnDarkSecondary`, `textPrimary`, `textSecondary`, `textTertiary`
- **Material:** `Colors.transparent`
- **Hardcoded:** none
- **Flags:** ✅ Blue actions + red delete = semantic.

#### 14. `pro_upgrade_sheet.dart`
- **AppColors:** `textOnDark`, `textOnDarkSecondary`, `textPrimary`, `textSecondary`, `textTertiary`, `darkCardAlt`, `lightGray`
- **Material:** `Colors.white`, `Colors.transparent`, `Colors.black` (barrier, L33)
- **Hardcoded:** `Color(0xFFFFD700)` gold + `Color(0xFFFFA500)` amber (crown gradient, L73, L79 and L148, L155)
- **Flags:** ⚠️ Gold duplicated **twice** in this file and 3× elsewhere — deserves an `AppColors.gold` token. `Colors.black` barrier could be a `scrim` token.

#### 15. `recovery_timeline_card.dart`
- **AppColors:** `successGreen`, `skyBlue`, `textOnDark`, `textOnDarkSecondary`, `textPrimary`, `textSecondary`, `textTertiary`, `darkCardAlt`, `lightGrayAlt`
- **Material:** `Colors.white` (L503), `Colors.transparent`
- **Hardcoded:** none
- **Flags:** ✅ Green primary; skyBlue only in the progress gradient. Clean.

#### 16. `section_header.dart`
- **AppColors:** `navyBlue`, `skyBlueLight`, `textOnDark`, `textPrimary`
- **Hardcoded:** none
- **Flags:** ✅ Clean.

#### 17. `sober_button.dart`
- **AppColors:** `navyBlue`, `navyBlueDark`, `skyBlueLight`, `white`
- **Hardcoded:** none
- **Flags:** ✅ Clean, single blue family.

#### 18. `sober_card.dart`
- **AppColors:** `navyBlue`, `skyBlueLight`, `white`, `darkCard`, `shadowLight`, `shadowDark`, `shadowAccent`, `textOnDark`, `textOnDarkSecondary`, `textPrimary`, `textSecondary`
- **Material:** `Colors.transparent`
- **Hardcoded:** none
- **Flags:** ✅ Clean; correctly uses all 3 shadow tokens.

#### 19. `sobriety_counter_card.dart`
- **AppColors:** `navyBlue`, `skyBlue`, `skyBlueLight`, `navyBlueDark`, `successGreen`, `mint`, `white`, `darkCard`, `darkCardAlt`, `textOnDark`, `textOnDarkSecondary`, `textPrimary`, `textSecondary`, `textTertiary`
- **Hardcoded:** none
- **Flags:** ⚠️ Navy primary + green streak progress = mild hue-mixing, but green-on-blue is defensible. Minor.

---

### `lib/screens/`

#### 1. `ai_chat_screen.dart`
- **AppColors:** almost the entire palette — `navyBlue`, `navyBlueLight`, `navyBlueDark`, `skyBlue`, `skyBlueLight`, `successGreen`, `softOrange`, `softRed`, `white`, `darkSurface`, `darkSurfaceAlt`, `darkCardAlt`, `lightGray`, `lightGrayAlt`, `shadowLight`, `shadowDark`, `textOnDark`, `textOnDarkSecondary`, `textPrimary`, `textSecondary`, `textTertiary`
- **Material:** `Colors.white`, `Colors.transparent`
- **Hardcoded:** none
- **Flags:** ⚠️ Very broad palette: navy bubbles, green/orange API-status chips, red errors. Each hue is semantic, so acceptable — but it's the widest usage in the app.

#### 2. `home_screen.dart`
- **AppColors:** `navyBlue`, `navyBlueDark`, `skyBlueLight`, `successGreen`, `successGreenLight`, `softOrangeLight`, `white`, `darkSurface`, `textOnDark`, `textOnDarkSecondary`, `textPrimary`, `textSecondary`, `textTertiary`
- **Material:** `Colors.white`, `Colors.transparent`
- **Hardcoded:** `Color(0xFFFFD700)` gold + `Color(0xFFFFA500)` amber (PRO badge, L716, L723)
- **Flags:** 🚩 **Hue-mixing:** the FAB and app bar are navy blue, but the drawer's active-item gradient is **green** (`successGreen`/`successGreenLight`, L307–312 — switched from navy in a recent change). PRO badge gold. Three competing primary hues on one screen.

#### 3. `memory_game_screen.dart`
- **AppColors:** `navyBlue`, `navyBlueLight`, `navyBlueDark`, `skyBlue`, `successGreen`, `successGreenLight`, `white`, `darkSurface`, `darkCard`, `darkCardAlt`, `lightGray`, `lightGrayAlt`, `textOnDark`, `textOnDarkSecondary`, `textPrimary`, `textSecondary`, `textTertiary`
- **Material:** `Colors.white`, `Colors.transparent`
- **Hardcoded:** none
- **Flags:** ✅ Navy cards + green score/matches — clear semantics.

#### 4. `privacy_policy_screen.dart`
- **AppColors:** `navyBlue`, `skyBlue`, `successGreen`, `softTeal`, `softOrange`, `softRed`, `white`… (via icon list), `darkSurface`, `lightGray`, `textOnDark`, `textOnDarkSecondary`, `textPrimary`, `textSecondary`, `textTertiary`
- **Material:** `Colors.transparent`
- **Hardcoded:** none
- **Flags:** ✅ Rainbow icon list (6 hues for 6 data categories) — intentional and consistent with ToS.

#### 5. `settings_screen.dart`
- **AppColors:** `navyBlue`, `skyBlue`, `skyBlueLight`, `successGreen`, `softOrange`, `softTeal`, `softRed`, `white`, `darkSurface`, `darkSurfaceAlt`, `darkCardAlt`, `lightGray`, `lightGrayAlt`, `textOnDark`, `textOnDarkSecondary`, `textPrimary`, `textSecondary`, `textTertiary`
- **Material:** `Colors.white`, `Colors.transparent`
- **Hardcoded:** none
- **Flags:** ✅ Multi-hue but each mapped semantically (red destructive, orange notifications, green data, navy links/toggles).

#### 6. `terms_of_service_screen.dart`
- **AppColors:** same rainbow set as privacy screen: `navyBlue`, `skyBlue`, `successGreen`, `softTeal`, `softOrange`, `softRed`, `darkSurface`, `lightGray`, text tokens
- **Material:** `Colors.transparent`
- **Hardcoded:** none
- **Flags:** ✅ Same pattern as privacy — consistent.

#### 7. `weight_tracker_screen.dart`
- **AppColors:** `successGreen`, `softTeal`, `skyBlue`, `skyBlueLight`, `navyBlue`, `navyBlueLight`, `white`, `darkSurface`, `darkCard`, `darkCardAlt`, `lightGray`, `lightGrayAlt`, text tokens
- **Material:** `Colors.white`, `Colors.transparent`
- **Hardcoded:** none
- **Flags:** ⚠️ **Hue-mixing:** green primary buttons/rings, teal secondary metric, skyBlue water row, navy links — four families on one screen. Functional but visually busy.

#### 8. `craving/breathing_screen.dart`
- **AppColors:** `skyBlueLight`, `successGreenLight`, `successGreen`, `softOrange`, `softOrangeLight`, `softRed`, `softRedLight`, `white`, `darkSurface`, `darkCard`, `darkCardAlt`, `lightGray`, `lightGrayAlt`, text tokens
- **Material:** `Colors.white`, `Colors.transparent`
- **Hardcoded:** `const Color(0xFF7EC8C3)` = softTeal (L46, `inhale` phase color)
- **Flags:** 🚩 **Inconsistent:** L46 hardcodes softTeal for the inhale phase, while the adjacent L48/L50 use `AppColors.skyBlueLight` / `AppColors.successGreenLight` for the other two phases. One line should be `AppColors.softTeal`.

#### 9. `craving/calming_activities_screen.dart`
- **AppColors:** `navyBlue`, `navyBlueLight`, `navyBlueDark`, `skyBlue`, `successGreen`, `successGreenLight`, `softTeal`, `softOrange`, `white`, `darkSurface`, `darkSurfaceAlt`, `lightGray`, text tokens
- **Material:** `Colors.white`, `Colors.black` (barrier, L425), `Colors.transparent`
- **Hardcoded:** `Color(0xFFFFD700)` gold + `Color(0xFFFFA500)` amber (PRO badge, L284–285)
- **Flags:** ⚠️ Activity icons each have their own hue (blue/green/teal/orange/navy) — intentional variety, but note the same `is_pro` upgrade path exists here as in `pro_upgrade_sheet.dart` (gold repeated).

#### 10. `craving/drink_water_screen.dart`
- **AppColors:** `skyBlue`, `successGreen`, `successGreenLight`, `softTeal`, `white`, `darkSurface`, `darkCard`, `darkCardAlt`, `lightGray`, `lightGrayAlt`, text tokens
- **Material:** `Colors.white`, `Colors.transparent`
- **Hardcoded:** none
- **Flags:** ✅ SkyBlue water theme + green for reached goals — consistent.

#### 11. `craving/journal_screen.dart`
- **AppColors:** `softOrange`, `softOrangeLight`, `softRed`, `navyBlue`, `skyBlueLight`, `white`, `darkSurface`, `darkSurfaceAlt`, `darkCard`, `darkCardAlt`, `lightGray`, `lightGrayAlt`, text tokens
- **Material:** `Colors.white`, `Colors.transparent`
- **Hardcoded:** none
- **Flags:** ✅ Orange journal theme + red delete — consistent.

#### 12. `craving/motivation_screen.dart`
- **AppColors:** `successGreen`, `successGreenLight`, `navyBlue`, `skyBlueLight`, `softRed`, `white`, `darkSurface`, `darkCard`, `darkCardAlt`, `lightGray`, `lightGrayAlt`, text tokens
- **Material:** `Colors.white`, `Colors.transparent`
- **Hardcoded:** none
- **Flags:** ⚠️ Green + navy + red combined; red only for the "not saved" state. Mostly semantic, minor mixing.

#### 13. `craving/my_reasons_screen.dart`
- **AppColors:** `softTeal`, `softTealLight`, `softRed`, `white`, `darkSurface`, `darkSurfaceAlt`, `darkCardAlt`, `lightGray`, text tokens
- **Material:** `Colors.white`, `Colors.transparent`
- **Hardcoded:** none
- **Flags:** ✅ Teal actions + red delete — consistent (mirrors the home card).

#### 14. `craving/walk_screen.dart`
- **AppColors:** `successGreen`, `successGreenLight`, `white`, `darkSurface`, `darkCard`, `darkCardAlt`, `lightGray`, `lightGrayAlt`, text tokens
- **Material:** `Colors.white`, `Colors.transparent`
- **Hardcoded:** none
- **Flags:** ✅ All-green theme — the most consistent screen in the app.

#### 15. `onboarding/onboarding_screen.dart`
- **AppColors:** `navyBlue`, `navyBlueLight`, `navyBlueDark`, `skyBlue`, `successGreen`, `softOrange`, `softTeal`, `white`, `darkSurface`, `darkSurfaceAlt`, `darkCard`, `darkCardAlt`, `lightGray`, `lightGrayAlt`, text tokens
- **Material:** `Colors.white`, `Colors.transparent`
- **Hardcoded:** none
- **Flags:** ✅ Navy primary; each of the 4 steps gets its own accent color (orange → green → blue → teal) — intentional per-page theming.

---

## Part 2 — `AppColors` inventory (used vs unused)

| Token | Value | Used? | Where |
|---|---|---|---|
| `navyBlue` | `0xFF1E3A5F` | ✅ Used | Everywhere (primary) |
| `navyBlueLight` | `0xFF2C5282` | ✅ Used | ai_chat, memory_game, weight_tracker, onboarding, calming_activities |
| `navyBlueDark` | `0xFF142A47` | ✅ Used | ai_chat, home, memory_game, onboarding, buttons, AI card |
| `skyBlue` | `0xFF7FB3D5` | ✅ Used | craving_help, guided_breathing, settings, weight_tracker, drink_water, daily_motivation, recovery_timeline, etc. |
| `skyBlueLight` | `0xFFA8D0E6` | ✅ Used | Many (icon color, light mode accents) |
| `skyBlueDark` | `0xFF5A9BC4` | ❌ **UNUSED** | — |
| `softTeal` | `0xFF7EC8C3` | ✅ Used | breath_challenge, craving_help, my_reasons, drink_water, weight_tracker, etc. |
| `softTealLight` | `0xFFA8DCD8` | ✅ Used | my_reasons_screen only |
| `softTealDark` | `0xFF5BB4AE` | ❌ **UNUSED** | — |
| `mint` | `0xFFD7F5EF` | ✅ Used | sobriety_counter, home_header, daily_motivation |
| `mintLight` | `0xFFE8FAF6` | ✅ Used | craving_help_card only |
| `lightGray` | `0xFFF5F7FA` | ✅ Used | Everywhere (screen background) |
| `lightGrayAlt` | `0xFFEDF0F5` | ✅ Used | Everywhere (card alt background) |
| `white` | `0xFFFFFFFF` | ✅ Used | Everywhere |
| `darkSurface` | `0xFF121B28` | ✅ Used | Everywhere (dark bg) |
| `darkSurfaceAlt` | `0xFF1A2537` | ✅ Used | my_reasons, settings, journal, onboarding |
| `darkCard` | `0xFF1E2D42` | ✅ Used | Many (dark card bg) |
| `darkCardAlt` | `0xFF25364D` | ✅ Used | Many (dark alt bg) |
| `successGreen` | `0xFF4CAF50` | ✅ Used | Many (milestones, check-in, savings, walk…) |
| `successGreenLight` | `0xFF81C784` | ✅ Used | memory_game, walk, drink_water, motivation, breathing, calming_activities |
| `softOrange` | `0xFFFFB74D` | ✅ Used | Many (journal, streak, check-in, settings…) |
| `softOrangeLight` | `0xFFFFD89B` | ✅ Used | home, journal, breathing |
| `softRed` | `0xFFEF5350` | ✅ Used | Many (delete, errors, danger) |
| `softRedLight` | `0xFFE57373` | ✅ Used | breathing_screen only |
| `textPrimary` | `0xFF1A202C` | ✅ Used | Everywhere |
| `textSecondary` | `0xFF718096` | ✅ Used | Everywhere |
| `textTertiary` | `0xFFA0AEC0` | ✅ Used | Everywhere |
| `textOnDark` | `0xFFF7FAFC` | ✅ Used | Everywhere |
| `textOnDarkSecondary` | `0xFFB0BEC5` | ✅ Used | Everywhere |
| `shadowLight` | black @ 6% | ✅ Used | sober_card, ai_chat |
| `shadowDark` | black @ 20% | ✅ Used | sober_card, ai_chat |
| `shadowAccent` | navy @ 15% | ✅ Used | sober_card only |

**Unused tokens (2):**
1. ❌ `AppColors.skyBlueDark` (`0xFF5A9BC4`)
2. ❌ `AppColors.softTealDark` (`0xFF5BB4AE`)

> Both are the only `*Dark` variants with zero references — candidates for removal or intentional use in dark-mode gradients.

---

## Part 3 — Cross-cutting findings

### 🚩 1. Hardcoded colors that should be `AppColors` (highest priority)
| File | Lines | Hardcoded | Should be |
|---|---|---|---|
| `confetti_celebration.dart` | 59–66 | 8 literals | `successGreen`, `softOrange`, `skyBlue`, `softTeal`, `softRed`, `softOrangeLight`, `successGreenLight`, `skyBlueLight` |
| `guided_breathing_card.dart` | 44–46 | `0xFF7EC8C3`, `0xFFA8D0E6`, `0xFF81C784` | `softTeal`, `skyBlueLight`, `successGreenLight` |
| `craving/breathing_screen.dart` | 46 | `0xFF7EC8C3` | `softTeal` (L48–50 already use AppColors — this is an inconsistency *within* the file) |

### ⚠️ 2. Recurring gold/amber — should become a named token
`Color(0xFFFFD700)` + `Color(0xFFFFA500)` (PRO badge / crown / stars) appear in **4 files, 9 occurrences**:
- `home_screen.dart` (L716, L723)
- `pro_upgrade_sheet.dart` (L73, L79, L148, L155)
- `calming_activities_screen.dart` (L284–285)
- `ai_chat_pro_card.dart` (L94–95, L103)

Recommendation: add `AppColors.gold` / `AppColors.goldDark` (or `softGold` to match naming).

### ⚠️ 3. `Colors.white` vs `AppColors.white` mixed usage
`Colors.white` (Material) is used in ~15 files even though `AppColors.white` exists. Both are `0xFFFFFFFF`, so it's harmless, but inconsistent. Pick one (either keep `Colors.white` app-wide and delete `AppColors.white`, or standardize on `AppColors.white`).

### ⚠️ 4. `Colors.black` barrier in bottom sheets
`pro_upgrade_sheet.dart` (L33) and `calming_activities_screen.dart` (L425) use `Colors.black.withValues(alpha: 0.4)` for modal barriers. Consider an `AppColors.scrim` token. (Low priority — standard Flutter idiom.)

### ⚠️ 5. Hue-mixing on the home screen
The FAB/app bar are **navy blue** while the drawer's active-item gradient is **green** (`successGreen` → `successGreenLight`, `home_screen.dart` L307–312). This was recently changed from navy to green and now competes with the navy primary. Pick one primary hue for the home screen.

### ⚠️ 6. Rainbow stat cards (minor)
`money_saved_card.dart` and `weight_tracker_screen.dart` use 3–4 distinct hues (`skyBlue`, `softOrange`, `softTeal`, `successGreen`) for parallel stats. Each hue is meaningful, but it breaks the "one accent per card" convention used elsewhere.

### ✅ 7. What's done well
- Dark-mode variants (`isDark ? … : …`) are used consistently in nearly every file.
- Semantic color use (red = destructive, green = success, orange = streak/warning) is consistent across the app.
- `sober_card.dart` correctly consumes all three shadow tokens; only `ai_chat_screen.dart` and `sober_card.dart` touch shadows at all.

---

## Recommended cleanup order
1. Replace hardcoded palette literals in `confetti_celebration.dart`, `guided_breathing_card.dart`, `craving/breathing_screen.dart` with `AppColors.*` (pure refactor, zero visual change).
2. Add `gold`/`goldDark` to `AppColors` and replace the 9 gold/amber literals.
3. Delete (or start using) `AppColors.skyBlueDark` and `AppColors.softTealDark`.
4. Standardize `Colors.white` vs `AppColors.white`.
5. Decide the home-screen primary: navy FAB **or** green drawer gradient — not both.
