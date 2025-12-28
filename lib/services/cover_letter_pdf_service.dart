import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../models/user_data/personal_info.dart';
import '../models/template_style.dart';
import 'pdf_font_service.dart';

/// Service for generating professional cover letter PDFs
class CoverLetterPdfService {
  /// Generate a cover letter PDF
  Future<File> generateCoverLetterPdf({
    required PersonalInfo personalInfo,
    required String companyName,
    required String position,
    required String recipientName,
    required String recipientTitle,
    required String letterBody,
    required String outputPath,
    required PdfColor accentColor,
    TemplateType templateType = TemplateType.professional,
  }) async {
    final pdf = pw.Document();

    // Get fonts from centralized font service (DRY principle)
    final fonts = PdfFontService.getFonts();
    final boldFont = fonts.bold;
    final regularFont = fonts.regular;
    final mediumFont = fonts.medium;

    // Adjust margins based on template type
    final margins = _getMargins(templateType);

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: margins,
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Header with sender info
              _buildHeader(
                personalInfo,
                accentColor,
                boldFont,
                regularFont,
                templateType,
              ),
              pw.SizedBox(height: 40),

              // Date
              pw.Text(
                _formatDate(DateTime.now()),
                style: pw.TextStyle(
                  font: regularFont,
                  fontSize: 10,
                  color: PdfColors.grey700,
                ),
              ),
              pw.SizedBox(height: 30),

              // Recipient info
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    recipientName,
                    style: pw.TextStyle(
                      font: mediumFont,
                      fontSize: 11,
                      color: PdfColors.grey900,
                    ),
                  ),
                  pw.SizedBox(height: 2),
                  pw.Text(
                    recipientTitle,
                    style: pw.TextStyle(
                      font: regularFont,
                      fontSize: 10,
                      color: PdfColors.grey700,
                    ),
                  ),
                  pw.SizedBox(height: 2),
                  pw.Text(
                    companyName,
                    style: pw.TextStyle(
                      font: regularFont,
                      fontSize: 10,
                      color: PdfColors.grey700,
                    ),
                  ),
                ],
              ),
              pw.SizedBox(height: 30),

              // Subject line
              pw.Text(
                'Re: Application for $position',
                style: pw.TextStyle(
                  font: boldFont,
                  fontSize: 11,
                  color: accentColor,
                ),
              ),
              pw.SizedBox(height: 20),

              // Letter body
              pw.Text(
                letterBody,
                style: pw.TextStyle(
                  font: regularFont,
                  fontSize: 11,
                  lineSpacing: 1.6,
                  color: PdfColors.grey900,
                ),
                textAlign: pw.TextAlign.justify,
              ),
              pw.SizedBox(height: 30),

              // Closing
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'Sincerely,',
                    style: pw.TextStyle(
                      font: regularFont,
                      fontSize: 11,
                      color: PdfColors.grey900,
                    ),
                  ),
                  pw.SizedBox(height: 30),
                  pw.Text(
                    personalInfo.fullName,
                    style: pw.TextStyle(
                      font: mediumFont,
                      fontSize: 11,
                      color: accentColor,
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );

    // Save the PDF
    final file = File(outputPath);
    await file.writeAsBytes(await pdf.save());
    return file;
  }

  /// Get margins based on template type
  pw.EdgeInsets _getMargins(TemplateType type) {
    switch (type) {
      case TemplateType.professional:
        return const pw.EdgeInsets.all(70); // Traditional letter margins
      case TemplateType.modern:
      case TemplateType.creative:
        return const pw.EdgeInsets.all(60); // Standard letter margins
      case TemplateType.yellow:
        return const pw.EdgeInsets.all(60); // Yellow template uses custom layout
    }
  }

  /// Build the header with sender information
  pw.Widget _buildHeader(
    PersonalInfo info,
    PdfColor accentColor,
    pw.Font boldFont,
    pw.Font regularFont,
    TemplateType templateType,
  ) {
    final isClassic = templateType == TemplateType.professional;

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        // Name
        pw.Text(
          info.fullName,
          style: pw.TextStyle(
            font: boldFont,
            fontSize: isClassic ? 24 : 20,
            color: isClassic ? PdfColors.black : accentColor,
            letterSpacing: isClassic ? -0.5 : -0.3,
          ),
        ),
        pw.SizedBox(height: isClassic ? 10 : 8),

        // Contact info - compact format
        pw.Row(
          children: [
            if (info.email != null) ...[
              pw.Text(
                info.email!,
                style: pw.TextStyle(
                  font: regularFont,
                  fontSize: 9,
                  color: PdfColors.grey700,
                ),
              ),
              if (info.phone != null) ...[
                pw.SizedBox(width: 12),
                pw.Text(
                  '|',
                  style: pw.TextStyle(
                    font: regularFont,
                    fontSize: 9,
                    color: PdfColors.grey500,
                  ),
                ),
                pw.SizedBox(width: 12),
              ],
            ],
            if (info.phone != null)
              pw.Text(
                info.phone!,
                style: pw.TextStyle(
                  font: regularFont,
                  fontSize: 9,
                  color: PdfColors.grey700,
                ),
              ),
          ],
        ),
        if (info.address != null) ...[
          pw.SizedBox(height: 3),
          pw.Text(
            info.address!,
            style: pw.TextStyle(
              font: regularFont,
              fontSize: 9,
              color: PdfColors.grey700,
            ),
          ),
        ],
        pw.SizedBox(height: isClassic ? 10 : 8),
        pw.Container(
          width: isClassic ? 40 : 60,
          height: isClassic ? 1 : 2,
          color: isClassic ? PdfColors.grey400 : accentColor,
        ),
      ],
    );
  }

  /// Format date for letter
  String _formatDate(DateTime date) {
    final months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December'
    ];

    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }
}
