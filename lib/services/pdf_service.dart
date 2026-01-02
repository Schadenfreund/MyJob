import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' show Color;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models/cv_data.dart';
import '../models/cover_letter.dart';
import '../models/template_style.dart';
import '../models/template_customization.dart';
import '../models/user_data/personal_info.dart';
import '../models/user_data/skill.dart';
import '../models/user_data/work_experience.dart';
import '../models/user_data/language.dart';
import '../models/user_data/interest.dart';
import '../pdf/shared/template_registry.dart';
import '../pdf/shared/pdf_icons.dart';
import '../pdf/cover_letter_templates/electric_cover_letter_template.dart';
import 'pdf_font_service.dart';
import 'log_service.dart';

/// Unified PDF Service for all document generation operations
///
/// This centralized service handles:
/// - CV PDF generation (from CvData or user profile data)
/// - Cover Letter PDF generation
/// - PDF utilities (save, print, share)
/// - Template selection via registry
///
/// All PDF generation uses templates from the PdfTemplateRegistry for a
/// consistent, professional look across all documents.
///
/// Usage:
/// ```dart
/// final service = PdfService.instance;
///
/// // Generate CV PDF with default template
/// final cvBytes = await service.generateCvPdf(cvData, style);
///
/// // Generate CV PDF with specific template
/// final cvBytes = await service.generateCvPdf(
///   cvData,
///   style,
///   templateId: 'classic_cv',
/// );
///
/// // Save to file
/// await service.savePdfToFile(cvBytes, '/path/to/cv.pdf');
/// ```
class PdfService {
  PdfService._();
  static final PdfService instance = PdfService._();

  // ============================================================================
  // CV PDF GENERATION
  // ============================================================================

  /// Generate CV PDF bytes using the specified or default template
  ///
  /// [templateId] - Optional template ID (e.g., 'electric_cv', 'classic_cv')
  ///                If not provided, uses the default template
  Future<Uint8List> generateCvPdf(
    CvData cv,
    TemplateStyle style, {
    TemplateCustomization? customization,
    Uint8List? profileImageBytes,
    String? templateId,
  }) async {
    logDebug('Generating CV PDF with template: ${templateId ?? "default"}',
        tag: 'PdfService');

    try {
      // Ensure icon font is loaded
      await PdfIcons.loadFont();

      // Get template by ID or use default
      final template = templateId != null
          ? (PdfTemplateRegistry.getCvTemplateById(templateId) ??
              PdfTemplateRegistry.defaultCvTemplate)
          : PdfTemplateRegistry.defaultCvTemplate;

      final result = await template.build(
        cv,
        style,
        customization: customization,
        profileImageBytes: profileImageBytes,
      );

      logInfo('CV PDF generated successfully (${result.length} bytes)',
          tag: 'PdfService');
      return result;
    } catch (e, stackTrace) {
      logError('CV PDF generation failed',
          error: e, stackTrace: stackTrace, tag: 'PdfService');
      rethrow;
    }
  }

  /// Generate CV PDF and save to file
  ///
  /// Convenience method that combines generation and file saving.
  /// Automatically loads profile picture if path is provided in cvData.
  Future<File> generateCvToFile({
    required CvData cvData,
    required String outputPath,
    TemplateStyle? templateStyle,
    TemplateCustomization? customization,
    bool includeProfilePicture = true,
  }) async {
    final style = templateStyle ?? TemplateStyle.electric;

    // Load profile picture if path is provided
    Uint8List? profileImageBytes;
    if (includeProfilePicture) {
      profileImageBytes = await _loadImage(
        cvData.contactDetails?.profilePicturePath,
      );
    }

    final bytes = await generateCvPdf(
      cvData,
      style,
      customization: customization,
      profileImageBytes: profileImageBytes,
    );

    return savePdfToFile(bytes, outputPath);
  }

  /// Generate CV PDF from user profile data
  ///
  /// Converts user profile data (PersonalInfo, Skills, etc.) to CvData format
  /// and generates a professional PDF.
  Future<File> generateCvFromUserData({
    required PersonalInfo personalInfo,
    required List<Skill> skills,
    required List<WorkExperience> workExperiences,
    required List<Language> languages,
    required List<Interest> interests,
    required String outputPath,
    Color? accentColor,
  }) async {
    // Convert user data to CvData format
    final cvData = _convertUserDataToCvData(
      personalInfo: personalInfo,
      skills: skills,
      workExperiences: workExperiences,
      languages: languages,
      interests: interests,
    );

    // Create template style with the accent color
    final style = TemplateStyle(
      type: TemplateType.electric,
      accentColor: accentColor ?? const Color(0xFFFFFF00),
    );

    return generateCvToFile(
      cvData: cvData,
      outputPath: outputPath,
      templateStyle: style,
    );
  }

  // ============================================================================
  // COVER LETTER PDF GENERATION
  // ============================================================================

  /// Generate Cover Letter PDF bytes using the Electric template
  Future<Uint8List> generateCoverLetterPdf(
    CoverLetter letter,
    TemplateStyle style, {
    ContactDetails? contactDetails,
  }) async {
    final pdf = pw.Document();
    final fonts = await PdfFontService.getFonts(style.fontFamily);

    ElectricCoverLetterTemplate.build(
      pdf,
      letter,
      style,
      contactDetails,
      regularFont: fonts.regular,
      boldFont: fonts.bold,
      mediumFont: fonts.medium,
    );

    return pdf.save();
  }

  /// Generate Cover Letter PDF and save to file
  Future<File> generateCoverLetterToFile({
    required CoverLetter coverLetter,
    required String outputPath,
    TemplateStyle? templateStyle,
    ContactDetails? contactDetails,
  }) async {
    final style = templateStyle ?? TemplateStyle.electric;

    final bytes = await generateCoverLetterPdf(
      coverLetter,
      style,
      contactDetails: contactDetails,
    );

    return savePdfToFile(bytes, outputPath);
  }

  // ============================================================================
  // PDF UTILITIES
  // ============================================================================

  /// Save PDF bytes to file
  Future<File> savePdfToFile(Uint8List bytes, String filePath) async {
    final file = File(filePath);
    await file.writeAsBytes(bytes);
    return file;
  }

  /// Print PDF
  Future<bool> printPdf(Uint8List bytes, {String? documentName}) async {
    return Printing.layoutPdf(
      onLayout: (_) => bytes,
      name: documentName ?? 'Document',
    );
  }

  /// Share PDF
  Future<bool> sharePdf(Uint8List bytes, {String? filename}) async {
    return Printing.sharePdf(
      bytes: bytes,
      filename: filename ?? 'document.pdf',
    );
  }

  /// Preview PDF using system viewer
  Future<void> previewPdf(Uint8List bytes) async {
    await Printing.layoutPdf(
      onLayout: (_) => bytes,
    );
  }

  /// Get PDF page format
  PdfPageFormat get pageFormat => PdfPageFormat.a4;

  // ============================================================================
  // PRIVATE HELPERS
  // ============================================================================

  /// Load image bytes from file path
  Future<Uint8List?> _loadImage(String? imagePath) async {
    if (imagePath == null || imagePath.isEmpty) return null;
    try {
      final file = File(imagePath);
      if (await file.exists()) {
        return await file.readAsBytes();
      }
    } catch (_) {
      // Ignore file read errors - return null for no image
    }
    return null;
  }

  /// Convert user profile data to CvData format
  CvData _convertUserDataToCvData({
    required PersonalInfo personalInfo,
    required List<Skill> skills,
    required List<WorkExperience> workExperiences,
    required List<Language> languages,
    required List<Interest> interests,
  }) {
    return CvData(
      id: 'export-${DateTime.now().millisecondsSinceEpoch}',
      name: '${personalInfo.fullName} CV',
      profile: '',
      skills: skills
          .map((s) =>
              s.level != null ? '${s.name} (${s.level!.displayName})' : s.name)
          .toList(),
      contactDetails: ContactDetails(
        fullName: personalInfo.fullName,
        email: personalInfo.email,
        phone: personalInfo.phone,
        address: personalInfo.address,
        linkedin: personalInfo.linkedin,
        website: personalInfo.website,
      ),
      experiences: workExperiences
          .map((exp) => Experience(
                title: exp.position,
                company: exp.company,
                startDate: _formatDate(exp.startDate),
                endDate: exp.endDate != null ? _formatDate(exp.endDate!) : null,
                description: exp.description,
                bullets: exp.responsibilities,
              ))
          .toList(),
      education: [],
      languages: languages
          .map((lang) => LanguageSkill(
                language: lang.name,
                level: lang.proficiency.displayName,
              ))
          .toList(),
      interests: interests.map((i) => i.name).toList(),
      lastModified: DateTime.now(),
    );
  }

  /// Format a single date (MMM yyyy)
  String _formatDate(DateTime date) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    return '${months[date.month - 1]} ${date.year}';
  }
}
