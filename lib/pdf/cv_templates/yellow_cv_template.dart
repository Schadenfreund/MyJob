import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../../models/cv_data.dart';
import '../../models/template_style.dart';
import '../../models/template_customization.dart';
import '../../constants/pdf_constants.dart';
import '../core/customized_constants.dart';
import '../shared/pdf_components.dart';

/// Yellow CV Template - Professional High-Contrast Design
///
/// REDESIGNED for professional quality with:
/// - Proper typography hierarchy using PdfConstants
/// - Generous, consistent spacing
/// - Clear visual hierarchy
/// - No overlapping elements
/// - Professional color scheme
class YellowCvTemplate {
  YellowCvTemplate._();

  // Professional color palette
  static const PdfColor _yellow = PdfColor.fromInt(0xFFFFD700);  // Gold (less harsh than electric yellow)
  static const PdfColor _yellowAccent = PdfColor.fromInt(0xFFFFA500);  // Orange-yellow accent
  static const PdfColor _black = PdfColors.black;
  static const PdfColor _darkGray = PdfColor.fromInt(0xFF2D3748);
  static const PdfColor _mediumGray = PdfColor.fromInt(0xFF4A5568);
  static const PdfColor _lightGray = PdfColor.fromInt(0xFF718096);

  static const double _sidebarPadding = 28.0;
  static const double _mainPadding = 36.0;
  static const double _photoSize = 90.0;

  /// Build the Yellow CV PDF with optional customization
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
    // Apply customization if provided
    final custom = customization != null
        ? CustomizedConstants(customization)
        : null;

    // Create font fallback list for Unicode support
    final fontFallback = [regularFont, boldFont, mediumFont];

    // Create profile image if bytes provided (respect customization toggle)
    pw.ImageProvider? profileImage;
    final showPhoto = custom?.showProfilePhoto ?? true;
    if (profileImageBytes != null && showPhoto) {
      try {
        profileImage = pw.MemoryImage(profileImageBytes);
      } catch (_) {
        // Ignore image loading errors
      }
    }

    // Calculate sidebar width based on customization
    final sidebarWidth = custom != null
        ? custom.getSidebarWidth(PdfConstants.pageFormat.width)
        : (PdfConstants.pageFormat.width * PdfConstants.sidebarWidthRatio);

    pdf.addPage(
      pw.Page(
        pageFormat: PdfConstants.pageFormat,
        margin: pw.EdgeInsets.zero,
        theme: pw.ThemeData.withFont(
          base: regularFont,
          bold: boldFont,
          fontFallback: fontFallback,
        ),
        build: (context) => pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            // Left Sidebar - Customizable background color
            _buildSidebar(cv, profileImage, sidebarWidth, custom),

            // Right Main Content - White background
            _buildMainContent(cv, custom),
          ],
        ),
      ),
    );
  }

  /// Build professional sidebar with proper typography
  static pw.Widget _buildSidebar(
    CvData cv,
    pw.ImageProvider? profileImage,
    double sidebarWidth,
    CustomizedConstants? custom,
  ) {
    return pw.Container(
      width: sidebarWidth,
      height: PdfConstants.pageFormat.height,
      color: _yellow,
      padding: pw.EdgeInsets.all(_sidebarPadding),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          // Profile Photo (if available)
          if (profileImage != null) ...[
            _buildProfilePhoto(profileImage),
            pw.SizedBox(height: PdfConstants.spaceXl),
          ],

          // Contact Information
          _buildSidebarSection('CONTACT'),
          pw.SizedBox(height: PdfConstants.spaceMd),
          _buildContactInfo(cv.contactDetails),
          pw.SizedBox(height: PdfConstants.space2xl),

          // Skills
          if (cv.skills.isNotEmpty) ...[
            _buildSidebarSection('SKILLS'),
            pw.SizedBox(height: PdfConstants.spaceMd),
            ...cv.skills.take(8).map((skill) => _buildSkillBar(skill, sidebarWidth)),
            pw.SizedBox(height: PdfConstants.space2xl),
          ],

          // Spacer to push languages to bottom
          pw.Spacer(),

          // Languages (if any)
          if (cv.languages.isNotEmpty) ...[
            _buildSidebarSection('LANGUAGES'),
            pw.SizedBox(height: PdfConstants.spaceMd),
            ...cv.languages.take(4).map((lang) => _buildLanguageItem(lang.language, lang.level)),
            pw.SizedBox(height: PdfConstants.spaceLg),
          ],
        ],
      ),
    );
  }

  /// Build main content with professional typography and spacing
  static pw.Widget _buildMainContent(CvData cv, CustomizedConstants? custom) {
    return pw.Expanded(
      child: pw.Container(
        height: PdfConstants.pageFormat.height,
        color: PdfColors.white,
        padding: pw.EdgeInsets.all(_mainPadding),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            // Name and Title Header
            _buildHeader(cv.contactDetails),
            pw.SizedBox(height: PdfConstants.space2xl),

            // Professional Profile/Summary
            if (cv.profile.isNotEmpty) ...[
              _buildMainSection('PROFILE'),
              pw.SizedBox(height: PdfConstants.spaceMd),
              pw.Text(
                cv.profile,
                style: pw.TextStyle(
                  fontSize: PdfConstants.fontSizeBody,
                  lineSpacing: PdfConstants.lineHeightNormal,
                  color: PdfConstants.textBody,
                ),
                textAlign: pw.TextAlign.justify,
              ),
              pw.SizedBox(height: PdfConstants.sectionSpacing),
            ],

            // Work Experience
            if (cv.experiences.isNotEmpty) ...[
              _buildMainSection('WORK EXPERIENCE'),
              pw.SizedBox(height: PdfConstants.spaceMd),
              ...cv.experiences.take(4).map(_buildExperienceEntry),
            ],

            pw.SizedBox(height: PdfConstants.spaceLg),

            // Education
            if (cv.education.isNotEmpty) ...[
              _buildMainSection('EDUCATION'),
              pw.SizedBox(height: PdfConstants.spaceMd),
              ...cv.education.take(3).map(_buildEducationEntry),
            ],
          ],
        ),
      ),
    );
  }

  // =========================================================================
  // HEADER COMPONENTS
  // =========================================================================

  /// Professional header with name and title
  static pw.Widget _buildHeader(ContactDetails? contact) {
    final name = contact?.fullName ?? 'Your Name';
    final title = contact?.jobTitle;

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        // Name - Large and bold
        pw.Text(
          name.toUpperCase(),
          style: pw.TextStyle(
            fontSize: PdfConstants.fontSizeName,
            fontWeight: pw.FontWeight.bold,
            color: _black,
            letterSpacing: 1.5,
            lineSpacing: PdfConstants.lineHeightTight,
          ),
        ),

        // Yellow accent bar
        pw.Container(
          margin: pw.EdgeInsets.only(top: PdfConstants.spaceSm),
          width: 60,
          height: 4,
          color: _yellowAccent,
        ),

        // Job title (if available)
        if (title != null && title.isNotEmpty) ...[
          pw.SizedBox(height: PdfConstants.spaceSm),
          pw.Text(
            title,
            style: pw.TextStyle(
              fontSize: PdfConstants.fontSizeH3,
              color: _mediumGray,
              fontWeight: pw.FontWeight.normal,
            ),
          ),
        ],
      ],
    );
  }

  // =========================================================================
  // SIDEBAR COMPONENTS
  // =========================================================================

  /// Sidebar section header
  static pw.Widget _buildSidebarSection(String title) {
    return pw.Text(
      title,
      style: pw.TextStyle(
        fontSize: PdfConstants.fontSizeH2,
        fontWeight: pw.FontWeight.bold,
        color: _black,
        letterSpacing: 1.2,
      ),
    );
  }

  /// Profile photo with professional styling
  static pw.Widget _buildProfilePhoto(pw.ImageProvider image) {
    return pw.Container(
      width: _photoSize,
      height: _photoSize,
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: _black, width: 3),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.ClipRRect(
        horizontalRadius: 5,
        verticalRadius: 5,
        child: pw.Image(image, fit: pw.BoxFit.cover),
      ),
    );
  }

  /// Contact information with proper spacing
  static pw.Widget _buildContactInfo(ContactDetails? contact) {
    if (contact == null) return pw.SizedBox();

    final items = <pw.Widget>[];

    void addItem(String? value, String label) {
      if (value != null && value.isNotEmpty) {
        items.add(
          pw.Padding(
            padding: pw.EdgeInsets.only(bottom: PdfConstants.spaceSm),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  label,
                  style: pw.TextStyle(
                    fontSize: PdfConstants.fontSizeTiny,
                    fontWeight: pw.FontWeight.bold,
                    color: _darkGray,
                  ),
                ),
                pw.SizedBox(height: 2),
                pw.Text(
                  value,
                  style: pw.TextStyle(
                    fontSize: PdfConstants.fontSizeSmall,
                    color: _black,
                  ),
                ),
              ],
            ),
          ),
        );
      }
    }

    addItem(contact.email, 'EMAIL');
    addItem(contact.phone, 'PHONE');
    addItem(contact.address, 'ADDRESS');
    addItem(contact.linkedin, 'LINKEDIN');

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: items,
    );
  }

  /// Professional skill bar with proper sizing
  static pw.Widget _buildSkillBar(String skillString, double sidebarWidth) {
    final parsed = PdfComponents.parseSkillString(skillString);

    return pw.Container(
      margin: pw.EdgeInsets.only(bottom: PdfConstants.spaceSm + 2),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          // Skill name
          pw.Text(
            parsed.name,
            style: pw.TextStyle(
              fontSize: PdfConstants.fontSizeSmall,
              fontWeight: pw.FontWeight.bold,
              color: _black,
            ),
          ),
          pw.SizedBox(height: 4),

          // Skill bar
          pw.Stack(
            children: [
              // Background
              pw.Container(
                width: double.infinity,
                height: 6,
                decoration: pw.BoxDecoration(
                  color: PdfColors.white,
                  borderRadius: pw.BorderRadius.circular(3),
                  border: pw.Border.all(color: _darkGray, width: 0.5),
                ),
              ),
              // Fill
              pw.Container(
                width: (sidebarWidth - _sidebarPadding * 2) * parsed.percentage,
                height: 6,
                decoration: pw.BoxDecoration(
                  color: _darkGray,
                  borderRadius: pw.BorderRadius.circular(3),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Language item with level
  static pw.Widget _buildLanguageItem(String language, String level) {
    return pw.Padding(
      padding: pw.EdgeInsets.only(bottom: PdfConstants.spaceSm),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            language,
            style: pw.TextStyle(
              fontSize: PdfConstants.fontSizeSmall,
              fontWeight: pw.FontWeight.bold,
              color: _black,
            ),
          ),
          pw.Text(
            level,
            style: pw.TextStyle(
              fontSize: PdfConstants.fontSizeTiny,
              color: _darkGray,
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================================
  // MAIN CONTENT COMPONENTS
  // =========================================================================

  /// Main section header
  static pw.Widget _buildMainSection(String title) {
    return pw.Row(
      children: [
        pw.Container(
          width: 4,
          height: PdfConstants.fontSizeH2 + 4,
          color: _yellowAccent,
          margin: pw.EdgeInsets.only(right: PdfConstants.spaceSm),
        ),
        pw.Text(
          title,
          style: pw.TextStyle(
            fontSize: PdfConstants.fontSizeH2,
            fontWeight: pw.FontWeight.bold,
            color: _black,
            letterSpacing: 1.2,
          ),
        ),
      ],
    );
  }

  /// Work experience entry with professional formatting
  static pw.Widget _buildExperienceEntry(Experience exp) {
    return pw.Container(
      margin: pw.EdgeInsets.only(bottom: PdfConstants.entrySpacing),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          // Job title and date
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Expanded(
                child: pw.Text(
                  exp.title,
                  style: pw.TextStyle(
                    fontSize: PdfConstants.fontSizeH3,
                    fontWeight: pw.FontWeight.bold,
                    color: _darkGray,
                  ),
                ),
              ),
              pw.SizedBox(width: PdfConstants.spaceMd),
              pw.Text(
                exp.dateRange,
                style: pw.TextStyle(
                  fontSize: PdfConstants.fontSizeSmall,
                  color: _lightGray,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ],
          ),

          pw.SizedBox(height: 4),

          // Company name
          pw.Text(
            exp.company,
            style: pw.TextStyle(
              fontSize: PdfConstants.fontSizeH4,
              color: _yellowAccent,
              fontWeight: pw.FontWeight.bold,
            ),
          ),

          // Description
          if (exp.description != null && exp.description!.isNotEmpty) ...[
            pw.SizedBox(height: PdfConstants.spaceSm),
            pw.Text(
              exp.description!,
              style: pw.TextStyle(
                fontSize: PdfConstants.fontSizeBody,
                lineSpacing: PdfConstants.lineHeightNormal,
                color: PdfConstants.textBody,
              ),
            ),
          ],

          // Bullet points
          if (exp.bullets.isNotEmpty) ...[
            pw.SizedBox(height: PdfConstants.spaceSm),
            ...exp.bullets.map((bullet) => pw.Padding(
                  padding: pw.EdgeInsets.only(
                    left: PdfConstants.bulletIndent,
                    bottom: PdfConstants.bulletSpacing,
                  ),
                  child: pw.Row(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        '• ',
                        style: pw.TextStyle(
                          fontSize: PdfConstants.fontSizeBody,
                          color: _yellowAccent,
                        ),
                      ),
                      pw.Expanded(
                        child: pw.Text(
                          bullet,
                          style: pw.TextStyle(
                            fontSize: PdfConstants.fontSizeBody,
                            lineSpacing: PdfConstants.lineHeightNormal,
                            color: PdfConstants.textBody,
                          ),
                        ),
                      ),
                    ],
                  ),
                )),
          ],
        ],
      ),
    );
  }

  /// Education entry with professional formatting
  static pw.Widget _buildEducationEntry(Education edu) {
    return pw.Container(
      margin: pw.EdgeInsets.only(bottom: PdfConstants.entrySpacing),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // Degree
                pw.Text(
                  edu.degree,
                  style: pw.TextStyle(
                    fontSize: PdfConstants.fontSizeH3,
                    fontWeight: pw.FontWeight.bold,
                    color: _darkGray,
                  ),
                ),
                pw.SizedBox(height: 4),

                // Institution
                pw.Text(
                  edu.institution,
                  style: pw.TextStyle(
                    fontSize: PdfConstants.fontSizeH4,
                    color: _yellowAccent,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),

                // Description
                if (edu.description != null && edu.description!.isNotEmpty) ...[
                  pw.SizedBox(height: 4),
                  pw.Text(
                    edu.description!,
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

          // Date range
          pw.Text(
            edu.dateRange,
            style: pw.TextStyle(
              fontSize: PdfConstants.fontSizeSmall,
              color: _lightGray,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
