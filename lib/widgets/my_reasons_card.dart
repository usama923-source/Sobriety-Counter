import 'package:flutter/material.dart';
import 'package:quit_drinking/constants/app_colors.dart';
import 'package:quit_drinking/constants/app_constants.dart';
import 'package:quit_drinking/services/reasons_service.dart';
import 'package:quit_drinking/widgets/sober_card.dart';

/// Section 4 — My Reasons Card.
///
/// Full CRUD for personal reasons: add, edit, delete with smooth animations.
/// Shows an empty state when there are no reasons.
class MyReasonsCard extends StatelessWidget {
  final ReasonsService service;

  const MyReasonsCard({super.key, required this.service});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SoberCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ──────────────────────────────────────────────────
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.softRed.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(AppConstants.radiusSm),
                ),
                child: const Icon(
                  Icons.favorite_rounded,
                  size: 20,
                  color: AppColors.softRed,
                ),
              ),
              const SizedBox(width: AppConstants.spacingSm),
              Expanded(
                child: Text(
                  'My Reasons',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: isDark ? AppColors.textOnDark : AppColors.textPrimary,
                  ),
                ),
              ),
              Text(
                '${service.length}',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: isDark ? AppColors.textOnDarkSecondary : AppColors.textTertiary,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppConstants.spacingLg),

          // ── Content ─────────────────────────────────────────────────
          if (service.isEmpty)
            _EmptyState(isDark: isDark)
          else
            _ReasonsList(service: service, isDark: isDark),

          const SizedBox(height: AppConstants.spacingMd),

          // ── Add Button ──────────────────────────────────────────────
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _showAddDialog(context),
              icon: const Icon(Icons.add_rounded, size: 20),
              label: const Text('Add a reason'),
              style: OutlinedButton.styleFrom(
                foregroundColor: isDark ? AppColors.skyBlueLight : AppColors.navyBlue,
                side: BorderSide(
                  color: isDark
                      ? AppColors.skyBlueLight.withValues(alpha: 0.4)
                      : AppColors.navyBlue.withValues(alpha: 0.3),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppConstants.radiusSm),
                ),
                padding: const EdgeInsets.symmetric(vertical: AppConstants.spacingSm),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Dialogs ────────────────────────────────────────────────────────

  void _showAddDialog(BuildContext context) {
    _showReasonDialog(
      context: context,
      title: 'Add a Reason',
      hint: 'Why do you want to stay sober?',
      onSave: (text) => service.add(text),
    );
  }

  void _showReasonDialog({
    required BuildContext context,
    required String title,
    required String hint,
    String? initialText,
    required Future<void> Function(String) onSave,
  }) async {
    final controller = TextEditingController(text: initialText);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? AppColors.darkSurfaceAlt : AppColors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.radiusLg),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: isDark ? AppColors.textOnDark : AppColors.textPrimary,
          ),
        ),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLines: 3,
          minLines: 1,
          decoration: InputDecoration(
            hintText: hint,
            filled: true,
            fillColor: isDark ? AppColors.darkCardAlt : AppColors.lightGray,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppConstants.radiusSm),
              borderSide: BorderSide.none,
            ),
          ),
          style: TextStyle(
            color: isDark ? AppColors.textOnDark : AppColors.textPrimary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Cancel',
              style: TextStyle(
                color: isDark ? AppColors.textOnDarkSecondary : AppColors.textSecondary,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              final text = controller.text.trim();
              if (text.isNotEmpty) {
                onSave(text);
                Navigator.pop(ctx);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: isDark ? AppColors.skyBlueLight : AppColors.navyBlue,
              foregroundColor: isDark ? AppColors.navyBlueDark : AppColors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppConstants.radiusSm),
              ),
            ),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    controller.dispose();
  }
}

// ── Empty State ─────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final bool isDark;
  const _EmptyState({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppConstants.spacingMd),
      child: Column(
        children: [
          Icon(
            Icons.favorite_border_rounded,
            size: 48,
            color: isDark
                ? AppColors.textOnDarkSecondary.withValues(alpha: 0.3)
                : AppColors.textTertiary.withValues(alpha: 0.4),
          ),
          const SizedBox(height: AppConstants.spacingSm),
          Text(
            'No reasons yet',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: isDark ? AppColors.textOnDark : AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: AppConstants.spacingXxs),
          Text(
            'Add your personal reasons for staying sober.\nWhat matters most to you?',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w400,
              height: 1.5,
              color: isDark ? AppColors.textOnDarkSecondary : AppColors.textTertiary,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Reasons List ────────────────────────────────────────────────────────

class _ReasonsList extends StatelessWidget {
  final ReasonsService service;
  final bool isDark;

  const _ReasonsList({required this.service, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: service.length,
      itemBuilder: (context, index) {
        final reason = service.reasons[index];
        return _ReasonChip(
          key: ValueKey('reason_$index'),
          reason: reason,
          index: index,
          isDark: isDark,
          onDelete: () => _confirmDelete(context, index, reason),
          service: service,
        );
      },
    );
  }

  void _confirmDelete(BuildContext context, int index, String reason) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? AppColors.darkSurfaceAlt : AppColors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.radiusLg),
        ),
        title: Text(
          'Remove Reason',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: isDark ? AppColors.textOnDark : AppColors.textPrimary,
          ),
        ),
        content: Text(
          'Are you sure you want to remove this reason?',
          style: TextStyle(
            color: isDark ? AppColors.textOnDarkSecondary : AppColors.textSecondary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Cancel',
              style: TextStyle(
                color: isDark ? AppColors.textOnDarkSecondary : AppColors.textSecondary,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              service.delete(index);
              Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.softRed,
              foregroundColor: AppColors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppConstants.radiusSm),
              ),
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

// ── Single Reason Chip ───────────────────────────────────────────────────

class _ReasonChip extends StatelessWidget {
  final String reason;
  final int index;
  final bool isDark;
  final VoidCallback onDelete;
  final ReasonsService service;

  const _ReasonChip({
    super.key,
    required this.reason,
    required this.index,
    required this.isDark,
    required this.onDelete,
    required this.service,
  });

  void _edit(BuildContext context) async {
    final controller = TextEditingController(text: reason);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? AppColors.darkSurfaceAlt : AppColors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.radiusLg),
        ),
        title: Text(
          'Edit Reason',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: isDark ? AppColors.textOnDark : AppColors.textPrimary,
          ),
        ),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLines: 3,
          decoration: InputDecoration(
            filled: true,
            fillColor: isDark ? AppColors.darkCardAlt : AppColors.lightGray,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppConstants.radiusSm),
              borderSide: BorderSide.none,
            ),
          ),
          style: TextStyle(
            color: isDark ? AppColors.textOnDark : AppColors.textPrimary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Cancel',
              style: TextStyle(
                color: isDark ? AppColors.textOnDarkSecondary : AppColors.textSecondary,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              final text = controller.text.trim();
              if (text.isNotEmpty) {
                service.update(index, text);
                Navigator.pop(ctx);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: isDark ? AppColors.skyBlueLight : AppColors.navyBlue,
              foregroundColor: isDark ? AppColors.navyBlueDark : AppColors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppConstants.radiusSm),
              ),
            ),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    controller.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSize(
      duration: AppConstants.animationMed,
      curve: Curves.easeInOut,
      child: Padding(
        padding: const EdgeInsets.only(bottom: AppConstants.spacingXs),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppConstants.spacingMd,
            vertical: AppConstants.spacingSm,
          ),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkCardAlt : AppColors.lightGray,
            borderRadius: BorderRadius.circular(AppConstants.radiusSm),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Bullet
              Container(
                margin: const EdgeInsets.only(top: 6),
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: isDark ? AppColors.skyBlueLight : AppColors.navyBlue,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: AppConstants.spacingSm),

              // Reason text
              Expanded(
                child: Text(
                  reason,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    height: 1.4,
                    color: isDark ? AppColors.textOnDark : AppColors.textPrimary,
                  ),
                ),
              ),

              // Edit button
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => _edit(context),
                  borderRadius: BorderRadius.circular(6),
                  child: Padding(
                    padding: const EdgeInsets.all(6),
                    child: Icon(
                      Icons.edit_rounded,
                      size: 18,
                      color: isDark ? AppColors.skyBlue : AppColors.navyBlue,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 2),

              // Delete button
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: onDelete,
                  borderRadius: BorderRadius.circular(6),
                  child: Padding(
                    padding: const EdgeInsets.all(6),
                    child: Icon(
                      Icons.delete_outline_rounded,
                      size: 18,
                      color: AppColors.softRed,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
