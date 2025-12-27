import '../../constants/pdf_constants.dart';
import '../../models/template_customization.dart';

/// Helper that applies template customization to PDF constants
class CustomizedConstants {
  final TemplateCustomization customization;

  const CustomizedConstants(this.customization);

  // Typography - Auto-scaled
  double get fontSizeBody => PdfConstants.fontSizeBody * customization.fontSizeScale;
  double get fontSizeH2 => PdfConstants.fontSizeH2 * customization.fontSizeScale;

  // Spacing - Auto-scaled
  double get spaceMd => PdfConstants.spaceMd * customization.spacingScale;
  double get sectionSpacing => PdfConstants.sectionSpacing * customization.spacingScale;

  // Layout
  double get sidebarWidthRatio => customization.sidebarWidthRatio;
  double getSidebarWidth(double pageWidth) => pageWidth * sidebarWidthRatio;

  // Feature toggles
  bool get showProfilePhoto => customization.showProfilePhoto;
  bool get showDividers => customization.showDividers;
  bool get uppercaseHeaders => customization.uppercaseHeaders;

  String formatHeader(String text) {
    return uppercaseHeaders ? text.toUpperCase() : text;
  }
}
