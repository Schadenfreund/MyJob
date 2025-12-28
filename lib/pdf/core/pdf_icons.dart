import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

/// Professional icon system for PDFs using simple shapes and text
/// All icons render reliably across all PDF viewers
class PdfIcons {
  /// Create a circular icon container with a text symbol inside
  static pw.Widget circularIcon({
    required String symbol,
    required pw.Font font,
    required PdfColor backgroundColor,
    required PdfColor iconColor,
    double size = 40,
    double iconSize = 20,
  }) {
    return pw.Container(
      width: size,
      height: size,
      decoration: pw.BoxDecoration(
        color: backgroundColor,
        shape: pw.BoxShape.circle,
      ),
      child: pw.Center(
        child: pw.Text(
          symbol,
          style: pw.TextStyle(
            font: font,
            fontSize: iconSize,
            color: iconColor,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
      ),
    );
  }

  /// Create a simple text-based icon (single character)
  static pw.Widget textIcon({
    required String symbol,
    required pw.Font font,
    required PdfColor color,
    double size = 16,
    pw.FontWeight? weight,
  }) {
    return pw.Text(
      symbol,
      style: pw.TextStyle(
        font: font,
        fontSize: size,
        color: color,
        fontWeight: weight ?? pw.FontWeight.bold,
      ),
    );
  }

  /// Create an icon with text label (horizontal layout)
  static pw.Widget iconWithText({
    required String icon,
    required String text,
    required pw.Font font,
    required PdfColor iconColor,
    required PdfColor textColor,
    double iconSize = 14,
    double textSize = 11,
    double spacing = 8,
  }) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.center,
      children: [
        textIcon(
          symbol: icon,
          font: font,
          color: iconColor,
          size: iconSize,
        ),
        pw.SizedBox(width: spacing),
        pw.Expanded(
          child: pw.Text(
            text,
            style: pw.TextStyle(
              font: font,
              fontSize: textSize,
              color: textColor,
            ),
          ),
        ),
      ],
    );
  }

  /// Create a simple bullet point icon
  static pw.Widget bulletIcon({
    required PdfColor color,
    double size = 8,
    BulletStyle style = BulletStyle.circle,
  }) {
    switch (style) {
      case BulletStyle.circle:
        return pw.Container(
          width: size,
          height: size,
          decoration: pw.BoxDecoration(
            color: color,
            shape: pw.BoxShape.circle,
          ),
        );
      case BulletStyle.square:
        return pw.Container(
          width: size,
          height: size,
          decoration: pw.BoxDecoration(
            color: color,
            borderRadius: pw.BorderRadius.circular(size * 0.1),
          ),
        );
      case BulletStyle.diamond:
        return pw.Transform.rotate(
          angle: 0.785398, // 45 degrees in radians
          child: pw.Container(
            width: size * 0.7,
            height: size * 0.7,
            decoration: pw.BoxDecoration(
              color: color,
              borderRadius: pw.BorderRadius.circular(size * 0.1),
            ),
          ),
        );
      case BulletStyle.chevron:
        // For chevron, use a simple arrow text symbol
        return pw.Container(
          width: size,
          height: size,
          child: pw.Center(
            child: pw.Text(
              '>',  // ASCII-safe chevron
              style: pw.TextStyle(
                fontSize: size * 1.2,
                color: color,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          ),
        );
    }
  }

  /// Create a skill level bar
  static pw.Widget skillRating({
    required double level, // 0.0 to 1.0
    required PdfColor activeColor,
    required PdfColor inactiveColor,
    double width = 150,
    double height = 8,
  }) {
    return pw.Stack(
      children: [
        // Background bar
        pw.Container(
          width: width,
          height: height,
          decoration: pw.BoxDecoration(
            color: inactiveColor,
            borderRadius: pw.BorderRadius.circular(height / 2),
          ),
        ),
        // Active bar
        pw.Container(
          width: width * level.clamp(0.0, 1.0),
          height: height,
          decoration: pw.BoxDecoration(
            color: activeColor,
            borderRadius: pw.BorderRadius.circular(height / 2),
          ),
        ),
      ],
    );
  }

  /// Create star rating display (using text stars)
  static pw.Widget starRating({
    required double rating, // 0.0 to 5.0
    required pw.Font font,
    required PdfColor activeColor,
    required PdfColor inactiveColor,
    double size = 12,
    double spacing = 2,
  }) {
    final fullStars = rating.floor();
    final hasHalfStar = (rating - fullStars) >= 0.5;
    final emptyStars = 5 - fullStars - (hasHalfStar ? 1 : 0);

    return pw.Row(
      mainAxisSize: pw.MainAxisSize.min,
      children: [
        // Full stars (ASCII-safe)
        ...List.generate(
          fullStars,
          (_) => pw.Padding(
            padding: pw.EdgeInsets.only(right: spacing),
            child: textIcon(
              symbol: '*',  // ASCII star
              font: font,
              color: activeColor,
              size: size,
            ),
          ),
        ),
        // Half star (ASCII-safe)
        if (hasHalfStar)
          pw.Padding(
            padding: pw.EdgeInsets.only(right: spacing),
            child: textIcon(
              symbol: '+',  // ASCII plus for half
              font: font,
              color: activeColor,
              size: size,
            ),
          ),
        // Empty stars (ASCII-safe)
        ...List.generate(
          emptyStars,
          (_) => pw.Padding(
            padding: pw.EdgeInsets.only(right: spacing),
            child: textIcon(
              symbol: 'o',  // ASCII circle for empty
              font: font,
              color: inactiveColor,
              size: size,
            ),
          ),
        ),
      ],
    );
  }

  /// Create a badge/tag container
  static pw.Widget badge({
    required String text,
    required pw.Font font,
    required PdfColor backgroundColor,
    required PdfColor textColor,
    double fontSize = 10,
    pw.EdgeInsets? padding,
  }) {
    return pw.Container(
      padding: padding ?? const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: pw.BoxDecoration(
        color: backgroundColor,
        borderRadius: pw.BorderRadius.circular(4),
      ),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          font: font,
          fontSize: fontSize,
          color: textColor,
          fontWeight: pw.FontWeight.bold,
        ),
      ),
    );
  }

  /// Create a section header with decorative element
  static pw.Widget sectionHeader({
    required String title,
    required pw.Font font,
    required PdfColor color,
    required PdfColor accentColor,
    double fontSize = 16,
    HeaderStyle style = HeaderStyle.underline,
  }) {
    switch (style) {
      case HeaderStyle.underline:
        return pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              title.toUpperCase(),
              style: pw.TextStyle(
                font: font,
                fontSize: fontSize,
                color: color,
                fontWeight: pw.FontWeight.bold,
                letterSpacing: 1.2,
              ),
            ),
            pw.SizedBox(height: 4),
            pw.Container(
              width: 40,
              height: 2,
              color: accentColor,
            ),
          ],
        );
      case HeaderStyle.fullLine:
        return pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              title.toUpperCase(),
              style: pw.TextStyle(
                font: font,
                fontSize: fontSize,
                color: color,
                fontWeight: pw.FontWeight.bold,
                letterSpacing: 1.2,
              ),
            ),
            pw.SizedBox(height: 4),
            pw.Container(
              width: double.infinity,
              height: 2,
              color: accentColor,
            ),
          ],
        );
      case HeaderStyle.leftBar:
        return pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.center,
          children: [
            pw.Container(
              width: 4,
              height: fontSize * 1.5,
              color: accentColor,
            ),
            pw.SizedBox(width: 12),
            pw.Text(
              title.toUpperCase(),
              style: pw.TextStyle(
                font: font,
                fontSize: fontSize,
                color: color,
                fontWeight: pw.FontWeight.bold,
                letterSpacing: 1.2,
              ),
            ),
          ],
        );
      case HeaderStyle.badge:
        return pw.Container(
          padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: pw.BoxDecoration(
            color: accentColor,
            borderRadius: pw.BorderRadius.circular(4),
          ),
          child: pw.Text(
            title.toUpperCase(),
            style: pw.TextStyle(
              font: font,
              fontSize: fontSize,
              color: PdfColors.black,
              fontWeight: pw.FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
        );
    }
  }
}

/// Bullet style options
enum BulletStyle {
  circle,
  square,
  diamond,
  chevron,
}

/// Header style options
enum HeaderStyle {
  underline,
  fullLine,
  leftBar,
  badge,
}

/// Simple text-based icon set (ASCII safe for Helvetica font - always renders)
class SimpleIcons {
  // Contact icons using symbols
  static const String email = '@';
  static const String phone = '#';
  static const String location = '*';
  static const String web = '~';
  static const String link = '>';

  // Professional icons
  static const String work = '^';
  static const String education = '=';
  static const String certificate = '+';
  static const String skills = '*';
  static const String language = '>';

  // General purpose (ASCII-safe - works with Helvetica)
  static const String bullet = '-';
  static const String chevron = '>';
  static const String arrow = '->';
  static const String check = 'x';
  static const String star = '*';
  static const String starEmpty = 'o';
  static const String circle = 'o';
  static const String circleFilled = 'O';
  static const String dot = '.';
  static const String square = '[ ]';
  static const String squareFilled = '[X]';

  // Decorative
  static const String diamond = '*';
  static const String triangleRight = '>';
  static const String triangleUp = '^';
  static const String hexagon = 'O';
}

/// Icon set configuration for templates
class IconSet {
  const IconSet({
    required this.email,
    required this.phone,
    required this.location,
    required this.web,
    required this.work,
    required this.education,
    required this.skills,
    required this.bullet,
  });

  final String email;
  final String phone;
  final String location;
  final String web;
  final String work;
  final String education;
  final String skills;
  final String bullet;

  /// Electric template icon set (clean and modern)
  static const electric = IconSet(
    email: SimpleIcons.email,
    phone: SimpleIcons.phone,
    location: SimpleIcons.location,
    web: SimpleIcons.web,
    work: SimpleIcons.circleFilled,
    education: SimpleIcons.squareFilled,
    skills: SimpleIcons.diamond,
    bullet: SimpleIcons.chevron,
  );

  /// Minimal template icon set (very clean)
  static const minimal = IconSet(
    email: SimpleIcons.email,
    phone: SimpleIcons.phone,
    location: SimpleIcons.location,
    web: SimpleIcons.web,
    work: SimpleIcons.bullet,
    education: SimpleIcons.bullet,
    skills: SimpleIcons.bullet,
    bullet: SimpleIcons.dot,
  );

  /// Professional template icon set (traditional)
  static const professional = IconSet(
    email: SimpleIcons.email,
    phone: SimpleIcons.phone,
    location: SimpleIcons.location,
    web: SimpleIcons.web,
    work: SimpleIcons.triangleRight,
    education: SimpleIcons.triangleRight,
    skills: SimpleIcons.check,
    bullet: SimpleIcons.arrow,
  );
}
