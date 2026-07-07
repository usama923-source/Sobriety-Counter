import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quit_drinking/constants/app_colors.dart';
import 'package:quit_drinking/constants/app_constants.dart';
import 'package:quit_drinking/core/providers/theme_provider.dart';
import 'package:quit_drinking/core/providers/sobriety_provider.dart';
import 'package:quit_drinking/core/providers/quotes_provider.dart';
import 'package:quit_drinking/core/providers/reasons_provider.dart';
import 'package:quit_drinking/core/providers/savings_provider.dart';
import 'package:quit_drinking/core/providers/breathing_provider.dart';
import 'package:quit_drinking/core/providers/checkin_provider.dart';
import 'package:quit_drinking/widgets/home_header.dart';
import 'package:quit_drinking/widgets/sobriety_counter_card.dart';
import 'package:quit_drinking/widgets/ai_chat_pro_card.dart';
import 'package:quit_drinking/widgets/daily_motivation_card.dart';
import 'package:quit_drinking/widgets/my_reasons_card.dart';
import 'package:quit_drinking/widgets/money_saved_card.dart';
import 'package:quit_drinking/widgets/breath_challenge_card.dart';
import 'package:quit_drinking/widgets/guided_breathing_card.dart';
import 'package:quit_drinking/widgets/recovery_timeline_card.dart';
import 'package:quit_drinking/widgets/craving_help_card.dart';
import 'package:quit_drinking/widgets/daily_checkin_card.dart';
import 'package:quit_drinking/screens/settings_screen.dart';
import 'package:quit_drinking/screens/ai_chat_screen.dart';
import 'package:quit_drinking/screens/memory_game_screen.dart';
import 'package:quit_drinking/screens/weight_tracker_screen.dart';
import 'package:quit_drinking/widgets/home_footer.dart';
import 'package:quit_drinking/widgets/pro_upgrade_sheet.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Main Home Screen — uses Riverpod [ref.watch] for all state.
///
/// Architecture:
/// - [ConsumerStatefulWidget] provides access to Riverpod ref
/// - Each section widget receives its service via provider rather than
///   constructor injection, making the code more testable and modular.
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final ScrollController _scrollController = ScrollController();
  bool _isInitialLoad = true;
  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();

    // Brief loading overlay for smooth startup
    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) setState(() => _isInitialLoad = false);
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _onRefresh() async {
    HapticFeedback.mediumImpact();
    setState(() => _isRefreshing = true);

    // Re-init all services via their providers
    await Future.wait([
      ref.read(sobrietyServiceProvider).init(),
      ref.read(quotesServiceProvider).init(),
      ref.read(reasonsServiceProvider).init(),
      ref.read(savingsServiceProvider).init(),
      ref.read(breathingServiceProvider).init(),
      ref.read(checkinServiceProvider).init(),
    ]);

    await Future.delayed(const Duration(milliseconds: 300));
    if (mounted) {
      HapticFeedback.heavyImpact();
      setState(() => _isRefreshing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      drawer: _buildDrawer(isDark),
      appBar: _buildAppBar(isDark),
      body: Stack(
        children: [
          RefreshIndicator(
            onRefresh: _onRefresh,
            displacement: 80,
            edgeOffset: 0,
            color: isDark ? AppColors.skyBlueLight : AppColors.navyBlue,
            backgroundColor: isDark ? AppColors.darkSurface : AppColors.white,
            child: _buildBody(isDark),
          ),

          // Initial loading overlay
          if (_isInitialLoad)
            Positioned.fill(
              child: IgnorePointer(
                child: Container(
                  color: isDark
                      ? AppColors.darkSurface.withValues(alpha: 0.7)
                      : AppColors.white.withValues(alpha: 0.7),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 40,
                          height: 40,
                          child: CircularProgressIndicator(
                            strokeWidth: 3,
                            color: isDark
                                ? AppColors.skyBlueLight
                                : AppColors.navyBlue,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Loading your journey...',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: isDark
                                ? AppColors.textOnDarkSecondary
                                : AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

          // Refresh spinner
          if (_isRefreshing)
            Positioned(
              top: 60,
              left: 0,
              right: 0,
              child: Center(
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: isDark ? AppColors.skyBlueLight : AppColors.navyBlue,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(bool isDark) {
    return AppBar(
      elevation: 0,
      scrolledUnderElevation: 0.5,
      backgroundColor: Colors.transparent,
      foregroundColor: isDark ? AppColors.textOnDark : AppColors.textPrimary,
      actions: [
        IconButton(
          onPressed: () => ref.read(themeServiceProvider).toggleTheme(),
          icon: AnimatedCrossFade(
            duration: AppConstants.animationFast,
            crossFadeState: isDark
                ? CrossFadeState.showFirst
                : CrossFadeState.showSecond,
            firstChild: const Icon(
              Icons.light_mode_rounded,
              color: AppColors.softOrangeLight,
            ),
            secondChild: Icon(
              Icons.dark_mode_rounded,
              color: isDark ? AppColors.textOnDark : AppColors.navyBlue,
            ),
          ),
          tooltip: isDark ? 'Light mode' : 'Dark mode',
        ),
        IconButton(
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => const SettingsScreen(),
            ),
          ),
          icon: Icon(
            Icons.settings_rounded,
            color: isDark ? AppColors.textOnDark : AppColors.textSecondary,
          ),
          tooltip: 'Settings',
        ),
        const SizedBox(width: AppConstants.spacingXs),
      ],
    );
  }

  // ── Drawer ────────────────────────────────────────────────────────────

  Widget _buildDrawer(bool isDark) {
    return Drawer(
      backgroundColor: isDark ? AppColors.darkSurface : AppColors.white,
      child: SafeArea(
        child: Column(
          children: [
            // ── App Header ────────────────────────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(
                AppConstants.spacingLg,
                AppConstants.spacingXl,
                AppConstants.spacingLg,
                AppConstants.spacingLg,
              ),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isDark
                      ? [
                          AppColors.navyBlueDark,
                          AppColors.navyBlue.withValues(alpha: 0.6),
                        ]
                      : [
                          AppColors.navyBlue,
                          AppColors.navyBlueLight,
                        ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // App logo
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(
                        AppConstants.radiusSm,
                      ),
                    ),
                    child: const Icon(
                      Icons.self_improvement_rounded,
                      size: 28,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: AppConstants.spacingSm),
                  Text(
                    AppConstants.appName,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    AppConstants.appTagline,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w400,
                      color: Colors.white.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            ),

            // ── Menu Items ───────────────────────────────────────────
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  const SizedBox(height: AppConstants.spacingXs),
                  _DrawerMenuItem(
                    icon: Icons.home_rounded,
                    title: 'Home',
                    isDark: isDark,
                    onTap: () => Navigator.of(context).pop(),
                  ),
                  _DrawerProMenuItem(
                    icon: Icons.smart_toy_rounded,
                    title: 'AI Friend',
                    isDark: isDark,
                    onTapPro: () => _navigateToPro(
                      const AIChatScreen(),
                    ),
                  ),
                  _DrawerProMenuItem(
                    icon: Icons.psychology_rounded,
                    title: 'Memory Game',
                    isDark: isDark,
                    onTapPro: () => _navigateToPro(
                      const MemoryGameScreen(),
                    ),
                  ),
                  _DrawerProMenuItem(
                    icon: Icons.monitor_weight_rounded,
                    title: 'Weight Tracker',
                    isDark: isDark,
                    onTapPro: () => _navigateToPro(
                      const WeightTrackerScreen(),
                    ),
                  ),
                  _DrawerProMenuItem(
                    icon: Icons.settings_rounded,
                    title: 'Settings',
                    isDark: isDark,
                    isPro: false,
                    onTapPro: () {
                      Navigator.of(context).pop();
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const SettingsScreen(),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),

            // ── Footer ───────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.all(AppConstants.spacingLg),
              child: Text(
                'One day at a time.',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                  fontStyle: FontStyle.italic,
                  color: isDark
                      ? AppColors.textOnDarkSecondary.withValues(alpha: 0.4)
                      : AppColors.textTertiary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _navigateToPro(Widget screen) async {
    // Capture navigator and context before any async gap
    final nav = Navigator.of(context);
    final ctx = context;
    // Close drawer first
    nav.pop();

    final prefs = await SharedPreferences.getInstance();
    final isPro = prefs.getBool('is_pro') ?? false;

    if (!ctx.mounted) return;

    if (isPro) {
      nav.push(
        MaterialPageRoute(builder: (_) => screen),
      );
    } else {
      final upgraded = await ProUpgradeSheet.show(ctx);
      if (upgraded && ctx.mounted) {
        nav.push(
          MaterialPageRoute(builder: (_) => screen),
        );
      }
    }
  }

  Widget _buildBody(bool isDark) {
    final soberDays = ref.watch(totalDaysProvider);
    final milestoneDays = ref.watch(hasQuitDateProvider) ? soberDays : 47;

    return Center(
      child: Container(
        constraints:
            const BoxConstraints(maxWidth: AppConstants.maxNarrowWidth),
        child: NotificationListener<ScrollNotification>(
          onNotification: (notification) => false,
          child: SingleChildScrollView(
            controller: _scrollController,
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            padding: EdgeInsets.only(
              top: AppConstants.spacingSm,
              bottom: MediaQuery.paddingOf(context).bottom + 16,
            ),
            child: RepaintBoundary(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const HomeHeader(),
                  const SizedBox(height: AppConstants.spacingLg),

                  RepaintBoundary(
                    child: _AnimatedCardWrapper(
                      index: 2,
                      child: SobrietyCounterCard(
                        service: ref.watch(sobrietyServiceProvider),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppConstants.spacingSm),

                  RepaintBoundary(
                    child: _AnimatedCardWrapper(
                      index: 3,
                      child: const AIChatProCard(),
                    ),
                  ),
                  const SizedBox(height: AppConstants.spacingLg),

                  RepaintBoundary(
                    child: _AnimatedCardWrapper(
                      index: 4,
                      child: DailyMotivationCard(
                        service: ref.watch(quotesServiceProvider),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppConstants.spacingLg),

                  RepaintBoundary(
                    child: _AnimatedCardWrapper(
                      index: 5,
                      child: MyReasonsCard(
                        service: ref.watch(reasonsServiceProvider),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppConstants.spacingLg),

                  RepaintBoundary(
                    child: _AnimatedCardWrapper(
                      index: 6,
                      child: MoneySavedCard(
                        savingsService: ref.watch(savingsServiceProvider),
                        sobrietyService: ref.watch(sobrietyServiceProvider),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppConstants.spacingLg),

                  RepaintBoundary(
                    child: _AnimatedCardWrapper(
                      index: 7,
                      child: BreathChallengeCard(
                        service: ref.watch(breathingServiceProvider),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppConstants.spacingLg),

                  RepaintBoundary(
                    child: _AnimatedCardWrapper(
                      index: 8,
                      child: const CravingHelpCard(),
                    ),
                  ),
                  const SizedBox(height: AppConstants.spacingLg),

                  RepaintBoundary(
                    child: _AnimatedCardWrapper(
                      index: 9,
                      child: const GuidedBreathingCard(),
                    ),
                  ),
                  const SizedBox(height: AppConstants.spacingLg),

                  RepaintBoundary(
                    child: _AnimatedCardWrapper(
                      index: 10,
                      child: RecoveryTimelineCard(currentDays: milestoneDays),
                    ),
                  ),
                  const SizedBox(height: AppConstants.spacingLg),

                  RepaintBoundary(
                    child: _AnimatedCardWrapper(
                      index: 11,
                      child: DailyCheckinCard(
                        service: ref.watch(checkinServiceProvider),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppConstants.spacingLg),

                  RepaintBoundary(
                    child: _AnimatedCardWrapper(
                      index: 12,
                      child: const HomeFooter(),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Drawer Menu Items ────────────────────────────────────────────────

class _DrawerMenuItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final bool isDark;
  final VoidCallback onTap;
  final Widget? trailing;

  const _DrawerMenuItem({
    required this.icon,
    required this.title,
    required this.isDark,
    required this.onTap,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(
        icon,
        size: 22,
        color: isDark ? AppColors.textOnDarkSecondary : AppColors.textSecondary,
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: isDark ? AppColors.textOnDark : AppColors.textPrimary,
        ),
      ),
      trailing: trailing,
      onTap: onTap,
      dense: true,
      horizontalTitleGap: 12,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppConstants.spacingLg,
        vertical: 0,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConstants.radiusSm),
      ),
    );
  }
}

class _DrawerProMenuItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final bool isDark;
  final VoidCallback onTapPro;
  final bool isPro;

  const _DrawerProMenuItem({
    required this.icon,
    required this.title,
    required this.isDark,
    required this.onTapPro,
    this.isPro = true,
  });

  @override
  Widget build(BuildContext context) {
    return _DrawerMenuItem(
      icon: icon,
      title: title,
      isDark: isDark,
      onTap: onTapPro,
      trailing: isPro
          ? Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 4,
              ),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(6),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFFFD700).withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    '🔒',
                    style: TextStyle(fontSize: 11),
                  ),
                  const SizedBox(width: 3),
                  Text(
                    'Pro',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: isDark
                          ? AppColors.navyBlueDark
                          : Colors.white,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            )
          : null,
    );
  }
}

/// Internal wrapper that applies staggered fade+slide+scale entrance animation.
class _AnimatedCardWrapper extends StatefulWidget {
  final int index;
  final Widget child;

  const _AnimatedCardWrapper({
    required this.index,
    required this.child,
  });

  @override
  State<_AnimatedCardWrapper> createState() => _AnimatedCardWrapperState();
}

class _AnimatedCardWrapperState extends State<_AnimatedCardWrapper>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _fadeAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
    _slideAnim = Tween<Offset>(
      begin: const Offset(0.0, 0.04),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );
    _scaleAnim = Tween<double>(begin: 0.97, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );

    Future.delayed(Duration(milliseconds: 60 * widget.index), () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Opacity(
          opacity: _fadeAnim.value,
          child: Transform.translate(
            offset: Offset(0.0, _slideAnim.value.dy * 24),
            child: Transform.scale(
              scale: _scaleAnim.value,
              child: child,
            ),
          ),
        );
      },
      child: widget.child,
    );
  }
}
