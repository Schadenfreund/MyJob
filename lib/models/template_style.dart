import 'package:flutter/material.dart';

/// Template styles for PDF generation - 3 distinct layouts
enum TemplateType {
  /// Classic single-column layout with traditional typography
  professional('Classic', 'Traditional single-column with elegant typography'),

  /// Modern two-column layout with colored sidebar
  modern('Modern', 'Contemporary two-column with sidebar profile'),

  /// Creative layout with unique visual elements
  creative('Creative', 'Bold design with timeline and accent graphics');

  const TemplateType(this.label, this.description);
  final String label;
  final String description;

  // Map old enum values to new ones for backwards compatibility
  static TemplateType fromName(String name) {
    switch (name) {
      case 'professional':
      case 'minimalist':
      case 'executive':
        return TemplateType.professional;
      case 'modern':
      case 'elegant':
        return TemplateType.modern;
      case 'creative':
      default:
        return TemplateType.creative;
    }
  }
}

/// Configuration for document template styling
class TemplateStyle {
  TemplateStyle({
    required this.type,
    this.primaryColor = const Color(0xFF2C3E50),
    this.accentColor = const Color(0xFF3498DB),
    this.fontFamily = 'Helvetica',
    this.showPhoto = false,
    this.twoColumnLayout = false,
  });

  factory TemplateStyle.fromJson(Map<String, dynamic> json) {
    // Use TemplateType.fromName for backwards compatibility with old enum values
    final typeName = json['type'] as String? ?? 'professional';
    return TemplateStyle(
      type: TemplateType.fromName(typeName),
      primaryColor: Color(json['primaryColor'] as int? ?? 0xFF2C3E50),
      accentColor: Color(json['accentColor'] as int? ?? 0xFF3498DB),
      fontFamily: json['fontFamily'] as String? ?? 'Helvetica',
      showPhoto: json['showPhoto'] as bool? ?? false,
      twoColumnLayout: json['twoColumnLayout'] as bool? ?? false,
    );
  }

  final TemplateType type;
  final Color primaryColor;
  final Color accentColor;
  final String fontFamily;
  final bool showPhoto;
  final bool twoColumnLayout;

  Map<String, dynamic> toJson() => {
        'type': type.name,
        'primaryColor': primaryColor.toARGB32(),
        'accentColor': accentColor.toARGB32(),
        'fontFamily': fontFamily,
        'showPhoto': showPhoto,
        'twoColumnLayout': twoColumnLayout,
      };

  TemplateStyle copyWith({
    TemplateType? type,
    Color? primaryColor,
    Color? accentColor,
    String? fontFamily,
    bool? showPhoto,
    bool? twoColumnLayout,
  }) {
    return TemplateStyle(
      type: type ?? this.type,
      primaryColor: primaryColor ?? this.primaryColor,
      accentColor: accentColor ?? this.accentColor,
      fontFamily: fontFamily ?? this.fontFamily,
      showPhoto: showPhoto ?? this.showPhoto,
      twoColumnLayout: twoColumnLayout ?? this.twoColumnLayout,
    );
  }

  /// Classic template - Traditional single-column with navy blue
  static TemplateStyle get professional => TemplateStyle(
        type: TemplateType.professional,
        primaryColor: const Color(0xFF1E3A5F),
        accentColor: const Color(0xFF2563EB),
      );

  /// Modern template - Two-column with teal sidebar
  static TemplateStyle get modern => TemplateStyle(
        type: TemplateType.modern,
        primaryColor: const Color(0xFF0F766E),
        accentColor: const Color(0xFF14B8A6),
        twoColumnLayout: true,
        showPhoto: true,
      );

  /// Creative template - Bold design with timeline graphics
  static TemplateStyle get creative => TemplateStyle(
        type: TemplateType.creative,
        primaryColor: const Color(0xFF7C3AED),
        accentColor: const Color(0xFFEC4899),
        twoColumnLayout: false,
      );

  /// Get all available presets (3 distinct templates)
  static List<TemplateStyle> get allPresets => [
        professional,
        modern,
        creative,
      ];
}
