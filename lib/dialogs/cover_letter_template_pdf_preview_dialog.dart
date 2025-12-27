import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as path;
import '../models/cover_letter.dart';
import '../models/cover_letter_template.dart';
import '../models/cv_data.dart';
import '../models/template_style.dart';
import '../services/cover_letter_template_pdf_service.dart';

/// Full-screen PDF preview dialog for cover letter templates with integrated style selection
///
/// **UX IMPROVEMENT:** Template style selection is now integrated directly into
/// the preview dialog, eliminating the need for a separate style picker dialog.
/// Users can switch between templates in real-time and see the preview update instantly.
class CoverLetterTemplatePdfPreviewDialog extends StatefulWidget {
  const CoverLetterTemplatePdfPreviewDialog({
    required this.coverLetterTemplate,
    this.contactDetails,
    this.templateStyle,
    super.key,
  });

  final CoverLetterTemplate coverLetterTemplate;
  final ContactDetails? contactDetails;
  final TemplateStyle? templateStyle;

  @override
  State<CoverLetterTemplatePdfPreviewDialog> createState() =>
      _CoverLetterTemplatePdfPreviewDialogState();
}

class _CoverLetterTemplatePdfPreviewDialogState
    extends State<CoverLetterTemplatePdfPreviewDialog> {
  late TemplateStyle _selectedStyle;
  bool _isGenerating = false;

  // Professional color presets for accent colors
  static const Map<String, Color> _accentColorPresets = {
    'Navy': Color(0xFF1E3A5F),
    'Teal': Color(0xFF0F766E),
    'Burgundy': Color(0xFF7C2D2D),
    'Forest': Color(0xFF166534),
    'Slate': Color(0xFF475569),
    'Indigo': Color(0xFF4338CA),
    'Rose': Color(0xFFBE185D),
    'Amber': Color(0xFFB45309),
    'Charcoal': Color(0xFF374151),
    'Ocean': Color(0xFF0369A1),
  };

  @override
  void initState() {
    super.initState();
    _selectedStyle = widget.templateStyle ??
        widget.coverLetterTemplate.templateStyle ??
        TemplateStyle.professional;
  }

  void _updateAccentColor(Color color) {
    setState(() {
      _selectedStyle = _selectedStyle.copyWith(
        accentColor: color,
        primaryColor: color,
      );
      _isGenerating = true;
    });
    Future.delayed(
      const Duration(milliseconds: 500),
      () {
        if (mounted) {
          setState(() => _isGenerating = false);
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Dialog.fullscreen(
      child: Scaffold(
        backgroundColor: theme.colorScheme.surface,
        appBar: AppBar(
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
                      'Cover Letter Preview',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      widget.coverLetterTemplate.name,
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
            // Export button
            ElevatedButton.icon(
              onPressed: () => _exportPdf(context),
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
        ),
        body: Column(
          children: [
            // Template Style Selector Bar (STREAMLINED UX)
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                border: Border(
                  bottom: BorderSide(
                    color: theme.dividerColor.withValues(alpha: 0.3),
                  ),
                ),
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 16,
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.style,
                    color: theme.colorScheme.primary,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Template Style:',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: TemplateStyle.allPresets.map((style) {
                          final isSelected = _selectedStyle.type == style.type;
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: ChoiceChip(
                              label: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 12,
                                    height: 12,
                                    decoration: BoxDecoration(
                                      color: style.primaryColor,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: Colors.white,
                                        width: 1,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(style.type.label),
                                ],
                              ),
                              selected: isSelected,
                              onSelected: (selected) {
                                if (selected) {
                                  setState(() {
                                    _selectedStyle = style;
                                    _isGenerating = true;
                                  });
                                  // Reset generating state after a delay
                                  Future.delayed(
                                    const Duration(milliseconds: 500),
                                    () {
                                      if (mounted) {
                                        setState(() => _isGenerating = false);
                                      }
                                    },
                                  );
                                }
                              },
                              avatar: isSelected
                                  ? Icon(
                                      Icons.check_circle,
                                      size: 16,
                                      color: theme.colorScheme.primary,
                                    )
                                  : null,
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
                  if (_isGenerating) ...[
                    const SizedBox(width: 16),
                    SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // Accent Color Picker Row
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                border: Border(
                  bottom: BorderSide(
                    color: theme.dividerColor.withValues(alpha: 0.3),
                  ),
                ),
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 12,
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.palette,
                    color: theme.colorScheme.secondary,
                    size: 20,
                  ),
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
                        children: _accentColorPresets.entries.map((entry) {
                          final isSelected =
                              _selectedStyle.primaryColor.toARGB32() ==
                                  entry.value.toARGB32();
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: Tooltip(
                              message: entry.key,
                              child: InkWell(
                                onTap: () => _updateAccentColor(entry.value),
                                borderRadius: BorderRadius.circular(20),
                                child: Container(
                                  width: 32,
                                  height: 32,
                                  decoration: BoxDecoration(
                                    color: entry.value,
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
                                          color: entry.value.computeLuminance() > 0.5
                                              ? Colors.black
                                              : Colors.white,
                                        )
                                      : null,
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // PDF Preview
            Expanded(
              child: PdfPreview(
                build: (format) => _generatePdf(),
                canChangePageFormat: false,
                canChangeOrientation: false,
                canDebug: false,
                allowSharing: false,
                allowPrinting: true,
                pdfFileName:
                    '${widget.coverLetterTemplate.name.replaceAll(' ', '_')}_${_selectedStyle.type.label}.pdf',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<Uint8List> _generatePdf() async {
    final service = CoverLetterTemplatePdfService();
    final coverLetter = widget.coverLetterTemplate.toCoverLetter();

    // Create temporary file
    final tempDir = Directory.systemTemp;
    final tempFile =
        File(path.join(tempDir.path, 'temp_cover_letter_preview.pdf'));

    final file = await service.generatePdfFromCoverLetter(
      coverLetter: coverLetter,
      outputPath: tempFile.path,
      contactDetails: widget.contactDetails,
      templateStyle: _selectedStyle,
    );

    final bytes = await file.readAsBytes();

    // Clean up temp file
    try {
      await tempFile.delete();
    } catch (_) {}

    return bytes;
  }

  Future<void> _exportPdf(BuildContext context) async {
    try {
      // Pick save location
      final outputPath = await FilePicker.platform.saveFile(
        dialogTitle: 'Save Cover Letter PDF',
        fileName:
            '${widget.coverLetterTemplate.name.replaceAll(' ', '_')}_${_selectedStyle.type.label}.pdf',
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );

      if (outputPath == null) return;

      if (!mounted) return;

      // Show progress (IMPROVED UX: Visual feedback)
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          content: Row(
            children: [
              const CircularProgressIndicator(),
              const SizedBox(width: 24),
              Text(
                'Generating PDF...',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ],
          ),
        ),
      );

      // Generate and save PDF
      final service = CoverLetterTemplatePdfService();
      final coverLetter = widget.coverLetterTemplate.toCoverLetter();

      await service.generatePdfFromCoverLetter(
        coverLetter: coverLetter,
        outputPath: outputPath,
        contactDetails: widget.contactDetails,
        templateStyle: _selectedStyle,
      );

      if (mounted) {
        Navigator.pop(context); // Close progress dialog

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(
                  child: Text('PDF saved to: ${path.basename(outputPath)}'),
                ),
              ],
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
            action: SnackBarAction(
              label: 'CLOSE',
              textColor: Colors.white,
              onPressed: () => Navigator.pop(context),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Close progress dialog if open

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(child: Text('Failed to export PDF: $e')),
              ],
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }
}
