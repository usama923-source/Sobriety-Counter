import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quit_drinking/constants/app_colors.dart';
import 'package:quit_drinking/constants/app_constants.dart';
import 'package:quit_drinking/core/providers/theme_provider.dart';
import 'package:quit_drinking/screens/ai_chat_screen.dart';
import 'package:quit_drinking/screens/craving/breathing_screen.dart';
import 'package:quit_drinking/screens/craving/journal_screen.dart';
import 'package:quit_drinking/screens/craving/motivation_screen.dart';
import 'package:quit_drinking/screens/craving/my_reasons_screen.dart';
import 'package:quit_drinking/screens/craving/timed_activity_screen.dart';
import 'package:quit_drinking/widgets/pro_upgrade_sheet.dart';
import 'package:quit_drinking/widgets/sober_card.dart';

/// Craving Actions screen — a full page of 7 calming activities to help
/// users ride out a craving.
///
/// Replaces the old bottom sheet; opened from CravingHelpCard.
class CravingActionsScreen extends StatelessWidget {
  const CravingActionsScreen({super.key});

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
          'You Can Do This 💪',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: isDark ? AppColors.textOnDark : AppColors.textPrimary,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: AppConstants.spacingXxl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header ─────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppConstants.spacingMd,
                  AppConstants.spacingLg,
                  AppConstants.spacingMd,
                  AppConstants.spacingSm,
                ),
                child: Column(
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.brandPrimary.withValues(alpha: 0.15),
                      ),
                      child: const Icon(
                        Icons.self_improvement_rounded,
                        size: 28,
                        color: AppColors.brandPrimary,
                      ),
                    ),
                    const SizedBox(height: AppConstants.spacingSm),
                    Text(
                      'Cravings last 15-20 minutes. Choose an activity:',
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

              // ── Action Tiles ───────────────────────────────────────
              ...List.generate(_cravingActions.length, (index) {
                final action = _cravingActions[index];
                return _CravingActionTile(
                  action: action,
                  isDark: isDark,
                  index: index,
                );
              }),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Craving Action Model ────────────────────────────────────────────────

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
    color: AppColors.brandPrimary,
  ),
  _CravingAction(
    icon: Icons.directions_walk_rounded,
    label: 'Go for a Walk',
    description: 'Step outside, get fresh air, and clear your mind',
    color: AppColors.brandLightBlue,
  ),
  _CravingAction(
    icon: Icons.list_alt_rounded,
    label: 'Read My Reasons',
    description: 'Remind yourself why you started this journey',
    color: AppColors.brandPrimary,
  ),
  _CravingAction(
    icon: Icons.air_rounded,
    label: 'Start Breathing Exercise',
    description: 'Take 5 deep breaths — in through your nose, out through your mouth',
    color: AppColors.brandPrimary,
  ),
  _CravingAction(
    icon: Icons.edit_note_rounded,
    label: 'Journal Your Feeling',
    description: 'Write down what you\'re feeling right now',
    color: AppColors.brandPrimaryLight,
  ),
  _CravingAction(
    icon: Icons.smart_toy_rounded,
    label: 'Talk to AI Friend',
    description: 'Chat with a supportive AI companion',
    color: AppColors.brandPrimary,
  ),
  _CravingAction(
    icon: Icons.format_quote_rounded,
    label: 'Read Motivation',
    description: 'Read an inspiring quote to get you through this moment',
    color: AppColors.brandPrimaryLight,
  ),
];

// ── Action Tile with Staggered Animation ────────────────────────────────

class _CravingActionTile extends ConsumerWidget {
  final _CravingAction action;
  final bool isDark;
  final int index;

  const _CravingActionTile({
    required this.action,
    required this.isDark,
    required this.index,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return InkWell(
      onTap: () => _onActionTap(context, ref),
      borderRadius: BorderRadius.circular(AppConstants.radiusLg),
      splashColor: AppColors.brandPrimary.withValues(alpha: 0.12),
      highlightColor: AppColors.brandPrimary.withValues(alpha: 0.12),
      child: SoberCard(
        color: action.color.withValues(alpha: isDark ? 0.1 : 0.07),
        border: Border.all(
          color: action.color.withValues(alpha: isDark ? 0.15 : 0.1),
        ),
        hasShadow: false,
        enableHoverEffect: false,
        child: Row(
        children: [
          // Icon container
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: action.color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(AppConstants.radiusSm),
            ),
            child: Icon(
              action.icon,
              size: 22,
              color: action.color,
            ),
          ),
          const SizedBox(width: AppConstants.spacingSm),
          // Label + description
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  action.label,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: isDark ? AppColors.textOnDark : AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  action.description,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    height: 1.3,
                    color: isDark ? AppColors.textOnDarkSecondary : AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppConstants.spacingXs),
          Icon(
            Icons.chevron_right_rounded,
            size: 20,
            color: action.color.withValues(alpha: 0.5),
          ),
        ],
        ),
      ),
    );
  }

  void _onActionTap(BuildContext context, WidgetRef ref) {
    switch (index) {
      case 0:
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => const TimedActivityScreen(
              title: 'Drink Water',
              message: 'Drinking water reduces cravings.\nThirst often feels like a craving.',
              color: AppColors.brandPrimary,
              icon: Icons.water_drop_rounded,
              durationMinutes: 5,
            ),
          ),
        );
      case 1:
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => const TimedActivityScreen(
              title: 'Go for a Walk',
              message: 'A short walk can reduce cravings\nby up to 60%. Step outside!',
              color: AppColors.brandPrimary,
              icon: Icons.directions_walk_rounded,
              durationMinutes: 10,
            ),
          ),
        );
      case 2:
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const MyReasonsScreen()),
        );
      case 3:
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const BreathingScreen()),
        );
      case 4:
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const JournalScreen()),
        );
      case 5:
        // Check Pro status first (async), then navigate or show upgrade
        _handleAIFriend(context, ref);
      case 6:
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const MotivationScreen()),
        );
      default:
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(action.icon, size: 18, color: Colors.white),
                const SizedBox(width: AppConstants.spacingXs),
                Text('${action.label} — great choice!'),
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
  }

  Future<void> _handleAIFriend(BuildContext context, WidgetRef ref) async {
    // Reads through the Pro gate: while billing is off (kProEnabled = false)
    // this is always true, so AI Friend opens directly. The upgrade path below
    // stays in place for when billing is switched back on.
    final isPro = await ref.read(isProProvider.future);

    if (!context.mounted) return;

    if (isPro) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => const AIChatScreen(),
        ),
      );
      return;
    }

    final upgraded = await ProUpgradeSheet.show(context);
    if (upgraded && context.mounted) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => const AIChatScreen(),
        ),
      );
    }
  }
}

