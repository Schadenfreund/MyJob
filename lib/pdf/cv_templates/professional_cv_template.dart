import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../../models/cv_data.dart';
import '../../models/template_style.dart';
import '../../constants/pdf_constants.dart';

/// Professional CV template - Clean and minimalist design
class ProfessionalCvTemplate {
  ProfessionalCvTemplate._();

  static void build(pw.Document pdf, CvData cv, TemplateStyle style) {
    final primaryColor = PdfColor.fromInt(style.primaryColor.toARGB32());
    final accentColor = PdfColor.fromInt(style.accentColor.toARGB32());

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfConstants.pageFormat,
        margin: const pw.EdgeInsets.only(
          top: PdfConstants.marginTop,
          bottom: PdfConstants.marginBottom,
          left: PdfConstants.marginLeft,
          right: PdfConstants.marginRight,
        ),
        build: (context) => [
          _buildHeader(cv, primaryColor, accentColor),
          pw.SizedBox(height: PdfConstants.sectionSpacing),
          if (cv.profile.isNotEmpty) ...[
            _buildSection('Profile', _buildProfile(cv), primaryColor),
            pw.SizedBox(height: PdfConstants.sectionSpacing),
          ],
          if (cv.experiences.isNotEmpty) ...[
            _buildSection(
              'Professional Experience',
              _buildExperiences(cv, primaryColor),
              primaryColor,
            ),
            pw.SizedBox(height: PdfConstants.sectionSpacing),
          ],
          if (cv.education.isNotEmpty) ...[
            _buildSection(
              'Education',
              _buildEducation(cv, primaryColor),
              primaryColor,
            ),
            pw.SizedBox(height: PdfConstants.sectionSpacing),
          ],
          if (cv.skills.isNotEmpty) ...[
            _buildSection(
                'Skills', _buildSkills(cv, accentColor), primaryColor),
            pw.SizedBox(height: PdfConstants.sectionSpacing),
          ],
          if (cv.languages.isNotEmpty) ...[
            _buildSection(
              'Languages',
              _buildLanguages(cv),
              primaryColor,
            ),
            pw.SizedBox(height: PdfConstants.sectionSpacing),
          ],
          if (cv.interests.isNotEmpty)
            _buildSection(
              'Interests',
              _buildInterests(cv),
              primaryColor,
            ),
        ],
      ),
    );
  }

  static pw.Widget _buildHeader(
    CvData cv,
    PdfColor primaryColor,
    PdfColor accentColor,
  ) {
    final contact = cv.contactDetails;
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          contact?.fullName ?? 'Name',
          style: pw.TextStyle(
            fontSize: PdfConstants.fontSizeName,
            fontWeight: pw.FontWeight.bold,
            color: primaryColor,
          ),
        ),
        pw.SizedBox(height: 8),
        pw.Divider(color: accentColor, thickness: 2),
        pw.SizedBox(height: 8),
        if (contact != null)
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.start,
            children: [
              if (contact.email != null)
                _buildContactItem(
                    contact.email!, PdfConstants.professionalMuted),
              if (contact.phone != null) ...[
                pw.SizedBox(width: 16),
                _buildContactItem(
                    contact.phone!, PdfConstants.professionalMuted),
              ],
              if (contact.address != null) ...[
                pw.SizedBox(width: 16),
                _buildContactItem(
                    contact.address!, PdfConstants.professionalMuted),
              ],
            ],
          ),
      ],
    );
  }

  static pw.Widget _buildContactItem(String text, PdfColor color) {
    return pw.Text(
      text,
      style: pw.TextStyle(
        fontSize: PdfConstants.fontSizeSmall,
        color: color,
      ),
    );
  }

  static pw.Widget _buildSection(
    String title,
    pw.Widget content,
    PdfColor primaryColor,
  ) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          title.toUpperCase(),
          style: pw.TextStyle(
            fontSize: PdfConstants.fontSizeHeading,
            fontWeight: pw.FontWeight.bold,
            color: primaryColor,
            letterSpacing: 1,
          ),
        ),
        pw.SizedBox(height: 4),
        pw.Divider(color: PdfConstants.professionalDivider, thickness: 0.5),
        pw.SizedBox(height: 8),
        content,
      ],
    );
  }

  static pw.Widget _buildProfile(CvData cv) {
    return pw.Text(
      cv.profile,
      style: const pw.TextStyle(
        fontSize: PdfConstants.fontSizeBody,
        color: PdfConstants.professionalText,
        lineSpacing: 2,
      ),
    );
  }

  static pw.Widget _buildExperiences(CvData cv, PdfColor primaryColor) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: cv.experiences.map((exp) {
        return pw.Padding(
          padding: const pw.EdgeInsets.only(bottom: 12),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Expanded(
                    child: pw.Text(
                      exp.title,
                      style: pw.TextStyle(
                        fontSize: PdfConstants.fontSizeSubheading,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfConstants.professionalText,
                      ),
                    ),
                  ),
                  pw.Text(
                    exp.dateRange,
                    style: const pw.TextStyle(
                      fontSize: PdfConstants.fontSizeSmall,
                      color: PdfConstants.professionalMuted,
                    ),
                  ),
                ],
              ),
              pw.Text(
                exp.company,
                style: pw.TextStyle(
                  fontSize: PdfConstants.fontSizeBody,
                  color: primaryColor,
                  fontStyle: pw.FontStyle.italic,
                ),
              ),
              if (exp.description != null) ...[
                pw.SizedBox(height: 4),
                pw.Text(
                  exp.description!,
                  style: const pw.TextStyle(
                    fontSize: PdfConstants.fontSizeBody,
                    color: PdfConstants.professionalText,
                  ),
                ),
              ],
              if (exp.bullets.isNotEmpty) ...[
                pw.SizedBox(height: 4),
                ...exp.bullets.map(
                  (bullet) => pw.Padding(
                    padding: const pw.EdgeInsets.only(left: 12, top: 2),
                    child: pw.Row(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          '• ',
                          style: const pw.TextStyle(
                            fontSize: PdfConstants.fontSizeBody,
                            color: PdfConstants.professionalText,
                          ),
                        ),
                        pw.Expanded(
                          child: pw.Text(
                            bullet,
                            style: const pw.TextStyle(
                              fontSize: PdfConstants.fontSizeBody,
                              color: PdfConstants.professionalText,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        );
      }).toList(),
    );
  }

  static pw.Widget _buildEducation(CvData cv, PdfColor primaryColor) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: cv.education.map((edu) {
        return pw.Padding(
          padding: const pw.EdgeInsets.only(bottom: 8),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      edu.degree,
                      style: pw.TextStyle(
                        fontSize: PdfConstants.fontSizeSubheading,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfConstants.professionalText,
                      ),
                    ),
                    pw.Text(
                      edu.institution,
                      style: pw.TextStyle(
                        fontSize: PdfConstants.fontSizeBody,
                        color: primaryColor,
                      ),
                    ),
                  ],
                ),
              ),
              pw.Text(
                edu.dateRange,
                style: const pw.TextStyle(
                  fontSize: PdfConstants.fontSizeSmall,
                  color: PdfConstants.professionalMuted,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  static pw.Widget _buildSkills(CvData cv, PdfColor accentColor) {
    return pw.Wrap(
      spacing: 8,
      runSpacing: 4,
      children: cv.skills.map((skill) {
        return pw.Container(
          padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: pw.BoxDecoration(
            color: const PdfColor.fromInt(0x1A3498DB),
            borderRadius: pw.BorderRadius.circular(4),
          ),
          child: pw.Text(
            skill,
            style: const pw.TextStyle(
              fontSize: PdfConstants.fontSizeSmall,
              color: PdfConstants.professionalText,
            ),
          ),
        );
      }).toList(),
    );
  }

  static pw.Widget _buildLanguages(CvData cv) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: cv.languages.map((lang) {
        return pw.Padding(
          padding: const pw.EdgeInsets.only(bottom: 4),
          child: pw.Row(
            children: [
              pw.Text(
                '${lang.language}: ',
                style: pw.TextStyle(
                  fontSize: PdfConstants.fontSizeBody,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfConstants.professionalText,
                ),
              ),
              pw.Text(
                lang.level,
                style: const pw.TextStyle(
                  fontSize: PdfConstants.fontSizeBody,
                  color: PdfConstants.professionalMuted,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  static pw.Widget _buildInterests(CvData cv) {
    return pw.Text(
      cv.interests.join(' • '),
      style: const pw.TextStyle(
        fontSize: PdfConstants.fontSizeBody,
        color: PdfConstants.professionalText,
      ),
    );
  }
}
