import 'package:pdf/widgets.dart' as pw;
import '../../models/cv_data.dart';
import '../shared/pdf_styling.dart';
import '../shared/pdf_icons.dart';
import '../shared/cv_translations.dart';
import 'icon_component.dart';

/// Experience Component - Flexible experience rendering with multiple layouts
///
/// Provides professional experience rendering with support for:
/// - Timeline visualization
/// - Traditional list layout
/// - Card-based layout
/// - Compact mode for dense CVs
class ExperienceComponent {
  ExperienceComponent._();

  /// Render a single experience entry
  static pw.Widget entry({
    required Experience experience,
    required PdfStyling styling,
    required int index,
    required int total,
    ExperienceLayout layout = ExperienceLayout.timeline,
  }) {
    switch (layout) {
      case ExperienceLayout.timeline:
        return _buildTimelineEntry(experience, styling, index, total);

      case ExperienceLayout.list:
        return _buildListEntry(experience, styling);

      case ExperienceLayout.cards:
        return _buildCardEntry(experience, styling);

      case ExperienceLayout.compact:
        return _buildCompactEntry(experience, styling);
    }
  }

  /// Render all experiences in a section
  static pw.Widget section({
    required List<Experience> experiences,
    required PdfStyling styling,
    ExperienceLayout layout = ExperienceLayout.timeline,
  }) {
    if (experiences.isEmpty) {
      return pw.SizedBox();
    }

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: experiences.asMap().entries.map((entry) {
        final index = entry.key;
        final experience = entry.value;
        final isLast = index == experiences.length - 1;

        return pw.Column(
          children: [
            ExperienceComponent.entry(
              experience: experience,
              styling: styling,
              index: index,
              total: experiences.length,
              layout: layout,
            ),
            if (!isLast) pw.SizedBox(height: styling.itemGap),
          ],
        );
      }).toList(),
    );
  }

  // ===========================================================================
  // PRIVATE LAYOUT BUILDERS
  // ===========================================================================

  /// Timeline layout - Simple ring at top with vertical line below
  static pw.Widget _buildTimelineEntry(
    Experience experience,
    PdfStyling styling,
    int index,
    int total,
  ) {
    // Timeline constants
    const double dotSize = 10;
    const double dotInnerSize = 4;
    const double lineWidth = 2;
    const double timelineWidth = 20;
    const double lineHeight = 80; // Fixed height line

    final accentColor = styling.accent;

    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        // Timeline column
        pw.Container(
          width: timelineWidth,
          child: pw.Column(
            children: [
              // Ring at top
              pw.Container(
                width: dotSize,
                height: dotSize,
                decoration: pw.BoxDecoration(
                  shape: pw.BoxShape.circle,
                  color: accentColor,
                ),
                child: pw.Center(
                  child: pw.Container(
                    width: dotInnerSize,
                    height: dotInnerSize,
                    decoration: pw.BoxDecoration(
                      shape: pw.BoxShape.circle,
                      color: styling.background,
                    ),
                  ),
                ),
              ),
              // Vertical line below ring (same for all entries)
              pw.Container(
                width: lineWidth,
                height: lineHeight,
                color: accentColor,
              ),
            ],
          ),
        ),

        // Content
        pw.Expanded(
          child: pw.Container(
            padding: pw.EdgeInsets.only(
              left: styling.space2,
              bottom: styling.space4,
            ),
            child: _buildExperienceContent(experience, styling),
          ),
        ),
      ],
    );
  }

  /// List layout - Traditional list without timeline
  static pw.Widget _buildListEntry(
    Experience experience,
    PdfStyling styling,
  ) {
    return pw.Container(
      padding: pw.EdgeInsets.only(bottom: styling.space3),
      child: _buildExperienceContent(experience, styling),
    );
  }

  /// Card layout - Card-based with background
  static pw.Widget _buildCardEntry(
    Experience experience,
    PdfStyling styling,
  ) {
    return pw.Container(
      padding: styling.cardPadding,
      decoration: pw.BoxDecoration(
        color: styling.cardBackground,
        // Note: Cannot use borderRadius with non-uniform Border in pdf package
        border: pw.Border(
          left: pw.BorderSide(color: styling.accent, width: 3),
        ),
      ),
      child: _buildExperienceContent(experience, styling),
    );
  }

  /// Compact layout - Minimal spacing for dense CVs
  static pw.Widget _buildCompactEntry(
    Experience experience,
    PdfStyling styling,
  ) {
    return pw.Container(
      padding: pw.EdgeInsets.only(bottom: styling.space2),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          // Header row: Title + Company | Date
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Left: Title and company
              pw.Expanded(
                child: pw.RichText(
                  text: pw.TextSpan(
                    children: [
                      pw.TextSpan(
                        text: experience.title,
                        style: pw.TextStyle(
                          fontSize: styling.fontSizeBody,
                          fontWeight: pw.FontWeight.bold,
                          color: styling.textPrimary,
                        ),
                      ),
                      pw.TextSpan(
                        text: ' at ${experience.company}',
                        style: pw.TextStyle(
                          fontSize: styling.fontSizeBody,
                          color: styling.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Right: Date
              pw.Text(
                CvTranslations.translateDate(
                  experience.dateRange,
                  styling.customization.language,
                ),
                style: pw.TextStyle(
                  fontSize: styling.fontSizeSmall,
                  color: styling.textSecondary,
                ),
              ),
            ],
          ),

          // Description (if present)
          if (experience.description != null &&
              experience.description!.isNotEmpty) ...[
            pw.SizedBox(height: styling.space1),
            pw.Text(
              experience.description!,
              style: pw.TextStyle(
                fontSize: styling.fontSizeSmall,
                color: styling.textSecondary,
                lineSpacing: 1.3,
              ),
            ),
          ],

          // Bullets (compact inline format)
          if (experience.bullets.isNotEmpty) ...[
            pw.SizedBox(height: styling.space1),
            pw.Text(
              experience.bullets.join(' • '),
              style: pw.TextStyle(
                fontSize: styling.fontSizeSmall,
                color: styling.textSecondary,
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Build standard experience content (used by multiple layouts)
  static pw.Widget _buildExperienceContent(
    Experience experience,
    PdfStyling styling,
  ) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        // Header row: Title + Date
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            // Job title
            pw.Expanded(
              child: pw.Text(
                experience.title,
                style: pw.TextStyle(
                  fontSize: styling.fontSizeH4,
                  fontWeight: pw.FontWeight.bold,
                  color: styling.textPrimary,
                ),
              ),
            ),

            // Date range with calendar icon
            pw.Row(
              mainAxisSize: pw.MainAxisSize.min,
              children: [
                PdfIcons.calendar(color: styling.accent, size: 10),
                pw.SizedBox(width: styling.space1),
                pw.Text(
                  CvTranslations.translateDate(
                    experience.dateRange,
                    styling.customization.language,
                  ),
                  style: pw.TextStyle(
                    fontSize: styling.fontSizeSmall,
                    color: styling.textSecondary,
                  ),
                ),
              ],
            ),
          ],
        ),

        pw.SizedBox(height: styling.space1),

        // Company with work icon
        pw.Row(
          children: [
            PdfIcons.work(color: styling.accent, size: 12),
            pw.SizedBox(width: styling.space2),
            pw.Text(
              experience.company,
              style: pw.TextStyle(
                fontSize: styling.fontSizeBody,
                color: styling.textSecondary,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          ],
        ),

        // Description
        if (experience.description != null &&
            experience.description!.isNotEmpty) ...[
          pw.SizedBox(height: styling.space3),
          pw.Text(
            experience.description!,
            style: pw.TextStyle(
              fontSize: styling.fontSizeBody,
              color: styling.textSecondary,
              lineSpacing: 1.5,
            ),
          ),
        ],

        // Bullet points
        if (experience.bullets.isNotEmpty) ...[
          pw.SizedBox(height: styling.space3),
          ...experience.bullets.map((bullet) {
            return pw.Padding(
              padding: pw.EdgeInsets.only(bottom: styling.space2),
              child: pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Container(
                    margin: pw.EdgeInsets.only(top: styling.space1),
                    child: IconComponent.bullet(
                      styling: styling,
                      style: BulletStyle.dot,
                    ),
                  ),
                  pw.SizedBox(width: styling.space3),
                  pw.Expanded(
                    child: pw.Text(
                      bullet,
                      style: pw.TextStyle(
                        fontSize: styling.fontSizeBody,
                        color: styling.textSecondary,
                        lineSpacing: 1.5,
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
}

/// Experience layout styles
enum ExperienceLayout {
  timeline, // Timeline dots + connecting lines
  list, // Traditional list
  cards, // Card-based layout
  compact, // Minimal spacing for dense CVs
}
