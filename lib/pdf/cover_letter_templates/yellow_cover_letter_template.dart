import 'dart:math' as math;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../../models/cover_letter.dart';
import '../../models/cv_data.dart';
import '../../models/template_style.dart';
import '../shared/pdf_components.dart';

/// Yellow Cover Letter Template - High-Contrast Magazine Style
///
/// Features:
/// - Electric yellow (#FFFF00) accent banner
/// - Bold, modern typography with black and yellow
/// - Yellow square bullets for contact info
/// - Minimal, professional letter layout
/// - Consistent with Yellow CV template design
class YellowCoverLetterTemplate {
  YellowCoverLetterTemplate._();

  // Design constants
  static const double _logoCircleSize = 35.0;
  static const double _squareBulletSize = 6.0;
  static const double _accentBarHeight = 3.0;

  /// Build the Yellow cover letter PDF
  static void build(
    pw.Document pdf,
    CoverLetter coverLetter,
    TemplateStyle style,
    ContactDetails? contactDetails, {
    required pw.Font regularFont,
    required pw.Font boldFont,
    required pw.Font mediumFont,
  }) {
    const yellow = PdfColor.fromInt(0xFFFFFF00);
    const black = PdfColors.black;
    const lightGray = PdfColor.fromInt(0xFF6B7280);

    // Create font fallback list for Unicode support
    final fontFallback = PdfComponents.getFontFallback(
      regularFont: regularFont,
      boldFont: boldFont,
      mediumFont: mediumFont,
    );

    final senderName = coverLetter.senderName ?? contactDetails?.fullName ?? 'Your Name';
    final jobTitle = contactDetails?.jobTitle;

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(60),
        theme: pw.ThemeData.withFont(
          base: regularFont,
          bold: boldFont,
          fontFallback: fontFallback,
        ),
        build: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            // Header with name and logo circle
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                // Left: Logo and name
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    // Yellow circle logo
                    pw.Container(
                      width: _logoCircleSize,
                      height: _logoCircleSize,
                      decoration: pw.BoxDecoration(
                        color: yellow,
                        shape: pw.BoxShape.circle,
                      ),
                      child: pw.Center(
                        child: pw.Container(
                          width: _logoCircleSize * 0.5,
                          height: _logoCircleSize * 0.5,
                          child: pw.CustomPaint(
                            painter: (canvas, size) {
                              final centerX = size.x / 2;
                              final centerY = size.y / 2;
                              final radius = size.x / 2.5;

                              canvas
                                ..setStrokeColor(black)
                                ..setLineWidth(1.2);

                              for (var i = 0; i <= 6; i++) {
                                final angle = (i * 60) * math.pi / 180;
                                final x = centerX + radius * math.cos(angle);
                                final y = centerY + radius * math.sin(angle);

                                if (i == 0) {
                                  canvas.moveTo(x, y);
                                } else {
                                  canvas.lineTo(x, y);
                                }
                              }
                              canvas.strokePath();
                            },
                          ),
                        ),
                      ),
                    ),
                    pw.SizedBox(height: 10),

                    // Name
                    pw.Text(
                      senderName,
                      style: pw.TextStyle(
                        fontSize: 24,
                        fontWeight: pw.FontWeight.bold,
                        color: black,
                        letterSpacing: -0.5,
                      ),
                    ),

                    // Job title (if available)
                    if (jobTitle != null && jobTitle.isNotEmpty) ...[
                      pw.SizedBox(height: 4),
                      pw.Text(
                        jobTitle.toUpperCase(),
                        style: pw.TextStyle(
                          fontSize: 9,
                          color: lightGray,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ],

                    // Yellow accent bar
                    pw.Container(
                      margin: const pw.EdgeInsets.only(top: 8),
                      width: 50,
                      height: _accentBarHeight,
                      color: yellow,
                    ),
                  ],
                ),

                // Right: Contact info with yellow bullets
                if (contactDetails != null)
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      if (contactDetails.email != null && contactDetails.email!.isNotEmpty)
                        _buildContactItem(contactDetails.email!, yellow, black),
                      if (contactDetails.phone != null && contactDetails.phone!.isNotEmpty)
                        _buildContactItem(contactDetails.phone!, yellow, black),
                      if (contactDetails.address != null && contactDetails.address!.isNotEmpty)
                        _buildContactItem(contactDetails.address!, yellow, black),
                    ],
                  ),
              ],
            ),

            pw.SizedBox(height: 40),

            // Date
            pw.Text(
              _formatDate(DateTime.now()),
              style: pw.TextStyle(
                fontSize: 10,
                color: lightGray,
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
                  if (coverLetter.recipientName != null && coverLetter.recipientName!.isNotEmpty)
                    pw.Text(
                      coverLetter.recipientName!,
                      style: pw.TextStyle(
                        fontSize: 11,
                        fontWeight: pw.FontWeight.bold,
                        color: black,
                      ),
                    ),
                  if (coverLetter.recipientTitle != null && coverLetter.recipientTitle!.isNotEmpty) ...[
                    pw.SizedBox(height: 2),
                    pw.Text(
                      coverLetter.recipientTitle!,
                      style: pw.TextStyle(
                        fontSize: 10,
                        color: lightGray,
                      ),
                    ),
                  ],
                  if (coverLetter.companyName != null && coverLetter.companyName!.isNotEmpty) ...[
                    pw.SizedBox(height: 2),
                    pw.Text(
                      coverLetter.companyName!,
                      style: pw.TextStyle(
                        fontSize: 10,
                        fontWeight: pw.FontWeight.bold,
                        color: black,
                      ),
                    ),
                  ],
                ],
              ),

            pw.SizedBox(height: 25),

            // Subject line with yellow accent (if job title provided)
            if (coverLetter.jobTitle != null && coverLetter.jobTitle!.isNotEmpty) ...[
              pw.Row(
                children: [
                  pw.Container(
                    width: 4,
                    height: 16,
                    color: yellow,
                    margin: const pw.EdgeInsets.only(right: 8),
                  ),
                  pw.Text(
                    'Re: Application for ${coverLetter.jobTitle}',
                    style: pw.TextStyle(
                      fontSize: 11,
                      fontWeight: pw.FontWeight.bold,
                      color: black,
                    ),
                  ),
                ],
              ),
              pw.SizedBox(height: 20),
            ],

            // Greeting
            pw.Text(
              coverLetter.greeting,
              style: pw.TextStyle(
                fontSize: 11,
                color: black,
              ),
            ),

            pw.SizedBox(height: 15),

            // Letter body
            pw.Text(
              coverLetter.processedBody,
              style: pw.TextStyle(
                fontSize: 10,
                lineSpacing: 1.7,
                color: PdfColor.fromInt(0xFF374151),
              ),
              textAlign: pw.TextAlign.justify,
            ),

            pw.SizedBox(height: 25),

            // Closing
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  coverLetter.closing,
                  style: pw.TextStyle(
                    fontSize: 11,
                    color: black,
                  ),
                ),
                pw.SizedBox(height: 25),

                // Signature with yellow underline
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      senderName,
                      style: pw.TextStyle(
                        fontSize: 12,
                        fontWeight: pw.FontWeight.bold,
                        color: black,
                      ),
                    ),
                    pw.Container(
                      margin: const pw.EdgeInsets.only(top: 4),
                      width: 40,
                      height: 2,
                      color: yellow,
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Build contact item with yellow square bullet
  static pw.Widget _buildContactItem(String value, PdfColor yellow, PdfColor black) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 6),
      child: pw.Row(
        mainAxisSize: pw.MainAxisSize.min,
        children: [
          pw.Container(
            width: _squareBulletSize,
            height: _squareBulletSize,
            margin: const pw.EdgeInsets.only(right: 8),
            color: yellow,
          ),
          pw.Text(
            value,
            style: pw.TextStyle(
              fontSize: 9,
              color: PdfColor.fromInt(0xFF4B5563),
            ),
          ),
        ],
      ),
    );
  }

  /// Format date for letter
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
