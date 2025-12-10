import 'dart:typed_data';
import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:iskra/features/reports/domain/report_person.dart';

enum ReportFont {
  calibri,
  timesNewRoman,
  arial,
}

class PdfReportService {
  Future<Uint8List> generateReport({
    required String city,
    required DateTime date,
    required ReportPerson sender,
    required ReportPerson recipient,
    required String title,
    required String body,
    required ReportFont fontType,
  }) async {
    final pdf = pw.Document();
    final font = await _loadFont(fontType);
    final boldFont = await _loadFont(fontType, isBold: true); // Simplified: using same font or bold variant if available

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        theme: pw.ThemeData.withFont(
          base: font,
          bold: boldFont,
        ),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Date & Place
              pw.Align(
                alignment: pw.Alignment.topRight,
                child: pw.Text(
                  '$city, ${_formatDate(date)}',
                  style: const pw.TextStyle(fontSize: 12),
                ),
              ),
              pw.SizedBox(height: 20),

              // Sender Details
              pw.Align(
                alignment: pw.Alignment.topRight,
                child: pw.SizedBox(
                  width: 200,
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(sender.rank, style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      pw.Text('${sender.firstName} ${sender.lastName}'),
                      pw.Text(sender.position),
                      if (sender.unit.isNotEmpty) pw.Text(sender.unit),
                    ],
                  ),
                ),
              ),
              pw.SizedBox(height: 40),

              // Recipient Details
              pw.Align(
                alignment: pw.Alignment.centerRight,
                child: pw.SizedBox(
                  width: 200,
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text("Do:", style: const pw.TextStyle(fontSize: 10)),
                      pw.Text(recipient.rank, style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      pw.Text('${recipient.firstName} ${recipient.lastName}'),
                      pw.Text(recipient.position),
                      if (recipient.unit.isNotEmpty) pw.Text(recipient.unit),
                    ],
                  ),
                ),
              ),
              pw.SizedBox(height: 60),

              // Title
              pw.Center(
                child: pw.Text(
                  title.toUpperCase(),
                  style: pw.TextStyle(
                    fontSize: 16,
                    fontWeight: pw.FontWeight.bold,
                    decoration: pw.TextDecoration.underline,
                  ),
                ),
              ),
              pw.SizedBox(height: 30),

              // Body
              pw.Text(
                body,
                textAlign: pw.TextAlign.justify,
                style: const pw.TextStyle(fontSize: 12, lineSpacing: 1.5),
              ),
              pw.SizedBox(height: 60),

              // Signature Placeholder
              pw.Align(
                alignment: pw.Alignment.bottomRight,
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.center,
                  children: [
                    pw.Text("................................................"),
                    pw.Text("(podpis)", style: const pw.TextStyle(fontSize: 10)),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );

    return pdf.save();
  }

  Future<pw.Font> _loadFont(ReportFont fontType, {bool isBold = false}) async {
    try {
      String fontName;
      switch (fontType) {
        case ReportFont.calibri:
          fontName = isBold ? 'calibrib.ttf' : 'calibri.ttf';
          break;
        case ReportFont.timesNewRoman:
          fontName = isBold ? 'timesbd.ttf' : 'times.ttf';
          break;
        case ReportFont.arial:
          fontName = isBold ? 'arialbd.ttf' : 'arial.ttf';
          break;
      }
      
      // Fallback to regular if bold not found (simplified logic for this example)
      // In a real app, you'd want specific bold assets.
      // Assuming assets are in assets/fonts/
      final fontData = await rootBundle.load('assets/fonts/$fontName');
      return pw.Font.ttf(fontData);
    } catch (e) {
      // Fallback to standard PDF fonts if assets are missing
      return isBold ? pw.Font.helveticaBold() : pw.Font.helvetica();
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}.${date.month}.${date.year}';
  }
}
