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

import 'ocr_service.dart';
import 'notification_service.dart';
import 'prescription_service.dart';
import 'secure_data_store.dart';

class PathokIcons {
  const PathokIcons._();

  static const _fontFamily = 'TablerIcons';
  static const _fontPackage = 'tabler_icons';
  static const home = IconData(0xeac1, fontFamily: _fontFamily, fontPackage: _fontPackage);
  static const history = IconData(0xebea, fontFamily: _fontFamily, fontPackage: _fontPackage);
  static const settings = IconData(0xeb20, fontFamily: _fontFamily, fontPackage: _fontPackage);
  static const volume = IconData(0xeb50, fontFamily: _fontFamily, fontPackage: _fontPackage);
  static const camera = IconData(0xea54, fontFamily: _fontFamily, fontPackage: _fontPackage);
  static const fileInvoice = IconData(0xeb67, fontFamily: _fontFamily, fontPackage: _fontPackage);
  static const photo = IconData(0xeb0a, fontFamily: _fontFamily, fontPackage: _fontPackage);
  static const fileText = IconData(0xeaa2, fontFamily: _fontFamily, fontPackage: _fontPackage);
  static const chevronRight = IconData(0xea61, fontFamily: _fontFamily, fontPackage: _fontPackage);
  static const language = IconData(0xebbe, fontFamily: _fontFamily, fontPackage: _fontPackage);
  static const alarm = IconData(0xea04, fontFamily: _fontFamily, fontPackage: _fontPackage);
  static const trash = IconData(0xeb41, fontFamily: _fontFamily, fontPackage: _fontPackage);
  static const wifi = IconData(0xeb52, fontFamily: _fontFamily, fontPackage: _fontPackage);
  static const accessible = IconData(0xeba9, fontFamily: _fontFamily, fontPackage: _fontPackage);
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
    const teal = Color(0xff00695c);
    return MaterialApp(
      title: 'পাঠক',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: teal),
        useMaterial3: true,
        inputDecorationTheme: const InputDecorationTheme(
          border: OutlineInputBorder(),
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

  @override
  Widget build(BuildContext context) {
    if (_onboardingComplete == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (_locked) {
      return LockScreen(onUnlock: _loadPreference);
    }
    return _onboardingComplete!
        ? const HomeScreen()
        : OnboardingScreen(onComplete: _completeOnboarding);
  }

}

class LockScreen extends StatelessWidget {
  const LockScreen({required this.onUnlock, super.key});

  final Future<void> Function() onUnlock;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.lock_outline, size: 72),
              const SizedBox(height: 16),
              const Text('পাঠক লক করা আছে', style: TextStyle(fontSize: 22)),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: onUnlock,
                icon: const Icon(Icons.fingerprint),
                label: const Text('আনলক করুন'),
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
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),
              Semantics(
                header: true,
                child: Text(
                  'পাঠক',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.displaySmall?.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Every document has a voice.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 32),
              const Icon(PathokIcons.volume, size: 96),
              const SizedBox(height: 32),
              const Text(
                'ছবি বা নথি থেকে লেখা পড়ুন এবং শুনুন।',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 22),
              ),
              const SizedBox(height: 12),
              const Text(
                'পাঠক আপনার নথি এই ডিভাইসেই নিরাপদে রাখে। শুরু করতে নিচের বোতামটি চাপুন।',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 17),
              ),
              const Spacer(),
              FilledButton.icon(
                onPressed: onComplete,
                icon: const Icon(Icons.arrow_forward),
                label: const Padding(
                  padding: EdgeInsets.all(12),
                  child: Text('শুরু করুন', style: TextStyle(fontSize: 18)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

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
    final values = (payload['documents'] as List<dynamic>? ?? <dynamic>[])
        .map((value) => value as String);
    _documents
      ..clear()
      ..addAll(
        values.map(
          (value) => LocalDocument.fromJson(
            jsonDecode(value) as Map<String, dynamic>,
          ),
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
    payload['documents'] =
        _documents.map((document) => jsonEncode(document.toJson())).toList();
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
      HistoryTab(documents: _documents, onOpen: _openDocument),
      SettingsTab(
        reminders: _reminders,
        onDeleteAllData: _confirmDeleteAllData,
        lockEnabled: _lockEnabled,
        onLockChanged: _setLockEnabled,
        onDeleteReminder: _deleteReminder,
      ),
    ];
    return Scaffold(
      body: IndexedStack(index: _selectedIndex, children: pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) => setState(() => _selectedIndex = index),
        destinations: const [
          NavigationDestination(icon: Icon(PathokIcons.home), label: 'হোম'),
          NavigationDestination(
            icon: Icon(PathokIcons.history),
            label: 'ইতিহাস',
          ),
          NavigationDestination(
            icon: Icon(PathokIcons.settings),
            label: 'সেটিংস',
          ),
        ],
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    final file = await ImagePicker().pickImage(source: source);
    if (!mounted || file == null) return;
    final storedPath = await _copyToAppStorage(file.path);
    final document = LocalDocument(
      title: 'নতুন নথি ${_documents.length + 1}',
      sourcePath: storedPath,
      text: '',
      fileType: 'image',
    );
    setState(() => _documents.insert(0, document));
    await _saveDocuments();
    _openDocument(document);
  }

  Future<void> _pickPdf() async {
    final files = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );
    if (!mounted || files.isEmpty || files.first.path == null) return;
    final storedPath = await _copyToAppStorage(files.first.path!);
    final document = LocalDocument(
      title: 'PDF নথি ${_documents.length + 1}',
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
          onReminderSaved: (reminder) => setState(() => _reminders.add(reminder)),
        ),
      ),
    );
  }

  Future<void> _exportDocument(LocalDocument document) async {
    final directory = await getApplicationDocumentsDirectory();
    final output = File(
      '${directory.path}${Platform.pathSeparator}${document.title.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_')}.pdf',
    );
    final pdf = pw.Document();
    pdf.addPage(
      pw.Page(
        build: (_) => pw.Padding(
          padding: const pw.EdgeInsets.all(24),
          child: pw.Text(document.text.isEmpty ? 'No text entered.' : document.text),
        ),
      ),
    );
    await output.writeAsBytes(await pdf.save());
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('PDF সংরক্ষণ হয়েছে: ${output.path}')),
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

  Future<void> _confirmDeleteAllData() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('সব তথ্য মুছবেন?'),
        content: const Text(
          'সংরক্ষিত নথি, কপি করা ফাইল এবং medicine reminder স্থায়ীভাবে মুছে যাবে।',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('বাতিল'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('স্থায়ীভাবে মুছুন'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await _deleteAllData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('সব স্থানীয় তথ্য মুছে ফেলা হয়েছে।')),
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
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text('শুভেচ্ছা!', style: Theme.of(context).textTheme.headlineMedium),
          const Text('আপনার নথি শুনতে প্রস্তুত?'),
          const SizedBox(height: 24),
          _ActionCard(
            icon: PathokIcons.camera,
            title: 'ক্যামেরা দিয়ে স্ক্যান করুন',
            subtitle: 'ছাপা নথির ছবি তুলুন',
            onPressed: onCapture,
          ),
          const SizedBox(height: 12),
          _ActionCard(
            icon: PathokIcons.fileInvoice,
            title: 'PDF বেছে নিন',
            subtitle: 'ডিভাইস থেকে একটি PDF নিন',
            onPressed: onImportPdf,
          ),
          const SizedBox(height: 12),
          _ActionCard(
            icon: PathokIcons.photo,
            title: 'ছবি বেছে নিন',
            subtitle: 'গ্যালারি থেকে একটি ছবি নিন',
            onPressed: onImport,
          ),
          const SizedBox(height: 28),
          Text('সাম্প্রতিক নথি', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          if (documents.isEmpty)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Text('এখনও কোনো নথি নেই। উপরের একটি অপশন দিয়ে শুরু করুন।'),
              ),
            )
          else
            ...documents.take(3).map(
                  (document) => ListTile(
                    leading: const CircleAvatar(child: Icon(PathokIcons.fileText)),
                    title: Text(document.title),
                    subtitle: Text(
                      document.text.isEmpty ? 'লেখা যোগ করা হয়নি' : 'লেখা সম্পাদনা করা হয়েছে',
                    ),
                    onTap: () => onOpen(document),
                  ),
                ),
        ],
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
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              Icon(icon, size: 40, color: Theme.of(context).colorScheme.primary),
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
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(
            'ছবির লেখা শনাক্ত হয়েছে। Confidence: ${result.confidenceLabel}',
          ),
        ));
      }
    } on Exception catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('OCR ব্যর্থ হয়েছে: $error')),
        );
      }
    } finally {
      if (mounted) setState(() => _recognizing = false);
    }
  }

  Future<void> _toggleSpeech() async {
    if (_speaking) {
      await _tts.stop();
      if (mounted) setState(() => _speaking = false);
      return;
    }

    if (_controller.text.trim().isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('শোনার জন্য আগে লেখাটি যোগ করুন।')),
        );
      }
      return;
    }
    await _tts.setLanguage('bn-BD');
    await _tts.setSpeechRate(0.45);
    await _tts.speak(_controller.text);
    if (mounted) setState(() => _speaking = true);
  }

  Future<void> _showPrescriptionCandidates() async {
    final candidates = _prescriptionService.extract(_controller.text);
    if (!mounted) return;
    if (candidates.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('সম্ভাব্য ওষুধের লাইন পাওয়া যায়নি।')),
      );
      return;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('সম্ভাব্য ওষুধ'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'এটি কেবল লেখা থেকে পাওয়া সম্ভাব্য লাইন। চিকিৎসার পরামর্শ নয়। সংরক্ষণ বা reminder করার আগে যাচাই করুন।',
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
            child: const Text('বাতিল'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('আমি যাচাই করেছি'),
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
          helpText: '${candidate.name} - সময় বেছে নিন',
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
                  ? 'কোনো reminder সংরক্ষণ করা হয়নি।'
                  : '$savedCountটি reminder সংরক্ষণ হয়েছে।',
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.document.title),
        actions: [
          IconButton(
            tooltip: 'PDF হিসেবে রপ্তানি',
            onPressed: () => widget.onExport(widget.document),
            icon: const Icon(Icons.picture_as_pdf),
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
              child: Image.file(File(widget.document.sourcePath), height: 220, fit: BoxFit.cover),
            ),
          if (widget.document.fileType == 'pdf')
            const Card(
              child: ListTile(
                leading: Icon(Icons.picture_as_pdf),
                title: Text('PDF নথি আমদানি হয়েছে'),
                subtitle: Text('PDF-এর লেখা OCR ধাপে প্রক্রিয়া করা হবে।'),
              ),
            ),
          const SizedBox(height: 16),
          const Text(
            'স্বীকৃত লেখা',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'ছবির লেখা ডিভাইসেই শনাক্ত করুন। ফলাফল অবশ্যই যাচাই করে সম্পাদনা করুন।',
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _controller,
            minLines: 8,
            maxLines: 16,
            onChanged: (value) {
              widget.document.text = value;
              widget.onChanged();
              setState(() {});
            },
            decoration: const InputDecoration(hintText: 'এখানে নথির লেখা লিখুন...'),
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
                  : const Icon(Icons.document_scanner_outlined),
              label: Text(_recognizing ? 'লেখা শনাক্ত হচ্ছে...' : 'অফলাইন OCR চালান'),
            ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: _controller.text.trim().isEmpty
                ? null
                : _showPrescriptionCandidates,
            icon: const Icon(Icons.medication_outlined),
            label: const Text('প্রেসক্রিপশন সহায়তা'),
          ),
          const SizedBox(height: 8),
          FilledButton.icon(
            onPressed: _toggleSpeech,
            icon: Icon(_speaking ? Icons.stop : Icons.volume_up),
            label: Text(_speaking ? 'থামুন' : 'লেখা শুনুন'),
          ),
        ],
      ),
    );
  }
}

class HistoryTab extends StatelessWidget {
  const HistoryTab({required this.documents, required this.onOpen, super.key});

  final List<LocalDocument> documents;
  final ValueChanged<LocalDocument> onOpen;

  @override
  Widget build(BuildContext context) {
    return _SearchableHistory(documents: documents, onOpen: onOpen);
  }
}

class _SearchableHistory extends StatefulWidget {
  const _SearchableHistory({required this.documents, required this.onOpen});

  final List<LocalDocument> documents;
  final ValueChanged<LocalDocument> onOpen;

  @override
  State<_SearchableHistory> createState() => _SearchableHistoryState();
}

class _SearchableHistoryState extends State<_SearchableHistory> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
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
          Text('ইতিহাস', style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 12),
          TextField(
            onChanged: (value) => setState(() => _query = value),
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.search),
              labelText: 'নথি খুঁজুন',
            ),
          ),
          const SizedBox(height: 12),
          if (filtered.isEmpty)
            const Text('আপনার সংরক্ষিত নথি এখানে দেখা যাবে।')
          else
            ...filtered.map(
              (document) => Card(
                child: ListTile(
                  leading: const Icon(PathokIcons.fileText),
                  title: Text(document.title),
                  subtitle: Text(document.text.isEmpty ? 'খালি লেখা' : document.text),
                  onTap: () => widget.onOpen(document),
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
    super.key,
  });

  final List<MedicineReminder> reminders;
  final Future<void> Function() onDeleteAllData;
  final bool lockEnabled;
  final ValueChanged<bool> onLockChanged;
  final ValueChanged<MedicineReminder> onDeleteReminder;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text('সেটিংস', style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 12),
          const ListTile(
            leading: Icon(PathokIcons.language),
            title: Text('ভাষা'),
            subtitle: Text('বাংলা'),
          ),
          const SizedBox(height: 12),
          Text('Medicine reminders', style: Theme.of(context).textTheme.titleLarge),
          if (reminders.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Text('এখনও কোনো reminder সংরক্ষণ করা হয়নি।'),
            )
          else
            ...reminders.map(
              (reminder) => Card(
                child: ListTile(
                  leading: const Icon(PathokIcons.alarm),
                  title: Text(reminder.medicineName),
                  subtitle: Text(
                    '${reminder.hour.toString().padLeft(2, '0')}:${reminder.minute.toString().padLeft(2, '0')} • ব্যবহার যাচাই করুন',
                  ),
                  trailing: IconButton(
                    tooltip: 'Reminder মুছুন',
                    icon: const Icon(PathokIcons.trash),
                    onPressed: () => onDeleteReminder(reminder),
                  ),
                ),
              ),
            ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: onDeleteAllData,
            icon: const Icon(PathokIcons.trash),
            label: const Text('সব স্থানীয় তথ্য মুছুন'),
          ),
          const ListTile(
            leading: Icon(PathokIcons.wifi),
            title: Text('অফলাইন মোড'),
            subtitle: Text('মূল কাজগুলো ইন্টারনেট ছাড়াই চলবে'),
          ),
          const ListTile(
            leading: Icon(PathokIcons.accessible),
            title: Text('অ্যাক্সেসিবিলিটি'),
            subtitle: Text('TalkBack এবং বড় লেখা সমর্থিত'),
          ),
          const AboutListTile(
            applicationName: 'পাঠক',
            applicationVersion: '0.1.0',
            applicationLegalese: 'Every document has a voice.',
          ),
        ],
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

  final String title;
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
