import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../../models/cv_data.dart';
import '../../models/template_style.dart';
import '../../models/template_customization.dart';
import '../../constants/pdf_constants.dart';
import '../../services/pdf_special_characters.dart';

/// Electric CV Template - Professional Modern Design
///
/// Features:
/// - Bold asymmetric magazine layout with professional design
/// - Dynamic accent colors with proper contrast (visible elements)
/// - Professional typography with optimal hierarchy
/// - ASCII-safe characters (Helvetica compatible)
/// - Clean, DRY, centralized code
/// - Proper page breaks and spacing
/// - Visual interest with icons, badges, and geometric elements
/// - Skill percentage parsing from multiple formats
class ElectricCvTemplate {
  ElectricCvTemplate._();

  // Color palette - professional and accessible
  static const PdfColor _black = PdfColors.black;
  static const PdfColor _darkGray = PdfColor.fromInt(0xFF1A1A1A);
  static const PdfColor _mediumGray = PdfColor.fromInt(0xFF4A4A4A);
  static const PdfColor _lightGray = PdfColor.fromInt(0xFF757575);
  static const PdfColor _paleGray = PdfColor.fromInt(0xFFE8E8E8);
  static const PdfColor _white = PdfColors.white;
  static const PdfColor _offWhite = PdfColor.fromInt(0xFFF8F8F8);

  /// Build the Electric CV PDF with professional magazine-style design
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
    // Initialize special characters service (ASCII-safe)
    final chars = PdfSpecialCharacters();
    PdfSpecialCharacters.enableAsciiFallback();

    // Theme configuration
    final isDarkMode = style.isDarkMode;
    final accentColor = PdfColor.fromInt(style.accentColor.toARGB32());

    // Create color variations with BETTER contrast
    final accentDark = _darkenColor(accentColor, 0.2); // Subtle darkening
    final accentLight =
        _adjustBrightness(accentColor, 1.3); // Visible but light
    final accentPale = _mixWithWhite(accentColor, 0.9); // Very pale background

    // Dynamic theme colors
    final bgColor = isDarkMode ? _darkGray : _white;
    final textColor = isDarkMode ? _white : _black;
    final textSecondary = isDarkMode ? _offWhite : _mediumGray;
    final textTertiary = isDarkMode ? _paleGray : _lightGray;
    final headerBg = isDarkMode ? _black : _black;

    // Profile image setup
    pw.ImageProvider? profileImage;
    if (profileImageBytes != null &&
        (customization?.showProfilePhoto ?? true)) {
      try {
        profileImage = pw.MemoryImage(profileImageBytes);
      } catch (_) {}
    }

    // Build the PDF with custom fonts
    pdf.addPage(
      pw.MultiPage(
        pageTheme: pw.PageTheme(
          pageFormat: PdfConstants.pageFormat,
          margin: pw.EdgeInsets.zero,
          theme: pw.ThemeData.withFont(
            base: regularFont,
            bold: boldFont,
            fontFallback: [
              regularFont,
              boldFont,
              mediumFont,
            ],
          ),
          buildBackground: (context) => pw.FullPage(
            ignoreMargins: true,
            child: pw.Container(color: bgColor),
          ),
        ),
        build: (context) => [
          // HEADER SECTION - Eye-catching hero
          _buildHeader(
            cv,
            profileImage,
            accentColor,
            accentDark,
            accentLight,
            headerBg,
            chars,
          ),

          // MAIN CONTENT with optimal spacing
          pw.Padding(
            padding: const pw.EdgeInsets.fromLTRB(48, 36, 48, 48),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // Summary + Key Skills (two-column)
                if (cv.profile.isNotEmpty || cv.skills.isNotEmpty)
                  _buildSummaryAndSkills(
                    cv,
                    accentColor,
                    accentDark,
                    accentPale,
                    textColor,
                    textSecondary,
                    chars,
                  ),

                if (cv.profile.isNotEmpty || cv.skills.isNotEmpty)
                  pw.SizedBox(height: 40),

                // Professional Experience
                if (cv.experiences.isNotEmpty) ...[
                  _buildSectionHeader(
                    'PROFESSIONAL EXPERIENCE',
                    accentColor,
                    accentDark,
                    textColor,
                  ),
                  pw.SizedBox(height: 20),
                  ...cv.experiences.asMap().entries.map((entry) {
                    return pw.Column(
                      children: [
                        _buildExperienceItem(
                          entry.value,
                          accentColor,
                          accentLight,
                          accentPale,
                          textColor,
                          textSecondary,
                          textTertiary,
                          chars,
                        ),
                        if (entry.key < cv.experiences.length - 1)
                          pw.SizedBox(height: 28),
                      ],
                    );
                  }),
                  pw.SizedBox(height: 40),
                ],

                // Education + Skills (two-column)
                if (cv.education.isNotEmpty || cv.skills.isNotEmpty)
                  _buildEducationAndSkills(
                    cv,
                    accentColor,
                    accentDark,
                    accentLight,
                    accentPale,
                    textColor,
                    textSecondary,
                    textTertiary,
                    chars,
                  ),

                if (cv.education.isNotEmpty || cv.skills.isNotEmpty)
                  pw.SizedBox(height: 40),

                // Languages + Interests
                if (cv.languages.isNotEmpty || cv.interests.isNotEmpty)
                  _buildLanguagesAndInterests(
                    cv,
                    accentColor,
                    accentDark,
                    textColor,
                    textSecondary,
                    chars,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================================
  // COLOR UTILITIES - Professional color manipulation
  // ============================================================================

  /// Darken a color by reducing brightness
  static PdfColor _darkenColor(PdfColor color, double amount) {
    return PdfColor(
      color.red * (1 - amount),
      color.green * (1 - amount),
      color.blue * (1 - amount),
    );
  }

  /// Adjust brightness while preserving hue
  static PdfColor _adjustBrightness(PdfColor color, double factor) {
    return PdfColor(
      (color.red * factor).clamp(0.0, 1.0),
      (color.green * factor).clamp(0.0, 1.0),
      (color.blue * factor).clamp(0.0, 1.0),
    );
  }

  /// Mix color with white for pale variations
  static PdfColor _mixWithWhite(PdfColor color, double whiteness) {
    return PdfColor(
      color.red + (1 - color.red) * whiteness,
      color.green + (1 - color.green) * whiteness,
      color.blue + (1 - color.blue) * whiteness,
    );
  }

  // ============================================================================
  // HEADER SECTION - Hero design
  // ============================================================================

  static pw.Widget _buildHeader(
    CvData cv,
    pw.ImageProvider? profileImage,
    PdfColor accentColor,
    PdfColor accentDark,
    PdfColor accentLight,
    PdfColor headerBg,
    PdfSpecialCharacters chars,
  ) {
    final contact = cv.contactDetails;
    final name = contact?.fullName ?? 'Your Name';
    final title = contact?.jobTitle ?? '';

    return pw.Stack(
      children: [
        // Background
        pw.Container(
          width: double.infinity,
          height: 200,
          color: headerBg,
        ),

        // Accent bar - STRONG and visible
        pw.Container(
          width: double.infinity,
          height: 12,
          color: accentColor,
        ),

        // Decorative geometric shape - VISIBLE with better contrast
        pw.Positioned(
          right: 0,
          top: 0,
          child: pw.ClipRect(
            child: pw.Transform.rotate(
              angle: 0.12,
              child: pw.Container(
                width: 280,
                height: 280,
                color: accentLight, // More visible now
              ),
            ),
          ),
        ),

        // Content
        pw.Positioned.fill(
          child: pw.Padding(
            padding: const pw.EdgeInsets.symmetric(horizontal: 48),
            child: pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              children: [
                // Profile photo with accent border
                if (profileImage != null) ...[
                  pw.Container(
                    width: 120,
                    height: 120,
                    decoration: pw.BoxDecoration(
                      shape: pw.BoxShape.circle,
                      color: accentColor,
                    ),
                    padding: const pw.EdgeInsets.all(5),
                    child: pw.ClipOval(
                      child: pw.Container(
                        color: _mediumGray,
                        child: pw.ClipOval(
                          child: pw.Image(profileImage, fit: pw.BoxFit.cover),
                        ),
                      ),
                    ),
                  ),
                  pw.SizedBox(width: 28),
                ],

                // Name and info
                pw.Expanded(
                  child: pw.Column(
                    mainAxisAlignment: pw.MainAxisAlignment.center,
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      // Name - BOLD and impactful
                      pw.Text(
                        name.toUpperCase(),
                        style: pw.TextStyle(
                          fontSize: 38,
                          fontWeight: pw.FontWeight.bold,
                          color: _white,
                          letterSpacing: 3.0,
                          height: 1.1,
                        ),
                      ),

                      pw.SizedBox(height: 10),

                      // Title badge - STRONG accent color
                      pw.Container(
                        padding: const pw.EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 6,
                        ),
                        decoration: pw.BoxDecoration(
                          color: accentColor,
                          borderRadius: pw.BorderRadius.circular(3),
                        ),
                        child: pw.Text(
                          title.toUpperCase(),
                          style: pw.TextStyle(
                            fontSize: 13,
                            fontWeight: pw.FontWeight.bold,
                            color: _black,
                            letterSpacing: 1.5,
                          ),
                        ),
                      ),

                      pw.SizedBox(height: 16),

                      // Contact info - Clean icons
                      pw.Wrap(
                        spacing: 20,
                        runSpacing: 8,
                        children: [
                          if (contact?.email != null)
                            _buildContactBadge(
                                '@', contact!.email!, accentColor),
                          if (contact?.phone != null)
                            _buildContactBadge(
                                '#', contact!.phone!, accentColor),
                          if (contact?.address != null)
                            _buildContactBadge(
                              '*',
                              contact!.address!.split(',').first,
                              accentColor,
                            ),
                          if (contact?.website != null)
                            _buildContactBadge(
                                'W', contact!.website!, accentColor),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// Contact badge - Clean professional design
  static pw.Widget _buildContactBadge(
      String icon, String text, PdfColor accentColor) {
    return pw.Row(
      mainAxisSize: pw.MainAxisSize.min,
      children: [
        pw.Container(
          width: 22,
          height: 22,
          decoration: pw.BoxDecoration(
            color: accentColor,
            shape: pw.BoxShape.circle,
          ),
          child: pw.Center(
            child: pw.Text(
              icon,
              style: pw.TextStyle(
                fontSize: 11,
                fontWeight: pw.FontWeight.bold,
                color: _black,
              ),
            ),
          ),
        ),
        pw.SizedBox(width: 7),
        pw.Text(
          text,
          style: const pw.TextStyle(
            fontSize: 9.5,
            color: _white,
          ),
        ),
      ],
    );
  }

  // ============================================================================
  // SECTION HEADER - Professional and clean
  // ============================================================================

  static pw.Widget _buildSectionHeader(
    String title,
    PdfColor accentColor,
    PdfColor accentDark,
    PdfColor textColor,
  ) {
    return pw.Row(
      children: [
        // Accent square
        pw.Container(
          width: 8,
          height: 8,
          decoration: pw.BoxDecoration(
            color: accentDark,
            borderRadius: pw.BorderRadius.circular(1),
          ),
        ),
        pw.SizedBox(width: 12),
        // Title
        pw.Text(
          title,
          style: pw.TextStyle(
            fontSize: 16,
            fontWeight: pw.FontWeight.bold,
            color: textColor,
            letterSpacing: 2.0,
          ),
        ),
        pw.SizedBox(width: 12),
        // Extending line
        pw.Expanded(
          child: pw.Container(
            height: 2.5,
            decoration: pw.BoxDecoration(
              color: accentColor,
              borderRadius: pw.BorderRadius.circular(1.25),
            ),
          ),
        ),
      ],
    );
  }

  // ============================================================================
  // SUMMARY + KEY SKILLS - Two column layout
  // ============================================================================

  static pw.Widget _buildSummaryAndSkills(
    CvData cv,
    PdfColor accentColor,
    PdfColor accentDark,
    PdfColor accentPale,
    PdfColor textColor,
    PdfColor textSecondary,
    PdfSpecialCharacters chars,
  ) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        // Summary - 65%
        if (cv.profile.isNotEmpty)
          pw.Expanded(
            flex: 65,
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                _buildSectionHeader(
                  'PROFESSIONAL SUMMARY',
                  accentColor,
                  accentDark,
                  textColor,
                ),
                pw.SizedBox(height: 14),
                pw.Row(
                  children: [
                    pw.Container(width: 3, color: accentColor),
                    pw.SizedBox(width: 2),
                    pw.Expanded(
                      child: pw.Container(
                        padding: const pw.EdgeInsets.all(14),
                        decoration: pw.BoxDecoration(
                          color: accentPale,
                          borderRadius: pw.BorderRadius.circular(4),
                        ),
                        child: pw.Text(
                          cv.profile,
                          style: pw.TextStyle(
                            fontSize: 10.5,
                            lineSpacing: 1.6,
                            color: textSecondary,
                            height: 1.4,
                          ),
                          textAlign: pw.TextAlign.justify,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

        if (cv.profile.isNotEmpty && cv.skills.isNotEmpty)
          pw.SizedBox(width: 32),

        // Key Skills - 35%
        if (cv.skills.isNotEmpty)
          pw.Expanded(
            flex: 35,
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                _buildSectionHeader(
                  'KEY SKILLS',
                  accentColor,
                  accentDark,
                  textColor,
                ),
                pw.SizedBox(height: 14),
                ...cv.skills.take(6).map((skill) {
                  final skillName = skill.split(' - ').first.trim();
                  return pw.Padding(
                    padding: const pw.EdgeInsets.only(bottom: 7),
                    child: pw.Row(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Padding(
                          padding: const pw.EdgeInsets.only(top: 3),
                          child: pw.Container(
                            width: 5,
                            height: 5,
                            decoration: pw.BoxDecoration(
                              color: accentDark,
                              shape: pw.BoxShape.circle,
                            ),
                          ),
                        ),
                        pw.SizedBox(width: 8),
                        pw.Expanded(
                          child: pw.Text(
                            skillName,
                            style: pw.TextStyle(
                              fontSize: 10,
                              color: textSecondary,
                              height: 1.3,
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

  // ============================================================================
  // EXPERIENCE ITEM - Professional and detailed
  // ============================================================================

  static pw.Widget _buildExperienceItem(
    Experience exp,
    PdfColor accentColor,
    PdfColor accentLight,
    PdfColor accentPale,
    PdfColor textColor,
    PdfColor textSecondary,
    PdfColor textTertiary,
    PdfSpecialCharacters chars,
  ) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        // Header row
        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Expanded(
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  // Job title with accent dot
                  pw.Row(
                    children: [
                      pw.Container(
                        width: 5,
                        height: 5,
                        decoration: pw.BoxDecoration(
                          color: accentColor,
                          shape: pw.BoxShape.circle,
                        ),
                      ),
                      pw.SizedBox(width: 8),
                      pw.Expanded(
                        child: pw.Text(
                          exp.title.toUpperCase(),
                          style: pw.TextStyle(
                            fontSize: 13,
                            fontWeight: pw.FontWeight.bold,
                            color: textColor,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ),
                    ],
                  ),
                  pw.SizedBox(height: 6),
                  // Company badge
                  pw.Padding(
                    padding: const pw.EdgeInsets.only(left: 13),
                    child: pw.Container(
                      padding: const pw.EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 3,
                      ),
                      decoration: pw.BoxDecoration(
                        color: accentColor,
                        borderRadius: pw.BorderRadius.circular(2),
                      ),
                      child: pw.Text(
                        exp.company,
                        style: pw.TextStyle(
                          fontSize: 9.5,
                          fontWeight: pw.FontWeight.bold,
                          color: _black,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            pw.SizedBox(width: 12),
            // Date in bordered box
            pw.Container(
              padding:
                  const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: accentColor, width: 1.5),
              ),
              child: pw.Text(
                exp.dateRange,
                style: pw.TextStyle(
                  fontSize: 9,
                  fontWeight: pw.FontWeight.bold,
                  color: textSecondary,
                ),
              ),
            ),
          ],
        ),

        // Description with left border
        if (exp.description != null && exp.description!.isNotEmpty) ...[
          pw.SizedBox(height: 10),
          pw.Padding(
            padding: const pw.EdgeInsets.only(left: 13),
            child: pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Container(width: 2, color: accentLight),
                pw.SizedBox(width: 10),
                pw.Expanded(
                  child: pw.Text(
                    exp.description!,
                    style: pw.TextStyle(
                      fontSize: 10,
                      lineSpacing: 1.5,
                      color: textSecondary,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],

        // Bullet points with diamonds
        if (exp.bullets.isNotEmpty) ...[
          pw.SizedBox(height: 10),
          ...exp.bullets.map((bullet) {
            return pw.Padding(
              padding: const pw.EdgeInsets.only(bottom: 6, left: 13),
              child: pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Padding(
                    padding: const pw.EdgeInsets.only(top: 4),
                    child: pw.Transform.rotate(
                      angle: 0.785398, // 45 degrees
                      child: pw.Container(
                        width: 4,
                        height: 4,
                        decoration: pw.BoxDecoration(
                          color: accentColor,
                          borderRadius: pw.BorderRadius.circular(0.5),
                        ),
                      ),
                    ),
                  ),
                  pw.SizedBox(width: 10),
                  pw.Expanded(
                    child: pw.Text(
                      bullet,
                      style: pw.TextStyle(
                        fontSize: 10,
                        lineSpacing: 1.4,
                        color: textSecondary,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ],
    );
  }

  // ============================================================================
  // EDUCATION + TECHNICAL SKILLS - Two column layout
  // ============================================================================

  static pw.Widget _buildEducationAndSkills(
    CvData cv,
    PdfColor accentColor,
    PdfColor accentDark,
    PdfColor accentLight,
    PdfColor accentPale,
    PdfColor textColor,
    PdfColor textSecondary,
    PdfColor textTertiary,
    PdfSpecialCharacters chars,
  ) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        // Education - 50%
        if (cv.education.isNotEmpty)
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                _buildSectionHeader(
                    'EDUCATION', accentColor, accentDark, textColor),
                pw.SizedBox(height: 16),
                ...cv.education.map((edu) {
                  return pw.Container(
                    margin: const pw.EdgeInsets.only(bottom: 16),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Row(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                          children: [
                            pw.Expanded(
                              child: pw.Row(
                                children: [
                                  // E badge
                                  pw.Container(
                                    width: 16,
                                    height: 16,
                                    decoration: pw.BoxDecoration(
                                      color: accentColor,
                                      borderRadius: pw.BorderRadius.circular(2),
                                    ),
                                    child: pw.Center(
                                      child: pw.Text(
                                        'E',
                                        style: pw.TextStyle(
                                          fontSize: 10,
                                          fontWeight: pw.FontWeight.bold,
                                          color: _black,
                                        ),
                                      ),
                                    ),
                                  ),
                                  pw.SizedBox(width: 8),
                                  pw.Expanded(
                                    child: pw.Text(
                                      edu.degree,
                                      style: pw.TextStyle(
                                        fontSize: 11.5,
                                        fontWeight: pw.FontWeight.bold,
                                        color: textColor,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            pw.SizedBox(width: 8),
                            pw.Text(
                              edu.dateRange,
                              style: pw.TextStyle(
                                fontSize: 9,
                                fontWeight: pw.FontWeight.bold,
                                color: textTertiary,
                              ),
                            ),
                          ],
                        ),
                        pw.SizedBox(height: 4),
                        pw.Padding(
                          padding: const pw.EdgeInsets.only(left: 24),
                          child: pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              pw.Text(
                                edu.institution,
                                style: pw.TextStyle(
                                  fontSize: 10,
                                  color: textSecondary,
                                ),
                              ),
                              if (edu.description != null &&
                                  edu.description!.isNotEmpty) ...[
                                pw.SizedBox(height: 3),
                                pw.Text(
                                  edu.description!,
                                  style: pw.TextStyle(
                                    fontSize: 9,
                                    color: textTertiary,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),

        if (cv.education.isNotEmpty && cv.skills.isNotEmpty)
          pw.SizedBox(width: 32),

        // Technical Skills - 50%
        if (cv.skills.isNotEmpty)
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                _buildSectionHeader(
                  'TECHNICAL SKILLS',
                  accentColor,
                  accentDark,
                  textColor,
                ),
                pw.SizedBox(height: 16),
                _buildSkillBars(
                  cv.skills,
                  accentColor,
                  accentPale,
                  textColor,
                  textSecondary,
                  textTertiary,
                ),
              ],
            ),
          ),
      ],
    );
  }

  // ============================================================================
  // SKILL BARS - With proper percentage parsing
  // ============================================================================

  static pw.Widget _buildSkillBars(
    List<String> skills,
    PdfColor accentColor,
    PdfColor accentPale,
    PdfColor textColor,
    PdfColor textSecondary,
    PdfColor textTertiary,
  ) {
    return pw.Column(
      children: skills.take(8).map((skillString) {
        // Parse skill with ROBUST percentage handling
        final parts = skillString.split(' - ');
        final skillName = parts.isNotEmpty ? parts[0].trim() : skillString;
        double proficiency = 0.8;

        if (parts.length > 1) {
          final level = parts[1].toLowerCase().trim();

          // Percentage: "90%", "85%"
          if (level.contains('%')) {
            final numStr = level.replaceAll(RegExp(r'[^0-9.]'), '');
            proficiency = (double.tryParse(numStr) ?? 80.0) / 100.0;
          }
          // Numeric: "90", "85", "0.9"
          else if (RegExp(r'^\d+\.?\d*$').hasMatch(level)) {
            final num = double.tryParse(level) ?? 80.0;
            proficiency = num <= 1.0 ? num : num / 100.0;
          }
          // Text levels
          else if (level.contains('expert') || level.contains('mastery')) {
            proficiency = 0.95;
          } else if (level.contains('advanced') ||
              level.contains('proficient')) {
            proficiency = 0.85;
          } else if (level.contains('intermediate') ||
              level.contains('competent')) {
            proficiency = 0.70;
          } else if (level.contains('basic') || level.contains('beginner')) {
            proficiency = 0.50;
          }
        }

        proficiency = proficiency.clamp(0.0, 1.0);

        return pw.Container(
          margin: const pw.EdgeInsets.only(bottom: 11),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Expanded(
                    child: pw.Text(
                      skillName,
                      style: pw.TextStyle(
                        fontSize: 10,
                        fontWeight: pw.FontWeight.bold,
                        color: textColor,
                      ),
                    ),
                  ),
                  pw.SizedBox(width: 6),
                  pw.Text(
                    '${(proficiency * 100).round()}%',
                    style: pw.TextStyle(
                      fontSize: 9,
                      fontWeight: pw.FontWeight.bold,
                      color: textTertiary,
                    ),
                  ),
                ],
              ),
              pw.SizedBox(height: 4),
              // Skill bar with better design
              pw.LayoutBuilder(
                builder: (context, constraints) {
                  return pw.Container(
                    height: 8,
                    child: pw.Stack(
                      children: [
                        // Background
                        pw.Container(
                          width: double.infinity,
                          height: 8,
                          decoration: pw.BoxDecoration(
                            color: accentPale,
                            border: pw.Border.all(color: _paleGray, width: 0.5),
                          ),
                        ),
                        // Fill
                        pw.Container(
                          width: constraints!.maxWidth * proficiency,
                          height: 8,
                          decoration: pw.BoxDecoration(
                            color: accentColor,
                            borderRadius: pw.BorderRadius.circular(4),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  // ============================================================================
  // LANGUAGES + INTERESTS - Bottom section
  // ============================================================================

  static pw.Widget _buildLanguagesAndInterests(
    CvData cv,
    PdfColor accentColor,
    PdfColor accentDark,
    PdfColor textColor,
    PdfColor textSecondary,
    PdfSpecialCharacters chars,
  ) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        // Languages
        if (cv.languages.isNotEmpty)
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                _buildSectionHeader(
                    'LANGUAGES', accentColor, accentDark, textColor),
                pw.SizedBox(height: 14),
                pw.Wrap(
                  spacing: 10,
                  runSpacing: 8,
                  children: cv.languages.map((lang) {
                    return pw.Container(
                      padding: const pw.EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: pw.BoxDecoration(
                        color: accentColor,
                        borderRadius: pw.BorderRadius.circular(3),
                      ),
                      child: pw.Text(
                        '${lang.language} - ${lang.level}',
                        style: pw.TextStyle(
                          fontSize: 9,
                          fontWeight: pw.FontWeight.bold,
                          color: _black,
                        ),
                      ),
                    );
                  }).toList(),
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
                _buildSectionHeader(
                    'INTERESTS', accentColor, accentDark, textColor),
                pw.SizedBox(height: 14),
                pw.Wrap(
                  spacing: 16,
                  runSpacing: 10,
                  children: cv.interests.map((interest) {
                    return pw.Row(
                      mainAxisSize: pw.MainAxisSize.min,
                      children: [
                        pw.Container(
                          width: 5,
                          height: 5,
                          decoration: pw.BoxDecoration(
                            color: accentDark,
                            borderRadius: pw.BorderRadius.circular(1),
                          ),
                        ),
                        pw.SizedBox(width: 6),
                        pw.Text(
                          interest,
                          style: pw.TextStyle(
                            fontSize: 10,
                            color: textSecondary,
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
