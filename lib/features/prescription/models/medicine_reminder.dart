import 'dart:math';

class MedicineReminder {
  MedicineReminder({
    String? id,
    required this.medicineName,
    required this.instructions,
    required this.hour,
    required this.minute,
    this.lastTakenDate,
    DateTime? confirmedAt,
  })  : id = id ?? _generateId(),
        confirmedAt = confirmedAt ?? DateTime.now();

  final String id;
  final String medicineName;
  final String instructions;
  final int hour;
  final int minute;
  final String? lastTakenDate;
  final DateTime confirmedAt;

  static String _generateId() {
    final random = Random.secure();
    final values = List<int>.generate(16, (i) => random.nextInt(256));
    values[6] = (values[6] & 0x0f) | 0x40;
    values[8] = (values[8] & 0x3f) | 0x80;
    return values.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  }

  /// Whether the user has marked this dose as taken today
  bool get isTakenToday {
    if (lastTakenDate == null) return false;
    final now = DateTime.now();
    final todayStr = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    return lastTakenDate == todayStr;
  }

  MedicineReminder copyWith({
    int? hour,
    int? minute,
    String? lastTakenDate,
    bool clearLastTaken = false,
  }) =>
      MedicineReminder(
        id: id,
        medicineName: medicineName,
        instructions: instructions,
        hour: hour ?? this.hour,
        minute: minute ?? this.minute,
        lastTakenDate: clearLastTaken ? null : (lastTakenDate ?? this.lastTakenDate),
        confirmedAt: confirmedAt,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'medicineName': medicineName,
        'instructions': instructions,
        'hour': hour,
        'minute': minute,
        if (lastTakenDate != null) 'lastTakenDate': lastTakenDate,
        'confirmedAt': confirmedAt.toIso8601String(),
      };

  factory MedicineReminder.fromJson(Map<String, dynamic> json) {
    return MedicineReminder(
      id: json['id'] as String?,
      medicineName: json['medicineName'] as String? ?? 'ওষুধ',
      instructions: json['instructions'] as String? ?? '',
      hour: json['hour'] as int? ?? 9,
      minute: json['minute'] as int? ?? 0,
      lastTakenDate: json['lastTakenDate'] as String?,
      confirmedAt: DateTime.tryParse(json['confirmedAt'] as String? ?? ''),
    );
  }
}
