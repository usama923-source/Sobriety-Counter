import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quit_drinking/constants/app_colors.dart';
import 'package:quit_drinking/constants/app_constants.dart';
import 'package:quit_drinking/core/providers/reasons_provider.dart';
import 'package:quit_drinking/services/reasons_service.dart';
import 'package:quit_drinking/widgets/sober_card.dart';

/// My Reasons screen — full CRUD for personal sobriety reasons.
///
/// Uses the shared [ReasonsService] (persisted under key "my_reasons" as a
/// JSON-encoded list of strings) so it stays in sync with the home card.
class MyReasonsScreen extends ConsumerStatefulWidget {
  const MyReasonsScreen({super.key});

  @override
  ConsumerState<MyReasonsScreen> createState() => _MyReasonsScreenState();
}

class _MyReasonsScreenState extends ConsumerState<MyReasonsScreen> {
  Future<void> _addReason(String reason) async {
    final trimmed = reason.trim();
    if (trimmed.isEmpty) return;
    await ref.read(reasonsServiceProvider).add(trimmed);
  }

  Future<void> _updateReason(int index, String reason) async {
    final trimmed = reason.trim();
    if (trimmed.isEmpty) return;
    await ref.read(reasonsServiceProvider).update(index, trimmed);
  }

  Future<void> _deleteReason(int index) async {
    await ref.read(reasonsServiceProvider).delete(index);
    HapticFeedback.mediumImpact();
  }

  void _showAddDialog() => _showReasonDialog();

  void _showEditDialog(int index, String currentReason) =>
      _showReasonDialog(index: index, initialText: currentReason);

  void _showReasonDialog({int? index, String? initialText}) {
    // Keep the entered value in a local instead of a TextEditingController:
    // the controller would have to outlive the dialog's close animation.
    var text = initialText ?? '';
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isEditing = index != null;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? AppColors.darkSurfaceAlt : AppColors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.radiusLg),
        ),
        title: Text(
          isEditing ? 'Edit Reason' : 'Add a Reason',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: isDark ? AppColors.textOnDark : AppColors.textPrimary,
          ),
        ),
        content: TextFormField(
          initialValue: initialText,
          autofocus: true,
          maxLines: 3,
          minLines: 1,
          onChanged: (value) => text = value,
          decoration: InputDecoration(
            hintText: 'Why do you want to stay sober?',
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
              final entered = text.trim();
              if (entered.isNotEmpty) {
                if (isEditing) {
                  _updateReason(index, entered);
                } else {
                  _addReason(entered);
                }
                Navigator.pop(ctx);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: context.primary,
              foregroundColor: context.onPrimary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppConstants.radiusSm),
              ),
            ),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final service = ref.watch(reasonsServiceProvider);
    final reasons = service.reasons;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkSurface : AppColors.lightGray,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_rounded,
            color: isDark ? AppColors.textOnDark : AppColors.textPrimary,
          ),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: Text(
          'My Reasons',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: isDark ? AppColors.textOnDark : AppColors.textPrimary,
          ),
        ),
        centerTitle: true,
      ),
      body: !service.initialized
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppConstants.spacingMd,
                  vertical: AppConstants.spacingLg,
                ),
                child: Column(
                  children: [
                    // ── Reasons List ──────────────────────────────────────
                    Expanded(
                      child: reasons.isEmpty
                          ? _EmptyReasonsState(isDark: isDark)
                          : ListView.builder(
                              itemCount: reasons.length,
                              itemBuilder: (context, index) {
                                return _ReasonTile(
                                  reason: reasons[index],
                                  index: index,
                                  isDark: isDark,
                                  onEdit: () => _showEditDialog(
                                    index,
                                    reasons[index],
                                  ),
                                  onDelete: () => _confirmDelete(context, index),
                                );
                              },
                            ),
                    ),

                    const SizedBox(height: AppConstants.spacingMd),

                    // ── Add Button ────────────────────────────────────────
                    SizedBox(
                      width: double.infinity,
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: _showAddDialog,
                          borderRadius: BorderRadius.circular(
                            AppConstants.radiusFull,
                          ),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              vertical: AppConstants.spacingMd,
                            ),
                            decoration: BoxDecoration(
                              color: context.primary,
                              borderRadius: BorderRadius.circular(
                                AppConstants.radiusFull,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: context.primary.withValues(alpha: 0.3),
                                  blurRadius: 16,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.add_rounded,
                                  size: 20,
                                  color: context.onPrimary,
                                ),
                                const SizedBox(width: AppConstants.spacingXs),
                                Text(
                                  'Add a reason',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: context.onPrimary,
                                    letterSpacing: 0.3,
                                  ),
                                ),
                              ],
                            ),
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

  void _confirmDelete(BuildContext context, int index) {
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
              _deleteReason(index);
              Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.softRed,
              foregroundColor: Colors.white,
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

// ── Empty State ────────────────────────────────────────────────────────

class _EmptyReasonsState extends StatelessWidget {
  final bool isDark;

  const _EmptyReasonsState({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.brandPrimary.withValues(alpha: isDark ? 0.12 : 0.08),
            ),
            child: Icon(
              Icons.favorite_border_rounded,
              size: 40,
              color: isDark
                  ? AppColors.textOnDarkSecondary.withValues(alpha: 0.5)
                  : AppColors.textTertiary,
            ),
          ),
          const SizedBox(height: AppConstants.spacingLg),
          Text(
            'No reasons yet',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: isDark ? AppColors.textOnDark : AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: AppConstants.spacingXs),
          Text(
            'Add your reasons for staying sober',
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
    );
  }
}

// ── Reason Tile ────────────────────────────────────────────────────────

class _ReasonTile extends StatelessWidget {
  final String reason;
  final int index;
  final bool isDark;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _ReasonTile({
    required this.reason,
    required this.index,
    required this.isDark,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppConstants.spacingXs),
      child: SoberCard(
        padding: const EdgeInsets.symmetric(
          horizontal: AppConstants.spacingMd,
          vertical: AppConstants.spacingMd,
        ),
        color: isDark ? AppColors.darkCardAlt.withValues(alpha: 0.5) : AppColors.white,
        hasShadow: true,
        child: Row(
          children: [
            // Heart icon
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.softRed.withValues(alpha: 0.12),
              ),
              child: const Icon(
                Icons.favorite_rounded,
                size: 18,
                color: AppColors.softRed,
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

            // Edit
            GestureDetector(
              onTap: onEdit,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.brandPrimary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.edit_rounded,
                  size: 18,
                  color: AppColors.brandPrimary.withValues(alpha: 0.7),
                ),
              ),
            ),
            const SizedBox(width: AppConstants.spacingXs),

            // Delete (tap, with long press kept as a shortcut)
            GestureDetector(
              onTap: () {
                HapticFeedback.heavyImpact();
                onDelete();
              },
              onLongPress: () {
                HapticFeedback.heavyImpact();
                onDelete();
              },
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.softRed.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.delete_outline_rounded,
                  size: 18,
                  color: AppColors.softRed.withValues(alpha: 0.7),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
