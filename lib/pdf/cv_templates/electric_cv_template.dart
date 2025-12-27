import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../../models/cv_data.dart';
import '../../models/template_style.dart';
import '../../models/template_customization.dart';
import '../../constants/pdf_constants.dart';

/// Electric CV Template - Modern Magazine-Style Design
///
/// Features:
/// - Bold asymmetric magazine layout
/// - Electric yellow (#FFFF00) accents on black backgrounds
/// - Overlapping photo banner with geometric shapes
/// - Professional icons using Unicode symbols
/// - Checkbox bullets for achievements
/// - Hexagonal accent shapes
/// - Modern brutalist typography
/// - High-contrast professional design
class ElectricCvTemplate {
  ElectricCvTemplate._();

  // Professional Electric color palette
  static const PdfColor _electricYellow = PdfColor.fromInt(0xFFFFFF00);
  static const PdfColor _electricYellowFaded = PdfColor.fromInt(0x26FFFF00); // 15% opacity
  static const PdfColor _black = PdfColors.black;
  static const PdfColor _mediumGray = PdfColor.fromInt(0xFF2D2D2D);
  static const PdfColor _mediumGrayFaded = PdfColor.fromInt(0x332D2D2D); // 20% opacity
  static const PdfColor _lightGray = PdfColor.fromInt(0xFF666666);
  static const PdfColor _white = PdfColors.white;

  // Professional Unicode icons
  static const String _iconEmail = '✉';
  static const String _iconPhone = '✆';
  static const String _iconLocation = '⚲';
  static const String _iconCheckbox = '☑';
  static const String _iconSquare = '■';
  static const String _iconHex = '⬢';
  static const String _iconStar = '★';
  static const String _iconArrow = '▸';

  /// Build the Electric CV PDF with stunning magazine-style design
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
    final fontFallback = [regularFont, boldFont, mediumFont];

    // Create profile image if provided
    pw.ImageProvider? profileImage;
    final showPhoto = customization?.showProfilePhoto ?? true;
    if (profileImageBytes != null && showPhoto) {
      try {
        profileImage = pw.MemoryImage(profileImageBytes);
      } catch (_) {
        // Ignore image loading errors
      }
    }

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfConstants.pageFormat,
        margin: pw.EdgeInsets.zero,
        theme: pw.ThemeData.withFont(
          base: regularFont,
          bold: boldFont,
          fontFallback: fontFallback,
        ),
        build: (context) => [
          // Hero header with overlapping photo banner
          _buildHeroHeader(cv, profileImage),

          // Main content area
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(horizontal: 48, vertical: 32),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // Two-column layout for professional summary and key skills
                _buildTopSection(cv),

                pw.SizedBox(height: 32),

                // Professional Experience
                if (cv.experiences.isNotEmpty) ...[
                  _buildSectionHeader('PROFESSIONAL EXPERIENCE', _iconHex),
                  pw.SizedBox(height: 16),
                  ...cv.experiences.map(_buildExperienceEntry),
                  pw.SizedBox(height: 32),
                ],

                // Education & Skills in two columns
                _buildEducationSkillsSection(cv),

                // Languages and Interests at bottom
                _buildBottomSection(cv),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Build stunning hero header with overlapping photo and geometric shapes
  static pw.Widget _buildHeroHeader(CvData cv, pw.ImageProvider? profileImage) {
    final contact = cv.contactDetails;
    final name = contact?.fullName ?? 'Your Name';
    final jobTitle = contact?.jobTitle ?? '';

    return pw.Stack(
      children: [
        // Black background banner
        pw.Container(
          width: double.infinity,
          height: 220,
          color: _black,
        ),

        // Electric yellow accent bar (top)
        pw.Container(
          width: double.infinity,
          height: 8,
          color: _electricYellow,
        ),

        // Electric yellow geometric accent (diagonal)
        pw.Positioned(
          right: 0,
          top: 0,
          child: pw.Transform.rotate(
            angle: 0.15,
            child: pw.Container(
              width: 300,
              height: 180,
              color: _electricYellowFaded,
            ),
          ),
        ),

        // Main content
        pw.Positioned.fill(
          child: pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              pw.SizedBox(width: 48),

              // Profile photo with hexagonal border
              if (profileImage != null) ...[
                pw.Container(
                  width: 140,
                  height: 140,
                  decoration: pw.BoxDecoration(
                    color: _electricYellow,
                    shape: pw.BoxShape.circle,
                  ),
                  padding: const pw.EdgeInsets.all(6),
                  child: pw.ClipOval(
                    child: pw.Container(
                      decoration: pw.BoxDecoration(
                        color: _mediumGray,
                        shape: pw.BoxShape.circle,
                      ),
                      child: pw.ClipOval(
                        child: pw.Image(profileImage, fit: pw.BoxFit.cover),
                      ),
                    ),
                  ),
                ),
                pw.SizedBox(width: 32),
              ],

              // Name and title
              pw.Expanded(
                child: pw.Column(
                  mainAxisAlignment: pw.MainAxisAlignment.center,
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    // Name in huge bold letters
                    pw.Text(
                      name.toUpperCase(),
                      style: pw.TextStyle(
                        fontSize: 42,
                        fontWeight: pw.FontWeight.bold,
                        color: _white,
                        letterSpacing: 2,
                        height: 1.1,
                      ),
                    ),

                    pw.SizedBox(height: 12),

                    // Electric yellow title bar
                    pw.Container(
                      decoration: pw.BoxDecoration(
                        color: _electricYellow,
                        borderRadius: pw.BorderRadius.circular(2),
                      ),
                      padding: const pw.EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: pw.Text(
                        jobTitle.toUpperCase(),
                        style: pw.TextStyle(
                          fontSize: 14,
                          fontWeight: pw.FontWeight.bold,
                          color: _black,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ),

                    pw.SizedBox(height: 20),

                    // Contact info with icons
                    pw.Row(
                      children: [
                        if (contact?.email != null) ...[
                          _buildContactIcon(_iconEmail, contact!.email!),
                          pw.SizedBox(width: 24),
                        ],
                        if (contact?.phone != null) ...[
                          _buildContactIcon(_iconPhone, contact!.phone!),
                          pw.SizedBox(width: 24),
                        ],
                        if (contact?.address != null) ...[
                          _buildContactIcon(_iconLocation, contact!.address!.split(',').first),
                        ],
                      ],
                    ),
                  ],
                ),
              ),

              pw.SizedBox(width: 48),
            ],
          ),
        ),
      ],
    );
  }

  /// Build contact info icon with text
  static pw.Widget _buildContactIcon(String icon, String text) {
    return pw.Row(
      children: [
        pw.Container(
          width: 24,
          height: 24,
          decoration: pw.BoxDecoration(
            color: _electricYellow,
            shape: pw.BoxShape.circle,
          ),
          child: pw.Center(
            child: pw.Text(
              icon,
              style: pw.TextStyle(
                fontSize: 12,
                color: _black,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          ),
        ),
        pw.SizedBox(width: 8),
        pw.Text(
          text,
          style: const pw.TextStyle(
            fontSize: 10,
            color: _white,
          ),
        ),
      ],
    );
  }

  /// Build top section with summary and key skills
  static pw.Widget _buildTopSection(CvData cv) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        // Professional Summary (2/3 width)
        if (cv.profile.isNotEmpty)
          pw.Expanded(
            flex: 2,
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                _buildSectionHeader('PROFESSIONAL SUMMARY', _iconStar),
                pw.SizedBox(height: 12),
                pw.Text(
                  cv.profile,
                  style: pw.TextStyle(
                    fontSize: 11,
                    lineSpacing: 1.6,
                    color: _lightGray,
                  ),
                  textAlign: pw.TextAlign.justify,
                ),
              ],
            ),
          ),

        if (cv.profile.isNotEmpty && cv.skills.isNotEmpty)
          pw.SizedBox(width: 32),

        // Key Skills (1/3 width)
        if (cv.skills.isNotEmpty)
          pw.Expanded(
            flex: 1,
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                _buildSectionHeader('KEY SKILLS', _iconArrow),
                pw.SizedBox(height: 12),
                ...cv.skills.take(6).map((skill) {
                  final skillName = skill.split(' - ').first;
                  return pw.Padding(
                    padding: const pw.EdgeInsets.only(bottom: 6),
                    child: pw.Row(
                      children: [
                        pw.Text(
                          _iconSquare,
                          style: const pw.TextStyle(
                            fontSize: 8,
                            color: _electricYellow,
                          ),
                        ),
                        pw.SizedBox(width: 8),
                        pw.Expanded(
                          child: pw.Text(
                            skillName,
                            style: pw.TextStyle(
                              fontSize: 10,
                              color: _lightGray,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
      ],
    );
  }

  /// Build section header with icon and yellow accent
  static pw.Widget _buildSectionHeader(String title, String icon) {
    return pw.Row(
      children: [
        pw.Text(
          icon,
          style: const pw.TextStyle(
            fontSize: 18,
            color: _electricYellow,
          ),
        ),
        pw.SizedBox(width: 12),
        pw.Text(
          title,
          style: pw.TextStyle(
            fontSize: 16,
            fontWeight: pw.FontWeight.bold,
            color: _black,
            letterSpacing: 1.5,
          ),
        ),
        pw.SizedBox(width: 12),
        pw.Expanded(
          child: pw.Container(
            height: 2,
            color: _electricYellow,
          ),
        ),
      ],
    );
  }

  /// Build experience entry with checkbox bullets
  static pw.Widget _buildExperienceEntry(Experience exp) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 24),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          // Title, company, and date in header row
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      exp.title.toUpperCase(),
                      style: pw.TextStyle(
                        fontSize: 13,
                        fontWeight: pw.FontWeight.bold,
                        color: _black,
                        letterSpacing: 0.8,
                      ),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Row(
                      children: [
                        pw.Container(
                          padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: pw.BoxDecoration(
                            color: _electricYellow,
                            borderRadius: pw.BorderRadius.circular(2),
                          ),
                          child: pw.Text(
                            exp.company,
                            style: pw.TextStyle(
                              fontSize: 10,
                              fontWeight: pw.FontWeight.bold,
                              color: _black,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              pw.Text(
                exp.dateRange,
                style: pw.TextStyle(
                  fontSize: 10,
                  color: _lightGray,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ],
          ),

          // Description
          if (exp.description != null && exp.description!.isNotEmpty) ...[
            pw.SizedBox(height: 8),
            pw.Text(
              exp.description!,
              style: pw.TextStyle(
                fontSize: 10,
                lineSpacing: 1.5,
                color: _lightGray,
              ),
            ),
          ],

          // Checkbox bullets for achievements
          if (exp.bullets.isNotEmpty) ...[
            pw.SizedBox(height: 8),
            ...exp.bullets.map((bullet) => pw.Padding(
                  padding: const pw.EdgeInsets.only(bottom: 6, left: 0),
                  child: pw.Row(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        _iconCheckbox,
                        style: const pw.TextStyle(
                          fontSize: 12,
                          color: _electricYellow,
                        ),
                      ),
                      pw.SizedBox(width: 10),
                      pw.Expanded(
                        child: pw.Text(
                          bullet,
                          style: pw.TextStyle(
                            fontSize: 10,
                            lineSpacing: 1.4,
                            color: _lightGray,
                          ),
                        ),
                      ),
                    ],
                  ),
                )),
          ],
        ],
      ),
    );
  }

  /// Build education and skills section in two columns
  static pw.Widget _buildEducationSkillsSection(CvData cv) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        // Education (60% width)
        if (cv.education.isNotEmpty)
          pw.Expanded(
            flex: 3,
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                _buildSectionHeader('EDUCATION', _iconHex),
                pw.SizedBox(height: 16),
                ...cv.education.map(_buildEducationEntry),
              ],
            ),
          ),

        if (cv.education.isNotEmpty && cv.skills.isNotEmpty)
          pw.SizedBox(width: 32),

        // Technical Skills (40% width)
        if (cv.skills.isNotEmpty)
          pw.Expanded(
            flex: 2,
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                _buildSectionHeader('TECHNICAL SKILLS', _iconStar),
                pw.SizedBox(height: 16),
                _buildSkillBars(cv.skills),
              ],
            ),
          ),
      ],
    );
  }

  /// Build education entry
  static pw.Widget _buildEducationEntry(Education edu) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 16),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  edu.degree,
                  style: pw.TextStyle(
                    fontSize: 12,
                    fontWeight: pw.FontWeight.bold,
                    color: _black,
                  ),
                ),
                pw.SizedBox(height: 4),
                pw.Text(
                  edu.institution,
                  style: pw.TextStyle(
                    fontSize: 10,
                    color: _lightGray,
                  ),
                ),
                if (edu.description != null && edu.description!.isNotEmpty) ...[
                  pw.SizedBox(height: 4),
                  pw.Text(
                    edu.description!,
                    style: pw.TextStyle(
                      fontSize: 9,
                      color: _lightGray,
                    ),
                  ),
                ],
              ],
            ),
          ),
          pw.SizedBox(width: 16),
          pw.Text(
            edu.dateRange,
            style: pw.TextStyle(
              fontSize: 10,
              color: _lightGray,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  /// Build skill bars with electric yellow fill
  static pw.Widget _buildSkillBars(List<String> skills) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: skills.take(8).map((skillString) {
        // Parse skill string (e.g., "JavaScript - Expert" or "Python - 90%")
        final parts = skillString.split(' - ');
        final skillName = parts.isNotEmpty ? parts[0] : skillString;
        double proficiency = 0.8; // Default 80%

        if (parts.length > 1) {
          final level = parts[1].toLowerCase();
          if (level.contains('%')) {
            proficiency = double.tryParse(level.replaceAll('%', '').trim()) ?? 80.0;
            proficiency = proficiency / 100.0;
          } else if (level.contains('expert')) {
            proficiency = 0.95;
          } else if (level.contains('advanced')) {
            proficiency = 0.85;
          } else if (level.contains('intermediate')) {
            proficiency = 0.70;
          } else if (level.contains('beginner')) {
            proficiency = 0.50;
          }
        }

        return pw.Container(
          margin: const pw.EdgeInsets.only(bottom: 12),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    skillName,
                    style: pw.TextStyle(
                      fontSize: 10,
                      fontWeight: pw.FontWeight.bold,
                      color: _black,
                    ),
                  ),
                  pw.Text(
                    '${(proficiency * 100).round()}%',
                    style: pw.TextStyle(
                      fontSize: 9,
                      color: _lightGray,
                    ),
                  ),
                ],
              ),
              pw.SizedBox(height: 4),
              pw.Container(
                width: double.infinity,
                height: 8,
                child: pw.Stack(
                  children: [
                    // Background bar
                    pw.Container(
                      width: double.infinity,
                      height: 8,
                      decoration: pw.BoxDecoration(
                        color: _mediumGrayFaded,
                        borderRadius: pw.BorderRadius.circular(4),
                      ),
                    ),
                    // Filled bar (electric yellow) - calculated width
                    pw.Container(
                      width: 150 * proficiency, // Max width ~150pt for skill bars
                      height: 8,
                      decoration: pw.BoxDecoration(
                        color: _electricYellow,
                        borderRadius: pw.BorderRadius.circular(4),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  /// Build bottom section with languages and interests
  static pw.Widget _buildBottomSection(CvData cv) {
    if (cv.languages.isEmpty && cv.interests.isEmpty) return pw.SizedBox();

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.SizedBox(height: 32),

        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            // Languages
            if (cv.languages.isNotEmpty)
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    _buildSectionHeader('LANGUAGES', _iconStar),
                    pw.SizedBox(height: 12),
                    pw.Wrap(
                      spacing: 12,
                      runSpacing: 8,
                      children: cv.languages.map((lang) => pw.Container(
                        padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: pw.BoxDecoration(
                          color: _electricYellow,
                          borderRadius: pw.BorderRadius.circular(2),
                        ),
                        child: pw.Text(
                          '${lang.language} • ${lang.level}',
                          style: pw.TextStyle(
                            fontSize: 9,
                            fontWeight: pw.FontWeight.bold,
                            color: _black,
                          ),
                        ),
                      )).toList(),
                    ),
                  ],
                ),
              ),

            if (cv.languages.isNotEmpty && cv.interests.isNotEmpty)
              pw.SizedBox(width: 32),

            // Interests
            if (cv.interests.isNotEmpty)
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    _buildSectionHeader('INTERESTS', _iconStar),
                    pw.SizedBox(height: 12),
                    pw.Wrap(
                      spacing: 12,
                      runSpacing: 8,
                      children: cv.interests.map((interest) => pw.Row(
                        mainAxisSize: pw.MainAxisSize.min,
                        children: [
                          pw.Text(
                            _iconSquare,
                            style: const pw.TextStyle(
                              fontSize: 8,
                              color: _electricYellow,
                            ),
                          ),
                          pw.SizedBox(width: 6),
                          pw.Text(
                            interest,
                            style: pw.TextStyle(
                              fontSize: 10,
                              color: _lightGray,
                            ),
                          ),
                        ],
                      )).toList(),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ],
    );
  }
}
