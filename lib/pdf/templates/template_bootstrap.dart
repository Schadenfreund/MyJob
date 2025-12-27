import '../core/template_registry.dart';
import 'professional_classic_template.dart';
import 'modern_sidebar_template.dart';
import 'creative_executive_template.dart';
import 'yellow_contrast_template.dart';

/// Bootstrap all PDF templates
///
/// This function should be called during app initialization to register
/// all available PDF templates in the TemplateRegistry.
///
/// Call this from your app's main() function or initState():
/// ```dart
/// void main() {
///   bootstrapTemplates();
///   runApp(MyApp());
/// }
/// ```
void bootstrapTemplates() {
  final registry = TemplateRegistry.instance;

  // Clear existing registrations (useful for hot reload)
  registry.clear();

  // Register Professional Classic template
  registry.register(
    const ProfessionalClassicCvTemplate(),
    const ProfessionalClassicCoverLetterTemplate(),
  );

  // Register Modern Sidebar template
  registry.register(
    const ModernSidebarCvTemplate(),
    const ModernSidebarCoverLetterTemplate(),
  );

  // Register Creative Executive template
  registry.register(
    const CreativeExecutiveCvTemplate(),
    const CreativeExecutiveCoverLetterTemplate(),
  );

  // Register Yellow Contrast template
  registry.register(
    const YellowContrastCvTemplate(),
    const YellowContrastCoverLetterTemplate(),
  );

  // TODO: Add new templates here following the same pattern:
  // registry.register(
  //   const NewCvTemplate(),
  //   const NewCoverLetterTemplate(),
  // );
}

/// Get the template ID for a given TemplateType (for backwards compatibility)
///
/// Maps old TemplateType enum values to new template IDs
String getTemplateIdFromType(dynamic templateType) {
  // Handle TemplateType enum
  final typeName = templateType.toString().split('.').last;

  switch (typeName) {
    case 'professional':
      return 'professional_classic';
    case 'modern':
      return 'modern_sidebar';
    case 'creative':
      return 'creative_executive';
    case 'yellow':
      return 'yellow_contrast';
    default:
      return 'professional_classic'; // Default fallback
  }
}

/// Get TemplateType from template ID (for backwards compatibility)
dynamic getTemplateTypeFromId(String templateId) {
  // This is a temporary bridge for migration
  // Eventually, all code should use template IDs directly
  switch (templateId) {
    case 'professional_classic':
      return 'professional';
    case 'modern_sidebar':
      return 'modern';
    case 'creative_executive':
      return 'creative';
    case 'yellow_contrast':
      return 'yellow';
    default:
      return 'professional';
  }
}
