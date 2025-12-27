import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../../models/cv_data.dart';
import '../../models/template_style.dart';
import '../../models/template_customization.dart';
import '../../constants/pdf_constants.dart';
import '../shared/pdf_components.dart';
import 'customized_constants.dart';

/// Base CV Template Builder - DRY foundation for all CV templates
///
/// Provides common functionality:
/// - Profile image loading with customization support
/// - Font loading
/// - Customization handling
/// - Standardized section rendering
abstract class BaseCvTemplate {
  /// Build common CV sections with customization support
  static List<pw.Widget> buildStandardSections(
    CvData cv,
    PdfColor primaryColor,
    PdfColor accentColor,
    CustomizedConstants? custom,
  ) {
    final spacing = custom?.sectionSpacing ?? PdfConstants.sectionSpacing;
    final spaceMd = custom?.spaceMd ?? PdfConstants.spaceMd;
    final uppercase = custom?.uppercaseHeaders ?? true;
    final showDividers = custom?.showDividers ?? true;

    return [
      // Profile/Summary Section
      if (cv.profile.isNotEmpty) ...[
        PdfComponents.buildSectionHeaderDivider(
          'Professional Summary',
          primaryColor,
          uppercase: uppercase,
          showDivider: showDividers,
        ),
        pw.SizedBox(height: spaceMd),
        PdfComponents.buildParagraph(cv.profile, justified: true),
        pw.SizedBox(height: spacing),
      ],

      // Professional Experience Section
      if (cv.experiences.isNotEmpty) ...[
        PdfComponents.buildSectionHeaderDivider(
          'Professional Experience',
          primaryColor,
          uppercase: uppercase,
          showDivider: showDividers,
        ),
        pw.SizedBox(height: spaceMd),
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
        pw.SizedBox(height: spacing),
      ],

      // Education Section
      if (cv.education.isNotEmpty) ...[
        PdfComponents.buildSectionHeaderDivider(
          'Education',
          primaryColor,
          uppercase: uppercase,
          showDivider: showDividers,
        ),
        pw.SizedBox(height: spaceMd),
        ...cv.education.map((edu) {
          return PdfComponents.buildEducationEntry(
            degree: edu.degree,
            institution: edu.institution,
            dateRange: edu.dateRange,
            details: edu.description,
            primaryColor: primaryColor,
          );
        }),
        pw.SizedBox(height: spacing),
      ],

      // Skills Section
      if (cv.skills.isNotEmpty) ...[
        PdfComponents.buildSectionHeaderDivider(
          'Skills',
          primaryColor,
          uppercase: uppercase,
          showDivider: showDividers,
        ),
        pw.SizedBox(height: spaceMd),
        PdfComponents.buildSkillBadgesWithLevels(cv.skills, accentColor),
        pw.SizedBox(height: spacing),
      ],

      // Languages Section
      if (cv.languages.isNotEmpty) ...[
        PdfComponents.buildSectionHeaderDivider(
          'Languages',
          primaryColor,
          uppercase: uppercase,
          showDivider: showDividers,
        ),
        pw.SizedBox(height: spaceMd),
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
        if (cv.interests.isNotEmpty) pw.SizedBox(height: spacing),
      ],

      // Interests Section
      if (cv.interests.isNotEmpty) ...[
        PdfComponents.buildSectionHeaderDivider(
          'Interests',
          primaryColor,
          uppercase: uppercase,
          showDivider: showDividers,
        ),
        pw.SizedBox(height: spaceMd),
        PdfComponents.buildInlineList(cv.interests),
      ],
    ];
  }

  /// Load and validate profile image with customization support
  static pw.ImageProvider? loadProfileImage(
    Uint8List? profileImageBytes,
    CustomizedConstants? custom,
  ) {
    final showPhoto = custom?.showProfilePhoto ?? true;
    if (profileImageBytes == null || !showPhoto) return null;

    try {
      return pw.MemoryImage(profileImageBytes);
    } catch (_) {
      return null; // Gracefully handle image loading errors
    }
  }

  /// Extract colors from style with optional customization
  static ({PdfColor primary, PdfColor accent}) getColors(
    TemplateStyle style,
  ) {
    return (
      primary: PdfColor.fromInt(style.primaryColor.toARGB32()),
      accent: PdfColor.fromInt(style.accentColor.toARGB32()),
    );
  }

  /// Create CustomizedConstants from optional customization
  static CustomizedConstants? getCustomization(
    TemplateCustomization? customization,
  ) {
    return customization != null ? CustomizedConstants(customization) : null;
  }
}
