import 'package:pdf/widgets.dart' as pw;
import 'package:flutter/services.dart' show rootBundle;
import 'dart:typed_data';

/// Centralized PDF font embedding service
///
/// Provides robust font loading with fallbacks and special character support.
/// Supports both standard PDF fonts and custom embedded fonts.
/// Single source of truth for all PDF font configuration.
///
/// Usage:
/// ```dart
/// final fonts = await PdfFontEmbeddingService.loadFonts();
/// ```
class PdfFontEmbeddingService {
  // Private constructor
  PdfFontEmbeddingService._();

  // Font loading strategy
  static FontStrategy _strategy = FontStrategy.standard;

  /// Set font loading strategy
  static void setStrategy(FontStrategy strategy) {
    _strategy = strategy;
  }

  /// Load fonts based on current strategy
  ///
  /// This is the main entry point for getting fonts in PDF generation.
  /// Returns a [PdfFonts] object with all font weights configured.
  static Future<PdfFonts> loadFonts() async {
    switch (_strategy) {
      case FontStrategy.standard:
        return _loadStandardFonts();
      case FontStrategy.embedded:
        return await _loadEmbeddedFonts();
      case FontStrategy.standardWithFallback:
        return await _loadStandardWithFallback();
    }
  }

  /// Load standard PDF fonts (no embedding required)
  ///
  /// Fastest option, works without assets, but limited character support
  static PdfFonts _loadStandardFonts() {
    return PdfFonts(
      regular: pw.Font.helvetica(),
      bold: pw.Font.helveticaBold(),
      italic: pw.Font.helveticaOblique(),
      boldItalic: pw.Font.helveticaBoldOblique(),
      fallback: [],
    );
  }

  /// Load embedded fonts from assets
  ///
  /// Best character support, requires font files in assets
  static Future<PdfFonts> _loadEmbeddedFonts() async {
    try {
      // Load OpenSans fonts (good Unicode support)
      final regularData = await rootBundle.load('assets/fonts/OpenSans-Regular.ttf');
      final boldData = await rootBundle.load('assets/fonts/OpenSans-Bold.ttf');
      final italicData = await rootBundle.load('assets/fonts/OpenSans-Italic.ttf');
      final boldItalicData = await rootBundle.load('assets/fonts/OpenSans-BoldItalic.ttf');

      final regular = pw.Font.ttf(regularData);
      final bold = pw.Font.ttf(boldData);
      final italic = pw.Font.ttf(italicData);
      final boldItalic = pw.Font.ttf(boldItalicData);

      return PdfFonts(
        regular: regular,
        bold: bold,
        italic: italic,
        boldItalic: boldItalic,
        fallback: [regular, bold],
      );
    } catch (e) {
      // Fallback to standard fonts if embedded fonts fail
      print('Warning: Failed to load embedded fonts, using standard fonts: $e');
      return _loadStandardFonts();
    }
  }

  /// Load standard fonts with embedded fallback for special characters
  ///
  /// Hybrid approach: fast standard fonts + embedded fallback for Unicode
  static Future<PdfFonts> _loadStandardWithFallback() async {
    final standard = _loadStandardFonts();

    try {
      // Load just one fallback font for special characters
      final fallbackData = await rootBundle.load('assets/fonts/OpenSans-Regular.ttf');
      final fallbackFont = pw.Font.ttf(fallbackData);

      return PdfFonts(
        regular: standard.regular,
        bold: standard.bold,
        italic: standard.italic,
        boldItalic: standard.boldItalic,
        fallback: [fallbackFont],
      );
    } catch (e) {
      // If fallback fails, just use standard
      return standard;
    }
  }

  /// Get fonts synchronously (standard fonts only)
  ///
  /// Use this when you need immediate fonts without async loading
  static PdfFonts getFontsSync() {
    return _loadStandardFonts();
  }
}

/// Font loading strategy
enum FontStrategy {
  /// Standard PDF fonts (fastest, limited characters)
  standard,

  /// Fully embedded fonts (best character support)
  embedded,

  /// Standard with embedded fallback (balanced)
  standardWithFallback,
}

/// PDF fonts container
///
/// Holds all font weights and fallback fonts for PDF generation
class PdfFonts {
  final pw.Font regular;
  final pw.Font bold;
  final pw.Font italic;
  final pw.Font boldItalic;
  final List<pw.Font> fallback;

  const PdfFonts({
    required this.regular,
    required this.bold,
    required this.italic,
    required this.boldItalic,
    required this.fallback,
  });

  /// Get font for medium weight (uses bold)
  pw.Font get medium => bold;

  /// Get font fallback list for ThemeData
  List<pw.Font> get fallbackList => [regular, bold, ...fallback];

  /// Get font for semibold weight (uses bold)
  pw.Font get semiBold => bold;

  /// Create theme data with these fonts
  pw.ThemeData buildTheme() {
    return pw.ThemeData.withFont(
      base: regular,
      bold: bold,
      italic: italic,
      boldItalic: boldItalic,
      fontFallback: fallbackList,
    );
  }
}
