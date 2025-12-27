import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as path;
import '../models/cv_template.dart';
import '../models/template_style.dart';
import '../models/template_customization.dart';
import '../services/cv_template_pdf_service.dart';

/// Modern PDF preview dialog with floating preview window and streamlined controls
///
/// Features:
/// - Floating/movable preview window for maximum workspace
/// - Clean, minimal control panel on the left
/// - Professional accent color picker with swatches
/// - Live preview updates
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

  // Floating preview window position
  Offset _previewPosition = const Offset(400, 50);
  Size _previewSize = const Size(500, 700);
  bool _isPreviewMinimized = false;

  // Professional accent color presets for Electric template
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
  }

  void _updateAccentColor(Color color) {
    setState(() {
      _selectedStyle = _selectedStyle.copyWith(accentColor: color);
      _isGenerating = true;
    });
    Future.delayed(
      const Duration(milliseconds: 300),
      () {
        if (mounted) {
          setState(() => _isGenerating = false);
        }
      },
    );
  }

  Future<Uint8List> _generatePdf() async {
    final service = CvTemplatePdfService();
    final cvData = widget.cvTemplate.toCvData();

    // Create temporary file for PDF generation
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
      // Clean up
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    }
  }

  Future<void> _exportPdf(BuildContext context) async {
    try {
      // Show save file dialog
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

    return Dialog.fullscreen(
      child: Scaffold(
        backgroundColor: const Color(0xFF1A1A1A), // Dark background
        body: Stack(
          children: [
            // Left control panel
            _buildControlPanel(theme),

            // Floating preview window
            _buildFloatingPreview(theme),

            // Top app bar overlay
            _buildTopBar(theme),
          ],
        ),
      ),
    );
  }

  /// Build top app bar with title and close button
  Widget _buildTopBar(ThemeData theme) {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Container(
        height: 60,
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.8),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFFFFF00).withOpacity(0.2),
              blurRadius: 20,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Row(
          children: [
            // Electric accent indicator
            Container(
              width: 4,
              height: 30,
              decoration: BoxDecoration(
                color: const Color(0xFFFFFF00),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 16),

            // Title
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
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.download, size: 18),
              label: Text(_isGenerating ? 'Exporting...' : 'Export PDF'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFFFF00),
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
              ),
            ),

            const SizedBox(width: 16),

            // Close button
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

  /// Build left control panel with color picker
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
            // Section: Accent Color
            _buildSection(
              title: 'ACCENT COLOR',
              icon: Icons.palette,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 16),
                  const Text(
                    'Choose your electric accent:',
                    style: TextStyle(
                      color: Colors.white70,
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
                        child: Container(
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

            // Section: Template Info
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
                  _buildInfoRow('Accent', _getColorName(_selectedStyle.accentColor)),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Tip box
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFFFFF00).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: const Color(0xFFFFFF00).withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.tips_and_updates,
                    color: Color(0xFFFFFF00),
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Drag the preview window to reposition it',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
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
            Icon(icon, color: const Color(0xFFFFFF00), size: 18),
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

  /// Build floating/draggable preview window
  Widget _buildFloatingPreview(ThemeData theme) {
    if (_isPreviewMinimized) {
      // Minimized state - show small floating button
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
              border: Border.all(color: const Color(0xFFFFFF00), width: 2),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFFFFF00).withOpacity(0.4),
                  blurRadius: 20,
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.picture_as_pdf, color: Color(0xFFFFFF00)),
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
        onPanUpdate: (details) {
          setState(() {
            _previewPosition += details.delta;
          });
        },
        child: Container(
          width: _previewSize.width,
          height: _previewSize.height,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: const Color(0xFFFFFF00),
              width: 3,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFFFFF00).withOpacity(0.3),
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
              // Window title bar
              Container(
                height: 40,
                decoration: const BoxDecoration(
                  color: Color(0xFFFFFF00),
                  borderRadius: BorderRadius.only(
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
                        'PDF Preview',
                        style: TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
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
                  child: FutureBuilder<Uint8List>(
                    future: _generatePdf(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting ||
                          _isGenerating) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const SizedBox(
                                width: 40,
                                height: 40,
                                child: CircularProgressIndicator(
                                  color: Color(0xFFFFFF00),
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
                        );
                      }

                      if (snapshot.hasError) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.error_outline,
                                  color: Colors.red.shade400, size: 48),
                              const SizedBox(height: 16),
                              Text(
                                'Error generating PDF',
                                style: TextStyle(color: Colors.grey.shade600),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                snapshot.error.toString(),
                                style: TextStyle(
                                  color: Colors.grey.shade500,
                                  fontSize: 11,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        );
                      }

                      if (!snapshot.hasData) {
                        return const Center(child: Text('No data'));
                      }

                      return PdfPreview(
                        build: (format) => snapshot.data!,
                        allowPrinting: false,
                        allowSharing: false,
                        canChangeOrientation: false,
                        canChangePageFormat: false,
                        canDebug: false,
                        pdfFileName: '${widget.cvTemplate.name}.pdf',
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
