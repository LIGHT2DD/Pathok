import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/constants/pathok_icons.dart';
import '../../../core/constants/voice_profiles.dart';
import '../../../core/localization/app_strings.dart';
import '../../prescription/models/medicine_reminder.dart';

class SettingsTab extends StatefulWidget {
  const SettingsTab({
    required this.reminders,
    required this.onDeleteAllData,
    required this.isDarkMode,
    required this.onThemeChanged,
    required this.onDeleteReminder,
    required this.onEditReminder,
    required this.onExportBackup,
    required this.onImportBackup,
    required this.onLanguageChanged,
    super.key,
  });

  final List<MedicineReminder> reminders;
  final Future<void> Function() onDeleteAllData;
  final bool isDarkMode;
  final ValueChanged<bool> onThemeChanged;
  final ValueChanged<MedicineReminder> onDeleteReminder;
  final ValueChanged<MedicineReminder> onEditReminder;
  final VoidCallback onExportBackup;
  final VoidCallback onImportBackup;
  final ValueChanged<bool> onLanguageChanged;

  @override
  State<SettingsTab> createState() => _SettingsTabState();
}

class _SettingsTabState extends State<SettingsTab> {
  final FlutterTts _tts = FlutterTts();
  String _selectedVoiceId = 'female_natural';

  @override
  void initState() {
    super.initState();
    _loadVoiceProfile();
  }

  @override
  void dispose() {
    _tts.stop();
    super.dispose();
  }

  Future<void> _loadVoiceProfile() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _selectedVoiceId = prefs.getString('tts_voice_profile') ?? 'female_natural';
      });
    }
  }

  Future<void> _selectVoice(VoiceProfile profile, AppStrings strings) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('tts_voice_profile', profile.id);
    if (mounted) {
      setState(() => _selectedVoiceId = profile.id);
    }

    // Play a preview utterance in the selected voice
    try {
      await _tts.stop();
      final targetLang = strings.isEnglish ? 'en-US' : 'bn-BD';
      await _tts.setLanguage(targetLang);
      await _tts.setPitch(profile.pitch);
      await _tts.setSpeechRate(profile.rate);
      await _tts.speak(strings.voiceTestSample);
    } catch (_) {}
  }

  Widget _buildIconContainer(IconData icon, Color color, Color bgColor) {
    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(icon, color: color, size: 20),
    );
  }

  void _showVoicePicker(BuildContext context) {
    final strings = AppStrings.of(context);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.record_voice_over, color: theme.colorScheme.primary),
                        const SizedBox(width: 10),
                        Text(
                          strings.readingVoice,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      strings.readingVoiceSubtitle,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ...VoiceProfile.allProfiles.map((profile) {
                      final isSelected = profile.id == _selectedVoiceId;
                      final isFemale = profile.gender == 'female';

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: () {
                            HapticFeedback.selectionClick();
                            _selectVoice(profile, strings);
                            setModalState(() {});
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? theme.colorScheme.primary.withAlpha(isDark ? 40 : 20)
                                  : (isDark ? const Color(0xff1e293b) : Colors.white),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isSelected
                                    ? theme.colorScheme.primary
                                    : (isDark ? const Color(0xff334155) : const Color(0xffe2e8f0)),
                                width: isSelected ? 1.5 : 1,
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: isFemale
                                        ? const Color(0xfffce7f3)
                                        : const Color(0xffdbeafe),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    isFemale ? Icons.female : Icons.male,
                                    size: 20,
                                    color: isFemale ? const Color(0xffdb2777) : const Color(0xff2563eb),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        profile.localizedName(strings.isEnglish),
                                        style: TextStyle(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 15,
                                          color: isSelected ? theme.colorScheme.primary : null,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        profile.localizedDescription(strings.isEnglish),
                                        style: theme.textTheme.bodySmall?.copyWith(
                                          color: theme.colorScheme.onSurfaceVariant,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                if (isSelected)
                                  Icon(Icons.check_circle, color: theme.colorScheme.primary, size: 22),
                              ],
                            ),
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final currentProfile = VoiceProfile.getById(_selectedVoiceId);

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 760),
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
            children: [
              // Header
              Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.asset(
                      'assets/logo.png',
                      width: 46,
                      height: 46,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Text(
                    strings.navSettings,
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.4,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Group 1: Preferences
              Text(
                strings.preferences,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.2,
                ),
              ),
              const SizedBox(height: 10),
              Card(
                child: Column(
                  children: [
                    SwitchListTile(
                      secondary: _buildIconContainer(
                        PathokIcons.language,
                        const Color(0xff2563eb),
                        isDark ? const Color(0xff1e3a8a) : const Color(0xffeff6ff),
                      ),
                      title: Text(strings.language, style: const TextStyle(fontWeight: FontWeight.w600)),
                      subtitle: Text(strings.currentLanguage),
                      value: strings.isEnglish,
                      onChanged: (val) {
                        HapticFeedback.selectionClick();
                        widget.onLanguageChanged(val);
                      },
                    ),
                    const Divider(height: 1, indent: 64),
                    SwitchListTile(
                      secondary: _buildIconContainer(
                        widget.isDarkMode ? PathokIcons.moon : PathokIcons.sun,
                        const Color(0xff8b5cf6),
                        isDark ? const Color(0xff4c1d95) : const Color(0xfff5f3ff),
                      ),
                      title: Text(strings.darkMode, style: const TextStyle(fontWeight: FontWeight.w600)),
                      subtitle: Text(strings.darkModeSubtitle),
                      value: widget.isDarkMode,
                      onChanged: (val) {
                        HapticFeedback.selectionClick();
                        widget.onThemeChanged(val);
                      },
                    ),
                    const Divider(height: 1, indent: 64),
                    // Voice Selection (Male & Female Choices)
                    ListTile(
                      leading: _buildIconContainer(
                        Icons.record_voice_over,
                        const Color(0xffea580c),
                        isDark ? const Color(0xff7c2d12) : const Color(0xfffff7ed),
                      ),
                      title: Text(strings.readingVoice, style: const TextStyle(fontWeight: FontWeight.w600)),
                      subtitle: Text(currentProfile.localizedName(strings.isEnglish)),
                      trailing: const Icon(PathokIcons.chevronRight, size: 18),
                      onTap: () {
                        HapticFeedback.lightImpact();
                        _showVoicePicker(context);
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),

              // Group 2: Reminders
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    strings.remindersTitle,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.2,
                    ),
                  ),
                  if (widget.reminders.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.secondary.withAlpha(25),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${widget.reminders.length}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: theme.colorScheme.secondary,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 10),
              if (widget.reminders.isEmpty)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Center(
                      child: Text(
                        strings.noRemindersYet,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ),
                )
              else
                ...widget.reminders.map(
                  (reminder) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Card(
                      child: ListTile(
                        leading: _buildIconContainer(
                          PathokIcons.alarm,
                          const Color(0xffd97706),
                          isDark ? const Color(0xff78350f) : const Color(0xfffef3c7),
                        ),
                        title: Text(
                          reminder.medicineName,
                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                        ),
                        subtitle: Text(
                          '${reminder.hour.toString().padLeft(2, '0')}:${reminder.minute.toString().padLeft(2, '0')} • ${reminder.instructions.isNotEmpty ? reminder.instructions : strings.verifyInstructions}',
                        ),
                        trailing: IconButton(
                          tooltip: strings.delete,
                          icon: Icon(PathokIcons.trash, color: theme.colorScheme.error, size: 20),
                          onPressed: () {
                            HapticFeedback.lightImpact();
                            widget.onDeleteReminder(reminder);
                          },
                        ),
                        onTap: () {
                          HapticFeedback.selectionClick();
                          widget.onEditReminder(reminder);
                        },
                      ),
                    ),
                  ),
                ),
              const SizedBox(height: 28),

              // Group 3: Privacy & Security
              Text(
                strings.privacyAccessibility,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.2,
                ),
              ),
              const SizedBox(height: 10),
              Card(
                child: Column(
                  children: [
                    ListTile(
                      leading: _buildIconContainer(
                        PathokIcons.wifi,
                        const Color(0xff0284c7),
                        isDark ? const Color(0xff0c4a6e) : const Color(0xfff0f9ff),
                      ),
                      title: Text(strings.offlineMode, style: const TextStyle(fontWeight: FontWeight.w600)),
                      subtitle: Text(strings.offlineModeSubtitle),
                    ),
                    const Divider(height: 1, indent: 64),
                    ListTile(
                      leading: _buildIconContainer(
                        Icons.shield_outlined,
                        const Color(0xff2563eb),
                        isDark ? const Color(0xff1e3a8a) : const Color(0xffeff6ff),
                      ),
                      title: Text(strings.exportEncryptedBackup, style: const TextStyle(fontWeight: FontWeight.w600)),
                      subtitle: Text(strings.exportBackupSubtitle),
                      onTap: () {
                        HapticFeedback.lightImpact();
                        widget.onExportBackup();
                      },
                    ),
                    const Divider(height: 1, indent: 64),
                    ListTile(
                      leading: _buildIconContainer(
                        Icons.restore_page_outlined,
                        const Color(0xff059669),
                        isDark ? const Color(0xff064e3b) : const Color(0xffecfdf5),
                      ),
                      title: Text(strings.restoreBackup, style: const TextStyle(fontWeight: FontWeight.w600)),
                      subtitle: Text(strings.restoreBackupSubtitle),
                      onTap: () {
                        HapticFeedback.lightImpact();
                        widget.onImportBackup();
                      },
                    ),
                    const Divider(height: 1, indent: 64),
                    ListTile(
                      leading: _buildIconContainer(
                        PathokIcons.trash,
                        theme.colorScheme.error,
                        isDark ? const Color(0xff450a0a) : const Color(0xfffef2f2),
                      ),
                      title: Text(
                        strings.deleteAllData,
                        style: TextStyle(
                          color: theme.colorScheme.error,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      onTap: () {
                        HapticFeedback.heavyImpact();
                        widget.onDeleteAllData();
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // About Section
              AboutListTile(
                icon: const Icon(Icons.info_outline),
                applicationName: strings.appName,
                applicationVersion: '1.0.0',
                applicationLegalese: strings.tagline,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
