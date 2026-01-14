import 'dart:typed_data';
import 'package:pdf/widgets.dart' as pw;
import '../../models/cover_letter.dart';
import '../../models/cv_data.dart';
import '../../models/template_style.dart';
import '../../models/template_customization.dart';
import '../shared/base_pdf_template.dart';
import '../shared/pdf_styling.dart';
import '../shared/cv_translations.dart';
import '../components/components.dart';

/// Professional Cover Letter Template
///
/// A flexible, professional cover letter template that uses the component
/// system for consistent styling and layout. Supports multiple header
/// layouts and customization options.
///
/// Features:
/// - Clean, professional design
/// - Component-based architecture
/// - Full customization support
/// - Proper typography and spacing
/// - Dark mode support
/// - Multiple header layouts
class ProfessionalCoverLetterTemplate extends BasePdfTemplate<CoverLetter>
    with PdfTemplateHelpers {
  ProfessionalCoverLetterTemplate._();

  /// Singleton instance
  static final instance = ProfessionalCoverLetterTemplate._();

  @override
  TemplateInfo get info => const TemplateInfo(
        id: 'professional_cover_letter',
        name: 'Professional',
        description: 'Clean, flexible professional cover letter template',
        category: 'cover_letter',
        previewTags: ['professional', 'clean', 'flexible'],
      );

  @override
  Future<Uint8List> build(
    CoverLetter coverLetter,
    TemplateStyle style, {
    TemplateCustomization? customization,
    Uint8List? profileImageBytes,
  }) async {
    final pdf = createDocument(
      title: 'Cover Letter - ${coverLetter.name}',
      author: coverLetter.senderName ?? 'MyJob',
    );

    final fonts = await loadFonts(style);
    final s = PdfStyling(
      style: style,
      customization: customization ?? const TemplateCustomization(),
    );

    // Create ContactDetails from cover letter data
    final contact = _buildContactDetails(coverLetter);

    // Use Modern header layout by default for this template
    final headerLayout = _mapHeaderStyle(
      customization?.headerStyle ?? HeaderStyle.modern,
    );

    pdf.addPage(
      pw.MultiPage(
        pageTheme: PdfPageThemes.standard(
          regularFont: fonts.regular,
          boldFont: fonts.bold,
          mediumFont: fonts.medium,
          styling: s,
        ),
        build: (context) => [
          // Header with name and contact info
          HeaderComponent.coverLetterHeader(
            name: coverLetter.senderName ?? contact?.fullName ?? 'Your Name',
            contact: contact,
            styling: s,
            layout: headerLayout,
          ),

          pw.SizedBox(height: s.sectionGapMajor),

          // Date
          _buildDateSection(s),

          pw.SizedBox(height: s.space6),

          // Recipient details (if provided)
          if (s.customization.showRecipient &&
              _hasRecipientInfo(coverLetter)) ...[
            _buildRecipientSection(coverLetter, s),
            pw.SizedBox(height: s.space6),
          ],

          // Subject Line (Bold, matching standard)
          if (s.customization.showSubject &&
              (coverLetter.subject?.isNotEmpty ?? false)) ...[
            pw.Text(
              coverLetter.subject!,
              style: pw.TextStyle(
                fontSize: s.fontSizeBody,
                fontWeight: pw.FontWeight.bold,
                color: s.textPrimary,
              ),
            ),
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
              fontWeight: pw.FontWeight.bold,
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
              color: s.textSecondary,
            ),
          ),

          pw.SizedBox(height: s.space6),

          // Signature
          _buildSignature(
            coverLetter.senderName ?? contact?.fullName ?? '',
            s,
          ),
        ],
      ),
    );

    return pdf.save();
  }

  // ===========================================================================
  // SECTION BUILDERS
  // ===========================================================================

  /// Build the date section with accent
  pw.Widget _buildDateSection(PdfStyling s) {
    final now = DateTime.now();
    final formattedDate = _formatDate(now);

    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.end, // Right-align the date
      children: [
        pw.Container(
          width: 4,
          height: 16,
          decoration: pw.BoxDecoration(
            color: s.accent,
            borderRadius: pw.BorderRadius.circular(2),
          ),
        ),
        pw.SizedBox(width: s.space3),
        pw.Text(
          CvTranslations.translateDate(
            formattedDate,
            s.customization.language,
          ),
          style: pw.TextStyle(
            fontSize: s.fontSizeSmall,
            color: s.textSecondary,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
      ],
    );
  }

  /// Build recipient section
  pw.Widget _buildRecipientSection(CoverLetter coverLetter, PdfStyling s) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        // Recipient name
        if (coverLetter.recipientName?.isNotEmpty ?? false)
          pw.Text(
            coverLetter.recipientName!,
            style: pw.TextStyle(
              fontSize: s.fontSizeBody,
              fontWeight: pw.FontWeight.bold,
              color: s.textPrimary,
            ),
          ),

        // Recipient title
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

        // Company name
        if (coverLetter.companyName?.isNotEmpty ?? false) ...[
          pw.SizedBox(height: s.space1),
          pw.Text(
            coverLetter.companyName!,
            style: pw.TextStyle(
              fontSize: s.fontSizeSmall,
              fontWeight: pw.FontWeight.bold,
              color: s.textSecondary,
            ),
          ),
        ],
      ],
    );
  }

  /// Build letter body with paragraph styling
  pw.Widget _buildLetterBody(String body, PdfStyling s) {
    // Normalize line breaks: convert single newlines within paragraphs to spaces,
    // and preserve double newlines as paragraph breaks
    // Also handle cases where user uses single newlines for each paragraph
    String normalizedBody = body;

    // Replace multiple consecutive newlines with a paragraph marker
    normalizedBody = normalizedBody.replaceAll(RegExp(r'\n\s*\n+'), '§PARA§');

    // Replace remaining single newlines with spaces (they're line wraps within a paragraph)
    normalizedBody = normalizedBody.replaceAll(RegExp(r'\n'), ' ');

    // Restore paragraph breaks
    normalizedBody = normalizedBody.replaceAll('§PARA§', '\n\n');

    // Split into paragraphs
    final paragraphs =
        normalizedBody.split('\n\n').where((p) => p.trim().isNotEmpty).toList();

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: paragraphs.map((paragraph) {
        // Check if this is a bullet list
        if (paragraph.trim().startsWith('-') ||
            paragraph.trim().startsWith('*') ||
            paragraph.trim().startsWith('•')) {
          return _buildBulletList(paragraph, s);
        }

        // Regular paragraph
        return pw.Container(
          margin: pw.EdgeInsets.only(bottom: s.paragraphGap),
          child: pw.Text(
            paragraph.trim(),
            style: pw.TextStyle(
              fontSize: s.fontSizeBody,
              height: s.lineHeightRelaxed,
              color: s.textSecondary,
            ),
            textAlign: pw.TextAlign.justify,
          ),
        );
      }).toList(),
    );
  }

  /// Build a bullet list from paragraph text
  pw.Widget _buildBulletList(String paragraph, PdfStyling s) {
    final bullets =
        paragraph.split('\n').where((l) => l.trim().isNotEmpty).toList();

    return pw.Container(
      margin: pw.EdgeInsets.only(bottom: s.paragraphGap),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: bullets.map((bullet) {
          // Remove bullet character
          final cleanBullet = bullet.trim().replaceFirst(
                RegExp(r'^[\-\*\•]\s*'),
                '',
              );

          return pw.Padding(
            padding: pw.EdgeInsets.only(bottom: s.space2, left: s.space2),
            child: pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // Bullet icon using IconComponent
                IconComponent.bullet(
                  styling: s,
                  style: BulletStyle.dot,
                ),
                pw.SizedBox(width: s.space3),
                pw.Expanded(
                  child: pw.Text(
                    cleanBullet,
                    style: pw.TextStyle(
                      fontSize: s.fontSizeBody,
                      height: s.lineHeightNormal,
                      color: s.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  /// Build signature with accent line
  pw.Widget _buildSignature(String name, PdfStyling s) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        // Signature line
        pw.Container(
          width: 180,
          height: 2,
          decoration: pw.BoxDecoration(
            color: s.accent,
            borderRadius: pw.BorderRadius.circular(1),
          ),
        ),
        pw.SizedBox(height: s.space3),
        pw.Text(
          name,
          style: pw.TextStyle(
            fontSize: s.fontSizeH4,
            fontWeight: pw.FontWeight.bold,
            color: s.textPrimary,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }

  // ===========================================================================
  // HELPER METHODS
  // ===========================================================================

  /// Build ContactDetails from CoverLetter
  ContactDetails? _buildContactDetails(CoverLetter coverLetter) {
    // Cover letters don't have embedded contact details,
    // but we can return null and let the header component handle it
    return null;
  }

  /// Check if recipient information is provided
  bool _hasRecipientInfo(CoverLetter coverLetter) {
    return (coverLetter.recipientName?.isNotEmpty ?? false) ||
        (coverLetter.recipientTitle?.isNotEmpty ?? false) ||
        (coverLetter.companyName?.isNotEmpty ?? false);
  }

  /// Map HeaderStyle to HeaderLayout
  HeaderLayout _mapHeaderStyle(HeaderStyle style) {
    switch (style) {
      case HeaderStyle.modern:
        return HeaderLayout.modern;
      case HeaderStyle.clean:
        return HeaderLayout.clean;
      case HeaderStyle.sidebar:
        return HeaderLayout.sidebar;
      case HeaderStyle.compact:
        return HeaderLayout.compact;
    }
  }

  /// Format date in professional style
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
