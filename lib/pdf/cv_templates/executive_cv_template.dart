import 'dart:io';
import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../../models/cv_data.dart';
import '../../models/template_style.dart';
import '../../constants/pdf_constants.dart';
import '../shared/pdf_components.dart';

/// Executive CV Template - Sophisticated Design for Senior Professionals
///
/// Features:
/// - Elegant header with centered name and contact info
/// - Refined typography with serif-style emphasis
/// - Gold/charcoal color palette option
/// - Understated section dividers
/// - Focus on achievements and leadership
/// - Optional profile picture support
class ExecutiveCvTemplate {
  ExecutiveCvTemplate._();

  static void build(
    pw.Document pdf,
    CvData cv,
    TemplateStyle style, {
    required pw.Font regularFont,
    required pw.Font boldFont,
    required pw.Font mediumFont,
    Uint8List? profileImageBytes,
  }) {
    final primaryColor = PdfColor.fromInt(style.primaryColor.toARGB32());
    final accentColor = PdfColor.fromInt(style.accentColor.toARGB32());

    // Create font fallback list for Unicode support
    final fontFallback = [regularFont, boldFont, mediumFont];

    // Create profile image if bytes provided
    pw.ImageProvider? profileImage;
    if (profileImageBytes != null) {
      try {
        profileImage = pw.MemoryImage(profileImageBytes);
      } catch (_) {
        // Ignore image loading errors
      }
    }

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfConstants.pageFormat,
        margin: const pw.EdgeInsets.only(
          top: PdfConstants.marginTop + 8,
          bottom: PdfConstants.marginBottom,
          left: PdfConstants.marginLeft + 8,
          right: PdfConstants.marginRight + 8,
        ),
        theme: pw.ThemeData.withFont(
          base: regularFont,
          bold: boldFont,
          fontFallback: fontFallback,
        ),
        build: (context) => [
          // Elegant centered header
          _buildExecutiveHeader(cv, primaryColor, accentColor, profileImage),

          PdfComponents.sectionSpacer,

          // Profile/Executive Summary
          if (cv.profile.isNotEmpty) ...[
            _buildSectionHeader('EXECUTIVE SUMMARY', accentColor),
            pw.SizedBox(height: PdfConstants.spaceMd),
            _buildProfileText(cv.profile),
            PdfComponents.sectionSpacer,
          ],

          // Professional Experience
          if (cv.experiences.isNotEmpty) ...[
            _buildSectionHeader('PROFESSIONAL EXPERIENCE', accentColor),
            pw.SizedBox(height: PdfConstants.spaceMd),
            ...cv.experiences.map((exp) {
              return _buildExperienceEntry(
                title: exp.title,
                company: exp.company,
                dateRange: exp.dateRange,
                description: exp.description,
                bullets: exp.bullets,
                primaryColor: primaryColor,
                accentColor: accentColor,
              );
            }),
            PdfComponents.sectionSpacer,
          ],

          // Education
          if (cv.education.isNotEmpty) ...[
            _buildSectionHeader('EDUCATION', accentColor),
            pw.SizedBox(height: PdfConstants.spaceMd),
            ...cv.education.map((edu) {
              return _buildEducationEntry(
                degree: edu.degree,
                institution: edu.institution,
                dateRange: edu.dateRange,
                details: edu.description,
                primaryColor: primaryColor,
              );
            }),
            PdfComponents.sectionSpacer,
          ],

          // Skills and Languages in a row
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Skills column
              if (cv.skills.isNotEmpty)
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      _buildSectionHeader('CORE COMPETENCIES', accentColor),
                      pw.SizedBox(height: PdfConstants.spaceMd),
                      _buildSkillsList(cv.skills, primaryColor),
                    ],
                  ),
                ),

              if (cv.skills.isNotEmpty && cv.languages.isNotEmpty)
                pw.SizedBox(width: PdfConstants.space2xl),

              // Languages column
              if (cv.languages.isNotEmpty)
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      _buildSectionHeader('LANGUAGES', accentColor),
                      pw.SizedBox(height: PdfConstants.spaceMd),
                      ...cv.languages.map((lang) {
                        return _buildLanguageEntry(
                          lang.language,
                          lang.level,
                          accentColor,
                        );
                      }),
                    ],
                  ),
                ),
            ],
          ),

          // Interests (optional, subtle)
          if (cv.interests.isNotEmpty) ...[
            PdfComponents.sectionSpacer,
            _buildSectionHeader('INTERESTS', accentColor),
            pw.SizedBox(height: PdfConstants.spaceMd),
            pw.Text(
              cv.interests.join('  •  '),
              style: pw.TextStyle(
                fontSize: PdfConstants.fontSizeSmall,
                color: PdfConstants.textMuted,
                fontStyle: pw.FontStyle.italic,
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ============================================================================
  // HEADER
  // ============================================================================

  /// Elegant centered header with name and contact details
  static pw.Widget _buildExecutiveHeader(
    CvData cv,
    PdfColor primaryColor,
    PdfColor accentColor,
    pw.ImageProvider? profileImage,
  ) {
    final name = cv.contactDetails?.fullName ?? 'Your Name';
    final jobTitle = cv.contactDetails?.jobTitle;

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.center,
      children: [
        // Profile picture (centered, optional)
        if (profileImage != null) ...[
          pw.Container(
            width: PdfConstants.photoSizeMedium,
            height: PdfConstants.photoSizeMedium,
            decoration: pw.BoxDecoration(
              shape: pw.BoxShape.circle,
              border: pw.Border.all(
                color: accentColor,
                width: 2,
              ),
            ),
            child: pw.ClipOval(
              child: pw.Image(profileImage, fit: pw.BoxFit.cover),
            ),
          ),
          pw.SizedBox(height: PdfConstants.spaceLg),
        ],

        // Name with elegant styling
        pw.Text(
          name.toUpperCase(),
          style: pw.TextStyle(
            fontSize: PdfConstants.fontSizeName + 4,
            fontWeight: pw.FontWeight.bold,
            color: primaryColor,
            letterSpacing: PdfConstants.letterSpacingExtraWide,
          ),
          textAlign: pw.TextAlign.center,
        ),

        // Job title (if available)
        if (jobTitle != null && jobTitle.isNotEmpty) ...[
          pw.SizedBox(height: PdfConstants.spaceXs),
          pw.Text(
            jobTitle,
            style: pw.TextStyle(
              fontSize: PdfConstants.fontSizeH3,
              color: PdfConstants.textMuted,
              fontStyle: pw.FontStyle.italic,
              letterSpacing: PdfConstants.letterSpacingNormal,
            ),
            textAlign: pw.TextAlign.center,
          ),
        ],

        pw.SizedBox(height: PdfConstants.spaceMd),

        // Decorative line
        pw.Container(
          width: 80,
          height: PdfConstants.accentDividerThickness,
          color: accentColor,
        ),

        pw.SizedBox(height: PdfConstants.spaceMd),

        // Contact information (centered, separated by pipes)
        PdfComponents.buildContactRowPublic(
          email: cv.contactDetails?.email,
          phone: cv.contactDetails?.phone,
          address: cv.contactDetails?.address,
          linkedin: cv.contactDetails?.linkedin,
          separator: '   |   ',
        ),
      ],
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

  // ============================================================================
  // SECTION HEADER
  // ============================================================================

  /// Elegant section header with centered underline
  static pw.Widget _buildSectionHeader(String title, PdfColor accentColor) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          title,
          style: pw.TextStyle(
            fontSize: PdfConstants.fontSizeH2,
            fontWeight: pw.FontWeight.bold,
            color: PdfConstants.textDark,
            letterSpacing: PdfConstants.letterSpacingWide,
          ),
        ),
        pw.SizedBox(height: PdfConstants.spaceXs),
        pw.Row(
          children: [
            pw.Container(
              width: 30,
              height: PdfConstants.accentDividerThickness,
              color: accentColor,
            ),
            pw.Expanded(
              child: pw.Container(
                height: PdfConstants.dividerThickness,
                color: PdfConstants.dividerLight,
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ============================================================================
  // PROFILE TEXT
  // ============================================================================

  /// Executive profile with refined styling
  static pw.Widget _buildProfileText(String text) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(
        horizontal: PdfConstants.spaceLg,
      ),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: PdfConstants.fontSizeBody,
          color: PdfConstants.textBody,
          lineSpacing: PdfConstants.lineHeightLoose,
          fontStyle: pw.FontStyle.italic,
        ),
        textAlign: pw.TextAlign.justify,
      ),
    );
  }

  // ============================================================================
  // EXPERIENCE ENTRY
  // ============================================================================

  /// Executive experience entry with emphasis on title
  static pw.Widget _buildExperienceEntry({
    required String title,
    required String company,
    required String dateRange,
    String? description,
    List<String>? bullets,
    required PdfColor primaryColor,
    required PdfColor accentColor,
  }) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: PdfConstants.entrySpacing),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          // Title row with date
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    // Role title
                    pw.Text(
                      title,
                      style: pw.TextStyle(
                        fontSize: PdfConstants.fontSizeH3 + 1,
                        fontWeight: pw.FontWeight.bold,
                        color: primaryColor,
                      ),
                    ),
                    pw.SizedBox(height: PdfConstants.spaceXs / 2),
                    // Company
                    pw.Text(
                      company,
                      style: pw.TextStyle(
                        fontSize: PdfConstants.fontSizeH4,
                        color: PdfConstants.textDark,
                      ),
                    ),
                  ],
                ),
              ),
              pw.SizedBox(width: PdfConstants.spaceMd),
              // Date badge
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(
                  horizontal: PdfConstants.badgePaddingH,
                  vertical: PdfConstants.badgePaddingV,
                ),
                decoration: pw.BoxDecoration(
                  color: PdfConstants.withOpacity(accentColor, 0.1),
                  borderRadius: pw.BorderRadius.circular(PdfConstants.borderRadius),
                ),
                child: pw.Text(
                  dateRange,
                  style: pw.TextStyle(
                    fontSize: PdfConstants.fontSizeSmall,
                    color: primaryColor,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),

          // Description
          if (description != null && description.isNotEmpty) ...[
            pw.SizedBox(height: PdfConstants.spaceSm),
            pw.Text(
              description,
              style: pw.TextStyle(
                fontSize: PdfConstants.fontSizeBody,
                color: PdfConstants.textMuted,
                fontStyle: pw.FontStyle.italic,
              ),
            ),
          ],

          // Bullet points
          if (bullets != null && bullets.isNotEmpty) ...[
            pw.SizedBox(height: PdfConstants.spaceSm),
            ...bullets.map((bullet) => _buildBulletPoint(bullet, accentColor)),
          ],
        ],
      ),
    );
  }

  /// Elegant bullet point with accent marker
  static pw.Widget _buildBulletPoint(String text, PdfColor accentColor) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(
        left: PdfConstants.bulletIndent / 2,
        top: PdfConstants.bulletSpacing,
      ),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Container(
            width: 6,
            height: 6,
            margin: const pw.EdgeInsets.only(top: 4, right: 8),
            decoration: pw.BoxDecoration(
              color: accentColor,
              shape: pw.BoxShape.circle,
            ),
          ),
          pw.Expanded(
            child: pw.Text(
              text,
              style: pw.TextStyle(
                fontSize: PdfConstants.fontSizeBody,
                color: PdfConstants.textBody,
                lineSpacing: PdfConstants.lineHeightNormal,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================================
  // EDUCATION ENTRY
  // ============================================================================

  static pw.Widget _buildEducationEntry({
    required String degree,
    required String institution,
    required String dateRange,
    String? details,
    required PdfColor primaryColor,
  }) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: PdfConstants.spaceMd),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  degree,
                  style: pw.TextStyle(
                    fontSize: PdfConstants.fontSizeH3,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfConstants.textDark,
                  ),
                ),
                pw.SizedBox(height: PdfConstants.spaceXs / 2),
                pw.Text(
                  institution,
                  style: pw.TextStyle(
                    fontSize: PdfConstants.fontSizeH4,
                    color: primaryColor,
                  ),
                ),
                if (details != null && details.isNotEmpty) ...[
                  pw.SizedBox(height: PdfConstants.spaceXs),
                  pw.Text(
                    details,
                    style: pw.TextStyle(
                      fontSize: PdfConstants.fontSizeSmall,
                      color: PdfConstants.textMuted,
                      fontStyle: pw.FontStyle.italic,
                    ),
                  ),
                ],
              ],
            ),
          ),
          pw.SizedBox(width: PdfConstants.spaceMd),
          pw.Text(
            dateRange,
            style: pw.TextStyle(
              fontSize: PdfConstants.fontSizeSmall,
              color: PdfConstants.textMuted,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================================
  // SKILLS LIST
  // ============================================================================

  /// Refined skills list with subtle bullets
  static pw.Widget _buildSkillsList(List<String> skills, PdfColor color) {
    // Display in two columns if many skills
    if (skills.length > 6) {
      final half = (skills.length / 2).ceil();
      final col1 = skills.take(half).toList();
      final col2 = skills.skip(half).toList();

      return pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: col1.map((s) => _buildSkillItem(s, color)).toList(),
            ),
          ),
          pw.SizedBox(width: PdfConstants.spaceMd),
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: col2.map((s) => _buildSkillItem(s, color)).toList(),
            ),
          ),
        ],
      );
    }

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: skills.map((s) => _buildSkillItem(s, color)).toList(),
    );
  }

  static pw.Widget _buildSkillItem(String skillString, PdfColor color) {
    // Parse skill string to extract name and level
    final parsed = PdfComponents.parseSkillString(skillString);

    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: PdfConstants.spaceSm),
      child: pw.Row(
        children: [
          pw.Container(
            width: 4,
            height: 4,
            margin: const pw.EdgeInsets.only(right: 8, top: 5),
            decoration: pw.BoxDecoration(
              color: color,
              shape: pw.BoxShape.circle,
            ),
          ),
          pw.Expanded(
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  parsed.name,
                  style: pw.TextStyle(
                    fontSize: PdfConstants.fontSizeBody,
                    color: PdfConstants.textBody,
                  ),
                ),
                pw.Container(
                  padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: pw.BoxDecoration(
                    color: PdfConstants.withOpacity(color, 0.15),
                    borderRadius: pw.BorderRadius.circular(4),
                  ),
                  child: pw.Text(
                    parsed.level,
                    style: pw.TextStyle(
                      fontSize: PdfConstants.fontSizeTiny,
                      color: color,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================================
  // LANGUAGE ENTRY
  // ============================================================================

  static pw.Widget _buildLanguageEntry(
    String language,
    String level,
    PdfColor accentColor,
  ) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: PdfConstants.spaceSm),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            language,
            style: pw.TextStyle(
              fontSize: PdfConstants.fontSizeBody,
              color: PdfConstants.textBody,
            ),
          ),
          pw.Text(
            level,
            style: pw.TextStyle(
              fontSize: PdfConstants.fontSizeSmall,
              color: accentColor,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
