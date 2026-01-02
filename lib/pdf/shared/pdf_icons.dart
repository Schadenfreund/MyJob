import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

/// PDF Icon System using Lineicons font
///
/// Uses the Lineicons icon font for clean, professional icons.
/// Icons are rendered as text using the Lineicons TTF font.
///
/// See: https://lineicons.com/icons for the full icon library
class PdfIcons {
  PdfIcons._();

  static pw.Font? _iconFont;

  /// Load the Lineicons font (call once at startup)
  static Future<void> loadFont() async {
    if (_iconFont != null) return;

    try {
      final bytes =
          await rootBundle.load('assets/fonts/Lineicons/Lineicons.ttf');
      _iconFont = pw.Font.ttf(bytes);
    } catch (e) {
      // Font not available, will use fallback
      _iconFont = null;
    }
  }

  /// Check if icon font is loaded
  static bool get isLoaded => _iconFont != null;

  // ===========================================================================
  // ICON CODES (from lineicons.css)
  // ===========================================================================

  // Contact icons
  static const String _envelope = '\uEACD'; // lni-envelope-1
  static const String _phone = '\uEB92'; // lni-phone
  static const String _location = '\uEB4C'; // lni-location-1
  static const String _globe = '\uEB0C'; // lni-globe-2
  static const String _linkedin = '\uEB4D'; // lni-linkedin
  static const String _github = '\uEB05'; // lni-github

  // Section icons
  static const String _briefcase = '\uEA51'; // lni-briefcase-1
  static const String _graduationCap = '\uEB09'; // lni-graduation-cap
  static const String _certificate = '\uEA82'; // lni-certificate
  static const String _user = '\uEC2E'; // lni-user-4 (correct code)
  static const String _file = '\uEADE'; // lni-file-multiple
  static const String _code = '\uEA8C'; // lni-code-1
  static const String _palette = '\uEB86'; // lni-paint-bucket
  static const String _comment = '\uEB59'; // lni-message-2
  static const String _wrench = '\uEC5D'; // lni-wrench

  // Additional section icons
  static const String _cog = '\uEA92'; // lni-cog
  static const String _lightbulb = '\uEB41'; // lni-lightbulb-alt
  static const String _rocket = '\uEBC7'; // lni-rocket-4
  static const String _quote = '\uEBB4'; // lni-quote-alt-1
  static const String _target = '\uEC09'; // lni-target-2
  static const String _pencil = '\uEB89'; // lni-pencil-alt-1
  static const String _userAlt = '\uEC25'; // lni-user-1 (simpler user)
  static const String _handShake = '\uEB15'; // lni-handshake

  // UI icons
  static const String _calendar = '\uEA5F'; // lni-calendar-2
  static const String _star = '\uEBF3'; // lni-star-fat
  static const String _flag = '\uEAE7'; // lni-flag-1
  static const String _checkCircle = '\uEA85'; // lni-check-circle-1
  static const String _arrowRight = '\uEA2A'; // lni-arrow-right

  // ===========================================================================
  // CONTACT ICONS
  // ===========================================================================

  /// Email icon
  static pw.Widget email({required PdfColor color, double size = 16}) {
    return _icon(_envelope, color, size);
  }

  /// Phone icon
  static pw.Widget phone({required PdfColor color, double size = 16}) {
    return _icon(_phone, color, size);
  }

  /// Location/address icon
  static pw.Widget location({required PdfColor color, double size = 16}) {
    return _icon(_location, color, size);
  }

  /// Website/globe icon
  static pw.Widget web({required PdfColor color, double size = 16}) {
    return _icon(_globe, color, size);
  }

  /// LinkedIn icon
  static pw.Widget linkedin({required PdfColor color, double size = 16}) {
    return _icon(_linkedin, color, size);
  }

  /// GitHub icon
  static pw.Widget github({required PdfColor color, double size = 16}) {
    return _icon(_github, color, size);
  }

  // ===========================================================================
  // SECTION ICONS
  // ===========================================================================

  /// Work/briefcase icon
  static pw.Widget work({required PdfColor color, double size = 16}) {
    return _icon(_briefcase, color, size);
  }

  /// Education/graduation cap icon
  static pw.Widget school({required PdfColor color, double size = 16}) {
    return _icon(_graduationCap, color, size);
  }

  /// Certificate/award icon
  static pw.Widget certificate({required PdfColor color, double size = 16}) {
    return _icon(_certificate, color, size);
  }

  /// Person/profile icon
  static pw.Widget person({required PdfColor color, double size = 16}) {
    return _icon(_user, color, size);
  }

  /// Document icon
  static pw.Widget document({required PdfColor color, double size = 16}) {
    return _icon(_file, color, size);
  }

  /// Code icon
  static pw.Widget code({required PdfColor color, double size = 16}) {
    return _icon(_code, color, size);
  }

  /// Design icon
  static pw.Widget design({required PdfColor color, double size = 16}) {
    return _icon(_palette, color, size);
  }

  /// Language/speech icon
  static pw.Widget language({required PdfColor color, double size = 16}) {
    return _icon(_comment, color, size);
  }

  /// Tool/wrench icon
  static pw.Widget tool({required PdfColor color, double size = 16}) {
    return _icon(_wrench, color, size);
  }

  /// Lightbulb/idea icon
  static pw.Widget lightbulb({required PdfColor color, double size = 16}) {
    return _icon(_lightbulb, color, size);
  }

  /// Cog/gear icon
  static pw.Widget cog({required PdfColor color, double size = 16}) {
    return _icon(_cog, color, size);
  }

  /// Rocket icon
  static pw.Widget rocket({required PdfColor color, double size = 16}) {
    return _icon(_rocket, color, size);
  }

  /// Quote icon
  static pw.Widget quote({required PdfColor color, double size = 16}) {
    return _icon(_quote, color, size);
  }

  /// Target icon
  static pw.Widget target({required PdfColor color, double size = 16}) {
    return _icon(_target, color, size);
  }

  /// Pencil icon (for "about me" / writing)
  static pw.Widget pencil({required PdfColor color, double size = 16}) {
    return _icon(_pencil, color, size);
  }

  /// User alternate (simpler person icon)
  static pw.Widget userAlt({required PdfColor color, double size = 16}) {
    return _icon(_userAlt, color, size);
  }

  /// Handshake icon
  static pw.Widget handshake({required PdfColor color, double size = 16}) {
    return _icon(_handShake, color, size);
  }

  // ===========================================================================
  // UI ICONS
  // ===========================================================================

  /// Calendar icon
  static pw.Widget calendar({required PdfColor color, double size = 16}) {
    return _icon(_calendar, color, size);
  }

  /// Star icon
  static pw.Widget star({required PdfColor color, double size = 16}) {
    return _icon(_star, color, size);
  }

  /// Flag icon
  static pw.Widget flag({required PdfColor color, double size = 16}) {
    return _icon(_flag, color, size);
  }

  /// Check circle icon
  static pw.Widget checkCircle({required PdfColor color, double size = 16}) {
    return _icon(_checkCircle, color, size);
  }

  /// Arrow right icon
  static pw.Widget arrowRight({required PdfColor color, double size = 16}) {
    return _icon(_arrowRight, color, size);
  }

  // ===========================================================================
  // DECORATIVE ELEMENTS (non-font based)
  // ===========================================================================

  /// Simple bullet point
  static pw.Widget bullet({required PdfColor color, double size = 6}) {
    return pw.Container(
      width: size,
      height: size,
      decoration: pw.BoxDecoration(
        color: color,
        shape: pw.BoxShape.circle,
      ),
    );
  }

  /// Accent bar
  static pw.Widget accentBar({
    required PdfColor color,
    double width = 4,
    double height = 20,
  }) {
    return pw.Container(
      width: width,
      height: height,
      decoration: pw.BoxDecoration(
        color: color,
        borderRadius: pw.BorderRadius.circular(width / 2),
      ),
    );
  }

  /// Timeline dot
  static pw.Widget timelineDot({required PdfColor color, double size = 12}) {
    return pw.Container(
      width: size,
      height: size,
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: color, width: size / 5),
        shape: pw.BoxShape.circle,
      ),
    );
  }

  /// Diamond bullet
  static pw.Widget diamond({required PdfColor color, double size = 6}) {
    return pw.Transform.rotate(
      angle: 0.785398,
      child: pw.Container(
        width: size * 0.7,
        height: size * 0.7,
        color: color,
      ),
    );
  }

  /// Skill level dots
  static pw.Widget skillDots({
    required PdfColor color,
    required int level,
    int maxLevel = 5,
    double dotSize = 6,
    double spacing = 3,
  }) {
    return pw.Row(
      mainAxisSize: pw.MainAxisSize.min,
      children: List.generate(maxLevel, (index) {
        final isFilled = index < level;
        return pw.Container(
          width: dotSize,
          height: dotSize,
          margin: pw.EdgeInsets.only(right: index < maxLevel - 1 ? spacing : 0),
          decoration: pw.BoxDecoration(
            color: isFilled ? color : PdfColors.grey300,
            shape: pw.BoxShape.circle,
          ),
        );
      }),
    );
  }

  /// Skill progress bar
  static pw.Widget skillBar({
    required PdfColor color,
    required double percentage,
    double width = 100,
    double height = 4,
    PdfColor? backgroundColor,
  }) {
    return pw.Container(
      width: width,
      height: height,
      decoration: pw.BoxDecoration(
        color: backgroundColor ?? PdfColors.grey200,
        borderRadius: pw.BorderRadius.circular(height / 2),
      ),
      child: pw.Align(
        alignment: pw.Alignment.centerLeft,
        child: pw.Container(
          width: width * percentage.clamp(0, 1),
          height: height,
          decoration: pw.BoxDecoration(
            color: color,
            borderRadius: pw.BorderRadius.circular(height / 2),
          ),
        ),
      ),
    );
  }

  /// Proficiency bar
  static pw.Widget proficiencyBar({
    required int level,
    required PdfColor fillColor,
    required PdfColor backgroundColor,
    double height = 4,
    double width = 100,
  }) {
    return skillBar(
      color: fillColor,
      percentage: level / 100,
      width: width,
      height: height,
      backgroundColor: backgroundColor,
    );
  }

  // ===========================================================================
  // PRIVATE HELPERS
  // ===========================================================================

  /// Render an icon from the Lineicons font
  static pw.Widget _icon(String iconCode, PdfColor color, double size) {
    if (_iconFont == null) {
      // Fallback to bullet if font not loaded
      return bullet(color: color, size: size * 0.4);
    }

    return pw.SizedBox(
      width: size,
      height: size,
      child: pw.Center(
        child: pw.Text(
          iconCode,
          style: pw.TextStyle(
            font: _iconFont,
            fontSize: size,
            color: color,
          ),
        ),
      ),
    );
  }
}
