# Cover Letter Refactoring Plan

## Objective
Refactor cover letter templates to:
1. Match CV template designs (Electric/Professional)
2. Add language toggle support
3. Use centralized, clean components
4. Support all customization options

## Current State Analysis

### Existing Templates:
1. **electric_cover_letter_template.dart** (13KB)
2. **professional_cover_letter_template.dart** (10KB)

### Issues:
- Not using centralized PdfStyling fully
- No language translation
- Custom header building instead of HeaderComponent
- Date formatting hardcoded
- Missing customization integration

## Refactoring Strategy

### Phase 1: Add Language Support (PRIORITY)

#### 1.1 Extend CvTranslations
Add cover letter specific translations:
```dart
// In cv_translations.dart
static const Map<String, String> _coverLetterTranslations = {
  'Dear': 'Sehr geehrte/r',
  'Sincerely': 'Mit freundlichen Grüßen',
  'Best regards': 'Beste Grüße',
  // Date formats handled by translateDate()
};
```

#### 1.2 Update Cover Letter Model
- Ensure CoverLetter model has access to language setting
- Pass language through template customization

#### 1.3 Apply Translations
- Translate date at top of letter
- Support German greetings
- Translate standard closings

### Phase 2: Use Centralized Components

#### 2.1 Use HeaderComponent
Replace custom `_buildHeroHeader` with:
```dart
HeaderComponent.build(
  name: contactDetails?.fullName,
  title: coverLetter.position,
  contact: contactDetails,
  styling: s,
  layout: HeaderLayout.modern, // or clean based on template
)
```

#### 2.2 Centralize Date Formatting
Use `CvTranslations.translateDate()` for dates

#### 2.3 Create CoverLetterComponent (if needed)
For letter-specific content like body paragraphs

### Phase 3: Match CV Designs

#### 3.1 Electric Template
- Use same accent colors and spacing as Electric CV
- Match header design exactly
- Use same typography scale

#### 3.2 Professional Template
- Match Professional CV styling
- Consistent spacing and layout
- Same color tokens

### Phase 4: Integration

#### 4.1 PDF Editor Support
- Add language toggle to cover letter editor
- Ensure customization persists
- Use same PdfEditorController pattern

#### 4.2 Preview System
- Ensure cover letter preview uses same editor UI
- Language toggle works in preview

## Implementation Order

1. ✅ **Quick Win**: Add `translateCoverLetterText()` method
2. ✅ **Core**: Apply translations to date and standard phrases
3. ✅ **Cleanup**: Use HeaderComponent instead of custom headers
4. ✅ **Polish**: Ensure visual consistency with CV templates
5. ✅ **Test**: Verify language toggle works in cover letter editor

## Files to Modify

### Core Files:
- `lib/pdf/shared/cv_translations.dart` - Add cover letter translations
- `lib/pdf/cover_letter_templates/electric_cover_letter_template.dart`
- `lib/pdf/cover_letter_templates/professional_cover_letter_template.dart`

### Supporting Files:
- Cover letter editor/preview dialogs (if they exist)
- Any cover letter-specific widgets

## Testing Checklist

- [ ] Language toggle appears in cover letter editor
- [ ] Date translates to German when language switched
- [ ] "Dear" → "Sehr geehrte/r"
- [ ] "Sincerely" → "Mit freundlichen Grüßen"
- [ ] Header matches CV header design
- [ ] Colors and spacing match CV template
- [ ] Settings persist across app restarts
- [ ] All customization options work

## Notes

- Keep templates simple and maintainable
- Reuse CV components where possible
- Ensure consistency across CV and cover letter
- Test with both English and German content
