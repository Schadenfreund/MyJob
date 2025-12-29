import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../../constants/pdf_constants.dart';

/// Parsed skill with name and proficiency level
class ParsedSkill {
  final String name;
  final String level;
  final double percentage;

  const ParsedSkill({
    required this.name,
    required this.level,
    required this.percentage,
  });
}

/// Shared PDF Components Library
///
/// Centralized, reusable PDF widgets following DRY principles.
/// Used by both CV and cover letter templates for consistent design.
class PdfComponents {
  PdfComponents._();

  // ============================================================================
  // FONT UTILITIES
  // ============================================================================

  /// Get font fallback list for Unicode support in PDF documents
  ///
  /// Used by cover letter templates to ensure proper font fallback for special
  /// characters. Returns a list of fonts that can be used as fallbacks.
  static List<pw.Font> getFontFallback({
    required pw.Font regularFont,
    required pw.Font boldFont,
    required pw.Font mediumFont,
  }) {
    return [regularFont, boldFont, mediumFont];
  }

  // ============================================================================
  // SKILL PARSING UTILITIES
  // ============================================================================

  /// Level to percentage mapping for skill bars
  static const Map<String, double> _skillLevelMap = {
    'beginner': 0.25,
    'basic': 0.35,
    'intermediate': 0.50,
    'advanced': 0.75,
    'expert': 1.0,
    'native': 1.0,
    'fluent': 0.90,
    'proficient': 0.65,
  };

  /// Parse skill string to extract name and level
  /// Handles formats: "Skill Name (Level)" or "Skill Name"
  static ParsedSkill parseSkillString(String skillString) {
    final match = RegExp(r'^(.+?)\s*\((.+?)\)$').firstMatch(skillString.trim());

    if (match != null) {
      final name = match.group(1)!.trim();
      final level = match.group(2)!.trim();
      final levelLower = level.toLowerCase();
      final percentage = _skillLevelMap[levelLower] ?? 0.50;

      return ParsedSkill(
        name: name,
        level: level,
        percentage: percentage,
      );
    }

    // No level specified - default to intermediate
    return ParsedSkill(
      name: skillString.trim(),
      level: 'Intermediate',
      percentage: 0.50,
    );
  }

  /// Parse list of skill strings
  static List<ParsedSkill> parseSkillStrings(List<String> skills) {
    return skills.map(parseSkillString).toList();
  }

  // ============================================================================
  // CONTACT ITEMS WITH CIRCULAR BADGE ICONS
  // ============================================================================

  /// Build circular badge icon (letter in colored circle)
  static pw.Widget buildCircularBadge({
    required String letter,
    required PdfColor color,
    double size = PdfConstants.contactBadgeSize,
    bool filled = true,
  }) {
    return pw.Container(
      width: size,
      height: size,
      decoration: pw.BoxDecoration(
        color: filled ? color : null,
        shape: pw.BoxShape.circle,
        border: filled ? null : pw.Border.all(color: color, width: 1),
      ),
      child: pw.Center(
        child: pw.Text(
          letter,
          style: pw.TextStyle(
            fontSize: size * 0.5,
            fontWeight: pw.FontWeight.bold,
            color: filled ? PdfColors.white : color,
          ),
        ),
      ),
    );
  }

  /// Build contact item with circular badge icon
  static pw.Widget buildContactWithIcon({
    required String icon,
    required String value,
    PdfColor? iconColor,
    PdfColor? textColor,
    double iconSize = PdfConstants.contactBadgeSize,
    double fontSize = PdfConstants.fontSizeSmall,
    bool compact = false,
    bool useBadge = true,
  }) {
    final badgeColor = iconColor ?? PdfConstants.textMuted;

    return pw.Row(
      mainAxisSize: pw.MainAxisSize.min,
      children: [
        if (useBadge)
          buildCircularBadge(
            letter: icon,
            color: badgeColor,
            size: iconSize,
          )
        else
          pw.Text(
            icon,
            style: pw.TextStyle(
              fontSize: iconSize,
              fontWeight: pw.FontWeight.bold,
              color: badgeColor,
            ),
          ),
        pw.SizedBox(width: compact ? 4 : 6),
        pw.Text(
          value,
          style: pw.TextStyle(
            fontSize: fontSize,
            color: textColor ?? PdfConstants.textBody,
          ),
        ),
      ],
    );
  }

  /// Build contact row with circular badge icons
  static pw.Widget buildContactRowWithIcons({
    String? email,
    String? phone,
    String? address,
    String? linkedin,
    String? website,
    PdfColor? iconColor,
    PdfColor? textColor,
    bool compact = false,
    bool wrap = true,
    bool useBadges = true,
  }) {
    final items = <pw.Widget>[];

    void addItem(String icon, String value) {
      if (items.isNotEmpty) {
        items.add(pw.Container(
          margin: const pw.EdgeInsets.symmetric(horizontal: 8),
          child: pw.Text(
            '|',
            style: pw.TextStyle(
              color: PdfConstants.textLight,
              fontSize: PdfConstants.fontSizeSmall,
            ),
          ),
        ));
      }
      items.add(buildContactWithIcon(
        icon: icon,
        value: value,
        iconColor: iconColor,
        textColor: textColor,
        compact: compact,
        useBadge: useBadges,
      ));
    }

    if (email != null && email.isNotEmpty) {
      addItem(PdfConstants.iconEmail, email);
    }
    if (phone != null && phone.isNotEmpty) {
      addItem(PdfConstants.iconPhone, phone);
    }
    if (address != null && address.isNotEmpty) {
      addItem(PdfConstants.iconLocation, address);
    }
    if (linkedin != null && linkedin.isNotEmpty) {
      addItem(PdfConstants.iconLinkedIn, linkedin);
    }
    if (website != null && website.isNotEmpty) {
      addItem(PdfConstants.iconWebsite, website);
    }

    if (items.isEmpty) return pw.SizedBox();

    if (wrap) {
      return pw.Wrap(
        spacing: 0,
        runSpacing: PdfConstants.spaceSm,
        children: items,
      );
    }

    return pw.Row(
      mainAxisSize: pw.MainAxisSize.min,
      children: items,
    );
  }

  /// Build stacked contact list (vertical layout with badges)
  static pw.Widget buildContactListVertical({
    String? email,
    String? phone,
    String? address,
    String? linkedin,
    String? website,
    PdfColor? iconColor,
    PdfColor? textColor,
  }) {
    final items = <pw.Widget>[];

    void addItem(String icon, String value) {
      items.add(
        pw.Padding(
          padding: const pw.EdgeInsets.only(bottom: PdfConstants.spaceSm),
          child: buildContactWithIcon(
            icon: icon,
            value: value,
            iconColor: iconColor,
            textColor: textColor,
            useBadge: true,
          ),
        ),
      );
    }

    if (email != null && email.isNotEmpty) {
      addItem(PdfConstants.iconEmail, email);
    }
    if (phone != null && phone.isNotEmpty) {
      addItem(PdfConstants.iconPhone, phone);
    }
    if (address != null && address.isNotEmpty) {
      addItem(PdfConstants.iconLocation, address);
    }
    if (linkedin != null && linkedin.isNotEmpty) {
      addItem(PdfConstants.iconLinkedIn, linkedin);
    }
    if (website != null && website.isNotEmpty) {
      addItem(PdfConstants.iconWebsite, website);
    }

    if (items.isEmpty) return pw.SizedBox();

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: items,
    );
  }

  // ============================================================================
  // ENHANCED SKILL BARS WITH PARSED LEVELS
  // ============================================================================

  /// Build skill bar from skill string (parses level automatically)
  static pw.Widget buildSkillBarFromString(
    String skillString,
    PdfColor accentColor, {
    double maxWidth = PdfConstants.skillBarMaxWidth,
    bool showLevel = true,
    PdfColor? textColor,
    PdfColor? bgColor,
  }) {
    final parsed = parseSkillString(skillString);

    return pw.Container(
      margin:
          const pw.EdgeInsets.only(bottom: PdfConstants.skillBarSpacing + 2),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Expanded(
                child: pw.Text(
                  parsed.name,
                  style: pw.TextStyle(
                    fontSize: PdfConstants.fontSizeSmall,
                    fontWeight: pw.FontWeight.bold,
                    color: textColor ?? PdfConstants.textBody,
                  ),
                ),
              ),
              if (showLevel)
                pw.Text(
                  parsed.level,
                  style: pw.TextStyle(
                    fontSize: PdfConstants.fontSizeTiny,
                    color: PdfConstants.withOpacity(
                        textColor ?? PdfConstants.textMuted, 0.7),
                  ),
                ),
            ],
          ),
          pw.SizedBox(height: PdfConstants.spaceXs),
          pw.Stack(
            children: [
              // Background bar
              pw.Container(
                width: maxWidth,
                height: PdfConstants.skillBarHeight,
                decoration: pw.BoxDecoration(
                  color: bgColor ?? PdfConstants.bgMediumGray,
                  borderRadius:
                      pw.BorderRadius.circular(PdfConstants.skillBarRadius),
                ),
              ),
              // Filled bar
              pw.Container(
                width: maxWidth * parsed.percentage,
                height: PdfConstants.skillBarHeight,
                decoration: pw.BoxDecoration(
                  color: accentColor,
                  borderRadius:
                      pw.BorderRadius.circular(PdfConstants.skillBarRadius),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Build skill dots rating from skill string
  static pw.Widget buildSkillDotsFromString(
    String skillString,
    PdfColor accentColor, {
    int maxDots = 5,
    PdfColor? textColor,
  }) {
    final parsed = parseSkillString(skillString);
    final filledDots = (parsed.percentage * maxDots).round();

    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: PdfConstants.spaceSm),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Expanded(
            child: pw.Text(
              parsed.name,
              style: pw.TextStyle(
                fontSize: PdfConstants.fontSizeSmall,
                color: textColor ?? PdfConstants.textBody,
              ),
            ),
          ),
          pw.Row(
            mainAxisSize: pw.MainAxisSize.min,
            children: List.generate(maxDots, (index) {
              final isFilled = index < filledDots;
              return pw.Container(
                width: 8,
                height: 8,
                margin: const pw.EdgeInsets.only(left: 3),
                decoration: pw.BoxDecoration(
                  color: isFilled ? accentColor : PdfConstants.dividerLight,
                  shape: pw.BoxShape.circle,
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  /// Build skill badges with parsed levels (shows level as badge)
  /// Skill bars with white text for dark backgrounds (sidebar)
  static pw.Widget buildSkillBarsWhite(List<String> skills) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: skills.map((skill) {
        final parsed = parseSkillString(skill);
        return pw.Padding(
          padding: const pw.EdgeInsets.only(bottom: 10),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    parsed.name,
                    style: const pw.TextStyle(
                      fontSize: 9,
                      color: PdfColors.white,
                    ),
                  ),
                  pw.Text(
                    '${(parsed.percentage * 100).round()}%',
                    style: pw.TextStyle(
                      fontSize: 8,
                      color: PdfConstants.withOpacity(PdfColors.white, 0.7),
                    ),
                  ),
                ],
              ),
              pw.SizedBox(height: 4),
              pw.Stack(
                children: [
                  // Background bar
                  pw.Container(
                    height: 4,
                    decoration: pw.BoxDecoration(
                      color: PdfConstants.withOpacity(PdfColors.white, 0.3),
                      borderRadius: pw.BorderRadius.circular(2),
                    ),
                  ),
                  // Filled bar
                  pw.Container(
                    height: 4,
                    width: 100 * parsed.percentage, // Max width of ~100 points
                    decoration: pw.BoxDecoration(
                      color: PdfColors.white,
                      borderRadius: pw.BorderRadius.circular(2),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  static pw.Widget buildSkillBadgesWithLevels(
    List<String> skills,
    PdfColor accentColor,
  ) {
    return pw.Wrap(
      spacing: PdfConstants.badgeSpacing,
      runSpacing: PdfConstants.badgeSpacing,
      children: skills.map((skill) {
        final parsed = parseSkillString(skill);
        return pw.Container(
          padding: const pw.EdgeInsets.symmetric(
            horizontal: PdfConstants.badgePaddingH,
            vertical: PdfConstants.badgePaddingV,
          ),
          decoration: pw.BoxDecoration(
            color: PdfConstants.withOpacity(accentColor, 0.12),
            borderRadius: pw.BorderRadius.circular(PdfConstants.badgeRadius),
            border: pw.Border.all(
              color: PdfConstants.withOpacity(accentColor, 0.25),
              width: 0.5,
            ),
          ),
          child: pw.Row(
            mainAxisSize: pw.MainAxisSize.min,
            children: [
              pw.Text(
                parsed.name,
                style: pw.TextStyle(
                  fontSize: PdfConstants.fontSizeSmall,
                  color: PdfConstants.darken(accentColor, 0.15),
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(width: 6),
              pw.Container(
                padding:
                    const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                decoration: pw.BoxDecoration(
                  color: accentColor,
                  borderRadius: pw.BorderRadius.circular(4),
                ),
                child: pw.Text(
                  parsed.level.substring(0, 1).toUpperCase(),
                  style: pw.TextStyle(
                    fontSize: PdfConstants.fontSizeTiny - 1,
                    color: PdfColors.white,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  // ============================================================================
  // DOCUMENT HEADER COMPONENTS
  // ============================================================================

  /// Professional document header with name and contact info
  ///
  /// Used in both CVs and cover letters for consistent branding
  static pw.Widget buildDocumentHeader({
    required String name,
    String? email,
    String? phone,
    String? address,
    String? website,
    required PdfColor primaryColor,
    required PdfColor accentColor,
    bool largeHeader = true,
  }) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        // Name
        pw.Text(
          name,
          style: pw.TextStyle(
            fontSize: largeHeader
                ? PdfConstants.fontSizeName
                : PdfConstants.fontSizeH2,
            fontWeight: pw.FontWeight.bold,
            color: primaryColor,
            letterSpacing: PdfConstants.letterSpacingTight,
          ),
        ),
        pw.SizedBox(height: PdfConstants.spaceSm),

        // Accent divider
        pw.Container(
          width: 60,
          height: PdfConstants.accentDividerThickness,
          color: accentColor,
        ),
        pw.SizedBox(height: PdfConstants.spaceMd),

        // Contact information with icons
        buildContactRowWithIcons(
          email: email,
          phone: phone,
          address: address,
          website: website,
          iconColor: accentColor,
        ),
      ],
    );
  }

  // ============================================================================
  // SECTION HEADERS
  // ============================================================================

  /// Section heading with underline
  static pw.Widget buildSectionHeader(
    String title,
    PdfColor color, {
    bool uppercase = true,
  }) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          uppercase ? title.toUpperCase() : title,
          style: pw.TextStyle(
            fontSize: PdfConstants.fontSizeH2,
            fontWeight: pw.FontWeight.bold,
            color: color,
            letterSpacing: uppercase ? PdfConstants.letterSpacingWide : 0,
          ),
        ),
        pw.SizedBox(height: PdfConstants.spaceXs),
        pw.Container(
          width: 40,
          height: PdfConstants.dividerThickness,
          color: color,
        ),
      ],
    );
  }

  /// Section heading with optional full-width divider
  static pw.Widget buildSectionHeaderDivider(
    String title,
    PdfColor color, {
    bool uppercase = true,
    bool showDivider = true,
  }) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          uppercase ? title.toUpperCase() : title,
          style: pw.TextStyle(
            fontSize: PdfConstants.fontSizeH2,
            fontWeight: pw.FontWeight.bold,
            color: color,
            letterSpacing: uppercase ? PdfConstants.letterSpacingWide : 0,
          ),
        ),
        if (showDivider) ...[
          pw.SizedBox(height: PdfConstants.spaceXs),
          pw.Divider(
            color: PdfConstants.dividerLight,
            thickness: PdfConstants.dividerThickness,
          ),
        ],
      ],
    );
  }

  // ============================================================================
  // EXPERIENCE / TIMELINE ENTRIES
  // ============================================================================

  /// Professional experience entry with title, company, dates, and description
  static pw.Widget buildExperienceEntry({
    required String title,
    required String company,
    required String dateRange,
    String? description,
    List<String>? bullets,
    required PdfColor primaryColor,
  }) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: PdfConstants.entrySpacing),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          // Title and date range
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Expanded(
                child: pw.Text(
                  title,
                  style: pw.TextStyle(
                    fontSize: PdfConstants.fontSizeH3,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfConstants.textDark,
                  ),
                ),
              ),
              pw.SizedBox(width: PdfConstants.spaceMd),
              pw.Text(
                dateRange,
                style: pw.TextStyle(
                  fontSize: PdfConstants.fontSizeSmall,
                  color: PdfConstants.textMuted,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ],
          ),
          pw.SizedBox(height: PdfConstants.spaceXs),

          // Company
          pw.Text(
            company,
            style: pw.TextStyle(
              fontSize: PdfConstants.fontSizeH4,
              color: primaryColor,
              fontStyle: pw.FontStyle.italic,
            ),
          ),

          // Description
          if (description != null && description.isNotEmpty) ...[
            pw.SizedBox(height: PdfConstants.spaceSm),
            pw.Text(
              description,
              style: pw.TextStyle(
                fontSize: PdfConstants.fontSizeBody,
                color: PdfConstants.textBody,
                lineSpacing: PdfConstants.lineHeightNormal,
              ),
            ),
          ],

          // Bullet points
          if (bullets != null && bullets.isNotEmpty) ...[
            pw.SizedBox(height: PdfConstants.bulletSpacing),
            ...bullets.map((bullet) => _buildBulletPoint(bullet)),
          ],
        ],
      ),
    );
  }

  /// Education entry
  static pw.Widget buildEducationEntry({
    required String degree,
    required String institution,
    required String dateRange,
    String? details,
    required PdfColor primaryColor,
  }) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: PdfConstants.spaceMd),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  degree,
                  style: pw.TextStyle(
                    fontSize: PdfConstants.fontSizeH3,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfConstants.textDark,
                  ),
                ),
                pw.SizedBox(height: PdfConstants.spaceXs),
                pw.Text(
                  institution,
                  style: pw.TextStyle(
                    fontSize: PdfConstants.fontSizeH4,
                    color: primaryColor,
                  ),
                ),
                if (details != null && details.isNotEmpty) ...[
                  pw.SizedBox(height: PdfConstants.spaceXs),
                  pw.Text(
                    details,
                    style: pw.TextStyle(
                      fontSize: PdfConstants.fontSizeSmall,
                      color: PdfConstants.textMuted,
                    ),
                  ),
                ],
              ],
            ),
          ),
          pw.SizedBox(width: PdfConstants.spaceMd),
          pw.Text(
            dateRange,
            style: pw.TextStyle(
              fontSize: PdfConstants.fontSizeSmall,
              color: PdfConstants.textMuted,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  /// Bullet point with proper indentation
  static pw.Widget _buildBulletPoint(String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(
        left: PdfConstants.bulletIndent,
        top: PdfConstants.bulletSpacing,
      ),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            '${PdfConstants.bulletCharacter} ',
            style: pw.TextStyle(
              fontSize: PdfConstants.fontSizeBody,
              color: PdfConstants.textBody,
            ),
          ),
          pw.Expanded(
            child: pw.Text(
              text,
              style: pw.TextStyle(
                fontSize: PdfConstants.fontSizeBody,
                color: PdfConstants.textBody,
                lineSpacing: PdfConstants.lineHeightNormal,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================================
  // SKILL COMPONENTS
  // ============================================================================

  /// Skill badges in a wrap layout
  static pw.Widget buildSkillBadges(
    List<String> skills,
    PdfColor accentColor,
  ) {
    return pw.Wrap(
      spacing: PdfConstants.badgeSpacing,
      runSpacing: PdfConstants.badgeSpacing,
      children: skills.map((skill) {
        return pw.Container(
          padding: const pw.EdgeInsets.symmetric(
            horizontal: PdfConstants.badgePaddingH,
            vertical: PdfConstants.badgePaddingV,
          ),
          decoration: pw.BoxDecoration(
            color: PdfConstants.withOpacity(accentColor, 0.15),
            borderRadius: pw.BorderRadius.circular(PdfConstants.badgeRadius),
            border: pw.Border.all(
              color: PdfConstants.withOpacity(accentColor, 0.3),
              width: 0.5,
            ),
          ),
          child: pw.Text(
            skill,
            style: pw.TextStyle(
              fontSize: PdfConstants.fontSizeSmall,
              color: PdfConstants.darken(accentColor, 0.2),
              fontWeight: pw.FontWeight.bold,
            ),
          ),
        );
      }).toList(),
    );
  }

  /// Skill with proficiency bar
  static pw.Widget buildSkillWithBar(
    String skill,
    String level,
    PdfColor accentColor,
  ) {
    // Map levels to percentages
    final levelMap = {
      'Beginner': 0.3,
      'Intermediate': 0.5,
      'Advanced': 0.75,
      'Expert': 1.0,
      'Native': 1.0,
      'Fluent': 0.9,
      'Basic': 0.4,
    };

    final percentage = levelMap[level] ?? 0.5;

    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: PdfConstants.skillBarSpacing),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                skill,
                style: pw.TextStyle(
                  fontSize: PdfConstants.fontSizeSmall,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfConstants.textBody,
                ),
              ),
              pw.Text(
                level,
                style: pw.TextStyle(
                  fontSize: PdfConstants.fontSizeTiny,
                  color: PdfConstants.textMuted,
                ),
              ),
            ],
          ),
          pw.SizedBox(height: PdfConstants.spaceXs),
          pw.Stack(
            children: [
              // Background bar
              pw.Container(
                width: PdfConstants.skillBarMaxWidth,
                height: PdfConstants.skillBarHeight,
                decoration: pw.BoxDecoration(
                  color: PdfConstants.bgMediumGray,
                  borderRadius:
                      pw.BorderRadius.circular(PdfConstants.skillBarRadius),
                ),
              ),
              // Filled bar
              pw.Container(
                width: PdfConstants.skillBarMaxWidth * percentage,
                height: PdfConstants.skillBarHeight,
                decoration: pw.BoxDecoration(
                  color: accentColor,
                  borderRadius:
                      pw.BorderRadius.circular(PdfConstants.skillBarRadius),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ============================================================================
  // SIMPLE LISTS
  // ============================================================================

  /// Simple key-value pair (e.g., for languages)
  static pw.Widget buildKeyValuePair(
    String key,
    String value, {
    PdfColor? keyColor,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: PdfConstants.itemSpacing),
      child: pw.Row(
        children: [
          pw.Text(
            '$key: ',
            style: pw.TextStyle(
              fontSize: PdfConstants.fontSizeBody,
              fontWeight: pw.FontWeight.bold,
              color: keyColor ?? PdfConstants.textDark,
            ),
          ),
          pw.Text(
            value,
            style: pw.TextStyle(
              fontSize: PdfConstants.fontSizeBody,
              color: PdfConstants.textBody,
            ),
          ),
        ],
      ),
    );
  }

  /// Inline text list with bullet separator
  static pw.Widget buildInlineList(List<String> items) {
    return pw.Text(
      items.join(' ${PdfConstants.bulletCharacter} '),
      style: pw.TextStyle(
        fontSize: PdfConstants.fontSizeBody,
        color: PdfConstants.textBody,
        lineSpacing: PdfConstants.lineHeightNormal,
      ),
    );
  }

  // ============================================================================
  // PARAGRAPH TEXT
  // ============================================================================

  /// Professional paragraph with optimal line spacing
  static pw.Widget buildParagraph(String text, {bool justified = false}) {
    return pw.Text(
      text,
      style: pw.TextStyle(
        fontSize: PdfConstants.fontSizeBody,
        color: PdfConstants.textBody,
        lineSpacing: PdfConstants.lineHeightNormal,
      ),
      textAlign: justified ? pw.TextAlign.justify : pw.TextAlign.left,
    );
  }

  // ============================================================================
  // COVER LETTER SPECIFIC
  // ============================================================================

  /// Cover letter date formatting
  static String formatLetterDate(DateTime date) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December'
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  /// Recipient address block for formal letters
  static pw.Widget buildRecipientBlock({
    String? recipientName,
    String? recipientTitle,
    String? companyName,
  }) {
    final hasAnyInfo =
        recipientName != null || recipientTitle != null || companyName != null;

    if (!hasAnyInfo) return pw.SizedBox();

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        if (recipientName != null)
          pw.Text(
            recipientName,
            style: pw.TextStyle(
              fontSize: PdfConstants.fontSizeBody,
              fontWeight: pw.FontWeight.bold,
              color: PdfConstants.textDark,
            ),
          ),
        if (recipientTitle != null) ...[
          pw.SizedBox(height: PdfConstants.spaceXs),
          pw.Text(
            recipientTitle,
            style: pw.TextStyle(
              fontSize: PdfConstants.fontSizeBody,
              color: PdfConstants.textBody,
            ),
          ),
        ],
        if (companyName != null) ...[
          pw.SizedBox(height: PdfConstants.spaceXs),
          pw.Text(
            companyName,
            style: pw.TextStyle(
              fontSize: PdfConstants.fontSizeBody,
              fontWeight: pw.FontWeight.bold,
              color: PdfConstants.textDark,
            ),
          ),
        ],
      ],
    );
  }

  // ============================================================================
  // ENHANCED SECTION DIVIDERS
  // ============================================================================

  /// Full-width elegant divider with optional accent line
  static pw.Widget buildSectionDivider({
    PdfColor? color,
    double thickness = PdfConstants.dividerThickness,
    double spacing = PdfConstants.spaceMd,
  }) {
    return pw.Column(
      children: [
        pw.SizedBox(height: spacing),
        pw.Divider(
          color: color ?? PdfConstants.dividerLight,
          thickness: thickness,
        ),
        pw.SizedBox(height: spacing),
      ],
    );
  }

  /// Decorative section divider with centered text
  static pw.Widget buildDecorativeDivider({
    String? centerText,
    PdfColor? lineColor,
    PdfColor? textColor,
  }) {
    final line = pw.Expanded(
      child: pw.Container(
        height: PdfConstants.dividerThickness,
        color: lineColor ?? PdfConstants.dividerLight,
      ),
    );

    if (centerText == null) {
      return pw.Row(children: [line]);
    }

    return pw.Row(
      children: [
        line,
        pw.Padding(
          padding:
              const pw.EdgeInsets.symmetric(horizontal: PdfConstants.spaceMd),
          child: pw.Text(
            centerText,
            style: pw.TextStyle(
              fontSize: PdfConstants.fontSizeTiny,
              color: textColor ?? PdfConstants.textMuted,
              letterSpacing: PdfConstants.letterSpacingWide,
            ),
          ),
        ),
        line,
      ],
    );
  }

  // ============================================================================
  // CONTACT ROW WITH SEPARATORS (PUBLIC)
  // ============================================================================

  /// Public contact row builder with separator
  static pw.Widget buildContactRowPublic({
    String? email,
    String? phone,
    String? address,
    String? website,
    String? linkedin,
    bool compact = false,
    String separator = ' | ',
  }) {
    final items = <String>[];
    if (email != null && email.isNotEmpty) items.add(email);
    if (phone != null && phone.isNotEmpty) items.add(phone);
    if (address != null && address.isNotEmpty) items.add(address);
    if (website != null && website.isNotEmpty) items.add(website);
    if (linkedin != null && linkedin.isNotEmpty) items.add(linkedin);

    if (items.isEmpty) return pw.SizedBox();

    return pw.Text(
      items.join(separator),
      style: pw.TextStyle(
        fontSize:
            compact ? PdfConstants.fontSizeTiny : PdfConstants.fontSizeSmall,
        color: PdfConstants.textMuted,
      ),
      textAlign: pw.TextAlign.center,
    );
  }

  // ============================================================================
  // PROGRESS BAR COMPONENT
  // ============================================================================

  /// Horizontal progress/proficiency bar
  static pw.Widget buildProgressBar({
    required double percentage,
    required PdfColor fillColor,
    PdfColor? backgroundColor,
    double width = PdfConstants.skillBarMaxWidth,
    double height = PdfConstants.skillBarHeight,
    double radius = PdfConstants.skillBarRadius,
  }) {
    return pw.Stack(
      children: [
        // Background bar
        pw.Container(
          width: width,
          height: height,
          decoration: pw.BoxDecoration(
            color: backgroundColor ?? PdfConstants.bgMediumGray,
            borderRadius: pw.BorderRadius.circular(radius),
          ),
        ),
        // Filled bar
        pw.Container(
          width: width * percentage.clamp(0.0, 1.0),
          height: height,
          decoration: pw.BoxDecoration(
            color: fillColor,
            borderRadius: pw.BorderRadius.circular(radius),
          ),
        ),
      ],
    );
  }

  // ============================================================================
  // CHIP/BADGE COMPONENTS
  // ============================================================================

  /// Single chip badge with customizable style
  static pw.Widget buildChipBadge(
    String text, {
    required PdfColor color,
    bool filled = false,
    bool outlined = true,
    double? fontSize,
  }) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(
        horizontal: PdfConstants.badgePaddingH,
        vertical: PdfConstants.badgePaddingV,
      ),
      decoration: pw.BoxDecoration(
        color: filled ? color : PdfConstants.withOpacity(color, 0.15),
        borderRadius: pw.BorderRadius.circular(PdfConstants.badgeRadius),
        border: outlined
            ? pw.Border.all(
                color: PdfConstants.withOpacity(color, 0.3),
                width: 0.5,
              )
            : null,
      ),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: fontSize ?? PdfConstants.fontSizeSmall,
          color: filled ? PdfColors.white : PdfConstants.darken(color, 0.2),
          fontWeight: pw.FontWeight.bold,
        ),
      ),
    );
  }

  /// Multiple chips in a wrap layout
  static pw.Widget buildChipBadges(
    List<String> items, {
    required PdfColor color,
    bool filled = false,
    bool outlined = true,
  }) {
    return pw.Wrap(
      spacing: PdfConstants.badgeSpacing,
      runSpacing: PdfConstants.badgeSpacing,
      children: items.map((item) {
        return buildChipBadge(
          item,
          color: color,
          filled: filled,
          outlined: outlined,
        );
      }).toList(),
    );
  }

  // ============================================================================
  // TIMELINE COMPONENTS
  // ============================================================================

  /// Timeline entry with dot and connecting line
  static pw.Widget buildTimelineEntry({
    required String title,
    required String subtitle,
    required String dateRange,
    String? description,
    List<String>? bullets,
    required PdfColor dotColor,
    required PdfColor primaryColor,
    bool isLast = false,
  }) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        // Timeline column
        pw.SizedBox(
          width: PdfConstants.timelineDotSize + PdfConstants.spaceMd,
          child: pw.Column(
            children: [
              // Dot
              pw.Container(
                width: PdfConstants.timelineDotSize,
                height: PdfConstants.timelineDotSize,
                decoration: pw.BoxDecoration(
                  color: dotColor,
                  shape: pw.BoxShape.circle,
                ),
              ),
            ],
          ),
        ),

        // Content
        pw.Expanded(
          child: pw.Container(
            margin: const pw.EdgeInsets.only(bottom: PdfConstants.entrySpacing),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // Title and date
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Expanded(
                      child: pw.Text(
                        title,
                        style: pw.TextStyle(
                          fontSize: PdfConstants.fontSizeH3,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfConstants.textDark,
                        ),
                      ),
                    ),
                    pw.SizedBox(width: PdfConstants.spaceMd),
                    pw.Text(
                      dateRange,
                      style: pw.TextStyle(
                        fontSize: PdfConstants.fontSizeSmall,
                        color: PdfConstants.textMuted,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                pw.SizedBox(height: PdfConstants.spaceXs),

                // Subtitle
                pw.Text(
                  subtitle,
                  style: pw.TextStyle(
                    fontSize: PdfConstants.fontSizeH4,
                    color: primaryColor,
                    fontStyle: pw.FontStyle.italic,
                  ),
                ),

                // Description
                if (description != null && description.isNotEmpty) ...[
                  pw.SizedBox(height: PdfConstants.spaceSm),
                  pw.Text(
                    description,
                    style: pw.TextStyle(
                      fontSize: PdfConstants.fontSizeBody,
                      color: PdfConstants.textBody,
                      lineSpacing: PdfConstants.lineHeightNormal,
                    ),
                  ),
                ],

                // Bullet points
                if (bullets != null && bullets.isNotEmpty) ...[
                  pw.SizedBox(height: PdfConstants.bulletSpacing),
                  ...bullets.map((bullet) => buildBulletPoint(bullet)),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// Public bullet point builder
  static pw.Widget buildBulletPoint(String text, {PdfColor? bulletColor}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(
        left: PdfConstants.bulletIndent,
        top: PdfConstants.bulletSpacing,
      ),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            '${PdfConstants.bulletCharacter} ',
            style: pw.TextStyle(
              fontSize: PdfConstants.fontSizeBody,
              color: bulletColor ?? PdfConstants.textBody,
            ),
          ),
          pw.Expanded(
            child: pw.Text(
              text,
              style: pw.TextStyle(
                fontSize: PdfConstants.fontSizeBody,
                color: PdfConstants.textBody,
                lineSpacing: PdfConstants.lineHeightNormal,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================================
  // RATING/DOTS COMPONENT
  // ============================================================================

  /// Dot rating display (for skills/proficiency)
  static pw.Widget buildDotRating({
    required int rating,
    int maxRating = 5,
    PdfColor? filledColor,
    PdfColor? emptyColor,
    double size = 8.0,
  }) {
    return pw.Row(
      mainAxisSize: pw.MainAxisSize.min,
      children: List.generate(maxRating, (index) {
        final isFilled = index < rating;
        return pw.Container(
          width: size,
          height: size,
          margin: const pw.EdgeInsets.only(right: 3),
          decoration: pw.BoxDecoration(
            color: isFilled
                ? (filledColor ?? PdfConstants.professionalAccent)
                : (emptyColor ?? PdfConstants.dividerLight),
            shape: pw.BoxShape.circle,
          ),
        );
      }),
    );
  }

  // ============================================================================
  // CARD/BOX COMPONENT
  // ============================================================================

  /// Bordered card container
  static pw.Widget buildCard({
    required pw.Widget child,
    PdfColor? backgroundColor,
    PdfColor? borderColor,
    double padding = PdfConstants.spaceMd,
    double borderRadius = PdfConstants.borderRadius,
  }) {
    return pw.Container(
      padding: pw.EdgeInsets.all(padding),
      decoration: pw.BoxDecoration(
        color: backgroundColor ?? PdfConstants.bgLightGray,
        border: borderColor != null
            ? pw.Border.all(color: borderColor, width: 0.5)
            : null,
        borderRadius: pw.BorderRadius.circular(borderRadius),
      ),
      child: child,
    );
  }

  // ============================================================================
  // SPACING HELPERS
  // ============================================================================

  static pw.Widget get sectionSpacer =>
      pw.SizedBox(height: PdfConstants.sectionSpacing);

  static pw.Widget get entrySpacer =>
      pw.SizedBox(height: PdfConstants.entrySpacing);

  static pw.Widget get paragraphSpacer =>
      pw.SizedBox(height: PdfConstants.paragraphSpacing);

  static pw.Widget spacer(double height) => pw.SizedBox(height: height);
}
