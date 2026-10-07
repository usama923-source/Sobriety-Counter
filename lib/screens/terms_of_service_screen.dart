import 'package:flutter/material.dart';
import 'package:quit_drinking/constants/app_colors.dart';
import 'package:quit_drinking/constants/app_constants.dart';
import 'package:quit_drinking/widgets/sober_card.dart';

/// Terms of Service screen — outlines the legal terms for using the app.
///
/// Accessed from the Settings screen's About section alongside Privacy Policy.
class TermsOfServiceScreen extends StatelessWidget {
  const TermsOfServiceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkSurface : AppColors.lightGray,
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 0.5,
        backgroundColor: Colors.transparent,
        foregroundColor: isDark ? AppColors.textOnDark : AppColors.textPrimary,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_rounded,
            color: isDark ? AppColors.textOnDark : AppColors.textPrimary,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Terms of Service',
          style: TextStyle(
            fontSize: 20,
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
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Terms of Service',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        height: 1.2,
                        color:
                            isDark ? AppColors.textOnDark : AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: AppConstants.spacingXs),
                    Text(
                      'Last updated: July 2026',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: isDark
                            ? AppColors.textOnDarkSecondary
                            : AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: AppConstants.spacingSm),
                    Text(
                      'Please read these terms carefully before using QuitDrink Ai.',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                        height: 1.5,
                        color: isDark
                            ? AppColors.textOnDarkSecondary
                            : AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),

              // ── Section 1: Acceptance ──────────────────────────────
              _TermsSection(
                icon: Icons.check_circle_outline_rounded,
                iconColor: AppColors.skyBlueDark,
                title: 'Acceptance',
                body:
                    'By using QuitDrink Ai, you agree to these terms of '
                    'service. If you do not agree with any part of these terms, '
                    'please refrain from using the application.',
                isDark: isDark,
              ),

              const SizedBox(height: AppConstants.spacingSm),

              // ── Section 2: Not Medical Advice ──────────────────────
              _TermsSection(
                icon: Icons.health_and_safety_rounded,
                iconColor: AppColors.softRed,
                title: 'Not Medical Advice',
                body:
                    'QuitDrink Ai is designed for motivational and '
                    'informational purposes only. It is not a substitute for '
                    'professional medical advice, diagnosis, or addiction '
                    'treatment. Always consult a qualified healthcare provider '
                    'for any health-related concerns or decisions.',
                isDark: isDark,
              ),

              const SizedBox(height: AppConstants.spacingSm),

              // ── Section 3: AI Chat ─────────────────────────────────
              _TermsSection(
                icon: Icons.smart_toy_rounded,
                iconColor: AppColors.softTeal,
                title: 'AI Chat',
                body:
                    'AI-generated responses are provided for support and '
                    'motivational purposes only. They do not constitute medical '
                    'or professional advice. Always consult a qualified '
                    'professional for serious concerns or emergencies. If you '
                    'are in crisis, please contact a helpline immediately.',
                isDark: isDark,
              ),

              const SizedBox(height: AppConstants.spacingSm),

              // ── Section 4: Pro Features ────────────────────────────
              _TermsSection(
                icon: Icons.star_rounded,
                iconColor: AppColors.softOrange,
                title: 'Pro Features',
                body:
                    'Pro features are available as a one-time in-app purchase. '
                    'All purchases are non-refundable after activation. '
                    'Unlocking Pro provides access to the AI Friend chat '
                    'feature and supports future development of the app.',
                isDark: isDark,
              ),

              const SizedBox(height: AppConstants.spacingSm),

              // ── Section 5: User Responsibility ─────────────────────
              _TermsSection(
                icon: Icons.person_outline_rounded,
                iconColor: AppColors.navyBlue,
                title: 'User Responsibility',
                body:
                    'You are responsible for your own sobriety journey. '
                    'QuitDrink Ai is a tool to help you track and stay '
                    'motivated — it is not a treatment program. The app '
                    'developers are not responsible for any outcomes related '
                    'to your use of the application.',
                isDark: isDark,
              ),

              const SizedBox(height: AppConstants.spacingSm),

              // ── Section 6: Changes ─────────────────────────────────
              _TermsSection(
                icon: Icons.update_rounded,
                iconColor: AppColors.softTeal,
                title: 'Changes',
                body:
                    'We may update these terms of service at any time. '
                    'Changes will be reflected on this screen with an updated '
                    '"Last updated" date. Continued use of the app after '
                    'changes constitutes acceptance of the new terms.',
                isDark: isDark,
              ),

              const SizedBox(height: AppConstants.spacingSm),

              // ── Section 7: Contact ─────────────────────────────────
              _TermsSection(
                icon: Icons.mail_outline_rounded,
                iconColor: AppColors.softRed,
                title: 'Contact',
                body:
                    'If you have any questions about these terms, please '
                    'reach out to us at:',
                isDark: isDark,
              ),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppConstants.spacingMd,
                ),
                child: SoberCard(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppConstants.spacingLg,
                    vertical: AppConstants.spacingMd,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.email_outlined,
                        size: 20,
                        color: AppColors.softRed,
                      ),
                      const SizedBox(width: AppConstants.spacingSm),
                      Expanded(
                        child: SelectableText(
                          'support.quitdrinkai@gmail.com',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: isDark
                                ? AppColors.textOnDark
                                : AppColors.textPrimary,
                          ),
                        ),
                      ),
                      Icon(
                        Icons.copy_rounded,
                        size: 18,
                        color: isDark
                            ? AppColors.textOnDarkSecondary
                            : AppColors.textTertiary,
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: AppConstants.spacingXxl),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Terms Section Widget ───────────────────────────────────────────────

class _TermsSection extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String body;
  final bool isDark;

  const _TermsSection({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.body,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppConstants.spacingMd),
      child: SoberCard(
        padding: const EdgeInsets.symmetric(
          horizontal: AppConstants.spacingLg,
          vertical: AppConstants.spacingMd,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: iconColor.withValues(alpha: 0.15),
                    borderRadius:
                        BorderRadius.circular(AppConstants.radiusSm),
                  ),
                  child: Icon(icon, size: 19, color: iconColor),
                ),
                const SizedBox(width: AppConstants.spacingSm),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      height: 1.3,
                      color:
                          isDark ? AppColors.textOnDark : AppColors.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppConstants.spacingSm),
            Text(
              body,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w400,
                height: 1.5,
                color: isDark
                    ? AppColors.textOnDarkSecondary
                    : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
