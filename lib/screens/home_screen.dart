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
import 'package:quit_drinking/widgets/daily_motivation_card.dart';
import 'package:quit_drinking/widgets/my_reasons_card.dart';
import 'package:quit_drinking/widgets/money_saved_card.dart';
import 'package:quit_drinking/widgets/breath_challenge_card.dart';
import 'package:quit_drinking/widgets/guided_breathing_card.dart';
import 'package:quit_drinking/widgets/recovery_timeline_card.dart';
import 'package:quit_drinking/widgets/craving_help_card.dart';
import 'package:quit_drinking/widgets/daily_checkin_card.dart';
import 'package:quit_drinking/widgets/home_footer.dart';

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
          onPressed: null,
          icon: Icon(
            Icons.tune_rounded,
            color: isDark ? AppColors.textOnDark : AppColors.textSecondary,
          ),
          tooltip: 'Settings',
        ),
        const SizedBox(width: AppConstants.spacingXs),
      ],
    );
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
                      child: DailyMotivationCard(
                        service: ref.watch(quotesServiceProvider),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppConstants.spacingLg),

                  RepaintBoundary(
                    child: _AnimatedCardWrapper(
                      index: 4,
                      child: MyReasonsCard(
                        service: ref.watch(reasonsServiceProvider),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppConstants.spacingLg),

                  RepaintBoundary(
                    child: _AnimatedCardWrapper(
                      index: 5,
                      child: MoneySavedCard(
                        savingsService: ref.watch(savingsServiceProvider),
                        sobrietyService: ref.watch(sobrietyServiceProvider),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppConstants.spacingLg),

                  RepaintBoundary(
                    child: _AnimatedCardWrapper(
                      index: 6,
                      child: BreathChallengeCard(
                        service: ref.watch(breathingServiceProvider),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppConstants.spacingLg),

                  RepaintBoundary(
                    child: _AnimatedCardWrapper(
                      index: 7,
                      child: const GuidedBreathingCard(),
                    ),
                  ),
                  const SizedBox(height: AppConstants.spacingLg),

                  RepaintBoundary(
                    child: _AnimatedCardWrapper(
                      index: 8,
                      child: RecoveryTimelineCard(currentDays: milestoneDays),
                    ),
                  ),
                  const SizedBox(height: AppConstants.spacingLg),

                  RepaintBoundary(
                    child: _AnimatedCardWrapper(
                      index: 9,
                      child: const CravingHelpCard(),
                    ),
                  ),
                  const SizedBox(height: AppConstants.spacingLg),

                  RepaintBoundary(
                    child: _AnimatedCardWrapper(
                      index: 10,
                      child: DailyCheckinCard(
                        service: ref.watch(checkinServiceProvider),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppConstants.spacingLg),

                  RepaintBoundary(
                    child: _AnimatedCardWrapper(
                      index: 11,
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
