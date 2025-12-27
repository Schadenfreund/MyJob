import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../../models/cover_letter.dart';
import '../../models/template_style.dart';
import '../../constants/pdf_constants.dart';
import '../shared/pdf_components.dart';

/// Professional Cover Letter Template - Clean Business Format
///
/// Features:
/// - Professional business letter layout
/// - Clean typography and spacing
/// - Consistent header with CV template
/// - Proper formal letter structure
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
      pw.MultiPage(
        pageFormat: PdfConstants.pageFormat,
        margin: const pw.EdgeInsets.only(
          top: PdfConstants.marginTop,
          bottom: PdfConstants.marginBottom,
          left: PdfConstants.marginLeft,
          right: PdfConstants.marginRight,
        ),
        build: (context) => [
          // Header with sender info
          PdfComponents.buildDocumentHeader(
            name: letter.senderName ?? 'Your Name',
            email: senderEmail,
            phone: senderPhone,
            address: senderAddress,
            primaryColor: primaryColor,
            accentColor: accentColor,
            largeHeader: false,
          ),

          pw.SizedBox(height: PdfConstants.space2xl),

          // Date
          pw.Text(
            PdfComponents.formatLetterDate(DateTime.now()),
            style: pw.TextStyle(
              fontSize: PdfConstants.fontSizeBody,
              color: PdfConstants.textMuted,
            ),
          ),

          pw.SizedBox(height: PdfConstants.spaceLg),

          // Recipient information
          PdfComponents.buildRecipientBlock(
            recipientName: letter.recipientName,
            recipientTitle: letter.recipientTitle,
            companyName: letter.companyName,
          ),

          pw.SizedBox(height: PdfConstants.spaceLg),

          // Subject line (optional)
          if (letter.jobTitle != null && letter.jobTitle!.isNotEmpty) ...[
            pw.RichText(
              text: pw.TextSpan(
                children: [
                  pw.TextSpan(
                    text: 'Re: ',
                    style: pw.TextStyle(
                      fontSize: PdfConstants.fontSizeBody,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfConstants.textDark,
                    ),
                  ),
                  pw.TextSpan(
                    text: 'Application for ${letter.jobTitle}',
                    style: pw.TextStyle(
                      fontSize: PdfConstants.fontSizeBody,
                      color: PdfConstants.textBody,
                    ),
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: PdfConstants.spaceLg),
          ],

          // Greeting
          pw.Text(
            letter.greeting,
            style: pw.TextStyle(
              fontSize: PdfConstants.fontSizeBody,
              color: PdfConstants.textDark,
            ),
          ),

          pw.SizedBox(height: PdfConstants.letterParagraphSpacing),

          // Body paragraphs
          ..._buildBodyParagraphs(letter.processedBody),

          pw.SizedBox(height: PdfConstants.letterParagraphSpacing),

          // Closing
          pw.Text(
            letter.closing,
            style: pw.TextStyle(
              fontSize: PdfConstants.fontSizeBody,
              color: PdfConstants.textDark,
            ),
          ),

          pw.SizedBox(height: PdfConstants.letterSignatureSpace),

          // Signature
          pw.Text(
            letter.senderName ?? '',
            style: pw.TextStyle(
              fontSize: PdfConstants.fontSizeBody,
              fontWeight: pw.FontWeight.bold,
              color: primaryColor,
            ),
          ),
        ],
      ),
    );
  }

  /// Split body text into paragraphs and build widgets
  static List<pw.Widget> _buildBodyParagraphs(String body) {
    // Split by double newlines to get paragraphs
    final paragraphs = body.split('\n\n').where((p) => p.trim().isNotEmpty);

    final widgets = <pw.Widget>[];
    for (final paragraph in paragraphs) {
      widgets.add(
        PdfComponents.buildParagraph(
          paragraph.trim().replaceAll('\n', ' '),
          justified: true,
        ),
      );
      widgets.add(pw.SizedBox(height: PdfConstants.letterParagraphSpacing));
    }

    // Remove last spacing
    if (widgets.isNotEmpty && widgets.length > 1) {
      widgets.removeLast();
    }

    return widgets;
  }
}
