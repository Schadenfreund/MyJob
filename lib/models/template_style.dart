import 'package:flutter/material.dart';

/// Template styles for PDF generation
enum TemplateType {
  professional('Professional', 'Clean and minimalist design'),
  modern('Modern', 'Colorful with accent elements'),
  minimalist('Minimalist', 'Ultra-clean with maximum whitespace'),
  classic('Classic', 'Traditional serif fonts, formal business style'),
  elegant('Elegant', 'Sophisticated serif-sans mix with refined spacing');

  const TemplateType(this.label, this.description);
  final String label;
  final String description;
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
    return TemplateStyle(
      type: TemplateType.values.firstWhere(
        (t) => t.name == json['type'],
        orElse: () => TemplateType.professional,
      ),
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

  /// Professional template preset
  static TemplateStyle get professional => TemplateStyle(
        type: TemplateType.professional,
        primaryColor: const Color(0xFF2C3E50),
        accentColor: const Color(0xFF3498DB),
      );

  /// Modern template preset with orange accent
  static TemplateStyle get modernOrange => TemplateStyle(
        type: TemplateType.modern,
        primaryColor: const Color(0xFFE67E22),
        accentColor: const Color(0xFF27AE60),
        twoColumnLayout: true,
      );

  /// Modern template preset with blue accent
  static TemplateStyle get modernBlue => TemplateStyle(
        type: TemplateType.modern,
        primaryColor: const Color(0xFF3498DB),
        accentColor: const Color(0xFFF1C40F),
        twoColumnLayout: true,
      );

  /// Modern template preset with green accent
  static TemplateStyle get modernGreen => TemplateStyle(
        type: TemplateType.modern,
        primaryColor: const Color(0xFF27AE60),
        accentColor: const Color(0xFF2C3E50),
        twoColumnLayout: true,
      );

  /// Minimalist template preset
  static TemplateStyle get minimalist => TemplateStyle(
        type: TemplateType.minimalist,
        primaryColor: const Color(0xFF000000),
        accentColor: const Color(0xFF666666),
        fontFamily: 'Helvetica',
      );

  /// Classic template preset
  static TemplateStyle get classic => TemplateStyle(
        type: TemplateType.classic,
        primaryColor: const Color(0xFF1A237E),
        accentColor: const Color(0xFF0D47A1),
        fontFamily: 'Times',
      );

  /// Elegant template preset
  static TemplateStyle get elegant => TemplateStyle(
        type: TemplateType.elegant,
        primaryColor: const Color(0xFF4A148C),
        accentColor: const Color(0xFF6A1B9A),
        fontFamily: 'Georgia',
        twoColumnLayout: true,
      );

  /// Get all available presets
  static List<TemplateStyle> get allPresets => [
        professional,
        modernBlue,
        minimalist,
        classic,
        elegant,
      ];
}
