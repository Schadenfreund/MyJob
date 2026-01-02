import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../models/cv_template.dart';
import '../models/template_style.dart';
import '../services/pdf_service.dart';
import '../widgets/pdf_editor/template_edit_panel.dart';
import 'base_template_pdf_preview_dialog.dart';

/// PDF preview and editor for CV templates
class CvTemplatePdfPreviewDialog extends BaseTemplatePdfPreviewDialog {
  const CvTemplatePdfPreviewDialog({
    required this.cvTemplate,
    super.templateStyle,
    super.templateCustomization,
    super.key,
  });

  final CvTemplate cvTemplate;

  @override
  State<CvTemplatePdfPreviewDialog> createState() =>
      _CvTemplatePdfPreviewDialogState();

  @override
  TemplateStyle getDefaultStyle() =>
      cvTemplate.templateStyle ?? TemplateStyle.electric;
}

class _CvTemplatePdfPreviewDialogState
    extends BaseTemplatePdfPreviewDialogState<CvTemplatePdfPreviewDialog> {
  @override
  bool get useSidebarLayout => true;

  @override
  String getDocumentName() => widget.cvTemplate.name;

  @override
  Future<Uint8List> generatePdfBytes() async {
    final cvData = widget.cvTemplate.toCvData();
    return PdfService.instance.generateCvPdf(
      cvData,
      selectedStyle,
      customization: customization,
    );
  }

  @override
  Future<void> exportPdf(BuildContext context, String outputPath) async {
    final cvData = widget.cvTemplate.toCvData();
    await PdfService.instance.generateCvToFile(
      cvData: cvData,
      outputPath: outputPath,
      templateStyle: selectedStyle,
      customization: customization,
    );
  }

  @override
  List<Widget> buildAdditionalSidebarSections() {
    return [
      _buildInfoSection(),
    ];
  }

  @override
  List<EditableField> buildEditableFields() {
    // Define editable fields for CV template
    return [
      EditableField(
        id: 'profile',
        label: 'Profile Summary',
        value: getFieldValue('profile', widget.cvTemplate.profile),
        onChanged: (value) => updateFieldValue('profile', value),
        maxLines: 4,
        hint: 'Enter your professional summary...',
      ),
      // Add more editable fields as needed
    ];
  }

  Widget _buildInfoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.info_outline,
                color: controller.style.accentColor, size: 18),
            const SizedBox(width: 8),
            const Text(
              'TEMPLATE INFO',
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
        _buildInfoRow('Style', 'Electric'),
        _buildInfoRow('Font', controller.style.fontFamily.displayName),
        _buildInfoRow('Mode', controller.style.isDarkMode ? 'Dark' : 'Light'),
        _buildInfoRow('Accent', _getColorName(controller.style.accentColor)),
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
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.5),
              fontSize: 11,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  String _getColorName(Color color) {
    final colorMap = {
      0xFFFFFF00: 'Yellow',
      0xFF00FFFF: 'Cyan',
      0xFFFF00FF: 'Magenta',
      0xFF00FF00: 'Lime',
      0xFFFF6600: 'Orange',
      0xFF9D00FF: 'Purple',
      0xFFFF0066: 'Pink',
      0xFF66FF00: 'Chartreuse',
    };
    return colorMap[color.toARGB32()] ?? 'Custom';
  }
}
