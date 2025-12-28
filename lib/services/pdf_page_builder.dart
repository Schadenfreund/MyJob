import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'pdf_font_service.dart' as legacy;
import 'pdf_font_embedding_service.dart';
import '../constants/pdf_constants.dart';

/// Centralized PDF page builder service
///
/// Provides robust, DRY-compliant page building for all PDF templates.
/// Prevents configuration errors by enforcing correct patterns.
/// Single source of truth for page configuration.
///
/// Supports both standard fonts (sync) and embedded fonts (async):
/// - Standard fonts: Use buildMultiPage() / buildSinglePage() (default)
/// - Embedded fonts: Use buildMultiPageWithFonts() / buildSinglePageWithFonts()
class PdfPageBuilder {
  // Private constructor - only static methods
  PdfPageBuilder._();

  /// Build a multi-page PDF with standard fonts (sync)
  ///
  /// This method prevents common configuration errors by:
  /// - Using only pageTheme for all settings (no duplicate properties)
  /// - Applying consistent font configuration
  /// - Providing optional background builder
  ///
  /// Usage:
  /// ```dart
  /// pdf.addPage(
  ///   PdfPageBuilder.buildMultiPage(
  ///     backgroundColor: Colors.white,
  ///     build: (context) => [...content...],
  ///   ),
  /// );
  /// ```
  static pw.MultiPage buildMultiPage({
    required List<pw.Widget> Function(pw.Context) build,
    PdfColor? backgroundColor,
    pw.EdgeInsets? margin,
    PdfPageFormat? pageFormat,
  }) {
    final fonts = legacy.PdfFontService.getFonts();
    final effectiveMargin = margin ?? pw.EdgeInsets.zero;
    final effectiveFormat = pageFormat ?? PdfConstants.pageFormat;

    return pw.MultiPage(
      pageTheme: _buildPageThemeFromLegacy(
        fonts: fonts,
        backgroundColor: backgroundColor,
        margin: effectiveMargin,
        pageFormat: effectiveFormat,
      ),
      build: build,
    );
  }

  /// Build a multi-page PDF with embedded fonts (async)
  ///
  /// Use this for better Unicode and special character support.
  /// Requires fonts parameter from PdfFontEmbeddingService.loadFonts()
  ///
  /// Usage:
  /// ```dart
  /// final fonts = await PdfFontEmbeddingService.loadFonts();
  /// pdf.addPage(
  ///   PdfPageBuilder.buildMultiPageWithFonts(
  ///     fonts: fonts,
  ///     backgroundColor: Colors.white,
  ///     build: (context) => [...content...],
  ///   ),
  /// );
  /// ```
  static pw.MultiPage buildMultiPageWithFonts({
    required PdfFonts fonts,
    required List<pw.Widget> Function(pw.Context) build,
    PdfColor? backgroundColor,
    pw.EdgeInsets? margin,
    PdfPageFormat? pageFormat,
  }) {
    final effectiveMargin = margin ?? pw.EdgeInsets.zero;
    final effectiveFormat = pageFormat ?? PdfConstants.pageFormat;

    return pw.MultiPage(
      pageTheme: _buildPageTheme(
        fonts: fonts,
        backgroundColor: backgroundColor,
        margin: effectiveMargin,
        pageFormat: effectiveFormat,
      ),
      build: build,
    );
  }

  /// Build a single-page PDF with standard fonts (sync)
  ///
  /// This method prevents common configuration errors by:
  /// - Using consistent font configuration
  /// - Providing optional background color
  ///
  /// Usage:
  /// ```dart
  /// pdf.addPage(
  ///   PdfPageBuilder.buildSinglePage(
  ///     backgroundColor: Colors.white,
  ///     build: (context) => pw.Center(...),
  ///   ),
  /// );
  /// ```
  static pw.Page buildSinglePage({
    required pw.Widget Function(pw.Context) build,
    PdfColor? backgroundColor,
    pw.EdgeInsets? margin,
    PdfPageFormat? pageFormat,
  }) {
    final fonts = legacy.PdfFontService.getFonts();
    final effectiveMargin = margin ?? pw.EdgeInsets.zero;
    final effectiveFormat = pageFormat ?? PdfConstants.pageFormat;

    return pw.Page(
      pageFormat: effectiveFormat,
      margin: effectiveMargin,
      theme: _buildThemeFromLegacy(fonts),
      build: (context) {
        if (backgroundColor != null) {
          return pw.Container(
            color: backgroundColor,
            child: build(context),
          );
        }
        return build(context);
      },
    );
  }

  /// Build a single-page PDF with embedded fonts (async)
  ///
  /// Use this for better Unicode and special character support.
  /// Requires fonts parameter from PdfFontEmbeddingService.loadFonts()
  ///
  /// Usage:
  /// ```dart
  /// final fonts = await PdfFontEmbeddingService.loadFonts();
  /// pdf.addPage(
  ///   PdfPageBuilder.buildSinglePageWithFonts(
  ///     fonts: fonts,
  ///     backgroundColor: Colors.white,
  ///     build: (context) => pw.Center(...),
  ///   ),
  /// );
  /// ```
  static pw.Page buildSinglePageWithFonts({
    required PdfFonts fonts,
    required pw.Widget Function(pw.Context) build,
    PdfColor? backgroundColor,
    pw.EdgeInsets? margin,
    PdfPageFormat? pageFormat,
  }) {
    final effectiveMargin = margin ?? pw.EdgeInsets.zero;
    final effectiveFormat = pageFormat ?? PdfConstants.pageFormat;

    return pw.Page(
      pageFormat: effectiveFormat,
      margin: effectiveMargin,
      theme: fonts.buildTheme(),
      build: (context) {
        if (backgroundColor != null) {
          return pw.Container(
            color: backgroundColor,
            child: build(context),
          );
        }
        return build(context);
      },
    );
  }

  /// Build page theme for embedded fonts
  ///
  /// Private helper that ensures all page themes follow the same pattern
  static pw.PageTheme _buildPageTheme({
    required PdfFonts fonts,
    required PdfColor? backgroundColor,
    required pw.EdgeInsets margin,
    required PdfPageFormat pageFormat,
  }) {
    return pw.PageTheme(
      theme: fonts.buildTheme(),
      pageFormat: pageFormat,
      margin: margin,
      buildBackground: backgroundColor != null
          ? (context) => _buildBackground(backgroundColor)
          : null,
    );
  }

  /// Build page theme for legacy fonts
  ///
  /// Private helper for backward compatibility with standard fonts
  static pw.PageTheme _buildPageThemeFromLegacy({
    required legacy.PdfFonts fonts,
    required PdfColor? backgroundColor,
    required pw.EdgeInsets margin,
    required PdfPageFormat pageFormat,
  }) {
    return pw.PageTheme(
      theme: _buildThemeFromLegacy(fonts),
      pageFormat: pageFormat,
      margin: margin,
      buildBackground: backgroundColor != null
          ? (context) => _buildBackground(backgroundColor)
          : null,
    );
  }

  /// Build theme from legacy font service
  ///
  /// Private helper for backward compatibility
  static pw.ThemeData _buildThemeFromLegacy(legacy.PdfFonts fonts) {
    return pw.ThemeData.withFont(
      base: fonts.regular,
      bold: fonts.bold,
      fontFallback: fonts.fallbackList,
    );
  }

  /// Build background with full page coverage
  ///
  /// Private helper for consistent background rendering
  static pw.Widget _buildBackground(PdfColor color) {
    return pw.FullPage(
      ignoreMargins: true,
      child: pw.Container(color: color),
    );
  }

  /// Get standard fonts for manual theme building (sync)
  ///
  /// Use this when you need direct access to standard fonts for custom styling
  static legacy.PdfFonts getFonts() => legacy.PdfFontService.getFonts();

  /// Get embedded fonts for manual theme building (async)
  ///
  /// Use this when you need direct access to embedded fonts for custom styling
  static Future<PdfFonts> loadFonts() => PdfFontEmbeddingService.loadFonts();
}
