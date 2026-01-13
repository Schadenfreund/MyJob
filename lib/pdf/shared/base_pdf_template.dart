import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../../models/template_style.dart';
import '../../models/template_customization.dart';
import '../../services/pdf_font_service.dart';
import 'pdf_styling.dart';

/// Describes a PDF template for the registry
class TemplateInfo {
  const TemplateInfo({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    required this.previewTags,
  });

  /// Unique identifier
  final String id;

  /// Display name
  final String name;

  /// Description for users
  final String description;

  /// Category: 'cv' or 'cover_letter'
  final String category;

  /// Tags for filtering/display (e.g., 'modern', 'minimal', 'professional')
  final List<String> previewTags;
}

/// Base class for all PDF templates
///
/// Provides common functionality and enforces consistent structure.
/// New templates should extend this class.
abstract class BasePdfTemplate<T> {
  /// Build the PDF document
  ///
  /// [data] - The data model to render (CvData, CoverLetter, etc.)
  /// [style] - Visual style (colors, fonts)
  /// [customization] - Layout customization (spacing, margins)
  Future<Uint8List> build(
    T data,
    TemplateStyle style, {
    TemplateCustomization? customization,
    Uint8List? profileImageBytes,
  });

  /// Template information for registry
  TemplateInfo get info;

  /// Convenience getters
  String get templateName => info.name;
  String get templateDescription => info.description;
  String get documentType => info.category;
}

/// Mixin providing common PDF template utilities
mixin PdfTemplateHelpers {
  /// Load fonts for the template
  Future<PdfFonts> loadFonts(TemplateStyle style) async {
    return PdfFontService.getFonts(style.fontFamily);
  }

  /// Create a styled PDF document with common settings
  pw.Document createDocument({String? title, String? author}) {
    return pw.Document(
      compress: true,
      title: title ?? 'Generated Document',
      author: author ?? 'MyJob',
    );
  }

  /// Get profile image provider if bytes are valid
  pw.ImageProvider? getProfileImage(Uint8List? bytes) {
    if (bytes == null || bytes.isEmpty) return null;
    try {
      return pw.MemoryImage(bytes);
    } catch (_) {
      return null;
    }
  }

  /// Standard A4 page format
  PdfPageFormat get pageFormat => PdfPageFormat.a4;
}

/// Standard page themes for templates
class PdfPageThemes {
  PdfPageThemes._();

  /// Create a page theme with zero margins (for full-bleed designs)
  static pw.PageTheme fullBleed({
    required pw.Font regularFont,
    required pw.Font boldFont,
    required pw.Font mediumFont,
    required PdfStyling styling,
  }) {
    return pw.PageTheme(
      pageFormat: PdfPageFormat.a4,
      margin: pw.EdgeInsets.zero,
      theme: pw.ThemeData.withFont(
        base: regularFont,
        bold: boldFont,
        fontFallback: [regularFont, boldFont, mediumFont],
      ),
      buildBackground: (context) => pw.FullPage(
        ignoreMargins: true,
        child: pw.Container(color: styling.background),
      ),
    );
  }

  /// Create a page theme with standard margins
  static pw.PageTheme standard({
    required pw.Font regularFont,
    required pw.Font boldFont,
    required pw.Font mediumFont,
    required PdfStyling styling,
  }) {
    return pw.PageTheme(
      pageFormat: PdfPageFormat.a4,
      margin: styling.pageMargins,
      theme: pw.ThemeData.withFont(
        base: regularFont,
        bold: boldFont,
        fontFallback: [regularFont, boldFont, mediumFont],
      ),
      buildBackground: (context) => pw.FullPage(
        ignoreMargins: true,
        child: pw.Container(color: styling.background),
      ),
    );
  }

  /// Create a page theme with content margins (for clean edges)
  static pw.PageTheme contentMargins({
    required pw.Font regularFont,
    required pw.Font boldFont,
    required pw.Font mediumFont,
    required PdfStyling styling,
    double horizontalMargin = 48,
    double verticalMargin = 40,
  }) {
    return pw.PageTheme(
      pageFormat: PdfPageFormat.a4,
      margin: pw.EdgeInsets.symmetric(
        horizontal: horizontalMargin,
        vertical: verticalMargin,
      ),
      theme: pw.ThemeData.withFont(
        base: regularFont,
        bold: boldFont,
        fontFallback: [regularFont, boldFont, mediumFont],
      ),
      buildBackground: (context) => pw.FullPage(
        ignoreMargins: true,
        child: pw.Container(color: styling.background),
      ),
    );
  }
}
