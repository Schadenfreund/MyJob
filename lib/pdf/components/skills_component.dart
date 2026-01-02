import 'package:pdf/widgets.dart' as pw;
import '../shared/pdf_styling.dart';
import '../shared/pdf_icons.dart';
import 'icon_component.dart';

/// Skills Component - Beautiful skill visualization with proficiency indicators
///
/// Provides multiple ways to display skills:
/// - Tags: Clean skill tags with optional proficiency levels
/// - Bars: Visual proficiency bars for skill levels
/// - Grid: Multi-column grid layout for large skill sets
class SkillsComponent {
  SkillsComponent._();

  /// Render skills as tags with optional proficiency indicators
  ///
  /// Example: "Python (Expert)", "JavaScript (Advanced)"
  static pw.Widget tags({
    required List<String> skills,
    required PdfStyling styling,
    bool showProficiency = false,
    SkillTagStyle style = SkillTagStyle.outlined,
  }) {
    if (skills.isEmpty) {
      return pw.SizedBox();
    }

    return pw.Wrap(
      spacing: styling.space2,
      runSpacing: styling.space2,
      children: skills.map((skill) {
        return _buildSkillTag(skill, styling, style);
      }).toList(),
    );
  }

  /// Render skills with proficiency bars
  ///
  /// Skills should be in format "Skill:Level" where Level is 0-100
  /// Example: "Python:90", "JavaScript:75"
  static pw.Widget bars({
    required List<String> skills,
    required PdfStyling styling,
    double barHeight = 6,
    double barWidth = 120,
  }) {
    if (skills.isEmpty) {
      return pw.SizedBox();
    }

    // Parse skills with levels
    final skillsWithLevels = <String, int>{};
    for (final skill in skills) {
      final parts = skill.split(':');
      if (parts.length == 2) {
        final name = parts[0].trim();
        final level = int.tryParse(parts[1].trim()) ?? 50;
        skillsWithLevels[name] = level.clamp(0, 100);
      } else {
        // No level specified, assume intermediate (70%)
        skillsWithLevels[skill] = 70;
      }
    }

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: skillsWithLevels.entries.map((entry) {
        return pw.Container(
          margin: pw.EdgeInsets.only(bottom: styling.space3),
          child: pw.Row(
            children: [
              // Skill name
              pw.SizedBox(
                width: 100,
                child: pw.Text(
                  entry.key,
                  style: pw.TextStyle(
                    fontSize: styling.fontSizeSmall,
                    color: styling.textPrimary,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),

              pw.SizedBox(width: styling.space3),

              // Proficiency bar
              PdfIcons.proficiencyBar(
                level: entry.value,
                fillColor: styling.accent,
                backgroundColor: styling.divider,
                height: barHeight,
                width: barWidth,
              ),

              pw.SizedBox(width: styling.space2),

              // Percentage text
              pw.Text(
                '${entry.value}%',
                style: pw.TextStyle(
                  fontSize: styling.fontSizeTiny,
                  color: styling.textSecondary,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  /// Render skills in a multi-column grid
  ///
  /// Useful for displaying many skills in a compact space.
  static pw.Widget grid({
    required List<String> skills,
    required PdfStyling styling,
    int columns = 3,
    bool showBullets = true,
  }) {
    if (skills.isEmpty) {
      return pw.SizedBox();
    }

    // Calculate rows needed
    final rows = (skills.length / columns).ceil();
    final skillsList = List<String>.from(skills);

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: List.generate(rows, (rowIndex) {
        final startIndex = rowIndex * columns;
        final endIndex = (startIndex + columns).clamp(0, skills.length);
        final rowSkills = skillsList.sublist(startIndex, endIndex);

        return pw.Container(
          margin: pw.EdgeInsets.only(bottom: styling.space2),
          child: pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: rowSkills.map((skill) {
              return pw.Expanded(
                child: pw.Row(
                  children: [
                    if (showBullets) ...[
                      IconComponent.bullet(
                        styling: styling,
                        style: BulletStyle.dot,
                        customSize: 4,
                      ),
                      pw.SizedBox(width: styling.space2),
                    ],
                    pw.Expanded(
                      child: pw.Text(
                        skill,
                        style: pw.TextStyle(
                          fontSize: styling.fontSizeSmall,
                          color: styling.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        );
      }).toList(),
    );
  }

  /// Render skills with icons for categories
  ///
  /// Skills should be in format "Category:Skill1,Skill2,Skill3"
  /// Example: "code:Python,JavaScript,TypeScript|design:Figma,Photoshop"
  static pw.Widget categorized({
    required List<String> categorizedSkills,
    required PdfStyling styling,
  }) {
    if (categorizedSkills.isEmpty) {
      return pw.SizedBox();
    }

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: categorizedSkills.map((categoryString) {
        final parts = categoryString.split(':');
        if (parts.length != 2) return pw.SizedBox();

        final category = parts[0].trim();
        final skillsList = parts[1].split(',').map((s) => s.trim()).toList();

        return pw.Container(
          margin: pw.EdgeInsets.only(bottom: styling.space4),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Category header with icon
              pw.Row(
                children: [
                  IconComponent.sectionIcon(
                    iconType: category,
                    styling: styling,
                  ),
                  pw.SizedBox(width: styling.space2),
                  pw.Text(
                    _formatCategoryName(category),
                    style: pw.TextStyle(
                      fontSize: styling.fontSizeBody,
                      fontWeight: pw.FontWeight.bold,
                      color: styling.textPrimary,
                    ),
                  ),
                ],
              ),

              pw.SizedBox(height: styling.space2),

              // Skills for this category
              pw.Wrap(
                spacing: styling.space2,
                runSpacing: styling.space2,
                children: skillsList.map((skill) {
                  return _buildSkillTag(
                    skill,
                    styling,
                    SkillTagStyle.minimal,
                  );
                }).toList(),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  // ===========================================================================
  // PRIVATE HELPERS
  // ===========================================================================

  /// Build a single skill tag
  static pw.Widget _buildSkillTag(
    String skill,
    PdfStyling styling,
    SkillTagStyle style,
  ) {
    switch (style) {
      case SkillTagStyle.outlined:
        return pw.Container(
          padding: pw.EdgeInsets.symmetric(
            horizontal: styling.space3,
            vertical: styling.space2,
          ),
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: styling.accent, width: 1),
            borderRadius: pw.BorderRadius.circular(12),
          ),
          child: pw.Text(
            skill,
            style: pw.TextStyle(
              fontSize: styling.fontSizeSmall,
              color: styling.textPrimary,
            ),
          ),
        );

      case SkillTagStyle.filled:
        return pw.Container(
          padding: pw.EdgeInsets.symmetric(
            horizontal: styling.space3,
            vertical: styling.space2,
          ),
          decoration: pw.BoxDecoration(
            color: styling.accent.flatten(),
            borderRadius: pw.BorderRadius.circular(12),
          ),
          child: pw.Text(
            skill,
            style: pw.TextStyle(
              fontSize: styling.fontSizeSmall,
              color: styling.textOnAccent,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
        );

      case SkillTagStyle.minimal:
        return pw.Row(
          mainAxisSize: pw.MainAxisSize.min,
          children: [
            IconComponent.bullet(
              styling: styling,
              style: BulletStyle.dot,
              customSize: 4,
            ),
            pw.SizedBox(width: styling.space2),
            pw.Text(
              skill,
              style: pw.TextStyle(
                fontSize: styling.fontSizeSmall,
                color: styling.textSecondary,
              ),
            ),
          ],
        );

      case SkillTagStyle.badge:
        return pw.Container(
          padding: pw.EdgeInsets.symmetric(
            horizontal: styling.space3,
            vertical: styling.space2,
          ),
          decoration: pw.BoxDecoration(
            color: styling.cardBackground,
            borderRadius: pw.BorderRadius.circular(4),
            border: pw.Border(
              left: pw.BorderSide(color: styling.accent, width: 2),
            ),
          ),
          child: pw.Text(
            skill,
            style: pw.TextStyle(
              fontSize: styling.fontSizeSmall,
              color: styling.textPrimary,
            ),
          ),
        );
    }
  }

  /// Format category name (capitalize first letter, replace underscores)
  static String _formatCategoryName(String category) {
    return category
        .replaceAll('_', ' ')
        .split(' ')
        .map((word) => word.isEmpty
            ? word
            : word[0].toUpperCase() + word.substring(1).toLowerCase())
        .join(' ');
  }
}

/// Skill tag visual styles
enum SkillTagStyle {
  outlined, // Border with no background (default)
  filled, // Solid background
  minimal, // Just bullet + text
  badge, // Card-style with left accent
}
