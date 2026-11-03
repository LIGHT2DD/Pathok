class VoiceProfile {
  const VoiceProfile({
    required this.id,
    required this.nameEn,
    required this.nameBn,
    required this.gender,
    required this.pitch,
    required this.rate,
    required this.descriptionEn,
    required this.descriptionBn,
  });

  final String id;
  final String nameEn;
  final String nameBn;
  final String gender; // 'female' or 'male'
  final double pitch;
  final double rate;
  final String descriptionEn;
  final String descriptionBn;

  String localizedName(bool isEnglish) => isEnglish ? nameEn : nameBn;
  String localizedDescription(bool isEnglish) => isEnglish ? descriptionEn : descriptionBn;

  static const List<VoiceProfile> allProfiles = [
    VoiceProfile(
      id: 'female_natural',
      nameEn: 'Female (Natural & Clear)',
      nameBn: 'নারী কণ্ঠ (স্বাভাবিক ও স্পষ্ট)',
      gender: 'female',
      pitch: 1.10,
      rate: 0.45,
      descriptionEn: 'Balanced, warm, and easy to understand',
      descriptionBn: 'সহজে বোঝার উপযোগী স্পষ্ট কণ্ঠ',
    ),
    VoiceProfile(
      id: 'male_deep',
      nameEn: 'Male (Deep & Resonant)',
      nameBn: 'পুরুষ কণ্ঠ (গম্ভীর ও বলিষ্ঠ)',
      gender: 'male',
      pitch: 0.82,
      rate: 0.44,
      descriptionEn: 'Deep tone, ideal for formal reports & news',
      descriptionBn: 'গম্ভীর ও গম্ভীর সুর, দীর্ঘ নথি পাঠের জন্য উপযোগী',
    ),
    VoiceProfile(
      id: 'female_gentle',
      nameEn: 'Female (Gentle & Smooth)',
      nameBn: 'নারী কণ্ঠ (কোমল ও শান্ত)',
      gender: 'female',
      pitch: 1.25,
      rate: 0.46,
      descriptionEn: 'Soft melody, pleasant for long reading',
      descriptionBn: 'কোমল ও শান্ত পাঠের কণ্ঠ',
    ),
    VoiceProfile(
      id: 'male_steady',
      nameEn: 'Male (Steady & Calm)',
      nameBn: 'পুরুষ কণ্ঠ (শান্ত ও স্বাভাবিক)',
      gender: 'male',
      pitch: 0.90,
      rate: 0.45,
      descriptionEn: 'Calm, conversational male cadence',
      descriptionBn: 'স্বাভাবিক ও শান্ত পুরুষ কণ্ঠ',
    ),
  ];

  static VoiceProfile getById(String? id) {
    return allProfiles.firstWhere(
      (p) => p.id == id,
      orElse: () => allProfiles.first,
    );
  }
}

