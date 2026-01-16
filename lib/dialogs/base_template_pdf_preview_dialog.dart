import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:window_manager/window_manager.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as path;
import 'package:printing/printing.dart';
import '../models/template_style.dart';
import '../models/template_customization.dart';
import '../models/pdf_font_family.dart';
import '../models/pdf_document_type.dart';
import '../services/pdf_font_service.dart';
import '../services/log_service.dart';
import '../widgets/pdf_editor/pdf_editor_controller.dart';
import '../widgets/pdf_editor/pdf_editor_sidebar.dart';
import '../widgets/pdf_editor/pdf_editor_toolbar.dart';
import '../widgets/pdf_editor/template_edit_panel.dart';
import '../widgets/pdf_editor/enhanced_pdf_viewer.dart';

/// Base class for PDF preview/editor dialogs with enhanced functionality
///
/// This centralized base class provides:
/// - Dynamic layout adjustments (spacing, margins, line height)
/// - Side-by-side and single page view modes
/// - Inline template editing capabilities
/// - Accent color and font family customization
/// - Export and print functionality
/// - Clean, DRY architecture using PDF editor components
///
/// Subclasses must implement:
/// - generatePdfBytes() - PDF generation logic with current style/customization
/// - exportPdf() - Export logic with service-specific details
/// - getDocumentName() - Name for the document being previewed
/// - buildEditableFields() - List of editable fields for inline editing (optional)
abstract class BaseTemplatePdfPreviewDialog extends StatefulWidget {
  const BaseTemplatePdfPreviewDialog({
    this.templateStyle,
    this.templateCustomization,
    super.key,
  });

  final TemplateStyle? templateStyle;
  final TemplateCustomization? templateCustomization;

  TemplateStyle getDefaultStyle() => TemplateStyle.electric;
  TemplateCustomization getDefaultCustomization() =>
      const TemplateCustomization();

  /// Get the document type for this dialog (CV or Cover Letter)
  PdfDocumentType getDocumentType();
}

abstract class BaseTemplatePdfPreviewDialogState<
    T extends BaseTemplatePdfPreviewDialog> extends State<T> {
  // ============================================================================
  // STATE
  // ============================================================================

  late PdfEditorController _controller;

  Uint8List? _cachedPdf;
  List<PdfFontFamily> _availableFonts = [];

  // Editable field values (for inline editing)
  // This map stores field values during editing sessions. Subclasses should use
  // getFieldValue() and updateFieldValue() to read/write these values, and
  // implement buildEditableFields() to expose fields for editing.
  final Map<String, String> _fieldValues = {};

  // ============================================================================
  // GETTERS FOR SUBCLASSES
  // ============================================================================

  /// Current template style
  TemplateStyle get selectedStyle => _controller.style;

  /// Current template customization
  TemplateCustomization get customization => _controller.customization;

  /// PDF editor controller
  PdfEditorController get controller => _controller;

  // ============================================================================
  // LIFECYCLE
  // ============================================================================

  @override
  void initState() {
    super.initState();
    _controller = PdfEditorController(
      initialStyle: widget.templateStyle ?? widget.getDefaultStyle(),
      initialCustomization:
          widget.templateCustomization ?? widget.getDefaultCustomization(),
    );
    _controller.addListener(_onControllerChanged);
    _loadAvailableFonts();
  }

  @override
  void dispose() {
    _controller.removeListener(_onControllerChanged);
    _controller.dispose();
    super.dispose();
  }

  void _onControllerChanged() {
    // Regenerate PDF when controller signals regeneration needed
    if (_controller.needsRegeneration && !_controller.isGenerating) {
      _generatePdfAsync();
    }
    // Always rebuild UI on controller changes (for zoom, view mode, etc.)
    if (mounted) {
      setState(() {});
    }
  }

  // ============================================================================
  // FONT LOADING
  // ============================================================================

  Future<void> _loadAvailableFonts() async {
    try {
      final fonts = await PdfFontService.getAvailableFontFamilies();
      if (!mounted) return;

      setState(() {
        _availableFonts = fonts;

        // Validate selected font is available
        if (_availableFonts.isNotEmpty &&
            !_availableFonts.contains(_controller.style.fontFamily)) {
          _controller.setFontFamily(_availableFonts.first);
        }
      });

      // Generate initial PDF
      _generatePdfAsync();
    } catch (e) {
      if (mounted) {
        setState(() {
          _availableFonts = PdfFontFamily.values.toList();
        });
        _generatePdfAsync();
      }
    }
  }

  // ============================================================================
  // PDF GENERATION - SUBCLASSES MUST IMPLEMENT
  // ============================================================================

  /// Generate PDF bytes with current style and customization
  ///
  /// This is called whenever the style or customization changes.
  /// The implementation should use [selectedStyle] and [customization].
  Future<Uint8List> generatePdfBytes();

  /// Export PDF to file
  Future<void> exportPdf(BuildContext context, String outputPath);

  /// Get document name for display and export
  String getDocumentName();

  /// Get initial directory for export dialog (optional)
  ///
  /// Override this method to provide a default directory for the file picker.
  /// Returns null by default, which lets the system choose the default location.
  String? getInitialExportDirectory() => null;

  // ============================================================================
  // OPTIONAL OVERRIDES
  // ============================================================================

  /// Build list of editable fields for inline editing
  ///
  /// Return empty list to disable inline editing functionality
  List<EditableField> buildEditableFields() => [];

  /// Additional sidebar sections (e.g., dark mode toggle, info)
  List<Widget> buildAdditionalSidebarSections() => [];

  /// Build custom preset selector (override for cover letters)
  /// Return null to use default CV layout presets
  Widget? buildCustomPresets() => null;

  /// Use sidebar layout (true) or horizontal bars (false)
  bool get useSidebarLayout => true;

  /// Hide CV layout presets section (for cover letters)
  bool get hideCvLayoutPresets => false;

  /// Hide photo options section (for cover letters)
  bool get hidePhotoOptions => false;

  /// Get CV section availability for context-sensitive page break toggles
  /// Override in CV dialogs to provide actual section availability
  CvSectionAvailability? getCvSectionAvailability() => null;

  // ============================================================================
  // PDF GENERATION
  // ============================================================================

  Future<void> _generatePdfAsync() async {
    if (_controller.isGenerating) return;

    _controller.setGenerating(true);
    logDebug('Starting PDF generation', tag: 'PdfPreview');

    try {
      final pdf = await generatePdfBytes();

      // Validate PDF bytes
      if (pdf.isEmpty) {
        throw Exception('Generated PDF is empty');
      }

      if (mounted) {
        setState(() {
          _cachedPdf = pdf;
        });
        _controller.markRegenerationComplete();
        _controller.setGenerating(false);
        logInfo('PDF generated successfully (${pdf.length} bytes)',
            tag: 'PdfPreview');
      }
    } catch (e, stackTrace) {
      logError('PDF generation failed',
          error: e, stackTrace: stackTrace, tag: 'PdfPreview');
      if (mounted) {
        _controller.setGenerating(false);
        _showError('Error generating PDF: $e');
      }
    }
  }

  // ============================================================================
  // EXPORT & PRINT
  // ============================================================================

  Future<void> _handleExport() async {
    try {
      final result = await FilePicker.platform.saveFile(
        dialogTitle: 'Export PDF',
        fileName: '${getDocumentName()}.pdf',
        initialDirectory: getInitialExportDirectory(),
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );

      if (result == null || !mounted) return;

      _controller.setGenerating(true);

      await exportPdf(context, result);

      if (!mounted) return;
      _controller.setGenerating(false);

      _showSuccess('PDF exported to ${path.basename(result)}');
    } catch (e) {
      if (!mounted) return;
      _controller.setGenerating(false);
      _showError('Error exporting PDF: $e');
    }
  }

  Future<void> _handlePrint() async {
    if (_cachedPdf == null) return;

    try {
      await Printing.layoutPdf(
        onLayout: (_) => _cachedPdf!,
        name: '${getDocumentName()}.pdf',
      );
    } catch (e) {
      _showError('Error printing PDF: $e');
    }
  }

  // ============================================================================
  // INLINE EDITING
  // ============================================================================

  void _handleSaveEdits() {
    // Subclasses can override to persist field changes
    _controller.setEditMode(false);
    _controller.regenerate();
  }

  void _handleCancelEdits() {
    // Reset field values
    _fieldValues.clear();
    _controller.setEditMode(false);
  }

  // ============================================================================
  // UI
  // ============================================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      body: Column(
        children: [
          _buildTopBar(),
          Expanded(
            child: Row(
              children: [
                if (useSidebarLayout) ...[
                  PdfEditorSidebar(
                    controller: _controller,
                    availableFonts: _availableFonts,
                    additionalSections: buildAdditionalSidebarSections(),
                    hideCvLayoutPresets: hideCvLayoutPresets,
                    hidePhotoOptions: hidePhotoOptions,
                    customPresetsBuilder: buildCustomPresets,
                    documentType: widget.getDocumentType(),
                    cvSectionAvailability: getCvSectionAvailability(),
                  ),
                ],
                Expanded(
                  child: _buildPreviewArea(),
                ),

                // Edit panel (when in edit mode)
                if (_controller.isEditMode && buildEditableFields().isNotEmpty)
                  SizedBox(
                    width: 320,
                    child: TemplateEditPanel(
                      fields: buildEditableFields(),
                      onSave: _handleSaveEdits,
                      onCancel: _handleCancelEdits,
                      accentColor: _controller.style.accentColor,
                    ),
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
      height: 64,
      decoration: BoxDecoration(
        color: Colors.black,
        border: Border(
          bottom: BorderSide(
            color: _controller.style.accentColor.withValues(alpha: 0.3),
            width: 2,
          ),
        ),
      ),
      child: Stack(
        children: [
          // Make entire bar draggable
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onPanStart: (details) => windowManager.startDragging(),
              child: const SizedBox.expand(),
            ),
          ),
          // Content
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: [
                Container(
                  width: 4,
                  height: 32,
                  decoration: BoxDecoration(
                    color: _controller.style.accentColor,
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
                        'PDF PREVIEW & EDITOR',
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
                if (_controller.isGenerating)
                  Padding(
                    padding: const EdgeInsets.only(right: 16),
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation(
                            _controller.style.accentColor),
                      ),
                    ),
                  ),
                ElevatedButton.icon(
                  onPressed: _controller.isGenerating ? null : _handleExport,
                  icon: const Icon(Icons.download, size: 18),
                  label: const Text('Export PDF'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _controller.style.accentColor,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 16),
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
          ),
        ],
      ),
    );
  }

  Widget _buildPreviewArea() {
    return Stack(
      children: [
        Container(
          color: Colors.grey.shade300,
          child: _cachedPdf != null
              ? EnhancedPdfViewer(
                  key: ValueKey('pdf_${_controller.pdfVersion}'),
                  pdfBytes: _cachedPdf!,
                  controller: _controller,
                  fileName: '${getDocumentName()}.pdf',
                )
              : Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 50,
                        height: 50,
                        child: CircularProgressIndicator(
                          color: _controller.style.accentColor,
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
        ),
        // Floating toolbar at bottom
        Positioned(
          bottom: 24,
          left: 0,
          right: 0,
          child: Center(
            child: PdfEditorToolbar(
              controller: _controller,
              accentColor: _controller.style.accentColor,
              onPrint: _handlePrint,
            ),
          ),
        ),
      ],
    );
  }

  // ============================================================================
  // HELPERS
  // ============================================================================

  void _showSuccess(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green.shade600,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showError(String message) {
    // Log error for debugging
    logError(message, tag: 'PdfPreview');

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: SelectableText(
          message,
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 8), // Longer duration for errors
        action: SnackBarAction(
          label: 'Copy',
          textColor: Colors.white,
          onPressed: () {
            Clipboard.setData(ClipboardData(text: message));
          },
        ),
      ),
    );
  }

  /// Update a field value (for inline editing)
  void updateFieldValue(String fieldId, String value) {
    setState(() {
      _fieldValues[fieldId] = value;
    });
  }

  /// Get current field value
  String getFieldValue(String fieldId, String defaultValue) {
    return _fieldValues[fieldId] ?? defaultValue;
  }
}
