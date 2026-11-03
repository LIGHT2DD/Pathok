class MedicineCandidate {
  const MedicineCandidate({
    required this.name,
    required this.instructions,
  });

  final String name;
  final String instructions;
}

class PrescriptionService {
  List<MedicineCandidate> extract(String text) {
    final candidates = <MedicineCandidate>[];
    for (final rawLine in text.split(RegExp(r'[\r\n]+'))) {
      final line = rawLine.trim();
      if (line.isEmpty || line.length < 3) continue;
      final looksLikeMedicine = RegExp(
        r'\b(?:mg|ml|mcg|tablet|tab|capsule|cap|syrup|দিন|বার)\b',
        caseSensitive: false,
      ).hasMatch(line);
      if (looksLikeMedicine) {
        candidates.add(MedicineCandidate(name: line, instructions: 'ব্যবহার যাচাই করুন'));
      }
    }
    return candidates;
  }
}
