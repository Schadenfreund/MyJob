import 'dart:io';
import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models/cv_data.dart';
import '../models/cover_letter.dart';
import '../models/template_style.dart';
import '../pdf/cv_templates/professional_cv_template.dart';
import '../pdf/cv_templates/modern_cv_template.dart';
import '../pdf/cover_letter_templates/professional_cover_letter_template.dart';
import '../pdf/cover_letter_templates/modern_cover_letter_template.dart';

/// Service for generating PDF documents
class PdfService {
  PdfService._();
  static final PdfService instance = PdfService._();

  /// Generate CV PDF bytes
  Future<Uint8List> generateCvPdf(CvData cv, TemplateStyle style) async {
    final pdf = pw.Document();

    switch (style.type) {
      case TemplateType.professional:
        ProfessionalCvTemplate.build(pdf, cv, style);
      case TemplateType.modern:
        ModernCvTemplate.build(pdf, cv, style);
      case TemplateType.creative:
        // Creative uses modern template with different styling
        ModernCvTemplate.build(pdf, cv, style);
    }

    return pdf.save();
  }

  /// Generate Cover Letter PDF bytes
  Future<Uint8List> generateCoverLetterPdf(
    CoverLetter letter,
    TemplateStyle style, {
    String? senderAddress,
    String? senderPhone,
    String? senderEmail,
  }) async {
    final pdf = pw.Document();

    switch (style.type) {
      case TemplateType.professional:
        ProfessionalCoverLetterTemplate.build(
          pdf,
          letter,
          style,
          senderAddress: senderAddress,
          senderPhone: senderPhone,
          senderEmail: senderEmail,
        );
      case TemplateType.modern:
      case TemplateType.creative:
        ModernCoverLetterTemplate.build(
          pdf,
          letter,
          style,
          senderAddress: senderAddress,
          senderPhone: senderPhone,
          senderEmail: senderEmail,
        );
    }

    return pdf.save();
  }

  /// Save PDF to file
  Future<File> savePdfToFile(Uint8List bytes, String filePath) async {
    final file = File(filePath);
    await file.writeAsBytes(bytes);
    return file;
  }

  /// Print PDF
  Future<bool> printPdf(Uint8List bytes, {String? documentName}) async {
    return Printing.layoutPdf(
      onLayout: (_) => bytes,
      name: documentName ?? 'Document',
    );
  }

  /// Share PDF
  Future<bool> sharePdf(Uint8List bytes, {String? filename}) async {
    return Printing.sharePdf(
      bytes: bytes,
      filename: filename ?? 'document.pdf',
    );
  }

  /// Preview PDF using system viewer
  Future<void> previewPdf(Uint8List bytes) async {
    await Printing.layoutPdf(
      onLayout: (_) => bytes,
    );
  }

  /// Get PDF page format
  PdfPageFormat get pageFormat => PdfPageFormat.a4;
}
