import 'package:pdf/pdf.dart';

/// PDF-specific constants for document generation
///
/// Defines page sizes, margins, fonts, and layout settings
/// for CV and cover letter PDF generation.
class PdfConstants {
  PdfConstants._();

  // ============================================================================
  // PAGE SETTINGS
  // ============================================================================

  /// A4 page format (210mm x 297mm)
  static const PdfPageFormat pageFormat = PdfPageFormat.a4;

  /// Page margins in points (1 inch = 72 points)
  static const double marginTop = 40;
  static const double marginBottom = 40;
  static const double marginLeft = 50;
  static const double marginRight = 50;

  // ============================================================================
  // FONT SIZES
  // ============================================================================

  static const double fontSizeName = 24;
  static const double fontSizeTitle = 18;
  static const double fontSizeHeading = 14;
  static const double fontSizeSubheading = 12;
  static const double fontSizeBody = 10;
  static const double fontSizeSmall = 9;
  static const double fontSizeCaption = 8;

  // ============================================================================
  // SPACING
  // ============================================================================

  static const double sectionSpacing = 16;
  static const double paragraphSpacing = 8;
  static const double lineSpacing = 4;
  static const double bulletIndent = 12;

  // ============================================================================
  // COLORS (as PdfColor)
  // ============================================================================

  // Professional Template Colors
  static const PdfColor professionalPrimary = PdfColor.fromInt(0xFF2C3E50);
  static const PdfColor professionalAccent = PdfColor.fromInt(0xFF3498DB);
  static const PdfColor professionalText = PdfColor.fromInt(0xFF333333);
  static const PdfColor professionalMuted = PdfColor.fromInt(0xFF7F8C8D);
  static const PdfColor professionalDivider = PdfColor.fromInt(0xFFBDC3C7);

  // Modern Template Colors
  static const PdfColor modernPrimary = PdfColor.fromInt(0xFFE67E22);
  static const PdfColor modernAccent = PdfColor.fromInt(0xFF27AE60);
  static const PdfColor modernText = PdfColor.fromInt(0xFF2C3E50);
  static const PdfColor modernMuted = PdfColor.fromInt(0xFF95A5A6);
  static const PdfColor modernBackground = PdfColor.fromInt(0xFFF8F9FA);

  // ============================================================================
  // LAYOUT RATIOS
  // ============================================================================

  /// Sidebar width ratio for two-column layouts
  static const double sidebarRatio = 0.32;

  /// Main content width ratio
  static const double contentRatio = 0.68;

  // ============================================================================
  // SKILL BAR SETTINGS
  // ============================================================================

  static const double skillBarHeight = 6;
  static const double skillBarRadius = 3;
  static const double skillBarMaxWidth = 100;

  // ============================================================================
  // PHOTO SETTINGS
  // ============================================================================

  static const double photoSize = 80;
  static const double photoRadius = 40;
}
