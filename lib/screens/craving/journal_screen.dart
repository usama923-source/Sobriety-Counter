import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:quit_drinking/constants/app_colors.dart';
import 'package:quit_drinking/constants/app_constants.dart';
import 'package:quit_drinking/widgets/sober_card.dart';

/// Journal screen — lets users write down how they're feeling during a
/// craving. Entries are saved to SharedPreferences with timestamps.
class JournalScreen extends StatefulWidget {
  const JournalScreen({super.key});

  @override
  State<JournalScreen> createState() => _JournalScreenState();
}

class _JournalScreenState extends State<JournalScreen> {
  static const _storageKey = 'craving_journal_entries';

  final TextEditingController _controller = TextEditingController();
  List<_JournalEntry> _entries = [];
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadEntries();
    // Listen for text changes so the Save button rebuilds reactively
    _controller.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _loadEntries() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_storageKey) ?? [];
    setState(() {
      _entries = raw.map((s) => _JournalEntry.fromJson(s)).toList();
      _isLoading = false;
    });
  }

  Future<void> _saveEntry() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    setState(() => _isSaving = true);
    HapticFeedback.lightImpact();

    final entry = _JournalEntry(
      text: text,
      timestamp: DateTime.now(),
    );
    _entries.insert(0, entry);
    _controller.clear();

    await _persistEntries();

    setState(() => _isSaving = false);
  }

  Future<void> _deleteEntry(int index) async {
    setState(() => _entries.removeAt(index));
    await _persistEntries();
    HapticFeedback.mediumImpact();
  }

  Future<void> _persistEntries() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      _storageKey,
      _entries.map((e) => e.toJson()).toList(),
    );
  }

  String _formatDate(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);

    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';

    return '${dt.day}/${dt.month}/${dt.year}';
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
          'Journal Your Feeling',
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
                    // ── Write Entry Card ─────────────────────────────────
                    SoberCard(
                      padding: const EdgeInsets.all(AppConstants.spacingLg),
                      color: isDark
                          ? AppColors.darkCardAlt.withValues(alpha: 0.5)
                          : AppColors.white,
                      hasShadow: true,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Header
                          Row(
                            children: [
                              Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: AppColors.softOrange.withValues(
                                    alpha: isDark ? 0.15 : 0.1,
                                  ),
                                ),
                                child: const Icon(
                                  Icons.edit_note_rounded,
                                  size: 20,
                                  color: AppColors.softOrange,
                                ),
                              ),
                              const SizedBox(width: AppConstants.spacingSm),
                              Text(
                                'How are you feeling?',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: isDark
                                      ? AppColors.textOnDark
                                      : AppColors.textPrimary,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppConstants.spacingMd),

                          // Text input
                          TextField(
                            controller: _controller,
                            maxLines: 5,
                            minLines: 3,
                            textCapitalization: TextCapitalization.sentences,
                            decoration: InputDecoration(
                              hintText:
                                  "Write what's on your mind right now…",
                              filled: true,
                              fillColor: isDark
                                  ? AppColors.darkCard
                                  : AppColors.lightGray,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(
                                  AppConstants.radiusSm,
                                ),
                                borderSide: BorderSide.none,
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(
                                  AppConstants.radiusSm,
                                ),
                                borderSide: BorderSide(
                                  color: AppColors.softOrange,
                                  width: 1.5,
                                ),
                              ),
                              contentPadding: const EdgeInsets.all(
                                AppConstants.spacingMd,
                              ),
                            ),
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w400,
                              height: 1.5,
                              color: isDark
                                  ? AppColors.textOnDark
                                  : AppColors.textPrimary,
                            ),
                          ),

                          const SizedBox(height: AppConstants.spacingMd),

                          // Save button
                          SizedBox(
                            width: double.infinity,
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: _controller.text.trim().isEmpty
                                    ? null
                                    : _saveEntry,
                                borderRadius: BorderRadius.circular(
                                  AppConstants.radiusFull,
                                ),
                                child: AnimatedContainer(
                                  duration: AppConstants.animationFast,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: AppConstants.spacingMd,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _controller.text.trim().isEmpty
                                        ? (isDark
                                            ? AppColors.darkCard
                                            : AppColors.lightGrayAlt)
                                        : null,
                                    gradient: _controller.text.trim().isEmpty
                                        ? null
                                        : const LinearGradient(
                                            colors: [
                                              AppColors.softOrange,
                                              AppColors.softOrangeLight,
                                            ],
                                            begin: Alignment.topLeft,
                                            end: Alignment.bottomRight,
                                          ),
                                    borderRadius: BorderRadius.circular(
                                      AppConstants.radiusFull,
                                    ),
                                    boxShadow: _controller.text.trim().isEmpty
                                        ? null
                                        : [
                                            BoxShadow(
                                              color: AppColors.softOrange
                                                  .withValues(alpha: 0.3),
                                              blurRadius: 16,
                                              offset: const Offset(0, 4),
                                            ),
                                          ],
                                  ),
                                  child: Center(
                                    child: _isSaving
                                        ? const SizedBox(
                                            width: 20,
                                            height: 20,
                                            child:
                                                CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: Colors.white,
                                            ),
                                          )
                                        : Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Icon(
                                                Icons.save_rounded,
                                                size: 18,
                                                color: _controller
                                                        .text.trim().isEmpty
                                                    ? (isDark
                                                        ? AppColors
                                                            .textOnDarkSecondary
                                                        : AppColors
                                                            .textTertiary)
                                                    : Colors.white,
                                              ),
                                              const SizedBox(
                                                  width:
                                                      AppConstants.spacingXs),
                                              Text(
                                                'Save Entry',
                                                style: TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.w700,
                                                  color: _controller
                                                          .text.trim().isEmpty
                                                      ? (isDark
                                                          ? AppColors
                                                              .textOnDarkSecondary
                                                          : AppColors
                                                              .textTertiary)
                                                      : Colors.white,
                                                  letterSpacing: 0.3,
                                                ),
                                              ),
                                            ],
                                          ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: AppConstants.spacingLg),

                    // ── Past Entries ─────────────────────────────────────
                    Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.navyBlue.withValues(
                              alpha: isDark ? 0.15 : 0.1,
                            ),
                          ),
                          child: Icon(
                            Icons.history_rounded,
                            size: 20,
                            color: isDark
                                ? AppColors.skyBlueLight
                                : AppColors.navyBlue,
                          ),
                        ),
                        const SizedBox(width: AppConstants.spacingSm),
                        Expanded(
                          child: Text(
                            'Past Entries',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: isDark
                                  ? AppColors.textOnDark
                                  : AppColors.textPrimary,
                            ),
                          ),
                        ),
                        if (_entries.isNotEmpty)
                          Text(
                            '${_entries.length}',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: isDark
                                  ? AppColors.textOnDarkSecondary
                                  : AppColors.textTertiary,
                            ),
                          ),
                      ],
                    ),

                    const SizedBox(height: AppConstants.spacingMd),

                    // ── Entries List ──────────────────────────────────
                    Expanded(
                      child: _entries.isEmpty
                          ? _EmptyJournalState(isDark: isDark)
                          : ListView.builder(
                              itemCount: _entries.length,
                              itemBuilder: (context, index) {
                                final entry = _entries[index];
                                return _JournalEntryTile(
                                  entry: entry,
                                  index: index,
                                  isDark: isDark,
                                  formattedDate: _formatDate(entry.timestamp),
                                  onDelete: () =>
                                      _confirmDelete(context, index),
                                );
                              },
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
          'Delete Entry',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: isDark ? AppColors.textOnDark : AppColors.textPrimary,
          ),
        ),
        content: Text(
          'Are you sure you want to delete this journal entry?',
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
                color: isDark
                    ? AppColors.textOnDarkSecondary
                    : AppColors.textSecondary,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              _deleteEntry(index);
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

// ── Journal Entry Model ─────────────────────────────────────────────────

class _JournalEntry {
  final String text;
  final DateTime timestamp;

  const _JournalEntry({required this.text, required this.timestamp});

  factory _JournalEntry.fromJson(String json) {
    // Format: "timestamp_unix|text"
    final parts = json.split('|');
    if (parts.length >= 2) {
      final ts = int.tryParse(parts[0]) ?? 0;
      return _JournalEntry(
        text: parts.sublist(1).join('|'),
        timestamp: DateTime.fromMillisecondsSinceEpoch(ts),
      );
    }
    return _JournalEntry(text: json, timestamp: DateTime.now());
  }

  String toJson() => '${timestamp.millisecondsSinceEpoch}|$text';
}

// ── Empty State ─────────────────────────────────────────────────────────

class _EmptyJournalState extends StatelessWidget {
  final bool isDark;

  const _EmptyJournalState({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.softOrange.withValues(
                alpha: isDark ? 0.12 : 0.08,
              ),
            ),
            child: Icon(
              Icons.menu_book_rounded,
              size: 36,
              color: isDark
                  ? AppColors.textOnDarkSecondary.withValues(alpha: 0.5)
                  : AppColors.textTertiary,
            ),
          ),
          const SizedBox(height: AppConstants.spacingLg),
          Text(
            'No entries yet',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: isDark ? AppColors.textOnDark : AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: AppConstants.spacingXs),
          Text(
            'Write down how you\'re feeling right now.\nIt helps to get it out.',
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

// ── Journal Entry Tile ──────────────────────────────────────────────────

class _JournalEntryTile extends StatelessWidget {
  final _JournalEntry entry;
  final int index;
  final bool isDark;
  final String formattedDate;
  final VoidCallback onDelete;

  const _JournalEntryTile({
    required this.entry,
    required this.index,
    required this.isDark,
    required this.formattedDate,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppConstants.spacingXs),
      child: SoberCard(
        padding: const EdgeInsets.all(AppConstants.spacingMd),
        color: isDark
            ? AppColors.darkCardAlt.withValues(alpha: 0.5)
            : AppColors.white,
        hasShadow: true,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row with date and delete
            Row(
              children: [
                Icon(
                  Icons.access_time_rounded,
                  size: 14,
                  color: isDark
                      ? AppColors.textOnDarkSecondary
                      : AppColors.textTertiary,
                ),
                const SizedBox(width: 4),
                Text(
                  formattedDate,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: isDark
                        ? AppColors.textOnDarkSecondary
                        : AppColors.textTertiary,
                  ),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: onDelete,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppColors.softRed.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Icon(
                      Icons.delete_outline_rounded,
                      size: 16,
                      color: AppColors.softRed.withValues(alpha: 0.7),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppConstants.spacingSm),

            // Entry text
            Text(
              entry.text,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w400,
                height: 1.5,
                color: isDark ? AppColors.textOnDark : AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
