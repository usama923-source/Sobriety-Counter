import 'package:flutter/material.dart';
import 'package:quit_drinking/constants/app_colors.dart';
import 'package:quit_drinking/constants/app_constants.dart';
import 'package:quit_drinking/widgets/confetti_celebration.dart';
import 'package:quit_drinking/widgets/sober_card.dart';

class RecoveryTimelineCard extends StatefulWidget {
  final int currentDays;

  const RecoveryTimelineCard({super.key, required this.currentDays});

  @override
  State<RecoveryTimelineCard> createState() => _RecoveryTimelineCardState();
}

class _RecoveryTimelineCardState extends State<RecoveryTimelineCard> {
  late int _previousDays;

  @override
  void initState() {
    super.initState();
    _previousDays = widget.currentDays;
  }

  @override
  void didUpdateWidget(RecoveryTimelineCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    _previousDays = oldWidget.currentDays;
  }

  int get _completedCount =>
      _milestones.where((m) => m.isCompleted(widget.currentDays)).length;

  int get _totalCount => _milestones.length;

  double get _overallProgress => _completedCount / _totalCount;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final allAchieved = _completedCount == _totalCount;

    return ConfettiOverlay(
      show: allAchieved && _completedCount > 0,
      particleCount: 50,
      duration: const Duration(seconds: 4),
      child: SoberCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.successGreen.withValues(alpha: 0.2)
                      : AppColors.successGreen.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(AppConstants.radiusSm),
                ),
                child: const Icon(
                  Icons.emoji_events_rounded,
                  size: 22,
                  color: AppColors.successGreen,
                ),
              ),
              const SizedBox(width: AppConstants.spacingSm),
              Expanded(
                child: Text(
                  'Recovery Timeline',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    height: 1.3,
                    color: isDark ? AppColors.textOnDark : AppColors.textPrimary,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppConstants.spacingXs,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.successGreen.withValues(alpha: 0.15)
                      : AppColors.successGreen.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppConstants.radiusFull),
                ),
                child: Text(
                  '$_completedCount/$_totalCount',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.successGreen,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: AppConstants.spacingLg),

          // Overall progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: _overallProgress),
              duration: AppConstants.animationSlow,
              curve: Curves.easeOutCubic,
              builder: (context, value, _) {
                return LinearProgressIndicator(
                  value: value,
                  backgroundColor:
                      isDark ? AppColors.darkCardAlt : AppColors.lightGrayAlt,
                  valueColor:
                      const AlwaysStoppedAnimation<Color>(AppColors.successGreen),
                  minHeight: 8,
                );
              },
            ),
          ),
          const SizedBox(height: AppConstants.spacingXxs),
          Text(
            _completedCount == _totalCount
                ? 'All milestones achieved!'
                : 'Day ${widget.currentDays} - $_completedCount of $_totalCount milestones',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: isDark ? AppColors.textOnDarkSecondary : AppColors.textSecondary,
            ),
          ),

          const SizedBox(height: AppConstants.spacingMd),

          // Milestone List
          ...List.generate(_milestones.length, (index) {
            final milestone = _milestones[index];
            final isReached = milestone.isCompleted(widget.currentDays);
            final isLast = index == _milestones.length - 1;

            return _MilestoneTile(
              milestone: milestone,
              isReached: isReached,
              isLast: isLast,
              isDark: isDark,
              isNewlyReached:
                  isReached && !milestone.isCompleted(_previousDays),
            );
          }),
        ],
      ),
      ),
    );
  }
}

class _Milestone {
  final int dayThreshold;
  final String title;
  final String subtitle;
  final IconData icon;

  const _Milestone({
    required this.dayThreshold,
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  bool isCompleted(int currentDays) => currentDays >= dayThreshold;
}

const _milestones = [
  _Milestone(
    dayThreshold: 1,
    title: '24 Hours',
    subtitle:
        'Your body begins to detoxify. Blood pressure and heart rate start to normalize.',
    icon: Icons.wb_twilight_rounded,
  ),
  _Milestone(
    dayThreshold: 2,
    title: '48 Hours',
    subtitle:
        'Carbon monoxide leaves your body. Oxygen levels in your blood rise.',
    icon: Icons.air_rounded,
  ),
  _Milestone(
    dayThreshold: 3,
    title: '72 Hours',
    subtitle:
        'Nicotine is fully eliminated. Taste and smell begin to sharpen.',
    icon: Icons.spa_outlined,
  ),
  _Milestone(
    dayThreshold: 7,
    title: '1 Week',
    subtitle:
        'Lung function improves. Breathing feels easier, especially during activity.',
    icon: Icons.directions_run_rounded,
  ),
  _Milestone(
    dayThreshold: 14,
    title: '2 Weeks',
    subtitle:
        'Circulation improves significantly. Walking and exercise feel easier.',
    icon: Icons.favorite_rounded,
  ),
  _Milestone(
    dayThreshold: 30,
    title: '1 Month',
    subtitle:
        'Energy spikes, skin looks healthier, and your immune system strengthens.',
    icon: Icons.battery_charging_full_rounded,
  ),
  _Milestone(
    dayThreshold: 90,
    title: '3 Months',
    subtitle:
        'Lungs have healed significantly. Coughing and shortness of breath diminish.',
    icon: Icons.air_rounded,
  ),
  _Milestone(
    dayThreshold: 180,
    title: '6 Months',
    subtitle:
        'Risk of heart disease drops by 50%. Lungs continue to heal and strengthen.',
    icon: Icons.monitor_heart_rounded,
  ),
  _Milestone(
    dayThreshold: 365,
    title: '1 Year',
    subtitle:
        'Risk of heart attack drops dramatically. Celebrate a full year of recovery!',
    icon: Icons.celebration_rounded,
  ),
];

class _MilestoneTile extends StatefulWidget {
  final _Milestone milestone;
  final bool isReached;
  final bool isLast;
  final bool isDark;
  final bool isNewlyReached;

  const _MilestoneTile({
    required this.milestone,
    required this.isReached,
    required this.isLast,
    required this.isDark,
    this.isNewlyReached = false,
  });

  @override
  State<_MilestoneTile> createState() => _MilestoneTileState();
}

class _MilestoneTileState extends State<_MilestoneTile>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: AppConstants.animationSlow,
    );
    _fadeAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOut),
    );
    _slideAnim = Tween<Offset>(
      begin: const Offset(-0.08, 0.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic));

    if (widget.isReached) {
      _animController.value = 1.0;
    } else {
      _animController.forward();
    }
  }

  @override
  void didUpdateWidget(_MilestoneTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isReached && !oldWidget.isReached) {
      _animController.forward(from: 0.0);
    } else if (widget.isReached) {
      _animController.value = 1.0;
    }
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnim,
      child: SlideTransition(
        position: _slideAnim,
        child: IntrinsicHeight(
          child: Padding(
            padding: EdgeInsets.only(
              bottom: widget.isLast ? 0 : AppConstants.spacingSm,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Timeline connector
                SizedBox(
                  width: 28,
                  child: Column(
                    children: [
                      AnimatedContainer(
                        duration: AppConstants.animationMed,
                        width: widget.isReached ? 16 : 10,
                        height: widget.isReached ? 16 : 10,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: widget.isReached
                              ? AppColors.successGreen
                              : (widget.isDark
                                  ? AppColors.darkCardAlt
                                  : AppColors.lightGrayAlt),
                          border: widget.isReached
                              ? Border.all(
                                  color: AppColors.successGreen, width: 2.5)
                              : Border.all(
                                  color: widget.isDark
                                      ? AppColors.textOnDarkSecondary
                                          .withValues(alpha: 0.25)
                                      : AppColors.textTertiary
                                          .withValues(alpha: 0.25),
                                  width: 1.5,
                                ),
                        ),
                        child: widget.isReached
                            ? const Icon(Icons.check,
                                size: 10, color: Colors.white)
                            : null,
                      ),
                      if (!widget.isLast)
                        Expanded(
                          child: Container(
                            width: 2,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: widget.isReached
                                    ? [
                                        AppColors.successGreen
                                            .withValues(alpha: 0.6),
                                        AppColors.successGreen
                                            .withValues(alpha: 0.15),
                                      ]
                                    : [
                                        widget.isDark
                                            ? AppColors.darkCardAlt
                                            : AppColors.lightGrayAlt,
                                        widget.isDark
                                            ? AppColors.darkCardAlt
                                                .withValues(alpha: 0.4)
                                            : AppColors.lightGrayAlt
                                                .withValues(alpha: 0.4),
                                      ],
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: AppConstants.spacingSm),

                // Content
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(
                      bottom: widget.isLast ? 0 : AppConstants.spacingXs,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Title row with icon
                        Row(
                          children: [
                            Icon(
                              widget.milestone.icon,
                              size: 16,
                              color: widget.isReached
                                  ? AppColors.successGreen
                                  : (widget.isDark
                                      ? AppColors.textOnDarkSecondary
                                          .withValues(alpha: 0.5)
                                      : AppColors.textTertiary),
                            ),
                            const SizedBox(width: AppConstants.spacingXs),
                            Text(
                              widget.milestone.title,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: widget.isReached
                                    ? (widget.isDark
                                        ? AppColors.textOnDark
                                        : AppColors.textPrimary)
                                    : (widget.isDark
                                        ? AppColors.textOnDarkSecondary
                                            .withValues(alpha: 0.6)
                                        : AppColors.textTertiary),
                              ),
                            ),
                            const Spacer(),
                            // Status badge
                            AnimatedContainer(
                              duration: AppConstants.animationMed,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: widget.isReached
                                    ? AppColors.successGreen
                                        .withValues(alpha: 0.15)
                                    : (widget.isDark
                                        ? AppColors.darkCardAlt
                                        : AppColors.lightGrayAlt),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                widget.isReached
                                    ? 'Done'
                                    : 'Day ${widget.milestone.dayThreshold}',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: widget.isReached
                                      ? AppColors.successGreen
                                      : (widget.isDark
                                          ? AppColors.textOnDarkSecondary
                                          : AppColors.textTertiary),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          widget.milestone.subtitle,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w400,
                            height: 1.4,
                            color: widget.isReached
                                ? (widget.isDark
                                    ? AppColors.textOnDarkSecondary
                                    : AppColors.textSecondary)
                                : (widget.isDark
                                    ? AppColors.textOnDarkSecondary
                                        .withValues(alpha: 0.4)
                                    : AppColors.textTertiary
                                        .withValues(alpha: 0.6)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
