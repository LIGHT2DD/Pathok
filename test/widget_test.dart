import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pathok/core/localization/app_strings.dart';
import 'package:pathok/features/documents/models/local_document.dart';
import 'package:pathok/features/documents/presentation/history_tab.dart';
import 'package:pathok/features/documents/presentation/home_tab.dart';
import 'package:pathok/features/onboarding/presentation/onboarding_screen.dart';
import 'package:pathok/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('shows Pathok onboarding on fresh installation', (tester) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    await tester.pumpWidget(const PathokApp());
    await tester.pumpAndSettle();

    expect(find.text('Get started'), findsOneWidget);
    expect(find.text('Read documents with ease'), findsOneWidget);
  });

  testWidgets('OnboardingScreen triggers onComplete callback', (tester) async {
    var completed = false;

    await tester.pumpWidget(
      MaterialApp(
        home: AppLocaleScope(
          isEnglish: false,
          child: OnboardingScreen(
            onComplete: () async {
              completed = true;
            },
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();
    expect(find.text('শুরু করুন'), findsOneWidget);

    await tester.ensureVisible(find.text('শুরু করুন'));
    await tester.tap(find.text('শুরু করুন'));
    await tester.pumpAndSettle();

    expect(completed, isTrue);
  });

  testWidgets('HomeTab renders quick action buttons and documents correctly', (tester) async {
    final docs = [
      LocalDocument(
        title: 'মেডিকেল প্রেসক্রিপশন',
        sourcePath: '/path/doc1.jpg',
        text: 'প্যারাসিটামল ৫০০ মিগ্রা',
        fileType: 'image',
      ),
    ];

    await tester.pumpWidget(
      MaterialApp(
        home: AppLocaleScope(
          isEnglish: false,
          child: Scaffold(
            body: HomeTab(
              documents: docs,
              onCapture: () {},
              onImport: () {},
              onImportPdf: () {},
              onOpen: (_) {},
              onDelete: (_) {},
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('ক্যামেরা দিয়ে স্ক্যান করুন'), findsOneWidget);
    expect(find.text('PDF বেছে নিন'), findsOneWidget);
    expect(find.text('ছবি বেছে নিন'), findsOneWidget);

    await tester.scrollUntilVisible(find.text('মেডিকেল প্রেসক্রিপশন'), 100);
    expect(find.text('মেডিকেল প্রেসক্রিপশন'), findsOneWidget);
  });

  testWidgets('HistoryTab filters documents dynamically on search query', (tester) async {
    final docs = [
      LocalDocument(
        title: 'Blood Test Report',
        sourcePath: '/path/1.pdf',
        text: 'Hemoglobin normal',
        fileType: 'pdf',
      ),
      LocalDocument(
        title: 'Prescription Doctor',
        sourcePath: '/path/2.jpg',
        text: 'Napa Extend 665mg',
        fileType: 'image',
      ),
    ];

    await tester.pumpWidget(
      MaterialApp(
        home: AppLocaleScope(
          isEnglish: true,
          child: Scaffold(
            body: HistoryTab(
              documents: docs,
              onOpen: (_) {},
              onRename: (_) {},
              onDelete: (_) {},
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();
    expect(find.text('Blood Test Report'), findsOneWidget);
    expect(find.text('Prescription Doctor'), findsOneWidget);

    // Enter search query
    await tester.enterText(find.byType(TextField), 'Napa');
    await tester.pumpAndSettle();

    expect(find.text('Prescription Doctor'), findsOneWidget);
    expect(find.text('Blood Test Report'), findsNothing);
  });
}
