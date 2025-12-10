import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iskra/features/reports/data/firestore_report_repository.dart';
import 'package:iskra/features/reports/data/pdf_report_service.dart';
import 'package:iskra/features/reports/data/report_ai_service.dart';
import 'package:iskra/features/reports/domain/report_person.dart';
import 'package:iskra/features/reports/domain/report_template.dart';

// --- Repositories ---

final firestoreReportRepositoryProvider = Provider<FirestoreReportRepository>((ref) {
  return FirestoreReportRepository();
});

// --- Services ---

final reportAiServiceProvider = Provider<ReportAiService>((ref) {
  return ReportAiService();
});

final pdfReportServiceProvider = Provider<PdfReportService>((ref) {
  return PdfReportService();
});

// --- Data Streams ---

final savedPersonsProvider = StreamProvider<List<ReportPerson>>((ref) {
  final repository = ref.watch(firestoreReportRepositoryProvider);
  return repository.watchPersons();
});

final customTemplatesProvider = StreamProvider<List<ReportTemplate>>((ref) {
  final repository = ref.watch(firestoreReportRepositoryProvider);
  return repository.watchCustomTemplates();
});

final allTemplatesProvider = Provider<List<ReportTemplate>>((ref) {
  final customTemplates = ref.watch(customTemplatesProvider).value ?? [];
  return [
    ...ReportTemplate.predefinedTemplates,
    ...customTemplates,
  ];
});

