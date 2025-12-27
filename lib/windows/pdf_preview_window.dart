import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:desktop_multi_window/desktop_multi_window.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as path;
import '../models/cv_template.dart';
import '../models/template_style.dart';
import '../models/template_customization.dart';
import '../services/cv_template_pdf_service.dart';

/// Standalone window entry point for PDF preview
/// This runs in a separate OS window process
class PdfPreviewWindow extends StatelessWidget {
  const PdfPreviewWindow({
    required this.windowController,
    required this.args,
    super.key,
  });

  final WindowController windowController;
  final Map<String, dynamic> args;

  @override
  Widget build(BuildContext context) {
    // Validate args and provide defaults
    final cvTemplateJson = args['cvTemplate'] as String? ?? '{}';
    final templateStyleJson = args['templateStyle'] as String?;
    final documentName = args['documentName'] as String? ?? 'Preview';

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(),
      home: PdfPreviewWindowContent(
        windowController: windowController,
        cvTemplateJson: cvTemplateJson,
        templateStyleJson: templateStyleJson,
        documentName: documentName,
      ),
    );
  }
}

/// The actual PDF preview window content
class PdfPreviewWindowContent extends StatefulWidget {
  const PdfPreviewWindowContent({
    required this.windowController,
    required this.cvTemplateJson,
    required this.documentName,
    this.templateStyleJson,
    super.key,
  });

  final WindowController windowController;
  final String cvTemplateJson;
  final String? templateStyleJson;
  final String documentName;

  @override
  State<PdfPreviewWindowContent> createState() =>
      _PdfPreviewWindowContentState();
}

class _PdfPreviewWindowContentState extends State<PdfPreviewWindowContent> {
  late TemplateStyle _selectedStyle;
  late CvTemplate _cvTemplate;
  bool _isGenerating = false;
  late TemplateCustomization _customization;

  // Preview state
  Uint8List? _cachedPdf;
  int _pdfGenerationVersion = 0;

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
    _initializeFromArgs();
    _generatePdfAsync();

    // Listen for messages from main window
    DesktopMultiWindow.setMethodHandler(_handleMethodCall);
  }

  void _initializeFromArgs() {
    try {
      debugPrint('Initializing PDF preview window...');
      debugPrint('CV Template JSON length: ${widget.cvTemplateJson.length}');

      // Decode CV template from JSON
      final cvJson = jsonDecode(widget.cvTemplateJson) as Map<String, dynamic>;
      _cvTemplate = CvTemplate.fromJson(cvJson);
      debugPrint('CV Template loaded: ${_cvTemplate.name}');

      // Decode template style from JSON
      if (widget.templateStyleJson != null && widget.templateStyleJson!.isNotEmpty) {
        final styleJson = jsonDecode(widget.templateStyleJson!) as Map<String, dynamic>;
        _selectedStyle = TemplateStyle.fromJson(styleJson);
        debugPrint('Template style loaded');
      } else {
        _selectedStyle = _cvTemplate.templateStyle ?? TemplateStyle.electric;
        debugPrint('Using default template style');
      }

      _customization = const TemplateCustomization();
      debugPrint('Window initialization complete');
    } catch (e, stackTrace) {
      debugPrint('Error initializing window args: $e');
      debugPrint('Stack trace: $stackTrace');

      // Create a minimal CV template as fallback
      _cvTemplate = CvTemplate(
        id: 'error',
        name: 'Error Loading Template',
        profile: 'Failed to load template data',
      );
      _selectedStyle = TemplateStyle.electric;
      _customization = const TemplateCustomization();
    }
  }

  Future<dynamic> _handleMethodCall(MethodCall call, int fromWindowId) async {
    switch (call.method) {
      case 'updateAccentColor':
        final colorValue = call.arguments as int;
        _updateAccentColor(Color(colorValue));
        break;
      case 'close':
        await widget.windowController.close();
        break;
    }
  }

  void _updateAccentColor(Color color) {
    setState(() {
      _selectedStyle = _selectedStyle.copyWith(accentColor: color);
      _pdfGenerationVersion++;
      _cachedPdf = null;
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
      debugPrint('Error generating PDF: $e');
      if (mounted) {
        setState(() => _isGenerating = false);
      }
    }
  }

  Future<Uint8List> _generatePdf() async {
    final service = CvTemplatePdfService();
    final cvData = _cvTemplate.toCvData();

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
        fileName: '${_cvTemplate.name}.pdf',
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );

      if (result == null) return;

      setState(() => _isGenerating = true);

      final service = CvTemplatePdfService();
      final cvData = _cvTemplate.toCvData();

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
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      body: Row(
        children: [
          // Left control panel
          _buildControlPanel(),

          // Main preview area
          Expanded(
            child: Column(
              children: [
                // Top bar
                _buildTopBar(),

                // PDF preview
                Expanded(
                  child: _buildPdfPreview(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar() {
    return Container(
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
                  widget.documentName,
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
            onPressed: () async {
              await widget.windowController.close();
            },
            icon: const Icon(Icons.close, color: Colors.white),
            tooltip: 'Close',
            style: IconButton.styleFrom(
              backgroundColor: Colors.white.withOpacity(0.1),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildControlPanel() {
    return Container(
      width: 320,
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
                _buildTipItem('This window floats freely'),
                _buildTipItem('Move it anywhere on screen'),
                _buildTipItem('Resize as needed'),
                _buildTipItem('Colors update in real-time'),
              ],
            ),
          ),
        ],
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

  Widget _buildPdfPreview() {
    return Container(
      margin: const EdgeInsets.all(24),
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
      child: ClipRRect(
        borderRadius: BorderRadius.circular(9),
        child: _cachedPdf != null
            ? PdfPreview(
                key: ValueKey(_pdfGenerationVersion),
                build: (format) => _cachedPdf!,
                allowPrinting: false,
                allowSharing: false,
                canChangeOrientation: false,
                canChangePageFormat: false,
                canDebug: false,
                pdfFileName: '${_cvTemplate.name}.pdf',
                pages: const [0, 1, 2, 3, 4],
                pageFormats: const {
                  'A4': PdfPageFormat.a4,
                },
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
    );
  }
}
