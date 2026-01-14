import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../../models/cover_letter.dart';
import '../../models/cv_data.dart';
import '../../models/template_style.dart';
import '../../models/template_customization.dart';
import '../../constants/pdf_constants.dart';
import '../shared/pdf_styling.dart';
import '../shared/cv_translations.dart';

/// Electric Cover Letter Template - Matching Magazine-Style Design
///
/// Features:
/// - Bold asymmetric magazine layout matching Electric CV
/// - Dynamic accent colors (respects theme settings)
/// - Professional typography with brutalist aesthetic
/// - Geometric accent shapes
/// - High-contrast professional design (light/dark mode)
class ElectricCoverLetterTemplate {
  ElectricCoverLetterTemplate._();

  /// Singleton instance
  static final instance = ElectricCoverLetterTemplate._();

  /// Template name
  String get templateName => 'Electric';

  /// Template description
  String get templateDescription =>
      'Modern, bold design matching Electric CV template';

  /// Build the Electric Cover Letter PDF with stunning magazine-style design
  static void build(
    pw.Document pdf,
    CoverLetter coverLetter,
    TemplateStyle style,
    ContactDetails? contactDetails, {
    required pw.Font regularFont,
    required pw.Font boldFont,
    required pw.Font mediumFont,
    TemplateCustomization? customization,
  }) {
    // Create styling from template style (respects dark mode, accent color, and customization)
    final s = PdfStyling(style: style, customization: customization);

    // Build page with custom theme
    pdf.addPage(
      pw.Page(
        pageFormat: PdfConstants.pageFormat,
        margin: pw.EdgeInsets.zero,
        theme: pw.ThemeData.withFont(
          base: regularFont,
          bold: boldFont,
          fontFallback: [regularFont, boldFont, mediumFont],
        ),
        build: (context) => pw.Column(
          children: [
            // Hero header matching CV template
            _buildHeroHeader(contactDetails, s),

            // Main letter content
            pw.Expanded(
              child: pw.Container(
                color: s.background,
                padding: pw.EdgeInsets.symmetric(
                  horizontal: s.space12,
                  vertical: s.space8,
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    // Recipient details
                    _buildRecipientSection(coverLetter, s),

                    pw.SizedBox(height: s.sectionGapMinor),

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
                      pw.SizedBox(height: s.sectionGapMinor),
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

                    pw.SizedBox(height: s.space4),

                    // Letter body with electric accents
                    _buildLetterBody(coverLetter.processedBody, s),

                    pw.SizedBox(height: s.sectionGapMinor),

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

                    pw.SizedBox(height: s.space4),

                    // Signature with accent color
                    _buildSignature(contactDetails?.fullName ?? '', s),
                  ],
                ),
              ),
            ),

            // Footer bar (matching header)
            pw.Container(
              width: double.infinity,
              height: 8,
              color: s.accent,
            ),
          ],
        ),
      ),
    );
  }

  /// Build stunning hero header matching CV template
  static pw.Widget _buildHeroHeader(
      ContactDetails? contactDetails, PdfStyling s) {
    final name = contactDetails?.fullName ?? 'Your Name';

    // Faded accent for geometric shape
    final accentFaded = PdfColor(
      s.accent.red,
      s.accent.green,
      s.accent.blue,
      0.15,
    );

    return pw.Stack(
      children: [
        // Black background banner
        pw.Container(
          width: double.infinity,
          height: 140,
          color: s.headerBackground,
        ),

        // Accent bar (top)
        pw.Container(
          width: double.infinity,
          height: 8,
          color: s.accent,
        ),

        // Geometric accent (diagonal)
        pw.Positioned(
          right: 0,
          top: 0,
          child: pw.Transform.rotate(
            angle: 0.15,
            child: pw.Container(
              width: 220,
              height: 120,
              color: accentFaded,
            ),
          ),
        ),

        // Main content
        pw.Positioned.fill(
          child: pw.Container(
            padding: pw.EdgeInsets.symmetric(horizontal: s.space12),
            child: pw.Column(
              mainAxisAlignment: pw.MainAxisAlignment.center,
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // Name in huge bold letters
                pw.Text(
                  name.toUpperCase(),
                  style: pw.TextStyle(
                    fontSize: s.fontSizeH1 * 1.5,
                    fontWeight: pw.FontWeight.bold,
                    color: s.headerText,
                    letterSpacing: s.letterSpacingExtraWide,
                    height: 1.1,
                  ),
                ),

                pw.SizedBox(height: s.space3),

                // Contact info with icons
                pw.Row(
                  children: [
                    if (contactDetails?.email != null) ...[
                      _buildContactIcon('@', contactDetails!.email!, s),
                      pw.SizedBox(width: s.space6),
                    ],
                    if (contactDetails?.phone != null) ...[
                      _buildContactIcon('#', contactDetails!.phone!, s),
                      pw.SizedBox(width: s.space6),
                    ],
                    if (contactDetails?.address != null) ...[
                      _buildContactIcon(
                          '*', contactDetails!.address!.split(',').first, s),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// Build contact info icon with text
  static pw.Widget _buildContactIcon(String icon, String text, PdfStyling s) {
    return pw.Row(
      children: [
        pw.Container(
          width: 20,
          height: 20,
          decoration: pw.BoxDecoration(
            color: s.accent,
            shape: pw.BoxShape.circle,
          ),
          child: pw.Center(
            child: pw.Text(
              icon,
              style: pw.TextStyle(
                fontSize: s.fontSizeBody,
                color: s.textOnAccent,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          ),
        ),
        pw.SizedBox(width: s.space2),
        pw.Text(
          text,
          style: pw.TextStyle(
            fontSize: s.fontSizeSmall,
            color: s.headerText,
          ),
        ),
      ],
    );
  }

  /// Build recipient section
  static pw.Widget _buildRecipientSection(
      CoverLetter coverLetter, PdfStyling s) {
    final hasRecipient = (coverLetter.recipientName?.isNotEmpty ?? false) ||
        (coverLetter.recipientTitle?.isNotEmpty ?? false) ||
        (coverLetter.companyName?.isNotEmpty ?? false);

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        // Date with accent
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.end, // Right-align the date
          children: [
            pw.Container(
              width: 4,
              height: 12,
              color: s.accent,
              margin: pw.EdgeInsets.only(right: s.space2),
            ),
            pw.Text(
              CvTranslations.translateDate(
                _formatDate(DateTime.now()),
                s.customization.language,
              ),
              style: pw.TextStyle(
                fontSize: s.fontSizeSmall,
                color: s.textSecondary,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          ],
        ),

        if (hasRecipient && s.customization.showRecipient) ...[
          pw.SizedBox(height: s.sectionGapMinor),

          // Recipient details
          if (coverLetter.recipientName?.isNotEmpty ?? false)
            pw.Text(
              coverLetter.recipientName!,
              style: pw.TextStyle(
                fontSize: s.fontSizeBody,
                fontWeight: pw.FontWeight.bold,
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
                fontWeight: pw.FontWeight.bold,
                color: s.textMuted,
              ),
            ),
          ],
        ],
      ],
    );
  }

  /// Build letter body with paragraph styling and bullet points
  static pw.Widget _buildLetterBody(String body, PdfStyling s) {
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
        // Check if paragraph is a bullet point list
        if (paragraph.trim().startsWith('-') ||
            paragraph.trim().startsWith('*')) {
          final bullets =
              paragraph.split('\n').where((l) => l.trim().isNotEmpty).toList();
          return pw.Container(
            margin: pw.EdgeInsets.only(bottom: s.space3),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: bullets.map((bullet) {
                final cleanBullet =
                    bullet.trim().replaceFirst(RegExp(r'^[\-\*]\s*'), '');
                return pw.Padding(
                  padding: pw.EdgeInsets.only(bottom: s.space1, left: 0),
                  child: pw.Row(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Container(
                        width: 6,
                        height: 6,
                        margin: pw.EdgeInsets.only(top: 4, right: s.space2),
                        decoration: pw.BoxDecoration(
                          color: s.accent,
                          shape: pw.BoxShape.circle,
                        ),
                      ),
                      pw.Expanded(
                        child: pw.Text(
                          cleanBullet,
                          style: pw.TextStyle(
                            fontSize: s.fontSizeBody,
                            lineSpacing: s.lineHeightRelaxed,
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

        // Regular paragraph
        return pw.Container(
          margin: pw.EdgeInsets.only(bottom: s.space3),
          child: pw.Text(
            paragraph,
            style: pw.TextStyle(
              fontSize: s.fontSizeBody,
              lineSpacing: s.lineHeightRelaxed,
              color: s.textSecondary,
            ),
            textAlign: pw.TextAlign.justify,
          ),
        );
      }).toList(),
    );
  }

  /// Build signature with accent color
  static pw.Widget _buildSignature(String name, PdfStyling s) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        // Accent signature line
        pw.Container(
          width: 200,
          height: 2,
          color: s.accent,
        ),
        pw.SizedBox(height: s.space2),
        pw.Text(
          name,
          style: pw.TextStyle(
            fontSize: s.fontSizeBody,
            fontWeight: pw.FontWeight.bold,
            color: s.textPrimary,
            letterSpacing: s.letterSpacingNormal,
          ),
        ),
      ],
    );
  }

  /// Format date in professional style
  static String _formatDate(DateTime date) {
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
