import 'dart:io';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:shared_preferences/shared_preferences.dart';

import 'ocr_service.dart';
import 'prescription_service.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
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

  @override
  void initState() {
    super.initState();
    _loadPreference();
  }

  Future<void> _loadPreference() async {
    final preferences = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _onboardingComplete =
            preferences.getBool('onboarding_complete') ?? false;
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
    return _onboardingComplete!
        ? const HomeScreen()
        : OnboardingScreen(onComplete: _completeOnboarding);
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
              const Icon(Icons.record_voice_over, size: 96),
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
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadDocuments();
  }

  Future<void> _loadDocuments() async {
    final preferences = await SharedPreferences.getInstance();
    final values = preferences.getStringList('documents') ?? <String>[];
    _documents
      ..clear()
      ..addAll(
        values.map(
          (value) => LocalDocument.fromJson(
            jsonDecode(value) as Map<String, dynamic>,
          ),
        ),
      );
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _saveDocuments() async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setStringList(
      'documents',
      _documents.map((document) => jsonEncode(document.toJson())).toList(),
    );
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
      const SettingsTab(),
    ];
    return Scaffold(
      body: IndexedStack(index: _selectedIndex, children: pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) => setState(() => _selectedIndex = index),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), label: 'হোম'),
          NavigationDestination(
            icon: Icon(Icons.history),
            label: 'ইতিহাস',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
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
            icon: Icons.camera_alt,
            title: 'ক্যামেরা দিয়ে স্ক্যান করুন',
            subtitle: 'ছাপা নথির ছবি তুলুন',
            onPressed: onCapture,
          ),
          const SizedBox(height: 12),
          _ActionCard(
            icon: Icons.picture_as_pdf_outlined,
            title: 'PDF বেছে নিন',
            subtitle: 'ডিভাইস থেকে একটি PDF নিন',
            onPressed: onImportPdf,
          ),
          const SizedBox(height: 12),
          _ActionCard(
            icon: Icons.photo_library_outlined,
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
                    leading: const CircleAvatar(child: Icon(Icons.description)),
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
              const Icon(Icons.chevron_right),
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
    super.key,
  });

  final LocalDocument document;
  final VoidCallback onChanged;
  final Future<void> Function(LocalDocument document) onExport;

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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('নিশ্চিত করা হয়েছে। Reminder তৈরি করতে সময়সূচি আলাদাভাবে সেট করুন।'),
        ),
      );
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
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text('ইতিহাস', style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 12),
          if (documents.isEmpty)
            const Text('আপনার সংরক্ষিত নথি এখানে দেখা যাবে।')
          else
            ...documents.map(
              (document) => Card(
                child: ListTile(
                  leading: const Icon(Icons.description_outlined),
                  title: Text(document.title),
                  subtitle: Text(document.text.isEmpty ? 'খালি লেখা' : document.text),
                  onTap: () => onOpen(document),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class SettingsTab extends StatelessWidget {
  const SettingsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text('সেটিংস', style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 12),
          const ListTile(
            leading: Icon(Icons.language),
            title: Text('ভাষা'),
            subtitle: Text('বাংলা'),
          ),
          const ListTile(
            leading: Icon(Icons.wifi_off),
            title: Text('অফলাইন মোড'),
            subtitle: Text('মূল কাজগুলো ইন্টারনেট ছাড়াই চলবে'),
          ),
          const ListTile(
            leading: Icon(Icons.accessibility_new),
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
