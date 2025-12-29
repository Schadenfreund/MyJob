import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as path;
import '../models/template_style.dart';
import '../models/pdf_font_family.dart';
import '../services/pdf_font_service.dart';
import '../widgets/multi_page_pdf_viewer.dart';

/// Base class for PDF preview dialogs to eliminate code duplication
///
/// This abstract class handles:
/// - Template style management
/// - PDF generation and caching
/// - Accent color and font family selection UI
/// - Export functionality
/// - Common UI patterns
///
/// Subclasses must implement:
/// - generatePdfBytes() - PDF generation logic
/// - exportPdf() - Export logic with service-specific details
/// - getDocumentName() - Name for the document being previewed
abstract class BaseTemplatePdfPreviewDialog extends StatefulWidget {
  const BaseTemplatePdfPreviewDialog({
    this.templateStyle,
    super.key,
  });

  final TemplateStyle? templateStyle;

  TemplateStyle getDefaultStyle() => TemplateStyle.electric;
}

abstract class BaseTemplatePdfPreviewDialogState<
    T extends BaseTemplatePdfPreviewDialog> extends State<T> {
  late TemplateStyle _selectedStyle;
  bool _isGenerating = false;

  // PDF state
  Uint8List? _cachedPdf;
  int _pdfGenerationVersion = 0;

  // Available fonts (loaded dynamically from bundled assets)
  List<PdfFontFamily> _availableFonts = [];

  // Protected getter for subclasses
  TemplateStyle get selectedStyle => _selectedStyle;

  // Accent color presets
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

  @override
  void initState() {
    super.initState();
    _selectedStyle = widget.templateStyle ?? widget.getDefaultStyle();
    _loadAvailableFonts();
  }

  Future<void> _loadAvailableFonts() async {
    try {
      final fonts = await PdfFontService.getAvailableFontFamilies();
      if (!mounted) return;

      setState(() {
        _availableFonts = fonts;

        // Validate selected font is available, switch to first available if not
        if (_availableFonts.isNotEmpty &&
            !_availableFonts.contains(_selectedStyle.fontFamily)) {
          _selectedStyle =
              _selectedStyle.copyWith(fontFamily: _availableFonts.first);
        }
      });

      // Generate PDF after fonts are loaded and validated
      _generatePdfAsync();
    } catch (e) {
      if (mounted) {
        // Use all fonts as fallback if detection fails
        setState(() {
          _availableFonts = PdfFontFamily.values.toList();
        });
        _generatePdfAsync();
      }
    }
  }

  /// Subclasses must implement: Generate PDF bytes for preview
  Future<Uint8List> generatePdfBytes();

  /// Subclasses must implement: Export PDF to file
  Future<void> exportPdf(BuildContext context, String outputPath);

  /// Subclasses must implement: Get document name for display
  String getDocumentName();

  /// Optional: Additional UI sections (e.g., dark mode toggle, info section)
  List<Widget> buildAdditionalSections() => [];

  /// Optional: Use sidebar layout (true) or horizontal bars (false)
  bool get useSidebarLayout => false;

  void updateAccentColor(Color color) {
    setState(() {
      _selectedStyle = _selectedStyle.copyWith(accentColor: color);
      _pdfGenerationVersion++;
      _cachedPdf = null;
    });
    _generatePdfAsync();
  }

  void updateFontFamily(PdfFontFamily fontFamily) {
    // Only allow switching to available fonts
    if (!_availableFonts.contains(fontFamily)) {
      return;
    }

    setState(() {
      _selectedStyle = _selectedStyle.copyWith(fontFamily: fontFamily);
      _pdfGenerationVersion++;
      _cachedPdf = null;
    });
    _generatePdfAsync();
  }

  void toggleDarkMode() {
    setState(() {
      _selectedStyle =
          _selectedStyle.copyWith(isDarkMode: !_selectedStyle.isDarkMode);
      _pdfGenerationVersion++;
      _cachedPdf = null;
    });
    _generatePdfAsync();
  }

  Future<void> _generatePdfAsync() async {
    if (_isGenerating) return;

    setState(() => _isGenerating = true);

    try {
      final pdf = await generatePdfBytes();
      if (mounted) {
        setState(() {
          _cachedPdf = pdf;
          _isGenerating = false;
        });
      }
    } catch (e, _) {
      if (mounted) {
        setState(() => _isGenerating = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error generating PDF: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 10),
          ),
        );
      }
    }
  }

  Future<void> _handleExport(BuildContext context) async {
    try {
      final result = await FilePicker.platform.saveFile(
        dialogTitle: 'Export PDF',
        fileName: '${getDocumentName()}.pdf',
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );

      if (result == null) return;
      if (!mounted) return;

      setState(() => _isGenerating = true);

      await exportPdf(context, result);

      if (!mounted) return;
      setState(() => _isGenerating = false);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('PDF exported to ${path.basename(result)}'),
            backgroundColor: Colors.green.shade600,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isGenerating = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error exporting PDF: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (useSidebarLayout) {
      return _buildSidebarLayout(context);
    } else {
      return _buildHorizontalLayout(context);
    }
  }

  Widget _buildSidebarLayout(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      body: Column(
        children: [
          _buildTopBar(),
          Expanded(
            child: Row(
              children: [
                _buildSidebar(),
                Expanded(child: _buildPreviewArea()),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHorizontalLayout(BuildContext context) {
    final theme = Theme.of(context);

    return Dialog.fullscreen(
      child: Scaffold(
        backgroundColor: theme.colorScheme.surface,
        appBar: _buildAppBar(theme),
        body: Column(
          children: [
            _buildAccentColorBar(theme),
            _buildFontFamilyBar(theme),
            ...buildAdditionalSections(),
            Expanded(child: _buildPreviewArea()),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Container(
      height: 64,
      decoration: BoxDecoration(
        color: Colors.black,
        border: Border(
          bottom: BorderSide(
            color: _selectedStyle.accentColor.withValues(alpha: 0.3),
            width: 2,
          ),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 32,
            decoration: BoxDecoration(
              color: _selectedStyle.accentColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'PDF PREVIEW',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
                Text(
                  getDocumentName(),
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.6),
                    fontSize: 12,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          if (_isGenerating)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor:
                      AlwaysStoppedAnimation(_selectedStyle.accentColor),
                ),
              ),
            ),
          ElevatedButton.icon(
            onPressed: _isGenerating ? null : () => _handleExport(context),
            icon: const Icon(Icons.download, size: 18),
            label: const Text('Export PDF'),
            style: ElevatedButton.styleFrom(
              backgroundColor: _selectedStyle.accentColor,
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              disabledBackgroundColor: Colors.grey.shade700,
            ),
          ),
          const SizedBox(width: 12),
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.close, color: Colors.white),
            tooltip: 'Close',
            style: IconButton.styleFrom(
              backgroundColor: Colors.white.withValues(alpha: 0.1),
            ),
          ),
        ],
      ),
    );
  }

  AppBar _buildAppBar(ThemeData theme) {
    return AppBar(
      title: Row(
        children: [
          Icon(
            Icons.picture_as_pdf,
            color: theme.colorScheme.primary,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'PDF Preview',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  getDocumentName(),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.textTheme.bodySmall?.color
                        ?.withValues(alpha: 0.7),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
      leading: IconButton(
        icon: const Icon(Icons.close),
        onPressed: () => Navigator.pop(context),
        tooltip: 'Close',
      ),
      actions: [
        ElevatedButton.icon(
          onPressed: _isGenerating ? null : () => _handleExport(context),
          icon: const Icon(Icons.download, size: 18),
          label: const Text('Export PDF'),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 12,
            ),
          ),
        ),
        const SizedBox(width: 16),
      ],
    );
  }

  Widget _buildSidebar() {
    return Container(
      width: 300,
      decoration: BoxDecoration(
        color: const Color(0xFF2D2D2D),
        border: Border(
          right: BorderSide(
            color: Colors.white.withValues(alpha: 0.1),
            width: 1,
          ),
        ),
      ),
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _buildAccentColorSectionSidebar(),
          const SizedBox(height: 24),
          _buildFontFamilySectionSidebar(),
          const SizedBox(height: 24),
          ...buildAdditionalSections(),
        ],
      ),
    );
  }

  Widget _buildAccentColorSectionSidebar() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.palette, color: _selectedStyle.accentColor, size: 18),
            const SizedBox(width: 8),
            const Text(
              'ACCENT COLOR',
              style: TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: _accentColorPresets.map((color) {
            final isSelected =
                _selectedStyle.accentColor.toARGB32() == color.toARGB32();
            return GestureDetector(
              onTap: () => updateAccentColor(color),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isSelected ? Colors.white : Colors.transparent,
                    width: 3,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: color.withValues(alpha: 0.5),
                            blurRadius: 12,
                            spreadRadius: 2,
                          ),
                        ]
                      : null,
                ),
                child: isSelected
                    ? const Icon(Icons.check, color: Colors.black, size: 24)
                    : null,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildFontFamilySectionSidebar() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.font_download,
                color: _selectedStyle.accentColor, size: 18),
            const SizedBox(width: 8),
            const Text(
              'FONT FAMILY',
              style: TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (_availableFonts.isEmpty)
          Padding(
            padding: const EdgeInsets.all(12),
            child: Text(
              'No fonts available. Add TTF files to assets/fonts/',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.6),
                fontSize: 11,
              ),
            ),
          )
        else
          ..._availableFonts.map((font) {
            final isSelected = _selectedStyle.fontFamily == font;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Container(
                decoration: BoxDecoration(
                  color: isSelected
                      ? _selectedStyle.accentColor.withValues(alpha: 0.1)
                      : Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isSelected
                        ? _selectedStyle.accentColor
                        : Colors.white.withValues(alpha: 0.1),
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => updateFontFamily(font),
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? _selectedStyle.accentColor
                                  : Colors.white.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Center(
                              child: Text(
                                font.displayName[0],
                                style: TextStyle(
                                  color:
                                      isSelected ? Colors.black : Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  font.displayName,
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 13,
                                    fontWeight: isSelected
                                        ? FontWeight.bold
                                        : FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  font.characteristicsLabel,
                                  style: TextStyle(
                                    color: isSelected
                                        ? _selectedStyle.accentColor
                                        : Colors.white.withValues(alpha: 0.6),
                                    fontSize: 10,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (isSelected)
                            Icon(
                              Icons.check_circle,
                              color: _selectedStyle.accentColor,
                              size: 20,
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          }),
      ],
    );
  }

  Widget _buildAccentColorBar(ThemeData theme) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: theme.dividerColor.withValues(alpha: 0.3),
          ),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: Row(
        children: [
          Icon(Icons.palette, color: theme.colorScheme.secondary, size: 20),
          const SizedBox(width: 12),
          Text(
            'Accent Color:',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _accentColorPresets.map((color) {
                  final isSelected =
                      _selectedStyle.accentColor.toARGB32() == color.toARGB32();
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: InkWell(
                      onTap: () => updateAccentColor(color),
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isSelected
                                ? theme.colorScheme.onSurface
                                : Colors.white,
                            width: isSelected ? 3 : 2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.2),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: isSelected
                            ? Icon(
                                Icons.check,
                                size: 16,
                                color: color.computeLuminance() > 0.5
                                    ? Colors.black
                                    : Colors.white,
                              )
                            : null,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFontFamilyBar(ThemeData theme) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: theme.dividerColor.withValues(alpha: 0.3),
          ),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: Row(
        children: [
          Icon(Icons.font_download,
              color: theme.colorScheme.secondary, size: 20),
          const SizedBox(width: 12),
          Text(
            'Font Family:',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _availableFonts.isEmpty
                ? Text(
                    'No fonts available. Add TTF files to assets/fonts/',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  )
                : SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: _availableFonts.map((font) {
                        final isSelected = _selectedStyle.fontFamily == font;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            label: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(font.displayName),
                                if (font.hasUnicodeSupport) ...[
                                  const SizedBox(width: 6),
                                  Icon(
                                    Icons.check_circle,
                                    size: 14,
                                    color: isSelected
                                        ? theme.colorScheme.onPrimaryContainer
                                        : theme.colorScheme.primary,
                                  ),
                                ],
                              ],
                            ),
                            selected: isSelected,
                            onSelected: (selected) {
                              if (selected) {
                                updateFontFamily(font);
                              }
                            },
                            selectedColor: theme.colorScheme.primaryContainer,
                            labelStyle: TextStyle(
                              color: isSelected
                                  ? theme.colorScheme.onPrimaryContainer
                                  : theme.colorScheme.onSurface,
                              fontWeight: isSelected
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildPreviewArea() {
    return Container(
      color: Colors.grey.shade300,
      child: _cachedPdf != null
          ? MultiPagePdfViewer(
              key: ValueKey(_pdfGenerationVersion),
              pdfBytes: _cachedPdf!,
              accentColor: _selectedStyle.accentColor,
              fileName: '${getDocumentName()}.pdf',
              showSideBySide: true,
            )
          : Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 50,
                    height: 50,
                    child: CircularProgressIndicator(
                      color: _selectedStyle.accentColor,
                      strokeWidth: 4,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Generating PDF Preview...',
                    style: TextStyle(
                      color: Colors.grey.shade700,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
