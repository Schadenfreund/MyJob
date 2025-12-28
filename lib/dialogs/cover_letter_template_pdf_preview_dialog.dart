import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../models/cover_letter_template.dart';
import '../models/cv_data.dart';
import '../models/template_style.dart';
import '../services/cover_letter_template_pdf_service.dart';
import 'base_template_pdf_preview_dialog.dart';

/// Full-screen PDF preview dialog for cover letter templates
class CoverLetterTemplatePdfPreviewDialog extends BaseTemplatePdfPreviewDialog {
  const CoverLetterTemplatePdfPreviewDialog({
    required this.coverLetterTemplate,
    this.contactDetails,
    super.templateStyle,
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
}

class _CoverLetterTemplatePdfPreviewDialogState
    extends BaseTemplatePdfPreviewDialogState<CoverLetterTemplatePdfPreviewDialog> {

  @override
  bool get useSidebarLayout => false;

  @override
  String getDocumentName() => widget.coverLetterTemplate.name;

  @override
  Future<Uint8List> generatePdfBytes() async {
    final service = CoverLetterTemplatePdfService();
    final coverLetter = widget.coverLetterTemplate.toCoverLetter();

    final tempDir = Directory.systemTemp;
    final tempPath = '${tempDir.path}/temp_cover_letter_preview.pdf';

    final file = await service.generatePdfFromCoverLetter(
      coverLetter: coverLetter,
      contactDetails: widget.contactDetails,
      templateStyle: selectedStyle,
      outputPath: tempPath,
    );

    final bytes = await file.readAsBytes();
    await file.delete();
    return bytes;
  }

  @override
  Future<void> exportPdf(BuildContext context, String outputPath) async {
    final service = CoverLetterTemplatePdfService();
    final coverLetter = widget.coverLetterTemplate.toCoverLetter();

    await service.generatePdfFromCoverLetter(
      coverLetter: coverLetter,
      outputPath: outputPath,
      contactDetails: widget.contactDetails,
      templateStyle: selectedStyle,
    );
  }
}
