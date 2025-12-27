import 'dart:io';
import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models/cv_data.dart';
import '../models/template_style.dart';
import '../pdf/cv_templates/professional_cv_template.dart';
import '../pdf/cv_templates/modern_cv_template.dart';
import '../pdf/cv_templates/executive_cv_template.dart';

/// Service for generating professional CV PDFs from CvTemplate/CvData
class CvTemplatePdfService {
  /// Generate a CV PDF from CvData using template classes
  ///
  /// If [includeProfilePicture] is true, the profile picture from
  /// contactDetails.profilePicturePath will be loaded and included.
  Future<File> generatePdfFromCvData({
    required CvData cvData,
    required String outputPath,
    TemplateStyle? templateStyle,
    bool includeProfilePicture = true,
  }) async {
    final style = templateStyle ?? TemplateStyle.professional;
    final pdf = pw.Document();

    // Load profile picture if path is provided
    Uint8List? profileImageBytes;
    if (includeProfilePicture) {
      profileImageBytes = await _loadProfileImage(
        cvData.contactDetails?.profilePicturePath,
      );
    }

    // Use specialized template classes based on template type (3 distinct templates)
    switch (style.type) {
      case TemplateType.modern:
        // Modern two-column template with sidebar
        ModernCvTemplate.build(
          pdf,
          cvData,
          style,
          profileImageBytes: profileImageBytes,
        );
      case TemplateType.creative:
        // Creative template with timeline and unique graphics
        ExecutiveCvTemplate.build(
          pdf,
          cvData,
          style,
          profileImageBytes: profileImageBytes,
        );
      case TemplateType.professional:
        // Classic single-column template
        ProfessionalCvTemplate.build(
          pdf,
          cvData,
          style,
          profileImageBytes: profileImageBytes,
        );
    }

    // Save the PDF
    final file = File(outputPath);
    await file.writeAsBytes(await pdf.save());
    return file;
  }

  /// Load profile image bytes from file path
  Future<Uint8List?> _loadProfileImage(String? imagePath) async {
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

  /// Legacy method - Generate a CV PDF with inline building (kept for compatibility)
  Future<File> generatePdfFromCvDataLegacy({
    required CvData cvData,
    required String outputPath,
    TemplateStyle? templateStyle,
  }) async {
    final style = templateStyle ?? TemplateStyle.professional;
    final pdf = pw.Document();

    // Load fonts for better typography
    final boldFont = await PdfGoogleFonts.interBold();
    final regularFont = await PdfGoogleFonts.interRegular();
    final mediumFont = await PdfGoogleFonts.interMedium();

    // Convert Flutter Color to PdfColor
    final color = style.primaryColor;
    final accentColor = PdfColor(
      (color.r * 255.0).round().clamp(0, 255) / 255,
      (color.g * 255.0).round().clamp(0, 255) / 255,
      (color.b * 255.0).round().clamp(0, 255) / 255,
      (color.a * 255.0).round().clamp(0, 255) / 255,
    );

    // Adjust margins based on template type
    final margins = _getMargins(style.type);

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: margins,
        build: (context) => [
          // Header section with name and contact info
          _buildHeader(
            cvData,
            accentColor,
            boldFont,
            regularFont,
            style.type,
          ),
          pw.SizedBox(height: 24),

          // Profile summary
          if (cvData.profile.isNotEmpty)
            _buildSection(
              title: 'Profile',
              accentColor: accentColor,
              boldFont: boldFont,
              mediumFont: mediumFont,
              regularFont: regularFont,
              templateType: style.type,
              content: [
                pw.Text(
                  cvData.profile,
                  style: pw.TextStyle(
                    font: regularFont,
                    fontSize: 10,
                    lineSpacing: 1.5,
                    color: PdfColors.grey800,
                  ),
                ),
              ],
            ),

          // Work Experience
          if (cvData.experiences.isNotEmpty) ...[
            pw.SizedBox(height: 20),
            _buildSection(
              title: 'Work Experience',
              accentColor: accentColor,
              boldFont: boldFont,
              mediumFont: mediumFont,
              regularFont: regularFont,
              templateType: style.type,
              content: cvData.experiences
                  .map((exp) => _buildWorkExperience(
                        exp,
                        mediumFont,
                        regularFont,
                        accentColor,
                      ))
                  .toList(),
            ),
          ],

          // Education
          if (cvData.education.isNotEmpty) ...[
            pw.SizedBox(height: 20),
            _buildSection(
              title: 'Education',
              accentColor: accentColor,
              boldFont: boldFont,
              mediumFont: mediumFont,
              regularFont: regularFont,
              templateType: style.type,
              content: cvData.education
                  .map((edu) => _buildEducation(
                        edu,
                        mediumFont,
                        regularFont,
                        accentColor,
                      ))
                  .toList(),
            ),
          ],

          // Skills
          if (cvData.skills.isNotEmpty) ...[
            pw.SizedBox(height: 20),
            _buildSection(
              title: 'Skills',
              accentColor: accentColor,
              boldFont: boldFont,
              mediumFont: mediumFont,
              regularFont: regularFont,
              templateType: style.type,
              content: [
                _buildSkills(cvData.skills, regularFont, accentColor),
              ],
            ),
          ],

          // Languages
          if (cvData.languages.isNotEmpty) ...[
            pw.SizedBox(height: 20),
            _buildSection(
              title: 'Languages',
              accentColor: accentColor,
              boldFont: boldFont,
              mediumFont: mediumFont,
              regularFont: regularFont,
              templateType: style.type,
              content: [
                _buildLanguages(cvData.languages, regularFont, accentColor),
              ],
            ),
          ],

          // Interests
          if (cvData.interests.isNotEmpty) ...[
            pw.SizedBox(height: 20),
            _buildSection(
              title: 'Interests',
              accentColor: accentColor,
              boldFont: boldFont,
              mediumFont: mediumFont,
              regularFont: regularFont,
              templateType: style.type,
              content: [
                pw.Text(
                  cvData.interests.join(' • '),
                  style: pw.TextStyle(
                    font: regularFont,
                    fontSize: 10,
                    color: PdfColors.grey800,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );

    // Save the PDF
    final file = File(outputPath);
    await file.writeAsBytes(await pdf.save());
    return file;
  }

  /// Get margins based on template type
  pw.EdgeInsets _getMargins(TemplateType type) {
    switch (type) {
      case TemplateType.professional:
        return const pw.EdgeInsets.all(50); // Traditional margins
      case TemplateType.modern:
      case TemplateType.creative:
        return const pw.EdgeInsets.all(40); // Standard margins
    }
  }

  /// Build the header with name and contact information
  pw.Widget _buildHeader(
    CvData cvData,
    PdfColor accentColor,
    pw.Font boldFont,
    pw.Font regularFont,
    TemplateType templateType,
  ) {
    final isClassic = templateType == TemplateType.professional;
    final contactDetails = cvData.contactDetails;

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        // Name
        pw.Text(
          contactDetails?.fullName ?? 'No Name',
          style: pw.TextStyle(
            font: boldFont,
            fontSize: isClassic ? 32 : 28,
            color: isClassic ? PdfColors.black : accentColor,
            letterSpacing: isClassic ? -1.0 : -0.5,
          ),
        ),
        pw.SizedBox(height: isClassic ? 12 : 8),

        // Contact info
        if (contactDetails != null)
          pw.Wrap(
            spacing: 16,
            runSpacing: 4,
            children: [
              if (contactDetails.email != null && contactDetails.email!.isNotEmpty)
                _buildContactItem(
                    'Email', contactDetails.email!, regularFont, accentColor, isClassic),
              if (contactDetails.phone != null && contactDetails.phone!.isNotEmpty)
                _buildContactItem(
                    'Phone', contactDetails.phone!, regularFont, accentColor, isClassic),
              if (contactDetails.address != null && contactDetails.address!.isNotEmpty)
                _buildContactItem('Address', contactDetails.address!, regularFont,
                    accentColor, isClassic),
              if (contactDetails.linkedin != null && contactDetails.linkedin!.isNotEmpty)
                _buildContactItem('LinkedIn', contactDetails.linkedin!, regularFont,
                    accentColor, isClassic),
              if (contactDetails.website != null && contactDetails.website!.isNotEmpty)
                _buildContactItem('Website', contactDetails.website!, regularFont,
                    accentColor, isClassic),
            ],
          ),

        // Divider
        pw.SizedBox(height: isClassic ? 16 : 12),
        pw.Container(
          height: isClassic ? 1 : 2,
          color: isClassic ? PdfColors.grey400 : accentColor,
        ),
      ],
    );
  }

  /// Build a contact item with text
  pw.Widget _buildContactItem(
    String label,
    String text,
    pw.Font font,
    PdfColor accentColor,
    bool isClassic,
  ) {
    return pw.Row(
      mainAxisSize: pw.MainAxisSize.min,
      children: [
        pw.Text(
          '$label: ',
          style: pw.TextStyle(
            font: font,
            fontSize: 9,
            color: isClassic ? PdfColors.grey700 : accentColor,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
        pw.Text(
          text,
          style: pw.TextStyle(
            font: font,
            fontSize: 9,
            color: PdfColors.grey700,
          ),
        ),
      ],
    );
  }

  /// Build a section with title and content
  pw.Widget _buildSection({
    required String title,
    required PdfColor accentColor,
    required pw.Font boldFont,
    required pw.Font mediumFont,
    required pw.Font regularFont,
    required TemplateType templateType,
    required List<pw.Widget> content,
  }) {
    final isClassic = templateType == TemplateType.professional;

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          title.toUpperCase(),
          style: pw.TextStyle(
            font: boldFont,
            fontSize: isClassic ? 12 : 14,
            color: isClassic ? PdfColors.grey800 : accentColor,
            letterSpacing: isClassic ? 2.0 : 1.2,
          ),
        ),
        pw.SizedBox(height: 8),
        if (!isClassic)
          pw.Container(
            width: 40,
            height: 2,
            color: accentColor,
          ),
        pw.SizedBox(height: 12),
        ...content,
      ],
    );
  }

  /// Build work experience entry
  pw.Widget _buildWorkExperience(
    Experience exp,
    pw.Font mediumFont,
    pw.Font regularFont,
    PdfColor accentColor,
  ) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 16),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          // Position and Date Range
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Expanded(
                child: pw.Text(
                  exp.title,
                  style: pw.TextStyle(
                    font: mediumFont,
                    fontSize: 12,
                    color: PdfColors.grey900,
                  ),
                ),
              ),
              pw.Text(
                exp.dateRange,
                style: pw.TextStyle(
                  font: regularFont,
                  fontSize: 9,
                  color: accentColor,
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 4),

          // Company
          pw.Text(
            exp.company,
            style: pw.TextStyle(
              font: mediumFont,
              fontSize: 10,
              color: PdfColors.grey700,
            ),
          ),
          pw.SizedBox(height: 8),

          // Description
          if (exp.description != null && exp.description!.isNotEmpty)
            pw.Padding(
              padding: const pw.EdgeInsets.only(bottom: 6),
              child: pw.Text(
                exp.description!,
                style: pw.TextStyle(
                  font: regularFont,
                  fontSize: 10,
                  color: PdfColors.grey800,
                  lineSpacing: 1.4,
                ),
              ),
            ),

          // Bullet points
          if (exp.bullets.isNotEmpty)
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: exp.bullets
                  .map(
                    (bullet) => pw.Padding(
                      padding: const pw.EdgeInsets.only(left: 12, bottom: 3),
                      child: pw.Row(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                            '- ',
                            style: pw.TextStyle(
                              font: regularFont,
                              fontSize: 10,
                              color: accentColor,
                            ),
                          ),
                          pw.Expanded(
                            child: pw.Text(
                              bullet,
                              style: pw.TextStyle(
                                font: regularFont,
                                fontSize: 9,
                                color: PdfColors.grey700,
                                lineSpacing: 1.3,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                  .toList(),
            ),
        ],
      ),
    );
  }

  /// Build education entry
  pw.Widget _buildEducation(
    Education edu,
    pw.Font mediumFont,
    pw.Font regularFont,
    PdfColor accentColor,
  ) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 16),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          // Degree and Date Range
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Expanded(
                child: pw.Text(
                  edu.degree,
                  style: pw.TextStyle(
                    font: mediumFont,
                    fontSize: 12,
                    color: PdfColors.grey900,
                  ),
                ),
              ),
              pw.Text(
                edu.dateRange,
                style: pw.TextStyle(
                  font: regularFont,
                  fontSize: 9,
                  color: accentColor,
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 4),

          // Institution
          pw.Text(
            edu.institution,
            style: pw.TextStyle(
              font: mediumFont,
              fontSize: 10,
              color: PdfColors.grey700,
            ),
          ),

          // Description
          if (edu.description != null && edu.description!.isNotEmpty) ...[
            pw.SizedBox(height: 6),
            pw.Text(
              edu.description!,
              style: pw.TextStyle(
                font: regularFont,
                fontSize: 9,
                color: PdfColors.grey700,
                lineSpacing: 1.3,
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Build skills section
  pw.Widget _buildSkills(
    List<String> skills,
    pw.Font font,
    PdfColor accentColor,
  ) {
    return pw.Wrap(
      spacing: 8,
      runSpacing: 6,
      children: skills
          .map(
            (skill) => pw.Container(
              padding: const pw.EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 4,
              ),
              decoration: pw.BoxDecoration(
                color: accentColor.flatten(),
                borderRadius: const pw.BorderRadius.all(
                  pw.Radius.circular(4),
                ),
              ),
              child: pw.Text(
                skill,
                style: pw.TextStyle(
                  font: font,
                  fontSize: 9,
                  color: PdfColors.white,
                ),
              ),
            ),
          )
          .toList(),
    );
  }

  /// Build languages section
  pw.Widget _buildLanguages(
    List<LanguageSkill> languages,
    pw.Font font,
    PdfColor accentColor,
  ) {
    return pw.Wrap(
      spacing: 16,
      runSpacing: 6,
      children: languages
          .map(
            (lang) => pw.Row(
              mainAxisSize: pw.MainAxisSize.min,
              children: [
                pw.Text(
                  lang.language,
                  style: pw.TextStyle(
                    font: font,
                    fontSize: 10,
                    color: PdfColors.grey900,
                  ),
                ),
                pw.SizedBox(width: 6),
                pw.Container(
                  padding: const pw.EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: pw.BoxDecoration(
                    color: accentColor.flatten(),
                    borderRadius: const pw.BorderRadius.all(
                      pw.Radius.circular(3),
                    ),
                  ),
                  child: pw.Text(
                    lang.level,
                    style: pw.TextStyle(
                      font: font,
                      fontSize: 7,
                      color: PdfColors.white,
                    ),
                  ),
                ),
              ],
            ),
          )
          .toList(),
    );
  }
}
