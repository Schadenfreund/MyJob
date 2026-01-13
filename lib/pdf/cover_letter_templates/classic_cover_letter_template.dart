import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../../models/cover_letter.dart';
import '../../models/cv_data.dart';
import '../../models/template_style.dart';
import '../../models/template_customization.dart';
import '../shared/base_pdf_template.dart';
import '../shared/pdf_styling.dart';
import '../shared/cv_translations.dart';
import '../components/header_component.dart';
import '../../services/pdf_font_service.dart';

/// Classic Cover Letter Template - Conservative, Traditional Design
///
/// Features:
/// - Clean, minimalist design
/// - Traditional formatting
/// - No bold colors or heavy accents
/// - Professional and timeless
/// - Suitable for formal applications
class ClassicCoverLetterTemplate extends BasePdfTemplate<CoverLetter> {
  ClassicCoverLetterTemplate._();

  /// Singleton instance
  static final instance = ClassicCoverLetterTemplate._();

  @override
  TemplateInfo get info => const TemplateInfo(
        id: 'classic_cover_letter',
        name: 'Classic',
        description: 'Conservative, traditional cover letter template',
        category: 'cover_letter',
        previewTags: ['classic', 'traditional', 'conservative'],
      );

  @override
  Future<Uint8List> build(
    CoverLetter coverLetter,
    TemplateStyle style, {
    TemplateCustomization? customization,
    Uint8List? profileImageBytes,
  }) async {
    final pdf = pw.Document(
      title: 'Cover Letter - ${coverLetter.name}',
      author: coverLetter.senderName ?? 'MyJob',
    );

    final fonts = await PdfFontService.getFonts(style.fontFamily);
    final s = PdfStyling(
      style: style,
      customization: customization ?? const TemplateCustomization(),
    );

    // Create ContactDetails from cover letter data
    final contact = _buildContactDetails(coverLetter);

    pdf.addPage(
      pw.MultiPage(
        pageTheme: pw.PageTheme(
          pageFormat: PdfPageFormat.a4,
          margin: pw.EdgeInsets.all(s.space10),
          theme: pw.ThemeData.withFont(
            base: fonts.regular,
            bold: fonts.bold,
            fontFallback: [fonts.regular, fonts.bold, fonts.medium],
          ),
          buildBackground: (context) => pw.FullPage(
            ignoreMargins: true,
            child: pw.Container(color: s.background),
          ),
        ),
        build: (context) => [
          // Traditional header - clean and centered
          HeaderComponent.coverLetterHeader(
            name: coverLetter.senderName ?? contact?.fullName ?? 'Your Name',
            contact: contact,
            styling: s,
            layout:
                HeaderLayout.clean, // Clean, centered layout for traditional
          ),

          pw.SizedBox(height: s.space8),

          // Date (right-aligned, traditional placement)
          _buildDateSection(s),

          pw.SizedBox(height: s.space6),

          // Recipient details (if provided)
          if (_hasRecipientInfo(coverLetter)) ...[
            _buildRecipientSection(coverLetter, s),
            pw.SizedBox(height: s.space6),
          ],

          // Greeting
          pw.Text(
            CvTranslations.translateGreeting(
              coverLetter.greeting,
              s.customization.language,
            ),
            style: pw.TextStyle(
              fontSize: s.fontSizeBody,
              color: s.textPrimary,
            ),
          ),

          pw.SizedBox(height: s.space5),

          // Letter body
          _buildLetterBody(coverLetter.processedBody, s),

          pw.SizedBox(height: s.space5),

          // Closing
          pw.Text(
            CvTranslations.translateClosing(
              coverLetter.closing,
              s.customization.language,
            ),
            style: pw.TextStyle(
              fontSize: s.fontSizeBody,
              color: s.textPrimary,
            ),
          ),

          pw.SizedBox(height: s.space8),

          // Signature (simple name)
          pw.Text(
            coverLetter.senderName ?? contact?.fullName ?? '',
            style: pw.TextStyle(
              fontSize: s.fontSizeBody,
              fontWeight: pw.FontWeight.bold,
              color: s.textPrimary,
            ),
          ),
        ],
      ),
    );

    return pdf.save();
  }

  // ===========================================================================
  // SECTION BUILDERS
  // ===========================================================================

  /// Build date section (right-aligned)
  pw.Widget _buildDateSection(PdfStyling s) {
    final now = DateTime.now();
    final formattedDate = _formatDate(now);

    return pw.Align(
      alignment: pw.Alignment.centerRight,
      child: pw.Text(
        CvTranslations.translateDate(
          formattedDate,
          s.customization.language,
        ),
        style: pw.TextStyle(
          fontSize: s.fontSizeSmall,
          color: s.textSecondary,
        ),
      ),
    );
  }

  /// Build recipient section
  pw.Widget _buildRecipientSection(CoverLetter coverLetter, PdfStyling s) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        if (coverLetter.recipientName?.isNotEmpty ?? false)
          pw.Text(
            coverLetter.recipientName!,
            style: pw.TextStyle(
              fontSize: s.fontSizeBody,
              color: s.textPrimary,
            ),
          ),
        if (coverLetter.recipientTitle?.isNotEmpty ?? false) ...[
          pw.SizedBox(height: s.space1),
          pw.Text(
            coverLetter.recipientTitle!,
            style: pw.TextStyle(
              fontSize: s.fontSizeSmall,
              color: s.textSecondary,
            ),
          ),
        ],
        if (coverLetter.companyName?.isNotEmpty ?? false) ...[
          pw.SizedBox(height: s.space1),
          pw.Text(
            coverLetter.companyName!,
            style: pw.TextStyle(
              fontSize: s.fontSizeSmall,
              color: s.textSecondary,
            ),
          ),
        ],
      ],
    );
  }

  /// Build letter body with paragraph styling
  pw.Widget _buildLetterBody(String body, PdfStyling s) {
    // Normalize line breaks for proper paragraph formatting
    String normalizedBody = body;
    normalizedBody = normalizedBody.replaceAll(RegExp(r'\n\s*\n+'), '§PARA§');
    normalizedBody = normalizedBody.replaceAll(RegExp(r'\n'), ' ');
    normalizedBody = normalizedBody.replaceAll('§PARA§', '\n\n');

    final paragraphs =
        normalizedBody.split('\n\n').where((p) => p.trim().isNotEmpty).toList();

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: paragraphs.map((paragraph) {
        return pw.Container(
          margin: pw.EdgeInsets.only(bottom: s.paragraphGap),
          child: pw.Text(
            paragraph.trim(),
            style: pw.TextStyle(
              fontSize: s.fontSizeBody,
              height: s.lineHeightRelaxed,
              color: s.textPrimary,
            ),
            textAlign: pw.TextAlign.justify,
          ),
        );
      }).toList(),
    );
  }

  // ===========================================================================
  // HELPER METHODS
  // ===========================================================================

  /// Build ContactDetails from CoverLetter
  ContactDetails? _buildContactDetails(CoverLetter coverLetter) {
    return null;
  }

  /// Check if recipient information is provided
  bool _hasRecipientInfo(CoverLetter coverLetter) {
    return (coverLetter.recipientName?.isNotEmpty ?? false) ||
        (coverLetter.recipientTitle?.isNotEmpty ?? false) ||
        (coverLetter.companyName?.isNotEmpty ?? false);
  }

  /// Format date in traditional style
  String _formatDate(DateTime date) {
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
      'December',
    ];

    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }
}
