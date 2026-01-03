# Cover Letter Template Restructuring Plan

## Goal
Reduce cover letter presets to 3 clean options:
1. **Modern** - Match CV Modern style (accent color top bar)
2. **Modern 2** - Current Electric/bold design
3. **Classic** - Conservative, traditional design

## Current State
- ElectricCoverLetterTemplate.dart (bold, magazine-style)
- ProfessionalCoverLetterTemplate.dart (clean, flexible)

## Implementation Plan

### Phase 1: Rename & Reorganize Templates

1. **Rename ElectricCoverLetterTemplate → ModernTwoCoverLetterTemplate**
   - File: `electric_cover_letter_template.dart` → `modern_two_cover_letter_template.dart`
   - Class: `ElectricCoverLetterTemplate` → `ModernTwoCoverLetterTemplate`
   - Keep current bold design

2. **Rename ProfessionalCoverLetterTemplate → ModernCoverLetterTemplate**
   - File: `professional_cover_letter_template.dart` → `modern_cover_letter_template.dart`
   - Class: `ProfessionalCoverLetterTemplate` → `ModernCoverLetterTemplate`
   - Update to match CV Modern style with accent top bar

3. **Create ClassicCoverLetterTemplate**
   - New file: `classic_cover_letter_template.dart`
   - Conservative design:
     - Simple header with name centered or left-aligned
     - No bold colors or accents
     - Traditional serif font feel
     - Clean spacing
     - Minimal decoration

### Phase 2: Update Template Selection Logic

Update `PdfService.generateCoverLetterPdf()`:
```dart
if (style.type == TemplateType.electric) {
  ModernTwoCoverLetterTemplate.build(...);
} else if (style.type == TemplateType.professional) {
  ModernCoverLetterTemplate.build(...);
} else {
  // For Traditional, Compact, Sidebar → use Classic
  ClassicCoverLetterTemplate.build(...);
}
```

### Phase 3: Update Template Mapping

Map TemplateStyle types to cover letter templates:
- `TemplateType.electric` → Modern 2
- `TemplateType.professional` → Modern
- `TemplateType.traditional` → Classic
- `TemplateType.compact` → Classic
- `TemplateType.sidebar` → Classic

## Design Specifications

### Modern (matching CV Modern)
- **Header**: Accent color bar at top (8px height)
- **Name**: Large, bold, black
- **Contact**: Icons with text, wrapped
- **Date**: With small accent line
- **Body**: Clean paragraphs, good spacing
- **Colors**: Minimal, accent used sparingly

### Modern 2 (current Electric)
- **Header**: Bold black background, accent bars
- **Name**: Large, magazine-style
- **Design**: Geometric accents, asymmetric
- **Date**: With accent bar
- **Body**: Professional with good spacing
- **Colors**: Bold use of accent

### Classic (new, conservative)
- **Header**: Simple centered or left name
- **Contact**: Text-only, no icons
- **Date**: Right-aligned, traditional format
- **Body**: Justified paragraphs
- **Design**: Minimal, timeless
- **Colors**: Black text only, no accent colors

## Files to Modify

1. `lib/pdf/cover_letter_templates/electric_cover_letter_template.dart`
   - Rename to `modern_two_cover_letter_template.dart`
   - Update class name and comments

2. `lib/pdf/cover_letter_templates/professional_cover_letter_template.dart`
   - Rename to `modern_cover_letter_template.dart`
   - Update to match CV Modern header style

3. Create `lib/pdf/cover_letter_templates/classic_cover_letter_template.dart`

4. `lib/services/pdf_service.dart`
   - Update imports
   - Fix template selection logic

## Testing Checklist

- [ ] Modern preset shows CV Modern-style design
- [ ] Modern 2 preset shows current Electric design
- [ ] Classic preset shows conservative design
- [ ] All translations work in all presets
- [ ] All customization options work
- [ ] Settings persist

## Implementation Order

1. ✅ Create Classic template (simplest, new file)
2. ✅ Update Modern template to match CV (modify existing Professional)
3. ✅ Rename Electric → Modern 2 (file rename + class rename)
4. ✅ Update PdfService template selection
5. ✅ Test all presets
