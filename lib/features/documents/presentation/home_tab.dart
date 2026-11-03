import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/constants/pathok_icons.dart';
import '../../../core/localization/app_strings.dart';
import '../models/local_document.dart';

class HomeTab extends StatelessWidget {
  const HomeTab({
    required this.documents,
    required this.onCapture,
    required this.onImport,
    required this.onImportPdf,
    required this.onOpen,
    required this.onDelete,
    super.key,
  });

  final List<LocalDocument> documents;
  final VoidCallback onCapture;
  final VoidCallback onImport;
  final VoidCallback onImportPdf;
  final ValueChanged<LocalDocument> onOpen;
  final ValueChanged<LocalDocument> onDelete;

  String _getTimeBasedGreeting(AppStrings strings) {
    final hour = DateTime.now().hour;
    if (hour < 12) return strings.greetingMorning;
    if (hour < 17) return strings.greetingAfternoon;
    return strings.greetingEvening;
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 760),
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
            children: [
              // Top Header & Offline Security Badge
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.asset(
                      'assets/logo.png',
                      width: 46,
                      height: 46,
                      cacheWidth: 92,
                      cacheHeight: 92,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _getTimeBasedGreeting(strings),
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.4,
                          ),
                        ),
                        Text(
                          strings.welcomeSubtitle,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Offline Security Pill
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
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
                          strings.offlineBadge,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: isDark ? const Color(0xff6ee7b7) : const Color(0xff047857),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 28),

              // Section Title: Quick Actions
              Text(
                strings.quickActions,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.2,
                ),
              ),
              const SizedBox(height: 14),

              // Modern Bento Grid: Hero Camera Tile
              _HeroCameraBentoCard(
                title: strings.scanCamera,
                subtitle: strings.scanCameraSubtitle,
                onPressed: () {
                  HapticFeedback.lightImpact();
                  onCapture();
                },
              ),
              const SizedBox(height: 12),

              // Bento Grid: 2-Column Split for PDF and Gallery
              Row(
                children: [
                  Expanded(
                    child: _CompactBentoCard(
                      icon: PathokIcons.fileInvoice,
                      iconColor: const Color(0xffe11d48), // Rose
                      badgeBgColor: isDark ? const Color(0xff4c0519) : const Color(0xffffe4e6),
                      title: strings.choosePdf,
                      subtitle: strings.choosePdfSubtitle,
                      onPressed: () {
                        HapticFeedback.lightImpact();
                        onImportPdf();
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _CompactBentoCard(
                      icon: PathokIcons.photo,
                      iconColor: const Color(0xff059669), // Emerald
                      badgeBgColor: isDark ? const Color(0xff064e3b) : const Color(0xffd1fae5),
                      title: strings.chooseImage,
                      subtitle: strings.chooseImageSubtitle,
                      onPressed: () {
                        HapticFeedback.lightImpact();
                        onImport();
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),

              // Recent Documents Section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    strings.recentDocuments,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.2,
                    ),
                  ),
                  if (documents.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withAlpha(20),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        strings.documentsCount(documents.length),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),

              if (documents.isEmpty)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary.withAlpha(20),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.document_scanner_outlined,
                            size: 38,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          strings.noDocumentsYet,
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                ...documents.take(4).map(
                      (document) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Card(
                          child: InkWell(
                            borderRadius: BorderRadius.circular(24),
                            onTap: () {
                              HapticFeedback.selectionClick();
                              onOpen(document);
                            },
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Row(
                                children: [
                                  Container(
                                    width: 48,
                                    height: 48,
                                    decoration: BoxDecoration(
                                      color: document.fileType == 'pdf'
                                          ? const Color(0xffffe4e6)
                                          : theme.colorScheme.primary.withAlpha(25),
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: Icon(
                                      document.fileType == 'pdf'
                                          ? Icons.picture_as_pdf_outlined
                                          : PathokIcons.fileText,
                                      color: document.fileType == 'pdf'
                                          ? const Color(0xffe11d48)
                                          : theme.colorScheme.primary,
                                      size: 24,
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          document.title,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w700,
                                            fontSize: 16,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          document.text.isEmpty
                                              ? strings.emptyText
                                              : document.text,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: theme.textTheme.bodySmall?.copyWith(
                                            color: theme.colorScheme.onSurfaceVariant,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(PathokIcons.trash, size: 19),
                                    color: theme.colorScheme.error,
                                    tooltip: strings.delete,
                                    onPressed: () {
                                      HapticFeedback.lightImpact();
                                      onDelete(document);
                                    },
                                  ),
                                  Icon(
                                    PathokIcons.chevronRight,
                                    size: 18,
                                    color: theme.colorScheme.onSurfaceVariant,
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
      ),
    );
  }
}

class _HeroCameraBentoCard extends StatelessWidget {
  const _HeroCameraBentoCard({
    required this.title,
    required this.subtitle,
    required this.onPressed,
  });

  final String title;
  final String subtitle;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        gradient: const LinearGradient(
          colors: [Color(0xff1d4ed8), Color(0xff2563eb), Color(0xff3b82f6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x332563eb),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(26),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 20),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withAlpha(45),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'FAST SCAN',
                          style: TextStyle(
                            fontSize: 10,
                            letterSpacing: 1.1,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 18,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: TextStyle(
                          color: Colors.white.withAlpha(210),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(45),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(
                    PathokIcons.camera,
                    color: Colors.white,
                    size: 32,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CompactBentoCard extends StatelessWidget {
  const _CompactBentoCard({
    required this.icon,
    required this.iconColor,
    required this.badgeBgColor,
    required this.title,
    required this.subtitle,
    required this.onPressed,
  });

  final IconData icon;
  final Color iconColor;
  final Color badgeBgColor;
  final String title;
  final String subtitle;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(24),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: badgeBgColor,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: iconColor, size: 24),
              ),
              const SizedBox(height: 16),
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                  letterSpacing: -0.2,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
