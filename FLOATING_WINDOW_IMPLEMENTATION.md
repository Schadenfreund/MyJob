# Floating PDF Preview Window - Implementation Guide

## Overview

The PDF preview system has been upgraded to use a **true floating window** that exists outside the main application window. This provides maximum flexibility for users to position the preview anywhere on their screen, even on secondary monitors.

---

## Key Features

### 1. **Independent OS Window**
- The preview opens as a **separate Windows application window**
- Can be moved anywhere on screen, including outside the main app boundaries
- Appears in Windows taskbar as a separate window
- Can be moved to different monitors
- Full native window controls (minimize, maximize, close)

### 2. **Live Color Customization**
- 8 electric accent color presets available in the left panel
- Colors apply directly to the PDF content (not just UI chrome)
- Real-time PDF regeneration when colors change
- Instant visual feedback

### 3. **Professional UI**
- Dark theme (#1A1A1A background)
- Electric yellow accents with glow effects
- Left control panel with color picker and template info
- Clean, modern design matching the Electric template aesthetic

---

## Architecture

### File Structure

```
lib/
├── windows/
│   ├── multi_window_entry.dart              # Entry point for sub-windows
│   └── pdf_preview_window.dart               # Floating preview window UI
├── dialogs/
│   ├── cv_template_pdf_preview_launcher.dart # Launcher for floating window
│   └── cv_template_pdf_preview_dialog.dart   # Legacy dialog (kept for reference)
├── main.dart                                  # Updated to support multi-window
```

### Key Components

#### 1. **Multi-Window Entry Point** (`windows/multi_window_entry.dart`)
```dart
void main(List<String> args) {
  // Parse window ID and arguments
  final windowId = int.parse(args.first);
  final windowController = WindowController.fromWindowId(windowId);
  final arguments = jsonDecode(args[1]) as Map<String, dynamic>;

  // Launch PDF preview window
  runApp(PdfPreviewWindow(
    windowController: windowController,
    args: arguments,
  ));
}
```

#### 2. **Preview Window Launcher** (`dialogs/cv_template_pdf_preview_launcher.dart`)
```dart
class CvTemplatePdfPreviewLauncher {
  static Future<void> openPreview({
    required BuildContext context,
    required CvTemplate cvTemplate,
    TemplateStyle? templateStyle,
  }) async {
    // Serialize CV data to JSON
    final args = {
      'cvTemplate': jsonEncode(cvTemplate.toJson()),
      'templateStyle': templateStyle != null ? jsonEncode(templateStyle.toJson()) : null,
      'documentName': cvTemplate.name,
    };

    // Create new window with data
    final window = await DesktopMultiWindow.createWindow(jsonEncode(args));

    // Configure window size and position
    window
      ..setFrame(const Offset(100, 100) & const Size(1400, 900))
      ..center()
      ..setTitle('Electric PDF Preview - ${cvTemplate.name}')
      ..show();
  }
}
```

#### 3. **Main App Integration** (`main.dart`)
```dart
void main(List<String> args) async {
  // Check if this is a sub-window process
  if (args.isNotEmpty && args.first == 'multi_window') {
    multi_window.main(args);
    return;
  }

  // Otherwise run as main window
  // ... existing window manager initialization
}
```

---

## Usage

### From Documents Screen

```dart
void _generateCvPdf(BuildContext context, CvTemplate template) {
  CvTemplatePdfPreviewLauncher.openPreview(
    context: context,
    cvTemplate: template,
    templateStyle: template.templateStyle,
  );
}
```

### From CV Template Editor

```dart
Future<void> _previewTemplate() async {
  await CvTemplatePdfPreviewLauncher.openPreview(
    context: context,
    cvTemplate: previewTemplate,
    templateStyle: previewTemplate.templateStyle,
  );
}
```

---

## Technical Details

### Dependencies

```yaml
dependencies:
  desktop_multi_window: ^0.2.0  # Multi-window support
  window_manager: ^0.3.5         # Window management (existing)
  pdf: ^3.10.0                   # PDF generation (existing)
  printing: ^5.12.0               # PDF preview widget (existing)
```

### Data Serialization

CV data is serialized to JSON to pass between windows:

```dart
// Serialize
'cvTemplate': jsonEncode(cvTemplate.toJson())

// Deserialize in new window
final cvJson = jsonDecode(args['cvTemplate']) as Map<String, dynamic>;
final cvTemplate = CvTemplate.fromJson(cvJson);
```

### Window Configuration

```dart
window
  ..setFrame(const Offset(100, 100) & const Size(1400, 900))  // Position and size
  ..center()                                                    // Center on screen
  ..setTitle('Electric PDF Preview - ${cvTemplate.name}')      // Window title
  ..show();                                                     // Make visible
```

---

## Benefits Over Previous Implementation

### Old Approach (Dialog within App)
- ❌ Preview constrained within app window bounds
- ❌ Cannot move to secondary monitors freely
- ❌ Limited workspace for editing and previewing simultaneously
- ❌ Feels like a modal blocking the main app

### New Approach (Floating OS Window)
- ✅ **True floating window** - can exist anywhere on any monitor
- ✅ **Independent window** - appears in taskbar separately
- ✅ **Maximum flexibility** - users can arrange windows as needed
- ✅ **Multi-monitor support** - perfect for dual-screen setups
- ✅ **Non-blocking** - main app remains fully accessible

---

## Window Features

### Left Control Panel (320px)
- **Accent Color Selector**: 8 color swatches with glow effects
- **Template Info**: Style, layout, design, current accent
- **Status Indicator**: Shows "Generating..." or "Ready"
- **Pro Tips**: Helpful hints for users

### Top App Bar
- **Title**: "ELECTRIC PDF PREVIEW" with document name
- **Export Button**: Save PDF with chosen accent color
- **Close Button**: Closes the preview window

### Preview Area
- **Live PDF Preview**: Updates in real-time when colors change
- **Multi-page View**: Shows all pages side-by-side
- **Loading State**: Spinner while generating PDF
- **Error Handling**: Friendly error messages if generation fails

---

## Color System Integration

### Electric Accent Colors
```dart
static const List<Color> _accentColorPresets = [
  Color(0xFFFFFF00), // Electric Yellow
  Color(0xFF00FFFF), // Electric Cyan
  Color(0xFFFF00FF), // Electric Magenta
  Color(0xFF00FF00), // Electric Lime
  Color(0xFFFF6600), // Electric Orange
  Color(0xFF9D00FF), // Electric Purple
  Color(0xFFFF0066), // Electric Pink
  Color(0xFF66FF00), // Electric Chartreuse
];
```

### Dynamic Color Application
When a color is selected:
1. UI updates immediately (border, buttons, icons)
2. `_pdfGenerationVersion` increments (triggers rebuild)
3. PDF regenerates with new accent color
4. Preview refreshes automatically

---

## Performance Optimizations

### PDF Caching
```dart
Uint8List? _cachedPdf;
int _pdfGenerationVersion = 0;

// Only regenerate when version changes
PdfPreview(
  key: ValueKey(_pdfGenerationVersion),
  build: (format) => _cachedPdf!,
  // ...
)
```

### Debouncing
- PDF generation is debounced to prevent multiple simultaneous builds
- `_isGenerating` flag prevents race conditions

### Temporary File Cleanup
```dart
try {
  final file = await service.generatePdfFromCvData(...);
  return await file.readAsBytes();
} finally {
  if (tempDir.existsSync()) {
    tempDir.deleteSync(recursive: true);
  }
}
```

---

## Comparison: Old vs New

| Feature | Old Dialog | New Floating Window |
|---------|-----------|---------------------|
| Window Type | Modal Dialog | Independent OS Window |
| Positioning | Constrained within app | Anywhere on screen/monitors |
| Taskbar Presence | No | Yes (separate entry) |
| Multi-monitor | Limited | Full support |
| Resizable | Within app bounds only | Native window resizing |
| User Experience | Modal/blocking feel | Non-blocking, flexible |
| Implementation | Flutter Dialog | desktop_multi_window |

---

## Future Enhancements

Potential improvements:
1. **Window State Persistence**: Remember last position/size
2. **Multiple Preview Windows**: Open several PDFs simultaneously
3. **Drag & Drop**: Drag PDF file from preview to desktop
4. **Print Preview**: Direct print from preview window
5. **Zoom Controls**: Zoom in/out on PDF pages
6. **Page Navigation**: Jump to specific pages quickly

---

## Troubleshooting

### Window doesn't appear
- Check that `desktop_multi_window` package is installed
- Verify `flutter pub get` ran successfully
- Ensure main.dart has multi-window detection logic

### Colors don't update in PDF
- Verify `PdfColor.fromInt(style.accentColor.toARGB32())` is used
- Check that `_pdfGenerationVersion` increments on color change
- Ensure PDF service receives updated `TemplateStyle`

### Window position issues
- Verify `.center()` is called after `.setFrame()`
- Check screen resolution and DPI scaling settings
- Ensure offset values are positive

---

## Summary

The floating PDF preview window provides a **professional, flexible, and modern** user experience that matches the quality of the Electric template system. Users can now:

- 🪟 **Float the preview anywhere** - even on secondary monitors
- 🎨 **Customize colors in real-time** - see changes instantly
- 📄 **Work efficiently** - edit and preview simultaneously
- 💾 **Export with confidence** - see exactly what will be saved

This implementation uses the **desktop_multi_window** package to create true OS-level windows, providing the flexibility the user requested while maintaining the clean, modern Electric aesthetic.
