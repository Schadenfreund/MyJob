import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../../models/cover_letter.dart';
import '../../models/template_style.dart';
import '../../constants/pdf_constants.dart';

/// Professional cover letter template - Clean business letter format
class ProfessionalCoverLetterTemplate {
  ProfessionalCoverLetterTemplate._();

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
        margin: const pw.EdgeInsets.only(
          top: PdfConstants.marginTop,
          bottom: PdfConstants.marginBottom,
          left: PdfConstants.marginLeft,
          right: PdfConstants.marginRight,
        ),
        build: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            // Header with sender info
            _buildHeader(
              letter,
              primaryColor,
              accentColor,
              senderAddress: senderAddress,
              senderPhone: senderPhone,
              senderEmail: senderEmail,
            ),
            pw.SizedBox(height: 30),

            // Date
            pw.Text(
              _formatDate(DateTime.now()),
              style: const pw.TextStyle(
                fontSize: PdfConstants.fontSizeBody,
                color: PdfConstants.professionalMuted,
              ),
            ),
            pw.SizedBox(height: 20),

            // Recipient info
            if (letter.recipientName != null || letter.companyName != null)
              _buildRecipientInfo(letter),
            pw.SizedBox(height: 20),

            // Subject line
            if (letter.jobTitle != null) ...[
              pw.Text(
                'Re: Application for ${letter.jobTitle}',
                style: pw.TextStyle(
                  fontSize: PdfConstants.fontSizeBody,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfConstants.professionalText,
                ),
              ),
              pw.SizedBox(height: 20),
            ],

            // Greeting
            pw.Text(
              letter.greeting,
              style: const pw.TextStyle(
                fontSize: PdfConstants.fontSizeBody,
                color: PdfConstants.professionalText,
              ),
            ),
            pw.SizedBox(height: 16),

            // Body
            pw.Text(
              letter.processedBody,
              style: const pw.TextStyle(
                fontSize: PdfConstants.fontSizeBody,
                color: PdfConstants.professionalText,
                lineSpacing: 4,
              ),
            ),
            pw.SizedBox(height: 24),

            // Closing
            pw.Text(
              letter.closing,
              style: const pw.TextStyle(
                fontSize: PdfConstants.fontSizeBody,
                color: PdfConstants.professionalText,
              ),
            ),
            pw.SizedBox(height: 40),

            // Signature
            pw.Text(
              letter.senderName ?? '',
              style: pw.TextStyle(
                fontSize: PdfConstants.fontSizeBody,
                fontWeight: pw.FontWeight.bold,
                color: PdfConstants.professionalText,
              ),
            ),
          ],
        ),
      ),
    );
  }

  static pw.Widget _buildHeader(
    CoverLetter letter,
    PdfColor primaryColor,
    PdfColor accentColor, {
    String? senderAddress,
    String? senderPhone,
    String? senderEmail,
  }) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          letter.senderName ?? '',
          style: pw.TextStyle(
            fontSize: PdfConstants.fontSizeName,
            fontWeight: pw.FontWeight.bold,
            color: primaryColor,
          ),
        ),
        pw.SizedBox(height: 8),
        pw.Divider(color: accentColor, thickness: 2),
        pw.SizedBox(height: 8),
        pw.Row(
          children: [
            if (senderEmail != null)
              pw.Text(
                senderEmail,
                style: const pw.TextStyle(
                  fontSize: PdfConstants.fontSizeSmall,
                  color: PdfConstants.professionalMuted,
                ),
              ),
            if (senderPhone != null) ...[
              pw.SizedBox(width: 16),
              pw.Text(
                senderPhone,
                style: const pw.TextStyle(
                  fontSize: PdfConstants.fontSizeSmall,
                  color: PdfConstants.professionalMuted,
                ),
              ),
            ],
            if (senderAddress != null) ...[
              pw.SizedBox(width: 16),
              pw.Text(
                senderAddress,
                style: const pw.TextStyle(
                  fontSize: PdfConstants.fontSizeSmall,
                  color: PdfConstants.professionalMuted,
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }

  static pw.Widget _buildRecipientInfo(CoverLetter letter) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        if (letter.recipientName != null)
          pw.Text(
            letter.recipientName!,
            style: const pw.TextStyle(
              fontSize: PdfConstants.fontSizeBody,
              color: PdfConstants.professionalText,
            ),
          ),
        if (letter.recipientTitle != null)
          pw.Text(
            letter.recipientTitle!,
            style: const pw.TextStyle(
              fontSize: PdfConstants.fontSizeBody,
              color: PdfConstants.professionalMuted,
            ),
          ),
        if (letter.companyName != null)
          pw.Text(
            letter.companyName!,
            style: pw.TextStyle(
              fontSize: PdfConstants.fontSizeBody,
              fontWeight: pw.FontWeight.bold,
              color: PdfConstants.professionalText,
            ),
          ),
      ],
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
