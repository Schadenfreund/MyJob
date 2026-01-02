# PDF Template System Architecture

This document describes the PDF template system for CV and Cover Letter generation.

## Directory Structure

```
lib/pdf/
├── shared/                    # Shared utilities and base classes
│   ├── base_pdf_template.dart    # Base template class (extend this!)
│   ├── pdf_styling.dart          # Theme-aware styling system
│   ├── pdf_icons.dart            # Icon library for PDF
│   └── template_registry.dart    # Template registration
├── components/               # Reusable PDF components
│   ├── header_component.dart     # Header layouts
│   ├── section_component.dart    # Section headers
│   ├── experience_component.dart # Work experience layouts
│   ├── skills_component.dart     # Skill rendering
│   ├── contact_component.dart    # Contact info
│   ├── icon_component.dart       # Icon rendering
│   └── layout_component.dart     # Layout helpers
├── cv_templates/             # CV template implementations
│   ├── professional_cv_template.dart  # Main flexible template
│   └── electric_cv_template.dart      # Legacy template
└── cover_letter_templates/   # Cover letter implementations
    ├── electric_cover_letter_template.dart
    └── professional_cover_letter_template.dart
```

## Adding a New Template

### 1. Create the Template Class

```dart
// lib/pdf/cv_templates/my_new_template.dart
import 'dart:typed_data';
import 'package:pdf/widgets.dart' as pw;
import '../../models/cv_data.dart';
import '../../models/template_style.dart';
import '../../models/template_customization.dart';
import '../shared/pdf_styling.dart';
import '../shared/base_pdf_template.dart';
import '../components/components.dart';

class MyNewCvTemplate extends BasePdfTemplate<CvData> with PdfTemplateHelpers {
  // Private constructor for singleton
  MyNewCvTemplate._();
  
  // Singleton instance
  static final instance = MyNewCvTemplate._();

  @override
  TemplateInfo get info => const TemplateInfo(
    id: 'my_new_cv',
    name: 'My New Style',
    description: 'A fresh, modern design with unique features',
    category: 'cv',
    previewTags: ['modern', 'creative', 'unique'],
  );

  @override
  Future<Uint8List> build(
    CvData cv,
    TemplateStyle style, {
    TemplateCustomization? customization,
    Uint8List? profileImageBytes,
  }) async {
    // Create PDF document
    final pdf = createDocument();
    
    // Load fonts based on selected family
    final fonts = await loadFonts(style);
    
    // Create styling (respects dark mode, accent color, etc.)
    final s = PdfStyling(style: style, customization: customization);
    
    // Get profile image if provided
    final profileImage = getProfileImage(profileImageBytes);

    // Add your pages
    pdf.addPage(
      pw.MultiPage(
        pageTheme: PdfPageThemes.standard(
          regularFont: fonts.regular,
          boldFont: fonts.bold,
          mediumFont: fonts.medium,
          styling: s,
        ),
        build: (context) => [
          // Use components for consistent styling
          HeaderComponent.cvHeader(
            name: cv.contactDetails?.fullName ?? 'Your Name',
            title: cv.contactDetails?.jobTitle,
            contact: cv.contactDetails,
            styling: s,
            profileImage: profileImage,
            layout: HeaderLayout.modern,
          ),
          
          pw.SizedBox(height: s.sectionGapMajor),
          
          // Add more sections...
        ],
      ),
    );

    return pdf.save();
  }
}
```

### 2. Register the Template

In `lib/pdf/shared/template_registry.dart`:

```dart
import '../cv_templates/my_new_template.dart';

class PdfTemplateRegistry {
  // Add to the CV templates list
  static final List<BasePdfTemplate<CvData>> cvTemplates = [
    ProfessionalCvTemplate.instance,
    ElectricCvTemplate.instance,
    MyNewCvTemplate.instance,  // Add your template here!
  ];
}
```

## Key Concepts

### PdfStyling

The `PdfStyling` class provides theme-aware colors and spacing:

```dart
final s = PdfStyling(style: style, customization: customization);

// Colors (auto-switch for dark/light mode)
s.accent          // Accent color from theme
s.textPrimary     // Primary text color
s.textSecondary   // Secondary text color
s.background      // Page background
s.headerBackground // Header background (usually black)
s.headerText      // Text on header (usually white)

// Spacing (respects customization.spacingScale)
s.space1, s.space2, s.space3, s.space4, s.space5, s.space6
s.sectionGapMajor // Gap between major sections
s.sectionGapMinor // Gap within sections

// Typography (respects customization.fontSizeScale)
s.fontSizeH1, s.fontSizeH2, s.fontSizeH3
s.fontSizeBody, s.fontSizeSmall, s.fontSizeTiny
```

### Components

Use components for consistent styling across templates:

- `HeaderComponent` - CV/letter headers
- `SectionComponent` - Section headers with icons
- `ExperienceComponent` - Work experience entries
- `SkillsComponent` - Skill tags/bars
- `ContactComponent` - Contact information
- `IconComponent` - Section icons

### TemplateCustomization

Users can customize:

```dart
customization.layoutMode        // Modern, Sidebar, Traditional, Compact
customization.spacingScale      // 0.7 to 1.3
customization.fontSizeScale     // 0.8 to 1.2
customization.lineHeight        // 1.2 to 1.8
customization.showDividers      // true/false
customization.showContactIcons  // true/false
customization.headerStyle       // Modern, Clean, Sidebar, Compact
customization.experienceStyle   // Timeline, List, Cards, Compact
```

## Best Practices

1. **Always use `PdfStyling`** - Don't hardcode colors or sizes
2. **Use components** - Ensures consistent look across templates
3. **Support dark mode** - Use `s.textPrimary`, not `PdfColors.black`
4. **Respect customization** - Use `s.space*` instead of fixed values
5. **Use singleton pattern** - Private constructor + static instance
6. **Document your template** - Add TemplateInfo with good description
