class MedicineCandidate {
  const MedicineCandidate({
    required this.name,
    required this.instructions,
    this.dosage = '',
  });

  final String name;
  final String instructions;
  final String dosage;
}

