import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/constants/pathok_icons.dart';
import '../../../core/localization/app_strings.dart';
import '../../prescription/models/medicine_reminder.dart';
import '../models/local_document.dart';

class HomeTab extends StatefulWidget {
  const HomeTab({
    required this.documents,
    required this.onCapture,
    required this.onImport,
    required this.onImportPdf,
    required this.onOpen,
    required this.onDelete,
    this.reminders,
    this.onToggleReminderTaken,
    super.key,
  });

  final List<LocalDocument> documents;
  final VoidCallback onCapture;
  final VoidCallback onImport;
  final VoidCallback onImportPdf;
  final ValueChanged<LocalDocument> onOpen;
  final ValueChanged<LocalDocument> onDelete;
  final List<MedicineReminder>? reminders;
  final ValueChanged<MedicineReminder>? onToggleReminderTaken;

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  String? _selectedCategory;

  String _getTimeBasedGreeting(AppStrings strings) {
    final hour = DateTime.now().hour;
    if (hour < 12) return strings.greetingMorning;
    if (hour < 17) return strings.greetingAfternoon;
    return strings.greetingEvening;
  }

  Widget _buildCategoryBadge(String category, AppStrings strings) {
    Color bg;
    Color fg;
    String label;

    switch (category) {
      case 'study':
        bg = const Color(0xffeef2ff);
        fg = const Color(0xff4f46e5);
        label = strings.categoryStudy;
        break;
      case 'prescription':
        bg = const Color(0xffecfdf5);
        fg = const Color(0xff059669);
        label = strings.categoryPrescriptions;
        break;
      case 'bill':
        bg = const Color(0xfffffbeb);
        fg = const Color(0xffd97706);
        label = strings.categoryBills;
        break;
      case 'id_card':
        bg = const Color(0xfff5f3ff);
        fg = const Color(0xff7c3aed);
        label = strings.categoryIdCards;
        break;
      default:
        bg = const Color(0xfff1f5f9);
        fg = const Color(0xff64748b);
        label = strings.categoryGeneral;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: fg),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final activeReminders = widget.reminders ?? const [];
    final takenCount = activeReminders.where((r) => r.isTakenToday).length;

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
                            fontWeight: FontWeight.w800,
                            color: isDark ? const Color(0xff34d399) : const Color(0xff059669),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Hero Quick-Scan Bento Card
              _HeroCameraBentoCard(
                badge: strings.fastScanBadge,
                title: strings.scanCamera,
                subtitle: strings.scanCameraSubtitle,
                onPressed: () {
                  HapticFeedback.lightImpact();
                  widget.onCapture();
                },
              ),
              const SizedBox(height: 14),

              // Secondary Quick Action Bento Cards (2 Columns)
              Row(
                children: [
                  Expanded(
                    child: _CompactBentoCard(
                      icon: PathokIcons.photo,
                      iconColor: const Color(0xff059669),
                      badgeBgColor: const Color(0xffecfdf5),
                      title: strings.chooseImage,
                      subtitle: strings.chooseImageSubtitle,
                      onPressed: () {
                        HapticFeedback.lightImpact();
                        widget.onImport();
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _CompactBentoCard(
                      icon: Icons.picture_as_pdf,
                      iconColor: const Color(0xffe11d48),
                      badgeBgColor: const Color(0xffffe4e6),
                      title: strings.choosePdf,
                      subtitle: strings.choosePdfSubtitle,
                      onPressed: () {
                        HapticFeedback.lightImpact();
                        widget.onImportPdf();
                      },
                    ),
                  ),
                ],
              ),

              // Universal Multi-Generational Category Hubs (4 Hubs)
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    strings.categoryHubs,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.2,
                    ),
                  ),
                  if (_selectedCategory != null)
                    GestureDetector(
                      onTap: () {
                        HapticFeedback.lightImpact();
                        setState(() => _selectedCategory = null);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary.withAlpha(20),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: [
                            Text(
                              strings.filterAll,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Icon(Icons.close, size: 12, color: theme.colorScheme.primary),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: _CategoryHubCard(
                      icon: Icons.menu_book_rounded,
                      color: const Color(0xff4f46e5),
                      bgColor: isDark ? const Color(0xff1e1b4b) : const Color(0xffeef2ff),
                      title: strings.categoryStudy,
                      subtitle: strings.categoryStudySubtitle,
                      count: widget.documents.where((d) => d.category == 'study').length,
                      isSelected: _selectedCategory == 'study',
                      onTap: () {
                        setState(() {
                          _selectedCategory = (_selectedCategory == 'study') ? null : 'study';
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _CategoryHubCard(
                      icon: Icons.receipt_long_rounded,
                      color: const Color(0xffd97706),
                      bgColor: isDark ? const Color(0xff451a03) : const Color(0xfffffbeb),
                      title: strings.categoryBills,
                      subtitle: strings.categoryBillsSubtitle,
                      count: widget.documents.where((d) => d.category == 'bill').length,
                      isSelected: _selectedCategory == 'bill',
                      onTap: () {
                        setState(() {
                          _selectedCategory = (_selectedCategory == 'bill') ? null : 'bill';
                        });
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _CategoryHubCard(
                      icon: PathokIcons.pill,
                      color: const Color(0xff059669),
                      bgColor: isDark ? const Color(0xff064e3b) : const Color(0xffecfdf5),
                      title: strings.categoryPrescriptions,
                      subtitle: strings.categoryPrescriptionsSubtitle,
                      count: widget.documents.where((d) => d.category == 'prescription').length,
                      isSelected: _selectedCategory == 'prescription',
                      onTap: () {
                        setState(() {
                          _selectedCategory = (_selectedCategory == 'prescription') ? null : 'prescription';
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _CategoryHubCard(
                      icon: Icons.description_outlined,
                      color: const Color(0xff0284c7),
                      bgColor: isDark ? const Color(0xff082f49) : const Color(0xfff0f9ff),
                      title: strings.categoryGeneral,
                      subtitle: strings.categoryGeneralSubtitle,
                      count: widget.documents.where((d) => d.category == 'general' || d.category == 'id_card').length,
                      isSelected: _selectedCategory == 'general',
                      onTap: () {
                        setState(() {
                          _selectedCategory = (_selectedCategory == 'general') ? null : 'general';
                        });
                      },
                    ),
                  ),
                ],
              ),

              // Interactive Today's Medicine Tracker Checklist
              if (activeReminders.isNotEmpty) ...[
                const SizedBox(height: 28),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(PathokIcons.pill, size: 20, color: Color(0xff059669)),
                        const SizedBox(width: 8),
                        Text(
                          strings.todaysMedicines,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.2,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: takenCount == activeReminders.length
                            ? const Color(0xffecfdf5)
                            : theme.colorScheme.primary.withAlpha(20),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '$takenCount / ${activeReminders.length}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: takenCount == activeReminders.length
                              ? const Color(0xff059669)
                              : theme.colorScheme.primary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Column(
                      children: activeReminders.map((reminder) {
                        final isTaken = reminder.isTakenToday;
                        final timeStr =
                            '${reminder.hour.toString().padLeft(2, '0')}:${reminder.minute.toString().padLeft(2, '0')}';

                        return ListTile(
                          leading: IconButton(
                            icon: Icon(
                              isTaken ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                              color: isTaken ? const Color(0xff10b981) : theme.colorScheme.onSurfaceVariant,
                              size: 24,
                            ),
                            onPressed: () {
                              HapticFeedback.mediumImpact();
                              widget.onToggleReminderTaken?.call(reminder);
                            },
                          ),
                          title: Text(
                            reminder.medicineName,
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                              decoration: isTaken ? TextDecoration.lineThrough : null,
                              color: isTaken ? theme.colorScheme.onSurfaceVariant : null,
                            ),
                          ),
                          subtitle: Text(
                            '${reminder.instructions} • $timeStr',
                            style: theme.textTheme.bodySmall,
                          ),
                          trailing: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: isTaken
                                  ? const Color(0xffecfdf5)
                                  : (isDark ? const Color(0xff374151) : const Color(0xfff1f5f9)),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              isTaken ? strings.taken : strings.pending,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: isTaken ? const Color(0xff059669) : theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                          onTap: () {
                            HapticFeedback.lightImpact();
                            widget.onToggleReminderTaken?.call(reminder);
                          },
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ],

              const SizedBox(height: 30),

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
                  if (widget.documents.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withAlpha(20),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        strings.documentsCount(
                          _selectedCategory == null
                              ? widget.documents.length
                              : widget.documents.where((d) => _selectedCategory == 'general'
                                  ? (d.category == 'general' || d.category == 'id_card')
                                  : d.category == _selectedCategory).length,
                        ),
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

              if (widget.documents.isEmpty)
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
                ...(_selectedCategory == null
                        ? widget.documents
                        : widget.documents.where((d) => _selectedCategory == 'general'
                            ? (d.category == 'general' || d.category == 'id_card')
                            : d.category == _selectedCategory).toList())
                    .take(5)
                    .map(
                      (document) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Card(
                          child: InkWell(
                            borderRadius: BorderRadius.circular(24),
                            onTap: () {
                              HapticFeedback.selectionClick();
                              widget.onOpen(document);
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
                                          : (document.category == 'study'
                                              ? const Color(0xffeef2ff)
                                              : (document.category == 'bill'
                                                  ? const Color(0xfffffbeb)
                                                  : (document.category == 'prescription'
                                                      ? const Color(0xffecfdf5)
                                                      : (document.category == 'id_card'
                                                          ? const Color(0xfff5f3ff)
                                                          : theme.colorScheme.primary.withAlpha(25))))),
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: Icon(
                                      document.fileType == 'pdf'
                                          ? Icons.picture_as_pdf_outlined
                                          : (document.category == 'study'
                                              ? Icons.menu_book_rounded
                                              : (document.category == 'bill'
                                                  ? Icons.receipt_long_rounded
                                                  : (document.category == 'prescription'
                                                      ? PathokIcons.pill
                                                      : (document.category == 'id_card'
                                                          ? Icons.badge_outlined
                                                          : PathokIcons.fileText)))),
                                      color: document.fileType == 'pdf'
                                          ? const Color(0xffe11d48)
                                          : (document.category == 'study'
                                              ? const Color(0xff4f46e5)
                                              : (document.category == 'bill'
                                                  ? const Color(0xffd97706)
                                                  : (document.category == 'prescription'
                                                      ? const Color(0xff059669)
                                                      : (document.category == 'id_card'
                                                          ? const Color(0xff7c3aed)
                                                          : theme.colorScheme.primary)))),
                                      size: 24,
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            if (document.isPinned) ...[
                                              const Icon(
                                                Icons.push_pin_rounded,
                                                size: 14,
                                                color: Color(0xfff59e0b),
                                              ),
                                              const SizedBox(width: 4),
                                            ],
                                            Expanded(
                                              child: Text(
                                                document.title,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.w700,
                                                  fontSize: 16,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            _buildCategoryBadge(document.category, strings),
                                            const SizedBox(width: 6),
                                            Expanded(
                                              child: Text(
                                                document.text.isEmpty
                                                    ? strings.emptyText
                                                    : document.text,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: theme.textTheme.bodySmall?.copyWith(
                                                  color: theme.colorScheme.onSurfaceVariant,
                                                ),
                                              ),
                                            ),
                                          ],
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
                                      widget.onDelete(document);
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

class _CategoryHubCard extends StatelessWidget {
  const _CategoryHubCard({
    required this.icon,
    required this.color,
    required this.bgColor,
    required this.title,
    required this.subtitle,
    required this.count,
    required this.isSelected,
    required this.onTap,
  });

  final IconData icon;
  final Color color;
  final Color bgColor;
  final String title;
  final String subtitle;
  final int count;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: isSelected ? 4 : 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: isSelected
            ? BorderSide(color: color, width: 2)
            : BorderSide.none,
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: bgColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(icon, color: color, size: 20),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: isSelected ? color : color.withAlpha(25),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '$count',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: isSelected ? Colors.white : color,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
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
    required this.badge,
    required this.title,
    required this.subtitle,
    required this.onPressed,
  });

  final String badge;
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
                        child: Text(
                          badge,
                          style: const TextStyle(
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
