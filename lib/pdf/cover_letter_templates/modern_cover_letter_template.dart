import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../../models/cover_letter.dart';
import '../../models/template_style.dart';
import '../../constants/pdf_constants.dart';

/// Modern cover letter template - Colorful with accent elements
class ModernCoverLetterTemplate {
  ModernCoverLetterTemplate._();

  static void build(
    pw.Document pdf,
    CoverLetter letter,
    TemplateStyle style, {
    String? senderAddress,
    String? senderPhone,
    String? senderEmail,
  }) {
    final primaryColor = PdfColor.fromInt(style.primaryColor.toARGB32());
    final accentColor = PdfColor.fromInt(style.accentColor.toARGB32());

    pdf.addPage(
      pw.Page(
        pageFormat: PdfConstants.pageFormat,
        margin: pw.EdgeInsets.zero,
        build: (context) => pw.Column(
          children: [
            // Header bar
            pw.Container(
              width: double.infinity,
              padding:
                  const pw.EdgeInsets.symmetric(horizontal: 50, vertical: 30),
              color: primaryColor,
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  // Name and contact
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        letter.senderName ?? '',
                        style: pw.TextStyle(
                          fontSize: 22,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.white,
                        ),
                      ),
                      pw.SizedBox(height: 8),
                      if (senderEmail != null) _buildContactItem(senderEmail),
                      if (senderPhone != null) _buildContactItem(senderPhone),
                      if (senderAddress != null)
                        _buildContactItem(senderAddress),
                    ],
                  ),
                  // Date
                  pw.Container(
                    padding: const pw.EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: pw.BoxDecoration(
                      color: accentColor,
                      borderRadius: pw.BorderRadius.circular(4),
                    ),
                    child: pw.Text(
                      _formatDate(DateTime.now()),
                      style: const pw.TextStyle(
                        fontSize: 10,
                        color: PdfColors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Main content
            pw.Expanded(
              child: pw.Container(
                padding: const pw.EdgeInsets.all(50),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    // Recipient info
                    if (letter.companyName != null ||
                        letter.recipientName != null)
                      _buildRecipientBlock(letter, primaryColor),
                    pw.SizedBox(height: 24),

                    // Subject
                    if (letter.jobTitle != null) ...[
                      pw.Row(
                        children: [
                          pw.Container(
                            width: 4,
                            height: 20,
                            color: accentColor,
                          ),
                          pw.SizedBox(width: 8),
                          pw.Text(
                            'Application for ${letter.jobTitle}',
                            style: pw.TextStyle(
                              fontSize: 14,
                              fontWeight: pw.FontWeight.bold,
                              color: PdfConstants.modernText,
                            ),
                          ),
                        ],
                      ),
                      pw.SizedBox(height: 20),
                    ],

                    // Greeting
                    pw.Text(
                      letter.greeting,
                      style: pw.TextStyle(
                        fontSize: 11,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfConstants.modernText,
                      ),
                    ),
                    pw.SizedBox(height: 12),

                    // Body
                    pw.Text(
                      letter.processedBody,
                      style: const pw.TextStyle(
                        fontSize: 10,
                        color: PdfConstants.modernText,
                        lineSpacing: 4,
                      ),
                    ),
                    pw.SizedBox(height: 24),

                    // Closing
                    pw.Text(
                      letter.closing,
                      style: const pw.TextStyle(
                        fontSize: 11,
                        color: PdfConstants.modernText,
                      ),
                    ),
                    pw.SizedBox(height: 30),

                    // Signature with accent
                    pw.Row(
                      children: [
                        pw.Container(
                          width: 40,
                          height: 2,
                          color: accentColor,
                        ),
                        pw.SizedBox(width: 12),
                        pw.Text(
                          letter.senderName ?? '',
                          style: pw.TextStyle(
                            fontSize: 12,
                            fontWeight: pw.FontWeight.bold,
                            color: primaryColor,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Footer bar
            pw.Container(
              width: double.infinity,
              height: 8,
              color: accentColor,
            ),
          ],
        ),
      ),
    );
  }

  static pw.Widget _buildContactItem(String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 2),
      child: pw.Text(
        text,
        style: const pw.TextStyle(
          fontSize: 9,
          color: PdfColor.fromInt(0xDDFFFFFF),
        ),
      ),
    );
  }

  static pw.Widget _buildRecipientBlock(
      CoverLetter letter, PdfColor primaryColor) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        border: pw.Border(
          left: pw.BorderSide(color: primaryColor, width: 3),
        ),
        color: const PdfColor.fromInt(0x0A000000),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          if (letter.recipientName != null)
            pw.Text(
              letter.recipientName!,
              style: pw.TextStyle(
                fontSize: 11,
                fontWeight: pw.FontWeight.bold,
                color: PdfConstants.modernText,
              ),
            ),
          if (letter.recipientTitle != null)
            pw.Text(
              letter.recipientTitle!,
              style: const pw.TextStyle(
                fontSize: 10,
                color: PdfConstants.modernMuted,
              ),
            ),
          if (letter.companyName != null)
            pw.Text(
              letter.companyName!,
              style: pw.TextStyle(
                fontSize: 11,
                color: primaryColor,
              ),
            ),
        ],
      ),
    );
  }

  static String _formatDate(DateTime date) {
    const months = [
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
