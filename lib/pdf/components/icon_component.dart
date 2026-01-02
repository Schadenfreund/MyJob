import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../shared/pdf_icons.dart';
import '../shared/pdf_styling.dart';

/// Icon Component - Wrapper for icon rendering with preset sizes and themes
///
/// Provides high-level icon rendering with consistent sizing and styling
/// across all PDF templates.
class IconComponent {
  IconComponent._();

  /// Render a contact icon with text
  ///
  /// Automatically selects the appropriate icon based on type:
  /// - 'email': Email icon
  /// - 'phone': Phone icon
  /// - 'location': Location/address icon
  /// - 'web': Website/globe icon
  /// - 'linkedin': LinkedIn icon
  /// - 'github': GitHub icon
  static pw.Widget contact({
    required String type,
    required String text,
    required PdfStyling styling,
    IconSize size = IconSize.medium,
    ContactIconStyle style = ContactIconStyle.inline,
  }) {
    final iconSize = size.value;
    final icon = _getContactIcon(type, styling.accent, iconSize);

    switch (style) {
      case ContactIconStyle.inline:
        // Icon and text side by side
        return pw.Row(
          mainAxisSize: pw.MainAxisSize.min,
          crossAxisAlignment: pw.CrossAxisAlignment.center,
          children: [
            icon,
            pw.SizedBox(width: styling.space2),
            pw.Text(
              text,
              style: pw.TextStyle(
                fontSize: styling.fontSizeSmall,
                color: styling.textSecondary,
              ),
            ),
          ],
        );

      case ContactIconStyle.badge:
        // Icon in colored circle with text
        return pw.Row(
          mainAxisSize: pw.MainAxisSize.min,
          crossAxisAlignment: pw.CrossAxisAlignment.center,
          children: [
            pw.Container(
              width: iconSize + 4,
              height: iconSize + 4,
              decoration: pw.BoxDecoration(
                color: styling.accent,
                shape: pw.BoxShape.circle,
              ),
              child: pw.Center(child: icon),
            ),
            pw.SizedBox(width: styling.space2),
            pw.Text(
              text,
              style: pw.TextStyle(
                fontSize: styling.fontSizeSmall,
                color: styling.textSecondary,
              ),
            ),
          ],
        );

      case ContactIconStyle.iconOnly:
        // Just the icon
        return icon;
    }
  }

  /// Render a bullet point
  ///
  /// Provides different bullet styles for lists and sections.
  static pw.Widget bullet({
    required PdfStyling styling,
    BulletStyle style = BulletStyle.dot,
    double? customSize,
  }) {
    final size = customSize ?? 5.0;

    switch (style) {
      case BulletStyle.dot:
        return PdfIcons.bullet(color: styling.accent, size: size);

      case BulletStyle.diamond:
        return pw.Transform.rotate(
          angle: 0.785398, // 45 degrees in radians
          child: pw.Container(
            width: size,
            height: size,
            color: styling.accent,
          ),
        );

      case BulletStyle.square:
        return pw.Container(
          width: size,
          height: size,
          decoration: pw.BoxDecoration(
            color: styling.accent,
            borderRadius: pw.BorderRadius.circular(1),
          ),
        );

      case BulletStyle.chevron:
        return PdfIcons.arrowRight(color: styling.accent, size: size * 1.5);

      case BulletStyle.accentBar:
        return PdfIcons.accentBar(
          color: styling.accent,
          width: 3,
          height: size * 2,
        );
    }
  }

  /// Render a badge with icon and text
  ///
  /// Used for skill tags, certifications, or any labeled items.
  static pw.Widget badge({
    required String iconType,
    required String text,
    required PdfStyling styling,
    BadgeStyle style = BadgeStyle.outlined,
  }) {
    final icon = _getIconByType(iconType, styling.accent, 12);

    switch (style) {
      case BadgeStyle.outlined:
        return pw.Container(
          padding: pw.EdgeInsets.symmetric(
            horizontal: styling.space3,
            vertical: styling.space2,
          ),
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: styling.accent, width: 1),
            borderRadius: pw.BorderRadius.circular(4),
          ),
          child: pw.Row(
            mainAxisSize: pw.MainAxisSize.min,
            children: [
              icon,
              pw.SizedBox(width: styling.space2),
              pw.Text(
                text,
                style: pw.TextStyle(
                  fontSize: styling.fontSizeSmall,
                  color: styling.textPrimary,
                ),
              ),
            ],
          ),
        );

      case BadgeStyle.filled:
        return pw.Container(
          padding: pw.EdgeInsets.symmetric(
            horizontal: styling.space3,
            vertical: styling.space2,
          ),
          decoration: pw.BoxDecoration(
            color: styling.accent.flatten(),
            borderRadius: pw.BorderRadius.circular(4),
          ),
          child: pw.Row(
            mainAxisSize: pw.MainAxisSize.min,
            children: [
              _getIconByType(iconType, styling.textOnAccent, 12),
              pw.SizedBox(width: styling.space2),
              pw.Text(
                text,
                style: pw.TextStyle(
                  fontSize: styling.fontSizeSmall,
                  color: styling.textOnAccent,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ],
          ),
        );

      case BadgeStyle.minimal:
        return pw.Row(
          mainAxisSize: pw.MainAxisSize.min,
          children: [
            icon,
            pw.SizedBox(width: styling.space2),
            pw.Text(
              text,
              style: pw.TextStyle(
                fontSize: styling.fontSizeSmall,
                color: styling.textSecondary,
              ),
            ),
          ],
        );
    }
  }

  /// Render a section icon
  ///
  /// Used for section headers with appropriate sizing.
  static pw.Widget sectionIcon({
    required String iconType,
    required PdfStyling styling,
    IconSize size = IconSize.medium,
  }) {
    return _getIconByType(iconType, styling.accent, size.value);
  }

  /// Get contact icon by type
  static pw.Widget _getContactIcon(String type, PdfColor color, double size) {
    switch (type.toLowerCase()) {
      case 'email':
        return PdfIcons.email(color: color, size: size);
      case 'phone':
        return PdfIcons.phone(color: color, size: size);
      case 'location':
      case 'address':
        return PdfIcons.location(color: color, size: size);
      case 'web':
      case 'website':
        return PdfIcons.web(color: color, size: size);
      case 'linkedin':
        return PdfIcons.linkedin(color: color, size: size);
      case 'github':
        return PdfIcons.github(color: color, size: size);
      default:
        return PdfIcons.web(color: color, size: size);
    }
  }

  /// Get icon by general type (for sections, badges, etc.)
  static pw.Widget _getIconByType(String type, PdfColor color, double size) {
    switch (type.toLowerCase()) {
      // Contact icons
      case 'email':
        return PdfIcons.email(color: color, size: size);
      case 'phone':
        return PdfIcons.phone(color: color, size: size);
      case 'location':
        return PdfIcons.location(color: color, size: size);
      case 'web':
        return PdfIcons.web(color: color, size: size);
      case 'linkedin':
        return PdfIcons.linkedin(color: color, size: size);
      case 'github':
        return PdfIcons.github(color: color, size: size);

      // Document icons
      case 'work':
      case 'experience':
        return PdfIcons.work(color: color, size: size);
      case 'school':
      case 'education':
        return PdfIcons.school(color: color, size: size);
      case 'certificate':
      case 'award':
        return PdfIcons.certificate(color: color, size: size);
      case 'person':
        return PdfIcons.person(color: color, size: size);
      case 'profile':
      case 'summary':
      case 'about':
        return PdfIcons.person(color: color, size: size); // user-4
      case 'document':
        return PdfIcons.document(color: color, size: size);

      // Skills/tech icons
      case 'code':
      case 'programming':
        return PdfIcons.code(color: color, size: size);
      case 'skills':
        return PdfIcons.lightbulb(
            color: color, size: size); // Lightbulb for skills
      case 'design':
        return PdfIcons.design(color: color, size: size);
      case 'language':
        return PdfIcons.language(color: color, size: size);
      case 'tool':
        return PdfIcons.tool(color: color, size: size);
      case 'cog':
      case 'settings':
        return PdfIcons.cog(color: color, size: size);
      case 'target':
      case 'goal':
        return PdfIcons.target(color: color, size: size);
      case 'rocket':
        return PdfIcons.rocket(color: color, size: size);

      // UI icons
      case 'calendar':
      case 'date':
        return PdfIcons.calendar(color: color, size: size);
      case 'star':
        return PdfIcons.star(color: color, size: size);
      case 'flag':
        return PdfIcons.flag(color: color, size: size);
      case 'check':
        return PdfIcons.checkCircle(color: color, size: size);
      case 'arrow':
        return PdfIcons.arrowRight(color: color, size: size);

      default:
        return PdfIcons.bullet(color: color, size: size);
    }
  }
}

/// Icon sizes for consistent sizing
enum IconSize {
  small(16), // Increased from 12
  medium(20), // Increased from 16
  large(24), // Increased from 20
  xlarge(32); // Increased from 24

  const IconSize(this.value);
  final double value;
}

/// Bullet styles for lists
enum BulletStyle {
  dot,
  diamond,
  square,
  chevron,
  accentBar,
}

/// Contact icon styles
enum ContactIconStyle {
  inline, // Icon and text side by side
  badge, // Icon in colored circle
  iconOnly, // Just the icon
}

/// Badge styles for labels and tags
enum BadgeStyle {
  outlined, // Border with no background
  filled, // Solid background
  minimal, // No decoration, just icon+text
}
