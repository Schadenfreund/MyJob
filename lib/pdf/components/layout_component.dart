import 'package:pdf/widgets.dart' as pw;
import '../shared/pdf_styling.dart';

/// Layout Component - Page layout helpers for single/two-column layouts
///
/// Provides reusable layout patterns for PDF templates.
class LayoutComponent {
  LayoutComponent._();

  /// Two-column layout with sidebar
  ///
  /// Creates a two-column layout with a sidebar on the left
  /// and main content on the right. Uses Table for reliable rendering.
  ///
  /// Example usage:
  /// ```dart
  /// LayoutComponent.twoColumn(
  ///   sidebar: _buildSidebar(),
  ///   mainContent: _buildMainContent(),
  ///   styling: styling,
  ///   sidebarWidth: 0.35, // 35% width
  /// )
  /// ```
  static pw.Widget twoColumn({
    required pw.Widget sidebar,
    required pw.Widget mainContent,
    required PdfStyling styling,
    double sidebarWidth = 0.32, // 32% default
    bool showDivider = true,
    SidebarPosition position = SidebarPosition.left,
  }) {
    // Use Table for reliable two-column layout
    // This works well with MultiPage and doesn't cause rendering issues

    final sidebarCell = pw.Container(
      padding: pw.EdgeInsets.all(styling.space3),
      color: styling.cardBackground,
      child: sidebar,
    );

    final mainCell = pw.Container(
      padding: pw.EdgeInsets.only(left: styling.space4),
      child: mainContent,
    );

    final dividerCell = showDivider
        ? pw.Container(
            width: 3,
            color: styling.accent,
          )
        : pw.SizedBox(width: styling.space2);

    // Build table columns based on position
    List<pw.TableRow> rows;
    Map<int, pw.TableColumnWidth> columnWidths;

    if (position == SidebarPosition.left) {
      columnWidths = {
        0: pw.FlexColumnWidth(sidebarWidth),
        1: const pw.FixedColumnWidth(12), // divider
        2: pw.FlexColumnWidth(1 - sidebarWidth),
      };
      rows = [
        pw.TableRow(
          children: [sidebarCell, dividerCell, mainCell],
        ),
      ];
    } else {
      columnWidths = {
        0: pw.FlexColumnWidth(1 - sidebarWidth),
        1: const pw.FixedColumnWidth(12), // divider
        2: pw.FlexColumnWidth(sidebarWidth),
      };
      rows = [
        pw.TableRow(
          children: [mainCell, dividerCell, sidebarCell],
        ),
      ];
    }

    return pw.Table(
      columnWidths: columnWidths,
      children: rows,
    );
  }

  /// Three-column layout
  ///
  /// Creates a three-column layout for dense information display.
  static pw.Widget threeColumn({
    required pw.Widget left,
    required pw.Widget center,
    required pw.Widget right,
    required PdfStyling styling,
    double columnGap = 16,
  }) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Expanded(child: left),
        pw.SizedBox(width: columnGap),
        pw.Expanded(child: center),
        pw.SizedBox(width: columnGap),
        pw.Expanded(child: right),
      ],
    );
  }

  /// Responsive section that adapts to layout mode
  ///
  /// Provides a consistent container for sections with proper spacing.
  static pw.Widget section({
    required String title,
    required pw.Widget content,
    required PdfStyling styling,
    String? iconType,
    SectionHeaderStyle headerStyle = SectionHeaderStyle.standard,
    bool addBottomMargin = true,
  }) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        // Section header
        _buildSectionHeader(title, styling, iconType, headerStyle),

        // Spacing between header and content
        pw.SizedBox(height: styling.space4),

        // Section content
        content,

        // Bottom margin (for spacing between sections)
        if (addBottomMargin) pw.SizedBox(height: styling.sectionGapMajor),
      ],
    );
  }

  /// Build a card container
  ///
  /// Provides a consistent card design for content blocks.
  static pw.Widget card({
    required pw.Widget content,
    required PdfStyling styling,
    bool showAccentBorder = true,
    double? customPadding,
  }) {
    return pw.Container(
      padding: customPadding != null
          ? pw.EdgeInsets.all(customPadding)
          : styling.cardPadding,
      decoration: pw.BoxDecoration(
        color: styling.cardBackground,
        // Note: Cannot use borderRadius with non-uniform Border in pdf package
        border: showAccentBorder
            ? pw.Border(
                left: pw.BorderSide(color: styling.accent, width: 3),
              )
            : null,
      ),
      child: content,
    );
  }

  /// Build a responsive grid layout
  ///
  /// Creates a grid with a specified number of columns.
  static pw.Widget grid({
    required List<pw.Widget> children,
    required PdfStyling styling,
    int columns = 2,
    double? horizontalGap,
    double? verticalGap,
  }) {
    if (children.isEmpty) {
      return pw.SizedBox();
    }

    final hGap = horizontalGap ?? styling.space4;
    final vGap = verticalGap ?? styling.space4;

    final rows = (children.length / columns).ceil();

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: List.generate(rows, (rowIndex) {
        final startIndex = rowIndex * columns;
        final endIndex = (startIndex + columns).clamp(0, children.length);
        final rowChildren = children.sublist(startIndex, endIndex);

        // Pad row with empty containers if needed
        while (rowChildren.length < columns) {
          rowChildren.add(pw.SizedBox());
        }

        return pw.Container(
          margin: pw.EdgeInsets.only(
            bottom: rowIndex < rows - 1 ? vGap : 0,
          ),
          child: pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: _intersperse(
              rowChildren.map((child) => pw.Expanded(child: child)).toList(),
              pw.SizedBox(width: hGap),
            ),
          ),
        );
      }).toList(),
    );
  }

  /// Build a spacer with consistent height
  static pw.Widget spacer({
    required PdfStyling styling,
    SpacerSize size = SpacerSize.medium,
  }) {
    switch (size) {
      case SpacerSize.small:
        return pw.SizedBox(height: styling.space2);
      case SpacerSize.medium:
        return pw.SizedBox(height: styling.space4);
      case SpacerSize.large:
        return pw.SizedBox(height: styling.space6);
      case SpacerSize.section:
        return pw.SizedBox(height: styling.sectionGapMinor);
      case SpacerSize.major:
        return pw.SizedBox(height: styling.sectionGapMajor);
    }
  }

  // ===========================================================================
  // PRIVATE HELPERS
  // ===========================================================================

  /// Build section header based on style
  static pw.Widget _buildSectionHeader(
    String title,
    PdfStyling styling,
    String? iconType,
    SectionHeaderStyle style,
  ) {
    switch (style) {
      case SectionHeaderStyle.standard:
        return pw.Row(
          children: [
            pw.Container(
              width: 4,
              height: 20,
              decoration: pw.BoxDecoration(
                color: styling.accent,
                borderRadius: pw.BorderRadius.circular(2),
              ),
              margin: pw.EdgeInsets.only(right: styling.space3),
            ),
            pw.Text(
              title.toUpperCase(),
              style: pw.TextStyle(
                fontSize: styling.fontSizeH2,
                fontWeight: pw.FontWeight.bold,
                color: styling.textPrimary,
                letterSpacing: 1,
              ),
            ),
          ],
        );

      case SectionHeaderStyle.minimal:
        return pw.Text(
          title,
          style: pw.TextStyle(
            fontSize: styling.fontSizeH2,
            fontWeight: pw.FontWeight.bold,
            color: styling.textPrimary,
          ),
        );

      case SectionHeaderStyle.underlined:
        return pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              title.toUpperCase(),
              style: pw.TextStyle(
                fontSize: styling.fontSizeH2,
                fontWeight: pw.FontWeight.bold,
                color: styling.textPrimary,
                letterSpacing: 0.5,
              ),
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
  }

  /// Intersperse a separator between list items
  static List<T> _intersperse<T>(List<T> list, T separator) {
    if (list.isEmpty) return [];

    final result = <T>[];
    for (var i = 0; i < list.length; i++) {
      result.add(list[i]);
      if (i < list.length - 1) {
        result.add(separator);
      }
    }
    return result;
  }
}

/// Sidebar position
enum SidebarPosition {
  left,
  right,
}

/// Section header styles
enum SectionHeaderStyle {
  standard, // Accent bar + title
  minimal, // Just title
  underlined, // Title with underline
}

/// Spacer sizes
enum SpacerSize {
  small, // space2
  medium, // space4
  large, // space6
  section, // sectionGapMinor
  major, // sectionGapMajor
}
