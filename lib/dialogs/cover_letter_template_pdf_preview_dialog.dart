import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../models/pdf_document_type.dart';
import '../models/cover_letter_template.dart';
import '../models/cv_data.dart';
import '../models/template_style.dart';
import '../models/cover_letter_template_selection.dart';
import '../services/pdf_service.dart';
import 'base_template_pdf_preview_dialog.dart';

/// PDF preview and editor for cover letter templates
class CoverLetterTemplatePdfPreviewDialog extends BaseTemplatePdfPreviewDialog {
  const CoverLetterTemplatePdfPreviewDialog({
    required this.coverLetterTemplate,
    this.contactDetails,
    super.templateStyle,
    super.templateCustomization,
    super.key,
  });

  final CoverLetterTemplate coverLetterTemplate;
  final ContactDetails? contactDetails;

  @override
  State<CoverLetterTemplatePdfPreviewDialog> createState() =>
      _CoverLetterTemplatePdfPreviewDialogState();

  @override
  TemplateStyle getDefaultStyle() =>
      coverLetterTemplate.templateStyle ?? TemplateStyle.electric;

  @override
  PdfDocumentType getDocumentType() => PdfDocumentType.coverLetter;
}

class _CoverLetterTemplatePdfPreviewDialogState
    extends BaseTemplatePdfPreviewDialogState<
        CoverLetterTemplatePdfPreviewDialog> {
  // Cover letter template selection (independent from CV)
  CoverLetterTemplateType _selectedTemplateType =
      CoverLetterTemplateType.modern;

  @override
  bool get useSidebarLayout => true;

  @override
  bool get hideCvLayoutPresets => true; // Hide CV presets for cover letters

  @override
  String getDocumentName() => widget.coverLetterTemplate.name;

  @override
  Widget? buildCustomPresets() {
    return _buildCoverLetterPresetsSection();
  }

  /// Build cover letter preset section (matching CV preset styling)
  Widget _buildCoverLetterPresetsSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.style, color: controller.style.accentColor, size: 18),
              const SizedBox(width: 8),
              const Text(
                'DESIGN PRESET',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Quick-switch between cover letter styles',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.5),
              fontSize: 10,
            ),
          ),
          const SizedBox(height: 12),
          ...CoverLetterTemplateType.values.map((templateType) {
            final isSelected = _selectedTemplateType == templateType;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    setState(() {
                      _selectedTemplateType = templateType;
                    });
                    controller.regenerate();
                  },
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? controller.style.accentColor.withValues(alpha: 0.15)
                          : Colors.white.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isSelected
                            ? controller.style.accentColor
                            : Colors.white.withValues(alpha: 0.1),
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: isSelected
                                ? controller.style.accentColor
                                : Colors.white.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            _getIconForTemplate(templateType),
                            color: isSelected ? Colors.black : Colors.white,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                templateType.label,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: isSelected
                                      ? FontWeight.bold
                                      : FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                templateType.description,
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.5),
                                  fontSize: 11,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  /// Get icon for template type
  IconData _getIconForTemplate(CoverLetterTemplateType type) {
    switch (type) {
      case CoverLetterTemplateType.modern:
        return Icons.description_outlined; // Modern - clean
      case CoverLetterTemplateType.traditional:
        return Icons.article_outlined; // Traditional - conservative
      case CoverLetterTemplateType.compact:
        return Icons.view_compact_outlined; // Compact - space-efficient
    }
  }

  @override
  Future<Uint8List> generatePdfBytes() async {
    final coverLetter = widget.coverLetterTemplate.toCoverLetter();
    return PdfService.instance.generateCoverLetterPdf(
      coverLetter,
      selectedStyle,
      contactDetails: widget.contactDetails,
      customization: customization,
      coverLetterTemplateType: _selectedTemplateType,
    );
  }

  @override
  Future<void> exportPdf(BuildContext context, String outputPath) async {
    final coverLetter = widget.coverLetterTemplate.toCoverLetter();
    await PdfService.instance.generateCoverLetterToFile(
      coverLetter: coverLetter,
      outputPath: outputPath,
      contactDetails: widget.contactDetails,
      templateStyle: selectedStyle,
      customization: customization,
      coverLetterTemplateType: _selectedTemplateType,
    );
  }
}
