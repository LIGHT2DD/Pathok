import 'dart:io';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:local_auth/local_auth.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:share_plus/share_plus.dart';

import 'ocr_service.dart';
import 'notification_service.dart';
import 'prescription_service.dart';
import 'secure_data_store.dart';

class PathokIcons {
  const PathokIcons._();

  static const _fontFamily = 'TablerIcons';
  static const _fontPackage = 'tabler_icons';
  static const home = IconData(
    0xeac1,
    fontFamily: _fontFamily,
    fontPackage: _fontPackage,
  );
  static const history = IconData(
    0xebea,
    fontFamily: _fontFamily,
    fontPackage: _fontPackage,
  );
  static const settings = IconData(
    0xeb20,
    fontFamily: _fontFamily,
    fontPackage: _fontPackage,
  );
  static const volume = IconData(
    0xeb50,
    fontFamily: _fontFamily,
    fontPackage: _fontPackage,
  );
  static const camera = IconData(
    0xea54,
    fontFamily: _fontFamily,
    fontPackage: _fontPackage,
  );
  static const fileInvoice = IconData(
    0xeb67,
    fontFamily: _fontFamily,
    fontPackage: _fontPackage,
  );
  static const photo = IconData(
    0xeb0a,
    fontFamily: _fontFamily,
    fontPackage: _fontPackage,
  );
  static const fileText = IconData(
    0xeaa2,
    fontFamily: _fontFamily,
    fontPackage: _fontPackage,
  );
  static const chevronRight = IconData(
    0xea61,
    fontFamily: _fontFamily,
    fontPackage: _fontPackage,
  );
  static const arrowRight = IconData(
    0xea1f,
    fontFamily: _fontFamily,
    fontPackage: _fontPackage,
  );
  static const fingerprint = IconData(
    0xebd1,
    fontFamily: _fontFamily,
    fontPackage: _fontPackage,
  );
  static const lock = IconData(
    0xeae2,
    fontFamily: _fontFamily,
    fontPackage: _fontPackage,
  );
  static const scan = IconData(
    0xebc8,
    fontFamily: _fontFamily,
    fontPackage: _fontPackage,
  );
  static const pill = IconData(
    0xec44,
    fontFamily: _fontFamily,
    fontPackage: _fontPackage,
  );
  static const stop = IconData(
    0xed4a,
    fontFamily: _fontFamily,
    fontPackage: _fontPackage,
  );
  static const language = IconData(
    0xebbe,
    fontFamily: _fontFamily,
    fontPackage: _fontPackage,
  );
  static const alarm = IconData(
    0xea04,
    fontFamily: _fontFamily,
    fontPackage: _fontPackage,
  );
  static const trash = IconData(
    0xeb41,
    fontFamily: _fontFamily,
    fontPackage: _fontPackage,
  );
  static const wifi = IconData(
    0xeb52,
    fontFamily: _fontFamily,
    fontPackage: _fontPackage,
  );
  static const accessible = IconData(
    0xeba9,
    fontFamily: _fontFamily,
    fontPackage: _fontPackage,
  );
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ReminderNotificationService.instance.initialize();
  runApp(const PathokApp());
}

class PathokApp extends StatelessWidget {
  const PathokApp({super.key});

  @override
  Widget build(BuildContext context) {
    const navy = Color(0xff173b70);
    const mint = Color(0xff2b8a78);
    final colorScheme = ColorScheme.fromSeed(
      seedColor: navy,
      primary: navy,
      secondary: mint,
      brightness: Brightness.light,
    );
    return MaterialApp(
      title: 'পাঠক',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: colorScheme,
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xfff6f8fc),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xfff6f8fc),
          surfaceTintColor: Colors.transparent,
          elevation: 0,
        ),
        cardTheme: CardThemeData(
          elevation: 0,
          margin: EdgeInsets.zero,
          color: Colors.white,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: const BorderSide(color: Color(0xffe6ebf2)),
          ),
        ),
        dialogTheme: DialogThemeData(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 24,
            vertical: 24,
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Color(0xffd9e1ec)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Color(0xffd9e1ec)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: colorScheme.primary, width: 2),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 18,
            vertical: 16,
          ),
        ),
      ),
      home: const AppRoot(),
    );
  }
}

class AppRoot extends StatefulWidget {
  const AppRoot({super.key});

  @override
  State<AppRoot> createState() => _AppRootState();
}

class _AppRootState extends State<AppRoot> {
  bool? _onboardingComplete;
  bool _locked = false;
  bool _english = false;

  @override
  void initState() {
    super.initState();
    _loadPreference();
  }

  Future<void> _loadPreference() async {
    final preferences = await SharedPreferences.getInstance();
    final lockEnabled = preferences.getBool('app_lock_enabled') ?? false;
    var locked = false;
    if (lockEnabled) {
      locked = !(await LocalAuthentication().authenticate(
        localizedReason: 'পাঠকের স্থানীয় নথি খুলতে পরিচয় যাচাই করুন',
        biometricOnly: false,
        persistAcrossBackgrounding: true,
      ));
    }
    if (mounted) {
      setState(() {
        _onboardingComplete =
            preferences.getBool('onboarding_complete') ?? false;
        _locked = locked;
        _english = preferences.getBool('english_language') ?? false;
      });
    }
  }

  Future<void> _completeOnboarding() async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setBool('onboarding_complete', true);
    if (mounted) {
      setState(() => _onboardingComplete = true);
    }
  }

  Future<void> _setEnglish(bool english) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setBool('english_language', english);
    if (mounted) setState(() => _english = english);
  }

  @override
  Widget build(BuildContext context) {
    final child = _onboardingComplete == null
        ? const Scaffold(body: Center(child: CircularProgressIndicator()))
        : _locked
        ? LockScreen(onUnlock: _loadPreference)
        : _onboardingComplete!
        ? HomeScreen(onLanguageChanged: _setEnglish)
        : OnboardingScreen(onComplete: _completeOnboarding);
    return _PathokLocale(english: _english, child: child);
  }
}

class _PathokLocale extends InheritedWidget {
  const _PathokLocale({required this.english, required super.child});

  final bool english;

  static bool of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_PathokLocale>()!.english;

  @override
  bool updateShouldNotify(_PathokLocale oldWidget) =>
      english != oldWidget.english;
}

class PathokStrings {
  const PathokStrings(this.english);

  final bool english;

  String get cancel => english ? 'Cancel' : 'বাতিল';
  String get save => english ? 'Save' : 'সংরক্ষণ';
  String get delete => english ? 'Delete' : 'মুছুন';
  String get noText =>
      english ? 'No text entered.' : 'কোনো লেখা যোগ করা হয়নি।';
  String get exportedPdf => english ? 'PDF exported.' : 'PDF সংরক্ষণ হয়েছে।';
  String get deleteAll =>
      english ? 'Delete all local data' : 'সব স্থানীয় তথ্য মুছুন';

  static PathokStrings of(BuildContext context) =>
      PathokStrings(_PathokLocale.of(context));
}

class _BrandMark extends StatelessWidget {
  const _BrandMark({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'পাঠক',
      image: true,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(size * .24),
        child: Image.asset(
          'assets/logo.png',
          width: size,
          height: size,
          fit: BoxFit.cover,
        ),
      ),
    );
  }
}

class LockScreen extends StatelessWidget {
  const LockScreen({required this.onUnlock, super.key});

  final Future<void> Function() onUnlock;

  @override
  Widget build(BuildContext context) {
    final english = _PathokLocale.of(context);
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const _BrandMark(size: 88),
              const SizedBox(height: 16),
              Text(
                english ? 'Pathok is locked' : 'পাঠক লক করা আছে',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: onUnlock,
                icon: const Icon(PathokIcons.fingerprint),
                label: Text(english ? 'Unlock' : 'আনলক করুন'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({required this.onComplete, super.key});

  final Future<void> Function() onComplete;

  @override
  Widget build(BuildContext context) {
    final english = _PathokLocale.of(context);
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: Row(
                  children: [
                    const _BrandMark(size: 56),
                    const SizedBox(width: 14),
                    Text(
                      english ? 'Pathok' : 'পাঠক',
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(
                            color: Theme.of(context).colorScheme.primary,
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),
              Semantics(
                header: true,
                child: Text(
                  english ? 'Read documents with ease' : 'সহজে নথি পড়ুন',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                english
                    ? 'Every document has a voice.'
                    : 'প্রতিটি নথির একটি কণ্ঠ আছে।',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 36),
              _OnboardingBenefit(
                icon: PathokIcons.scan,
                text: english
                    ? 'Scan images and read Bangla or English text'
                    : 'ছবি স্ক্যান করে বাংলা বা English লেখা পড়ুন',
              ),
              const SizedBox(height: 12),
              _OnboardingBenefit(
                icon: PathokIcons.volume,
                text: english
                    ? 'Listen to recognized text offline'
                    : 'Offline-এ শনাক্ত লেখা শুনুন',
              ),
              const SizedBox(height: 12),
              _OnboardingBenefit(
                icon: PathokIcons.lock,
                text: english
                    ? 'Keep your documents private on this device'
                    : 'নথি এই ডিভাইসেই ব্যক্তিগত রাখুন',
              ),
              const Spacer(),
              Text(
                english
                    ? 'No account or internet connection is required.'
                    : 'কোনো account বা internet connection প্রয়োজন নেই।',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 14),
              FilledButton.icon(
                onPressed: onComplete,
                icon: const Icon(PathokIcons.arrowRight),
                label: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(
                    english ? 'Get started' : 'শুরু করুন',
                    style: const TextStyle(fontSize: 18),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OnboardingBenefit extends StatelessWidget {
  const _OnboardingBenefit({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).colorScheme.primaryContainer,
          child: Icon(icon, color: Theme.of(context).colorScheme.primary),
        ),
        title: Text(text),
      ),
    );
  }
}

class _ResponsiveContent extends StatelessWidget {
  const _ResponsiveContent({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 760),
        child: child,
      ),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({required this.onLanguageChanged, super.key});

  final ValueChanged<bool> onLanguageChanged;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  final List<LocalDocument> _documents = [];
  final List<MedicineReminder> _reminders = [];
  final PrescriptionService _prescriptionService = PrescriptionService();
  bool _loading = true;
  bool _lockEnabled = false;

  @override
  void initState() {
    super.initState();
    _loadDocuments();
  }

  Future<void> _loadDocuments() async {
    final payload = await SecureDataStore.instance.read();
    final preferences = await SharedPreferences.getInstance();
    final values = (payload['documents'] as List<dynamic>? ?? <dynamic>[]).map(
      (value) => value as String,
    );
    _documents
      ..clear()
      ..addAll(
        values.map(
          (value) =>
              LocalDocument.fromJson(jsonDecode(value) as Map<String, dynamic>),
        ),
      );
    _reminders
      ..clear()
      ..addAll(await _prescriptionService.loadReminders());
    if (mounted) {
      setState(() {
        _lockEnabled = preferences.getBool('app_lock_enabled') ?? false;
        _loading = false;
      });
    }
  }

  Future<void> _saveDocuments() async {
    final payload = await SecureDataStore.instance.read();
    payload['documents'] = _documents
        .map((document) => jsonEncode(document.toJson()))
        .toList();
    await SecureDataStore.instance.write(payload);
  }

  Future<void> _deleteAllData() async {
    for (final document in _documents) {
      final file = File(document.sourcePath);
      if (await file.exists()) await file.delete();
    }
    _documents.clear();
    _reminders.clear();
    await SecureDataStore.instance.clear();
    await ReminderNotificationService.instance.cancelAll();
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final pages = [
      _HomeTab(
        documents: _documents,
        onCapture: () => _pickImage(ImageSource.camera),
        onImport: () => _pickImage(ImageSource.gallery),
        onImportPdf: _pickPdf,
        onOpen: _openDocument,
      ),
      HistoryTab(
        documents: _documents,
        onOpen: _openDocument,
        onRename: _renameDocument,
        onDelete: _deleteDocument,
      ),
      SettingsTab(
        reminders: _reminders,
        onDeleteAllData: _confirmDeleteAllData,
        lockEnabled: _lockEnabled,
        onLockChanged: _setLockEnabled,
        onDeleteReminder: _deleteReminder,
        onEditReminder: _editReminder,
        onExportBackup: _exportBackup,
        onImportBackup: _importBackup,
        onLanguageChanged: widget.onLanguageChanged,
      ),
    ];
    final english = _PathokLocale.of(context);
    return Scaffold(
      body: IndexedStack(index: _selectedIndex, children: pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) =>
            setState(() => _selectedIndex = index),
        destinations: [
          NavigationDestination(
            icon: const Icon(PathokIcons.home),
            label: english ? 'Home' : 'হোম',
          ),
          NavigationDestination(
            icon: const Icon(PathokIcons.history),
            label: english ? 'Documents' : 'নথি',
          ),
          NavigationDestination(
            icon: const Icon(PathokIcons.settings),
            label: english ? 'Settings' : 'সেটিংস',
          ),
        ],
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    final english = _PathokLocale.of(context);
    final file = await ImagePicker().pickImage(
      source: source,
      maxWidth: 2400,
      maxHeight: 2400,
      imageQuality: 92,
    );
    if (!mounted || file == null) return;
    final storedPath = await _copyToAppStorage(file.path);
    final document = LocalDocument(
      title: english
          ? 'New document ${_documents.length + 1}'
          : 'নতুন নথি ${_documents.length + 1}',
      sourcePath: storedPath,
      text: '',
      fileType: 'image',
    );
    setState(() => _documents.insert(0, document));
    await _saveDocuments();
    _openDocument(document);
  }

  Future<void> _pickPdf() async {
    final english = _PathokLocale.of(context);
    final files = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );
    if (!mounted || files.isEmpty || files.first.path == null) return;
    final storedPath = await _copyToAppStorage(files.first.path!);
    final document = LocalDocument(
      title: english
          ? 'PDF document ${_documents.length + 1}'
          : 'PDF নথি ${_documents.length + 1}',
      sourcePath: storedPath,
      text: '',
      fileType: 'pdf',
    );
    setState(() => _documents.insert(0, document));
    await _saveDocuments();
    _openDocument(document);
  }

  Future<String> _copyToAppStorage(String sourcePath) async {
    final directory = await getApplicationDocumentsDirectory();
    final extension = sourcePath.split('.').last;
    final target = File(
      '${directory.path}${Platform.pathSeparator}document_${DateTime.now().microsecondsSinceEpoch}.$extension',
    );
    await File(sourcePath).copy(target.path);
    return target.path;
  }

  void _openDocument(LocalDocument document) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => DocumentScreen(
          document: document,
          onChanged: () async {
            setState(() {});
            await _saveDocuments();
          },
          onExport: _exportDocument,
          onReminderSaved: (reminder) =>
              setState(() => _reminders.add(reminder)),
        ),
      ),
    );
  }

  Future<void> _exportDocument(LocalDocument document) async {
    final strings = PathokStrings.of(context);
    final directory = await getApplicationDocumentsDirectory();
    final output = File(
      '${directory.path}${Platform.pathSeparator}${document.title.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_')}.pdf',
    );
    final pdf = pw.Document();
    pdf.addPage(
      pw.Page(
        build: (_) => pw.Padding(
          padding: const pw.EdgeInsets.all(24),
          child: pw.Text(
            document.text.isEmpty ? strings.noText : document.text,
          ),
        ),
      ),
    );
    await output.writeAsBytes(await pdf.save());
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${strings.exportedPdf} ${output.path}')),
      );
    }
  }

  Future<void> _setLockEnabled(bool enabled) async {
    final preferences = await SharedPreferences.getInstance();
    if (enabled) {
      final authenticated = await LocalAuthentication().authenticate(
        localizedReason: 'অ্যাপ লক চালু করতে পরিচয় যাচাই করুন',
        biometricOnly: false,
        persistAcrossBackgrounding: true,
      );
      if (!authenticated || !mounted) return;
    }

    await preferences.setBool('app_lock_enabled', enabled);
    if (mounted) setState(() => _lockEnabled = enabled);
  }

  Future<void> _deleteReminder(MedicineReminder reminder) async {
    await _prescriptionService.deleteReminder(reminder);
    await ReminderNotificationService.instance.cancel(reminder);
    if (mounted) setState(() => _reminders.remove(reminder));
  }

  Future<void> _editReminder(MedicineReminder reminder) async {
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: reminder.hour, minute: reminder.minute),
      helpText: '${reminder.medicineName} - নতুন সময়',
    );
    if (time == null) return;
    final replacement = reminder.copyWith(hour: time.hour, minute: time.minute);
    await _prescriptionService.replaceReminder(reminder, replacement);
    await ReminderNotificationService.instance.cancel(reminder);
    await ReminderNotificationService.instance.schedule(replacement);
    if (mounted) {
      setState(() {
        final index = _reminders.indexOf(reminder);
        if (index >= 0) _reminders[index] = replacement;
      });
    }
  }

  Future<void> _exportBackup() async {
    final english = _PathokLocale.of(context);
    try {
      final encoded = await SecureDataStore.instance.exportEncryptedPayload();
      final path = await FilePicker.saveFile(
        dialogTitle: 'Pathok backup সংরক্ষণ করুন',
        fileName: 'pathok_backup.txt',
        bytes: utf8.encode(encoded),
      );
      if (mounted && path != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              english
                  ? 'Encrypted backup saved.'
                  : 'Encrypted backup সংরক্ষণ হয়েছে。',
            ),
          ),
        );
      }
    } on Exception catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              english
                  ? 'Backup could not be saved.'
                  : 'Backup সংরক্ষণ ব্যর্থ হয়েছে: $error',
            ),
          ),
        );
      }
    }
  }

  Future<void> _importBackup() async {
    final english = _PathokLocale.of(context);
    final files = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['txt', 'backup'],
    );
    if (!mounted || files.isEmpty || files.first.path == null) return;
    try {
      final selected = files.first;
      final content = await File(selected.path!).readAsString();
      await SecureDataStore.instance.importEncryptedPayload(content);
      await _loadDocuments();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              english ? 'Backup restored.' : 'Backup restore হয়েছে।',
            ),
          ),
        );
      }
    } on Exception catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              english
                  ? 'Backup could not be restored.'
                  : 'Backup restore ব্যর্থ হয়েছে: $error',
            ),
          ),
        );
      }
    }
  }

  Future<void> _renameDocument(LocalDocument document) async {
    final english = _PathokLocale.of(context);
    final controller = TextEditingController(text: document.title);
    final title = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(english ? 'Rename document' : 'নথির নাম পরিবর্তন করুন'),
        content: TextField(
          controller: controller,
          autofocus: true,
          textInputAction: TextInputAction.done,
          decoration: InputDecoration(
            labelText: english ? 'Document name' : 'নথির নাম',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(english ? 'Cancel' : 'বাতিল'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: Text(english ? 'Save' : 'সংরক্ষণ'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (title == null || title.isEmpty) return;
    setState(() => document.title = title);
    await _saveDocuments();
  }

  Future<void> _deleteDocument(LocalDocument document) async {
    final english = _PathokLocale.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(english ? 'Delete document?' : 'নথি মুছবেন?'),
        content: Text(
          english
              ? '"${document.title}" will be permanently deleted.'
              : '“${document.title}” স্থায়ীভাবে মুছে যাবে।',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(english ? 'Cancel' : 'বাতিল'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(english ? 'Delete' : 'মুছুন'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    final file = File(document.sourcePath);
    if (await file.exists()) await file.delete();
    setState(() => _documents.remove(document));
    await _saveDocuments();
  }

  Future<void> _confirmDeleteAllData() async {
    final english = _PathokLocale.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(english ? 'Delete all data?' : 'সব তথ্য মুছবেন?'),
        content: Text(
          english
              ? 'Saved documents, copied files, and medicine reminders will be permanently deleted.'
              : 'সংরক্ষিত নথি, কপি করা ফাইল এবং medicine reminder স্থায়ীভাবে মুছে যাবে।',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(english ? 'Cancel' : 'বাতিল'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(english ? 'Delete permanently' : 'স্থায়ীভাবে মুছুন'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await _deleteAllData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              english
                  ? 'All local data was deleted.'
                  : 'সব স্থানীয় তথ্য মুছে ফেলা হয়েছে।',
            ),
          ),
        );
      }
    }
  }
}

class _HomeTab extends StatelessWidget {
  const _HomeTab({
    required this.documents,
    required this.onCapture,
    required this.onImport,
    required this.onImportPdf,
    required this.onOpen,
  });

  final List<LocalDocument> documents;
  final VoidCallback onCapture;
  final VoidCallback onImport;
  final VoidCallback onImportPdf;
  final ValueChanged<LocalDocument> onOpen;

  @override
  Widget build(BuildContext context) {
    final english = _PathokLocale.of(context);
    return _ResponsiveContent(
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Row(
              children: [
                const _BrandMark(size: 48),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        english ? 'Welcome!' : 'শুভেচ্ছা!',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      Text(
                        english
                            ? 'Ready to listen to your documents?'
                            : 'আপনার নথি শুনতে প্রস্তুত?',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 28),
            Text(
              english ? 'Add a new document' : 'নতুন নথি যোগ করুন',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            _ActionCard(
              icon: PathokIcons.camera,
              title: english
                  ? 'Scan with camera'
                  : 'ক্যামেরা দিয়ে স্ক্যান করুন',
              subtitle: english
                  ? 'Take a photo of a printed document'
                  : 'ছাপা নথির ছবি তুলুন',
              onPressed: onCapture,
            ),
            const SizedBox(height: 12),
            _ActionCard(
              icon: PathokIcons.fileInvoice,
              title: english ? 'Choose a PDF' : 'PDF বেছে নিন',
              subtitle: english
                  ? 'Select a PDF from your device'
                  : 'ডিভাইস থেকে একটি PDF নিন',
              onPressed: onImportPdf,
            ),
            const SizedBox(height: 12),
            _ActionCard(
              icon: PathokIcons.photo,
              title: english ? 'Choose an image' : 'ছবি বেছে নিন',
              subtitle: english
                  ? 'Select an image from your gallery'
                  : 'গ্যালারি থেকে একটি ছবি নিন',
              onPressed: onImport,
            ),
            const SizedBox(height: 28),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  english ? 'Recent documents' : 'সাম্প্রতিক নথি',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                if (documents.isNotEmpty)
                  Text(
                    english
                        ? '${documents.length} documents'
                        : '${documents.length}টি নথি',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            if (documents.isEmpty)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(22),
                  child: Column(
                    children: [
                      Icon(
                        Icons.description_outlined,
                        size: 42,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        english
                            ? 'No documents yet.\nChoose an option above to begin.'
                            : 'এখনও কোনো নথি নেই।\nউপরের একটি অপশন দিয়ে শুরু করুন।',
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              )
            else
              ...documents
                  .take(3)
                  .map(
                    (document) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Card(
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 4,
                          ),
                          leading: CircleAvatar(
                            backgroundColor: Theme.of(
                              context,
                            ).colorScheme.primaryContainer,
                            child: Icon(
                              document.fileType == 'pdf'
                                  ? Icons.picture_as_pdf_outlined
                                  : PathokIcons.fileText,
                            ),
                          ),
                          title: Text(document.title),
                          subtitle: Text(
                            document.text.isEmpty
                                ? (english
                                      ? 'No text added'
                                      : 'লেখা যোগ করা হয়নি')
                                : (english
                                      ? 'Text has been edited'
                                      : 'লেখা সম্পাদনা করা হয়েছে'),
                          ),
                          trailing: const Icon(PathokIcons.chevronRight),
                          onTap: () => onOpen(document),
                        ),
                      ),
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  const _ActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onPressed,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  icon,
                  size: 30,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: Theme.of(context).textTheme.titleMedium),
                    Text(subtitle),
                  ],
                ),
              ),
              const Icon(PathokIcons.chevronRight),
            ],
          ),
        ),
      ),
    );
  }
}

class DocumentScreen extends StatefulWidget {
  const DocumentScreen({
    required this.document,
    required this.onChanged,
    required this.onExport,
    required this.onReminderSaved,
    super.key,
  });

  final LocalDocument document;
  final VoidCallback onChanged;
  final Future<void> Function(LocalDocument document) onExport;
  final ValueChanged<MedicineReminder> onReminderSaved;

  @override
  State<DocumentScreen> createState() => _DocumentScreenState();
}

class _DocumentScreenState extends State<DocumentScreen> {
  late final TextEditingController _controller;
  final FlutterTts _tts = FlutterTts();
  final OfflineOcrService _ocrService = OfflineOcrService();
  bool _speaking = false;
  bool _recognizing = false;
  final PrescriptionService _prescriptionService = PrescriptionService();

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.document.text);
  }

  @override
  void dispose() {
    _controller.dispose();
    _tts.stop();
    _ocrService.close();
    super.dispose();
  }

  Future<void> _recognizeText() async {
    if (widget.document.fileType != 'image') return;
    setState(() => _recognizing = true);
    try {
      final result = await _ocrService.recognize(widget.document.sourcePath);
      if (!result.quality.isUsable) {
        throw StateError(result.quality.message);
      }
      final text = result.text;
      if (text.isEmpty) {
        throw StateError('No text was detected in this image.');
      }
      _controller.text = text;
      widget.document.text = text;
      widget.onChanged();
      if (mounted) {
        final english = _PathokLocale.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              english
                  ? 'Text recognized. Confidence: ${result.confidenceLabel}'
                  : 'ছবির লেখা শনাক্ত হয়েছে। Confidence: ${result.confidenceLabel}',
            ),
          ),
        );
      }
    } on Exception catch (error) {
      if (mounted) {
        final english = _PathokLocale.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              english
                  ? 'OCR failed. Please try again.'
                  : 'OCR ব্যর্থ হয়েছে: $error',
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _recognizing = false);
    }
  }

  Future<void> _toggleSpeech() async {
    final english = _PathokLocale.of(context);
    if (_speaking) {
      await _tts.stop();
      if (mounted) setState(() => _speaking = false);
      return;
    }

    if (_controller.text.trim().isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              english
                  ? 'Add text before starting playback.'
                  : 'শোনার জন্য আগে লেখাটি যোগ করুন।',
            ),
          ),
        );
      }
      return;
    }
    await _tts.setLanguage(_PathokLocale.of(context) ? 'en-US' : 'bn-BD');
    await _tts.setSpeechRate(0.45);
    await _tts.speak(_controller.text);
    if (mounted) setState(() => _speaking = true);
  }

  Future<void> _showPrescriptionCandidates() async {
    final english = _PathokLocale.of(context);
    final candidates = _prescriptionService.extract(_controller.text);
    if (!mounted) return;
    if (candidates.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            english
                ? 'No possible medicine lines were found.'
                : 'সম্ভাব্য ওষুধের লাইন পাওয়া যায়নি।',
          ),
        ),
      );
      return;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(english ? 'Possible medicines' : 'সম্ভাব্য ওষুধ'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                english
                    ? 'These are possible lines found in the text, not medical advice. Verify them before saving a reminder.'
                    : 'এটি কেবল লেখা থেকে পাওয়া সম্ভাব্য লাইন। চিকিৎসার পরামর্শ নয়। সংরক্ষণ বা reminder করার আগে যাচাই করুন।',
              ),
              const SizedBox(height: 12),
              ...candidates.map(
                (candidate) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text('• ${candidate.name}'),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(english ? 'Cancel' : 'বাতিল'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(english ? 'I have verified this' : 'আমি যাচাই করেছি'),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      var savedCount = 0;
      for (final candidate in candidates) {
        if (!mounted) return;
        final time = await showTimePicker(
          context: context,
          initialTime: const TimeOfDay(hour: 9, minute: 0),
          helpText: english
              ? '${candidate.name} - choose a time'
              : '${candidate.name} - সময় বেছে নিন',
        );
        if (!mounted || time == null) continue;
        final reminder = MedicineReminder(
          medicineName: candidate.name,
          instructions: candidate.instructions,
          hour: time.hour,
          minute: time.minute,
          confirmedAt: DateTime.now(),
        );
        await _prescriptionService.saveReminder(reminder);
        await ReminderNotificationService.instance.schedule(reminder);
        widget.onReminderSaved(reminder);
        savedCount++;
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              savedCount == 0
                  ? (english
                        ? 'No reminders were saved.'
                        : 'কোনো reminder সংরক্ষণ করা হয়নি।')
                  : (english
                        ? '$savedCount reminder(s) saved.'
                        : '$savedCountটি reminder সংরক্ষণ হয়েছে।'),
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final english = _PathokLocale.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.document.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          IconButton(
            tooltip: english ? 'Export as PDF' : 'PDF হিসেবে রপ্তানি',
            onPressed: () => widget.onExport(widget.document),
            icon: const Icon(Icons.picture_as_pdf),
          ),
          IconButton(
            tooltip: english ? 'Share text' : 'লেখা শেয়ার করুন',
            onPressed: _shareText,
            icon: const Icon(Icons.share_outlined),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (widget.document.fileType == 'image' &&
              File(widget.document.sourcePath).existsSync())
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.file(
                File(widget.document.sourcePath),
                height: 220,
                fit: BoxFit.cover,
              ),
            ),
          if (widget.document.fileType == 'pdf')
            Card(
              child: ListTile(
                contentPadding: const EdgeInsets.all(16),
                leading: Icon(
                  Icons.picture_as_pdf_outlined,
                  color: Theme.of(context).colorScheme.primary,
                ),
                title: Text(english ? 'PDF imported' : 'PDF নথি আমদানি হয়েছে'),
                subtitle: Text(
                  english
                      ? 'PDF text will be processed during the OCR step.'
                      : 'PDF-এর লেখা OCR ধাপে প্রক্রিয়া করা হবে।',
                ),
              ),
            ),
          const SizedBox(height: 16),
          Text(
            english ? 'Recognized text' : 'স্বীকৃত লেখা',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Text(
            english
                ? 'Recognize text on this device. Review and edit the result.'
                : 'ছবির লেখা ডিভাইসেই শনাক্ত করুন। ফলাফল অবশ্যই যাচাই করে সম্পাদনা করুন।',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          Card(
            color: Theme.of(context).colorScheme.secondaryContainer,
            child: ListTile(
              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              leading: Icon(Icons.offline_bolt_outlined),
              title: Text(
                english
                    ? 'Offline Bangla + English OCR'
                    : 'Offline বাংলা + English OCR',
              ),
              subtitle: Text(
                english
                    ? 'Clear, straight images produce better results.'
                    : 'ছবি পরিষ্কার ও সোজা রাখলে ফলাফল ভালো হবে।',
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(4),
              child: TextField(
                controller: _controller,
                minLines: 8,
                maxLines: 16,
                onChanged: (value) {
                  widget.document.text = value;
                  widget.onChanged();
                  setState(() {});
                },
                decoration: InputDecoration(
                  hintText: english
                      ? 'Enter document text here...'
                      : 'এখানে নথির লেখা লিখুন...',
                  border: InputBorder.none,
                  filled: false,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          if (widget.document.fileType == 'image')
            OutlinedButton.icon(
              onPressed: _recognizing ? null : _recognizeText,
              icon: _recognizing
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(PathokIcons.scan),
              label: Text(
                _recognizing
                    ? (english ? 'Recognizing text...' : 'লেখা শনাক্ত হচ্ছে...')
                    : (english ? 'Run offline OCR' : 'অফলাইন OCR চালান'),
              ),
            ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: _controller.text.trim().isEmpty
                ? null
                : _showPrescriptionCandidates,
            icon: const Icon(PathokIcons.pill),
            label: Text(
              english ? 'Prescription assistance' : 'প্রেসক্রিপশন সহায়তা',
            ),
          ),
          const SizedBox(height: 8),
          FilledButton.icon(
            onPressed: _toggleSpeech,
            icon: Icon(_speaking ? PathokIcons.stop : PathokIcons.volume),
            label: Text(
              _speaking
                  ? (english ? 'Stop' : 'থামুন')
                  : (english ? 'Listen to text' : 'লেখা শুনুন'),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _shareText() async {
    final english = _PathokLocale.of(context);
    final text = _controller.text.trim();
    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            english
                ? 'There is no text to share.'
                : 'শেয়ার করার মতো লেখা নেই।',
          ),
        ),
      );
      return;
    }
    await SharePlus.instance.share(
      ShareParams(text: text, subject: widget.document.title),
    );
  }
}

class HistoryTab extends StatelessWidget {
  const HistoryTab({
    required this.documents,
    required this.onOpen,
    required this.onRename,
    required this.onDelete,
    super.key,
  });

  final List<LocalDocument> documents;
  final ValueChanged<LocalDocument> onOpen;
  final ValueChanged<LocalDocument> onRename;
  final ValueChanged<LocalDocument> onDelete;

  @override
  Widget build(BuildContext context) {
    return _SearchableHistory(
      documents: documents,
      onOpen: onOpen,
      onRename: onRename,
      onDelete: onDelete,
    );
  }
}

class _SearchableHistory extends StatefulWidget {
  const _SearchableHistory({
    required this.documents,
    required this.onOpen,
    required this.onRename,
    required this.onDelete,
  });

  final List<LocalDocument> documents;
  final ValueChanged<LocalDocument> onOpen;
  final ValueChanged<LocalDocument> onRename;
  final ValueChanged<LocalDocument> onDelete;

  @override
  State<_SearchableHistory> createState() => _SearchableHistoryState();
}

class _SearchableHistoryState extends State<_SearchableHistory> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final english = _PathokLocale.of(context);
    final filtered = widget.documents.where((document) {
      final query = _query.trim().toLowerCase();
      return query.isEmpty ||
          document.title.toLowerCase().contains(query) ||
          document.text.toLowerCase().contains(query);
    }).toList();
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Row(
            children: [
              Text(
                english ? 'Documents' : 'নথি',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const Spacer(),
              Text(
                english
                    ? '${widget.documents.length}'
                    : '${widget.documents.length}টি',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            onChanged: (value) => setState(() => _query = value),
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.search),
              labelText: english ? 'Search documents' : 'নথি খুঁজুন',
            ),
          ),
          const SizedBox(height: 12),
          if (filtered.isEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    const Icon(Icons.search_off, size: 42),
                    const SizedBox(height: 10),
                    Text(
                      _query.trim().isEmpty
                          ? (english
                                ? 'Your saved documents will appear here.'
                                : 'আপনার সংরক্ষিত নথি এখানে দেখা যাবে।')
                          : (english
                                ? 'No documents match this search.'
                                : 'এই খোঁজের সঙ্গে কোনো নথি মেলেনি।'),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            )
          else
            ...filtered.map(
              (document) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Card(
                  child: ListTile(
                    leading: Icon(
                      document.fileType == 'pdf'
                          ? Icons.picture_as_pdf_outlined
                          : PathokIcons.fileText,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    title: Text(document.title),
                    subtitle: Text(
                      document.text.isEmpty
                          ? (english ? 'Empty text' : 'খালি লেখা')
                          : document.text,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: PopupMenuButton<String>(
                      onSelected: (value) {
                        if (value == 'rename') widget.onRename(document);
                        if (value == 'delete') widget.onDelete(document);
                      },
                      itemBuilder: (context) => [
                        PopupMenuItem(
                          value: 'rename',
                          child: Text(english ? 'Rename' : 'নাম পরিবর্তন'),
                        ),
                        PopupMenuItem(
                          value: 'delete',
                          child: Text(english ? 'Delete' : 'মুছুন'),
                        ),
                      ],
                    ),
                    onTap: () => widget.onOpen(document),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class SettingsTab extends StatelessWidget {
  const SettingsTab({
    required this.reminders,
    required this.onDeleteAllData,
    required this.lockEnabled,
    required this.onLockChanged,
    required this.onDeleteReminder,
    required this.onEditReminder,
    required this.onExportBackup,
    required this.onImportBackup,
    required this.onLanguageChanged,
    super.key,
  });

  final List<MedicineReminder> reminders;
  final Future<void> Function() onDeleteAllData;
  final bool lockEnabled;
  final ValueChanged<bool> onLockChanged;
  final ValueChanged<MedicineReminder> onDeleteReminder;
  final ValueChanged<MedicineReminder> onEditReminder;
  final VoidCallback onExportBackup;
  final VoidCallback onImportBackup;
  final ValueChanged<bool> onLanguageChanged;

  @override
  Widget build(BuildContext context) {
    final english = _PathokLocale.of(context);
    return _ResponsiveContent(
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Row(
              children: [
                const _BrandMark(size: 48),
                const SizedBox(width: 14),
                Text(
                  english ? 'Settings' : 'সেটিংস',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              english ? 'Preferences' : 'পছন্দ',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Card(
              child: Column(
                children: [
                  SwitchListTile(
                    secondary: const Icon(PathokIcons.language),
                    title: Text(english ? 'Language' : 'ভাষা'),
                    subtitle: Text(english ? 'English' : 'বাংলা'),
                    value: english,
                    onChanged: onLanguageChanged,
                  ),
                  SwitchListTile(
                    secondary: const Icon(PathokIcons.lock),
                    title: Text(english ? 'App lock' : 'অ্যাপ লক'),
                    subtitle: Text(
                      english
                          ? 'Use device biometrics or PIN'
                          : 'ডিভাইসের biometrics বা PIN ব্যবহার করুন',
                    ),
                    value: lockEnabled,
                    onChanged: onLockChanged,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              english ? 'Reminders' : 'রিমাইন্ডার',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            if (reminders.isEmpty)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Text(
                    english
                        ? 'No reminders saved yet.'
                        : 'এখনও কোনো reminder সংরক্ষণ করা হয়নি।',
                  ),
                ),
              )
            else
              ...reminders.map(
                (reminder) => Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Card(
                    child: ListTile(
                      leading: const Icon(PathokIcons.alarm),
                      title: Text(reminder.medicineName),
                      subtitle: Text(
                        english
                            ? '${reminder.hour.toString().padLeft(2, '0')}:${reminder.minute.toString().padLeft(2, '0')} • Verify instructions'
                            : '${reminder.hour.toString().padLeft(2, '0')}:${reminder.minute.toString().padLeft(2, '0')} • ব্যবহার যাচাই করুন',
                      ),
                      trailing: IconButton(
                        tooltip: english ? 'Delete reminder' : 'Reminder মুছুন',
                        icon: const Icon(PathokIcons.trash),
                        onPressed: () => onDeleteReminder(reminder),
                      ),
                      onTap: () => onEditReminder(reminder),
                    ),
                  ),
                ),
              ),
            const SizedBox(height: 12),
            Text(
              english
                  ? 'Privacy & accessibility'
                  : 'গোপনীয়তা ও অ্যাক্সেসিবিলিটি',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Card(
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(PathokIcons.wifi),
                    title: Text(english ? 'Offline mode' : 'অফলাইন মোড'),
                    subtitle: Text(
                      english
                          ? 'Core tasks work without internet'
                          : 'মূল কাজগুলো ইন্টারনেট ছাড়াই চলবে',
                    ),
                  ),
                  ListTile(
                    leading: const Icon(PathokIcons.accessible),
                    title: Text(english ? 'Accessibility' : 'অ্যাক্সেসিবিলিটি'),
                    subtitle: Text(
                      english
                          ? 'TalkBack and large text are supported'
                          : 'TalkBack এবং বড় লেখা সমর্থিত',
                    ),
                  ),
                  ListTile(
                    leading: const Icon(PathokIcons.trash),
                    title: Text(
                      english
                          ? 'Delete all local data'
                          : 'সব স্থানীয় তথ্য মুছুন',
                    ),
                    onTap: onDeleteAllData,
                  ),
                  ListTile(
                    leading: const Icon(Icons.upload_file_outlined),
                    title: Text(
                      english
                          ? 'Export encrypted backup'
                          : 'Encrypted backup export',
                    ),
                    subtitle: Text(
                      english
                          ? 'Save document data to an encrypted file'
                          : 'নথির তথ্য একটি encrypted ফাইলে রাখুন',
                    ),
                    onTap: onExportBackup,
                  ),
                  ListTile(
                    leading: const Icon(Icons.download_outlined),
                    title: Text(english ? 'Restore backup' : 'Backup restore'),
                    subtitle: Text(
                      english
                          ? 'Restore data from a previous Pathok backup'
                          : 'আগের Pathok backup থেকে তথ্য ফিরিয়ে আনুন',
                    ),
                    onTap: onImportBackup,
                  ),
                ],
              ),
            ),
            AboutListTile(
              applicationName: english ? 'Pathok' : 'পাঠক',
              applicationVersion: '0.1.0',
              applicationLegalese: english
                  ? 'Every document has a voice.'
                  : 'প্রতিটি নথির একটি কণ্ঠ আছে।',
            ),
          ],
        ),
      ),
    );
  }
}

class LocalDocument {
  LocalDocument({
    required this.title,
    required this.sourcePath,
    required this.text,
    required this.fileType,
  });

  String title;
  final String sourcePath;
  String text;
  final String fileType;

  Map<String, dynamic> toJson() => {
    'title': title,
    'sourcePath': sourcePath,
    'text': text,
    'fileType': fileType,
  };

  factory LocalDocument.fromJson(Map<String, dynamic> json) => LocalDocument(
    title: json['title'] as String? ?? 'নথি',
    sourcePath: json['sourcePath'] as String? ?? '',
    text: json['text'] as String? ?? '',
    fileType: json['fileType'] as String? ?? 'image',
  );
}
