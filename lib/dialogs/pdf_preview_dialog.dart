import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:printing/printing.dart';
import 'package:pdf/pdf.dart';
import 'package:file_picker/file_picker.dart';
import '../models/template_style.dart';
import '../providers/user_data_provider.dart';
import '../services/cv_pdf_service.dart';
import '../services/settings_service.dart';

/// Full-screen PDF preview dialog with export capability
class PdfPreviewDialog extends StatelessWidget {
  const PdfPreviewDialog({
    required this.templateStyle,
    super.key,
  });

  final TemplateStyle templateStyle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final userDataProvider = context.watch<UserDataProvider>();
    final settings = context.watch<SettingsService>();

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
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'PDF Preview',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    '${templateStyle.type.label} Template',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.textTheme.bodySmall?.color
                          ?.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            ],
          ),
          leading: IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.pop(context),
            tooltip: 'Close',
          ),
          actions: [
            // Change template button
            TextButton.icon(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.style, size: 18),
              label: const Text('Change Template'),
            ),
            const SizedBox(width: 8),

            // Export button
            ElevatedButton.icon(
              onPressed: () => _exportPdf(context, userDataProvider, settings),
              icon: const Icon(Icons.download, size: 18),
              label: const Text('Export PDF'),
              style: ElevatedButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              ),
            ),
            const SizedBox(width: 16),
          ],
        ),
        body: Container(
          color:
              theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
          padding: const EdgeInsets.all(24),
          child: PdfPreview(
            build: (format) => _generatePdf(userDataProvider, settings),
            canChangePageFormat: false,
            canChangeOrientation: false,
            canDebug: false,
            maxPageWidth: 700,
            pdfFileName: 'CV_${DateTime.now().toString().split(' ')[0]}.pdf',
          ),
        ),
      ),
    );
  }

  /// Generate PDF bytes for preview
  Future<Uint8List> _generatePdf(
    UserDataProvider userDataProvider,
    SettingsService settings,
  ) async {
    if (userDataProvider.personalInfo == null) {
      throw Exception('Personal info is required');
    }

    // Convert Flutter Color to PDF Color
    final color = settings.accentColor;
    final accentColor = PdfColor(color.r, color.g, color.b, color.a);

    // Create a temporary file path for generation
    final tempDir = Directory.systemTemp;
    final tempFile = File('${tempDir.path}/temp_cv_preview.pdf');

    final service = CvPdfService();
    final file = await service.generateCvPdf(
      personalInfo: userDataProvider.personalInfo!,
      skills: userDataProvider.skills,
      workExperiences: userDataProvider.workExperiences,
      languages: userDataProvider.languages,
      interests: userDataProvider.interests,
      outputPath: tempFile.path,
      accentColor: accentColor,
      templateType: templateStyle.type,
    );

    final bytes = await file.readAsBytes();
    return Uint8List.fromList(bytes);
  }

  /// Export PDF to user-selected location
  Future<void> _exportPdf(
    BuildContext context,
    UserDataProvider userDataProvider,
    SettingsService settings,
  ) async {
    try {
      // Let user choose save location
      final result = await FilePicker.platform.saveFile(
        dialogTitle: 'Save CV as PDF',
        fileName: 'CV_${DateTime.now().toString().split(' ')[0]}.pdf',
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );

      if (result == null || !context.mounted) return;

      if (userDataProvider.personalInfo == null) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text(
                  'Please add your personal information before exporting.'),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        }
        return;
      }

      // Convert accent color to PDF color
      final color = settings.accentColor;
      final accentColor = PdfColor(color.r, color.g, color.b, color.a);

      // Generate PDF
      final service = CvPdfService();
      await service.generateCvPdf(
        personalInfo: userDataProvider.personalInfo!,
        skills: userDataProvider.skills,
        workExperiences: userDataProvider.workExperiences,
        languages: userDataProvider.languages,
        interests: userDataProvider.interests,
        outputPath: result,
        accentColor: accentColor,
        templateType: templateStyle.type,
      );

      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('CV exported successfully!'),
            backgroundColor: Theme.of(context).colorScheme.primary,
            action: SnackBarAction(
              label: 'Open Folder',
              textColor: Colors.white,
              onPressed: () {
                // Open folder containing the file
                final file = File(result);
                Process.run('explorer.exe', ['/select,', file.path]);
              },
            ),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error exporting CV: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }
}
