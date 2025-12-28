import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'pdf_special_characters.dart';

/// Centralized PDF icon pack service
///
/// Provides scalable vector icons for PDF templates.
/// Icons can be rendered as Unicode characters (with embedded fonts) or
/// as simple geometric shapes (universal compatibility).
///
/// Usage:
/// ```dart
/// final icons = PdfIconPack();
/// pw.Row(children: [
///   icons.email(size: 12, color: PdfColors.blue),
///   pw.SizedBox(width: 5),
///   pw.Text('contact@example.com'),
/// ])
/// ```
class PdfIconPack {
  // Private constructor - use singleton pattern
  PdfIconPack._();
  static final PdfIconPack _instance = PdfIconPack._();
  factory PdfIconPack() => _instance;

  final _chars = PdfSpecialCharacters();

  // ============================================================================
  // ICON RENDERING STRATEGY
  // ============================================================================

  /// Icon rendering strategy
  static IconStrategy _strategy = IconStrategy.unicode;

  /// Set icon rendering strategy
  static void setStrategy(IconStrategy strategy) {
    _strategy = strategy;
  }

  // ============================================================================
  // CONTACT ICONS
  // ============================================================================

  /// Email icon
  pw.Widget email({
    double size = 12,
    PdfColor? color,
  }) {
    return _buildIcon(
      unicode: _chars.email,
      shape: _buildEmailShape,
      size: size,
      color: color,
    );
  }

  /// Phone icon
  pw.Widget phone({
    double size = 12,
    PdfColor? color,
  }) {
    return _buildIcon(
      unicode: _chars.phone,
      shape: _buildPhoneShape,
      size: size,
      color: color,
    );
  }

  /// Location/Address icon
  pw.Widget location({
    double size = 12,
    PdfColor? color,
  }) {
    return _buildIcon(
      unicode: _chars.location,
      shape: _buildLocationShape,
      size: size,
      color: color,
    );
  }

  /// LinkedIn icon (using 'in' text)
  pw.Widget linkedin({
    double size = 12,
    PdfColor? color,
  }) {
    return _buildIcon(
      unicode: 'in',
      shape: (s, c) => _buildTextShape('in', s, c),
      size: size,
      color: color,
    );
  }

  /// GitHub icon (using 'gh' text)
  pw.Widget github({
    double size = 12,
    PdfColor? color,
  }) {
    return _buildIcon(
      unicode: 'gh',
      shape: (s, c) => _buildTextShape('gh', s, c),
      size: size,
      color: color,
    );
  }

  /// Website/Globe icon
  pw.Widget website({
    double size = 12,
    PdfColor? color,
  }) {
    return _buildIcon(
      unicode: '⊕',
      shape: _buildGlobeShape,
      size: size,
      color: color,
    );
  }

  // ============================================================================
  // EDUCATION ICONS
  // ============================================================================

  /// Education/Graduation cap icon
  pw.Widget education({
    double size = 12,
    PdfColor? color,
  }) {
    return _buildIcon(
      unicode: '🎓',
      shape: _buildEducationShape,
      size: size,
      color: color,
    );
  }

  /// Certificate icon
  pw.Widget certificate({
    double size = 12,
    PdfColor? color,
  }) {
    return _buildIcon(
      unicode: '📜',
      shape: _buildCertificateShape,
      size: size,
      color: color,
    );
  }

  // ============================================================================
  // WORK ICONS
  // ============================================================================

  /// Briefcase/Work icon
  pw.Widget work({
    double size = 12,
    PdfColor? color,
  }) {
    return _buildIcon(
      unicode: '💼',
      shape: _buildBriefcaseShape,
      size: size,
      color: color,
    );
  }

  /// Skills/Tools icon
  pw.Widget skills({
    double size = 12,
    PdfColor? color,
  }) {
    return _buildIcon(
      unicode: '⚙',
      shape: _buildGearsShape,
      size: size,
      color: color,
    );
  }

  /// Languages icon
  pw.Widget languages({
    double size = 12,
    PdfColor? color,
  }) {
    return _buildIcon(
      unicode: '🌐',
      shape: _buildLanguagesShape,
      size: size,
      color: color,
    );
  }

  // ============================================================================
  // COMMON ICONS
  // ============================================================================

  /// Checkmark icon
  pw.Widget checkmark({
    double size = 12,
    PdfColor? color,
  }) {
    return _buildIcon(
      unicode: _chars.checkmark,
      shape: _buildCheckmarkShape,
      size: size,
      color: color,
    );
  }

  /// Star icon
  pw.Widget star({
    double size = 12,
    PdfColor? color,
    bool filled = true,
  }) {
    return _buildIcon(
      unicode: filled ? _chars.star : _chars.starEmpty,
      shape: (s, c) => _buildStarShape(s, c, filled),
      size: size,
      color: color,
    );
  }

  /// Bullet point icon
  pw.Widget bullet({
    double size = 12,
    PdfColor? color,
  }) {
    return _buildIcon(
      unicode: _chars.bullet,
      shape: _buildBulletShape,
      size: size,
      color: color,
    );
  }

  /// Calendar/Date icon
  pw.Widget calendar({
    double size = 12,
    PdfColor? color,
  }) {
    return _buildIcon(
      unicode: '📅',
      shape: _buildCalendarShape,
      size: size,
      color: color,
    );
  }

  // ============================================================================
  // ICON BUILDER
  // ============================================================================

  /// Build icon using current strategy
  pw.Widget _buildIcon({
    required String unicode,
    required pw.Widget Function(double, PdfColor) shape,
    required double size,
    PdfColor? color,
  }) {
    final effectiveColor = color ?? PdfColors.black;

    switch (_strategy) {
      case IconStrategy.unicode:
        return pw.Text(
          unicode,
          style: pw.TextStyle(
            fontSize: size,
            color: effectiveColor,
          ),
        );
      case IconStrategy.shapes:
        return shape(size, effectiveColor);
    }
  }

  // ============================================================================
  // SHAPE BUILDERS
  // ============================================================================

  /// Build email envelope shape
  pw.Widget _buildEmailShape(double size, PdfColor color) {
    return _buildTextShape('@', size, color);
  }

  /// Build phone shape
  pw.Widget _buildPhoneShape(double size, PdfColor color) {
    return _buildTextShape('☎', size, color);
  }

  /// Build location pin shape
  pw.Widget _buildLocationShape(double size, PdfColor color) {
    return _buildTextShape('⌖', size, color);
  }

  /// Build globe/website shape
  pw.Widget _buildGlobeShape(double size, PdfColor color) {
    return _buildTextShape('⊕', size, color);
  }

  /// Build education/graduation cap shape
  pw.Widget _buildEducationShape(double size, PdfColor color) {
    return _buildTextShape('🎓', size, color);
  }

  /// Build certificate shape
  pw.Widget _buildCertificateShape(double size, PdfColor color) {
    return _buildTextShape('📜', size, color);
  }

  /// Build briefcase shape
  pw.Widget _buildBriefcaseShape(double size, PdfColor color) {
    return _buildTextShape('💼', size, color);
  }

  /// Build gears/skills shape
  pw.Widget _buildGearsShape(double size, PdfColor color) {
    return _buildTextShape('⚙', size, color);
  }

  /// Build languages/globe shape
  pw.Widget _buildLanguagesShape(double size, PdfColor color) {
    return _buildTextShape('🌐', size, color);
  }

  /// Build checkmark shape
  pw.Widget _buildCheckmarkShape(double size, PdfColor color) {
    return _buildTextShape('✓', size, color);
  }

  /// Build star shape
  pw.Widget _buildStarShape(double size, PdfColor color, bool filled) {
    return _buildTextShape(filled ? '★' : '☆', size, color);
  }

  /// Build bullet shape
  pw.Widget _buildBulletShape(double size, PdfColor color) {
    return _buildTextShape('•', size, color);
  }

  /// Build calendar shape
  pw.Widget _buildCalendarShape(double size, PdfColor color) {
    return _buildTextShape('📅', size, color);
  }

  /// Build text-based icon shape
  pw.Widget _buildTextShape(String text, double size, PdfColor color) {
    return pw.Text(
      text,
      style: pw.TextStyle(
        fontSize: size * 0.7,
        color: color,
        fontWeight: pw.FontWeight.bold,
      ),
    );
  }

  // ============================================================================
  // HELPER METHODS
  // ============================================================================

  /// Create a labeled icon (icon + text)
  pw.Widget labeled({
    required pw.Widget icon,
    required String text,
    pw.TextStyle? textStyle,
    double gap = 5,
  }) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.center,
      children: [
        icon,
        pw.SizedBox(width: gap),
        pw.Text(text, style: textStyle),
      ],
    );
  }

  /// Create a contact info row
  pw.Widget contactInfo({
    required String type,
    required String value,
    double iconSize = 12,
    PdfColor? iconColor,
    pw.TextStyle? textStyle,
  }) {
    final icon = switch (type.toLowerCase()) {
      'email' => email(size: iconSize, color: iconColor),
      'phone' => phone(size: iconSize, color: iconColor),
      'location' || 'address' => location(size: iconSize, color: iconColor),
      'linkedin' => linkedin(size: iconSize, color: iconColor),
      'github' => github(size: iconSize, color: iconColor),
      'website' => website(size: iconSize, color: iconColor),
      _ => bullet(size: iconSize, color: iconColor),
    };

    return labeled(
      icon: icon,
      text: value,
      textStyle: textStyle,
      gap: 5,
    );
  }

  /// Create a star rating widget
  pw.Widget rating({
    required int rating,
    int maxRating = 5,
    double size = 12,
    PdfColor? color,
  }) {
    return pw.Row(
      children: List.generate(maxRating, (index) {
        return star(
          size: size,
          color: color,
          filled: index < rating,
        );
      }),
    );
  }
}

/// Icon rendering strategy
enum IconStrategy {
  /// Use Unicode characters (requires embedded fonts with Unicode support)
  unicode,

  /// Use geometric shapes (universal compatibility, simpler appearance)
  shapes,
}
