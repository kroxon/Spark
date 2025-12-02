import 'dart:math';
import 'package:iskra/features/kpp/domain/question.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class KppPdfGenerator {
  static Future<void> generateExamSheet(List<KppQuestion> allQuestions) async {
    // 1. Select 30 random questions
    final random = Random();
    final List<KppQuestion> selectedQuestions = [];
    final List<KppQuestion> pool = List.from(allQuestions);
    
    final count = min(30, pool.length);
    for (int i = 0; i < count; i++) {
      final index = random.nextInt(pool.length);
      selectedQuestions.add(pool[index]);
      pool.removeAt(index);
    }

    // 2. Load font
    final font = await PdfGoogleFonts.robotoRegular();
    final fontBold = await PdfGoogleFonts.robotoBold();

    // 3. Create PDF
    final doc = pw.Document();

    // Portrait orientation is best for single-column lists to maximize vertical space
    final pageFormat = PdfPageFormat.a4;
    
    // Professional layout constants
    const double margin = 20.0;
    const double questionSpacing = 8.0; // Reduced spacing for compactness
    const double headerSpacing = 10.0;
    
    doc.addPage(
      pw.MultiPage(
        pageFormat: pageFormat,
        margin: const pw.EdgeInsets.all(margin),
        footer: (pw.Context context) {
          return pw.Container(
            alignment: pw.Alignment.centerRight,
            margin: const pw.EdgeInsets.only(top: 5),
            child: pw.Text(
              'Strona ${context.pageNumber} z ${context.pagesCount}',
              style: pw.TextStyle(font: font, fontSize: 8, color: PdfColors.grey600),
            ),
          );
        },
        build: (pw.Context context) {
          return [
            // --- Header (First Page Only) ---
            pw.Column(
              children: [
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('Egzamin KPP', style: pw.TextStyle(font: fontBold, fontSize: 16)),
                    pw.Text('Data: ...........................', style: pw.TextStyle(font: font, fontSize: 10)),
                  ],
                ),
                pw.SizedBox(height: 10),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Expanded(
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text('Imię i nazwisko:', style: pw.TextStyle(font: font, fontSize: 10)),
                          pw.SizedBox(height: 4),
                          pw.Container(height: 0.5, color: PdfColors.black),
                        ],
                      ),
                    ),
                    pw.SizedBox(width: 30),
                    pw.Expanded(
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text('Miejscowość:', style: pw.TextStyle(font: font, fontSize: 10)),
                          pw.SizedBox(height: 4),
                          pw.Container(height: 0.5, color: PdfColors.black),
                        ],
                      ),
                    ),
                  ],
                ),
                pw.SizedBox(height: headerSpacing),
              ],
            ),

            // --- Questions ---
            // Using pw.Table ensures that rows are kept together on the same page if possible.
            pw.Table(
              columnWidths: {0: const pw.FlexColumnWidth()},
              children: [
                for (int i = 0; i < selectedQuestions.length; i++)
                  pw.TableRow(
                    children: [
                      pw.Container(
                        margin: const pw.EdgeInsets.only(bottom: questionSpacing),
                        decoration: const pw.BoxDecoration(
                          border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey300, width: 0.5)),
                        ),
                        padding: const pw.EdgeInsets.only(bottom: 4),
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            // Question Text
                            pw.Row(
                              crossAxisAlignment: pw.CrossAxisAlignment.start,
                              children: [
                                pw.Text('${i + 1}. ', style: pw.TextStyle(font: fontBold, fontSize: 10)),
                                pw.Expanded(
                                  child: pw.Text(
                                    selectedQuestions[i].question,
                                    style: pw.TextStyle(font: font, fontSize: 10),
                                  ),
                                ),
                              ],
                            ),
                            pw.SizedBox(height: 4),
                            
                            // Answers
                            ...List.generate(selectedQuestions[i].answers.length, (ansIndex) {
                              final letter = String.fromCharCode(65 + ansIndex);
                              return pw.Padding(
                                padding: const pw.EdgeInsets.only(left: 15, top: 2),
                                child: pw.Row(
                                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                                  children: [
                                    pw.Text('$letter. ', style: pw.TextStyle(font: fontBold, fontSize: 9)),
                                    pw.Expanded(
                                      child: pw.Text(
                                        selectedQuestions[i].answers[ansIndex],
                                        style: pw.TextStyle(font: font, fontSize: 9),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }),
                          ],
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ];
        },
      ),
    );

    // 4. Show Print/Share Dialog
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => doc.save(),
      name: 'Egzamin_KPP_Arkusz.pdf',
    );
  }
}
