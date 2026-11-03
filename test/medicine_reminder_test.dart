import 'package:flutter_test/flutter_test.dart';
import 'package:pathok/features/prescription/models/medicine_reminder.dart';

void main() {
  group('MedicineReminder Model', () {
    test('generates unique identifier and preserves values in json', () {
      final reminder = MedicineReminder(
        medicineName: 'Paracetamol 500mg',
        instructions: '1+0+1 খাবার পর',
        hour: 14,
        minute: 30,
      );

      expect(reminder.id, isNotEmpty);
      expect(reminder.hour, equals(14));
      expect(reminder.minute, equals(30));

      final json = reminder.toJson();
      final restored = MedicineReminder.fromJson(json);

      expect(restored.id, equals(reminder.id));
      expect(restored.medicineName, equals('Paracetamol 500mg'));
      expect(restored.instructions, equals('1+0+1 খাবার পর'));
      expect(restored.hour, equals(14));
      expect(restored.minute, equals(30));
    });

    test('copyWith properly modifies time values while keeping id intact', () {
      final initial = MedicineReminder(
        id: 'reminder-abc-123',
        medicineName: 'Omeprazole 20mg',
        instructions: 'খাবার আগে',
        hour: 8,
        minute: 0,
      );

      final updated = initial.copyWith(hour: 20, minute: 15);

      expect(updated.id, equals('reminder-abc-123'));
      expect(updated.medicineName, equals('Omeprazole 20mg'));
      expect(updated.hour, equals(20));
      expect(updated.minute, equals(15));
    });

    test('isTakenToday correctly detects today date tracking', () {
      final now = DateTime.now();
      final todayStr = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

      final pending = MedicineReminder(
        medicineName: 'Napa',
        instructions: 'খাবার পর',
        hour: 8,
        minute: 0,
      );
      expect(pending.isTakenToday, isFalse);

      final taken = pending.copyWith(lastTakenDate: todayStr);
      expect(taken.isTakenToday, isTrue);

      final cleared = taken.copyWith(clearLastTaken: true);
      expect(cleared.isTakenToday, isFalse);
    });
  });
}
