import 'package:pdf/pdf.dart';

/// Professional PDF Design System
///
/// Centralized design constants following professional typographic and
/// layout principles for CVs and cover letters.
class PdfConstants {
  PdfConstants._();

  // ============================================================================
  // PAGE SETTINGS
  // ============================================================================

  /// A4 page format (210mm x 297mm)
  static const PdfPageFormat pageFormat = PdfPageFormat.a4;

  /// Professional page margins in points (1 inch = 72 points)
  /// Standard business document margins for balance and readability
  static const double marginTop = 54;        // ~0.75 inches (3/4")
  static const double marginBottom = 54;     // ~0.75 inches
  static const double marginLeft = 72;       // 1 inch (standard)
  static const double marginRight = 72;      // 1 inch (standard)

  // ============================================================================
  // PROFESSIONAL TYPOGRAPHY SCALE
  // ============================================================================
  // Based on professional print standards for maximum readability
  // 11pt body text is the standard for professional documents

  /// Name/Document title (H1) - Should stand out significantly
  static const double fontSizeName = 32.0;  // Increased for better presence

  /// Major section headings (H2) - Clear visual hierarchy
  static const double fontSizeH2 = 14.0;  // Professional section headers

  /// Subsection headings (H3) - Job titles, degree names
  static const double fontSizeH3 = 12.0;  // Slightly larger for readability

  /// Subheadings within entries (H4) - Company names, institutions
  static const double fontSizeH4 = 11.0;  // Match body text weight

  /// Body text (standard paragraphs) - CRITICAL for readability
  static const double fontSizeBody = 11.0;  // Industry standard (not 10.5pt)

  /// Small text (captions, meta info) - Dates, locations
  static const double fontSizeSmall = 10.0;  // Still readable

  /// Tiny text (footnotes) - Use sparingly
  static const double fontSizeTiny = 9.0;  // Minimum for professional docs

  // ============================================================================
  // LINE HEIGHT / LEADING
  // ============================================================================
  // Professional print standards: 1.4-1.6x font size for optimal readability

  /// Tight line spacing for headings and names
  static const double lineHeightTight = 1.15;  // Headers need to be compact

  /// Normal line spacing for body text (THE MOST IMPORTANT)
  static const double lineHeightNormal = 1.4;  // Professional standard

  /// Loose line spacing for emphasized paragraphs
  static const double lineHeightLoose = 1.6;  // More breathing room

  // ============================================================================
  // PROFESSIONAL SPACING SYSTEM
  // ============================================================================
  // Based on 4pt grid for visual consistency and breathing room

  /// Extra small spacing - Between related inline elements
  static const double spaceXs = 4.0;

  /// Small spacing - Between tightly related items
  static const double spaceSm = 8.0;

  /// Medium spacing - Between paragraphs
  static const double spaceMd = 14.0;  // Increased for better readability

  /// Large spacing - Between job entries
  static const double spaceLg = 20.0;  // More generous

  /// Extra large spacing - After subsections
  static const double spaceXl = 24.0;

  /// 2X extra large spacing - Before major sections
  static const double space2xl = 28.0;

  /// 3X extra large spacing - Between major content blocks
  static const double space3xl = 36.0;  // More professional breathing room

  /// Section spacing - Between major CV sections
  static const double spaceSection = 24.0;  // Reduced from 40pt for balance

  // Semantic spacing names for clarity
  static const double paragraphSpacing = spaceMd;  // 14pt between paragraphs
  static const double sectionSpacing = spaceSection;  // 24pt between sections
  static const double entrySpacing = spaceLg;  // 20pt between job entries
  static const double itemSpacing = spaceSm;  // 8pt between list items

  // ============================================================================
  // PROFESSIONAL COLOR SYSTEM
  // ============================================================================

  // Neutral grays for text (ensures readability on white)
  static const PdfColor textDark = PdfColor.fromInt(0xFF1A1A1A);      // Near black
  static const PdfColor textBody = PdfColor.fromInt(0xFF333333);       // Dark gray
  static const PdfColor textMuted = PdfColor.fromInt(0xFF666666);      // Medium gray
  static const PdfColor textLight = PdfColor.fromInt(0xFF999999);      // Light gray

  // Dividers and borders
  static const PdfColor dividerDark = PdfColor.fromInt(0xFFCCCCCC);
  static const PdfColor dividerLight = PdfColor.fromInt(0xFFE0E0E0);

  // Backgrounds
  static const PdfColor bgWhite = PdfColors.white;
  static const PdfColor bgLightGray = PdfColor.fromInt(0xFFF5F5F5);
  static const PdfColor bgMediumGray = PdfColor.fromInt(0xFFF0F0F0);

  // Professional color palettes for different templates

  // Classic Professional (Navy & Blue)
  static const PdfColor professionalPrimary = PdfColor.fromInt(0xFF1E3A5F);
  static const PdfColor professionalAccent = PdfColor.fromInt(0xFF2563EB);

  // Modern (Teal & Emerald)
  static const PdfColor modernPrimary = PdfColor.fromInt(0xFF0F766E);
  static const PdfColor modernAccent = PdfColor.fromInt(0xFF059669);

  // Executive (Charcoal & Gold)
  static const PdfColor executivePrimary = PdfColor.fromInt(0xFF2D3748);
  static const PdfColor executiveAccent = PdfColor.fromInt(0xFFD97706);

  // Creative (Indigo & Purple)
  static const PdfColor creativePrimary = PdfColor.fromInt(0xFF4F46E5);
  static const PdfColor creativeAccent = PdfColor.fromInt(0xFF7C3AED);

  // Minimalist (Black & Charcoal)
  static const PdfColor minimalistPrimary = PdfColor.fromInt(0xFF000000);
  static const PdfColor minimalistAccent = PdfColor.fromInt(0xFF374151);

  // ============================================================================
  // LAYOUT PROPORTIONS
  // ============================================================================

  /// Golden ratio for harmonious proportions
  static const double goldenRatio = 1.618;

  /// Sidebar width for two-column layouts (30% of page width)
  static const double sidebarWidthRatio = 0.30;

  /// Main content width for two-column layouts (70% of page width)
  static const double contentWidthRatio = 0.70;

  /// Gutter between columns
  static const double columnGutter = 20.0;

  // ============================================================================
  // DECORATIVE ELEMENTS
  // ============================================================================

  /// Standard divider thickness
  static const double dividerThickness = 1.0;

  /// Accent divider thickness
  static const double accentDividerThickness = 2.5;

  /// Border radius for rounded elements
  static const double borderRadius = 4.0;

  /// Border radius for pills/badges
  static const double borderRadiusPill = 12.0;

  // ============================================================================
  // SKILL & PROGRESS BARS
  // ============================================================================

  static const double skillBarHeight = 8.0;
  static const double skillBarRadius = 4.0;
  static const double skillBarMaxWidth = 120.0;
  static const double skillBarSpacing = 6.0;

  // ============================================================================
  // BADGES & CHIPS
  // ============================================================================

  static const double badgeHeight = 20.0;
  static const double badgePaddingH = 10.0;
  static const double badgePaddingV = 4.0;
  static const double badgeRadius = 10.0;
  static const double badgeSpacing = 6.0;

  // ============================================================================
  // ICON SIZES
  // ============================================================================

  static const double iconSizeSmall = 12.0;
  static const double iconSizeMedium = 14.0;
  static const double iconSizeLarge = 16.0;

  // ============================================================================
  // CONTACT INFO LAYOUT
  // ============================================================================

  static const double contactIconSize = iconSizeMedium;
  static const double contactSpacing = 14.0;
  static const double contactLineSpacing = 6.0;

  // ============================================================================
  // BULLET POINTS (ASCII-compatible for all fonts)
  // ============================================================================

  static const double bulletIndent = 16.0;
  static const double bulletSpacing = 5.0;
  static const String bulletCharacter = '-';     // ASCII dash (universal)
  static const String bulletAlternative = '>';   // ASCII arrow (universal)
  static const String bulletDot = '*';           // ASCII asterisk (universal)

  // ============================================================================
  // CONTACT LABELS (text-based for universal font compatibility)
  // ============================================================================

  // Contact label letters (displayed in circular badges)
  static const String iconEmail = 'E';        // Email
  static const String iconPhone = 'T';        // Telephone
  static const String iconLocation = 'A';     // Address
  static const String iconLink = 'W';         // Web
  static const String iconLinkedIn = 'in';    // LinkedIn
  static const String iconWebsite = 'W';      // Website
  static const String iconCalendar = 'D';     // Date

  // Contact badge settings
  static const double contactBadgeSize = 16.0;
  static const double contactBadgeFontSize = 8.0;

  // ============================================================================
  // ACCENT COLOR PRESETS (for PDF template customization)
  // ============================================================================

  static const Map<String, int> accentColorPresets = {
    'Navy': 0xFF1E3A5F,
    'Teal': 0xFF0F766E,
    'Burgundy': 0xFF7C2D2D,
    'Forest': 0xFF166534,
    'Slate': 0xFF475569,
    'Indigo': 0xFF4338CA,
    'Rose': 0xFFBE185D,
    'Amber': 0xFFB45309,
    'Charcoal': 0xFF374151,
    'Ocean': 0xFF0369A1,
  };

  // ============================================================================
  // LETTER SPACING (TRACKING)
  // ============================================================================

  /// Tight letter spacing for headings
  static const double letterSpacingTight = -0.3;

  /// Normal letter spacing
  static const double letterSpacingNormal = 0.0;

  /// Wide letter spacing for small caps
  static const double letterSpacingWide = 1.2;

  /// Extra wide for section headings
  static const double letterSpacingExtraWide = 2.0;

  // ============================================================================
  // PHOTO/AVATAR SETTINGS
  // ============================================================================

  static const double photoSizeLarge = 100.0;
  static const double photoSizeMedium = 80.0;
  static const double photoSizeSmall = 60.0;
  static const double photoRadiusFull = 50.0;  // Circular
  static const double photoRadiusRounded = 8.0; // Rounded rectangle

  // ============================================================================
  // TIMELINE GRAPHICS
  // ============================================================================

  static const double timelineWidth = 2.0;
  static const double timelineDotSize = 8.0;
  static const double timelineSpacing = 16.0;

  // ============================================================================
  // COVER LETTER SPECIFIC
  // ============================================================================

  /// Standard paragraph indent for formal letters
  static const double letterParagraphIndent = 0.0;  // Block format (no indent)

  /// Space between paragraphs in cover letter body
  static const double letterParagraphSpacing = 14.0;

  /// Space for signature area
  static const double letterSignatureSpace = 48.0;

  // ============================================================================
  // HELPER METHODS
  // ============================================================================

  /// Get opacity value for subtle elements
  static double opacity(double value) => value.clamp(0.0, 1.0);

  /// Apply alpha channel to PdfColor
  static PdfColor withOpacity(PdfColor color, double opacity) {
    final alpha = (opacity * 255).round();
    return PdfColor(color.red, color.green, color.blue, alpha / 255);
  }

  /// Create a lighter version of a color
  static PdfColor lighten(PdfColor color, double amount) {
    final r = (color.red + (1 - color.red) * amount).clamp(0.0, 1.0);
    final g = (color.green + (1 - color.green) * amount).clamp(0.0, 1.0);
    final b = (color.blue + (1 - color.blue) * amount).clamp(0.0, 1.0);
    return PdfColor(r, g, b);
  }

  /// Create a darker version of a color
  static PdfColor darken(PdfColor color, double amount) {
    final r = (color.red * (1 - amount)).clamp(0.0, 1.0);
    final g = (color.green * (1 - amount)).clamp(0.0, 1.0);
    final b = (color.blue * (1 - amount)).clamp(0.0, 1.0);
    return PdfColor(r, g, b);
  }
}
