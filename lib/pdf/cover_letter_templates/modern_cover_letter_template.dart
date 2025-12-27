import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../../models/cover_letter.dart';
import '../../models/template_style.dart';
import '../../constants/pdf_constants.dart';
import '../shared/pdf_components.dart';

/// Modern Cover Letter Template - Contemporary Design with Color Accents
///
/// Features:
/// - Colored header bar with sender info
/// - Modern typography and spacing
/// - Accent color highlights
/// - Contemporary business format
class ModernCoverLetterTemplate {
  ModernCoverLetterTemplate._();

  static void build(
    pw.Document pdf,
    CoverLetter letter,
    TemplateStyle style, {
    required pw.Font regularFont,
    required pw.Font boldFont,
    required pw.Font mediumFont,
    String? senderAddress,
    String? senderPhone,
    String? senderEmail,
  }) {
    final primaryColor = PdfColor.fromInt(style.primaryColor.toARGB32());
    final accentColor = PdfColor.fromInt(style.accentColor.toARGB32());

    // Create font fallback list for Unicode support
    final fontFallback = PdfComponents.getFontFallback(
      regularFont: regularFont,
      boldFont: boldFont,
      mediumFont: mediumFont,
    );

    pdf.addPage(
      pw.Page(
        pageFormat: PdfConstants.pageFormat,
        margin: pw.EdgeInsets.zero,
        theme: pw.ThemeData.withFont(
          base: regularFont,
          bold: boldFont,
          fontFallback: fontFallback,
        ),
        build: (context) => pw.Column(
          children: [
            // Colored header bar
            _buildHeader(
              letter,
              primaryColor,
              accentColor,
              senderEmail: senderEmail,
              senderPhone: senderPhone,
              senderAddress: senderAddress,
            ),

            // Main content area
            pw.Expanded(
              child: pw.Container(
                padding: const pw.EdgeInsets.symmetric(
                  horizontal: PdfConstants.marginLeft + 10,
                  vertical: PdfConstants.space3xl,
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    // Recipient information with styled border
                    _buildRecipientBlock(
                      letter,
                      primaryColor,
                      accentColor,
                    ),

                    pw.SizedBox(height: PdfConstants.space2xl),

                    // Subject line with accent bar
                    if (letter.jobTitle != null &&
                        letter.jobTitle!.isNotEmpty) ...[
                      _buildSubjectLine(letter.jobTitle!, accentColor),
                      pw.SizedBox(height: PdfConstants.spaceLg),
                    ],

                    // Greeting
                    pw.Text(
                      letter.greeting,
                      style: pw.TextStyle(
                        fontSize: PdfConstants.fontSizeH4,
                        fontWeight: pw.FontWeight.bold,
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

                    pw.SizedBox(height: PdfConstants.space2xl + 8),

                    // Signature with accent line
                    _buildSignature(
                      letter.senderName ?? '',
                      primaryColor,
                      accentColor,
                    ),
                  ],
                ),
              ),
            ),

            // Footer accent bar
            pw.Container(
              width: double.infinity,
              height: PdfConstants.accentDividerThickness * 2,
              color: accentColor,
            ),
          ],
        ),
      ),
    );
  }

  /// Build colored header with sender information and date
  static pw.Widget _buildHeader(
    CoverLetter letter,
    PdfColor primaryColor,
    PdfColor accentColor, {
    String? senderEmail,
    String? senderPhone,
    String? senderAddress,
  }) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.symmetric(
        horizontal: PdfConstants.marginLeft + 10,
        vertical: PdfConstants.space2xl,
      ),
      color: primaryColor,
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          // Sender name and contact info
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                letter.senderName ?? 'Your Name',
                style: pw.TextStyle(
                  fontSize: PdfConstants.fontSizeH2 + 4,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.white,
                  letterSpacing: PdfConstants.letterSpacingTight,
                ),
              ),
              pw.SizedBox(height: PdfConstants.spaceSm),
              if (senderEmail != null)
                _buildContactItemWithIcon(PdfConstants.iconEmail, senderEmail),
              if (senderPhone != null)
                _buildContactItemWithIcon(PdfConstants.iconPhone, senderPhone),
              if (senderAddress != null)
                _buildContactItemWithIcon(PdfConstants.iconLocation, senderAddress),
            ],
          ),

          // Date badge
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(
              horizontal: PdfConstants.badgePaddingH + 2,
              vertical: PdfConstants.badgePaddingV + 2,
            ),
            decoration: pw.BoxDecoration(
              color: accentColor,
              borderRadius: pw.BorderRadius.circular(PdfConstants.borderRadius),
            ),
            child: pw.Text(
              PdfComponents.formatLetterDate(DateTime.now()),
              style: pw.TextStyle(
                fontSize: PdfConstants.fontSizeSmall,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Contact item in header with circular badge icon
  static pw.Widget _buildContactItemWithIcon(String icon, String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(top: PdfConstants.spaceXs),
      child: pw.Row(
        mainAxisSize: pw.MainAxisSize.min,
        children: [
          // Circular badge with letter
          pw.Container(
            width: 14,
            height: 14,
            decoration: pw.BoxDecoration(
              color: PdfConstants.withOpacity(PdfColors.white, 0.9),
              shape: pw.BoxShape.circle,
            ),
            child: pw.Center(
              child: pw.Text(
                icon,
                style: pw.TextStyle(
                  fontSize: 7,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfConstants.modernPrimary,
                ),
              ),
            ),
          ),
          pw.SizedBox(width: 6),
          pw.Text(
            text,
            style: pw.TextStyle(
              fontSize: PdfConstants.fontSizeSmall,
              color: PdfConstants.withOpacity(PdfColors.white, 0.95),
            ),
          ),
        ],
      ),
    );
  }

  /// Recipient information block with styled border
  static pw.Widget _buildRecipientBlock(
    CoverLetter letter,
    PdfColor primaryColor,
    PdfColor accentColor,
  ) {
    final hasRecipientInfo = letter.recipientName != null ||
        letter.recipientTitle != null ||
        letter.companyName != null;

    if (!hasRecipientInfo) return pw.SizedBox();

    return pw.Container(
      padding: const pw.EdgeInsets.all(PdfConstants.spaceLg),
      decoration: pw.BoxDecoration(
        border: pw.Border(
          left: pw.BorderSide(
            color: primaryColor,
            width: PdfConstants.accentDividerThickness + 0.5,
          ),
        ),
        color: PdfConstants.withOpacity(accentColor, 0.05),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          if (letter.recipientName != null) ...[
            pw.Text(
              letter.recipientName!,
              style: pw.TextStyle(
                fontSize: PdfConstants.fontSizeH4,
                fontWeight: pw.FontWeight.bold,
                color: PdfConstants.textDark,
              ),
            ),
            pw.SizedBox(height: PdfConstants.spaceXs),
          ],
          if (letter.recipientTitle != null) ...[
            pw.Text(
              letter.recipientTitle!,
              style: pw.TextStyle(
                fontSize: PdfConstants.fontSizeBody,
                color: PdfConstants.textMuted,
              ),
            ),
            pw.SizedBox(height: PdfConstants.spaceXs),
          ],
          if (letter.companyName != null)
            pw.Text(
              letter.companyName!,
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

  /// Subject line with accent bar
  static pw.Widget _buildSubjectLine(String jobTitle, PdfColor accentColor) {
    return pw.Row(
      children: [
        pw.Container(
          width: PdfConstants.accentDividerThickness + 1.5,
          height: PdfConstants.fontSizeH3 + 4,
          color: accentColor,
        ),
        pw.SizedBox(width: PdfConstants.spaceSm),
        pw.Text(
          'Application for $jobTitle',
          style: pw.TextStyle(
            fontSize: PdfConstants.fontSizeH3,
            fontWeight: pw.FontWeight.bold,
            color: PdfConstants.textDark,
          ),
        ),
      ],
    );
  }

  /// Signature with decorative accent line
  static pw.Widget _buildSignature(
    String name,
    PdfColor primaryColor,
    PdfColor accentColor,
  ) {
    return pw.Row(
      children: [
        pw.Container(
          width: 40,
          height: PdfConstants.accentDividerThickness,
          color: accentColor,
        ),
        pw.SizedBox(width: PdfConstants.spaceMd),
        pw.Text(
          name,
          style: pw.TextStyle(
            fontSize: PdfConstants.fontSizeH4,
            fontWeight: pw.FontWeight.bold,
            color: primaryColor,
          ),
        ),
      ],
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
