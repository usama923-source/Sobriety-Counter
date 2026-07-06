# Sober Today

> **A calming wellness app for your sobriety journey.**
> One day at a time.

Sober Today is a premium Flutter application designed to help individuals track and celebrate their sobriety journey. With a calming navy blue aesthetic, smooth animations, and thoughtful interactions inspired by Calm, Headspace, and Apple Health, the app provides a supportive, encouraging experience.

## Features

- **📅 Sobriety Counter** — Live days/hours/minutes/seconds counter with animated transitions
- **💬 Daily Motivation** — 100 curated motivational quotes with favorites and sharing
- **📝 My Reasons** — Personal reasons tracker with full CRUD and animated list
- **💰 Money Saved** — Calculate money saved and drinks avoided with animated stats
- **🫁 Breath Challenge** — Timer-based breath holding challenge with best time and history
- **🧘 Guided Breathing** — Animated 4-4-6 breathing exercise with haptic feedback
- **🏆 Recovery Timeline** — 9 milestone checkpoints with progress tracking and confetti
- **🤝 Craving Help** — Calming "I'm Having a Craving" button with 7 actionable steps
- **✅ Daily Check-In** — Track alcohol-free days with streaks, calendar, and monthly summary
- **🌙 Dark Mode** — Full light/dark theme support with smooth transitions
- **🎉 Confetti Celebrations** — Particle confetti when all milestones are achieved

## Architecture

```
lib/
├── core/                          # Shared infrastructure
│   ├── providers/                 # Riverpod state providers
│   │   ├── breathing_provider.dart
│   │   ├── checkin_provider.dart
│   │   ├── quotes_provider.dart
│   │   ├── reasons_provider.dart
│   │   ├── savings_provider.dart
│   │   ├── sobriety_provider.dart
│   │   └── theme_provider.dart
│   ├── storage/                   # Persistence abstraction
│   │   └── local_storage.dart     # SharedPreferences with Result pattern
│   └── utils/
│       ├── error_handler.dart     # Centralized error handling
│       └── result.dart            # Sealed Result type (Success/Failure)
├── constants/                     # Design tokens
│   ├── app_colors.dart            # Color palette (navy, teal, sky, mint)
│   ├── app_constants.dart         # Spacing, radius, animation durations
│   └── app_text_styles.dart       # Google Fonts Inter typography
├── data/                          # Static data assets
│   └── quotes.dart                # 100 motivational quotes
├── models/                        # Domain models
│   └── milestone.dart             # Milestone thresholds and metadata
├── services/                      # Business logic (ChangeNotifier)
│   ├── breathing_service.dart     # Breath challenge timer + history
│   ├── checkin_service.dart       # Daily check-in, streaks, stats
│   ├── quotes_service.dart        # Daily quotes, favorites
│   ├── reasons_service.dart       # Reasons CRUD
│   ├── savings_service.dart       # Money saved calculations
│   ├── sobriety_service.dart      # Quit date, live counter, milestones
│   └── theme_service.dart         # Dark/light theme mode
├── theme/
│   └── app_theme.dart             # Full Material 3 theme (light + dark)
├── utils/
│   └── responsive_helper.dart     # Responsive layout breakpoints
├── widgets/                       # Reusable UI components
│   ├── breath_challenge_card.dart
│   ├── confetti_celebration.dart  # Custom particle confetti system
│   ├── craving_help_card.dart
│   ├── daily_checkin_card.dart
│   ├── daily_motivation_card.dart
│   ├── empty_state.dart           # Animated empty states
│   ├── guided_breathing_card.dart
│   ├── home_footer.dart
│   ├── home_header.dart
│   ├── milestone_badges.dart
│   ├── money_saved_card.dart
│   ├── my_reasons_card.dart
│   ├── recovery_timeline_card.dart
│   ├── section_header.dart
│   ├── sober_button.dart
│   ├── sober_card.dart            # Premium card with shadows + haptics
│   └── sobriety_counter_card.dart
└── screens/
    └── home_screen.dart           # Main scrollable home screen
```

## State Management

The app uses **Riverpod** for state management with a service layer pattern:

```
UI Widget (ConsumerWidget)
    ↓ ref.watch()
Provider (Riverpod)
    ↓
Service (ChangeNotifier)
    ↓
SharedPreferences (persistence)
```

- **Providers** are defined in `lib/core/providers/`
- **Services** encapsulate business logic and notify on changes
- **Widgets** use `ref.watch(provider)` to react to state changes
- **Pull-to-refresh** re-initializes all services via `ref.read(provider).init()`

## Design System

### Colors

| Token | Light | Dark | Usage |
|-------|-------|------|-------|
| Navy Blue | `#1E3A5F` | — | Primary, headings |
| Sky Blue | `#7FB3D5` | `#A8D0E6` | Secondary, dark mode primary |
| Soft Teal | `#7EC8C3` | — | Accent, success |
| Mint | `#D7F5EF` | — | Light backgrounds |
| Success Green | `#4CAF50` | — | Milestones, streaks |

### Typography

- **Font**: Inter (Google Fonts)
- **Scale**: Material 3 type scale (display → label)
- **Special**: Counter (72px, w200), Quote (18px, w300 italic)

### Animations

- **Fast**: 200ms (hover effects, color transitions)
- **Medium**: 350ms (AnimatedSwitcher, container transitions)
- **Slow**: 600ms (entrance animations, confetti)

## Getting Started

### Prerequisites

- Flutter SDK ^3.10.3
- Dart SDK ^3.10.3
- Android Studio / VS Code with Flutter extensions
- iOS Simulator or Android Emulator (or physical device)

### Installation

```bash
# 1. Clone the repository
git clone <repository-url>
cd quit_drinking

# 2. Install dependencies
flutter pub get

# 3. Run the app
flutter run

# 4. Run on specific platform
flutter run -d chrome       # Web
flutter run -d windows      # Windows desktop
flutter run -d ios          # iOS simulator
flutter run -d android      # Android emulator
```

### Development

```bash
# Run Flutter analysis
flutter analyze

# Run tests
flutter test

# Run tests with coverage
flutter test --coverage

# Generate coverage report
genhtml coverage/lcov.info -o coverage/html
```

## Testing

The app includes:

- **Unit tests** for services and utilities
- **Widget tests** for core UI components
- **Integration tests** (coming soon)

### Test Structure

```
test/
├── services/
│   ├── sobriety_service_test.dart
│   ├── checkin_service_test.dart
│   └── quotes_service_test.dart
├── widgets/
│   ├── sober_card_test.dart
│   └── empty_state_test.dart
└── core/
    └── result_test.dart
```

## Performance

- **RepaintBoundary** on each section to isolate repaints
- **BouncingScrollPhysics** for smooth scrolling
- **Const constructors** wherever possible
- **AnimatedBuilder** for efficient animation rebuilds
- **RepaintBoundary** reduces the cost of individual section rebuilds

## Accessibility

- **Semantics** labels on interactive elements
- **Sufficient color contrast** in both light and dark themes
- **Tooltips** on icon buttons
- **Haptic feedback** on key interactions

## Offline Support

The app works fully offline:
- All data is stored locally via SharedPreferences
- No network requests are required
- Quotes are bundled as local data

## License

This project is for personal use. All rights reserved.
