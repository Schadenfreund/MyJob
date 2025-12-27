import 'dart:io';
import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../../models/cv_data.dart';
import '../../models/template_style.dart';
import '../../models/template_customization.dart';
import '../../constants/pdf_constants.dart';
import '../core/base_cv_template.dart';
import '../shared/pdf_components.dart';

/// Professional CV Template - Clean Single-Column Layout
///
/// Features:
/// - Professional typography with optimal readability
/// - Clean section dividers
/// - Skill badges
/// - Proper spacing and hierarchy
/// - Optional profile picture support
class ProfessionalCvTemplate {
  ProfessionalCvTemplate._();

  static void build(
    pw.Document pdf,
    CvData cv,
    TemplateStyle style, {
    required pw.Font regularFont,
    required pw.Font boldFont,
    required pw.Font mediumFont,
    Uint8List? profileImageBytes,
    TemplateCustomization? customization,
  }) {
    // Use base template helpers (DRY)
    final custom = BaseCvTemplate.getCustomization(customization);
    final colors = BaseCvTemplate.getColors(style);
    final profileImage = BaseCvTemplate.loadProfileImage(profileImageBytes, custom);
    final fontFallback = [regularFont, boldFont, mediumFont];

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfConstants.pageFormat,
        margin: pw.EdgeInsets.only(
          top: PdfConstants.marginTop,
          bottom: PdfConstants.marginBottom,
          left: PdfConstants.marginLeft,
          right: PdfConstants.marginRight,
        ),
        theme: pw.ThemeData.withFont(
          base: regularFont,
          bold: boldFont,
          fontFallback: fontFallback,
        ),
        build: (context) => [
          // Template-specific header
          _buildHeader(cv, colors.primary, colors.accent, profileImage),
          pw.SizedBox(height: custom?.sectionSpacing ?? PdfConstants.sectionSpacing),

          // Standard sections (DRY - reused across all templates)
          ...BaseCvTemplate.buildStandardSections(
            cv,
            colors.primary,
            colors.accent,
            custom,
          ),
        ],
      ),
    );
  }

  /// Load profile image bytes from file path
  static Future<Uint8List?> loadProfileImage(String? imagePath) async {
    if (imagePath == null || imagePath.isEmpty) return null;
    try {
      final file = File(imagePath);
      if (await file.exists()) {
        return await file.readAsBytes();
      }
    } catch (_) {
      // Ignore file read errors
    }
    return null;
  }

  /// Build header with optional profile picture (template-specific layout)
  static pw.Widget _buildHeader(
    CvData cv,
    PdfColor primaryColor,
    PdfColor accentColor,
    pw.ImageProvider? profileImage,
  ) {
    final contact = cv.contactDetails;
    final name = contact?.fullName ?? 'Your Name';
    final jobTitle = contact?.jobTitle;
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';

    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        // Profile picture (optional) - left side
        if (profileImage != null || jobTitle != null) ...[
          pw.Container(
            width: PdfConstants.photoSizeMedium,
            height: PdfConstants.photoSizeMedium,
            decoration: pw.BoxDecoration(
              color: profileImage == null ? primaryColor : null,
              shape: pw.BoxShape.circle,
              border: pw.Border.all(
                color: primaryColor,
                width: 2,
              ),
            ),
            child: pw.ClipOval(
              child: profileImage != null
                  ? pw.Image(profileImage, fit: pw.BoxFit.cover)
                  : pw.Center(
                      child: pw.Text(
                        initial,
                        style: pw.TextStyle(
                          fontSize: PdfConstants.fontSizeH2,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.white,
                        ),
                      ),
                    ),
            ),
          ),
          pw.SizedBox(width: PdfConstants.spaceLg),
        ],

        // Name and contact info - right side
        pw.Expanded(
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Name
              pw.Text(
                name,
                style: pw.TextStyle(
                  fontSize: PdfConstants.fontSizeName,
                  fontWeight: pw.FontWeight.bold,
                  color: primaryColor,
                  letterSpacing: PdfConstants.letterSpacingTight,
                ),
              ),

              // Job title
              if (jobTitle != null && jobTitle.isNotEmpty) ...[
                pw.SizedBox(height: PdfConstants.spaceXs),
                pw.Text(
                  jobTitle,
                  style: pw.TextStyle(
                    fontSize: PdfConstants.fontSizeH3,
                    color: PdfConstants.textMuted,
                    fontStyle: pw.FontStyle.italic,
                  ),
                ),
              ],

              pw.SizedBox(height: PdfConstants.spaceMd),

              // Contact info row with icons
              PdfComponents.buildContactRowWithIcons(
                email: contact?.email,
                phone: contact?.phone,
                address: contact?.address,
                linkedin: contact?.linkedin,
                website: contact?.website,
                iconColor: accentColor,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
