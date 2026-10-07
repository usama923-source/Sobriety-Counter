import 'package:flutter/material.dart';
import "dart:async";
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:quit_drinking/constants/app_colors.dart';
import 'package:quit_drinking/constants/app_constants.dart';
import 'package:quit_drinking/widgets/app_logo.dart';
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
import 'package:quit_drinking/widgets/pro_teaser_card.dart';
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

class _HomeScreenState extends ConsumerState<HomeScreen>
    with SingleTickerProviderStateMixin {
  final ScrollController _scrollController = ScrollController();
  bool _isInitialLoad = true;
  bool _isRefreshing = false;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  // Drawer tooltip state
  OverlayEntry? _tooltipEntry;
  AnimationController? _tooltipFadeController;
  Timer? _tooltipTimer;

  @override
  void initState() {
    super.initState();

    // Brief loading overlay for smooth startup
    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) setState(() => _isInitialLoad = false);
    });

    // One-time drawer tooltip on first launch
    _initDrawerTooltip();
  }

  @override
  void dispose() {
    _tooltipTimer?.cancel();
    // Dispose the tooltip fade controller even if the auto-dismiss timer
    // never fired (e.g. user left the screen immediately) — otherwise the
    // controller and its overlay entry leak.
    _tooltipFadeController?.dispose();
    _tooltipFadeController = null;
    _tooltipEntry?.remove();
    _tooltipEntry?.dispose();
    _tooltipEntry = null;
    _scrollController.dispose();
    super.dispose();
  }

  // ── Drawer tooltip (one-time, first launch) ─────────────────────────

  Future<void> _initDrawerTooltip() async {
    final prefs = await SharedPreferences.getInstance();

    // Already shown this session? Skip.
    if (prefs.getBool('drawer_tooltip_shown') ?? false) return;

    _showDrawerTooltip();
  }

  void _showDrawerTooltip() {
    if (!mounted) return;

    final scaffoldContext = _scaffoldKey.currentContext;
    if (scaffoldContext == null) return;

    // Fade transition controller for the tooltip (tracked on the state so
    // dispose() can always clean it up).
    final fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _tooltipFadeController = fadeController;
    final fadeAnimation = CurvedAnimation(parent: fadeController, curve: Curves.easeOut);

    final entry = OverlayEntry(
      builder: (context) => Positioned(
        left: 8,
        top: 56,
        child: FadeTransition(
          opacity: fadeAnimation,
          child: Material(
            color: Colors.transparent,
            child: Center(
              child: _drawerTooltipContent(),
            ),
          ),
        ),
      ),
    );

    // Add to overlay, then track it and start fade in.
    // Assigned only after a successful insert so a non-null field always
    // means "inserted and safe to remove".
    Overlay.of(scaffoldContext).insert(entry);
    _tooltipEntry = entry;
    fadeController.forward();

    // Fade out after 3s, then mark as shown
    _tooltipTimer = Timer(const Duration(seconds: 3), () {
      if (!mounted) return;
      _removeDrawerTooltip();
    });
  }

  /// Removes the tooltip overlay, disposes its animation controller, and
  /// persists the "shown" flag. Safe to call from both the timer callback
  /// and [dispose] (fields are nulled out so nothing is cleaned up twice).
  void _removeDrawerTooltip() {
    _tooltipTimer?.cancel();
    _tooltipTimer = null;

    _tooltipFadeController?.dispose();
    _tooltipFadeController = null;

    _tooltipEntry?.remove();
    _tooltipEntry?.dispose();
    _tooltipEntry = null;

    // Persist the flag for future launches
    SharedPreferences.getInstance().then((prefs) {
      prefs.setBool('drawer_tooltip_shown', true);
    });
  }

  // ── Drawer tooltip content (gold, rounded, one-time) ─────────────────

  Widget _drawerTooltipContent() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.navyBlue,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.navyBlue.withValues(alpha: 0.35),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: const BoxDecoration(
              color: AppColors.gold,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            'Pro features inside! 👆',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  // ── Main build method ──────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
return Scaffold(
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
            color: isDark ? AppColors.softTealLight : AppColors.navyBlue,
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
                                ? AppColors.softTealLight
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
                    color: isDark ? AppColors.softTealLight : AppColors.navyBlue,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ── Refresh ────────────────────────────────────────────────────────

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
                          AppColors.navyBlue,
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
                  // App logo (reused from the drawer / home header)
                  const AppLogo(size: 56, isDark: false),
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
                  _DrawerMenuItem(
                    icon: Icons.self_improvement_rounded,
                    title: 'Calming Activities',
                    isDark: isDark,
                    onTap: () {
                      Navigator.of(context).pop();
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

  // ── Locked Pro teaser card ────────────────────────────────────────────

  Widget _buildProTeaserCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    // If the user is already Pro, hide these cards entirely
    // AsyncValue guards: valueOrNull is null while loading or on error.
    final bool isProEnabled = ref.watch(isProProvider).valueOrNull ?? false;
    if (isProEnabled) return const SizedBox.shrink();

    return ProTeaserCard(
      icon: icon,
      title: title,
      subtitle: subtitle,
      color: color,
      onTap: onTap,
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
          gradient: LinearGradient(
            colors: [AppColors.navyBlue, AppColors.softTeal],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: AppColors.navyBlue.withValues(alpha: 0.35),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(
            color: AppColors.navyBlue,
            width: 3,
          ),
          borderRadius: BorderRadius.circular(AppConstants.radiusFull),
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            const Center(
              child: Icon(
                Icons.smart_toy_rounded,
                size: 26,
                color: Colors.white,
              ),
            ),
            // Gold crown badge overlay on top-right
            Positioned(
              top: -4,
              right: -4,
              child: Container(
                width: 22,
                height: 22,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.gold,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white,
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.gold.withValues(alpha: 0.5),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Text(
                  '👑',
                  style: TextStyle(fontSize: 12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _onAIFabTap() async {
    final prefs = await SharedPreferences.getInstance();
    final isPro = prefs.getBool('is_pro') ?? false;

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

  // ── Body ──────────────────────────────────────────────────────────────

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

                  // ── Locked Pro teaser cards ─────────────────────────
                  _buildProTeaserCard(
                    icon: Icons.smart_toy_rounded,
                    title: 'AI Friend',
                    subtitle: '24/7 AI support during cravings',
                    color: AppColors.softTeal,
                    onTap: () => _navigateToPro(const AIChatScreen()),
                  ),
                  const SizedBox(height: AppConstants.spacingLg),

                  _buildProTeaserCard(
                    icon: Icons.psychology_rounded,
                    title: 'Memory Game',
                    subtitle: 'Beat cravings with a focus game',
                    color: AppColors.navyBlue,
                    onTap: () => _navigateToPro(const MemoryGameScreen()),
                  ),
                  const SizedBox(height: AppConstants.spacingLg),

                  _buildProTeaserCard(
                    icon: Icons.monitor_weight_rounded,
                    title: 'Weight Tracker',
                    subtitle: 'Track your body transformation',
                    color: AppColors.gold,
                    onTap: () => _navigateToPro(const WeightTrackerScreen()),
                  ),
                  const SizedBox(height: AppConstants.spacingLg),

                  // ── End Pro teaser cards ────────────────────────────

                  RepaintBoundary(
                    child: _AnimatedCardWrapper(
                      index: 8,
                      child: MoneySavedCard(
                        savingsService: ref.watch(savingsServiceProvider),
                        sobrietyService: ref.watch(sobrietyServiceProvider),
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
                      color: isDark
                          ? AppColors.navyBlue
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
