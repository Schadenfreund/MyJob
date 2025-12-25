import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../../models/cv_data.dart';
import '../../models/template_style.dart';
import '../../constants/pdf_constants.dart';

/// Modern CV template - Colorful with accent elements and two-column layout
class ModernCvTemplate {
  ModernCvTemplate._();

  static void build(pw.Document pdf, CvData cv, TemplateStyle style) {
    final primaryColor = PdfColor.fromInt(style.primaryColor.toARGB32());
    final accentColor = PdfColor.fromInt(style.accentColor.toARGB32());

    pdf.addPage(
      pw.Page(
        pageFormat: PdfConstants.pageFormat,
        margin: pw.EdgeInsets.zero,
        build: (context) => pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            // Sidebar
            pw.Container(
              width: PdfConstants.pageFormat.width * PdfConstants.sidebarRatio,
              height: PdfConstants.pageFormat.height,
              color: primaryColor,
              padding: const pw.EdgeInsets.all(20),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  _buildSidebarHeader(cv, accentColor),
                  pw.SizedBox(height: 24),
                  _buildSidebarContact(cv),
                  pw.SizedBox(height: 24),
                  if (cv.skills.isNotEmpty) ...[
                    _buildSidebarSection(
                        'SKILLS', _buildSkillBars(cv, accentColor)),
                    pw.SizedBox(height: 24),
                  ],
                  if (cv.languages.isNotEmpty) ...[
                    _buildSidebarSection(
                        'LANGUAGES', _buildLanguagesList(cv, accentColor)),
                    pw.SizedBox(height: 24),
                  ],
                  if (cv.interests.isNotEmpty)
                    _buildSidebarSection('INTERESTS', _buildInterestsList(cv)),
                ],
              ),
            ),
            // Main content
            pw.Expanded(
              child: pw.Container(
                padding: const pw.EdgeInsets.all(30),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    if (cv.profile.isNotEmpty) ...[
                      _buildMainSection(
                          'PROFILE', _buildProfile(cv), primaryColor),
                      pw.SizedBox(height: 20),
                    ],
                    if (cv.experiences.isNotEmpty) ...[
                      _buildMainSection(
                        'EXPERIENCE',
                        _buildExperiences(cv, primaryColor, accentColor),
                        primaryColor,
                      ),
                      pw.SizedBox(height: 20),
                    ],
                    if (cv.education.isNotEmpty)
                      _buildMainSection(
                        'EDUCATION',
                        _buildEducation(cv, primaryColor),
                        primaryColor,
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static pw.Widget _buildSidebarHeader(CvData cv, PdfColor accentColor) {
    final contact = cv.contactDetails;
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Container(
          width: 80,
          height: 80,
          decoration: pw.BoxDecoration(
            color: accentColor,
            shape: pw.BoxShape.circle,
          ),
          child: pw.Center(
            child: pw.Text(
              contact?.fullName.isNotEmpty == true
                  ? contact!.fullName[0].toUpperCase()
                  : '?',
              style: pw.TextStyle(
                fontSize: 36,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.white,
              ),
            ),
          ),
        ),
        pw.SizedBox(height: 16),
        pw.Text(
          contact?.fullName ?? 'Name',
          style: pw.TextStyle(
            fontSize: 20,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.white,
          ),
        ),
      ],
    );
  }

  static pw.Widget _buildSidebarContact(CvData cv) {
    final contact = cv.contactDetails;
    if (contact == null) return pw.SizedBox();

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'CONTACT',
          style: pw.TextStyle(
            fontSize: 12,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.white,
            letterSpacing: 1,
          ),
        ),
        pw.SizedBox(height: 8),
        pw.Divider(color: PdfColors.white, thickness: 0.5),
        pw.SizedBox(height: 8),
        if (contact.email != null) _buildContactRow('Email', contact.email!),
        if (contact.phone != null) _buildContactRow('Phone', contact.phone!),
        if (contact.address != null)
          _buildContactRow('Address', contact.address!),
        if (contact.linkedin != null)
          _buildContactRow('LinkedIn', contact.linkedin!),
      ],
    );
  }

  static pw.Widget _buildContactRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 6),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            label,
            style: const pw.TextStyle(
              fontSize: 8,
              color: PdfColor.fromInt(0xAAFFFFFF),
            ),
          ),
          pw.Text(
            value,
            style: const pw.TextStyle(
              fontSize: 9,
              color: PdfColors.white,
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildSidebarSection(String title, pw.Widget content) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          title,
          style: pw.TextStyle(
            fontSize: 12,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.white,
            letterSpacing: 1,
          ),
        ),
        pw.SizedBox(height: 8),
        pw.Divider(color: PdfColors.white, thickness: 0.5),
        pw.SizedBox(height: 8),
        content,
      ],
    );
  }

  static pw.Widget _buildSkillBars(CvData cv, PdfColor accentColor) {
    return pw.Column(
      children: cv.skills.take(6).map((skill) {
        return pw.Padding(
          padding: const pw.EdgeInsets.only(bottom: 6),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                skill,
                style: const pw.TextStyle(
                  fontSize: 9,
                  color: PdfColors.white,
                ),
              ),
              pw.SizedBox(height: 2),
              pw.Container(
                height: PdfConstants.skillBarHeight,
                decoration: pw.BoxDecoration(
                  color: const PdfColor.fromInt(0x4DFFFFFF),
                  borderRadius:
                      pw.BorderRadius.circular(PdfConstants.skillBarRadius),
                ),
                child: pw.Row(
                  children: [
                    pw.Expanded(
                      flex: 85,
                      child: pw.Container(
                        decoration: pw.BoxDecoration(
                          color: accentColor,
                          borderRadius: pw.BorderRadius.circular(
                              PdfConstants.skillBarRadius),
                        ),
                      ),
                    ),
                    pw.Expanded(flex: 15, child: pw.SizedBox()),
                  ],
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  static pw.Widget _buildLanguagesList(CvData cv, PdfColor accentColor) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: cv.languages.map((lang) {
        return pw.Padding(
          padding: const pw.EdgeInsets.only(bottom: 4),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                lang.language,
                style: const pw.TextStyle(
                  fontSize: 9,
                  color: PdfColors.white,
                ),
              ),
              pw.Container(
                padding:
                    const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: pw.BoxDecoration(
                  color: accentColor,
                  borderRadius: pw.BorderRadius.circular(4),
                ),
                child: pw.Text(
                  lang.level,
                  style: const pw.TextStyle(
                    fontSize: 7,
                    color: PdfColors.white,
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  static pw.Widget _buildInterestsList(CvData cv) {
    return pw.Wrap(
      spacing: 4,
      runSpacing: 4,
      children: cv.interests.map((interest) {
        return pw.Container(
          padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 3),
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: PdfColors.white, width: 0.5),
            borderRadius: pw.BorderRadius.circular(4),
          ),
          child: pw.Text(
            interest,
            style: const pw.TextStyle(
              fontSize: 8,
              color: PdfColors.white,
            ),
          ),
        );
      }).toList(),
    );
  }

  static pw.Widget _buildMainSection(
    String title,
    pw.Widget content,
    PdfColor primaryColor,
  ) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Row(
          children: [
            pw.Container(
              width: 4,
              height: 20,
              color: primaryColor,
            ),
            pw.SizedBox(width: 8),
            pw.Text(
              title,
              style: pw.TextStyle(
                fontSize: 14,
                fontWeight: pw.FontWeight.bold,
                color: PdfConstants.modernText,
                letterSpacing: 1,
              ),
            ),
          ],
        ),
        pw.SizedBox(height: 12),
        content,
      ],
    );
  }

  static pw.Widget _buildProfile(CvData cv) {
    return pw.Text(
      cv.profile,
      style: const pw.TextStyle(
        fontSize: 10,
        color: PdfConstants.modernText,
        lineSpacing: 2,
      ),
    );
  }

  static pw.Widget _buildExperiences(
    CvData cv,
    PdfColor primaryColor,
    PdfColor accentColor,
  ) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: cv.experiences.map((exp) {
        return pw.Padding(
          padding: const pw.EdgeInsets.only(bottom: 16),
          child: pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Container(
                width: 8,
                height: 8,
                margin: const pw.EdgeInsets.only(top: 4, right: 12),
                decoration: pw.BoxDecoration(
                  color: accentColor,
                  shape: pw.BoxShape.circle,
                ),
              ),
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text(
                          exp.title,
                          style: pw.TextStyle(
                            fontSize: 11,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfConstants.modernText,
                          ),
                        ),
                        pw.Text(
                          exp.dateRange,
                          style: const pw.TextStyle(
                            fontSize: 9,
                            color: PdfConstants.modernMuted,
                          ),
                        ),
                      ],
                    ),
                    pw.Text(
                      exp.company,
                      style: pw.TextStyle(
                        fontSize: 10,
                        color: primaryColor,
                      ),
                    ),
                    if (exp.bullets.isNotEmpty) ...[
                      pw.SizedBox(height: 6),
                      ...exp.bullets.map(
                        (bullet) => pw.Padding(
                          padding: const pw.EdgeInsets.only(bottom: 2),
                          child: pw.Row(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              pw.Text(
                                '• ',
                                style: const pw.TextStyle(
                                  fontSize: 9,
                                  color: PdfConstants.modernText,
                                ),
                              ),
                              pw.Expanded(
                                child: pw.Text(
                                  bullet,
                                  style: const pw.TextStyle(
                                    fontSize: 9,
                                    color: PdfConstants.modernText,
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
              ),
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
          padding: const pw.EdgeInsets.only(bottom: 10),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      edu.degree,
                      style: pw.TextStyle(
                        fontSize: 11,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfConstants.modernText,
                      ),
                    ),
                    pw.Text(
                      edu.institution,
                      style: pw.TextStyle(
                        fontSize: 10,
                        color: primaryColor,
                      ),
                    ),
                  ],
                ),
              ),
              pw.Text(
                edu.dateRange,
                style: const pw.TextStyle(
                  fontSize: 9,
                  color: PdfConstants.modernMuted,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
