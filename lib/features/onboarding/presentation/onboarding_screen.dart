import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/constants/pathok_icons.dart';
import '../../../core/localization/app_strings.dart';

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({
    required this.onComplete,
    this.onLanguageChanged,
    super.key,
  });

  final Future<void> Function() onComplete;
  final ValueChanged<bool>? onLanguageChanged;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isEnglish = strings.isEnglish;

    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight - 42),
                child: IntrinsicHeight(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Top Row: Brand & Language Toggle
                      Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: Image.asset(
                              'assets/logo.png',
                              width: 46,
                              height: 46,
                              fit: BoxFit.cover,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  strings.appName,
                                  style: theme.textTheme.headlineSmall?.copyWith(
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: -0.5,
                                    color: theme.colorScheme.primary,
                                  ),
                                ),
                                Text(
                                  strings.tagline,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (onLanguageChanged != null)
                            InkWell(
                              onTap: () {
                                HapticFeedback.selectionClick();
                                onLanguageChanged!(!isEnglish);
                              },
                              borderRadius: BorderRadius.circular(20),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.primary.withAlpha(isDark ? 35 : 20),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: theme.colorScheme.primary.withAlpha(60),
                                    width: 1,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.translate,
                                      size: 15,
                                      color: theme.colorScheme.primary,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      isEnglish ? 'বাং' : 'EN',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w800,
                                        color: theme.colorScheme.primary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Bento Hero Banner Card
                      Container(
                        padding: const EdgeInsets.all(22),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: isDark
                                ? [
                                    theme.colorScheme.primary.withAlpha(45),
                                    theme.colorScheme.surface,
                                  ]
                                : [
                                    theme.colorScheme.primary.withAlpha(22),
                                    Colors.white,
                                  ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: isDark
                                ? theme.colorScheme.primary.withAlpha(70)
                                : theme.colorScheme.primary.withAlpha(35),
                            width: 1.2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: theme.colorScheme.primary.withAlpha(isDark ? 25 : 12),
                              blurRadius: 18,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Security & Offline Badge
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: isDark ? const Color(0xff064e3b) : const Color(0xffecfdf5),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: isDark ? const Color(0xff059669) : const Color(0xffa7f3d0),
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 7,
                                    height: 7,
                                    decoration: const BoxDecoration(
                                      color: Color(0xff10b981),
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    strings.onboardingBadge,
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: isDark ? const Color(0xff6ee7b7) : const Color(0xff047857),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                            Semantics(
                              header: true,
                              child: Text(
                                strings.onboardingTitle,
                                style: theme.textTheme.headlineMedium?.copyWith(
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -0.5,
                                  color: isDark ? Colors.white : const Color(0xff0f172a),
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              strings.onboardingSubtitle,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                                height: 1.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Bento Feature Grid
                      _BentoFeatureCard(
                        icon: PathokIcons.scan,
                        iconColor: const Color(0xff2563eb),
                        badgeBgColor: isDark ? const Color(0xff1e1b4b) : const Color(0xffeff6ff),
                        title: strings.onboardingFeature1Title,
                        subtitle: strings.onboardingBenefit1,
                      ),
                      const SizedBox(height: 12),
                      _BentoFeatureCard(
                        icon: PathokIcons.volume,
                        iconColor: const Color(0xff059669),
                        badgeBgColor: isDark ? const Color(0xff064e3b) : const Color(0xffecfdf5),
                        title: strings.onboardingFeature2Title,
                        subtitle: strings.onboardingBenefit2,
                      ),
                      const SizedBox(height: 12),
                      _BentoFeatureCard(
                        icon: PathokIcons.lock,
                        iconColor: const Color(0xff7c3aed),
                        badgeBgColor: isDark ? const Color(0xff2e1065) : const Color(0xfff5f3ff),
                        title: strings.onboardingFeature3Title,
                        subtitle: strings.onboardingBenefit3,
                      ),

                      const Spacer(),
                      const SizedBox(height: 24),

                      // Privacy Note
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.shield_outlined,
                            size: 15,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              strings.onboardingNoAccount,
                              textAlign: TextAlign.center,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // High-Profile CTA Button
                      FilledButton.icon(
                        onPressed: () {
                          HapticFeedback.mediumImpact();
                          onComplete();
                        },
                        style: FilledButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          elevation: 2,
                        ),
                        icon: const Icon(PathokIcons.arrowRight, size: 20),
                        label: Text(
                          strings.getStarted,
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.2,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _BentoFeatureCard extends StatelessWidget {
  const _BentoFeatureCard({
    required this.icon,
    required this.iconColor,
    required this.badgeBgColor,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final Color iconColor;
  final Color badgeBgColor;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xff1e293b) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark ? const Color(0xff334155) : const Color(0xffe2e8f0),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(isDark ? 30 : 8),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: badgeBgColor,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              icon,
              color: iconColor,
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    color: isDark ? const Color(0xfff1f5f9) : const Color(0xff0f172a),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
