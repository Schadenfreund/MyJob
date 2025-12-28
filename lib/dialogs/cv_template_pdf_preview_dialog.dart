import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../models/cv_template.dart';
import '../models/template_style.dart';
import '../models/template_customization.dart';
import '../services/cv_template_pdf_service.dart';
import 'base_template_pdf_preview_dialog.dart';

/// Clean, professional PDF preview with sidebar controls for CV templates
class CvTemplatePdfPreviewDialog extends BaseTemplatePdfPreviewDialog {
  const CvTemplatePdfPreviewDialog({
    required this.cvTemplate,
    super.templateStyle,
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
  late TemplateCustomization _customization;

  @override
  void initState() {
    _customization = const TemplateCustomization();
    super.initState();
  }

  @override
  bool get useSidebarLayout => true;

  @override
  String getDocumentName() => widget.cvTemplate.name;

  @override
  Future<Uint8List> generatePdfBytes() async {
    final service = CvTemplatePdfService();
    final cvData = widget.cvTemplate.toCvData();

    final tempDir = await Directory.systemTemp.createTemp();
    final tempFile = File('${tempDir.path}/preview.pdf');

    try {
      final file = await service.generatePdfFromCvData(
        cvData: cvData,
        outputPath: tempFile.path,
        templateStyle: selectedStyle,
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

  @override
  Future<void> exportPdf(BuildContext context, String outputPath) async {
    final service = CvTemplatePdfService();
    final cvData = widget.cvTemplate.toCvData();

    await service.generatePdfFromCvData(
      cvData: cvData,
      outputPath: outputPath,
      templateStyle: selectedStyle,
      customization: _customization,
      includeProfilePicture: true,
    );
  }

  @override
  List<Widget> buildAdditionalSections() {
    return [
      _buildDarkModeSection(),
      const SizedBox(height: 24),
      _buildInfoSection(),
    ];
  }

  Widget _buildDarkModeSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.brightness_6, color: selectedStyle.accentColor, size: 18),
            const SizedBox(width: 8),
            const Text(
              'COLOR MODE',
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
        Container(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: selectedStyle.accentColor.withValues(alpha: 0.2),
              width: 1,
            ),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: toggleDarkMode,
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Icon(
                      selectedStyle.isDarkMode ? Icons.dark_mode : Icons.light_mode,
                      color: selectedStyle.accentColor,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            selectedStyle.isDarkMode ? 'Dark Mode' : 'Light Mode',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            selectedStyle.isDarkMode
                                ? 'Dark background'
                                : 'Light background',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.6),
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Switch(
                      value: selectedStyle.isDarkMode,
                      onChanged: (_) => toggleDarkMode(),
                      activeThumbColor: selectedStyle.accentColor,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.info_outline, color: selectedStyle.accentColor, size: 18),
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
        _buildInfoRow('Font', selectedStyle.fontFamily.displayName),
        _buildInfoRow('Mode', selectedStyle.isDarkMode ? 'Dark' : 'Light'),
        _buildInfoRow('Accent', _getColorName(selectedStyle.accentColor)),
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
