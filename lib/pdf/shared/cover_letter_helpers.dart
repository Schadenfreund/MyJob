/// Shared utilities for cover letter PDF templates.
///
/// Centralises logic that was previously duplicated across all four templates
/// (classic, professional, electric, modern_two).
abstract final class CoverLetterHelpers {
  // Month names used when formatting dates in cover letter documents.
  // Note: date strings are subsequently passed through CvTranslations.translateDate()
  // which handles language-specific formatting, so these English names act as
  // the canonical input format for that translation layer.
  static const List<String> _months = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December',
  ];

  /// Format [date] as "Month D, YYYY" (e.g. "March 8, 2026").
  ///
  /// The result is intended to be passed to [CvTranslations.translateDate]
  /// for language-specific presentation.
  static String formatDate(DateTime date) =>
      '${_months[date.month - 1]} ${date.day}, ${date.year}';

  /// Normalise [body] text and split it into non-empty paragraphs.
  ///
  /// Rules:
  /// - Multiple consecutive newlines → paragraph break
  /// - Single newlines within a block → collapsed to a space (line-wrap)
  ///
  /// Returns a list of trimmed, non-empty paragraph strings ready for rendering.
  static List<String> splitBodyParagraphs(String body) {
    var normalised = body
        .replaceAll(RegExp(r'\n\s*\n+'), '§PARA§')
        .replaceAll(RegExp(r'\n'), ' ')
        .replaceAll('§PARA§', '\n\n');
    return normalised.split('\n\n').where((p) => p.trim().isNotEmpty).toList();
  }
}
