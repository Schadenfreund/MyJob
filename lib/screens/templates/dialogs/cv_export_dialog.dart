import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pdf/pdf.dart';
import 'package:file_picker/file_picker.dart';
import '../../../providers/user_data_provider.dart';
import '../../../services/cv_pdf_service.dart';
import '../../../services/settings_service.dart';

/// Dialog for exporting CV as PDF
class CvExportDialog extends StatefulWidget {
  const CvExportDialog({super.key});

  @override
  State<CvExportDialog> createState() => _CvExportDialogState();
}

class _CvExportDialogState extends State<CvExportDialog> {
  bool _isExporting = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final userDataProvider = context.watch<UserDataProvider>();
    final personalInfo = userDataProvider.personalInfo;

    // Check if we have the minimum required data
    final canExport = personalInfo != null;

    return AlertDialog(
      title: const Text('Export CV as PDF'),
      content: SizedBox(
        width: 450,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!canExport) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.error.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: theme.colorScheme.error.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.warning,
                      color: theme.colorScheme.error,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Please add your personal information before exporting.',
                        style: TextStyle(
                          color: theme.colorScheme.error,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ] else ...[
              const Text(
                'Your CV will be generated with the following information:',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 16),
              _InfoRow(
                icon: Icons.person,
                label: 'Personal Info',
                value: personalInfo.fullName,
              ),
              _InfoRow(
                icon: Icons.work,
                label: 'Work Experience',
                value: '${userDataProvider.workExperiences.length} entries',
              ),
              _InfoRow(
                icon: Icons.star,
                label: 'Skills',
                value: '${userDataProvider.skills.length} skills',
              ),
              _InfoRow(
                icon: Icons.language,
                label: 'Languages',
                value: '${userDataProvider.languages.length} languages',
              ),
              const SizedBox(height: 16),
              Text(
                'The PDF will be saved to your chosen location.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color:
                      theme.textTheme.bodySmall?.color?.withValues(alpha: 0.7),
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isExporting ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton.icon(
          onPressed: canExport && !_isExporting ? _exportCv : null,
          icon: _isExporting
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.download, size: 18),
          label: Text(_isExporting ? 'Exporting...' : 'Export PDF'),
        ),
      ],
    );
  }

  Future<void> _exportCv() async {
    setState(() => _isExporting = true);

    try {
      // Let user choose save location
      final result = await FilePicker.platform.saveFile(
        dialogTitle: 'Save CV as PDF',
        fileName: 'CV_${DateTime.now().toString().split(' ')[0]}.pdf',
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );

      if (result == null) {
        setState(() => _isExporting = false);
        return;
      }

      if (!mounted) return;

      final userDataProvider = context.read<UserDataProvider>();
      final settings = context.read<SettingsService>();

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
      );

      if (mounted) {
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
      if (mounted) {
        setState(() => _isExporting = false);
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

/// Info row widget
class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(
            icon,
            size: 18,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(width: 12),
          Text(
            '$label:',
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 13,
                color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.8),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
