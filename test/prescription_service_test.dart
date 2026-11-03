import 'package:flutter_test/flutter_test.dart';
import 'package:pathok/prescription_service.dart';

void main() {
  test('extracts only medicine-like lines', () {
    final result = PrescriptionService().extract(
      'Take paracetamol 500 mg twice daily\nDrink water\nAmoxicillin 250mg',
    );

    expect(result, hasLength(2));
    expect(result.first.name, contains('paracetamol'));
    expect(result.last.name, contains('Amoxicillin'));
  });
}
