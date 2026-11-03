import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/constants/pathok_icons.dart';
import '../../../core/localization/app_strings.dart';
import '../../../core/notifications/notification_service.dart';
import '../../../core/security/secure_data_store.dart';
import '../../prescription/models/medicine_reminder.dart';
import '../../prescription/services/prescription_service.dart';
import '../../settings/presentation/settings_tab.dart';
import '../data/document_repository.dart';
import '../models/local_document.dart';
import '../services/pdf_service.dart';
import 'document_screen.dart';
import 'history_tab.dart';
import 'home_tab.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({
    required this.onLanguageChanged,
    required this.onThemeChanged,
    required this.isDarkMode,
    super.key,
  });

  final ValueChanged<bool> onLanguageChanged;
  final ValueChanged<bool> onThemeChanged;
  final bool isDarkMode;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  final List<LocalDocument> _documents = [];
  final List<MedicineReminder> _reminders = [];
  final PrescriptionService _prescriptionService = PrescriptionService();
  final PdfService _pdfService = PdfService();
  final DocumentRepository _documentRepository = DocumentRepository();

  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadState();
  }

  Future<void> _loadState() async {
    _documents
      ..clear()
      ..addAll(await _documentRepository.getDocuments());

    _reminders
      ..clear()
      ..addAll(await _prescriptionService.loadReminders());

    if (mounted) {
      setState(() {
        _loading = false;
      });
    }
  }

  Future<void> _saveDocuments() async {
    await _documentRepository.saveDocuments(_documents);
  }

  Future<void> _deleteAllData() async {
    await _documentRepository.deleteAll(_documents);
    _reminders.clear();
    await ReminderNotificationService.instance.cancelAll();
    if (mounted) setState(() {});
  }

  Future<void> _pickImage(ImageSource source) async {
    final strings = AppStrings.of(context);
    final file = await ImagePicker().pickImage(
      source: source,
      maxWidth: 1920,
      maxHeight: 1920,
      imageQuality: 85,
    );
    if (!mounted || file == null) return;

    final document = await _documentRepository.importFile(
      sourcePath: file.path,
      title: '${strings.documentDetails} ${_documents.length + 1}',
      fileType: 'image',
    );

    setState(() => _documents.insert(0, document));
    await _saveDocuments();
    _openDocument(document);
  }

  Future<void> _pickPdf() async {
    final strings = AppStrings.of(context);
    final files = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );
    if (!mounted || files.isEmpty || files.first.path == null) return;

    final document = await _documentRepository.importFile(
      sourcePath: files.first.path!,
      title: 'PDF ${strings.documentDetails} ${_documents.length + 1}',
      fileType: 'pdf',
    );

    setState(() => _documents.insert(0, document));
    await _saveDocuments();
    _openDocument(document);
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
          onReminderSaved: (reminder) {
            setState(() => _reminders.add(reminder));
          },
        ),
      ),
    );
  }

  Future<void> _exportDocument(LocalDocument document) async {
    final strings = AppStrings.of(context);
    try {
      final exportedFile = await _pdfService.exportToPdf(
        title: document.title,
        text: document.text,
        defaultNotice: strings.noText,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${strings.pdfExportSuccess}: ${exportedFile.path.split('/').last}',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('${strings.error}: $e')));
      }
    }
  }

  Future<void> _togglePinDocument(LocalDocument document) async {
    await _documentRepository.togglePinDocument(_documents, document);
    if (mounted) setState(() {});
  }

  Future<void> _toggleReminderTaken(MedicineReminder reminder) async {
    final updated = await _prescriptionService.toggleReminderTaken(reminder);
    if (mounted) {
      setState(() {
        final index = _reminders.indexWhere((r) => r.id == reminder.id);
        if (index >= 0) {
          _reminders[index] = updated;
        }
      });
    }
  }

  Future<void> _deleteReminder(MedicineReminder reminder) async {
    await _prescriptionService.deleteReminder(reminder);
    await ReminderNotificationService.instance.cancel(reminder);
    if (mounted) setState(() => _reminders.remove(reminder));
  }

  Future<void> _editReminder(MedicineReminder reminder) async {
    final selectTimeText = AppStrings.of(context).selectTime;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: reminder.hour, minute: reminder.minute),
      helpText: '${reminder.medicineName} - $selectTimeText',
    );
    if (time == null) return;

    final replacement = reminder.copyWith(hour: time.hour, minute: time.minute);
    await _prescriptionService.replaceReminder(reminder, replacement);
    await ReminderNotificationService.instance.cancel(reminder);
    await ReminderNotificationService.instance.schedule(replacement);

    if (mounted) {
      setState(() {
        final index = _reminders.indexWhere((r) => r.id == reminder.id);
        if (index >= 0) {
          _reminders[index] = replacement;
        }
      });
    }
  }

  Future<void> _exportBackup() async {
    final strings = AppStrings.of(context);
    final controller = TextEditingController();

    final passphrase = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(strings.exportEncryptedBackup),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(strings.enterPassphrase),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              obscureText: true,
              autofocus: true,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.password_outlined),
                hintText: '••••••••',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(strings.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: Text(strings.save),
          ),
        ],
      ),
    );

    controller.dispose();
    if (passphrase == null || passphrase.length < 6) return;

    try {
      final encryptedBackup = await SecureDataStore.instance
          .exportWithPassphrase(passphrase);
      final path = await FilePicker.saveFile(
        dialogTitle: strings.exportEncryptedBackup,
        fileName:
            'pathok_backup_${DateTime.now().millisecondsSinceEpoch}.backup',
        bytes: utf8.encode(encryptedBackup),
      );

      if (mounted && path != null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(strings.backupSaved)));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('${strings.error}: $e')));
      }
    }
  }

  Future<void> _importBackup() async {
    final strings = AppStrings.of(context);
    final files = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['backup', 'txt'],
    );
    if (!mounted || files.isEmpty || files.first.path == null) return;

    final controller = TextEditingController();
    final passphrase = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(strings.restoreBackup),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(strings.enterPassphrase),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              obscureText: true,
              autofocus: true,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.password_outlined),
                hintText: '••••••••',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(strings.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: Text(strings.confirm),
          ),
        ],
      ),
    );

    controller.dispose();
    if (passphrase == null || passphrase.isEmpty) return;

    try {
      final content = await File(files.first.path!).readAsString();
      await SecureDataStore.instance.importWithPassphrase(content, passphrase);
      await _loadState();

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(strings.backupRestored)));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(strings.invalidPassphrase)));
      }
    }
  }

  Future<void> _renameDocument(LocalDocument document) async {
    final strings = AppStrings.of(context);
    final controller = TextEditingController(text: document.title);

    final title = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(strings.renameDocument),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(hintText: strings.documentDetails),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(strings.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: Text(strings.save),
          ),
        ],
      ),
    );

    controller.dispose();
    if (title == null || title.isEmpty) return;

    await _documentRepository.renameDocument(_documents, document, title);
    if (mounted) setState(() {});
  }

  Future<void> _deleteDocument(LocalDocument document) async {
    final strings = AppStrings.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(strings.deleteDocument),
        content: Text(strings.deleteDocumentConfirm(document.title)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(strings.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(strings.delete),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    await _documentRepository.deleteDocument(_documents, document);
    if (mounted) setState(() {});
  }

  Future<void> _confirmDeleteAllData() async {
    final strings = AppStrings.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(strings.deleteAllData),
        content: Text(strings.deleteAllConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(strings.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(strings.deletePermanently),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _deleteAllData();
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(strings.allDataDeleted)));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);

    if (_loading) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Text(strings.appName),
            ],
          ),
        ),
      );
    }

    final pages = [
      HomeTab(
        documents: _documents,
        onCapture: () => _pickImage(ImageSource.camera),
        onImport: () => _pickImage(ImageSource.gallery),
        onImportPdf: _pickPdf,
        onOpen: _openDocument,
        onDelete: _deleteDocument,
        reminders: _reminders,
        onToggleReminderTaken: _toggleReminderTaken,
      ),
      HistoryTab(
        documents: _documents,
        onOpen: _openDocument,
        onRename: _renameDocument,
        onDelete: _deleteDocument,
        onTogglePin: _togglePinDocument,
      ),
      SettingsTab(
        reminders: _reminders,
        onDeleteAllData: _confirmDeleteAllData,
        isDarkMode: widget.isDarkMode,
        onThemeChanged: widget.onThemeChanged,
        onDeleteReminder: _deleteReminder,
        onEditReminder: _editReminder,
        onExportBackup: _exportBackup,
        onImportBackup: _importBackup,
        onLanguageChanged: widget.onLanguageChanged,
      ),
    ];

    return Scaffold(
      body: IndexedStack(index: _selectedIndex, children: pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) =>
            setState(() => _selectedIndex = index),
        destinations: [
          NavigationDestination(
            icon: const Icon(PathokIcons.home),
            label: strings.navHome,
          ),
          NavigationDestination(
            icon: const Icon(PathokIcons.history),
            label: strings.navDocuments,
          ),
          NavigationDestination(
            icon: const Icon(PathokIcons.settings),
            label: strings.navSettings,
          ),
        ],
      ),
    );
  }
}
