import 'dart:io';
import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../../models/cv_data.dart';
import '../../models/template_style.dart';
import '../../models/template_customization.dart';
import '../../constants/pdf_constants.dart';
import '../core/base_cv_template.dart';
import '../core/customized_constants.dart';
import '../shared/pdf_components.dart';

/// Modern CV Template - Professional Two-Column Layout
///
/// Features:
/// - Customizable sidebar with colored background
/// - Main content area with standard sections
/// - Skill bars with proficiency levels
/// - Contemporary design with clean typography
/// - Optional profile picture support
class ModernCvTemplate {
  ModernCvTemplate._();

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

    // Calculate sidebar width with customization support
    final sidebarWidth = custom?.getSidebarWidth(PdfConstants.pageFormat.width) ??
        (PdfConstants.pageFormat.width * PdfConstants.sidebarWidthRatio);

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
            // Sidebar - template-specific layout
            _buildSidebar(cv, colors.primary, colors.accent, profileImage, sidebarWidth, custom),
            // Main content - uses DRY base sections
            _buildMainContent(cv, colors.primary, colors.accent, custom),
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
    } catch (_) {}
    return null;
  }

  /// Build colored sidebar with contact, skills, languages, and interests
  static pw.Widget _buildSidebar(
    CvData cv,
    PdfColor primaryColor,
    PdfColor accentColor,
    pw.ImageProvider? profileImage,
    double sidebarWidth,
    CustomizedConstants? custom,
  ) {
    final contact = cv.contactDetails;
    final name = contact?.fullName ?? 'Your Name';
    final jobTitle = contact?.jobTitle;
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';

    final uppercase = custom?.uppercaseHeaders ?? true;
    final spacing2xl = custom != null ? custom.sectionSpacing * 1.5 : PdfConstants.space2xl;

    return pw.Container(
      width: sidebarWidth,
      height: PdfConstants.pageFormat.height,
      color: primaryColor,
      padding: pw.EdgeInsets.symmetric(
        horizontal: custom?.spaceMd ?? PdfConstants.spaceLg,
        vertical: spacing2xl,
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          // Profile photo/avatar
          pw.Center(
            child: pw.Container(
              width: 90,
              height: 90,
              decoration: pw.BoxDecoration(
                shape: pw.BoxShape.circle,
                color: profileImage == null ? accentColor : null,
                border: pw.Border.all(color: PdfColors.white, width: 3),
              ),
              child: pw.ClipOval(
                child: profileImage != null
                    ? pw.Image(profileImage, fit: pw.BoxFit.cover)
                    : pw.Center(
                        child: pw.Text(
                          initial,
                          style: pw.TextStyle(
                            fontSize: 32,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.white,
                          ),
                        ),
                      ),
              ),
            ),
          ),
          pw.SizedBox(height: PdfConstants.spaceMd),

          // Name and title
          pw.Center(
            child: pw.Column(
              children: [
                pw.Text(
                  name,
                  style: pw.TextStyle(
                    fontSize: PdfConstants.fontSizeH2,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.white,
                  ),
                  textAlign: pw.TextAlign.center,
                ),
                if (jobTitle != null && jobTitle.isNotEmpty) ...[
                  pw.SizedBox(height: PdfConstants.spaceXs),
                  pw.Text(
                    jobTitle,
                    style: const pw.TextStyle(
                      fontSize: PdfConstants.fontSizeSmall,
                      color: PdfColors.white,
                    ),
                    textAlign: pw.TextAlign.center,
                  ),
                ],
              ],
            ),
          ),
          pw.SizedBox(height: spacing2xl),

          // Contact
          _buildSidebarSection(uppercase ? 'CONTACT' : 'Contact', [
            if (contact?.email != null)
              _buildSidebarItem('E', contact!.email!, accentColor),
            if (contact?.phone != null)
              _buildSidebarItem('P', contact!.phone!, accentColor),
            if (contact?.address != null)
              _buildSidebarItem('A', contact!.address!, accentColor),
          ]),
          pw.SizedBox(height: spacing2xl),

          // Skills
          if (cv.skills.isNotEmpty) ...[
            _buildSidebarSection(
              uppercase ? 'SKILLS' : 'Skills',
              [PdfComponents.buildSkillBarsWhite(cv.skills)],
            ),
            pw.SizedBox(height: spacing2xl),
          ],

          // Languages
          if (cv.languages.isNotEmpty) ...[
            _buildSidebarSection(
              uppercase ? 'LANGUAGES' : 'Languages',
              cv.languages.map((lang) =>
                _buildSidebarItem('•', '${lang.language} - ${lang.level}', accentColor)
              ).toList(),
            ),
            pw.SizedBox(height: spacing2xl),
          ],

          // Interests
          if (cv.interests.isNotEmpty)
            _buildSidebarSection(
              uppercase ? 'INTERESTS' : 'Interests',
              [pw.Wrap(
                spacing: 8,
                runSpacing: 8,
                children: cv.interests.map((interest) =>
                  pw.Text('• $interest', style: const pw.TextStyle(color: PdfColors.white, fontSize: 9))
                ).toList(),
              )],
            ),
        ],
      ),
    );
  }

  static pw.Widget _buildSidebarSection(String title, List<pw.Widget> children) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          title,
          style: pw.TextStyle(
            fontSize: PdfConstants.fontSizeH3,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.white,
            letterSpacing: 1,
          ),
        ),
        pw.SizedBox(height: PdfConstants.spaceSm),
        pw.Container(
          width: 30,
          height: 2,
          color: PdfColors.white,
        ),
        pw.SizedBox(height: PdfConstants.spaceMd),
        ...children,
      ],
    );
  }

  static pw.Widget _buildSidebarItem(String icon, String text, PdfColor iconColor) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 8),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Container(
            width: 16,
            height: 16,
            decoration: pw.BoxDecoration(
              color: iconColor,
              shape: pw.BoxShape.circle,
            ),
            child: pw.Center(
              child: pw.Text(
                icon,
                style: pw.TextStyle(
                  fontSize: 10,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.white,
                ),
              ),
            ),
          ),
          pw.SizedBox(width: 8),
          pw.Expanded(
            child: pw.Text(
              text,
              style: const pw.TextStyle(
                fontSize: 9,
                color: PdfColors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Build main content area using DRY base sections
  static pw.Widget _buildMainContent(
    CvData cv,
    PdfColor primaryColor,
    PdfColor accentColor,
    CustomizedConstants? custom,
  ) {
    return pw.Expanded(
      child: pw.Container(
        padding: pw.EdgeInsets.all(custom?.sectionSpacing ?? PdfConstants.space3xl),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            // Use DRY base template sections
            ...BaseCvTemplate.buildStandardSections(
              cv,
              primaryColor,
              accentColor,
              custom,
            ),
          ],
        ),
      ),
    );
  }
}
