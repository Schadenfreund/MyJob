import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../../models/cover_letter.dart';
import '../../models/cv_data.dart';
import '../../models/template_style.dart';
import '../../constants/pdf_constants.dart';

/// Electric Cover Letter Template - Matching Magazine-Style Design
///
/// Features:
/// - Bold asymmetric magazine layout matching Electric CV
/// - Electric yellow (#FFFF00) accents on black backgrounds
/// - Professional typography with brutalist aesthetic
/// - Geometric accent shapes
/// - High-contrast professional design
class ElectricCoverLetterTemplate {
  ElectricCoverLetterTemplate._();

  // Professional Electric color palette (matching CV template)
  static const PdfColor _electricYellow = PdfColor.fromInt(0xFFFFFF00);
  static const PdfColor _electricYellowFaded = PdfColor.fromInt(0x26FFFF00); // 15% opacity
  static const PdfColor _black = PdfColors.black;
  static const PdfColor _mediumGray = PdfColor.fromInt(0xFF2D2D2D);
  static const PdfColor _lightGray = PdfColor.fromInt(0xFF666666);
  static const PdfColor _white = PdfColors.white;

  // Professional ASCII-safe icons (works with Helvetica)
  static const String _iconEmail = '@';
  static const String _iconPhone = '#';
  static const String _iconLocation = '*';
  static const String _iconSquare = '-';

  /// Build the Electric Cover Letter PDF with stunning magazine-style design
  static void build(
    pw.Document pdf,
    CoverLetter coverLetter,
    TemplateStyle style,
    ContactDetails? contactDetails, {
    required pw.Font regularFont,
    required pw.Font boldFont,
    required pw.Font mediumFont,
  }) {
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
            _buildHeroHeader(contactDetails),

            // Main letter content
            pw.Expanded(
              child: pw.Container(
                padding: const pw.EdgeInsets.symmetric(horizontal: 48, vertical: 32),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    // Recipient details
                    _buildRecipientSection(coverLetter),

                    pw.SizedBox(height: 24),

                    // Greeting
                    pw.Text(
                      coverLetter.greeting,
                      style: pw.TextStyle(
                        fontSize: 12,
                        fontWeight: pw.FontWeight.bold,
                        color: _black,
                      ),
                    ),

                    pw.SizedBox(height: 16),

                    // Letter body with electric accents
                    _buildLetterBody(coverLetter.body),

                    pw.SizedBox(height: 20),

                    // Closing
                    pw.Text(
                      coverLetter.closing,
                      style: pw.TextStyle(
                        fontSize: 11,
                        color: _lightGray,
                      ),
                    ),

                    pw.SizedBox(height: 16),

                    // Signature with electric yellow accent
                    _buildSignature(contactDetails?.fullName ?? ''),
                  ],
                ),
              ),
            ),

            // Footer bar (matching header)
            pw.Container(
              width: double.infinity,
              height: 8,
              color: _electricYellow,
            ),
          ],
        ),
      ),
    );
  }

  /// Build stunning hero header matching CV template
  static pw.Widget _buildHeroHeader(ContactDetails? contactDetails) {
    final name = contactDetails?.fullName ?? 'Your Name';

    return pw.Stack(
      children: [
        // Black background banner
        pw.Container(
          width: double.infinity,
          height: 140,
          color: _black,
        ),

        // Electric yellow accent bar (top)
        pw.Container(
          width: double.infinity,
          height: 8,
          color: _electricYellow,
        ),

        // Electric yellow geometric accent (diagonal)
        pw.Positioned(
          right: 0,
          top: 0,
          child: pw.Transform.rotate(
            angle: 0.15,
            child: pw.Container(
              width: 220,
              height: 120,
              color: _electricYellowFaded,
            ),
          ),
        ),

        // Main content
        pw.Positioned.fill(
          child: pw.Container(
            padding: const pw.EdgeInsets.symmetric(horizontal: 48),
            child: pw.Column(
              mainAxisAlignment: pw.MainAxisAlignment.center,
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // Name in huge bold letters
                pw.Text(
                  name.toUpperCase(),
                  style: pw.TextStyle(
                    fontSize: 36,
                    fontWeight: pw.FontWeight.bold,
                    color: _white,
                    letterSpacing: 2,
                    height: 1.1,
                  ),
                ),

                pw.SizedBox(height: 12),

                // Contact info with icons
                pw.Row(
                  children: [
                    if (contactDetails?.email != null) ...[
                      _buildContactIcon(_iconEmail, contactDetails!.email!),
                      pw.SizedBox(width: 24),
                    ],
                    if (contactDetails?.phone != null) ...[
                      _buildContactIcon(_iconPhone, contactDetails!.phone!),
                      pw.SizedBox(width: 24),
                    ],
                    if (contactDetails?.address != null) ...[
                      _buildContactIcon(_iconLocation, contactDetails!.address!.split(',').first),
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
  static pw.Widget _buildContactIcon(String icon, String text) {
    return pw.Row(
      children: [
        pw.Container(
          width: 20,
          height: 20,
          decoration: const pw.BoxDecoration(
            color: _electricYellow,
            shape: pw.BoxShape.circle,
          ),
          child: pw.Center(
            child: pw.Text(
              icon,
              style: pw.TextStyle(
                fontSize: 11,
                color: _black,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          ),
        ),
        pw.SizedBox(width: 8),
        pw.Text(
          text,
          style: const pw.TextStyle(
            fontSize: 9,
            color: _white,
          ),
        ),
      ],
    );
  }

  /// Build recipient section
  static pw.Widget _buildRecipientSection(CoverLetter coverLetter) {
    final hasRecipient = (coverLetter.recipientName?.isNotEmpty ?? false) ||
        (coverLetter.recipientTitle?.isNotEmpty ?? false) ||
        (coverLetter.companyName?.isNotEmpty ?? false);

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        // Date with electric accent
        pw.Row(
          children: [
            pw.Container(
              width: 4,
              height: 12,
              color: _electricYellow,
              margin: const pw.EdgeInsets.only(right: 8),
            ),
            pw.Text(
              _formatDate(DateTime.now()),
              style: pw.TextStyle(
                fontSize: 10,
                color: _lightGray,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          ],
        ),

        if (hasRecipient) ...[
          pw.SizedBox(height: 20),

          // Recipient details
          if (coverLetter.recipientName?.isNotEmpty ?? false)
            pw.Text(
              coverLetter.recipientName!,
              style: pw.TextStyle(
                fontSize: 11,
                fontWeight: pw.FontWeight.bold,
                color: _black,
              ),
            ),

          if (coverLetter.recipientTitle?.isNotEmpty ?? false) ...[
            pw.SizedBox(height: 4),
            pw.Text(
              coverLetter.recipientTitle!,
              style: const pw.TextStyle(
                fontSize: 10,
                color: _lightGray,
              ),
            ),
          ],

          if (coverLetter.companyName?.isNotEmpty ?? false) ...[
            pw.SizedBox(height: 4),
            pw.Text(
              coverLetter.companyName!,
              style: pw.TextStyle(
                fontSize: 10,
                fontWeight: pw.FontWeight.bold,
                color: _mediumGray,
              ),
            ),
          ],
        ],
      ],
    );
  }

  /// Build letter body with paragraph styling and bullet points
  static pw.Widget _buildLetterBody(String body) {
    final paragraphs = body.split('\n\n').where((p) => p.trim().isNotEmpty).toList();

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: paragraphs.map((paragraph) {
        // Check if paragraph is a bullet point list (ASCII-safe)
        if (paragraph.trim().startsWith('-') || paragraph.trim().startsWith('*')) {
          final bullets = paragraph.split('\n').where((l) => l.trim().isNotEmpty).toList();
          return pw.Container(
            margin: const pw.EdgeInsets.only(bottom: 12),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: bullets.map((bullet) {
                final cleanBullet = bullet.trim().replaceFirst(RegExp(r'^[\-\*]\s*'), '');
                return pw.Padding(
                  padding: const pw.EdgeInsets.only(bottom: 6, left: 0),
                  child: pw.Row(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        _iconSquare,
                        style: const pw.TextStyle(
                          fontSize: 8,
                          color: _electricYellow,
                        ),
                      ),
                      pw.SizedBox(width: 10),
                      pw.Expanded(
                        child: pw.Text(
                          cleanBullet,
                          style: pw.TextStyle(
                            fontSize: 11,
                            lineSpacing: 1.5,
                            color: _lightGray,
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
          margin: const pw.EdgeInsets.only(bottom: 12),
          child: pw.Text(
            paragraph,
            style: pw.TextStyle(
              fontSize: 11,
              lineSpacing: 1.6,
              color: _lightGray,
            ),
            textAlign: pw.TextAlign.justify,
          ),
        );
      }).toList(),
    );
  }

  /// Build signature with electric yellow accent
  static pw.Widget _buildSignature(String name) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        // Electric yellow signature line
        pw.Container(
          width: 200,
          height: 2,
          color: _electricYellow,
        ),
        pw.SizedBox(height: 8),
        pw.Text(
          name,
          style: pw.TextStyle(
            fontSize: 12,
            fontWeight: pw.FontWeight.bold,
            color: _black,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }

  /// Format date in professional style
  static String _formatDate(DateTime date) {
    final months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];

    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }
}
