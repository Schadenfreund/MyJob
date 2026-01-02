import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../../models/cv_data.dart';
import '../../models/template_style.dart';
import '../../models/template_customization.dart';
import '../shared/pdf_styling.dart';
import '../shared/pdf_icons.dart';
import '../shared/base_pdf_template.dart';

/// Electric CV Template - Clean Professional Design
class ElectricCvTemplate extends BasePdfTemplate<CvData>
    with PdfTemplateHelpers {
  ElectricCvTemplate._();
  static final instance = ElectricCvTemplate._();

  @override
  TemplateInfo get info => const TemplateInfo(
        id: 'electric_cv',
        name: 'Electric',
        description: 'Modern, clean design with accent colors',
        category: 'cv',
        previewTags: ['modern', 'clean', 'professional'],
      );

  @override
  Future<Uint8List> build(
    CvData cv,
    TemplateStyle style, {
    TemplateCustomization? customization,
    Uint8List? profileImageBytes,
  }) async {
    final pdf = createDocument();
    final fonts = await loadFonts(style);
    final s = PdfStyling(style: style, customization: customization);
    final profileImage = getProfileImage(profileImageBytes);
    final showProfile = customization?.showProfilePhoto ?? true;

    pdf.addPage(
      pw.MultiPage(
        pageTheme: PdfPageThemes.fullBleed(
          regularFont: fonts.regular,
          boldFont: fonts.bold,
          mediumFont: fonts.medium,
          styling: s,
        ),
        build: (context) => [
          // Header
          _buildHeader(cv, showProfile ? profileImage : null, s),

          // Content
          pw.Padding(
            padding: s.pageMargins,
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // Summary
                if (cv.profile.isNotEmpty) ...[
                  _buildSection('About Me', s),
                  _buildSummaryContent(cv.profile, s),
                  pw.SizedBox(height: s.sectionGapMajor),
                ],

                // Skills
                if (cv.skills.isNotEmpty) ...[
                  _buildSection('Skills', s),
                  _buildSkillsContent(cv, s),
                  pw.SizedBox(height: s.sectionGapMajor),
                ],

                // Experience
                if (cv.experiences.isNotEmpty) ...[
                  _buildSection('Experience', s),
                  _buildExperienceContent(cv, s),
                  pw.SizedBox(height: s.sectionGapMajor),
                ],

                // Education
                if (cv.education.isNotEmpty) ...[
                  _buildSection('Education', s),
                  _buildEducationContent(cv, s),
                ],
              ],
            ),
          ),
        ],
      ),
    );

    return pdf.save();
  }

  // ===========================================================================
  // HEADER
  // ===========================================================================

  pw.Widget _buildHeader(
      CvData cv, pw.ImageProvider? profileImage, PdfStyling s) {
    final contact = cv.contactDetails;
    final name = contact?.fullName ?? 'Your Name';
    final title = contact?.jobTitle ?? '';

    return pw.Container(
      width: double.infinity,
      color: s.headerBackground,
      padding: pw.EdgeInsets.all(s.space12),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        children: [
          // Photo
          if (profileImage != null) ...[
            pw.Container(
              width: 90,
              height: 90,
              decoration: pw.BoxDecoration(
                shape: pw.BoxShape.circle,
                border: pw.Border.all(color: s.accent, width: 3),
              ),
              child: pw.ClipOval(
                  child: pw.Image(profileImage, fit: pw.BoxFit.cover)),
            ),
            pw.SizedBox(width: s.space6),
          ],

          // Name & Contact
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // Name - WHITE text on dark header
                pw.Text(
                  name.toUpperCase(),
                  style: pw.TextStyle(
                    fontSize: s.fontSizeH1,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.white, // Always white on dark header
                    letterSpacing: 2,
                  ),
                ),

                // Title
                if (title.isNotEmpty) ...[
                  pw.SizedBox(height: s.space2),
                  pw.Text(
                    title,
                    style: pw.TextStyle(
                      fontSize: s.fontSizeH4,
                      color: s.accent,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ],

                pw.SizedBox(height: s.space4),

                // Contact - WHITE text on dark header
                pw.Wrap(
                  spacing: s.space6,
                  runSpacing: s.space2,
                  children: [
                    if (contact?.email != null)
                      _buildContactText(contact!.email!),
                    if (contact?.phone != null)
                      _buildContactText(contact!.phone!),
                    if (contact?.address != null)
                      _buildContactText(contact!.address!),
                    if (contact?.linkedin != null)
                      _buildContactText(contact!.linkedin!),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildContactText(String text) {
    return pw.Text(
      text,
      style: pw.TextStyle(
        fontSize: 10,
        color: PdfColors.grey300, // Light gray on dark header
      ),
    );
  }

  // ===========================================================================
  // SECTION HEADER
  // ===========================================================================

  pw.Widget _buildSection(String title, PdfStyling s) {
    final displayTitle =
        s.customization.uppercaseHeaders ? title.toUpperCase() : title;

    return pw.Container(
      margin: pw.EdgeInsets.only(bottom: s.space4),
      child: pw.Row(
        children: [
          // Accent bar
          PdfIcons.accentBar(color: s.accent),
          pw.SizedBox(width: s.space2),
          // Title
          pw.Text(
            displayTitle,
            style: pw.TextStyle(
              fontSize: s.fontSizeH2,
              fontWeight: pw.FontWeight.bold,
              color: s.textPrimary,
            ),
          ),
          pw.SizedBox(width: s.space3),
          // Line
          pw.Expanded(child: pw.Container(height: 1, color: s.divider)),
        ],
      ),
    );
  }

  // ===========================================================================
  // SUMMARY
  // ===========================================================================

  pw.Widget _buildSummaryContent(String profile, PdfStyling s) {
    return pw.Container(
      padding: pw.EdgeInsets.all(s.space4),
      decoration: pw.BoxDecoration(
        color: s.cardBackground,
        border: pw.Border(left: pw.BorderSide(color: s.accent, width: 3)),
      ),
      child: pw.Text(
        profile,
        style: pw.TextStyle(
          fontSize: s.fontSizeBody,
          color: s.textSecondary,
          lineSpacing: 3,
          height: 1.4,
        ),
      ),
    );
  }

  // ===========================================================================
  // SKILLS
  // ===========================================================================

  pw.Widget _buildSkillsContent(CvData cv, PdfStyling s) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        // Skills tags
        pw.Wrap(
          spacing: s.space2,
          runSpacing: s.space2,
          children: cv.skills.map((skill) {
            final name = skill.split(' - ').first.split('(').first.trim();
            final isTop = cv.skills.indexOf(skill) < 3;

            return pw.Container(
              padding: pw.EdgeInsets.symmetric(
                  horizontal: s.space3, vertical: s.space2),
              decoration: pw.BoxDecoration(
                color: isTop ? s.accent : s.cardBackground,
                borderRadius: pw.BorderRadius.circular(4),
                border: isTop ? null : pw.Border.all(color: s.divider),
              ),
              child: pw.Text(
                name,
                style: pw.TextStyle(
                  fontSize: s.fontSizeSmall,
                  fontWeight: isTop ? pw.FontWeight.bold : pw.FontWeight.normal,
                  color: isTop ? s.textOnAccent : s.textPrimary,
                ),
              ),
            );
          }).toList(),
        ),

        // Languages
        if (cv.languages.isNotEmpty) ...[
          pw.SizedBox(height: s.space4),
          pw.RichText(
            text: pw.TextSpan(
              children: [
                pw.TextSpan(
                  text: 'Languages: ',
                  style: pw.TextStyle(
                    fontSize: s.fontSizeSmall,
                    fontWeight: pw.FontWeight.bold,
                    color: s.textPrimary,
                  ),
                ),
                pw.TextSpan(
                  text: cv.languages
                      .map((l) => '${l.language} (${l.level})')
                      .join(' • '),
                  style: pw.TextStyle(
                      fontSize: s.fontSizeSmall, color: s.textSecondary),
                ),
              ],
            ),
          ),
        ],

        // Interests
        if (cv.interests.isNotEmpty) ...[
          pw.SizedBox(height: s.space2),
          pw.RichText(
            text: pw.TextSpan(
              children: [
                pw.TextSpan(
                  text: 'Interests: ',
                  style: pw.TextStyle(
                    fontSize: s.fontSizeSmall,
                    fontWeight: pw.FontWeight.bold,
                    color: s.textPrimary,
                  ),
                ),
                pw.TextSpan(
                  text: cv.interests.join(' • '),
                  style: pw.TextStyle(
                      fontSize: s.fontSizeSmall, color: s.textSecondary),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  // ===========================================================================
  // EXPERIENCE
  // ===========================================================================

  pw.Widget _buildExperienceContent(CvData cv, PdfStyling s) {
    return pw.Column(
      children: cv.experiences.asMap().entries.map((entry) {
        final exp = entry.value;
        final isLast = entry.key == cv.experiences.length - 1;

        return pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            // Timeline
            pw.Column(
              children: [
                PdfIcons.timelineDot(color: s.accent, size: 8),
                if (!isLast)
                  pw.Container(width: 1, height: 60, color: s.divider),
              ],
            ),
            pw.SizedBox(width: s.space3),

            // Content
            pw.Expanded(
              child: pw.Container(
                margin: pw.EdgeInsets.only(bottom: s.space4),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    // Header row
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Expanded(
                          child: pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              pw.Text(
                                exp.title,
                                style: pw.TextStyle(
                                  fontSize: s.fontSizeBody,
                                  fontWeight: pw.FontWeight.bold,
                                  color: s.textPrimary,
                                ),
                              ),
                              pw.Text(
                                exp.company,
                                style: pw.TextStyle(
                                    fontSize: s.fontSizeSmall, color: s.accent),
                              ),
                            ],
                          ),
                        ),
                        pw.Text(
                          exp.dateRange,
                          style: pw.TextStyle(
                              fontSize: s.fontSizeSmall, color: s.textMuted),
                        ),
                      ],
                    ),

                    // Bullets
                    if (exp.bullets.isNotEmpty) ...[
                      pw.SizedBox(height: s.space2),
                      ...exp.bullets.map((b) => pw.Padding(
                            padding: pw.EdgeInsets.only(bottom: 2),
                            child: pw.Row(
                              crossAxisAlignment: pw.CrossAxisAlignment.start,
                              children: [
                                pw.Padding(
                                  padding: const pw.EdgeInsets.only(top: 5),
                                  child:
                                      PdfIcons.bullet(color: s.accent, size: 4),
                                ),
                                pw.SizedBox(width: s.space2),
                                pw.Expanded(
                                  child: pw.Text(
                                    b,
                                    style: pw.TextStyle(
                                      fontSize: s.fontSizeSmall,
                                      color: s.textSecondary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          )),
                    ],
                  ],
                ),
              ),
            ),
          ],
        );
      }).toList(),
    );
  }

  // ===========================================================================
  // EDUCATION
  // ===========================================================================

  pw.Widget _buildEducationContent(CvData cv, PdfStyling s) {
    return pw.Column(
      children: cv.education.map((edu) {
        return pw.Container(
          margin: pw.EdgeInsets.only(bottom: s.space3),
          padding: pw.EdgeInsets.all(s.space3),
          decoration: pw.BoxDecoration(
            color: s.cardBackground,
            border: pw.Border(left: pw.BorderSide(color: s.accent, width: 2)),
          ),
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
                        fontSize: s.fontSizeBody,
                        fontWeight: pw.FontWeight.bold,
                        color: s.textPrimary,
                      ),
                    ),
                    pw.Text(
                      edu.institution,
                      style: pw.TextStyle(
                          fontSize: s.fontSizeSmall, color: s.accent),
                    ),
                  ],
                ),
              ),
              pw.Text(
                edu.dateRange,
                style:
                    pw.TextStyle(fontSize: s.fontSizeSmall, color: s.textMuted),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
