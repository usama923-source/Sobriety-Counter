import 'package:flutter/material.dart';
import 'package:quit_drinking/constants/app_colors.dart';
import 'package:quit_drinking/constants/app_constants.dart';
import 'package:quit_drinking/widgets/sober_card.dart';

/// Privacy Policy screen — explains how user data is handled.
///
/// Accessed from the Settings screen's About section.
class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

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
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: Text(
          'Privacy Policy',
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
                      'Privacy Policy',
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
                      'Last updated: October 2026',
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
                      'Your privacy matters to us. Here\'s a simple overview of '
                      'how QuitDrink Ai handles your data.',
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

              // ── Section 1: Data We Collect ─────────────────────────
              _PolicySection(
                icon: Icons.storage_rounded,
                iconColor: AppColors.brandPrimary,
                title: 'Data Stored on Your Device',
                body:
                    'Your sobriety date, the reasons you save, your weight '
                    'entries, daily check-in history, favourite quotes, and app '
                    'settings are stored locally on your device. We do not upload '
                    'this information to our own servers.',
                isDark: isDark,
              ),

              const SizedBox(height: AppConstants.spacingSm),

              // ── Section 2: Analytics ───────────────────────────────
              _PolicySection(
                icon: Icons.insights_rounded,
                iconColor: AppColors.brandLightBlue,
                title: 'Analytics',
                body:
                    'We use Firebase Analytics (Google) to understand how the app '
                    'is used. It records basic events such as when the app is '
                    'opened and when a daily reminder is set. These events '
                    'contain no name, email, or contact details, and are not used '
                    'to advertise to you.',
                isDark: isDark,
              ),

              const SizedBox(height: AppConstants.spacingSm),

              // ── Section 3: AI Chat ─────────────────────────────────
              _PolicySection(
                icon: Icons.smart_toy_rounded,
                iconColor: AppColors.brandPrimary,
                title: 'AI Chat',
                body:
                    'When you use the AI Friend chat feature, your messages — '
                    'together with the recent conversation history needed to '
                    'generate a reply — are sent through Firebase AI Logic to '
                    'Google\'s Gemini to produce a response. Requests are '
                    'protected by Firebase App Check, which verifies that they '
                    'come from this app. Google\'s privacy policy applies to '
                    'those transmissions. Under Google\'s terms for the free '
                    'Gemini API tier, Google may use submitted content to '
                    'improve its products and services. Please do not share '
                    'personal or sensitive information (such as your name, '
                    'contact details, or medical information) in the chat. We '
                    'do not store your chat messages on our servers — they '
                    'remain on your device. AI chat has a daily message limit, '
                    'and the app keeps a count of the messages you send each '
                    'day in your device\'s private storage to enforce it.',
                isDark: isDark,
              ),

              const SizedBox(height: AppConstants.spacingSm),

              // ── Section 4: No Account Required ─────────────────────
              _PolicySection(
                icon: Icons.person_off_rounded,
                iconColor: AppColors.brandLightBlue,
                title: 'No Account Required',
                body:
                    'The app works fully offline for all core features — tracking '
                    'your sobriety, logging reasons, checking in daily, and more. '
                    'The only feature that requires an internet connection is the '
                    'AI Friend chat, and even that works without creating an account.',
                isDark: isDark,
              ),

              const SizedBox(height: AppConstants.spacingSm),

              // ── Section 5: No Data Selling ─────────────────────────
              _PolicySection(
                icon: Icons.verified_rounded,
                iconColor: AppColors.brandPrimary,
                title: 'We Don\'t Sell Your Data',
                body:
                    'We do not sell or rent your personal data. We share data only '
                    'with the service providers described above (Google Firebase, '
                    'including Firebase AI Logic and Gemini for AI replies) to '
                    'operate the app.',
                isDark: isDark,
              ),

              const SizedBox(height: AppConstants.spacingSm),

              // ── Section 6: Children ────────────────────────────────
              _PolicySection(
                icon: Icons.family_restroom_rounded,
                iconColor: AppColors.brandPrimary,
                title: 'Children',
                body:
                    'QuitDrink Ai is not intended for use by individuals '
                    'under the age of 18. We do not knowingly collect any '
                    'information from minors.',
                isDark: isDark,
              ),

              const SizedBox(height: AppConstants.spacingSm),

              // ── Section 7: Contact Us ──────────────────────────────
              _PolicySection(
                icon: Icons.mail_outline_rounded,
                iconColor: AppColors.softRed,
                title: 'Contact Us',
                body:
                    'If you have any questions about this privacy policy or how '
                    'your data is handled, please reach out to us at:',
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

// ── Policy Section Widget ──────────────────────────────────────────────

class _PolicySection extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String body;
  final bool isDark;

  const _PolicySection({
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
