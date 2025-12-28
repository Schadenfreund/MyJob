import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../models/user_data/personal_info.dart';
import '../models/user_data/skill.dart';
import '../models/user_data/work_experience.dart';
import '../models/user_data/language.dart';
import '../models/user_data/interest.dart';
import '../models/template_style.dart';
import 'pdf_font_service.dart';

/// Service for generating professional CV PDFs
class CvPdfService {
  /// Generate a CV PDF from user data
  Future<File> generateCvPdf({
    required PersonalInfo personalInfo,
    required List<Skill> skills,
    required List<WorkExperience> workExperiences,
    required List<Language> languages,
    required List<Interest> interests,
    required String outputPath,
    required PdfColor accentColor,
    TemplateType templateType = TemplateType.professional,
  }) async {
    final pdf = pw.Document();

    // Get fonts from centralized font service (DRY principle)
    final fonts = PdfFontService.getFonts();
    final boldFont = fonts.bold;
    final regularFont = fonts.regular;
    final mediumFont = fonts.medium;

    // Adjust margins based on template type
    final margins = _getMargins(templateType);

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: margins,
        build: (context) => [
          // Header section with name and contact info
          _buildHeader(
            personalInfo,
            accentColor,
            boldFont,
            regularFont,
            templateType,
          ),
          pw.SizedBox(height: 24),

          // Profile summary
          if (personalInfo.profileSummary != null &&
              personalInfo.profileSummary!.isNotEmpty)
            _buildSection(
              title: 'Profile',
              accentColor: accentColor,
              boldFont: boldFont,
              mediumFont: mediumFont,
              regularFont: regularFont,
              templateType: templateType,
              content: [
                pw.Text(
                  personalInfo.profileSummary!,
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
          if (workExperiences.isNotEmpty) ...[
            pw.SizedBox(height: 20),
            _buildSection(
              title: 'Work Experience',
              accentColor: accentColor,
              boldFont: boldFont,
              mediumFont: mediumFont,
              regularFont: regularFont,
              templateType: templateType,
              content: workExperiences
                  .map((exp) => _buildWorkExperience(
                        exp,
                        mediumFont,
                        regularFont,
                        accentColor,
                      ))
                  .toList(),
            ),
          ],

          // Skills
          if (skills.isNotEmpty) ...[
            pw.SizedBox(height: 20),
            _buildSection(
              title: 'Skills',
              accentColor: accentColor,
              boldFont: boldFont,
              mediumFont: mediumFont,
              regularFont: regularFont,
              templateType: templateType,
              content: [
                _buildSkills(skills, regularFont, accentColor),
              ],
            ),
          ],

          // Languages
          if (languages.isNotEmpty) ...[
            pw.SizedBox(height: 20),
            _buildSection(
              title: 'Languages',
              accentColor: accentColor,
              boldFont: boldFont,
              mediumFont: mediumFont,
              regularFont: regularFont,
              templateType: templateType,
              content: [
                _buildLanguages(languages, regularFont, accentColor),
              ],
            ),
          ],

          // Interests
          if (interests.isNotEmpty) ...[
            pw.SizedBox(height: 20),
            _buildSection(
              title: 'Interests',
              accentColor: accentColor,
              boldFont: boldFont,
              mediumFont: mediumFont,
              regularFont: regularFont,
              templateType: templateType,
              content: [
                pw.Text(
                  interests.map((i) => i.name).join(' • '),
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
      case TemplateType.yellow:
        return pw.EdgeInsets.zero; // Yellow template uses custom layout with no default margins
    }
  }

  /// Build the header with name and contact information
  pw.Widget _buildHeader(
    PersonalInfo info,
    PdfColor accentColor,
    pw.Font boldFont,
    pw.Font regularFont,
    TemplateType templateType,
  ) {
    final isClassic = templateType == TemplateType.professional;

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        // Name
        pw.Text(
          info.fullName,
          style: pw.TextStyle(
            font: boldFont,
            fontSize: isClassic ? 32 : 28,
            color: isClassic ? PdfColors.black : accentColor,
            letterSpacing: isClassic ? -1.0 : -0.5,
          ),
        ),
        pw.SizedBox(height: isClassic ? 12 : 8),

        // Contact info
        pw.Wrap(
          spacing: 16,
          runSpacing: 4,
          children: [
            if (info.email != null)
              _buildContactItem(
                  'Email', info.email!, regularFont, accentColor, isClassic),
            if (info.phone != null)
              _buildContactItem(
                  'Phone', info.phone!, regularFont, accentColor, isClassic),
            if (info.address != null)
              _buildContactItem('Address', info.address!, regularFont,
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
    WorkExperience exp,
    pw.Font mediumFont,
    pw.Font regularFont,
    PdfColor accentColor,
  ) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 16),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          // Position and Company
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Expanded(
                child: pw.Text(
                  exp.position,
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

          // Company and Location
          pw.Row(
            children: [
              pw.Text(
                exp.company,
                style: pw.TextStyle(
                  font: mediumFont,
                  fontSize: 10,
                  color: PdfColors.grey700,
                ),
              ),
              if (exp.location != null) ...[
                pw.SizedBox(width: 8),
                pw.Text(
                  '|',
                  style: pw.TextStyle(
                    font: regularFont,
                    fontSize: 10,
                    color: PdfColors.grey500,
                  ),
                ),
                pw.SizedBox(width: 8),
                pw.Text(
                  exp.location!,
                  style: pw.TextStyle(
                    font: regularFont,
                    fontSize: 9,
                    color: PdfColors.grey600,
                  ),
                ),
              ],
            ],
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

          // Responsibilities
          if (exp.responsibilities.isNotEmpty)
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: exp.responsibilities
                  .map(
                    (resp) => pw.Padding(
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
                              resp,
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

  /// Build skills section with categories
  pw.Widget _buildSkills(
    List<Skill> skills,
    pw.Font font,
    PdfColor accentColor,
  ) {
    // Group skills by category
    final skillsByCategory = <String, List<Skill>>{};
    for (final skill in skills) {
      final category = skill.category ?? 'Other';
      skillsByCategory.putIfAbsent(category, () => []).add(skill);
    }

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: skillsByCategory.entries.map((entry) {
        return pw.Padding(
          padding: const pw.EdgeInsets.only(bottom: 8),
          child: pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.SizedBox(
                width: 100,
                child: pw.Text(
                  '${entry.key}:',
                  style: pw.TextStyle(
                    font: font,
                    fontSize: 10,
                    color: accentColor,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
              pw.Expanded(
                child: pw.Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: entry.value
                      .map(
                        (skill) => pw.Container(
                          padding: const pw.EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: pw.BoxDecoration(
                            color: accentColor.flatten(),
                            borderRadius: const pw.BorderRadius.all(
                              pw.Radius.circular(4),
                            ),
                          ),
                          child: pw.Text(
                            skill.level != null
                                ? '${skill.name} (${skill.level!.displayName})'
                                : skill.name,
                            style: pw.TextStyle(
                              font: font,
                              fontSize: 8,
                              color: PdfColors.white,
                            ),
                          ),
                        ),
                      )
                      .toList(),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  /// Build languages section
  pw.Widget _buildLanguages(
    List<Language> languages,
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
                  lang.name,
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
                    lang.proficiency.displayName,
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
