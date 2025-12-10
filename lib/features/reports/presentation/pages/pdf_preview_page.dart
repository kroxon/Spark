import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:printing/printing.dart';

class PdfPreviewPage extends ConsumerWidget {
  final Uint8List pdfData;
  final String fileName;

  const PdfPreviewPage({
    super.key,
    required this.pdfData,
    required this.fileName,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Podgląd PDF'),
      ),
      body: PdfPreview(
        build: (format) => pdfData,
        canChangeOrientation: false,
        canChangePageFormat: false,
        pdfFileName: fileName,
      ),
    );
  }
}
