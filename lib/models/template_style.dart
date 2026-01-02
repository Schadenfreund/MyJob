import 'package:flutter/material.dart';
import 'pdf_font_family.dart';

/// Template styles for PDF generation - Magazine-inspired layouts
enum TemplateType {
  /// Electric high-contrast magazine-style layout with bold design
  electric('Electric',
      'Bold magazine-style layout with electric yellow accents and modern brutalist aesthetic');

  const TemplateType(this.label, this.description);
  final String label;
  final String description;

  // Map old enum values to new Electric template for backwards compatibility
  static TemplateType fromName(String name) {
    // All old templates map to electric now
    return TemplateType.electric;
  }
}

/// Configuration for document template styling
class TemplateStyle {
  TemplateStyle({
    required this.type,
    this.primaryColor = const Color(0xFF000000), // Black
    this.accentColor = const Color(0xFFFFFF00), // Electric Yellow
    this.fontFamily = PdfFontFamily.roboto,
    this.showPhoto = true,
    this.twoColumnLayout = false,
    this.isDarkMode = true, // Dark mode by default for magazine-style look
  });

  factory TemplateStyle.fromJson(Map<String, dynamic> json) {
    // Use TemplateType.fromName for backwards compatibility with old enum values
    final typeName = json['type'] as String? ?? 'electric';

    // Parse font family from string (backwards compatible)
    PdfFontFamily fontFamily = PdfFontFamily.roboto;
    final fontFamilyStr = json['fontFamily'] as String?;
    if (fontFamilyStr != null) {
      try {
        fontFamily = PdfFontFamily.values.firstWhere(
          (e) => e.name == fontFamilyStr.toLowerCase(),
          orElse: () => PdfFontFamily.roboto,
        );
      } catch (_) {
        fontFamily = PdfFontFamily.roboto;
      }
    }

    return TemplateStyle(
      type: TemplateType.fromName(typeName),
      primaryColor: Color(json['primaryColor'] as int? ?? 0xFF000000),
      accentColor: Color(json['accentColor'] as int? ?? 0xFFFFFF00),
      fontFamily: fontFamily,
      showPhoto: json['showPhoto'] as bool? ?? true,
      twoColumnLayout: json['twoColumnLayout'] as bool? ?? false,
      isDarkMode: json['isDarkMode'] as bool? ?? true, // Dark mode by default
    );
  }

  final TemplateType type;
  final Color primaryColor;
  final Color accentColor;
  final PdfFontFamily fontFamily;
  final bool showPhoto;
  final bool twoColumnLayout;
  final bool isDarkMode;

  Map<String, dynamic> toJson() => {
        'type': type.name,
        'primaryColor': primaryColor.toARGB32(),
        'accentColor': accentColor.toARGB32(),
        'fontFamily': fontFamily.name,
        'showPhoto': showPhoto,
        'twoColumnLayout': twoColumnLayout,
        'isDarkMode': isDarkMode,
      };

  TemplateStyle copyWith({
    TemplateType? type,
    Color? primaryColor,
    Color? accentColor,
    PdfFontFamily? fontFamily,
    bool? showPhoto,
    bool? twoColumnLayout,
    bool? isDarkMode,
  }) {
    return TemplateStyle(
      type: type ?? this.type,
      primaryColor: primaryColor ?? this.primaryColor,
      accentColor: accentColor ?? this.accentColor,
      fontFamily: fontFamily ?? this.fontFamily,
      showPhoto: showPhoto ?? this.showPhoto,
      twoColumnLayout: twoColumnLayout ?? this.twoColumnLayout,
      isDarkMode: isDarkMode ?? this.isDarkMode,
    );
  }

  /// Electric template - High-contrast magazine style with electric yellow
  /// Now uses dark mode by default for a more striking appearance
  static TemplateStyle get electric => TemplateStyle(
        type: TemplateType.electric,
        primaryColor: const Color(0xFF000000), // Black
        accentColor: const Color(0xFFFFFF00), // Electric Yellow
        fontFamily: PdfFontFamily.roboto,
        twoColumnLayout: false,
        showPhoto: true,
        isDarkMode: true, // Dark mode by default
      );

  /// Get all available presets (currently just Electric)
  static List<TemplateStyle> get allPresets => [
        electric,
      ];

  /// Default template (Electric)
  static TemplateStyle get defaultStyle => electric;
}
