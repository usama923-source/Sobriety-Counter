import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quit_drinking/theme/app_theme.dart';
import 'package:quit_drinking/screens/home_screen.dart';
import 'package:quit_drinking/core/providers/theme_provider.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );
  runApp(
    const ProviderScope(
      child: SoberTodayApp(),
    ),
  );
}

/// Root widget for the Sober Today application.
/// Wrapped in [ProviderScope] for Riverpod state management.
class SoberTodayApp extends ConsumerStatefulWidget {
  const SoberTodayApp({super.key});

  @override
  ConsumerState<SoberTodayApp> createState() => _SoberTodayAppState();
}

class _SoberTodayAppState extends ConsumerState<SoberTodayApp> {
  bool _showSplash = true;

  @override
  void initState() {
    super.initState();

    // Animate splash screen away after a brief delay
    Future.delayed(const Duration(milliseconds: 1200), () {
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
      title: 'Sober Today',
      debugShowCheckedModeBanner: false,

      // ── Theme ──────────────────────────────────────────────────────────
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeMode,

      // ── Home ───────────────────────────────────────────────────────────
      home: _showSplash ? const _SplashScreen() : const HomeScreen(),

      // ── General ────────────────────────────────────────────────────────
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.noScaling,
          ),
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
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _fadeAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    _scaleAnim = Tween<double>(begin: 0.8, end: 1.0).animate(
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
