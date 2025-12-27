import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models/cover_letter.dart';
import '../models/cv_data.dart';
import '../models/template_style.dart';

/// Service for generating professional cover letter PDFs from CoverLetter model
class CoverLetterTemplatePdfService {
  /// Generate a cover letter PDF from CoverLetter data
  Future<File> generatePdfFromCoverLetter({
    required CoverLetter coverLetter,
    required String outputPath,
    ContactDetails? contactDetails,
    TemplateStyle? templateStyle,
  }) async {
    final style = templateStyle ?? TemplateStyle.professional;
    final pdf = pw.Document();

    // Load fonts
    final boldFont = await PdfGoogleFonts.interBold();
    final regularFont = await PdfGoogleFonts.interRegular();
    final mediumFont = await PdfGoogleFonts.interMedium();

    // Convert Flutter Color to PdfColor
    final color = style.primaryColor;
    final accentColor = PdfColor(
      (color.r * 255.0).round().clamp(0, 255) / 255,
      (color.g * 255.0).round().clamp(0, 255) / 255,
      (color.b * 255.0).round().clamp(0, 255) / 255,
      (color.a * 255.0).round().clamp(0, 255) / 255,
    );

    // Adjust margins based on template type
    final margins = _getMargins(style.type);

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
                coverLetter,
                contactDetails,
                accentColor,
                boldFont,
                regularFont,
                style.type,
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
              if (coverLetter.recipientName != null ||
                  coverLetter.recipientTitle != null ||
                  coverLetter.companyName != null)
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    if (coverLetter.recipientName != null &&
                        coverLetter.recipientName!.isNotEmpty)
                      pw.Text(
                        coverLetter.recipientName!,
                        style: pw.TextStyle(
                          font: mediumFont,
                          fontSize: 11,
                          color: PdfColors.grey900,
                        ),
                      ),
                    if (coverLetter.recipientTitle != null &&
                        coverLetter.recipientTitle!.isNotEmpty) ...[
                      pw.SizedBox(height: 2),
                      pw.Text(
                        coverLetter.recipientTitle!,
                        style: pw.TextStyle(
                          font: regularFont,
                          fontSize: 10,
                          color: PdfColors.grey700,
                        ),
                      ),
                    ],
                    if (coverLetter.companyName != null &&
                        coverLetter.companyName!.isNotEmpty) ...[
                      pw.SizedBox(height: 2),
                      pw.Text(
                        coverLetter.companyName!,
                        style: pw.TextStyle(
                          font: regularFont,
                          fontSize: 10,
                          color: PdfColors.grey700,
                        ),
                      ),
                    ],
                  ],
                ),
              pw.SizedBox(height: 30),

              // Subject line (if job title is provided)
              if (coverLetter.jobTitle != null &&
                  coverLetter.jobTitle!.isNotEmpty) ...[
                pw.Text(
                  'Re: Application for ${coverLetter.jobTitle}',
                  style: pw.TextStyle(
                    font: boldFont,
                    fontSize: 11,
                    color: accentColor,
                  ),
                ),
                pw.SizedBox(height: 20),
              ],

              // Greeting
              pw.Text(
                coverLetter.greeting,
                style: pw.TextStyle(
                  font: regularFont,
                  fontSize: 11,
                  color: PdfColors.grey900,
                ),
              ),
              pw.SizedBox(height: 15),

              // Letter body (with placeholders replaced)
              pw.Text(
                coverLetter.processedBody,
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
                    coverLetter.closing,
                    style: pw.TextStyle(
                      font: regularFont,
                      fontSize: 11,
                      color: PdfColors.grey900,
                    ),
                  ),
                  pw.SizedBox(height: 30),
                  pw.Text(
                    coverLetter.senderName ??
                        contactDetails?.fullName ??
                        'Your Name',
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
        return const pw.EdgeInsets.all(60); // Contemporary letter margins
    }
  }

  /// Build the header with sender information
  pw.Widget _buildHeader(
    CoverLetter coverLetter,
    ContactDetails? contactDetails,
    PdfColor accentColor,
    pw.Font boldFont,
    pw.Font regularFont,
    TemplateType templateType,
  ) {
    final isClassic = templateType == TemplateType.professional;
    final senderName =
        coverLetter.senderName ?? contactDetails?.fullName ?? 'Your Name';

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        // Name
        pw.Text(
          senderName,
          style: pw.TextStyle(
            font: boldFont,
            fontSize: isClassic ? 24 : 20,
            color: isClassic ? PdfColors.black : accentColor,
            letterSpacing: isClassic ? -0.5 : -0.3,
          ),
        ),
        pw.SizedBox(height: isClassic ? 10 : 8),

        // Contact info - compact format
        if (contactDetails != null) ...[
          pw.Row(
            children: [
              if (contactDetails.email != null &&
                  contactDetails.email!.isNotEmpty) ...[
                pw.Text(
                  contactDetails.email!,
                  style: pw.TextStyle(
                    font: regularFont,
                    fontSize: 9,
                    color: PdfColors.grey700,
                  ),
                ),
                if (contactDetails.phone != null &&
                    contactDetails.phone!.isNotEmpty) ...[
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
              if (contactDetails.phone != null &&
                  contactDetails.phone!.isNotEmpty)
                pw.Text(
                  contactDetails.phone!,
                  style: pw.TextStyle(
                    font: regularFont,
                    fontSize: 9,
                    color: PdfColors.grey700,
                  ),
                ),
            ],
          ),
          if (contactDetails.address != null &&
              contactDetails.address!.isNotEmpty) ...[
            pw.SizedBox(height: 3),
            pw.Text(
              contactDetails.address!,
              style: pw.TextStyle(
                font: regularFont,
                fontSize: 9,
                color: PdfColors.grey700,
              ),
            ),
          ],
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
