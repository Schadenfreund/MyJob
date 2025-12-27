import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../../models/cv_data.dart';
import '../../models/template_style.dart';
import '../../models/template_customization.dart';
import '../../constants/pdf_constants.dart';
import '../core/pdf_icons.dart';

/// Electric CV Template - Modern Magazine-Style Design with Dynamic Accent Colors
///
/// Features:
/// - Bold asymmetric magazine layout
/// - Dynamic accent colors (Electric Yellow, Cyan, Magenta, etc.)
/// - Professional typography with ASCII-safe icons
/// - High-contrast design
/// - Fully customizable accent color support
class ElectricCvTemplate {
  ElectricCvTemplate._();

  // Base color palette (primary colors that don't change)
  static const PdfColor _black = PdfColors.black;
  static const PdfColor _mediumGray = PdfColor.fromInt(0xFF2D2D2D);
  static const PdfColor _lightGray = PdfColor.fromInt(0xFF666666);
  static const PdfColor _darkGray = PdfColor.fromInt(0xFF1A1A1A);
  static const PdfColor _white = PdfColors.white;
  static const PdfColor _offWhite = PdfColor.fromInt(0xFFF5F5F5);

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

    // Dark mode flag
    final isDarkMode = style.isDarkMode;

    // Convert Flutter accent color to PDF color (this makes colors dynamic!)
    final accentColor = PdfColor.fromInt(style.accentColor.toARGB32());
    final accentFaded = PdfColor.fromHex('#${style.accentColor.toARGB32().toRadixString(16).substring(2)}26'); // 15% opacity

    // Dynamic colors based on dark mode
    final backgroundColor = isDarkMode ? _darkGray : _white;
    final textColor = isDarkMode ? _white : _black;
    final secondaryTextColor = isDarkMode ? _offWhite : _lightGray;
    final headerBackground = isDarkMode ? _black : _black;
    final pageBackground = isDarkMode ? _darkGray : _offWhite;

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
          _buildHeroHeader(cv, profileImage, accentColor, accentFaded, isDarkMode, headerBackground),

          // Main content area with dynamic background
          pw.Container(
            color: backgroundColor,
            padding: const pw.EdgeInsets.symmetric(horizontal: 56, vertical: 40),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // Two-column layout for professional summary and key skills
                _buildTopSection(cv, accentColor, textColor, secondaryTextColor),

                pw.SizedBox(height: 40),

                // Professional Experience
                if (cv.experiences.isNotEmpty) ...[
                  _buildSectionHeader('PROFESSIONAL EXPERIENCE', accentColor, textColor),
                  pw.SizedBox(height: 20),
                  ...cv.experiences.map((exp) => _buildExperienceEntry(exp, accentColor, textColor, secondaryTextColor)),
                  pw.SizedBox(height: 40),
                ],

                // Education & Skills in two columns
                _buildEducationSkillsSection(cv, accentColor, textColor, secondaryTextColor),

                pw.SizedBox(height: 40),

                // Languages and Interests at bottom
                _buildBottomSection(cv, accentColor, textColor, secondaryTextColor),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Build stunning hero header with overlapping photo and geometric shapes
  static pw.Widget _buildHeroHeader(
    CvData cv,
    pw.ImageProvider? profileImage,
    PdfColor accentColor,
    PdfColor accentFaded,
    bool isDarkMode,
    PdfColor headerBackground,
  ) {
    final contact = cv.contactDetails;
    final name = contact?.fullName ?? 'Your Name';
    final jobTitle = contact?.jobTitle ?? '';

    return pw.Stack(
      children: [
        // Header background banner (black in both modes for contrast)
        pw.Container(
          width: double.infinity,
          height: 220,
          color: headerBackground,
        ),

        // Accent bar (top) - DYNAMIC COLOR
        pw.Container(
          width: double.infinity,
          height: 8,
          color: accentColor,
        ),

        // Diagonal geometric accent shape - DYNAMIC COLOR
        pw.Positioned(
          right: 0,
          top: 0,
          child: pw.Transform.rotate(
            angle: 0.15,
            child: pw.Container(
              width: 300,
              height: 180,
              color: accentFaded,
            ),
          ),
        ),

        // Main content
        pw.Positioned.fill(
          child: pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              pw.SizedBox(width: 48),

              // Profile photo with accent border - DYNAMIC COLOR
              if (profileImage != null) ...[
                pw.Container(
                  width: 140,
                  height: 140,
                  decoration: pw.BoxDecoration(
                    color: accentColor,
                    shape: pw.BoxShape.circle,
                  ),
                  padding: const pw.EdgeInsets.all(6),
                  child: pw.ClipOval(
                    child: pw.Container(
                      decoration: const pw.BoxDecoration(
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

                    // Accent title bar - DYNAMIC COLOR
                    pw.Container(
                      decoration: pw.BoxDecoration(
                        color: accentColor,
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

                    // Contact info with accent circles - DYNAMIC COLOR
                    pw.Row(
                      children: [
                        if (contact?.email != null) ...[
                          _buildContactIcon(IconSet.electric.email, contact!.email!, accentColor),
                          pw.SizedBox(width: 24),
                        ],
                        if (contact?.phone != null) ...[
                          _buildContactIcon(IconSet.electric.phone, contact!.phone!, accentColor),
                          pw.SizedBox(width: 24),
                        ],
                        if (contact?.address != null) ...[
                          _buildContactIcon(IconSet.electric.location, contact!.address!.split(',').first, accentColor),
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

  /// Build contact info icon with text - DYNAMIC COLOR
  static pw.Widget _buildContactIcon(String icon, String text, PdfColor accentColor) {
    return pw.Row(
      children: [
        pw.Container(
          width: 24,
          height: 24,
          decoration: pw.BoxDecoration(
            color: accentColor,
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

  /// Build top section with summary and key skills - DYNAMIC COLOR
  static pw.Widget _buildTopSection(CvData cv, PdfColor accentColor, PdfColor textColor, PdfColor secondaryTextColor) {
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
                _buildSectionHeader('PROFESSIONAL SUMMARY', accentColor, textColor),
                pw.SizedBox(height: 12),
                pw.Text(
                  cv.profile,
                  style: pw.TextStyle(
                    fontSize: 11.5,
                    lineSpacing: 1.8,
                    color: secondaryTextColor,
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
                _buildSectionHeader('KEY SKILLS', accentColor, textColor),
                pw.SizedBox(height: 12),
                ...cv.skills.take(6).map((skill) {
                  final skillName = skill.split(' - ').first;
                  return pw.Padding(
                    padding: const pw.EdgeInsets.only(bottom: 6),
                    child: pw.Row(
                      children: [
                        PdfIcons.bulletIcon(
                          color: accentColor,
                          size: 6,
                          style: BulletStyle.circle,
                        ),
                        pw.SizedBox(width: 8),
                        pw.Expanded(
                          child: pw.Text(
                            skillName,
                            style: pw.TextStyle(
                              fontSize: 10.5,
                              color: secondaryTextColor,
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

  /// Build section header with accent line - DYNAMIC COLOR
  static pw.Widget _buildSectionHeader(String title, PdfColor accentColor, PdfColor textColor) {
    return pw.Row(
      children: [
        pw.Container(
          width: 8,
          height: 8,
          decoration: pw.BoxDecoration(
            color: accentColor,
            shape: pw.BoxShape.circle,
          ),
        ),
        pw.SizedBox(width: 12),
        pw.Text(
          title,
          style: pw.TextStyle(
            fontSize: 18,
            fontWeight: pw.FontWeight.bold,
            color: textColor,
            letterSpacing: 2.0,
          ),
        ),
        pw.SizedBox(width: 12),
        pw.Expanded(
          child: pw.Container(
            height: 2,
            color: accentColor,
          ),
        ),
      ],
    );
  }

  /// Build experience entry with accent badges - DYNAMIC COLOR
  static pw.Widget _buildExperienceEntry(Experience exp, PdfColor accentColor, PdfColor textColor, PdfColor secondaryTextColor) {
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
                        fontSize: 14,
                        fontWeight: pw.FontWeight.bold,
                        color: textColor,
                        letterSpacing: 1.0,
                      ),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Row(
                      children: [
                        pw.Container(
                          padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: pw.BoxDecoration(
                            color: accentColor,
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
                  fontSize: 10.5,
                  color: secondaryTextColor,
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
                fontSize: 10.5,
                lineSpacing: 1.6,
                color: secondaryTextColor,
              ),
            ),
          ],

          // Bullets with accent color
          if (exp.bullets.isNotEmpty) ...[
            pw.SizedBox(height: 8),
            ...exp.bullets.map((bullet) => pw.Padding(
                  padding: const pw.EdgeInsets.only(bottom: 6, left: 0),
                  child: pw.Row(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.only(top: 4),
                        child: PdfIcons.bulletIcon(
                          color: accentColor,
                          size: 6,
                          style: BulletStyle.diamond,
                        ),
                      ),
                      pw.SizedBox(width: 10),
                      pw.Expanded(
                        child: pw.Text(
                          bullet,
                          style: pw.TextStyle(
                            fontSize: 10.5,
                            lineSpacing: 1.5,
                            color: secondaryTextColor,
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

  /// Build education and skills section in two columns - DYNAMIC COLOR
  static pw.Widget _buildEducationSkillsSection(CvData cv, PdfColor accentColor, PdfColor textColor, PdfColor secondaryTextColor) {
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
                _buildSectionHeader('EDUCATION', accentColor, textColor),
                pw.SizedBox(height: 16),
                ...cv.education.map((edu) => _buildEducationEntry(edu, textColor, secondaryTextColor)),
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
                _buildSectionHeader('TECHNICAL SKILLS', accentColor, textColor),
                pw.SizedBox(height: 16),
                _buildSkillBars(cv.skills, accentColor, textColor, secondaryTextColor),
              ],
            ),
          ),
      ],
    );
  }

  /// Build education entry
  static pw.Widget _buildEducationEntry(Education edu, PdfColor textColor, PdfColor secondaryTextColor) {
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
                    fontSize: 12.5,
                    fontWeight: pw.FontWeight.bold,
                    color: textColor,
                  ),
                ),
                pw.SizedBox(height: 4),
                pw.Text(
                  edu.institution,
                  style: pw.TextStyle(
                    fontSize: 10.5,
                    color: secondaryTextColor,
                  ),
                ),
                if (edu.description != null && edu.description!.isNotEmpty) ...[
                  pw.SizedBox(height: 4),
                  pw.Text(
                    edu.description!,
                    style: pw.TextStyle(
                      fontSize: 9.5,
                      color: secondaryTextColor,
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
              fontSize: 10.5,
              color: secondaryTextColor,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  /// Build skill bars with accent fill - DYNAMIC COLOR
  static pw.Widget _buildSkillBars(List<String> skills, PdfColor accentColor, PdfColor textColor, PdfColor secondaryTextColor) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: skills.take(8).map((skillString) {
        // Parse skill string
        final parts = skillString.split(' - ');
        final skillName = parts.isNotEmpty ? parts[0] : skillString;
        double proficiency = 0.8;

        if (parts.length > 1) {
          final level = parts[1].toLowerCase();
          if (level.contains('%')) {
            proficiency = (double.tryParse(level.replaceAll('%', '').trim()) ?? 80.0) / 100.0;
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
                      fontSize: 10.5,
                      fontWeight: pw.FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                  pw.Text(
                    '${(proficiency * 100).round()}%',
                    style: pw.TextStyle(
                      fontSize: 9.5,
                      color: secondaryTextColor,
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
                        color: const PdfColor.fromInt(0x332D2D2D),
                        borderRadius: pw.BorderRadius.circular(4),
                      ),
                    ),
                    // Filled bar with accent color - DYNAMIC COLOR
                    pw.Container(
                      width: 150 * proficiency,
                      height: 8,
                      decoration: pw.BoxDecoration(
                        color: accentColor,
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

  /// Build bottom section with languages and interests - DYNAMIC COLOR
  static pw.Widget _buildBottomSection(CvData cv, PdfColor accentColor, PdfColor textColor, PdfColor secondaryTextColor) {
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
                    _buildSectionHeader('LANGUAGES', accentColor, textColor),
                    pw.SizedBox(height: 12),
                    pw.Wrap(
                      spacing: 12,
                      runSpacing: 8,
                      children: cv.languages.map((lang) => pw.Container(
                        padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: pw.BoxDecoration(
                          color: accentColor,
                          borderRadius: pw.BorderRadius.circular(2),
                        ),
                        child: pw.Text(
                          '${lang.language} - ${lang.level}',
                          style: pw.TextStyle(
                            fontSize: 9.5,
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
                    _buildSectionHeader('INTERESTS', accentColor, textColor),
                    pw.SizedBox(height: 12),
                    pw.Wrap(
                      spacing: 12,
                      runSpacing: 8,
                      children: cv.interests.map((interest) => pw.Row(
                        mainAxisSize: pw.MainAxisSize.min,
                        children: [
                          PdfIcons.bulletIcon(
                            color: accentColor,
                            size: 5,
                            style: BulletStyle.square,
                          ),
                          pw.SizedBox(width: 6),
                          pw.Text(
                            interest,
                            style: pw.TextStyle(
                              fontSize: 10.5,
                              color: secondaryTextColor,
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
