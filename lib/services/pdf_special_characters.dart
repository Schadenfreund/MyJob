import 'package:pdf/widgets.dart' as pw;

/// Centralized PDF special character service
///
/// Provides Unicode-safe special characters that work with embedded fonts.
/// Single source of truth for all special characters used in PDF templates.
///
/// Usage:
/// ```dart
/// final chars = PdfSpecialCharacters();
/// pw.Text('${chars.bullet} Item 1');
/// pw.Text('${chars.email} contact@example.com');
/// ```
class PdfSpecialCharacters {
  // Private constructor - use singleton pattern
  PdfSpecialCharacters._();
  static final PdfSpecialCharacters _instance = PdfSpecialCharacters._();
  factory PdfSpecialCharacters() => _instance;

  // ============================================================================
  // BASIC SYMBOLS
  // ============================================================================

  /// Bullet point • (U+2022)
  /// Works with embedded fonts like OpenSans
  String get bullet => '•';

  /// En dash – (U+2013)
  /// For ranges: 2020–2025
  String get enDash => '–';

  /// Em dash — (U+2014)
  /// For emphasis—like this
  String get emDash => '—';

  /// Ellipsis … (U+2026)
  String get ellipsis => '…';

  // ============================================================================
  // ARROWS
  // ============================================================================

  /// Right arrow → (U+2192)
  String get arrowRight => '→';

  /// Left arrow ← (U+2190)
  String get arrowLeft => '←';

  /// Up arrow ↑ (U+2191)
  String get arrowUp => '↑';

  /// Down arrow ↓ (U+2193)
  String get arrowDown => '↓';

  /// Right chevron › (U+203A)
  String get chevronRight => '›';

  /// Left chevron ‹ (U+2039)
  String get chevronLeft => '‹';

  // ============================================================================
  // SHAPES
  // ============================================================================

  /// Square ■ (U+25A0)
  String get square => '■';

  /// Circle ● (U+25CF)
  String get circle => '●';

  /// Triangle ▲ (U+25B2)
  String get triangle => '▲';

  /// Diamond ◆ (U+25C6)
  String get diamond => '◆';

  /// Star ★ (U+2605)
  String get star => '★';

  /// Empty star ☆ (U+2606)
  String get starEmpty => '☆';

  // ============================================================================
  // COMMON ICONS (Unicode)
  // ============================================================================

  /// Checkmark ✓ (U+2713)
  String get checkmark => '✓';

  /// Cross ✗ (U+2717)
  String get cross => '✗';

  /// Phone ☎ (U+260E)
  String get phone => '☎';

  /// Email ✉ (U+2709)
  String get email => '✉';

  /// Location/Pin ⌖ (U+2316)
  String get location => '⌖';

  /// Home ⌂ (U+2302)
  String get home => '⌂';

  /// Info ℹ (U+2139)
  String get info => 'ℹ';

  /// Warning ⚠ (U+26A0)
  String get warning => '⚠';

  // ============================================================================
  // CURRENCY
  // ============================================================================

  /// Dollar sign $
  String get dollar => r'$';

  /// Euro sign € (U+20AC)
  String get euro => '€';

  /// Pound sign £ (U+00A3)
  String get pound => '£';

  /// Yen sign ¥ (U+00A5)
  String get yen => '¥';

  // ============================================================================
  // PUNCTUATION
  // ============================================================================

  /// Left double quote " (U+201C)
  String get quoteLeft => '"';

  /// Right double quote " (U+201D)
  String get quoteRight => '"';

  /// Left single quote ' (U+2018)
  String get quoteLeftSingle => ''';

  /// Right single quote ' (U+2019)
  String get quoteRightSingle => ''';

  // ============================================================================
  // ASCII FALLBACK MODE
  // ============================================================================

  /// Whether to use ASCII-safe fallbacks instead of Unicode
  /// Set to true if using standard PDF fonts (Helvetica) without embedding
  static bool _useAsciiFallback = false;

  /// Enable ASCII-safe fallback mode
  /// Use this when not using embedded fonts
  static void enableAsciiFallback() {
    _useAsciiFallback = true;
  }

  /// Disable ASCII-safe fallback mode
  /// Use this when using embedded fonts with Unicode support
  static void disableAsciiFallback() {
    _useAsciiFallback = false;
  }

  /// Get bullet with fallback
  String get bulletSafe => _useAsciiFallback ? '-' : bullet;

  /// Get arrow with fallback
  String get arrowRightSafe => _useAsciiFallback ? '>' : arrowRight;

  /// Get star with fallback
  String get starSafe => _useAsciiFallback ? '*' : star;

  /// Get checkmark with fallback
  String get checkmarkSafe => _useAsciiFallback ? 'v' : checkmark;

  /// Get email icon with fallback
  String get emailSafe => _useAsciiFallback ? '@' : email;

  // ============================================================================
  // HELPER METHODS
  // ============================================================================

  /// Create a bulleted list item
  pw.Widget bulletItem(String text, {pw.TextStyle? style}) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text('$bullet  ', style: style),
        pw.Expanded(child: pw.Text(text, style: style)),
      ],
    );
  }

  /// Create a numbered list item
  pw.Widget numberedItem(int number, String text, {pw.TextStyle? style}) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text('$number.  ', style: style),
        pw.Expanded(child: pw.Text(text, style: style)),
      ],
    );
  }

  /// Create a checkmark list item
  pw.Widget checklistItem(String text,
      {bool checked = true, pw.TextStyle? style}) {
    final icon = checked ? checkmark : cross;
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text('$icon  ', style: style),
        pw.Expanded(child: pw.Text(text, style: style)),
      ],
    );
  }

  /// Create star rating (1-5 stars)
  String starRating(int rating, {int max = 5}) {
    assert(rating >= 0 && rating <= max, 'Rating must be between 0 and $max');
    final filled = star * rating;
    final empty = starEmpty * (max - rating);
    return filled + empty;
  }
}
