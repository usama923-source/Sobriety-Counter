import 'package:firebase_core/firebase_core.dart' hide FirebaseService;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quit_drinking/constants/app_colors.dart';
import 'package:quit_drinking/constants/app_constants.dart';
import 'package:quit_drinking/core/providers/currency_provider.dart';
import 'package:quit_drinking/core/providers/sobriety_provider.dart';
import 'package:quit_drinking/core/providers/theme_provider.dart';
import 'package:quit_drinking/theme/app_theme.dart';
import 'package:quit_drinking/core/services/firebase_service.dart';
import 'package:quit_drinking/core/services/notification_service.dart';
import 'package:quit_drinking/firebase_options.dart';
import 'package:quit_drinking/screens/home_screen.dart';
import 'package:quit_drinking/screens/onboarding/onboarding_screen.dart';
import 'package:quit_drinking/widgets/app_logo.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    // Log the app-open event once per launch. Never blocks startup.
    await FirebaseService().logAppOpen();
  } catch (e) {
    // Firebase is optional (analytics + purchase logging) — continue
    // without it so a broken config never blocks app startup.
    debugPrint('Firebase failed to initialize (continuing without it): $e');
  }

  // Set up local notifications (daily reminder)
  await NotificationService().initialize();

  // Re-schedule the daily reminder if the user had it enabled previously.
  await NotificationService().syncScheduledReminder();

  // Check whether the user has completed onboarding
  final prefs = await SharedPreferences.getInstance();
  final onboardingDone = prefs.getBool('onboarding_complete') ?? false;

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );
  runApp(
    ProviderScope(
      child: SoberTodayApp(showOnboarding: !onboardingDone),
    ),
  );
}

/// Root widget for the QuitDrink Ai application.
/// Wrapped in [ProviderScope] for Riverpod state management.
class SoberTodayApp extends ConsumerStatefulWidget {
  final bool showOnboarding;

  const SoberTodayApp({super.key, this.showOnboarding = false});

  @override
  ConsumerState<SoberTodayApp> createState() => _SoberTodayAppState();
}

class _SoberTodayAppState extends ConsumerState<SoberTodayApp> {
  bool _showSplash = true;

  @override
  void initState() {
    super.initState();

    // Start loading the stored quit date while the splash is on screen, so
    // the counter never renders a "no quit date" state first.
    ref.read(sobrietyServiceProvider);

    // Same for the saved currency, so money is never briefly shown with the
    // default symbol on launch.
    ref.read(currencyServiceProvider);

    // And the saved theme, so a dark-mode user never sees a light flash.
    ref.read(themeServiceProvider);

    // Animate splash screen away after 2 seconds
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        HapticFeedback.lightImpact();
        setState(() => _showSplash = false);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp(
      title: 'QuitDrink Ai',
      debugShowCheckedModeBanner: false,

      // ── Theme ──────────────────────────────────────────────────────────
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeMode,

      // ── Home ───────────────────────────────────────────────────────────
      home: _showSplash
          ? const _SplashScreen()
          : (widget.showOnboarding
              ? const OnboardingScreen()
              : const HomeScreen()),

      // ── General ────────────────────────────────────────────────────────
      builder: (context, child) {
        return MediaQuery(
          // Respect the user's system text-scaling setting for accessibility.
          data: MediaQuery.of(context),
          child: child!,
        );
      },
    );
  }
}

// ── Splash Screen ───────────────────────────────────────────────────────

class _SplashScreen extends StatefulWidget {
  const _SplashScreen();

  @override
  State<_SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<_SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _logoFade;
  late Animation<double> _logoScale;
  late Animation<double> _taglineFade;

  @override
  void initState() {
    super.initState();
    // 2 second total: ~1.2s logo fade+scale, then ~0.8s staggered name+tagline.
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );

    // Logo fades + scales first, then the name, then the tagline. Intervals
    // split the same 2s controller so the sequence is staggered.
    _logoFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
      ),
    );

    _logoScale = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOutBack),
      ),
    );

    _taglineFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.5, 0.85, curve: Curves.easeOut),
      ),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return Scaffold(
          backgroundColor:
              isDark ? AppColors.darkSurface : AppColors.lightGray,
          body: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                FadeTransition(
                  opacity: _logoFade,
                  child: ScaleTransition(
                    scale: _logoScale,
                    child: const AppLogo(size: 96),
                  ),
                ),
                const SizedBox(height: 24),
                FadeTransition(
                  opacity: _taglineFade,
                  child: Text(
                    AppConstants.tagline,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w300,
                      fontStyle: FontStyle.italic,
                      color: isDark
                          ? AppColors.textOnDarkSecondary
                          : AppColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
