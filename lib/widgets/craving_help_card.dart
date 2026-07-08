import 'package:flutter/material.dart';
import 'package:quit_drinking/constants/app_colors.dart';
import 'package:quit_drinking/constants/app_constants.dart';
import 'package:quit_drinking/screens/ai_chat_screen.dart';
import 'package:quit_drinking/screens/craving/drink_water_screen.dart';
import 'package:quit_drinking/screens/craving/walk_screen.dart';
import 'package:quit_drinking/screens/craving/my_reasons_screen.dart';
import 'package:quit_drinking/screens/craving/breathing_screen.dart';
import 'package:quit_drinking/screens/craving/motivation_screen.dart';
import 'package:quit_drinking/screens/craving/journal_screen.dart';
import 'package:quit_drinking/widgets/sober_card.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Section 9 — Craving Help Card.
///
/// Features a large, calming "I'm Having a Craving" button that opens a
/// beautiful bottom sheet with 7 actionable steps, each with an icon.
class CravingHelpCard extends StatelessWidget {
  const CravingHelpCard({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SoberCard(
      color: isDark
          ? AppColors.softTeal.withValues(alpha: 0.06)
          : AppColors.mintLight,
      border: Border.all(
        color: isDark
            ? AppColors.softTeal.withValues(alpha: 0.15)
            : AppColors.softTeal.withValues(alpha: 0.2),
        width: 1.2,
      ),
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
                  color: AppColors.softTeal.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(AppConstants.radiusSm),
                ),
                child: const Icon(
                  Icons.healing_rounded,
                  size: 22,
                  color: AppColors.softTeal,
                ),
              ),
              const SizedBox(width: AppConstants.spacingSm),
              Expanded(
                child: Text(
                  'Craving Help',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    height: 1.3,
                    color: isDark ? AppColors.textOnDark : AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppConstants.spacingSm),
          Text(
            'Cravings are normal and they pass. Take a deep breath and try one of these calming activities.',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w400,
              height: 1.4,
              color: isDark ? AppColors.textOnDarkSecondary : AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppConstants.spacingLg),

          // Calming "I'm Having a Craving" Button
          SizedBox(
            width: double.infinity,
            child: _CalmCravingButton(
              onTap: () => _showCravingModal(context),
            ),
          ),
        ],
      ),
    );
  }

  void _showCravingModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.4),
      builder: (ctx) => _CravingActionSheet(),
    );
  }
}

// ── Calming Craving Button ──────────────────────────────────────────────

class _CalmCravingButton extends StatefulWidget {
  final VoidCallback onTap;

  const _CalmCravingButton({required this.onTap});

  @override
  State<_CalmCravingButton> createState() => _CalmCravingButtonState();
}

class _CalmCravingButtonState extends State<_CalmCravingButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 1.0, end: 1.04).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulseAnim,
      builder: (context, _) {
        return Transform.scale(
          scale: _pulseAnim.value,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: widget.onTap,
              borderRadius: BorderRadius.circular(AppConstants.radiusMd),
              splashColor: AppColors.softTeal.withValues(alpha: 0.15),
              highlightColor: AppColors.softTeal.withValues(alpha: 0.05),
              child: AnimatedContainer(
                duration: AppConstants.animationFast,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppConstants.spacingLg,
                  vertical: AppConstants.spacingLg,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.softTeal.withValues(alpha: 0.9),
                      AppColors.skyBlue.withValues(alpha: 0.8),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(AppConstants.radiusMd),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.softTeal.withValues(alpha: 0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 6),
                    ),
                    BoxShadow(
                      color: AppColors.skyBlue.withValues(alpha: 0.15),
                      blurRadius: 40,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Breathing circle icon
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withValues(alpha: 0.2),
                      ),
                      child: const Icon(
                        Icons.self_improvement_rounded,
                        size: 30,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: AppConstants.spacingSm),
                    const Text(
                      "I'm Having a Craving",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        letterSpacing: 0.3,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Tap for calming activities',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w400,
                        color: Colors.white.withValues(alpha: 0.85),
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

// ── Craving Action Bottom Sheet ─────────────────────────────────────────

class _CravingAction {
  final IconData icon;
  final String label;
  final String description;
  final Color color;

  const _CravingAction({
    required this.icon,
    required this.label,
    required this.description,
    required this.color,
  });
}

const _cravingActions = [
  _CravingAction(
    icon: Icons.water_drop_rounded,
    label: 'Drink Water',
    description: 'Hydrate yourself — thirst often feels like a craving',
    color: AppColors.skyBlue,
  ),
  _CravingAction(
    icon: Icons.directions_walk_rounded,
    label: 'Go for a Walk',
    description: 'Step outside, get fresh air, and clear your mind',
    color: AppColors.successGreen,
  ),
  _CravingAction(
    icon: Icons.list_alt_rounded,
    label: 'Read My Reasons',
    description: 'Remind yourself why you started this journey',
    color: AppColors.softTeal,
  ),
  _CravingAction(
    icon: Icons.air_rounded,
    label: 'Start Breathing Exercise',
    description: 'Take 5 deep breaths — in through your nose, out through your mouth',
    color: AppColors.softOrange,
  ),
  _CravingAction(
    icon: Icons.edit_note_rounded,
    label: 'Journal Your Feeling',
    description: 'Write down what you\'re feeling right now',
    color: AppColors.navyBlueLight,
  ),
  _CravingAction(
    icon: Icons.smart_toy_rounded,
    label: 'Talk to AI Friend',
    description: 'Chat with a supportive AI companion',
    color: AppColors.navyBlue,
  ),
  _CravingAction(
    icon: Icons.format_quote_rounded,
    label: 'Read Motivation',
    description: 'Read an inspiring quote to get you through this moment',
    color: AppColors.successGreenLight,
  ),
];

class _CravingActionSheet extends StatefulWidget {
  @override
  State<_CravingActionSheet> createState() => _CravingActionSheetState();
}

class _CravingActionSheetState extends State<_CravingActionSheet> {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      padding: EdgeInsets.only(bottom: bottomInset),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.white,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppConstants.radiusXl),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag Handle
          Padding(
            padding: const EdgeInsets.only(top: AppConstants.spacingSm),
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.textOnDarkSecondary.withValues(alpha: 0.3)
                    : AppColors.textTertiary.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppConstants.spacingLg,
              AppConstants.spacingLg,
              AppConstants.spacingLg,
              AppConstants.spacingMd,
            ),
            child: Column(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.softTeal.withValues(alpha: 0.15),
                  ),
                  child: const Icon(
                    Icons.self_improvement_rounded,
                    size: 26,
                    color: AppColors.softTeal,
                  ),
                ),
                const SizedBox(height: AppConstants.spacingSm),
                Text(
                  'You can do this',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    height: 1.2,
                    color: isDark ? AppColors.textOnDark : AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: AppConstants.spacingXxs),
                Text(
                  'Cravings last about 15-20 minutes. Choose an activity below:',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    height: 1.4,
                    color: isDark
                        ? AppColors.textOnDarkSecondary
                        : AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),

          // Action Items
          Flexible(
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ...List.generate(_cravingActions.length, (index) {
                    final action = _cravingActions[index];
                    final isLast = index == _cravingActions.length - 1;
                    return _CravingActionTile(
                      action: action,
                      isDark: isDark,
                      isLast: isLast,
                      index: index,
                    );
                  }),
                ],
              ),
            ),
          ),

          const SizedBox(height: AppConstants.spacingMd),
        ],
      ),
    );
  }
}

// ── Pro Upgrade Bottom Sheet ────────────────────────────────────────────

class _ProUpgradeSheet extends StatelessWidget {
  final bool isDark;
  final Future<void> Function() onUpgrade;

  const _ProUpgradeSheet({
    required this.isDark,
    required this.onUpgrade,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.white,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppConstants.radiusXl),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppConstants.spacingLg,
          AppConstants.spacingLg,
          AppConstants.spacingLg,
          AppConstants.spacingXxl,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag Handle
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.textOnDarkSecondary.withValues(alpha: 0.3)
                    : AppColors.textTertiary.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: AppConstants.spacingLg),

            // Pro icon
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.navyBlue.withValues(alpha: 0.12),
              ),
              child: const Icon(
                Icons.smart_toy_rounded,
                size: 36,
                color: AppColors.navyBlue,
              ),
            ),
            const SizedBox(height: AppConstants.spacingLg),

            // Title
            Text(
              'Pro Feature',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                height: 1.2,
                color: isDark ? AppColors.textOnDark : AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: AppConstants.spacingSm),

            // Description
            Text(
              'Talk to an AI Friend is a Pro feature.\nUpgrade to unlock AI-powered conversations\nto help you through your journey.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w400,
                height: 1.5,
                color: isDark
                    ? AppColors.textOnDarkSecondary
                    : AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: AppConstants.spacingXl),

            // Upgrade button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: onUpgrade,
                icon: const Icon(Icons.star_rounded, size: 20),
                label: const Text('Upgrade to Pro'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.navyBlue,
                  foregroundColor: AppColors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppConstants.radiusSm),
                  ),
                  padding: const EdgeInsets.symmetric(
                    vertical: AppConstants.spacingMd,
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppConstants.spacingSm),

            // Maybe later
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Maybe later',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
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
  }
}

// ── Action Tile with Staggered Animation ────────────────────────────────

class _CravingActionTile extends StatefulWidget {
  final _CravingAction action;
  final bool isDark;
  final bool isLast;
  final int index;

  const _CravingActionTile({
    required this.action,
    required this.isDark,
    required this.isLast,
    required this.index,
  });

  @override
  State<_CravingActionTile> createState() => _CravingActionTileState();
}

class _CravingActionTileState extends State<_CravingActionTile>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _fadeAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOut),
    );
    _slideAnim = Tween<Offset>(
      begin: const Offset(0.08, 0.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic));

    // Stagger animation by index
    Future.delayed(Duration(milliseconds: 50 * widget.index), () {
      if (mounted) _animController.forward();
    });
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
        child: Padding(
          padding: EdgeInsets.only(
            left: AppConstants.spacingMd,
            right: AppConstants.spacingMd,
            bottom: widget.isLast ? 0 : AppConstants.spacingXs,
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => _onActionTap(context),
              borderRadius: BorderRadius.circular(AppConstants.radiusSm),
              child: Container(
                padding: const EdgeInsets.all(AppConstants.spacingMd),
                decoration: BoxDecoration(
                  color: widget.action.color.withValues(
                    alpha: widget.isDark ? 0.1 : 0.07,
                  ),
                  borderRadius: BorderRadius.circular(AppConstants.radiusSm),
                  border: Border.all(
                    color: widget.action.color.withValues(
                      alpha: widget.isDark ? 0.15 : 0.1,
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    // Icon container
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: widget.action.color.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(AppConstants.radiusSm),
                      ),
                      child: Icon(
                        widget.action.icon,
                        size: 22,
                        color: widget.action.color,
                      ),
                    ),
                    const SizedBox(width: AppConstants.spacingSm),
                    // Label + description
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.action.label,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: widget.isDark
                                  ? AppColors.textOnDark
                                  : AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 1),
                          Text(
                            widget.action.description,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w400,
                              height: 1.3,
                              color: widget.isDark
                                  ? AppColors.textOnDarkSecondary
                                  : AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: AppConstants.spacingXs),
                    Icon(
                      Icons.chevron_right_rounded,
                      size: 20,
                      color: widget.action.color.withValues(alpha: 0.5),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _onActionTap(BuildContext context) {
    if (widget.index == 0) {
      // Dismiss the bottom sheet first, then navigate
      Navigator.of(context).pop();
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => const DrinkWaterScreen(),
        ),
      );
      return;
    }

    if (widget.index == 1) {
      // Dismiss the bottom sheet first, then navigate
      Navigator.of(context).pop();
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => const WalkScreen(),
        ),
      );
      return;
    }

    if (widget.index == 2) {
      // Dismiss the bottom sheet first, then navigate
      Navigator.of(context).pop();
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => const MyReasonsScreen(),
        ),
      );
      return;
    }

    if (widget.index == 3) {
      // Dismiss the bottom sheet first, then navigate
      Navigator.of(context).pop();
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => const BreathingScreen(),
        ),
      );
      return;
    }

    if (widget.index == 4) {
      // Dismiss the bottom sheet first, then navigate
      Navigator.of(context).pop();
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => const JournalScreen(),
        ),
      );
      return;
    }

    if (widget.index == 5) {
      // Check Pro status first (async), THEN dismiss sheet
      _handleAIFriend(context);
      return;
    }

    if (widget.index == 6) {
      // Dismiss the bottom sheet first, then navigate
      Navigator.of(context).pop();
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => const MotivationScreen(),
        ),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(widget.action.icon, size: 18, color: Colors.white),
            const SizedBox(width: AppConstants.spacingXs),
            Text('${widget.action.label} — great choice!'),
          ],
        ),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.radiusSm),
        ),
      ),
    );
  }

  Future<void> _handleAIFriend(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    final isPro = prefs.getBool('is_pro') ?? false;

    if (!context.mounted) return;

    // Pop the craving action sheet (synchronous — context still valid)
    Navigator.of(context).pop();

    if (isPro) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => const AIChatScreen(),
        ),
      );
    } else {
      _showProUpgradeSheet(context, prefs);
    }
  }

  void _showProUpgradeSheet(BuildContext context, SharedPreferences prefs) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.4),
      builder: (ctx) => _ProUpgradeSheet(
        isDark: isDark,
        onUpgrade: () async {
          // Fake payment confirmation dialog
          final confirmed = await showDialog<bool>(
            context: ctx,
            builder: (ctx2) => AlertDialog(
              backgroundColor: isDark ? AppColors.darkSurfaceAlt : AppColors.white,
              surfaceTintColor: Colors.transparent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppConstants.radiusLg),
              ),
              title: Text(
                'Confirm Upgrade',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: isDark ? AppColors.textOnDark : AppColors.textPrimary,
                ),
              ),
              content: Text(
                'Upgrade to Pro for \$4.99/month?\n\nIncludes:\n• AI Friend Chat\n• Premium features\n• Early access to new tools',
                style: TextStyle(
                  height: 1.5,
                  color: isDark ? AppColors.textOnDarkSecondary : AppColors.textSecondary,
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx2, false),
                  child: Text(
                    'Cancel',
                    style: TextStyle(
                      color: isDark ? AppColors.textOnDarkSecondary : AppColors.textSecondary,
                    ),
                  ),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pop(ctx2, true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.navyBlue,
                    foregroundColor: AppColors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppConstants.radiusSm),
                    ),
                  ),
                  child: const Text('Upgrade Now'),
                ),
              ],
            ),
          );

          if (confirmed == true) {
            await prefs.setBool('is_pro', true);
            if (ctx.mounted) {
              Navigator.of(ctx).pop(); // Close upgrade sheet
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const AIChatScreen(),
                ),
              );
            }
          }
        },
      ),
    );
  }
}