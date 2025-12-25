# MyLife App - CV & Cover Letter Creator

## ✅ Completed Features

### Core Functionality
- **YAML Import System** - Import CV data from YAML files with automatic template creation
- **5 PDF Template Styles** - Professional, Modern, Minimalist, Classic, Elegant
- **Template-Specific Rendering** - Each style has distinct margins, fonts, colors, and decorations
- **Full PDF Preview** - Real-time preview with export capability
- **Template Management** - Create, duplicate, delete CV and cover letter templates
- **Application Tracking** - Light tracking for where documents were sent

### UI Components
- **Custom Titlebar** - Integrated tabs with 3 main sections (Documents, Tracking, Settings)
- **YAML Import Section** - Beautiful import buttons with hover effects and gradient backgrounds
- **Document Template Cards** - Action-rich cards with PDF generation, edit, duplicate, delete
- **Template Style Picker** - 5 template presets with color swatches and feature chips
- **PDF Preview Dialog** - Full-screen preview with export to file
- **Settings Screen** - Theme toggle, accent colors, app info

### Template Types
| Template | Margins | Style |
|----------|---------|-------|
| **Professional** | 40px | Standard accent colors, clean layout |
| **Modern** | 40px | Vibrant colors, two-column support |
| **Minimalist** | 60px | Large whitespace, black text, no underlines |
| **Classic** | 50px | Traditional, formal, wide letter spacing |
| **Elegant** | 40px | Sophisticated, serif-inspired, refined |

## Architecture

### Data Flow
```
YAML File → YamlImportService → TemplatesProvider → CvTemplate/CoverLetterTemplate
                                        ↓
                              Template Style Picker
                                        ↓
                              CvPdfService (with TemplateType)
                                        ↓
                              PDF Preview/Export
```

### Key Files
```
lib/
├── dialogs/
│   ├── pdf_preview_dialog.dart      # Full PDF preview with export
│   ├── template_style_picker_dialog.dart  # 5 template style selection
│   └── yaml_import_dialog.dart      # YAML file picker and parser
├── models/
│   ├── template_style.dart          # TemplateType enum + TemplateStyle config
│   ├── cv_template.dart             # CV template model
│   └── cover_letter_template.dart   # Cover letter template model
├── providers/
│   ├── templates_provider.dart      # CRUD for templates and instances
│   ├── applications_provider.dart   # Application tracking
│   └── user_data_provider.dart      # User personal info, skills, etc.
├── screens/
│   ├── documents/documents_screen.dart  # Main YAML import + template list
│   ├── applications/applications_screen.dart  # Simplified tracking
│   └── settings/settings_screen.dart    # App settings
├── services/
│   ├── cv_pdf_service.dart          # PDF generation with template variants
│   ├── yaml_import_service.dart     # YAML parsing
│   └── templates_storage_service.dart  # Persistence
└── widgets/
    ├── yaml_import_section.dart     # Import UI with hover effects
    ├── document_template_card.dart  # Template card with actions
    └── template_style_card.dart     # Style picker card
```

## Usage

### Creating a CV
1. **Import YAML** - Click "Import CV YAML" and select your cv_data.yaml file
2. **Generate PDF** - Click "Generate PDF" on the created template card
3. **Choose Style** - Select one of 5 professional template styles
4. **Preview & Export** - Review the PDF and export to your desired location

### YAML File Format
```yaml
personal_info:
  full_name: "John Doe"
  email: "john@example.com"
  phone: "+1 234 567 890"
  profile_summary: "Experienced developer..."

work_experience:
  - company: "Tech Corp"
    position: "Senior Developer"
    start_date: "2020-01-01"
    responsibilities:
      - "Led team of 5 developers"
      - "Implemented CI/CD pipelines"

skills:
  - name: "Python"
    category: "Programming"
    level: "expert"

languages:
  - name: "English"
    proficiency: "native"
```

## Technical Details

### PDF Generation
- Uses `pdf` and `printing` packages
- Google Fonts (Inter family) for professional typography
- Template-specific margins, colors, and decorations
- Accent color customization from app settings

### State Management
- Provider pattern for all state
- TemplatesProvider for template CRUD
- UserDataProvider for personal info used in PDFs
- SettingsService for app preferences

### Storage
- JSON-based local storage in UserData directory
- Separate files for templates and instances
- Auto-save on changes

## Future Enhancements
- [ ] Cover letter PDF generation
- [ ] Template editing UI
- [ ] Photo support in CV
- [ ] Multiple language versions
- [ ] Export history
