import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:quit_drinking/constants/app_colors.dart';
import 'package:quit_drinking/constants/app_constants.dart';
import 'package:quit_drinking/screens/home_screen.dart';

/// Onboarding screen shown on first app launch.
///
/// Guides the user through setting up their sobriety date, first reason,
/// and daily spend estimate before entering the main app.
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  // ── Page 2: Sobriety Date ─────────────────────────────────────────────
  DateTime? _selectedDate;

  // ── Page 3: Reasons ───────────────────────────────────────────────────
  final TextEditingController _reasonController = TextEditingController();

  // ── Page 4: Money Tracker ─────────────────────────────────────────────
  final TextEditingController _spendController = TextEditingController();
  String _selectedCurrency = 'USD';

  final List<String> _currencies = ['USD', 'EUR', 'GBP', 'CAD', 'AUD'];

  bool get _isLastPage => _currentPage == 3;

  @override
  void dispose() {
    _pageController.dispose();
    _reasonController.dispose();
    _spendController.dispose();
    super.dispose();
  }

  Future<void> _onComplete() async {
    final prefs = await SharedPreferences.getInstance();

    // Save sobriety start date (page 2)
    if (_selectedDate != null) {
      await prefs.setInt(
        'sobriety_start_date',
        _selectedDate!.millisecondsSinceEpoch,
      );
    }

    // Save first reason (page 3)
    final reason = _reasonController.text.trim();
    if (reason.isNotEmpty) {
      await prefs.setStringList('my_reasons', [reason]);
    }

    // Save daily spend (page 4)
    final spendText = _spendController.text.trim();
    if (spendText.isNotEmpty) {
      final spend = double.tryParse(spendText) ?? 0;
      // Store as cost per drink using the savings service keys
      // We store the daily spend in the savings_cost_per_drink field
      // since the onboarding asks for total daily spend
      await prefs.setDouble('savings_cost_per_drink', spend);
      await prefs.setDouble('daily_spend', spend);
    }

    // Save currency
    await prefs.setString('currency', _selectedCurrency);

    // Mark onboarding as complete
    await prefs.setBool('onboarding_complete', true);

    // One-time first-run safety acknowledgement (persisted with a safe
    // fallback: if prefs fail the notice simply shows again next launch).
    final acknowledged = prefs.getBool('health_notice_acknowledged') ?? false;
    if (!acknowledged && mounted) {
      await _showHealthNoticeDialog();
      try {
        await prefs.setBool('health_notice_acknowledged', true);
      } catch (_) {
        // Ignore — the acknowledgement will be requested again next time.
      }
    }

    // Navigate to home screen (replace so user can't go back)
    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    }
  }

  /// One-time notice: QuitDrink Ai is not medical advice, and stopping heavy
  /// drinking suddenly can be dangerous.
  Future<void> _showHealthNoticeDialog() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? AppColors.darkSurfaceAlt : AppColors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.radiusLg),
        ),
        title: Text(
          'Before You Begin',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: isDark ? AppColors.textOnDark : AppColors.textPrimary,
          ),
        ),
        content: Text(
          'QuitDrink Ai is not medical advice and is not a substitute for '
          'professional care.\n\n'
          'Stopping heavy drinking suddenly can be dangerous. Please talk to '
          'a doctor before making big changes — especially if you drink '
          'heavily or have withdrawal symptoms.\n\n'
          'In an emergency, call your local emergency services, or 988 in '
          'the US.',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w400,
            height: 1.5,
            color: isDark
                ? AppColors.textOnDarkSecondary
                : AppColors.textSecondary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('I understand'),
          ),
        ],
      ),
    );
  }

  void _nextPage() {
    if (_isLastPage) {
      _onComplete();
    } else {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOutCubic,
      );
    }
  }

  void _skip() {
    _pageController.animateToPage(
      3,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOutCubic,
    );
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? now,
      firstDate: DateTime(2000),
      lastDate: now,
      builder: (context, child) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Theme(
          data: Theme.of(context).copyWith(
            datePickerTheme: DatePickerThemeData(
              backgroundColor:
                  isDark ? AppColors.darkSurfaceAlt : AppColors.white,
              surfaceTintColor: Colors.transparent,
              headerBackgroundColor:
                  AppColors.navyBlue,
              headerForegroundColor: AppColors.white,
              todayForegroundColor:
                  WidgetStateProperty.all(AppColors.navyBlue),
              dayForegroundColor: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.selected)) return AppColors.white;
                return isDark ? AppColors.textOnDark : AppColors.textPrimary;
              }),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkSurface : AppColors.lightGray,
      body: SafeArea(
        child: Column(
          children: [
            // ── Skip Button (top-right, hidden on last page) ──────────
            if (!_isLastPage)
              Align(
                alignment: Alignment.topRight,
                child: TextButton(
                  onPressed: _skip,
                  style: TextButton.styleFrom(
                    foregroundColor: isDark
                        ? AppColors.textOnDarkSecondary
                        : AppColors.textSecondary,
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppConstants.spacingLg,
                      vertical: AppConstants.spacingMd,
                    ),
                  ),
                  child: Text(
                    'Skip',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              )
            else
              const SizedBox(height: 56),

            // ── Page View ─────────────────────────────────────────────
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: (page) => setState(() => _currentPage = page),
                physics: const ClampingScrollPhysics(),
                children: [
                  _buildWelcomePage(isDark),
                  _buildDatePage(isDark),
                  _buildReasonPage(isDark),
                  _buildMoneyPage(isDark),
                ],
              ),
            ),

            // ── Bottom Section ────────────────────────────────────────
            Container(
              padding: EdgeInsets.fromLTRB(
                AppConstants.spacingLg,
                AppConstants.spacingMd,
                AppConstants.spacingLg,
                MediaQuery.of(context).padding.bottom + AppConstants.spacingMd,
              ),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurface : AppColors.white,
                border: Border(
                  top: BorderSide(
                    color: isDark ? AppColors.darkCardAlt : AppColors.lightGrayAlt,
                  ),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Dot Indicators
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(4, (i) {
                      final isActive = i == _currentPage;
                      return AnimatedContainer(
                        duration: AppConstants.animationFast,
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: isActive ? 24 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(4),
                          color: isActive
                              ? AppColors.navyBlue
                              : (isDark
                                  ? AppColors.darkCardAlt
                                  : AppColors.lightGrayAlt),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: AppConstants.spacingLg),

                  // Action Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _nextPage,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.navyBlue,
                        foregroundColor: AppColors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(AppConstants.radiusSm),
                        ),
                        padding: const EdgeInsets.symmetric(
                          vertical: AppConstants.spacingMd,
                        ),
                      ),
                      child: Text(
                        _isLastPage ? 'Start My Journey' : 'Next',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Page 1: Welcome ──────────────────────────────────────────────────

  Widget _buildWelcomePage(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppConstants.spacingXl),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Large spa icon in a circle
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  AppColors.navyBlue,
                  AppColors.navyBlueLight,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.navyBlue.withValues(alpha: 0.3),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: const Icon(
              Icons.spa_rounded,
              size: 48,
              color: AppColors.white,
            ),
          ),
          const SizedBox(height: AppConstants.spacingLg),

          Text(
            'Welcome to\nQuitDrink Ai',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w700,
              height: 1.2,
              color: isDark ? AppColors.textOnDark : AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: AppConstants.spacingMd),

          Text(
            'Your personal sobriety companion.\n${AppConstants.tagline}',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w400,
              height: 1.5,
              color: isDark
                  ? AppColors.textOnDarkSecondary
                  : AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppConstants.spacingLg),

          // Age disclaimer
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppConstants.spacingMd,
              vertical: AppConstants.spacingSm,
            ),
            decoration: BoxDecoration(
              color: AppColors.softOrange.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppConstants.radiusSm),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.info_outline_rounded,
                  size: 16,
                  color: AppColors.softOrange,
                ),
                const SizedBox(width: AppConstants.spacingXs),
                Flexible(
                  child: Text(
                    'This app is intended for users 18 and older',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      height: 1.3,
                      color: AppColors.softOrange,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppConstants.spacingSm),

          // GDPR note
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppConstants.spacingMd,
              vertical: AppConstants.spacingSm,
            ),
            decoration: BoxDecoration(
              color: AppColors.softTeal.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(AppConstants.radiusSm),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.lock_outline_rounded,
                  size: 16,
                  color: AppColors.softTeal,
                ),
                const SizedBox(width: AppConstants.spacingXs),
                Flexible(
                  child: Text(
                    'We don\'t collect or share your personal data. Everything stays on your device.',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      height: 1.3,
                      color: AppColors.softTeal,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Page 2: Sobriety Date ────────────────────────────────────────────

  Widget _buildDatePage(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppConstants.spacingXl),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Icon
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.softTeal.withValues(alpha: 0.15),
            ),
            child: const Icon(
              Icons.calendar_today_rounded,
              size: 32,
              color: AppColors.softTeal,
            ),
          ),
          const SizedBox(height: AppConstants.spacingLg),

          Text(
            'When did you start\nyour journey?',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              height: 1.3,
              color: isDark ? AppColors.textOnDark : AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: AppConstants.spacingLg),

          // Date picker button
          InkWell(
            onTap: _pickDate,
            borderRadius: BorderRadius.circular(AppConstants.radiusSm),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                horizontal: AppConstants.spacingLg,
                vertical: AppConstants.spacingMd,
              ),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkCard : AppColors.white,
                borderRadius: BorderRadius.circular(AppConstants.radiusSm),
                border: Border.all(
                  color: isDark ? AppColors.darkCardAlt : AppColors.lightGrayAlt,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.event_rounded,
                    size: 20,
                    color: AppColors.navyBlue,
                  ),
                  const SizedBox(width: AppConstants.spacingSm),
                  Text(
                    _selectedDate != null
                        ? '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}'
                        : 'Tap to select your quit date',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: _selectedDate != null
                          ? (isDark
                              ? AppColors.textOnDark
                              : AppColors.textPrimary)
                          : AppColors.textTertiary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Page 3: Your Reason ──────────────────────────────────────────────

  Widget _buildReasonPage(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppConstants.spacingXl),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Icon
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.softTeal.withValues(alpha: 0.15),
            ),
            child: const Icon(
              Icons.edit_note_rounded,
              size: 32,
              color: AppColors.softTeal,
            ),
          ),
          const SizedBox(height: AppConstants.spacingLg),

          Text(
            'Why are you quitting?',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              height: 1.3,
              color: isDark ? AppColors.textOnDark : AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: AppConstants.spacingLg),

          // Text input
          Container(
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkCard : AppColors.white,
              borderRadius: BorderRadius.circular(AppConstants.radiusSm),
              border: Border.all(
                color: isDark ? AppColors.darkCardAlt : AppColors.lightGrayAlt,
              ),
            ),
            child: TextField(
              controller: _reasonController,
              textCapitalization: TextCapitalization.sentences,
              maxLines: 3,
              minLines: 2,
              decoration: InputDecoration(
                hintText: 'For my health, my family, my future…',
                hintStyle: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w400,
                  color: isDark
                      ? AppColors.textOnDarkSecondary.withValues(alpha: 0.5)
                      : AppColors.textTertiary,
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.all(AppConstants.spacingMd),
              ),
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w400,
                height: 1.5,
                color: isDark ? AppColors.textOnDark : AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Page 4: Money Tracker ────────────────────────────────────────────

  Widget _buildMoneyPage(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppConstants.spacingXl),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Icon
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.softTeal.withValues(alpha: 0.15),
            ),
            child: const Icon(
              Icons.monetization_on_rounded,
              size: 32,
              color: AppColors.softTeal,
            ),
          ),
          const SizedBox(height: AppConstants.spacingLg),

          Text(
            'How much did you spend\non alcohol daily?',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              height: 1.3,
              color: isDark ? AppColors.textOnDark : AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: AppConstants.spacingLg),

          // Amount input
          Container(
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkCard : AppColors.white,
              borderRadius: BorderRadius.circular(AppConstants.radiusSm),
              border: Border.all(
                color: isDark ? AppColors.darkCardAlt : AppColors.lightGrayAlt,
              ),
            ),
            child: TextField(
              controller: _spendController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                hintText: 'e.g. 15.00',
                hintStyle: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w400,
                  color: isDark
                      ? AppColors.textOnDarkSecondary.withValues(alpha: 0.5)
                      : AppColors.textTertiary,
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.all(AppConstants.spacingMd),
              ),
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: isDark ? AppColors.textOnDark : AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: AppConstants.spacingMd),

          // Currency selector
          Container(
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkCard : AppColors.white,
              borderRadius: BorderRadius.circular(AppConstants.radiusSm),
              border: Border.all(
                color: isDark ? AppColors.darkCardAlt : AppColors.lightGrayAlt,
              ),
            ),
            padding: const EdgeInsets.symmetric(
              horizontal: AppConstants.spacingMd,
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedCurrency,
                isExpanded: true,
                dropdownColor:
                    isDark ? AppColors.darkSurfaceAlt : AppColors.white,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: isDark ? AppColors.textOnDark : AppColors.textPrimary,
                ),
                items: _currencies.map((c) {
                  return DropdownMenuItem(
                    value: c,
                    child: Row(
                      children: [
                        Text(
                          _currencyFlag(c),
                          style: const TextStyle(fontSize: 20),
                        ),
                        const SizedBox(width: AppConstants.spacingSm),
                        Text(c),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _selectedCurrency = value);
                  }
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _currencyFlag(String code) {
    switch (code) {
      case 'USD': return '\u{1F1FA}\u{1F1F8}';
      case 'EUR': return '\u{1F1EA}\u{1F1FA}';
      case 'GBP': return '\u{1F1EC}\u{1F1E7}';
      case 'CAD': return '\u{1F1E8}\u{1F1E6}';
      case 'AUD': return '\u{1F1E6}\u{1F1FA}';
      default: return '';
    }
  }
}
