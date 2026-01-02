# PDF Template Design Improvement Plan

Comprehensive improvements to CV and Cover Letter PDF templates with professional typography, spacing, layout, and unified design language.

---

## Design Principles & Constraints

### A4 Page Layout Math
| Property | Value | Notes |
|----------|-------|-------|
| **A4 Dimensions** | 595 × 842 pt | Standard PDF points |
| **Normal Margins** | 48pt all sides | ~17mm each side |
| **Narrow Margins** | 36pt all sides | ~12.7mm for more content |
| **Usable Width** | 499pt (normal) / 523pt (narrow) | Available for content |
| **Usable Height** | 746pt (normal) / 770pt (narrow) | Available for content |

### PDF Package Constraints
> [!WARNING]
> These constraints affect what designs are possible:
> - **Cannot use `borderRadius` with non-uniform `Border`** - Use uniform borders or skip radius
> - **`MultiPage` cannot split `Table`/`Row` across pages** - Use single `Page` for two-column
> - **No CSS-like flexbox** - Use `pw.Row`, `pw.Column`, `pw.Expanded` carefully
> - **Limited font embedding** - Use pre-loaded fonts only

---

## Phase 1: Typography Refinement

### Current Problems
- Body text at 10pt is small on printed A4
- No letter-spacing differentiation between headers and body
- Inconsistent line heights

### Typography Scale (1.25× Modular)

| Token | Current | New | Purpose |
|-------|---------|-----|---------|
| `fontSizeH1` | 24pt | 24pt ✓ | Main name/title |
| `fontSizeH2` | 19pt | 19pt ✓ | Section headers |
| `fontSizeH3` | 15pt | 15pt ✓ | Subsection headers |
| `fontSizeH4` | 12pt | 12pt ✓ | Entry titles |
| `fontSizeBody` | **10pt** | **11pt** | Main content |
| `fontSizeSmall` | 9pt | 9pt ✓ | Secondary content |
| `fontSizeTiny` | 8pt | 8pt ✓ | Labels, metadata |

### Letter Spacing Tokens (New)

| Token | Value | Usage |
|-------|-------|-------|
| `letterSpacingTight` | -0.5 | Dense body text |
| `letterSpacingNormal` | 0 | Standard body |
| `letterSpacingRelaxed` | 0.5 | Subtitles |
| `letterSpacingWide` | 1.0 | Section headers |
| `letterSpacingExtraWide` | 1.5 | Name in header |

### Line Height Context

| Context | Value | Getter |
|---------|-------|--------|
| Headers | 1.2 | `lineHeightTight` |
| Body text | 1.4 | `lineHeightNormal` |
| Paragraphs | 1.6 | `lineHeightRelaxed` |

#### [MODIFY] [pdf_styling.dart](file:///c:/Users/iBuri/Desktop/MyLife/lib/pdf/shared/pdf_styling.dart)

```diff
- double get fontSizeBody => 10 * _fontScale;
+ double get fontSizeBody => 11 * _fontScale;  // More readable on printed A4
```

---

## Phase 2: True Two-Column Single-Page Layout

### Design Rationale
- Current "sidebar" mode uses an info bar at top, not true two-column
- `MultiPage` cannot split Table/Row across pages
- **Solution**: Use `pw.Page` (single page) with `LayoutComponent.twoColumn()` Table approach
- Content intelligently fits on ONE page with compact styling

### Two-Column Layout Structure

```
┌────────────────────────────────────────────────┐
│ ████████████  HEADER (Full Width)  ████████████│ ← Accent bar
├───────────────┬────────────────────────────────┤
│   SIDEBAR     │      MAIN CONTENT              │
│   (35%)       │      (65%)                     │
│               │                                │
│ ┌───────────┐ │  PROFESSIONAL SUMMARY          │
│ │  PHOTO    │ │  ────────────────────          │
│ └───────────┘ │  Lorem ipsum dolor sit amet... │
│               │                                │
│ CONTACT       │  EXPERIENCE                    │
│ ─────────     │  ──────────                    │
│ ✉ email       │  Senior Developer | 2020-Now   │
│ ☎ phone       │  Company Name                  │
│ ⌂ address     │  • Achievement 1               │
│               │  • Achievement 2               │
│ SKILLS        │                                │
│ ──────        │  Developer | 2018-2020         │
│ [Python]      │  Previous Company              │
│ [JavaScript]  │  • Achievement                 │
│ [React]       │                                │
│               │  EDUCATION                     │
│ LANGUAGES     │  ─────────                     │
│ ─────────     │  BSc Computer Science          │
│ English (C2)  │  University | 2014-2018        │
│ German (B2)   │                                │
│               │                                │
│ INTERESTS     │                                │
│ ─────────     │                                │
│ Photography   │                                │
│ Hiking        │                                │
└───────────────┴────────────────────────────────┘
```

### Compact Styling for Single-Page Fit
When two-column mode is active, automatically apply:
- `spacingScale: 0.85` (tighter gaps)
- `fontSizeScale: 0.95` (slightly smaller text)
- `lineHeight: 1.3` (tighter line spacing)
- Narrow margins (36pt)
- Truncate long descriptions if needed

### Implementation

#### [MODIFY] [professional_cv_template.dart](file:///c:/Users/iBuri/Desktop/MyLife/lib/pdf/cv_templates/professional_cv_template.dart)

**Key changes:**
1. Check `customization.useTwoColumnLayout` - if true, use `pw.Page` not `pw.MultiPage`
2. Add `_buildTwoColumnSinglePageLayout()` method
3. Build sidebar with: photo, contact, skills, languages, interests
4. Build main column with: summary, experience, education

```dart
// Pseudo-code structure
if (customization?.useTwoColumnLayout == true) {
  pdf.addPage(
    pw.Page(
      pageTheme: PdfPageThemes.contentMargins(...),
      build: (context) => _buildTwoColumnSinglePageLayout(cv, s, profileImage),
    ),
  );
} else {
  pdf.addPage(pw.MultiPage(...)); // Existing multi-page approach
}

pw.Widget _buildTwoColumnSinglePageLayout(...) {
  return pw.Column([
    _buildCompactHeader(...),  // Name + title only, no contact
    pw.SizedBox(height: s.space4),
    LayoutComponent.twoColumn(
      sidebarWidth: 0.35,
      sidebar: _buildSidebarColumn(...),
      mainContent: _buildMainColumn(...),
    ),
  ]);
}
```

---

## Phase 3: Cover Letter Integration

### Current Problems
- Hardcoded spacing: `48`, `32`, `24`, `16`, `20`
- Hardcoded font sizes: `36`, `12`, `11`, `10`, `9`
- No customization support for spacing/fonts

### Changes

#### [MODIFY] [electric_cover_letter_template.dart](file:///c:/Users/iBuri/Desktop/MyLife/lib/pdf/cover_letter_templates/electric_cover_letter_template.dart)

**Replace all hardcoded values:**

| Hardcoded | Replace With |
|-----------|--------------|
| `horizontal: 48` | `s.space12` (48pt) |
| `vertical: 32` | `s.space8` (32pt) |
| `height: 24` | `s.sectionGapMinor` (20pt) |
| `height: 16` | `s.space4` (16pt) |
| `fontSize: 12` | `s.fontSizeBody` (11pt) |
| `fontSize: 11` | `s.fontSizeBody` |
| `fontSize: 10` | `s.fontSizeSmall` (9pt) |
| `fontSize: 9` | `s.fontSizeTiny` (8pt) |

**Add customization parameter:**

```diff
  static void build(
    pw.Document pdf,
    CoverLetter coverLetter,
    TemplateStyle style,
    ContactDetails? contactDetails, {
    required pw.Font regularFont,
    required pw.Font boldFont,
    required pw.Font mediumFont,
+   TemplateCustomization? customization,
  }) {
-   final s = PdfStyling(style: style);
+   final s = PdfStyling(style: style, customization: customization);
```

---

## Phase 4: Wire Unused Customization Options

### showDividers
Currently not consistently applied. Add dividers between major sections:

```dart
// In each layout builder
if (s.customization.showDividers) {
  widgets.add(s.buildDivider());
}
```

### sectionOrderPreset
Already implemented in `_getSectionOrder()`. Ensure all layouts use it consistently.

---

## Iconography Guidelines

### Available Section Icons
| Icon Type | Used For | Visual |
|-----------|----------|--------|
| `profile` / `person` | Summary section | User silhouette |
| `skills` / `lightbulb` | Skills section | Lightbulb |
| `work` / `experience` | Experience section | Briefcase |
| `school` / `education` | Education section | Graduation cap |
| `language` | Languages section | Globe |
| `star` | Interests section | Star |
| `calendar` | Date ranges | Calendar |

### Icon Sizing
| Size | Points | Usage |
|------|--------|-------|
| Small | 16pt | Contact icons, inline |
| Medium | 20pt | Section headers |
| Large | 24pt | Featured elements |

### Bullet Styles
- **Dot**: Simple circle (default)
- **Diamond**: Rotated square for emphasis
- **Square**: Clean geometric
- **AccentBar**: Vertical accent line

---

## Spacing Grid System (8px Base)

| Token | Points | Usage |
|-------|--------|-------|
| `space1` | 4pt | Tight internal spacing |
| `space2` | 8pt | Icon gaps, tag spacing |
| `space3` | 12pt | Small gaps |
| `space4` | 16pt | Standard gaps |
| `space5` | 20pt | Medium gaps |
| `space6` | 24pt | Section internal |
| `space8` | 32pt | Between major sections |
| `space12` | 48pt | Page margins |

### Semantic Spacing
| Token | Points | Usage |
|-------|--------|-------|
| `sectionGapMajor` | 32pt | Between major sections |
| `sectionGapMinor` | 20pt | Between subsections |
| `itemGap` | 16pt | Between list items |
| `paragraphGap` | 12pt | Between paragraphs |

---

## Component Reference

### Header Layouts
| Layout | Description | Best For |
|--------|-------------|----------|
| **Modern** | Full-width accent bar, bold name | Default, impactful |
| **Clean** | Centered, minimal | Traditional industries |
| **Sidebar** | Name left, contact right | Two-column mode |
| **Compact** | Single line with border | Dense CVs |

### Experience Layouts
| Layout | Description | Best For |
|--------|-------------|----------|
| **Timeline** | Dots + vertical line | Default, visual flow |
| **List** | Traditional list | Simple, clean |
| **Cards** | Card containers | Modern, creative |
| **Compact** | Minimal spacing | Long work history |

### Skills Display
| Style | Description | Best For |
|-------|-------------|----------|
| **Tags (Outlined)** | Border, no fill | Default, clean |
| **Tags (Filled)** | Solid accent background | Emphasis |
| **Bars** | Proficiency bars | Technical roles |
| **Grid** | Multi-column layout | Many skills |

---

## Verification (Manual Testing)

### CV Template Testing
1. **All 4 layout modes**: Modern, Sidebar, Traditional, Compact
2. **Two-column mode**: Verify all content fits on ONE page
3. **Dark mode toggle**: Check contrast and readability
4. **Accent color changes**: Verify all elements update

### Cover Letter Testing
1. **Generate PDF**: Verify spacing is consistent
2. **Dark mode**: Check text contrast
3. **Accent color**: Verify header/footer update

### Print Test
1. Export PDF and open at 100% zoom
2. Verify 11pt body text is readable
3. Verify margins don't cut off content
