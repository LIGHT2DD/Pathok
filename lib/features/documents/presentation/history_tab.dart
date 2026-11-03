import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/constants/pathok_icons.dart';
import '../../../core/localization/app_strings.dart';
import '../models/local_document.dart';

class HistoryTab extends StatefulWidget {
  const HistoryTab({
    required this.documents,
    required this.onOpen,
    required this.onRename,
    required this.onDelete,
    this.onTogglePin,
    super.key,
  });

  final List<LocalDocument> documents;
  final ValueChanged<LocalDocument> onOpen;
  final ValueChanged<LocalDocument> onRename;
  final ValueChanged<LocalDocument> onDelete;
  final ValueChanged<LocalDocument>? onTogglePin;

  @override
  State<HistoryTab> createState() => _HistoryTabState();
}

class _HistoryTabState extends State<HistoryTab> {
  String _query = '';
  String _activeFilter = 'all'; // 'all', 'prescription', 'bill', 'id_card', 'image', 'pdf'

  Widget _buildCategoryBadge(String category, AppStrings strings) {
    Color bg;
    Color fg;
    String label;

    switch (category) {
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

    final filtered = widget.documents.where((document) {
      if (_activeFilter == 'image' && document.fileType != 'image') return false;
      if (_activeFilter == 'pdf' && document.fileType != 'pdf') return false;
      if (_activeFilter == 'prescription' && document.category != 'prescription') return false;
      if (_activeFilter == 'bill' && document.category != 'bill') return false;
      if (_activeFilter == 'id_card' && document.category != 'id_card') return false;

      final query = _query.trim().toLowerCase();
      if (query.isEmpty) return true;
      return document.title.toLowerCase().contains(query) ||
          document.text.toLowerCase().contains(query);
    }).toList();

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 760),
        child: SafeArea(
          child: CustomScrollView(
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                sliver: SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header
                      Row(
                        children: [
                          Text(
                            strings.navDocuments,
                            style: theme.textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.4,
                            ),
                          ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary.withAlpha(20),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Text(
                              strings.documentsCount(widget.documents.length),
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Modern Floating Search Bar
                      TextField(
                        onChanged: (value) => setState(() => _query = value),
                        decoration: InputDecoration(
                          prefixIcon: const Icon(Icons.search, size: 22),
                          hintText: strings.searchDocuments,
                          filled: true,
                          fillColor: theme.cardColor,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(30),
                            borderSide: BorderSide(
                              color: theme.dividerColor.withAlpha(50),
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(30),
                            borderSide: BorderSide(
                              color: theme.dividerColor.withAlpha(50),
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(30),
                            borderSide: BorderSide(
                              color: theme.colorScheme.primary,
                              width: 2,
                            ),
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                          suffixIcon: _query.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear, size: 20),
                                  onPressed: () => setState(() => _query = ''),
                                )
                              : null,
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Smart Filter Chips Row with Categories
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            FilterChip(
                              selected: _activeFilter == 'all',
                              label: Text(strings.filterAll),
                              onSelected: (_) {
                                HapticFeedback.selectionClick();
                                setState(() => _activeFilter = 'all');
                              },
                            ),
                            const SizedBox(width: 8),
                            FilterChip(
                              selected: _activeFilter == 'prescription',
                              avatar: const Icon(PathokIcons.pill, size: 14),
                              label: Text(strings.categoryPrescriptions),
                              onSelected: (_) {
                                HapticFeedback.selectionClick();
                                setState(() => _activeFilter = 'prescription');
                              },
                            ),
                            const SizedBox(width: 8),
                            FilterChip(
                              selected: _activeFilter == 'bill',
                              avatar: const Icon(Icons.receipt_long_outlined, size: 14),
                              label: Text(strings.categoryBills),
                              onSelected: (_) {
                                HapticFeedback.selectionClick();
                                setState(() => _activeFilter = 'bill');
                              },
                            ),
                            const SizedBox(width: 8),
                            FilterChip(
                              selected: _activeFilter == 'id_card',
                              avatar: const Icon(Icons.badge_outlined, size: 14),
                              label: Text(strings.categoryIdCards),
                              onSelected: (_) {
                                HapticFeedback.selectionClick();
                                setState(() => _activeFilter = 'id_card');
                              },
                            ),
                            const SizedBox(width: 8),
                            FilterChip(
                              selected: _activeFilter == 'image',
                              label: Text(strings.filterPhotos),
                              onSelected: (_) {
                                HapticFeedback.selectionClick();
                                setState(() => _activeFilter = 'image');
                              },
                            ),
                            const SizedBox(width: 8),
                            FilterChip(
                              selected: _activeFilter == 'pdf',
                              label: Text(strings.filterPdfs),
                              onSelected: (_) {
                                HapticFeedback.selectionClick();
                                setState(() => _activeFilter = 'pdf');
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Empty State or Lazy Recycled Document Cards
              if (filtered.isEmpty)
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  sliver: SliverToBoxAdapter(
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(40),
                        child: Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(18),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primary.withAlpha(20),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.search_off, size: 36),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _query.trim().isEmpty
                                  ? strings.noDocumentsYet
                                  : strings.noDocumentsMatch,
                              textAlign: TextAlign.center,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                                height: 1.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                  sliver: SliverList.builder(
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final document = filtered[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Card(
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 6,
                            ),
                            leading: Container(
                              width: 46,
                              height: 46,
                              decoration: BoxDecoration(
                                color: document.fileType == 'pdf'
                                    ? const Color(0xffffe4e6)
                                    : (document.category == 'prescription'
                                        ? const Color(0xffecfdf5)
                                        : theme.colorScheme.primary.withAlpha(25)),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Icon(
                                document.fileType == 'pdf'
                                    ? Icons.picture_as_pdf_outlined
                                    : (document.category == 'prescription'
                                        ? PathokIcons.pill
                                        : PathokIcons.fileText),
                                color: document.fileType == 'pdf'
                                    ? const Color(0xffe11d48)
                                    : (document.category == 'prescription'
                                        ? const Color(0xff059669)
                                        : theme.colorScheme.primary),
                                size: 24,
                              ),
                            ),
                            title: Row(
                              children: [
                                if (document.isPinned) ...[
                                  const Icon(
                                    Icons.push_pin_rounded,
                                    size: 16,
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
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 5),
                                Row(
                                  children: [
                                    _buildCategoryBadge(document.category, strings),
                                    const SizedBox(width: 8),
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
                            trailing: PopupMenuButton<String>(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(18),
                              ),
                              onSelected: (value) {
                                if (value == 'pin') widget.onTogglePin?.call(document);
                                if (value == 'rename') widget.onRename(document);
                                if (value == 'delete') widget.onDelete(document);
                              },
                              itemBuilder: (context) => [
                                PopupMenuItem(
                                  value: 'pin',
                                  child: Row(
                                    children: [
                                      Icon(
                                        document.isPinned ? Icons.push_pin_outlined : Icons.push_pin,
                                        size: 20,
                                        color: const Color(0xfff59e0b),
                                      ),
                                      const SizedBox(width: 10),
                                      Text(document.isPinned ? strings.unpinDocument : strings.pinDocument),
                                    ],
                                  ),
                                ),
                                PopupMenuItem(
                                  value: 'rename',
                                  child: Row(
                                    children: [
                                      const Icon(Icons.edit_outlined, size: 20),
                                      const SizedBox(width: 10),
                                      Text(strings.renameDocument),
                                    ],
                                  ),
                                ),
                                PopupMenuItem(
                                  value: 'delete',
                                  child: Row(
                                    children: [
                                      Icon(PathokIcons.trash, size: 20, color: theme.colorScheme.error),
                                      const SizedBox(width: 10),
                                      Text(
                                        strings.delete,
                                        style: TextStyle(color: theme.colorScheme.error),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            onTap: () {
                              HapticFeedback.selectionClick();
                              widget.onOpen(document);
                            },
                          ),
                        ),
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
}
