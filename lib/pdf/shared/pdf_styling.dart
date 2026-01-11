import 'dart:math' as math;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../../models/template_style.dart';
import '../../models/template_customization.dart';

/// Centralized PDF styling configuration
///
/// Provides a single source of truth for all PDF styling values:
/// - HSL-based color manipulation for clean derivatives
/// - WCAG contrast validation
/// - Modular typography scale (1.25x ratio)
/// - 8px spacing grid system
/// - Semantic color and spacing tokens
class PdfStyling {
  PdfStyling({
    required this.style,
    TemplateCustomization? customization,
  }) : customization = customization ?? const TemplateCustomization();

  final TemplateStyle style;
  final TemplateCustomization customization;

  // ===========================================================================
  // COLOR PALETTE
  // ===========================================================================

  /// Accent color from style
  PdfColor get accent => PdfColor.fromInt(style.accentColor.toARGB32());

  /// Darker accent for emphasis (HSL-based)
  PdfColor get accentDark => darkenHsl(accent, 0.15);

  /// Lighter accent for subtle highlights (HSL-based)
  PdfColor get accentLight => lightenHsl(accent, 0.2);

  /// Very pale accent for backgrounds - theme-aware
  PdfColor get accentPale => isDark
      ? darkenHsl(accent, 0.6) // Dark: use darker accent
      : mixWithWhite(accent, 0.92); // Light: use very pale accent

  /// Saturated accent for emphasis
  PdfColor get accentVibrant => saturate(accent, 0.2);

  // Theme-aware colors
  bool get isDark => style.isDarkMode;

  PdfColor get background => isDark ? _darkGray : _white;
  PdfColor get textPrimary => isDark ? _white : _black;
  PdfColor get textSecondary => isDark ? _lightGrayText : _mediumGray;
  PdfColor get textMuted => isDark ? _mutedDark : _lightGray;
  PdfColor get headerBackground => _black;
  PdfColor get cardBackground => isDark ? _charcoal : _offWhite;
  PdfColor get divider => isDark ? _dividerDark : _paleGray;

  /// Skill tag background - theme aware
  PdfColor get skillTagBackground => isDark ? _charcoal : accentPale;

  /// Skill tag text - theme aware
  PdfColor get skillTagText => isDark ? _lightGrayText : textPrimary;

  /// Skill tag border - theme aware
  PdfColor get skillTagBorder => isDark ? _dividerDark : accent;

  /// Text color for header section (always white on black header)
  PdfColor get headerText => _white;

  /// Text color on accent-colored backgrounds (black for contrast)
  PdfColor get textOnAccent => _black;

  // Semantic colors
  PdfColor get success => const PdfColor.fromInt(0xFF4CAF50);
  PdfColor get warning => const PdfColor.fromInt(0xFFFF9800);
  PdfColor get error => const PdfColor.fromInt(0xFFF44336);
  PdfColor get info => const PdfColor.fromInt(0xFF2196F3);

  // Base color constants
  static const _black = PdfColor.fromInt(0xFF000000);
  static const _darkGray = PdfColor.fromInt(0xFF1A1A1A);
  static const _charcoal = PdfColor.fromInt(0xFF2D2D2D);
  static const _mediumGray = PdfColor.fromInt(0xFF4A4A4A);
  static const _lightGray = PdfColor.fromInt(0xFF757575);
  static const _paleGray = PdfColor.fromInt(0xFFE8E8E8);
  static const _offWhite = PdfColor.fromInt(0xFFF8F8F8);
  static const _white = PdfColor.fromInt(0xFFFFFFFF);

  // Dark mode specific colors (improved contrast)
  static const _lightGrayText =
      PdfColor.fromInt(0xFFE0E0E0); // Improved from CCCCCC
  static const _mutedDark =
      PdfColor.fromInt(0xFFAAAAAA); // Improved from 999999
  static const _dividerDark =
      PdfColor.fromInt(0xFF505050); // Improved from 444444

  // ===========================================================================
  // TYPOGRAPHY - Modular scale (1.25x ratio)
  // ===========================================================================

  double get _fontScale => customization.fontSizeScale;

  // Heading sizes (modular scale 1.25x from 10pt base)
  double get fontSizeH1 => 24 * _fontScale; // 24pt
  double get fontSizeH2 => 19 * _fontScale; // 19pt
  double get fontSizeH3 => 15 * _fontScale; // 15pt
  double get fontSizeH4 => 12 * _fontScale; // 12pt

  // Body sizes
  double get fontSizeBody =>
      11 * _fontScale; // 11pt - more readable on printed A4
  double get fontSizeSmall => 9 * _fontScale; // 9pt
  double get fontSizeTiny => 8 * _fontScale; // 8pt

  // Letter spacing scale
  double get letterSpacingTight => -0.5;
  double get letterSpacingNormal => 0.0;
  double get letterSpacingRelaxed => 0.5;
  double get letterSpacingWide => 1.0;
  double get letterSpacingExtraWide => 1.5;

  // Context-specific line heights
  double get lineHeightTight => 1.2; // Headers
  double get lineHeightNormal => 1.4; // Body text
  double get lineHeightRelaxed => 1.6; // Paragraphs

  // Deprecated (use context-specific)
  @Deprecated('Use lineHeightNormal, lineHeightTight, or lineHeightRelaxed')
  double get lineHeight => customization.lineHeight;

  // ===========================================================================
  // SPACING - 8px grid system
  // ===========================================================================

  double get _spaceScale => customization.spacingScale;

  // Base spacing units (8px grid)
  double get space1 => 4 * _spaceScale; // 4px
  double get space2 => 8 * _spaceScale; // 8px
  double get space3 => 12 * _spaceScale; // 12px
  double get space4 => 16 * _spaceScale; // 16px
  double get space5 => 20 * _spaceScale; // 20px
  double get space6 => 24 * _spaceScale; // 24px
  double get space8 => 32 * _spaceScale; // 32px
  double get space10 => 40 * _spaceScale; // 40px
  double get space12 => 48 * _spaceScale; // 48px
  double get space16 => 64 * _spaceScale; // 64px

  // Semantic section spacing (hierarchical)
  double get sectionGapMajor => 32 * _spaceScale; // Between major sections
  double get sectionGapMinor => 20 * _spaceScale; // Between minor sections
  double get itemGap => 16 * _spaceScale; // Between list items
  double get paragraphGap => 12 * _spaceScale; // Between paragraphs;

  // ===========================================================================
  // MARGINS - Based on marginPreset
  // ===========================================================================

  pw.EdgeInsets get pageMargins {
    final preset = customization.marginPreset;
    return pw.EdgeInsets.fromLTRB(
      preset.leftMargin,
      preset.topMargin,
      preset.rightMargin,
      preset.bottomMargin,
    );
  }

  // Semantic padding tokens
  pw.EdgeInsets get cardPadding => pw.EdgeInsets.all(space4);
  pw.EdgeInsets get sectionPadding => pw.EdgeInsets.all(space6);
  pw.EdgeInsets get compactPadding => pw.EdgeInsets.all(space3);
  pw.EdgeInsets get relaxedPadding => pw.EdgeInsets.all(space8);

  // ===========================================================================
  // LAYOUT HELPERS
  // ===========================================================================

  /// Build a styled section header with accent line
  pw.Widget buildSectionHeader(String title) {
    final displayTitle =
        customization.uppercaseHeaders ? title.toUpperCase() : title;

    return pw.Container(
      margin: pw.EdgeInsets.only(bottom: space4),
      child: pw.Row(
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
          pw.SizedBox(width: space3),
          // Title
          pw.Text(
            displayTitle,
            style: pw.TextStyle(
              fontSize: fontSizeH2,
              fontWeight: pw.FontWeight.bold,
              color: textPrimary,
              letterSpacing: letterSpacingWide,
            ),
          ),
          pw.SizedBox(width: space3),
          // Extending line
          pw.Expanded(
            child: pw.Container(
              height: 2.5,
              decoration: pw.BoxDecoration(
                color: accent,
                borderRadius: pw.BorderRadius.circular(1.25),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Build a divider line (respects showDividers setting)
  pw.Widget buildDivider() {
    if (!customization.showDividers) {
      return pw.SizedBox(height: space3);
    }
    return pw.Container(
      margin: pw.EdgeInsets.symmetric(vertical: space3),
      height: 1,
      color: divider,
    );
  }

  /// Build an accent badge with text
  pw.Widget buildAccentBadge(String text, {bool dark = false}) {
    return pw.Container(
      padding: pw.EdgeInsets.symmetric(
        horizontal: space3,
        vertical: space1,
      ),
      decoration: pw.BoxDecoration(
        color: dark ? accentDark : accent,
        borderRadius: pw.BorderRadius.circular(3),
      ),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: fontSizeSmall,
          fontWeight: pw.FontWeight.bold,
          color: _black,
          letterSpacing: letterSpacingNormal,
        ),
      ),
    );
  }

  /// Build a bullet point with accent color
  pw.Widget buildBulletPoint(String text) {
    return pw.Padding(
      padding: pw.EdgeInsets.only(bottom: space2),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Padding(
            padding: pw.EdgeInsets.only(top: 4),
            child: pw.Transform.rotate(
              angle: 0.785398, // 45 degrees - diamond shape
              child: pw.Container(
                width: 4,
                height: 4,
                decoration: pw.BoxDecoration(
                  color: accent,
                  borderRadius: pw.BorderRadius.circular(0.5),
                ),
              ),
            ),
          ),
          pw.SizedBox(width: space3),
          pw.Expanded(
            child: pw.Text(
              text,
              style: pw.TextStyle(
                fontSize: fontSizeBody,
                color: textSecondary,
                lineSpacing: lineHeightNormal,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Build a skill tag
  pw.Widget buildSkillTag(String skill) {
    return pw.Container(
      margin: pw.EdgeInsets.only(right: space2, bottom: space2),
      padding: pw.EdgeInsets.symmetric(
        horizontal: space3,
        vertical: space1,
      ),
      decoration: pw.BoxDecoration(
        color: skillTagBackground,
        border: pw.Border.all(color: skillTagBorder, width: 0.5),
        borderRadius: pw.BorderRadius.circular(4),
      ),
      child: pw.Text(
        skill,
        style: pw.TextStyle(
          fontSize: fontSizeSmall,
          color: skillTagText,
          fontWeight: pw.FontWeight.normal,
        ),
      ),
    );
  }

  /// Build contact badge with icon
  pw.Widget buildContactBadge(String icon, String text) {
    if (!customization.showContactIcons) {
      return pw.Text(
        text,
        style: pw.TextStyle(fontSize: fontSizeSmall, color: _white),
      );
    }

    return pw.Row(
      mainAxisSize: pw.MainAxisSize.min,
      children: [
        pw.Container(
          width: 20,
          height: 20,
          decoration: pw.BoxDecoration(
            color: accent,
            shape: pw.BoxShape.circle,
          ),
          child: pw.Center(
            child: pw.Text(
              icon,
              style: pw.TextStyle(
                fontSize: fontSizeTiny,
                fontWeight: pw.FontWeight.bold,
                color: _black,
              ),
            ),
          ),
        ),
        pw.SizedBox(width: space2),
        pw.Text(
          text,
          style: pw.TextStyle(
            fontSize: fontSizeSmall,
            color: _white,
          ),
        ),
      ],
    );
  }

  // ===========================================================================
  // COLOR UTILITIES - HSL-based manipulation
  // ===========================================================================

  /// Darken a color using HSL manipulation (preserves hue and saturation)
  PdfColor darkenHsl(PdfColor color, double amount) {
    final hsl = _rgbToHsl(color);
    final newLightness = (hsl[2] - amount).clamp(0.0, 1.0);
    return _hslToRgb(hsl[0], hsl[1], newLightness);
  }

  /// Lighten a color using HSL manipulation (preserves hue and saturation)
  PdfColor lightenHsl(PdfColor color, double amount) {
    final hsl = _rgbToHsl(color);
    final newLightness = (hsl[2] + amount).clamp(0.0, 1.0);
    return _hslToRgb(hsl[0], hsl[1], newLightness);
  }

  /// Saturate a color (increase color intensity)
  PdfColor saturate(PdfColor color, double amount) {
    final hsl = _rgbToHsl(color);
    final newSaturation = (hsl[1] + amount).clamp(0.0, 1.0);
    return _hslToRgb(hsl[0], newSaturation, hsl[2]);
  }

  /// Mix color with white
  PdfColor mixWithWhite(PdfColor color, double whiteness) {
    return PdfColor(
      color.red + (1 - color.red) * whiteness,
      color.green + (1 - color.green) * whiteness,
      color.blue + (1 - color.blue) * whiteness,
    );
  }

  /// Calculate WCAG contrast ratio between two colors
  double getContrastRatio(PdfColor fg, PdfColor bg) {
    final l1 = _getLuminance(fg);
    final l2 = _getLuminance(bg);
    final lighter = math.max(l1, l2);
    final darker = math.min(l1, l2);
    return (lighter + 0.05) / (darker + 0.05);
  }

  /// Check if color combination meets WCAG AA standard (4.5:1 for normal text)
  bool meetsWcagAa(PdfColor fg, PdfColor bg, {bool largeText = false}) {
    final ratio = getContrastRatio(fg, bg);
    return largeText ? ratio >= 3.0 : ratio >= 4.5;
  }

  /// Check if color combination meets WCAG AAA standard (7:1 for normal text)
  bool meetsWcagAaa(PdfColor fg, PdfColor bg, {bool largeText = false}) {
    final ratio = getContrastRatio(fg, bg);
    return largeText ? ratio >= 4.5 : ratio >= 7.0;
  }

  // ===========================================================================
  // PRIVATE COLOR CONVERSION UTILITIES
  // ===========================================================================

  /// Convert RGB to HSL
  List<double> _rgbToHsl(PdfColor color) {
    final r = color.red;
    final g = color.green;
    final b = color.blue;

    final max = math.max(r, math.max(g, b));
    final min = math.min(r, math.min(g, b));
    final delta = max - min;

    double h = 0;
    double s = 0;
    final l = (max + min) / 2;

    if (delta != 0) {
      s = l > 0.5 ? delta / (2 - max - min) : delta / (max + min);

      if (max == r) {
        h = ((g - b) / delta + (g < b ? 6 : 0)) / 6;
      } else if (max == g) {
        h = ((b - r) / delta + 2) / 6;
      } else {
        h = ((r - g) / delta + 4) / 6;
      }
    }

    return [h, s, l];
  }

  /// Convert HSL to RGB
  PdfColor _hslToRgb(double h, double s, double l) {
    double r, g, b;

    if (s == 0) {
      r = g = b = l;
    } else {
      final q = l < 0.5 ? l * (1 + s) : l + s - l * s;
      final p = 2 * l - q;
      r = _hueToRgb(p, q, h + 1 / 3);
      g = _hueToRgb(p, q, h);
      b = _hueToRgb(p, q, h - 1 / 3);
    }

    return PdfColor(r, g, b);
  }

  /// Helper for HSL to RGB conversion
  double _hueToRgb(double p, double q, double t) {
    double tNorm = t;
    if (t < 0) tNorm += 1;
    if (t > 1) tNorm -= 1;
    if (tNorm < 1 / 6) return p + (q - p) * 6 * tNorm;
    if (tNorm < 1 / 2) return q;
    if (tNorm < 2 / 3) return p + (q - p) * (2 / 3 - tNorm) * 6;
    return p;
  }

  /// Calculate relative luminance for WCAG contrast
  double _getLuminance(PdfColor color) {
    final r = _sRgbToLinear(color.red);
    final g = _sRgbToLinear(color.green);
    final b = _sRgbToLinear(color.blue);
    return 0.2126 * r + 0.7152 * g + 0.0722 * b;
  }

  /// Convert sRGB to linear RGB for luminance calculation
  double _sRgbToLinear(double channel) {
    if (channel <= 0.03928) {
      return channel / 12.92;
    }
    return math.pow((channel + 0.055) / 1.055, 2.4).toDouble();
  }
}
