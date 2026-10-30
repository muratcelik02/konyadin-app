import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';
import '../report_models.dart';
import '../report_pdf.dart';
import '../report_rules.dart';
import '../report_store.dart';

/// PDF önizleme; paylaş/yazdır/Dosyalar'a kaydet düğmeleri printing paketinden gelir.
class ReportPdfScreen extends StatelessWidget {
  final ReportStore store;
  final InspectionJob job;
  final PanelReport report;

  const ReportPdfScreen({super.key, required this.store, required this.job, required this.report});

  String get _fileName {
    final name = '${report.reportNo}_${report.panelName}'.replaceAll(RegExp(r'[^\wğüşıöçĞÜŞİÖÇ.-]+'), '_');
    return '${missingFields(report).isNotEmpty ? 'TASLAK_' : ''}$name.pdf';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(report.panelName.isEmpty ? 'Rapor' : report.panelName)),
      body: PdfPreview(
        build: (_) => buildReportPdf(job: job, report: report, store: store),
        initialPageFormat: PdfPageFormat.a4,
        canChangePageFormat: false,
        canChangeOrientation: false,
        canDebug: false,
        pdfFileName: _fileName,
      ),
    );
  }
}
