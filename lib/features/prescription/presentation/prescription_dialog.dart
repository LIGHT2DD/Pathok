import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/constants/pathok_icons.dart';
import '../../../core/localization/app_strings.dart';
import '../models/medicine_candidate.dart';
import '../models/medicine_reminder.dart';

class PrescriptionItemConfig {
  PrescriptionItemConfig({
    required this.candidate,
    this.selected = true,
    TimeOfDay? time,
  }) : time = time ?? const TimeOfDay(hour: 8, minute: 0);

  final MedicineCandidate candidate;
  bool selected;
  TimeOfDay time;
}

class PrescriptionDialog extends StatefulWidget {
  const PrescriptionDialog({
    super.key,
    required this.candidates,
  });

  final List<MedicineCandidate> candidates;

  static Future<List<MedicineReminder>?> show(
    BuildContext context,
    List<MedicineCandidate> candidates,
  ) {
    return showDialog<List<MedicineReminder>>(
      context: context,
      builder: (context) => PrescriptionDialog(candidates: candidates),
    );
  }

  @override
  State<PrescriptionDialog> createState() => _PrescriptionDialogState();
}

class _PrescriptionDialogState extends State<PrescriptionDialog> {
  late final List<PrescriptionItemConfig> _items;

  @override
  void initState() {
    super.initState();
    _items = widget.candidates
        .map((c) => PrescriptionItemConfig(candidate: c))
        .toList();
  }

  bool _isDuplicate(String name) {
    final lower = name.toLowerCase().trim();
    var matchCount = 0;
    for (final itm in _items) {
      final other = itm.candidate.name.toLowerCase().trim();
      if (other.contains(lower) || lower.contains(other)) {
        matchCount++;
      }
    }
    return matchCount > 1;
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final theme = Theme.of(context);
    final selectedCount = _items.where((i) => i.selected).length;

    return AlertDialog(
      title: Row(
        children: [
          Icon(PathokIcons.pill, color: theme.colorScheme.primary),
          const SizedBox(width: 10),
          Expanded(child: Text(strings.possibleMedicines)),
        ],
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer.withAlpha(50),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: theme.colorScheme.primary.withAlpha(40),
                  ),
                ),
                child: Text(
                  strings.prescriptionDisclaimer,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              ..._items.map((item) {
                final formattedTime =
                    '${item.time.hour.toString().padLeft(2, '0')}:${item.time.minute.toString().padLeft(2, '0')}';
                final isDup = _isDuplicate(item.candidate.name);

                return Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CheckboxListTile(
                          contentPadding: EdgeInsets.zero,
                          value: item.selected,
                          onChanged: (val) {
                            HapticFeedback.selectionClick();
                            setState(() => item.selected = val ?? false);
                          },
                          title: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  item.candidate.name,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              if (isDup)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: const Color(0xfffef3c7),
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(color: const Color(0xfff59e0b), width: 0.8),
                                  ),
                                  child: Text(
                                    '⚠️ ${strings.duplicateWarning}',
                                    style: const TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xffb45309),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          subtitle: item.candidate.instructions.isNotEmpty
                              ? Text(
                                  item.candidate.instructions,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                )
                              : null,
                        ),
                        const Divider(height: 12),
                        // Timing & Presets row
                        Wrap(
                          spacing: 6,
                          runSpacing: 4,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            // Custom Time Picker Chip
                            ActionChip(
                              avatar: const Icon(PathokIcons.alarm, size: 14),
                              label: Text(formattedTime),
                              onPressed: () async {
                                HapticFeedback.selectionClick();
                                final picked = await showTimePicker(
                                  context: context,
                                  initialTime: item.time,
                                  helpText: '${item.candidate.name} - ${strings.selectTime}',
                                );
                                if (picked != null) {
                                  setState(() => item.time = picked);
                                }
                              },
                            ),
                            // Quick Presets
                            ChoiceChip(
                              label: Text(strings.presetMorning),
                              selected: item.time.hour == 8 && item.time.minute == 0,
                              onSelected: (_) {
                                HapticFeedback.selectionClick();
                                setState(() => item.time = const TimeOfDay(hour: 8, minute: 0));
                              },
                            ),
                            ChoiceChip(
                              label: Text(strings.presetNoon),
                              selected: item.time.hour == 13 && item.time.minute == 30,
                              onSelected: (_) {
                                HapticFeedback.selectionClick();
                                setState(() => item.time = const TimeOfDay(hour: 13, minute: 30));
                              },
                            ),
                            ChoiceChip(
                              label: Text(strings.presetNight),
                              selected: item.time.hour == 21 && item.time.minute == 30,
                              onSelected: (_) {
                                HapticFeedback.selectionClick();
                                setState(() => item.time = const TimeOfDay(hour: 21, minute: 30));
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(strings.cancel),
        ),
        FilledButton(
          onPressed: selectedCount == 0
              ? null
              : () {
                  HapticFeedback.mediumImpact();
                  final reminders = _items
                      .where((i) => i.selected)
                      .map((i) => MedicineReminder(
                            medicineName: i.candidate.name,
                            instructions: i.candidate.instructions,
                            hour: i.time.hour,
                            minute: i.time.minute,
                            confirmedAt: DateTime.now(),
                          ))
                      .toList();
                  Navigator.pop(context, reminders);
                },
          child: Text(
            selectedCount == 0
                ? strings.confirm
                : '${strings.scheduleReminder} ($selectedCount)',
          ),
        ),
      ],
    );
  }
}
