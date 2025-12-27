import 'dart:io';
import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../../models/cv_data.dart';
import '../../models/template_style.dart';
import '../../constants/pdf_constants.dart';
import '../shared/pdf_components.dart';

/// Modern CV Template - Professional Two-Column Layout
///
/// Features:
/// - 30% sidebar with colored background
/// - 70% main content area
/// - Skill bars with proficiency levels
/// - Contemporary design with clean typography
/// - Color-coded sections
/// - Optional profile picture support
class ModernCvTemplate {
  ModernCvTemplate._();

  /// Build the CV PDF
  ///
  /// [profileImageBytes] - Optional profile picture bytes (JPEG/PNG)
  static void build(
    pw.Document pdf,
    CvData cv,
    TemplateStyle style, {
    Uint8List? profileImageBytes,
  }) {
    final primaryColor = PdfColor.fromInt(style.primaryColor.toARGB32());
    final accentColor = PdfColor.fromInt(style.accentColor.toARGB32());

    // Create profile image if bytes provided
    pw.ImageProvider? profileImage;
    if (profileImageBytes != null) {
      try {
        profileImage = pw.MemoryImage(profileImageBytes);
      } catch (_) {
        // Ignore image loading errors, will fall back to initial
      }
    }

    pdf.addPage(
      pw.Page(
        pageFormat: PdfConstants.pageFormat,
        margin: pw.EdgeInsets.zero,
        build: (context) => pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            // Sidebar (30% width)
            _buildSidebar(cv, primaryColor, accentColor, profileImage),
            // Main content (70% width)
            _buildMainContent(cv, primaryColor, accentColor),
          ],
        ),
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

  /// Build colored sidebar with contact, skills, languages, and interests
  static pw.Widget _buildSidebar(
    CvData cv,
    PdfColor primaryColor,
    PdfColor accentColor,
    pw.ImageProvider? profileImage,
  ) {
    return pw.Container(
      width: PdfConstants.pageFormat.width * PdfConstants.sidebarWidthRatio,
      height: PdfConstants.pageFormat.height,
      color: primaryColor,
      padding: const pw.EdgeInsets.symmetric(
        horizontal: PdfConstants.spaceLg,
        vertical: PdfConstants.space2xl,
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          // Header with avatar/profile picture
          _buildSidebarHeader(cv, accentColor, profileImage),
          pw.SizedBox(height: PdfConstants.space2xl),

          // Contact information
          _buildSidebarSection(
            'CONTACT',
            _buildContactInfo(cv),
          ),
          pw.SizedBox(height: PdfConstants.space2xl),

          // Skills with bars
          if (cv.skills.isNotEmpty) ...[
            _buildSidebarSection(
              'SKILLS',
              _buildSkillBars(cv.skills, accentColor),
            ),
            pw.SizedBox(height: PdfConstants.space2xl),
          ],

          // Languages with proficiency levels
          if (cv.languages.isNotEmpty) ...[
            _buildSidebarSection(
              'LANGUAGES',
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: cv.languages.map((lang) {
                  return _buildLanguageEntry(
                    lang.language,
                    lang.level,
                    accentColor,
                  );
                }).toList(),
              ),
            ),
            pw.SizedBox(height: PdfConstants.space2xl),
          ],

          // Interests as tags
          if (cv.interests.isNotEmpty)
            _buildSidebarSection(
              'INTERESTS',
              _buildInterestTags(cv.interests, accentColor),
            ),
        ],
      ),
    );
  }

  /// Build main content area with profile, experience, and education
  static pw.Widget _buildMainContent(
    CvData cv,
    PdfColor primaryColor,
    PdfColor accentColor,
  ) {
    return pw.Expanded(
      child: pw.Container(
        padding: const pw.EdgeInsets.symmetric(
          horizontal: PdfConstants.space3xl,
          vertical: PdfConstants.space2xl,
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            // Professional Summary
            if (cv.profile.isNotEmpty) ...[
              _buildMainSectionHeader('PROFILE', primaryColor),
              pw.SizedBox(height: PdfConstants.spaceMd),
              PdfComponents.buildParagraph(cv.profile, justified: true),
              pw.SizedBox(height: PdfConstants.sectionSpacing),
            ],

            // Professional Experience
            if (cv.experiences.isNotEmpty) ...[
              _buildMainSectionHeader('EXPERIENCE', primaryColor),
              pw.SizedBox(height: PdfConstants.spaceMd),
              ...cv.experiences.map((exp) {
                return _buildExperienceEntry(
                  exp.title,
                  exp.company,
                  exp.dateRange,
                  exp.description,
                  exp.bullets,
                  primaryColor,
                  accentColor,
                );
              }),
              pw.SizedBox(height: PdfConstants.spaceLg),
            ],

            // Education
            if (cv.education.isNotEmpty) ...[
              _buildMainSectionHeader('EDUCATION', primaryColor),
              pw.SizedBox(height: PdfConstants.spaceMd),
              ...cv.education.map((edu) {
                return _buildEducationEntry(
                  edu.degree,
                  edu.institution,
                  edu.dateRange,
                  edu.description,
                  primaryColor,
                );
              }),
            ],
          ],
        ),
      ),
    );
  }

  // ==========================================================================
  // SIDEBAR COMPONENTS
  // ==========================================================================

  /// Sidebar header with profile picture or initial avatar
  static pw.Widget _buildSidebarHeader(
    CvData cv,
    PdfColor accentColor,
    pw.ImageProvider? profileImage,
  ) {
    final name = cv.contactDetails?.fullName ?? 'Your Name';
    final jobTitle = cv.contactDetails?.jobTitle;
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        // Profile picture or circular avatar with initial
        pw.Container(
          width: PdfConstants.photoSizeLarge,
          height: PdfConstants.photoSizeLarge,
          decoration: pw.BoxDecoration(
            color: profileImage == null ? accentColor : null,
            shape: pw.BoxShape.circle,
            border: pw.Border.all(
              color: accentColor,
              width: 3,
            ),
          ),
          child: pw.ClipOval(
            child: profileImage != null
                ? pw.Image(profileImage, fit: pw.BoxFit.cover)
                : pw.Center(
                    child: pw.Text(
                      initial,
                      style: pw.TextStyle(
                        fontSize: PdfConstants.fontSizeName + 8,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.white,
                      ),
                    ),
                  ),
          ),
        ),
        pw.SizedBox(height: PdfConstants.spaceLg),

        // Name
        pw.Text(
          name,
          style: pw.TextStyle(
            fontSize: PdfConstants.fontSizeH2 + 4,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.white,
            letterSpacing: PdfConstants.letterSpacingTight,
          ),
        ),

        // Job title (if available)
        if (jobTitle != null && jobTitle.isNotEmpty) ...[
          pw.SizedBox(height: PdfConstants.spaceXs),
          pw.Text(
            jobTitle,
            style: pw.TextStyle(
              fontSize: PdfConstants.fontSizeH4,
              color: PdfConstants.withOpacity(PdfColors.white, 0.85),
              fontStyle: pw.FontStyle.italic,
            ),
          ),
        ],
      ],
    );
  }

  /// Sidebar section with title and content
  static pw.Widget _buildSidebarSection(String title, pw.Widget content) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          title,
          style: pw.TextStyle(
            fontSize: PdfConstants.fontSizeH3,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.white,
            letterSpacing: PdfConstants.letterSpacingWide,
          ),
        ),
        pw.SizedBox(height: PdfConstants.spaceXs),
        pw.Container(
          width: 40,
          height: PdfConstants.dividerThickness,
          color: PdfConstants.withOpacity(PdfColors.white, 0.5),
        ),
        pw.SizedBox(height: PdfConstants.spaceMd),
        content,
      ],
    );
  }

  /// Contact information in sidebar
  static pw.Widget _buildContactInfo(CvData cv) {
    final contact = cv.contactDetails;
    if (contact == null) return pw.SizedBox();

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        if (contact.email != null)
          _buildContactItem('Email', contact.email!),
        if (contact.phone != null)
          _buildContactItem('Phone', contact.phone!),
        if (contact.address != null)
          _buildContactItem('Address', contact.address!),
        if (contact.linkedin != null)
          _buildContactItem('LinkedIn', contact.linkedin!),
      ],
    );
  }

  /// Single contact item
  static pw.Widget _buildContactItem(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: PdfConstants.spaceSm),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            label,
            style: pw.TextStyle(
              fontSize: PdfConstants.fontSizeTiny,
              color: PdfConstants.withOpacity(PdfColors.white, 0.7),
            ),
          ),
          pw.SizedBox(height: PdfConstants.spaceXs / 2),
          pw.Text(
            value,
            style: pw.TextStyle(
              fontSize: PdfConstants.fontSizeSmall,
              color: PdfColors.white,
            ),
          ),
        ],
      ),
    );
  }

  /// Skill bars with visual proficiency indicator (parses skill levels)
  static pw.Widget _buildSkillBars(List<String> skills, PdfColor accentColor) {
    // Limit to top 8 skills to fit in sidebar
    final displaySkills = skills.take(8).toList();
    const barWidth = 120.0; // Fixed width for consistency

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: displaySkills.map((skillString) {
        // Parse the skill string to extract name and level
        final parsed = PdfComponents.parseSkillString(skillString);

        return pw.Padding(
          padding: const pw.EdgeInsets.only(bottom: PdfConstants.spaceSm + 2),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Skill name and level
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Expanded(
                    child: pw.Text(
                      parsed.name,
                      style: pw.TextStyle(
                        fontSize: PdfConstants.fontSizeSmall,
                        color: PdfColors.white,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ),
                  pw.Text(
                    parsed.level,
                    style: pw.TextStyle(
                      fontSize: PdfConstants.fontSizeTiny,
                      color: PdfConstants.withOpacity(PdfColors.white, 0.7),
                    ),
                  ),
                ],
              ),
              pw.SizedBox(height: PdfConstants.spaceXs),
              pw.Stack(
                children: [
                  // Background bar
                  pw.Container(
                    width: barWidth,
                    height: PdfConstants.skillBarHeight,
                    decoration: pw.BoxDecoration(
                      color: PdfConstants.withOpacity(PdfColors.white, 0.2),
                      borderRadius:
                          pw.BorderRadius.circular(PdfConstants.skillBarRadius),
                    ),
                  ),
                  // Filled bar (uses parsed percentage)
                  pw.Container(
                    width: barWidth * parsed.percentage,
                    height: PdfConstants.skillBarHeight,
                    decoration: pw.BoxDecoration(
                      color: accentColor,
                      borderRadius:
                          pw.BorderRadius.circular(PdfConstants.skillBarRadius),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  /// Language entry with proficiency badge
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
              fontSize: PdfConstants.fontSizeSmall,
              color: PdfColors.white,
            ),
          ),
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(
              horizontal: PdfConstants.badgePaddingH - 2,
              vertical: PdfConstants.badgePaddingV - 1,
            ),
            decoration: pw.BoxDecoration(
              color: accentColor,
              borderRadius: pw.BorderRadius.circular(PdfConstants.badgeRadius),
            ),
            child: pw.Text(
              level,
              style: pw.TextStyle(
                fontSize: PdfConstants.fontSizeTiny,
                color: PdfColors.white,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Interest tags
  static pw.Widget _buildInterestTags(
    List<String> interests,
    PdfColor accentColor,
  ) {
    return pw.Wrap(
      spacing: PdfConstants.badgeSpacing,
      runSpacing: PdfConstants.badgeSpacing,
      children: interests.map((interest) {
        return pw.Container(
          padding: const pw.EdgeInsets.symmetric(
            horizontal: PdfConstants.badgePaddingH - 2,
            vertical: PdfConstants.badgePaddingV,
          ),
          decoration: pw.BoxDecoration(
            border: pw.Border.all(
              color: PdfConstants.withOpacity(PdfColors.white, 0.5),
              width: 1,
            ),
            borderRadius: pw.BorderRadius.circular(PdfConstants.badgeRadius),
          ),
          child: pw.Text(
            interest,
            style: pw.TextStyle(
              fontSize: PdfConstants.fontSizeTiny,
              color: PdfColors.white,
            ),
          ),
        );
      }).toList(),
    );
  }

  // ==========================================================================
  // MAIN CONTENT COMPONENTS
  // ==========================================================================

  /// Main section header with accent bar
  static pw.Widget _buildMainSectionHeader(String title, PdfColor color) {
    return pw.Row(
      children: [
        pw.Container(
          width: PdfConstants.accentDividerThickness + 1.5,
          height: PdfConstants.fontSizeH2 + 4,
          color: color,
        ),
        pw.SizedBox(width: PdfConstants.spaceSm),
        pw.Text(
          title,
          style: pw.TextStyle(
            fontSize: PdfConstants.fontSizeH2,
            fontWeight: pw.FontWeight.bold,
            color: PdfConstants.textDark,
            letterSpacing: PdfConstants.letterSpacingWide,
          ),
        ),
      ],
    );
  }

  /// Experience entry with timeline dot
  static pw.Widget _buildExperienceEntry(
    String title,
    String company,
    String dateRange,
    String? description,
    List<String> bullets,
    PdfColor primaryColor,
    PdfColor accentColor,
  ) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: PdfConstants.entrySpacing),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          // Timeline dot
          pw.Container(
            width: PdfConstants.timelineDotSize,
            height: PdfConstants.timelineDotSize,
            margin: const pw.EdgeInsets.only(
              top: 4,
              right: PdfConstants.spaceMd,
            ),
            decoration: pw.BoxDecoration(
              color: accentColor,
              shape: pw.BoxShape.circle,
            ),
          ),

          // Content
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // Title and date
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Expanded(
                      child: pw.Text(
                        title,
                        style: pw.TextStyle(
                          fontSize: PdfConstants.fontSizeH3,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfConstants.textDark,
                        ),
                      ),
                    ),
                    pw.SizedBox(width: PdfConstants.spaceMd),
                    pw.Text(
                      dateRange,
                      style: pw.TextStyle(
                        fontSize: PdfConstants.fontSizeSmall,
                        color: PdfConstants.textMuted,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                pw.SizedBox(height: PdfConstants.spaceXs),

                // Company
                pw.Text(
                  company,
                  style: pw.TextStyle(
                    fontSize: PdfConstants.fontSizeH4,
                    color: primaryColor,
                    fontStyle: pw.FontStyle.italic,
                  ),
                ),

                // Description
                if (description != null && description.isNotEmpty) ...[
                  pw.SizedBox(height: PdfConstants.spaceSm),
                  pw.Text(
                    description,
                    style: pw.TextStyle(
                      fontSize: PdfConstants.fontSizeBody,
                      color: PdfConstants.textBody,
                      lineSpacing: PdfConstants.lineHeightNormal,
                    ),
                  ),
                ],

                // Bullets
                if (bullets.isNotEmpty) ...[
                  pw.SizedBox(height: PdfConstants.bulletSpacing),
                  ...bullets.map((bullet) => _buildBulletPoint(bullet)),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Education entry
  static pw.Widget _buildEducationEntry(
    String degree,
    String institution,
    String dateRange,
    String? details,
    PdfColor primaryColor,
  ) {
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
                pw.SizedBox(height: PdfConstants.spaceXs),
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
              fontWeight: pw.FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  /// Bullet point
  static pw.Widget _buildBulletPoint(String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(
        left: PdfConstants.bulletIndent,
        top: PdfConstants.bulletSpacing,
      ),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            PdfConstants.bulletCharacter + ' ',
            style: pw.TextStyle(
              fontSize: PdfConstants.fontSizeBody,
              color: PdfConstants.textBody,
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
}
