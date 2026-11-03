import 'dart:convert';

import '../../../core/security/secure_data_store.dart';
import '../models/medicine_candidate.dart';
import '../models/medicine_reminder.dart';

class PrescriptionService {
  // Pre-compiled static regexes to eliminate regex compilation overhead on repeated analysis
  static final RegExp _linesPattern = RegExp(r'[\r\n]+');

  static final RegExp _medicineFormPattern = RegExp(
    r'(?:\b(?:tab|tablet|cap|capsule|syrup|syr|inj|drops?|suspension)\b|'
    r'(?:\d+(?:\.\d+)?\s*(?:mg|ml|mcg|gm|iu)\b)|'
    r'(?:ট্যাবলেট|ক্যাপসুল|সিরাপ|ড্রপ|ইনজেকশন|মিগ্রা|মিলি))',
    caseSensitive: false,
  );

  static final RegExp _dosagePattern = RegExp(
    r'(?:[0-2]\s*[\+\-]\s*[0-2]\s*[\+\-]\s*[0-2]|[০-২]\s*[\+\-]\s*[০-২]\s*[\+\-]\s*[০-২]|'
    r'(?:\d+|এক|দুই|তিন|চার)\s*বার|খাবার\s*(?:আগে|পরে))',
    caseSensitive: false,
  );

  static final RegExp _bulletPattern = RegExp(r'^(?:[0-9০-৯]+[\.\)\-]|[\•\-\*])\s*');

  /// Extracts medicine candidates with conservative heuristics to avoid false positives
  List<MedicineCandidate> extract(String text) {
    final candidates = <MedicineCandidate>[];
    final lines = text.split(_linesPattern);

    for (final rawLine in lines) {
      final line = rawLine.trim();
      if (line.isEmpty || line.length < 3) continue;

      // Check if line contains a strong pharmaceutical keyword or dosage pattern
      final hasFormOrStrength = _medicineFormPattern.hasMatch(line);
      final hasDosage = _dosagePattern.hasMatch(line);

      if (hasFormOrStrength || (hasDosage && line.length > 5)) {
        // Clean up common bullet points or numbering at the start
        final cleanedName = line.replaceFirst(_bulletPattern, '');

        // Extract dosage hint if available
        final dosageMatch = _dosagePattern.firstMatch(line);
        final dosageHint = dosageMatch != null ? dosageMatch.group(0)! : 'ব্যবহারবিধি প্যাকেটে দেখুন';

        candidates.add(
          MedicineCandidate(
            name: cleanedName,
            instructions: dosageHint,
            dosage: dosageHint,
          ),
        );
      }
    }

    return candidates;
  }

  Future<List<MedicineReminder>> loadReminders() async {
    final payload = await SecureDataStore.instance.read();
    final rawList = payload['medicine_reminders'] as List<dynamic>? ?? <dynamic>[];

    return rawList.map((value) {
      if (value is String) {
        final decoded = jsonDecode(value) as Map<String, dynamic>;
        return MedicineReminder.fromJson(decoded);
      }
      return MedicineReminder.fromJson(value as Map<String, dynamic>);
    }).toList();
  }

  Future<void> saveReminder(MedicineReminder reminder) async {
    final payload = await SecureDataStore.instance.read();
    final values = (payload['medicine_reminders'] as List<dynamic>? ?? <dynamic>[])
        .toList();

    values.add(reminder.toJson());
    payload['medicine_reminders'] = values;
    await SecureDataStore.instance.write(payload);
  }

  Future<void> deleteReminder(MedicineReminder reminder) async {
    final payload = await SecureDataStore.instance.read();
    final values = (payload['medicine_reminders'] as List<dynamic>? ?? <dynamic>[])
        .where((value) {
          final decoded = value is String
              ? MedicineReminder.fromJson(jsonDecode(value) as Map<String, dynamic>)
              : MedicineReminder.fromJson(value as Map<String, dynamic>);

          if (reminder.id.isNotEmpty && decoded.id.isNotEmpty) {
            return decoded.id != reminder.id;
          }
          return decoded.medicineName != reminder.medicineName ||
              decoded.hour != reminder.hour ||
              decoded.minute != reminder.minute;
        })
        .toList();

    payload['medicine_reminders'] = values;
    await SecureDataStore.instance.write(payload);
  }

  Future<void> replaceReminder(
    MedicineReminder previous,
    MedicineReminder replacement,
  ) async {
    await deleteReminder(previous);
    await saveReminder(replacement);
  }

  /// Toggles today's taken status for a reminder
  Future<MedicineReminder> toggleReminderTaken(MedicineReminder reminder) async {
    final now = DateTime.now();
    final todayStr = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

    final updated = reminder.isTakenToday
        ? reminder.copyWith(clearLastTaken: true)
        : reminder.copyWith(lastTakenDate: todayStr);

    await replaceReminder(reminder, updated);
    return updated;
  }
}
