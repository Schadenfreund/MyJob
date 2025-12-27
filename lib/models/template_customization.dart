/// Template customization parameters for PDF templates
class TemplateCustomization {
  final double spacingScale;
  final double fontSizeScale;
  final double sidebarWidthRatio;
  final bool showProfilePhoto;
  final bool showDividers;
  final bool uppercaseHeaders;

  const TemplateCustomization({
    this.spacingScale = 1.0,
    this.fontSizeScale = 1.0,
    this.sidebarWidthRatio = 0.32,
    this.showProfilePhoto = true,
    this.showDividers = true,
    this.uppercaseHeaders = true,
  });

  TemplateCustomization copyWith({
    double? spacingScale,
    double? fontSizeScale,
    double? sidebarWidthRatio,
    bool? showProfilePhoto,
    bool? showDividers,
    bool? uppercaseHeaders,
  }) {
    return TemplateCustomization(
      spacingScale: spacingScale ?? this.spacingScale,
      fontSizeScale: fontSizeScale ?? this.fontSizeScale,
      sidebarWidthRatio: sidebarWidthRatio ?? this.sidebarWidthRatio,
      showProfilePhoto: showProfilePhoto ?? this.showProfilePhoto,
      showDividers: showDividers ?? this.showDividers,
      uppercaseHeaders: uppercaseHeaders ?? this.uppercaseHeaders,
    );
  }
}
