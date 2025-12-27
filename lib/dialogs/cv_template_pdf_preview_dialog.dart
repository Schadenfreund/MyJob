import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as path;
import '../models/cv_template.dart';
import '../models/template_style.dart';
import '../models/template_customization.dart';
import '../services/cv_template_pdf_service.dart';
import '../widgets/multi_page_pdf_viewer.dart';

/// Modern PDF preview with floating, resizable window and live color updates
class CvTemplatePdfPreviewDialog extends StatefulWidget {
  const CvTemplatePdfPreviewDialog({
    required this.cvTemplate,
    this.templateStyle,
    super.key,
  });

  final CvTemplate cvTemplate;
  final TemplateStyle? templateStyle;

  @override
  State<CvTemplatePdfPreviewDialog> createState() =>
      _CvTemplatePdfPreviewDialogState();
}

class _CvTemplatePdfPreviewDialogState
    extends State<CvTemplatePdfPreviewDialog> {
  late TemplateStyle _selectedStyle;
  bool _isGenerating = false;
  late TemplateCustomization _customization;

  // Preview state
  Uint8List? _cachedPdf;
  int _pdfGenerationVersion = 0; // Increment to trigger regeneration

  // Floating window state
  Offset _previewPosition = const Offset(100, 80);
  Size _previewSize = const Size(900, 650); // Wider for side-by-side pages
  bool _isPreviewMinimized = false;
  bool _isResizing = false;

  // Electric accent color presets
  static const List<Color> _accentColorPresets = [
    Color(0xFFFFFF00), // Electric Yellow (default)
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
    _selectedStyle = widget.templateStyle ??
        widget.cvTemplate.templateStyle ??
        TemplateStyle.electric;
    _customization = const TemplateCustomization();
    _generatePdfAsync(); // Generate initial PDF
  }

  void _updateAccentColor(Color color) {
    setState(() {
      _selectedStyle = _selectedStyle.copyWith(accentColor: color);
      _pdfGenerationVersion++; // Trigger regeneration
      _cachedPdf = null; // Clear cache
    });
    _generatePdfAsync();
  }

  void _toggleDarkMode() {
    setState(() {
      _selectedStyle = _selectedStyle.copyWith(isDarkMode: !_selectedStyle.isDarkMode);
      _pdfGenerationVersion++; // Trigger regeneration
      _cachedPdf = null; // Clear cache
    });
    _generatePdfAsync();
  }

  Future<void> _generatePdfAsync() async {
    if (_isGenerating) return;

    setState(() => _isGenerating = true);

    try {
      final pdf = await _generatePdf();
      if (mounted) {
        setState(() {
          _cachedPdf = pdf;
          _isGenerating = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isGenerating = false);
      }
    }
  }

  Future<Uint8List> _generatePdf() async {
    final service = CvTemplatePdfService();
    final cvData = widget.cvTemplate.toCvData();

    final tempDir = await Directory.systemTemp.createTemp();
    final tempFile = File('${tempDir.path}/preview.pdf');

    try {
      final file = await service.generatePdfFromCvData(
        cvData: cvData,
        outputPath: tempFile.path,
        templateStyle: _selectedStyle,
        customization: _customization,
        includeProfilePicture: true,
      );

      return await file.readAsBytes();
    } finally {
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    }
  }

  Future<void> _exportPdf(BuildContext context) async {
    try {
      final result = await FilePicker.platform.saveFile(
        dialogTitle: 'Export PDF',
        fileName: '${widget.cvTemplate.name}.pdf',
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );

      if (result == null) return;

      setState(() => _isGenerating = true);

      final service = CvTemplatePdfService();
      final cvData = widget.cvTemplate.toCvData();

      await service.generatePdfFromCvData(
        cvData: cvData,
        outputPath: result,
        templateStyle: _selectedStyle,
        customization: _customization,
        includeProfilePicture: true,
      );

      setState(() => _isGenerating = false);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'PDF exported to ${path.basename(result)}',
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.green.shade600,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        );
      }
    } catch (e) {
      setState(() => _isGenerating = false);
      if (context.mounted) {
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
    final theme = Theme.of(context);
    final screenSize = MediaQuery.of(context).size;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.zero,
      child: Container(
        width: screenSize.width,
        height: screenSize.height,
        color: const Color(0xFF1A1A1A), // Dark background
        child: Stack(
          children: [
            // Left control panel
            _buildControlPanel(theme),

            // Floating resizable preview window
            _buildFloatingPreview(theme, screenSize),

            // Top app bar overlay
            _buildTopBar(theme),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar(ThemeData theme) {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Container(
        height: 60,
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.9),
          boxShadow: [
            BoxShadow(
              color: _selectedStyle.accentColor.withOpacity(0.3),
              blurRadius: 20,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Row(
          children: [
            Container(
              width: 4,
              height: 30,
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
                    'ELECTRIC PDF PREVIEW',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                  Text(
                    widget.cvTemplate.name,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.6),
                      fontSize: 12,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),

            // Export button
            ElevatedButton.icon(
              onPressed: _isGenerating ? null : () => _exportPdf(context),
              icon: _isGenerating
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.black,
                      ),
                    )
                  : const Icon(Icons.download, size: 18),
              label: Text(_isGenerating ? 'Exporting...' : 'Export PDF'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _selectedStyle.accentColor,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
              ),
            ),

            const SizedBox(width: 16),

            IconButton(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.close, color: Colors.white),
              tooltip: 'Close',
              style: IconButton.styleFrom(
                backgroundColor: Colors.white.withOpacity(0.1),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildControlPanel(ThemeData theme) {
    return Positioned(
      left: 0,
      top: 60,
      bottom: 0,
      width: 320,
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF2D2D2D),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 20,
              offset: const Offset(4, 0),
            ),
          ],
        ),
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            // Accent Color Section
            _buildSection(
              title: 'ACCENT COLOR',
              icon: Icons.palette,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 16),
                  Text(
                    'Choose your electric accent (live preview):',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: _accentColorPresets.map((color) {
                      final isSelected = _selectedStyle.accentColor.value == color.value;
                      return GestureDetector(
                        onTap: () => _updateAccentColor(color),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: 56,
                          height: 56,
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
                                      color: color.withOpacity(0.6),
                                      blurRadius: 16,
                                      spreadRadius: 2,
                                    ),
                                  ]
                                : null,
                          ),
                          child: isSelected
                              ? const Icon(
                                  Icons.check,
                                  color: Colors.black,
                                  size: 28,
                                )
                              : null,
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Dark Mode Toggle
            _buildSection(
              title: 'COLOR MODE',
              icon: Icons.brightness_6,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 16),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: _selectedStyle.accentColor.withOpacity(0.2),
                        width: 1,
                      ),
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: _toggleDarkMode,
                        borderRadius: BorderRadius.circular(8),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              Icon(
                                _selectedStyle.isDarkMode
                                    ? Icons.dark_mode
                                    : Icons.light_mode,
                                color: _selectedStyle.accentColor,
                                size: 24,
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _selectedStyle.isDarkMode
                                          ? 'Dark Mode'
                                          : 'Light Mode',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      _selectedStyle.isDarkMode
                                          ? 'Black background, white text'
                                          : 'White background, black text',
                                      style: TextStyle(
                                        color: Colors.white.withOpacity(0.6),
                                        fontSize: 11,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Switch(
                                value: _selectedStyle.isDarkMode,
                                onChanged: (value) => _toggleDarkMode(),
                                activeColor: _selectedStyle.accentColor,
                                activeTrackColor:
                                    _selectedStyle.accentColor.withOpacity(0.5),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Template Info
            _buildSection(
              title: 'TEMPLATE INFO',
              icon: Icons.info_outline,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 16),
                  _buildInfoRow('Style', 'Electric Magazine'),
                  _buildInfoRow('Layout', 'Asymmetric Single-Column'),
                  _buildInfoRow('Design', 'Modern Brutalist'),
                  _buildInfoRow('Mode', _selectedStyle.isDarkMode ? 'Dark' : 'Light'),
                  _buildInfoRow('Accent', _getColorName(_selectedStyle.accentColor)),
                  _buildInfoRow('Status', _isGenerating ? 'Generating...' : 'Ready'),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Tips
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _selectedStyle.accentColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: _selectedStyle.accentColor.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.tips_and_updates,
                        color: _selectedStyle.accentColor,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'Pro Tips:',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  _buildTipItem('Toggle dark/light mode above'),
                  _buildTipItem('Drag the window to reposition'),
                  _buildTipItem('Drag corners to resize'),
                  _buildTipItem('All changes update in real-time'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTipItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 4, left: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '• ',
            style: TextStyle(
              color: _selectedStyle.accentColor,
              fontSize: 12,
            ),
          ),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: Colors.white.withOpacity(0.8),
                fontSize: 11,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: _selectedStyle.accentColor, size: 18),
            const SizedBox(width: 8),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              ),
            ),
          ],
        ),
        child,
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Colors.white54,
              fontSize: 12,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  String _getColorName(Color color) {
    if (color.value == const Color(0xFFFFFF00).value) return 'Electric Yellow';
    if (color.value == const Color(0xFF00FFFF).value) return 'Electric Cyan';
    if (color.value == const Color(0xFFFF00FF).value) return 'Electric Magenta';
    if (color.value == const Color(0xFF00FF00).value) return 'Electric Lime';
    if (color.value == const Color(0xFFFF6600).value) return 'Electric Orange';
    if (color.value == const Color(0xFF9D00FF).value) return 'Electric Purple';
    if (color.value == const Color(0xFFFF0066).value) return 'Electric Pink';
    if (color.value == const Color(0xFF66FF00).value) return 'Electric Chartreuse';
    return 'Custom';
  }

  Widget _buildFloatingPreview(ThemeData theme, Size screenSize) {
    if (_isPreviewMinimized) {
      return Positioned(
        left: _previewPosition.dx,
        top: _previewPosition.dy,
        child: GestureDetector(
          onPanUpdate: (details) {
            setState(() {
              _previewPosition += details.delta;
            });
          },
          child: Container(
            width: 200,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: _selectedStyle.accentColor, width: 2),
              boxShadow: [
                BoxShadow(
                  color: _selectedStyle.accentColor.withOpacity(0.4),
                  blurRadius: 20,
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.picture_as_pdf, color: _selectedStyle.accentColor),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Preview',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
                IconButton(
                  onPressed: () {
                    setState(() => _isPreviewMinimized = false);
                  },
                  icon: const Icon(Icons.open_in_full, color: Colors.white, size: 16),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Positioned(
      left: _previewPosition.dx,
      top: _previewPosition.dy,
      child: GestureDetector(
        onPanUpdate: !_isResizing
            ? (details) {
                setState(() {
                  _previewPosition += details.delta;
                  // Keep window on screen
                  _previewPosition = Offset(
                    _previewPosition.dx.clamp(0, screenSize.width - 200),
                    _previewPosition.dy.clamp(60, screenSize.height - 100),
                  );
                });
              }
            : null,
        child: Stack(
          children: [
            // Main preview window
            Container(
              width: _previewSize.width,
              height: _previewSize.height,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _selectedStyle.accentColor,
                  width: 3,
                ),
                boxShadow: [
                  BoxShadow(
                    color: _selectedStyle.accentColor.withOpacity(0.3),
                    blurRadius: 30,
                    spreadRadius: 5,
                  ),
                  BoxShadow(
                    color: Colors.black.withOpacity(0.5),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Title bar
                  Container(
                    height: 40,
                    decoration: BoxDecoration(
                      color: _selectedStyle.accentColor,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(9),
                        topRight: Radius.circular(9),
                      ),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Row(
                      children: [
                        const Icon(Icons.drag_indicator, color: Colors.black, size: 18),
                        const SizedBox(width: 8),
                        const Expanded(
                          child: Text(
                            'PDF Preview - Drag to move, resize corners',
                            style: TextStyle(
                              color: Colors.black,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        if (_isGenerating)
                          const Padding(
                            padding: EdgeInsets.only(right: 8),
                            child: SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.black,
                              ),
                            ),
                          ),
                        IconButton(
                          onPressed: () {
                            setState(() => _isPreviewMinimized = true);
                          },
                          icon: const Icon(Icons.minimize, color: Colors.black, size: 16),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          tooltip: 'Minimize',
                        ),
                      ],
                    ),
                  ),

                  // PDF preview content
                  Expanded(
                    child: ClipRRect(
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(9),
                        bottomRight: Radius.circular(9),
                      ),
                      child: _cachedPdf != null
                          ? MultiPagePdfViewer(
                              key: ValueKey(_pdfGenerationVersion),
                              pdfBytes: _cachedPdf!,
                              accentColor: _selectedStyle.accentColor,
                              fileName: '${widget.cvTemplate.name}.pdf',
                              showSideBySide: true,
                            )
                          : Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  SizedBox(
                                    width: 40,
                                    height: 40,
                                    child: CircularProgressIndicator(
                                      color: _selectedStyle.accentColor,
                                      strokeWidth: 3,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'Generating Electric PDF...',
                                    style: TextStyle(
                                      color: Colors.grey.shade600,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),

            // Resize handles (bottom-right corner)
            Positioned(
              right: 0,
              bottom: 0,
              child: GestureDetector(
                onPanStart: (_) => setState(() => _isResizing = true),
                onPanUpdate: (details) {
                  setState(() {
                    _previewSize = Size(
                      (_previewSize.width + details.delta.dx).clamp(600, screenSize.width - _previewPosition.dx - 50),
                      (_previewSize.height + details.delta.dy).clamp(400, screenSize.height - _previewPosition.dy - 50),
                    );
                  });
                },
                onPanEnd: (_) => setState(() => _isResizing = false),
                child: Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: _selectedStyle.accentColor,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(8),
                      bottomRight: Radius.circular(9),
                    ),
                  ),
                  child: const Icon(
                    Icons.drag_handle,
                    color: Colors.black,
                    size: 16,
                  ),
                ),
              ),
            ),

            // Bottom-left resize handle
            Positioned(
              left: 0,
              bottom: 0,
              child: GestureDetector(
                onPanStart: (_) => setState(() => _isResizing = true),
                onPanUpdate: (details) {
                  setState(() {
                    final newWidth = _previewSize.width - details.delta.dx;
                    final newHeight = _previewSize.height + details.delta.dy;

                    if (newWidth >= 600 && newWidth <= screenSize.width - _previewPosition.dx - 50) {
                      _previewSize = Size(newWidth, _previewSize.height);
                      _previewPosition = Offset(_previewPosition.dx + details.delta.dx, _previewPosition.dy);
                    }

                    _previewSize = Size(
                      _previewSize.width,
                      newHeight.clamp(400, screenSize.height - _previewPosition.dy - 50),
                    );
                  });
                },
                onPanEnd: (_) => setState(() => _isResizing = false),
                child: Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: _selectedStyle.accentColor.withOpacity(0.8),
                    borderRadius: const BorderRadius.only(
                      topRight: Radius.circular(8),
                      bottomLeft: Radius.circular(9),
                    ),
                  ),
                  child: const Icon(
                    Icons.drag_handle,
                    color: Colors.black,
                    size: 16,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
