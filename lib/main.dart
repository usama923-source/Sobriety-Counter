import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quit_drinking/constants/app_colors.dart';
import 'package:quit_drinking/core/providers/theme_provider.dart';
import 'package:quit_drinking/theme/app_theme.dart';
import 'package:quit_drinking/core/services/notification_service.dart';
import 'package:quit_drinking/firebase_options.dart';
import 'package:quit_drinking/screens/home_screen.dart';
import 'package:quit_drinking/screens/onboarding/onboarding_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    // Firebase is optional (analytics + purchase logging) — continue
    // without it so a broken config never blocks app startup.
    debugPrint('Firebase failed to initialize (continuing without it): $e');
  }

  // Set up local notifications (daily reminder)
  await NotificationService().initialize();

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
  late Animation<double> _fadeAnim;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    // 2 second total: ~1.2s logo fade+scale, then ~0.8s staggered name+tagline.
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );

    _fadeAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );

    _scaleAnim = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
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
              isDark ? const Color(0xFF121B28) : const Color(0xFFF5F7FA),
          body: Center(
            child: FadeTransition(
              opacity: _fadeAnim,
              child: ScaleTransition(
                scale: _scaleAnim,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isDark
                            ? const Color(0xFF1E2D42)
                            : const Color(0xFFD7F5EF),
                      ),
                      child: Icon(
                        Icons.spa_rounded,
                        size: 40,
                        color: isDark
                            ? const Color(0xFFA8D0E6)
                            : const Color(0xFF1E3A5F),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Sober Today',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w700,
                        color: isDark
                            ? const Color(0xFFF7FAFC)
                            : const Color(0xFF1A202C),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'One day at a time.',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w300,
                        fontStyle: FontStyle.italic,
                        color: isDark
                            ? const Color(0xFFB0BEC5)
                            : const Color(0xFF718096),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
