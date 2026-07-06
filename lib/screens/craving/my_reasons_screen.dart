import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:quit_drinking/constants/app_colors.dart';
import 'package:quit_drinking/constants/app_constants.dart';
import 'package:quit_drinking/widgets/sober_card.dart';

/// My Reasons screen — full CRUD for personal sobriety reasons.
/// Persisted in SharedPreferences under the key "my_reasons".
class MyReasonsScreen extends StatefulWidget {
  const MyReasonsScreen({super.key});

  @override
  State<MyReasonsScreen> createState() => _MyReasonsScreenState();
}

class _MyReasonsScreenState extends State<MyReasonsScreen> {
  static const _storageKey = 'my_reasons';
  List<String> _reasons = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadReasons();
  }

  Future<void> _loadReasons() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _reasons = prefs.getStringList(_storageKey) ?? [];
      _isLoading = false;
    });
  }

  Future<void> _saveReasons() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_storageKey, _reasons);
  }

  Future<void> _addReason(String reason) async {
    final trimmed = reason.trim();
    if (trimmed.isEmpty) return;
    setState(() => _reasons.insert(0, trimmed));
    await _saveReasons();
  }

  Future<void> _deleteReason(int index) async {
    setState(() => _reasons.removeAt(index));
    await _saveReasons();
    HapticFeedback.mediumImpact();
  }

  void _showAddDialog() {
    final controller = TextEditingController();
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
          'Add a Reason',
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
              final text = controller.text.trim();
              if (text.isNotEmpty) {
                _addReason(text);
                Navigator.pop(ctx);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.softTeal,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppConstants.radiusSm),
              ),
            ),
            child: const Text('Save'),
          ),
        ],
      ),
    ).then((_) => controller.dispose());
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

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
          onPressed: () => Navigator.of(context).pop(),
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
      body: _isLoading
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
                      child: _reasons.isEmpty
                          ? _EmptyReasonsState(isDark: isDark)
                          : ListView.builder(
                              itemCount: _reasons.length,
                              itemBuilder: (context, index) {
                                return _ReasonTile(
                                  reason: _reasons[index],
                                  index: index,
                                  isDark: isDark,
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
                              gradient: LinearGradient(
                                colors: [
                                  AppColors.softTeal,
                                  AppColors.softTealLight,
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(
                                AppConstants.radiusFull,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.softTeal.withValues(alpha: 0.3),
                                  blurRadius: 16,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.add_rounded,
                                  size: 20,
                                  color: Colors.white,
                                ),
                                SizedBox(width: AppConstants.spacingXs),
                                Text(
                                  'Add a reason',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
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
              color: AppColors.softTeal.withValues(alpha: isDark ? 0.12 : 0.08),
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
  final VoidCallback onDelete;

  const _ReasonTile({
    required this.reason,
    required this.index,
    required this.isDark,
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

            // Delete by long press
            GestureDetector(
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
