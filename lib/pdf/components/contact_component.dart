import 'package:pdf/widgets.dart' as pw;
import '../../models/cv_data.dart';
import '../shared/pdf_styling.dart';
import 'icon_component.dart';

/// Contact Component - Contact information with icons and proper formatting
///
/// Provides flexible contact info rendering with multiple layout modes.
class ContactComponent {
  ContactComponent._();

  /// Render contact info with icons
  ///
  /// Supports different layout modes:
  /// - wrap: Wrap to multiple lines if needed (default)
  /// - row: Single row (may overflow)
  /// - column: Vertical stack
  /// - grid: 2-column grid
  static pw.Widget info({
    required ContactDetails contact,
    required PdfStyling styling,
    ContactLayout layout = ContactLayout.wrap,
    bool showIcons = true,
    IconSize iconSize = IconSize.small,
  }) {
    final items = _buildContactItems(contact, styling, showIcons, iconSize);

    if (items.isEmpty) {
      return pw.SizedBox();
    }

    switch (layout) {
      case ContactLayout.wrap:
        return pw.Wrap(
          spacing: styling.space4,
          runSpacing: styling.space2,
          children: items,
        );

      case ContactLayout.row:
        return pw.Row(
          mainAxisSize: pw.MainAxisSize.min,
          children: _intersperse(
            items,
            pw.SizedBox(width: styling.space4),
          ),
        );

      case ContactLayout.column:
        return pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: _intersperse(
            items,
            pw.SizedBox(height: styling.space2),
          ),
        );

      case ContactLayout.grid:
        return _buildGrid(items, styling);
    }
  }

  /// Render a single contact item
  static pw.Widget item({
    required String type,
    required String value,
    required PdfStyling styling,
    bool showIcon = true,
    IconSize iconSize = IconSize.small,
    ContactIconStyle iconStyle = ContactIconStyle.inline,
  }) {
    if (value.isEmpty) {
      return pw.SizedBox();
    }

    return IconComponent.contact(
      type: type,
      text: value,
      styling: styling,
      size: iconSize,
      style: iconStyle,
    );
  }

  /// Render contact info in a compact format (for sidebar)
  static pw.Widget compact({
    required ContactDetails contact,
    required PdfStyling styling,
  }) {
    final items = <pw.Widget>[];

    void addItem(String? value, String type) {
      if (value != null && value.isNotEmpty) {
        items.add(
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                _formatLabel(type),
                style: pw.TextStyle(
                  fontSize: styling.fontSizeTiny,
                  color: styling.textSecondary,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: styling.space1),
              pw.Text(
                value,
                style: pw.TextStyle(
                  fontSize: styling.fontSizeSmall,
                  color: styling.textPrimary,
                ),
              ),
              pw.SizedBox(height: styling.space3),
            ],
          ),
        );
      }
    }

    addItem(contact.email, 'email');
    addItem(contact.phone, 'phone');
    addItem(contact.address, 'address');
    addItem(contact.website, 'website');
    addItem(contact.linkedin, 'linkedin');

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: items,
    );
  }

  /// Render contact info in a sidebar format with icons
  static pw.Widget sidebar({
    required ContactDetails contact,
    required PdfStyling styling,
  }) {
    final items = <pw.Widget>[];

    void addItem(String? value, String type) {
      if (value != null && value.isNotEmpty) {
        items.add(
          IconComponent.contact(
            type: type,
            text: value,
            styling: styling,
            size: IconSize.small,
            style: ContactIconStyle.inline,
          ),
        );
        items.add(pw.SizedBox(height: styling.space3));
      }
    }

    addItem(contact.email, 'email');
    addItem(contact.phone, 'phone');
    addItem(contact.address, 'location');
    addItem(contact.website, 'web');
    addItem(contact.linkedin, 'linkedin');

    if (items.isEmpty) {
      return pw.SizedBox();
    }

    // Remove last spacer
    if (items.isNotEmpty) {
      items.removeLast();
    }

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: items,
    );
  }

  // ===========================================================================
  // PRIVATE HELPERS
  // ===========================================================================

  /// Build contact items from ContactDetails
  static List<pw.Widget> _buildContactItems(
    ContactDetails contact,
    PdfStyling styling,
    bool showIcons,
    IconSize iconSize,
  ) {
    final items = <pw.Widget>[];

    void addItem(String? value, String type) {
      if (value != null && value.isNotEmpty) {
        items.add(
          IconComponent.contact(
            type: type,
            text: value,
            styling: styling,
            size: iconSize,
            style: showIcons
                ? ContactIconStyle.inline
                : ContactIconStyle.iconOnly,
          ),
        );
      }
    }

    addItem(contact.email, 'email');
    addItem(contact.phone, 'phone');
    addItem(contact.address, 'location');
    addItem(contact.website, 'web');
    addItem(contact.linkedin, 'linkedin');

    return items;
  }

  /// Build a 2-column grid layout
  static pw.Widget _buildGrid(List<pw.Widget> items, PdfStyling styling) {
    if (items.isEmpty) {
      return pw.SizedBox();
    }

    final rows = (items.length / 2).ceil();
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: List.generate(rows, (rowIndex) {
        final startIndex = rowIndex * 2;
        final endIndex = (startIndex + 2).clamp(0, items.length);
        final rowItems = items.sublist(startIndex, endIndex);

        return pw.Container(
          margin: pw.EdgeInsets.only(bottom: styling.space2),
          child: pw.Row(
            children: [
              pw.Expanded(child: rowItems[0]),
              if (rowItems.length > 1) ...[
                pw.SizedBox(width: styling.space4),
                pw.Expanded(child: rowItems[1]),
              ] else
                pw.Expanded(child: pw.SizedBox()),
            ],
          ),
        );
      }).toList(),
    );
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

  /// Format label for compact display
  static String _formatLabel(String type) {
    switch (type.toLowerCase()) {
      case 'email':
        return 'Email';
      case 'phone':
        return 'Phone';
      case 'address':
      case 'location':
        return 'Address';
      case 'website':
      case 'web':
        return 'Website';
      case 'linkedin':
        return 'LinkedIn';
      case 'github':
        return 'GitHub';
      default:
        return type[0].toUpperCase() + type.substring(1);
    }
  }
}

/// Contact layout styles
enum ContactLayout {
  wrap, // Wrap to multiple lines if needed (default)
  row, // Single row (may overflow)
  column, // Vertical stack
  grid, // 2-column grid
}
