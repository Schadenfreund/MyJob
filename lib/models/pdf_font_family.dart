/// PDF Font Family options with full Unicode support
///
/// Provides different Google Font families for PDF generation.
/// All fonts support Unicode characters and are loaded via Google Fonts.
enum PdfFontFamily {
  roboto(
    'Roboto',
    'Modern Sans-Serif',
    'Clean, professional sans-serif with excellent Unicode support',
  ),
  openSans(
    'Open Sans',
    'Friendly Sans-Serif',
    'Highly readable sans-serif font perfect for professional documents',
  ),
  notoSans(
    'Noto Sans',
    'Universal Sans-Serif',
    'Google\'s font designed for maximum Unicode coverage',
  ),
  lora(
    'Lora',
    'Contemporary Serif',
    'Elegant serif font for formal documents',
  );

  const PdfFontFamily(
    this.displayName,
    this.technicalName,
    this.description,
  );

  final String displayName;
  final String technicalName;
  final String description;

  /// All fonts have Unicode support when loaded via Google Fonts
  bool get hasUnicodeSupport => true;

  /// Get a short description of the font's characteristics
  String get characteristicsLabel {
    switch (this) {
      case PdfFontFamily.roboto:
        return 'Unicode • Modern • Clean';
      case PdfFontFamily.openSans:
        return 'Unicode • Friendly • Professional';
      case PdfFontFamily.notoSans:
        return 'Unicode • Universal • Multilingual';
      case PdfFontFamily.lora:
        return 'Unicode • Elegant • Serif';
    }
  }

  /// Get font style category
  String get category {
    switch (this) {
      case PdfFontFamily.roboto:
      case PdfFontFamily.openSans:
      case PdfFontFamily.notoSans:
        return 'Sans-Serif';
      case PdfFontFamily.lora:
        return 'Serif';
    }
  }
}
