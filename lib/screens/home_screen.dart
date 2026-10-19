import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quit_drinking/constants/app_colors.dart';
import 'package:quit_drinking/constants/app_constants.dart';
import 'package:quit_drinking/core/providers/currency_provider.dart';
import 'package:quit_drinking/core/providers/theme_provider.dart';
import 'package:quit_drinking/core/providers/sobriety_provider.dart';
import 'package:quit_drinking/core/providers/quotes_provider.dart';
import 'package:quit_drinking/core/providers/reasons_provider.dart';
import 'package:quit_drinking/core/providers/savings_provider.dart';
import 'package:quit_drinking/core/providers/breathing_provider.dart';
import 'package:quit_drinking/core/providers/checkin_provider.dart';
import 'package:quit_drinking/widgets/home_header.dart';
import 'package:quit_drinking/widgets/sobriety_counter_card.dart';
import 'package:quit_drinking/widgets/daily_motivation_card.dart';
import 'package:quit_drinking/widgets/my_reasons_card.dart';
import 'package:quit_drinking/widgets/money_saved_card.dart';
import 'package:quit_drinking/widgets/guided_breathing_card.dart';
import 'package:quit_drinking/widgets/feature_card.dart';
import 'package:quit_drinking/widgets/recovery_timeline_card.dart';
import 'package:quit_drinking/widgets/craving_help_card.dart';
import 'package:quit_drinking/widgets/daily_checkin_card.dart';
import 'package:quit_drinking/screens/settings_screen.dart';
import 'package:quit_drinking/screens/ai_chat_screen.dart';
import 'package:quit_drinking/screens/memory_game_screen.dart';
import 'package:quit_drinking/screens/weight_tracker_screen.dart';
import 'package:quit_drinking/screens/craving/craving_actions_screen.dart';
import 'package:quit_drinking/widgets/home_footer.dart';
import 'package:quit_drinking/widgets/pro_upgrade_sheet.dart';

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
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  /// Time of the last back press that only showed the "press again" notice.
  DateTime? _lastBackPress;

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

  // ── Main build method ──────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final content = Scaffold(
      key: _scaffoldKey,
      drawer: _buildDrawer(isDark),
      appBar: _buildAppBar(isDark),
      floatingActionButton: _buildAIFab(),
      body: Stack(
        children: [
          RefreshIndicator(
            onRefresh: _onRefresh,
            displacement: 80,
            edgeOffset: 0,
            color: isDark ? AppColors.brandLightBlue : AppColors.brandPrimary,
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
                                ? AppColors.brandLightBlue
                                : AppColors.brandPrimary,
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
                                : AppColors.secondaryTextLight,
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
                    color: isDark ? AppColors.brandLightBlue : AppColors.brandPrimary,
                  ),
                ),
              ),
            ),
        ],
      ),
    );

    // Home sits at the root of the navigator: back must never pop it, or the
    // stack empties and the app renders black. This scope only applies while
    // Home is the top route, so pushed screens keep their own back handling.
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) => _handleSystemBack(didPop),
      child: content,
    );
  }

  /// First back press warns, a second one within two seconds exits the app.
  void _handleSystemBack(bool didPop) {
    if (didPop) return;

    final scaffold = _scaffoldKey.currentState;
    if (scaffold != null && scaffold.isDrawerOpen) {
      scaffold.closeDrawer();
      return;
    }

    final now = DateTime.now();
    final lastPress = _lastBackPress;
    if (lastPress == null ||
        now.difference(lastPress) > const Duration(seconds: 2)) {
      _lastBackPress = now;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Press back again to exit'),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppConstants.radiusSm),
          ),
          margin: const EdgeInsets.all(AppConstants.spacingMd),
        ),
      );
      return;
    }

    HapticFeedback.lightImpact();
    SystemNavigator.pop();
  }

  // ── Refresh ────────────────────────────────────────────────────────

  Future<void> _onRefresh() async {
    HapticFeedback.mediumImpact();
    setState(() => _isRefreshing = true);

    try {
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
    } catch (e, stackTrace) {
      debugPrint('[Home] Refresh failed: $e\n$stackTrace');
    } finally {
      // Always clear the spinner, even if one of the reloads failed.
      if (mounted) {
        HapticFeedback.heavyImpact();
        setState(() => _isRefreshing = false);
      }
    }
  }

  // ── AppBar ────────────────────────────────────────────────────────────

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
              color: AppColors.brandLightBlue,
            ),
            secondChild: Icon(
              Icons.dark_mode_rounded,
              color: isDark ? AppColors.textOnDark : AppColors.brandPrimary,
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
            color: isDark ? AppColors.textOnDark : AppColors.secondaryTextLight,
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
      // Only the header carries a background; the body is plain surface.
      backgroundColor: isDark ? AppColors.darkSurface : AppColors.white,
      // Only the bottom inset is needed: the gradient header paints behind
      // the status bar and adds that inset to its own top padding instead.
      child: SafeArea(
        top: false,
        child: Column(
          children: [
            // ── Header — gradient with logo + tagline ────────────────
            Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppColors.brandPrimary,
                    AppColors.brandPrimaryLight,
                  ],
                ),
              ),
              padding: EdgeInsets.fromLTRB(
                AppConstants.spacingLg,
                MediaQuery.paddingOf(context).top + AppConstants.spacingMd,
                AppConstants.spacingLg,
                AppConstants.spacingXl,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Raw brand mark — centered, no circular crop, no box.
                  Center(
                    child: Image.asset(
                      'assets/logo_icon.png',
                      width: 104,
                      height: 104,
                      fit: BoxFit.contain,
                      // Decode at ~3× the rendered size for crisp scaling.
                      cacheWidth: 312,
                      errorBuilder: (context, error, stackTrace) =>
                          const Icon(
                        Icons.spa_rounded,
                        size: 52,
                        color: AppColors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppConstants.spacingMd),
                  const Text(
                    AppConstants.tagline,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w400,
                      fontStyle: FontStyle.italic,
                      color: AppColors.white,
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
                    isSelected: true,
                    onTap: _closeDrawer,
                  ),
                  _DrawerMenuItem(
                    icon: Icons.self_improvement_rounded,
                    title: 'Calming Activities',
                    isDark: isDark,
                    onTap: () {
                      _closeDrawer();
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const CravingActionsScreen(),
                        ),
                      );
                    },
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
                      _closeDrawer();
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
          ],
        ),
      ),
    );
  }

  // ── AI Friend FAB ─────────────────────────────────────────────────────

  Widget _buildAIFab() {
    return FloatingActionButton(
      onPressed: _onAIFabTap,
      tooltip: 'Talk to AI Friend',
      backgroundColor: Colors.transparent,
      elevation: 4,
      highlightElevation: 8,
      shape: const CircleBorder(),
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: AppColors.brandPrimary,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: AppColors.brandPrimary.withValues(alpha: 0.35),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(
            color: AppColors.brandPrimary,
            width: 3,
          ),
        ),
        child: const Center(
          child: Icon(
            Icons.smart_toy_rounded,
            size: 26,
            color: AppColors.white,
          ),
        ),
      ),
    );
  }

  Future<void> _onAIFabTap() async {
    // Reads through the Pro gate: while billing is off (kProEnabled = false)
    // this is always true, so the feature opens directly. The upgrade branch
    // stays in place for when billing is switched back on.
    final isPro = await ref.read(isProProvider.future);

    if (!mounted) return;

    if (isPro) {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const AIChatScreen()),
      );
    } else {
      final upgraded = await ProUpgradeSheet.show(context);
      if (upgraded && mounted) {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const AIChatScreen()),
        );
      }
    }
  }

  /// Closes the drawer through the [Scaffold], not the navigator.
  ///
  /// `Navigator.pop()` only dismisses the drawer while it still owns a local
  /// history entry; once the drawer is closing (a second tap, or a tap during
  /// the close animation) that pop reaches Home — the app's only route — and
  /// leaves an empty navigator, which renders as a black screen.
  void _closeDrawer() {
    final scaffold = _scaffoldKey.currentState;
    if (scaffold != null && scaffold.isDrawerOpen) {
      scaffold.closeDrawer();
    }
  }

  Future<void> _navigateToPro(Widget screen) async {
    // Capture navigator and context before any async gap
    final nav = Navigator.of(context);
    final ctx = context;
    // Close drawer first — never with a navigator pop, see [_closeDrawer].
    _closeDrawer();

    // Reads through the Pro gate: always true while billing is off, so the
    // feature opens directly. The upgrade path stays for later billing.
    final isPro = await ref.read(isProProvider.future);

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

  // ── Body ──────────────────────────────────────────────────────────────

  Widget _buildBody(bool isDark) {
    final soberDays = ref.watch(totalDaysProvider);
    // No hardcoded fallback: with no quit date the timeline shows its
    // "set your quit date" state instead of a fabricated day count.
    final milestoneDays = ref.watch(hasQuitDateProvider) ? soberDays : 0;

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
                      // Only this card rebuilds on the once-per-second tick.
                      child: Consumer(
                        builder: (context, ref, _) => SobrietyCounterCard(
                          service: ref.watch(sobrietyServiceProvider),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppConstants.spacingLg),

                  // AI Friend — right after the sobriety card.
                  FeatureCard(
                    icon: Icons.smart_toy_rounded,
                    title: 'AI Friend',
                    subtitle: '24/7 AI support during cravings',
                    onTap: () => _navigateToPro(const AIChatScreen()),
                  ),
                  const SizedBox(height: AppConstants.spacingLg),

                  RepaintBoundary(
                    child: _AnimatedCardWrapper(
                      index: 3,
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
                      child: const CravingHelpCard(),
                    ),
                  ),
                  const SizedBox(height: AppConstants.spacingLg),

                  // Memory Game — right after Craving Help.
                  FeatureCard(
                    icon: Icons.psychology_rounded,
                    title: 'Memory Game',
                    subtitle: 'Beat cravings with a focus game',
                    onTap: () => _navigateToPro(const MemoryGameScreen()),
                  ),
                  const SizedBox(height: AppConstants.spacingLg),

                  RepaintBoundary(
                    child: _AnimatedCardWrapper(
                      index: 8,
                      child: MoneySavedCard(
                        savingsService: ref.watch(savingsServiceProvider),
                        // reactive: the card follows the currency chosen in
                        // Settings without needing a refresh.
                        currencyService: ref.watch(currencyServiceProvider),
                        // read (not watch): this card must not rebuild on the
                        // once-per-second sobriety counter tick.
                        sobrietyService: ref.read(sobrietyServiceProvider),
                      ),
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

                  // Weight Tracker — right after Guided Breathing.
                  FeatureCard(
                    icon: Icons.monitor_weight_rounded,
                    title: 'Weight Tracker',
                    subtitle: 'Track your body transformation',
                    onTap: () => _navigateToPro(const WeightTrackerScreen()),
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

// ── Drawer Menu Items ────────────────────────────────────────────────

class _DrawerMenuItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final bool isDark;
  final VoidCallback onTap;
  final Widget? trailing;
  final bool isSelected;

  const _DrawerMenuItem({
    required this.icon,
    required this.title,
    required this.isDark,
    required this.onTap,
    this.trailing,
    this.isSelected = false,
  });

  @override
  Widget build(BuildContext context) {
    // Navy content in light mode, light content in dark mode. The selected
    // item gets a light-blue tint with navy (light) / light-blue (dark) text.
    final Color foreground = isDark
        ? (isSelected ? AppColors.brandLightBlue : AppColors.textOnDark)
        : AppColors.brandPrimary;

    return ListTile(
      selected: isSelected,
      selectedTileColor:
          AppColors.brandLightBlue.withValues(alpha: isDark ? 0.18 : 0.22),
      leading: Icon(
        icon,
        size: 22,
        color: foreground,
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: foreground,
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
    // The gold PRO badge only exists while billing is switched on.
    this.isPro = kProEnabled,
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
                color: AppColors.gold,
                borderRadius: BorderRadius.circular(6),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.gold.withValues(alpha: 0.3),
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
                      color: AppColors.brandPrimary,
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
