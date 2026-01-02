import 'package:pdf/widgets.dart' as pw;
import '../shared/pdf_styling.dart';
import 'icon_component.dart';

/// Section Component - Consistent section headers across all layouts
///
/// Provides multiple section header styles with icons, dividers, and proper spacing.
class SectionComponent {
  SectionComponent._();

  /// Build a section header with icon and divider
  ///
  /// Supports different visual styles:
  /// - accent: Accent bar + title + line (default, current Electric style)
  /// - minimal: Just title, no decorations
  /// - underline: Title with underline
  /// - boxed: Title in accent box
  static pw.Widget header({
    required String title,
    required PdfStyling styling,
    String? iconType,
    SectionStyle style = SectionStyle.accent,
  }) {
    switch (style) {
      case SectionStyle.accent:
        return _buildAccentHeader(title, styling, iconType);

      case SectionStyle.minimal:
        return _buildMinimalHeader(title, styling, iconType);

      case SectionStyle.underline:
        return _buildUnderlineHeader(title, styling, iconType);

      case SectionStyle.boxed:
        return _buildBoxedHeader(title, styling, iconType);
    }
  }

  /// Build a subsection header (smaller than section header)
  static pw.Widget subheader({
    required String title,
    required PdfStyling styling,
    String? iconType,
  }) {
    return pw.Row(
      children: [
        if (iconType != null) ...[
          IconComponent.sectionIcon(iconType: iconType, styling: styling),
          pw.SizedBox(width: styling.space2),
        ],
        pw.Text(
          title,
          style: pw.TextStyle(
            fontSize: styling.fontSizeH4,
            fontWeight: pw.FontWeight.bold,
            color: styling.textPrimary,
          ),
        ),
      ],
    );
  }

  // ===========================================================================
  // PRIVATE STYLE BUILDERS
  // ===========================================================================

  /// Accent style - Icon + title (no vertical bar)
  static pw.Widget _buildAccentHeader(
    String title,
    PdfStyling styling,
    String? iconType,
  ) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.center,
          children: [
            // Icon (if provided) - 20% larger
            if (iconType != null) ...[
              IconComponent.sectionIcon(
                iconType: iconType,
                styling: styling,
                size: IconSize.large, // Larger icon
              ),
              pw.SizedBox(width: styling.space3),
            ],

            // Title
            pw.Text(
              title.toUpperCase(),
              style: pw.TextStyle(
                fontSize: styling.fontSizeH2,
                fontWeight: pw.FontWeight.bold,
                color: styling.textPrimary,
                letterSpacing: 1,
              ),
            ),

            // Expanding line
            pw.SizedBox(width: styling.space3),
            pw.Expanded(
              child: pw.Container(
                height: 1,
                color: styling.divider,
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Minimal style - Just title, no decorations
  static pw.Widget _buildMinimalHeader(
    String title,
    PdfStyling styling,
    String? iconType,
  ) {
    return pw.Row(
      children: [
        if (iconType != null) ...[
          IconComponent.sectionIcon(iconType: iconType, styling: styling),
          pw.SizedBox(width: styling.space2),
        ],
        pw.Text(
          title,
          style: pw.TextStyle(
            fontSize: styling.fontSizeH2,
            fontWeight: pw.FontWeight.bold,
            color: styling.textPrimary,
          ),
        ),
      ],
    );
  }

  /// Underline style - Title with underline
  static pw.Widget _buildUnderlineHeader(
    String title,
    PdfStyling styling,
    String? iconType,
  ) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Row(
          children: [
            if (iconType != null) ...[
              IconComponent.sectionIcon(iconType: iconType, styling: styling),
              pw.SizedBox(width: styling.space2),
            ],
            pw.Text(
              title.toUpperCase(),
              style: pw.TextStyle(
                fontSize: styling.fontSizeH2,
                fontWeight: pw.FontWeight.bold,
                color: styling.textPrimary,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
        pw.SizedBox(height: styling.space2),
        pw.Container(
          width: 60,
          height: 3,
          decoration: pw.BoxDecoration(
            color: styling.accent,
            borderRadius: pw.BorderRadius.circular(1.5),
          ),
        ),
      ],
    );
  }

  /// Boxed style - Title in accent-colored box
  static pw.Widget _buildBoxedHeader(
    String title,
    PdfStyling styling,
    String? iconType,
  ) {
    return pw.Container(
      padding: pw.EdgeInsets.symmetric(
        horizontal: styling.space4,
        vertical: styling.space3,
      ),
      decoration: pw.BoxDecoration(
        color: styling.accent.flatten(),
        borderRadius: pw.BorderRadius.circular(4),
      ),
      child: pw.Row(
        mainAxisSize: pw.MainAxisSize.min,
        children: [
          if (iconType != null) ...[
            IconComponent.sectionIcon(iconType: iconType, styling: styling),
            pw.SizedBox(width: styling.space2),
          ],
          pw.Text(
            title.toUpperCase(),
            style: pw.TextStyle(
              fontSize: styling.fontSizeH3,
              fontWeight: pw.FontWeight.bold,
              color: styling.textOnAccent,
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }

  /// Build a section container with consistent padding and spacing
  ///
  /// Wraps section content with proper spacing from the header.
  /// Note: We use Column here because Wrap with vertical direction causes
  /// unbounded width constraints that break Row/Expanded widgets inside.
  static pw.Widget section({
    required String title,
    required pw.Widget content,
    required PdfStyling styling,
    String? iconType,
    SectionStyle style = SectionStyle.accent,
    bool addBottomMargin = true,
  }) {
    // Use Column - it's safer for MultiPage layouts
    // The MultiPage widget handles page breaks between Column children
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        // Section header
        header(
          title: title,
          styling: styling,
          iconType: iconType,
          style: style,
        ),

        // Spacing between header and content
        pw.SizedBox(height: styling.space4),

        // Section content
        content,

        // Bottom margin (for spacing between sections)
        if (addBottomMargin) pw.SizedBox(height: styling.sectionGapMajor),
      ],
    );
  }

  /// Build a section that keeps header with a minimum preview of content
  ///
  /// This version wraps the header with a ConstrainedBox preview to ensure
  /// at least some content stays with the header. Use this for sections
  /// where content splitting is especially problematic.
  static pw.Widget sectionKeepTogether({
    required String title,
    required pw.Widget content,
    required PdfStyling styling,
    String? iconType,
    SectionStyle style = SectionStyle.accent,
    bool addBottomMargin = true,
    double minPreviewHeight = 80,
  }) {
    // Create a fixed-height preview that stays with the header
    // This ensures at least this much content appears with the header
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        // Header + preview container - this whole block stays together
        pw.Container(
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            mainAxisSize: pw.MainAxisSize.min,
            children: [
              header(
                title: title,
                styling: styling,
                iconType: iconType,
                style: style,
              ),
              pw.SizedBox(height: styling.space4),
              // Constrained preview of content
              pw.ConstrainedBox(
                constraints: pw.BoxConstraints(minHeight: minPreviewHeight),
                child: content,
              ),
            ],
          ),
        ),

        // Bottom margin
        if (addBottomMargin) pw.SizedBox(height: styling.sectionGapMajor),
      ],
    );
  }

  /// Build a divider between sections
  static pw.Widget divider({
    required PdfStyling styling,
    DividerStyle style = DividerStyle.line,
  }) {
    switch (style) {
      case DividerStyle.line:
        return pw.Container(
          width: double.infinity,
          height: 1,
          color: styling.divider,
          margin: pw.EdgeInsets.symmetric(vertical: styling.space4),
        );

      case DividerStyle.dashed:
        // Simplified dashed line using dotted container decoration
        return pw.Container(
          width: double.infinity,
          height: 1,
          decoration: pw.BoxDecoration(
            border: pw.Border(
              bottom: pw.BorderSide(
                color: styling.divider,
                width: 1,
                style: pw.BorderStyle.dashed,
              ),
            ),
          ),
          margin: pw.EdgeInsets.symmetric(vertical: styling.space4),
        );

      case DividerStyle.accent:
        return pw.Container(
          width: double.infinity,
          height: 2,
          decoration: pw.BoxDecoration(
            color: styling.accent,
            borderRadius: pw.BorderRadius.circular(1),
          ),
          margin: pw.EdgeInsets.symmetric(vertical: styling.space4),
        );

      case DividerStyle.spacer:
        return pw.SizedBox(height: styling.sectionGapMinor);
    }
  }
}

/// Section header visual styles
enum SectionStyle {
  accent, // Accent bar + title + line (current Electric style)
  minimal, // Just title, no decorations
  underline, // Title with underline
  boxed, // Title in accent box
}

/// Divider styles for separating content
enum DividerStyle {
  line, // Solid line
  dashed, // Dashed line
  accent, // Accent-colored thicker line
  spacer, // Just empty space, no visible line
}
