import '../cv_templates/electric_cv_template.dart';
import '../cv_templates/professional_cv_template.dart';
import '../cover_letter_templates/professional_cover_letter_template.dart';
import 'base_pdf_template.dart';
import '../../models/cv_data.dart';
import '../../models/cover_letter.dart';

/// Registry of all available PDF templates
///
/// This provides a centralized way to access and manage templates.
///
/// ## Adding a new template:
///
/// 1. Create a class extending `BasePdfTemplate<YourDataType>`
/// 2. Implement the `info` getter with a `TemplateInfo`
/// 3. Implement the `build` method
/// 4. Add a static `instance` getter for singleton access
/// 5. Register it in the appropriate list below
///
/// ```dart
/// class MyNewCvTemplate extends BasePdfTemplate<CvData> with PdfTemplateHelpers {
///   MyNewCvTemplate._();
///   static final instance = MyNewCvTemplate._();
///
///   @override
///   TemplateInfo get info => const TemplateInfo(
///     id: 'my_new_cv',
///     name: 'My New',
///     description: 'A fresh new design',
///     category: 'cv',
///     previewTags: ['modern', 'clean'],
///   );
///
///   @override
///   Future<Uint8List> build(CvData data, TemplateStyle style, {...}) async {
///     // Build your PDF here using PdfStyling
///   }
/// }
/// ```
class PdfTemplateRegistry {
  PdfTemplateRegistry._();

  // ===========================================================================
  // CV TEMPLATES
  // ===========================================================================

  /// All available CV templates
  static final List<BasePdfTemplate<CvData>> cvTemplates = [
    ProfessionalCvTemplate.instance, // New unified professional template (recommended)
    ElectricCvTemplate.instance, // Legacy template (kept for compatibility)
    // Add more CV templates here:
    // ModernCvTemplate.instance,
    // CreativeCvTemplate.instance,
  ];

  /// Get default CV template
  static BasePdfTemplate<CvData> get defaultCvTemplate =>
      ProfessionalCvTemplate.instance;

  /// Get CV template by ID
  static BasePdfTemplate<CvData>? getCvTemplateById(String id) {
    try {
      return cvTemplates.firstWhere((t) => t.info.id == id);
    } catch (_) {
      return null;
    }
  }

  /// Get CV template by name
  static BasePdfTemplate<CvData>? getCvTemplateByName(String name) {
    try {
      return cvTemplates.firstWhere(
        (t) => t.templateName.toLowerCase() == name.toLowerCase(),
      );
    } catch (_) {
      return null;
    }
  }

  // ===========================================================================
  // COVER LETTER TEMPLATES
  // ===========================================================================

  /// All available cover letter templates
  static final List<BasePdfTemplate<CoverLetter>> coverLetterTemplates = [
    ProfessionalCoverLetterTemplate.instance, // New professional template (recommended)
    // ElectricCoverLetterTemplate.instance, // Legacy - not compatible with BasePdfTemplate
    // Add more cover letter templates here:
  ];

  /// Get default cover letter template
  static BasePdfTemplate<CoverLetter> get defaultCoverLetterTemplate =>
      ProfessionalCoverLetterTemplate.instance;

  /// Get cover letter template by name
  static BasePdfTemplate<CoverLetter>? getCoverLetterTemplateByName(String name) {
    try {
      return coverLetterTemplates.firstWhere(
        (t) => t.templateName.toLowerCase() == name.toLowerCase(),
      );
    } catch (_) {
      return null;
    }
  }

  /// Get cover letter template by ID
  static BasePdfTemplate<CoverLetter>? getCoverLetterTemplateById(String id) {
    try {
      return coverLetterTemplates.firstWhere((t) => t.info.id == id);
    } catch (_) {
      return null;
    }
  }

  // ===========================================================================
  // TEMPLATE INFO / DISCOVERY
  // ===========================================================================

  /// Get all CV template infos for UI display
  static List<TemplateInfo> get cvTemplateInfos =>
      cvTemplates.map((t) => t.info).toList();

  /// Get all cover letter template infos for UI display
  static List<TemplateInfo> get coverLetterTemplateInfos =>
      coverLetterTemplates.map((t) => t.info).toList();

  /// Get all template names for a document type
  static List<String> getTemplateNames(String documentType) {
    switch (documentType.toLowerCase()) {
      case 'cv':
        return cvTemplates.map((t) => t.templateName).toList();
      case 'cover_letter':
        return coverLetterTemplates.map((t) => t.templateName).toList();
      default:
        return [];
    }
  }

  /// Get CV templates by tag
  static List<BasePdfTemplate<CvData>> getCvTemplatesByTag(String tag) {
    return cvTemplates
        .where((t) => t.info.previewTags.contains(tag.toLowerCase()))
        .toList();
  }

  /// Get cover letter templates by tag
  static List<BasePdfTemplate<CoverLetter>> getCoverLetterTemplatesByTag(String tag) {
    return coverLetterTemplates
        .where((t) => t.info.previewTags.contains(tag.toLowerCase()))
        .toList();
  }
}
