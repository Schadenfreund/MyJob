# Electric PDF Template System - Complete Guide

## Overview

The MyLife app now features a **stunning, professional Electric template system** with a modern magazine-style design and intuitive user interface. All old bland templates have been removed and replaced with a single, high-quality Electric template that's easy to customize.

---

## ✨ Features

### 1. **Electric Magazine-Style Template**
- **Bold Asymmetric Layout**: Modern brutalist aesthetic with eye-catching geometric shapes
- **Electric Yellow Accents**: High-contrast design with customizable neon accent colors
- **Professional Typography**: Clean, readable fonts with optimal spacing
- **Unicode Icons**: Professional symbols (✉ email, ✆ phone, ⚲ location, ☑ checkbox, ■ bullets, ⬢ hexagon, ★ star)
- **Magazine Quality**: Hero header with overlapping photo banner and diagonal accent shapes

### 2. **Modern Floating Preview UI**
- **Draggable Preview Window**: Move the PDF preview anywhere on screen for maximum workspace
- **Minimizable**: Click to minimize preview to a small floating button
- **Dark Professional Interface**: Black background (#1A1A1A) with electric yellow highlights
- **Live Preview Updates**: See changes instantly as you adjust colors
- **Clean Control Panel**: Left sidebar with organized sections for easy customization

### 3. **8 Electric Accent Colors**
Choose from professional electric color presets:
- **Electric Yellow** (#FFFF00) - Default
- **Electric Cyan** (#00FFFF)
- **Electric Magenta** (#FF00FF)
- **Electric Lime** (#00FF00)
- **Electric Orange** (#FF6600)
- **Electric Purple** (#9D00FF)
- **Electric Pink** (#FF0066)
- **Electric Chartreuse** (#66FF00)

---

## 🎨 Template Design Details

### CV Template (`electric_cv_template.dart`)

**Hero Header Section:**
- Full-width black background banner (220px height)
- Electric yellow accent bar across top (8px)
- Diagonal geometric accent shape (300x180px, 15% opacity)
- Circular profile photo with electric yellow border (140x140px)
- Large uppercase name (42pt, bold, white, 2pt letter-spacing)
- Electric yellow title badge with rounded corners
- Contact icons in electric yellow circles

**Main Content Structure:**
- Two-column top section: Professional Summary (2/3 width) + Key Skills (1/3 width)
- Professional Experience with checkbox bullets (☑)
- Company names in electric yellow badges
- Education & Skills in two-column layout
- Skill bars with electric yellow fill and proficiency percentages
- Languages and Interests at bottom with square bullets (■)

**Typography:**
- Name: 42pt bold uppercase
- Section headers: 16pt bold with electric yellow hex icon (⬢)
- Body text: 11pt with 1.6 line-spacing
- Skill names: 10pt bold

**Color Palette:**
- Black: #000000 (primary text and backgrounds)
- Electric Yellow: #FFFF00 (default accent)
- Medium Gray: #2D2D2D (backgrounds)
- Light Gray: #666666 (secondary text)
- White: #FFFFFF (header text)

### Cover Letter Template (`electric_cover_letter_template.dart`)

**Matching Design:**
- Same hero header style as CV (140px height)
- Electric yellow accent bars (top and bottom)
- Professional letter format with electric yellow accents
- Date with electric yellow vertical accent bar
- Electric yellow square bullets (■) for list items
- Signature with electric yellow underline (200px x 2px)

---

## 🖥️ User Interface

### Preview Dialog (`cv_template_pdf_preview_dialog.dart`)

**Top App Bar:**
- Black background (#000000, 80% opacity) with electric yellow shadow glow
- Electric yellow vertical accent indicator (4px x 30px)
- Large title: "ELECTRIC PDF PREVIEW" (16pt, bold, 1.2pt letter-spacing)
- Document name subtitle (12pt, 60% opacity)
- Electric yellow "Export PDF" button with black text
- Close button with semi-transparent white background

**Left Control Panel (320px width):**
- Dark background (#2D2D2D)
- Section: **ACCENT COLOR**
  - 8 color swatches (56x56px each)
  - Selected swatch has white border (3px) and glow effect
  - Check icon (✓) on selected color
- Section: **TEMPLATE INFO**
  - Style: Electric Magazine
  - Layout: Asymmetric Single-Column
  - Design: Modern Brutalist
  - Accent: [Color Name]
- **Tip Box**: Yellow hint about dragging preview window

**Floating Preview Window:**
- Draggable anywhere on screen
- Size: 500px x 700px
- Electric yellow border (3px) with glow shadow effect
- Yellow title bar (40px) with drag handle icon
- Minimize button to collapse to small floating button
- Live PDF preview with loading spinner
- Error handling with helpful messages

---

## 📁 File Structure

```
lib/
├── models/
│   └── template_style.dart                  # Electric template enum and styles
├── services/
│   ├── cv_template_pdf_service.dart        # CV PDF generation service
│   └── cover_letter_template_pdf_service.dart  # Cover letter PDF service
├── pdf/
│   ├── cv_templates/
│   │   └── electric_cv_template.dart       # Electric CV template (only template)
│   └── cover_letter_templates/
│       └── electric_cover_letter_template.dart  # Electric cover letter template
├── dialogs/
│   └── cv_template_pdf_preview_dialog.dart  # Modern floating preview UI
└── widgets/
    └── template_style_card.dart             # Color picker widget
```

---

## 🚀 How It Works

### 1. **User Workflow**

```
Documents Screen
    ↓
Click "Generate PDF"
    ↓
Electric Preview Dialog Opens
    ↓
[Left Panel] Choose Accent Color (8 options)
    ↓
[Floating Window] Live PDF Preview Updates
    ↓
Drag Preview Window to Reposition (optional)
    ↓
Click "Export PDF" Button
    ↓
Choose Save Location
    ↓
PDF Exported Successfully
```

### 2. **Template Selection**

All documents automatically use the Electric template. The system is designed for easy extension:

```dart
// In template_style.dart
enum TemplateType {
  electric('Electric', 'Bold magazine-style layout...');
}

// To add a new template in the future:
enum TemplateType {
  electric('Electric', '...'),
  future('Future Template', '...'),  // Just add here
}
```

### 3. **Color Customization**

Users can change accent colors on-the-fly:

```dart
// Accent color presets
static const List<Color> _accentColorPresets = [
  Color(0xFFFFFF00), // Electric Yellow
  Color(0xFF00FFFF), // Electric Cyan
  // ... 6 more colors
];

// Update accent color
void _updateAccentColor(Color color) {
  setState(() {
    _selectedStyle = _selectedStyle.copyWith(accentColor: color);
  });
}
```

---

## 🎯 Design Principles

### 1. **Brutalist Aesthetic**
- High contrast (black + neon colors)
- Geometric shapes and sharp angles
- Bold typography with wide letter-spacing
- Asymmetric layouts that break traditional grids

### 2. **Magazine Inspiration**
- Overlapping elements (photo banner)
- Large headlines with small details
- Pull quotes and accent bars
- Creative use of whitespace

### 3. **Professional Quality**
- Perfect alignment and spacing
- Consistent visual hierarchy
- Print-ready typography (11pt body, 1.6 line-height)
- Proper margins and gutters

### 4. **User Experience**
- Floating preview window for maximum workspace
- Instant live preview updates
- Clear visual feedback (glowing selected colors)
- Minimal clicks to export

---

## 🔧 Technical Implementation

### Font Loading

The Electric template uses **Inter font** for professional typography:

```dart
final boldFont = await PdfGoogleFonts.interBold();
final regularFont = await PdfGoogleFonts.interRegular();
final mediumFont = await PdfGoogleFonts.interMedium();

final fontFallback = [regularFont, boldFont, mediumFont];
```

### Unicode Icon Support

Professional symbols are rendered as text:

```dart
static const String _iconEmail = '✉';
static const String _iconPhone = '✆';
static const String _iconLocation = '⚲';
static const String _iconCheckbox = '☑';
static const String _iconSquare = '■';
static const String _iconHex = '⬢';
static const String _iconStar = '★';
static const String _iconArrow = '▸';
```

### Geometric Shapes

Diagonal accent with rotation:

```dart
pw.Positioned(
  right: 0,
  top: 0,
  child: pw.Transform.rotate(
    angle: 0.15,  // ~8.6 degrees
    child: pw.Container(
      width: 300,
      height: 180,
      color: _electricYellowFaded,  // 15% opacity
    ),
  ),
),
```

### Skill Bars with Proficiency

Intelligent parsing of skill strings:

```dart
// Parses "JavaScript - Expert" or "Python - 90%"
if (level.contains('expert')) {
  proficiency = 0.95;  // 95%
} else if (level.contains('%')) {
  proficiency = double.parse(level.replaceAll('%', '')) / 100.0;
}

// Render bar
pw.Container(
  width: 150 * proficiency,
  height: 8,
  decoration: pw.BoxDecoration(
    color: _electricYellow,
    borderRadius: pw.BorderRadius.circular(4),
  ),
)
```

---

## 📱 Responsive Elements

### Floating Window Behavior

```dart
// Draggable preview
GestureDetector(
  onPanUpdate: (details) {
    setState(() {
      _previewPosition += details.delta;
    });
  },
  child: Container(/* preview window */)
)

// Minimize/Restore
IconButton(
  onPressed: () {
    setState(() => _isPreviewMinimized = !_isPreviewMinimized);
  },
  icon: Icon(_isPreviewMinimized ? Icons.open_in_full : Icons.minimize),
)
```

---

## 🎨 Color System

### Predefined Electric Colors

```dart
// All colors use full RGB values for maximum vibrancy
Electric Yellow:    #FFFF00  (R:255, G:255, B:0)
Electric Cyan:      #00FFFF  (R:0,   G:255, B:255)
Electric Magenta:   #FF00FF  (R:255, G:0,   B:255)
Electric Lime:      #00FF00  (R:0,   G:255, B:0)
Electric Orange:    #FF6600  (R:255, G:102, B:0)
Electric Purple:    #9D00FF  (R:157, G:0,   B:255)
Electric Pink:      #FF0066  (R:255, G:0,   B:102)
Electric Chartreuse:#66FF00  (R:102, G:255, B:0)
```

### Background Colors

```dart
Black:        #000000  // Hero header, primary text
Dark Gray:    #1A1A1A  // UI background
Medium Gray:  #2D2D2D  // Control panel, skill bar backgrounds
Light Gray:   #666666  // Secondary text
White:        #FFFFFF  // Header text on dark backgrounds
```

---

## 🚀 Future Extensions

The system is designed for easy template addition. To add a new template:

1. Create template file in `lib/pdf/cv_templates/new_template.dart`
2. Add enum value in `lib/models/template_style.dart`
3. Update service in `lib/services/cv_template_pdf_service.dart`

**Example:**

```dart
// 1. Create lib/pdf/cv_templates/neon_cv_template.dart
class NeonCvTemplate {
  static void build(pdf, cv, style, {...}) {
    // Your unique template design
  }
}

// 2. Add to template_style.dart
enum TemplateType {
  electric('Electric', '...'),
  neon('Neon', 'Cyberpunk-inspired layout'),  // New
}

// 3. Update cv_template_pdf_service.dart
switch (style.type) {
  case TemplateType.electric:
    ElectricCvTemplate.build(...);
  case TemplateType.neon:  // New
    NeonCvTemplate.build(...);
}
```

---

## ✅ Testing Checklist

- [x] CV template generates without errors
- [x] Cover letter template matches CV design
- [x] All 8 accent colors work correctly
- [x] Preview window is draggable
- [x] Preview window minimizes/restores
- [x] Live preview updates on color change
- [x] Unicode icons render correctly
- [x] Skill bars show accurate percentages
- [x] PDF export saves to chosen location
- [x] Profile photos display correctly

---

## 🎉 Summary

The **Electric PDF Template System** provides:

✨ **One stunning template** instead of multiple bland options
🎨 **8 professional electric accent colors** for customization
🖥️ **Modern floating preview UI** with drag-and-drop repositioning
⚡ **Instant live preview** updates
📱 **Clean, professional interface** with dark theme
🔧 **Easy to extend** with new templates in the future

**Result**: Professional, magazine-quality PDFs with a delightful user experience!
