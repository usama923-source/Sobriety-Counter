import 'package:flutter/material.dart';

import 'package:quit_drinking/constants/app_colors.dart';
import 'package:quit_drinking/constants/app_constants.dart';
import 'package:quit_drinking/screens/craving/drink_water_screen.dart';
import 'package:quit_drinking/screens/craving/walk_screen.dart';
import 'package:quit_drinking/screens/craving/my_reasons_screen.dart';
import 'package:quit_drinking/screens/craving/breathing_screen.dart';
import 'package:quit_drinking/screens/craving/motivation_screen.dart';
import 'package:quit_drinking/screens/craving/journal_screen.dart';
import 'package:quit_drinking/screens/ai_chat_screen.dart';
import 'package:quit_drinking/services/reasons_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Full-screen page for calming activities to help with cravings.
///
/// Replaces the previous bottom sheet with a dedicated screen that shows
/// 7 actionable steps, each with an icon, description, and navigation.
class CalmingActivitiesScreen extends StatefulWidget {
  final ReasonsService? reasonsService;

  const CalmingActivitiesScreen({super.key, this.reasonsService});

  @override
  State<CalmingActivitiesScreen> createState() =>
      _CalmingActivitiesScreenState();
}

// ── Action Data ─────────────────────────────────────────────────────────

class _CravingAction {
  final IconData icon;
  final String label;
  final String description;
  final Color color;
  final bool isPro;

  const _CravingAction({
    required this.icon,
    required this.label,
    required this.description,
    required this.color,
    this.isPro = false,
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
    isPro: true,
  ),
  _CravingAction(
    icon: Icons.format_quote_rounded,
    label: 'Read Motivation',
    description: 'Read an inspiring quote to get you through this moment',
    color: AppColors.successGreenLight,
  ),
];

class _CalmingActivitiesScreenState extends State<CalmingActivitiesScreen> {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkSurface : AppColors.lightGray,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_rounded,
            color: isDark ? AppColors.textOnDark : AppColors.textPrimary,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Calming Activities',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: isDark ? AppColors.textOnDark : AppColors.textPrimary,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // ── Action Items ─────────────────────────────────────────────
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(
                  AppConstants.spacingMd,
                  AppConstants.spacingMd,
                  AppConstants.spacingMd,
                  AppConstants.spacingXxl,
                ),
                itemCount: _cravingActions.length,
                itemBuilder: (context, index) {
                  final action = _cravingActions[index];
                  return _ActivityTile(
                    action: action,
                    isDark: isDark,
                    index: index,
                    reasonsService: widget.reasonsService,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Activity Tile ───────────────────────────────────────────────────────

class _ActivityTile extends StatefulWidget {
  final _CravingAction action;
  final bool isDark;
  final int index;
  final ReasonsService? reasonsService;

  const _ActivityTile({
    required this.action,
    required this.isDark,
    required this.index,
    this.reasonsService,
  });

  @override
  State<_ActivityTile> createState() => _ActivityTileState();
}

class _ActivityTileState extends State<_ActivityTile>
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
    ).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic),
    );

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
            bottom: widget.index < _cravingActions.length - 1
                ? AppConstants.spacingSm
                : 0,
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
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: widget.action.color.withValues(alpha: 0.15),
                        borderRadius:
                            BorderRadius.circular(AppConstants.radiusSm),
                      ),
                      child: Icon(
                        widget.action.icon,
                        size: 24,
                        color: widget.action.color,
                      ),
                    ),
                    const SizedBox(width: AppConstants.spacingMd),
                    // Label + description
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  widget.action.label,
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: widget.isDark
                                        ? AppColors.textOnDark
                                        : AppColors.textPrimary,
                                  ),
                                ),
                              ),
                              if (widget.action.isPro)
                                Padding(
                                  padding: const EdgeInsets.only(left: 6),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 3,
                                    ),
                                    decoration: BoxDecoration(
                                      gradient: const LinearGradient(
                                        colors: [AppColors.gold, AppColors.goldDark],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Text(
                                          '🔒',
                                          style: TextStyle(fontSize: 10),
                                        ),
                                        const SizedBox(width: 2),
                                        Text(
                                          'Pro',
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w800,
                                            color: widget.isDark
                                                ? AppColors.navyBlueDark
                                                : AppColors.white,
                                            letterSpacing: 0.3,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            widget.action.description,
                            style: TextStyle(
                              fontSize: 13,
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
                      size: 22,
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
    switch (widget.index) {
      case 0:
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => const DrinkWaterScreen(),
          ),
        );
        break;
      case 1:
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => const WalkScreen(),
          ),
        );
        break;
      case 2:
        final service = widget.reasonsService;
        if (service != null) {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => MyReasonsScreen(service: service),
            ),
          );
        }
        break;
      case 3:
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => const BreathingScreen(),
          ),
        );
        break;
      case 4:
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => const JournalScreen(),
          ),
        );
        break;
      case 5:
        _handleAIFriend(context);
        break;
      case 6:
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => const MotivationScreen(),
          ),
        );
        break;
    }
  }

  Future<void> _handleAIFriend(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    final isPro = prefs.getBool('is_pro') ?? false;

    if (!context.mounted) return;

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
      builder: (ctx) => _ProPromptSheet(
        isDark: isDark,
        onUpgrade: () async {
          final confirmed = await showDialog<bool>(
            context: ctx,
            builder: (ctx2) => AlertDialog(
              backgroundColor:
                  isDark ? AppColors.darkSurfaceAlt : AppColors.white,
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
                  color: isDark
                      ? AppColors.textOnDarkSecondary
                      : AppColors.textSecondary,
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx2, false),
                  child: Text(
                    'Cancel',
                    style: TextStyle(
                      color: isDark
                          ? AppColors.textOnDarkSecondary
                          : AppColors.textSecondary,
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

// ── Pro Upgrade Prompt (kept minimal, shown as bottom sheet) ───────────

class _ProPromptSheet extends StatelessWidget {
  final bool isDark;
  final Future<void> Function() onUpgrade;

  const _ProPromptSheet({
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
