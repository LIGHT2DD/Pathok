import 'dart:convert';

import 'secure_data_store.dart';

class MedicineCandidate {
  const MedicineCandidate({
    required this.name,
    required this.instructions,
  });

  final String name;
  final String instructions;
}

class MedicineReminder {
  const MedicineReminder({
    required this.medicineName,
    required this.instructions,
    required this.hour,
    required this.minute,
    required this.confirmedAt,
  });

  final String medicineName;
  final String instructions;
  final int hour;
  final int minute;
  final DateTime confirmedAt;

  Map<String, dynamic> toJson() => {
        'medicineName': medicineName,
        'instructions': instructions,
        'hour': hour,
        'minute': minute,
        'confirmedAt': confirmedAt.toIso8601String(),
      };

  factory MedicineReminder.fromJson(Map<String, dynamic> json) {
    return MedicineReminder(
      medicineName: json['medicineName'] as String? ?? 'ওষুধ',
      instructions: json['instructions'] as String? ?? '',
      hour: json['hour'] as int? ?? 9,
      minute: json['minute'] as int? ?? 0,
      confirmedAt: DateTime.tryParse(json['confirmedAt'] as String? ?? '') ??
          DateTime.now(),
    );
  }
}

class PrescriptionService {
  List<MedicineCandidate> extract(String text) {
    final candidates = <MedicineCandidate>[];
    for (final rawLine in text.split(RegExp(r'[\r\n]+'))) {
      final line = rawLine.trim();
      if (line.isEmpty || line.length < 3) continue;
      final looksLikeMedicine = RegExp(
        r'(?:mg|ml|mcg|tablet|tab|capsule|cap|syrup|দিন|বার)\b',
        caseSensitive: false,
      ).hasMatch(line);
      if (looksLikeMedicine) {
        candidates.add(MedicineCandidate(name: line, instructions: 'ব্যবহার যাচাই করুন'));
      }
    }
    return candidates;
  }

  Future<List<MedicineReminder>> loadReminders() async {
    final payload = await SecureDataStore.instance.read();
    final values = (payload['medicine_reminders'] as List<dynamic>? ?? <dynamic>[])
        .map((value) => value as String)
        .map(
          (value) => MedicineReminder.fromJson(
            jsonDecode(value) as Map<String, dynamic>,
          ),
        )
        .toList();
    return values;
  }

  Future<void> saveReminder(MedicineReminder reminder) async {
    final payload = await SecureDataStore.instance.read();
    final values = (payload['medicine_reminders'] as List<dynamic>? ?? <dynamic>[])
        .map((value) => value as String)
        .toList();
    values.add(jsonEncode(reminder.toJson()));
    payload['medicine_reminders'] = values;
    await SecureDataStore.instance.write(payload);
  }

  Future<void> deleteReminder(MedicineReminder reminder) async {
    final payload = await SecureDataStore.instance.read();
    final values = (payload['medicine_reminders'] as List<dynamic>? ?? <dynamic>[])
        .map((value) => value as String)
        .where((value) {
          final decoded = MedicineReminder.fromJson(
            jsonDecode(value) as Map<String, dynamic>,
          );
          return decoded.medicineName != reminder.medicineName ||
              decoded.hour != reminder.hour ||
              decoded.minute != reminder.minute ||
              decoded.confirmedAt != reminder.confirmedAt;
        })
        .toList();
    payload['medicine_reminders'] = values;
    await SecureDataStore.instance.write(payload);
  }
}
