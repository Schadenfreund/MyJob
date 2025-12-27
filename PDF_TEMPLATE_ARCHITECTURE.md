# PDF Template Architecture - DRY & Extensible Design

## Overview
This document describes the refactored PDF template system that follows DRY (Don't Repeat Yourself) principles and makes it easy to add new custom layouts.

## Architecture

### Core Components

```
lib/pdf/
├── core/
│   ├── base_cv_template.dart       # DRY base class with shared functionality
│   └── customized_constants.dart   # Customization helper
├── cv_templates/
│   ├── professional_cv_template.dart  # Single-column layout
│   ├── modern_cv_template.dart        # Two-column with sidebar
│   ├── yellow_cv_template.dart        # Magazine-style layout
│   └── executive_cv_template.dart     # Executive layout
├── cover_letter_templates/
│   └── ... (cover letter templates)
└── shared/
    └── pdf_components.dart         # Centralized reusable components
```

## Key Principles

### 1. **DRY Base Template** (`base_cv_template.dart`)

All CV templates inherit common functionality:

```dart
// Shared sections (Experience, Education, Skills, etc.)
BaseCvTemplate.buildStandardSections(cv, colors, customization)

// Image loading with customization support
BaseCvTemplate.loadProfileImage(bytes, customization)

// Color extraction
BaseCvTemplate.getColors(style)

// Customization helper
BaseCvTemplate.getCustomization(customization)
```

### 2. **Centralized Components** (`pdf_components.dart`)

Reusable widgets used across all templates:

- **Headers**: `buildSectionHeaderDivider()`
- **Contact**: `buildContactRowWithIcons()`
- **Experience**: `buildExperienceEntry()`
- **Education**: `buildEducationEntry()`
- **Skills**:
  - `buildSkillBadgesWithLevels()` - For light backgrounds
  - `buildSkillBarsWhite()` - For dark backgrounds (sidebar)
- **Text**: `buildParagraph()`, `buildInlineList()`

### 3. **Customization Support**

All templates support live customization via `TemplateCustomization`:

```dart
class TemplateCustomization {
  final double spacingScale;        // 0.8 - 1.5
  final double fontSizeScale;       // 0.85 - 1.2
  final double sidebarWidthRatio;   // 0.25 - 0.40 (for 2-column)
  final bool showProfilePhoto;
  final bool showDividers;
  final bool uppercaseHeaders;
}
```

## Template Structure

Each template follows this pattern:

```dart
class MyCustomCvTemplate {
  static void build(
    pw.Document pdf,
    CvData cv,
    TemplateStyle style, {
    Uint8List? profileImageBytes,
    TemplateCustomization? customization,
  }) {
    // 1. Use base helpers (DRY)
    final custom = BaseCvTemplate.getCustomization(customization);
    final colors = BaseCvTemplate.getColors(style);
    final profileImage = BaseCvTemplate.loadProfileImage(profileImageBytes, custom);

    // 2. Build template-specific layout
    pdf.addPage(
      pw.Page(
        build: (context) => [
          // Your custom header/layout
          _buildCustomHeader(cv, colors, profileImage),

          // Standard sections (DRY - automatically includes all sections)
          ...BaseCvTemplate.buildStandardSections(cv, colors.primary, colors.accent, custom),
        ],
      ),
    );
  }

  // 3. Template-specific helper methods
  static pw.Widget _buildCustomHeader(...) { ... }
}
```

## How to Add a New Template

### Step 1: Create Template File

```dart
// lib/pdf/cv_templates/my_awesome_template.dart
import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../../models/cv_data.dart';
import '../../models/template_style.dart';
import '../../models/template_customization.dart';
import '../core/base_cv_template.dart';
import '../shared/pdf_components.dart';

class MyAwesomeCvTemplate {
  static void build(
    pw.Document pdf,
    CvData cv,
    TemplateStyle style, {
    required pw.Font regularFont,
    required pw.Font boldFont,
    required pw.Font mediumFont,
    Uint8List? profileImageBytes,
    TemplateCustomization? customization,
  }) {
    // Use base helpers (DRY)
    final custom = BaseCvTemplate.getCustomization(customization);
    final colors = BaseCvTemplate.getColors(style);
    final profileImage = BaseCvTemplate.loadProfileImage(profileImageBytes, custom);
    final fontFallback = [regularFont, boldFont, mediumFont];

    // Your unique layout
    pdf.addPage(
      pw.Page(
        theme: pw.ThemeData.withFont(
          base: regularFont,
          bold: boldFont,
          fontFallback: fontFallback,
        ),
        build: (context) => pw.Column(
          children: [
            // Custom header
            _buildAwesomeHeader(cv, colors, profileImage),

            // Reuse standard sections (DRY)
            ...BaseCvTemplate.buildStandardSections(cv, colors.primary, colors.accent, custom),
          ],
        ),
      ),
    );
  }

  static pw.Widget _buildAwesomeHeader(cv, colors, image) {
    // Your unique header design
    return pw.Container(...);
  }
}
```

### Step 2: Register in Template Enum

```dart
// lib/models/template_style.dart
enum TemplateType {
  professional,
  modern,
  creative,
  yellow,
  myAwesome,  // ← Add your template
}
```

### Step 3: Add to Template Service

```dart
// lib/services/cv_template_pdf_service.dart
switch (style.type) {
  case TemplateType.myAwesome:
    MyAwesomeCvTemplate.build(
      pdf,
      cvData,
      style,
      regularFont: regularFont,
      boldFont: boldFont,
      mediumFont: mediumFont,
      profileImageBytes: profileImageBytes,
      customization: customization,
    );
  // ... other templates
}
```

### Step 4: Add Style Preset (Optional)

```dart
// lib/models/template_style.dart
static TemplateStyle get myAwesome => TemplateStyle(
  type: TemplateType.myAwesome,
  primaryColor: const Color(0xFF123456),
  accentColor: const Color(0xFF654321),
);
```

That's it! Your new template:
- ✅ Automatically gets all standard sections
- ✅ Supports full customization
- ✅ Works with live preview
- ✅ Integrates with existing UI

## Benefits

### 🔄 **DRY Compliance**
- Standard sections defined once in `BaseCvTemplate`
- Reusable components in `PdfComponents`
- No code duplication across templates

### 🎨 **Easy Customization**
- Single `TemplateCustomization` model
- Live preview with instant updates
- Consistent behavior across all templates

### ➕ **Simple Extension**
- Add new templates in ~50 lines
- Focus on unique layout, reuse everything else
- No need to reimplement sections

### 🛠️ **Maintainability**
- Bug fixes in one place benefit all templates
- Easy to add new sections globally
- Clear separation of concerns

## Example: Template Comparison

### Old Way (Repetitive)
```dart
// Every template repeats 200+ lines
class Template1 {
  // Build experience section
  if (cv.experiences.isNotEmpty) {
    // 50 lines of code
  }
  // Build education section
  if (cv.education.isNotEmpty) {
    // 40 lines of code
  }
  // ... more repetition
}

class Template2 {
  // Duplicate the same 200+ lines
}
```

### New Way (DRY)
```dart
class Template1 {
  // Custom header (20 lines)
  _buildHeader();
  // Reuse standard sections (1 line!)
  ...BaseCvTemplate.buildStandardSections();
}

class Template2 {
  // Different header (20 lines)
  _buildDifferentHeader();
  // Same standard sections (1 line!)
  ...BaseCvTemplate.buildStandardSections();
}
```

**Result**: ~90% code reduction, 100% consistency

## Customization in UI

Users can customize templates via the PDF preview dialog:

1. **Template Style** - Select Professional/Modern/Creative/Yellow
2. **Accent Color** - Choose from 10 professional colors
3. **Layout Customization** (expandable section):
   - Spacing slider (80-150%)
   - Font size slider (85-120%)
   - Profile photo toggle
   - Section dividers toggle
   - Uppercase headers toggle

All changes reflect in real-time PDF preview!

## Future Enhancements

Easy to add:
- [ ] More layout templates (grid, timeline, infographic)
- [ ] Color themes presets
- [ ] Advanced typography options
- [ ] Multi-language support
- [ ] Export customization presets
