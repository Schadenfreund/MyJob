import 'dart:io';
import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../../models/cv_data.dart';
import '../../models/template_style.dart';
import '../../constants/pdf_constants.dart';
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
        // Ignore image loading errors
      }
    }

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfConstants.pageFormat,
        margin: pw.EdgeInsets.only(
          top: PdfConstants.marginTop,
          bottom: PdfConstants.marginBottom,
          left: PdfConstants.marginLeft,
          right: PdfConstants.marginRight,
        ),
        build: (context) => [
          // Header with optional profile picture
          _buildHeader(cv, primaryColor, accentColor, profileImage),

          PdfComponents.sectionSpacer,

          // Profile/Summary
          if (cv.profile.isNotEmpty) ...[
            PdfComponents.buildSectionHeaderDivider('Professional Summary', primaryColor),
            pw.SizedBox(height: PdfConstants.spaceMd),
            PdfComponents.buildParagraph(cv.profile, justified: true),
            PdfComponents.sectionSpacer,
          ],

          // Professional Experience
          if (cv.experiences.isNotEmpty) ...[
            PdfComponents.buildSectionHeaderDivider('Professional Experience', primaryColor),
            pw.SizedBox(height: PdfConstants.spaceMd),
            ...cv.experiences.map((exp) {
              return PdfComponents.buildExperienceEntry(
                title: exp.title,
                company: exp.company,
                dateRange: exp.dateRange,
                description: exp.description,
                bullets: exp.bullets,
                primaryColor: primaryColor,
              );
            }),
            PdfComponents.sectionSpacer,
          ],

          // Education
          if (cv.education.isNotEmpty) ...[
            PdfComponents.buildSectionHeaderDivider('Education', primaryColor),
            pw.SizedBox(height: PdfConstants.spaceMd),
            ...cv.education.map((edu) {
              return PdfComponents.buildEducationEntry(
                degree: edu.degree,
                institution: edu.institution,
                dateRange: edu.dateRange,
                details: edu.description,
                primaryColor: primaryColor,
              );
            }),
            PdfComponents.sectionSpacer,
          ],

          // Skills (with proficiency levels)
          if (cv.skills.isNotEmpty) ...[
            PdfComponents.buildSectionHeaderDivider('Skills', primaryColor),
            pw.SizedBox(height: PdfConstants.spaceMd),
            PdfComponents.buildSkillBadgesWithLevels(cv.skills, accentColor),
            PdfComponents.sectionSpacer,
          ],

          // Languages
          if (cv.languages.isNotEmpty) ...[
            PdfComponents.buildSectionHeaderDivider('Languages', primaryColor),
            pw.SizedBox(height: PdfConstants.spaceMd),
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: cv.languages.map((lang) {
                return PdfComponents.buildKeyValuePair(
                  lang.language,
                  lang.level,
                  keyColor: primaryColor,
                );
              }).toList(),
            ),
            if (cv.interests.isNotEmpty) PdfComponents.sectionSpacer,
          ],

          // Interests
          if (cv.interests.isNotEmpty) ...[
            PdfComponents.buildSectionHeaderDivider('Interests', primaryColor),
            pw.SizedBox(height: PdfConstants.spaceMd),
            PdfComponents.buildInlineList(cv.interests),
          ],
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

  /// Build header with optional profile picture
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
