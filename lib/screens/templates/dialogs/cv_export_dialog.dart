import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import '../../../providers/user_data_provider.dart';
import '../../../services/pdf_service.dart';
import '../../../services/settings_service.dart';
import '../../../localization/app_localizations.dart';

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
      title: Text(context.tr('export_cv_as_pdf')),
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
                        context.tr('add_personal_info_before_export'),
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
              Text(
                context.tr('cv_will_be_generated'),
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 16),
              _InfoRow(
                icon: Icons.person,
                label: context.tr('personal_info'),
                value: personalInfo.fullName,
              ),
              _InfoRow(
                icon: Icons.work,
                label: context.tr('work_experience'),
                value: context.tr('n_entries', {'count': '${userDataProvider.workExperiences.length}'}),
              ),
              _InfoRow(
                icon: Icons.star,
                label: context.tr('skills'),
                value: context.tr('n_skills', {'count': '${userDataProvider.skills.length}'}),
              ),
              _InfoRow(
                icon: Icons.language,
                label: context.tr('languages_section'),
                value: context.tr('n_languages', {'count': '${userDataProvider.languages.length}'}),
              ),
              const SizedBox(height: 16),
              Text(
                context.tr('pdf_saved_to_location'),
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
          child: Text(context.tr('cancel')),
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
          label: Text(_isExporting ? context.tr('exporting') : context.tr('pdf_dialog_export')),
        ),
      ],
    );
  }

  Future<void> _exportCv() async {
    setState(() => _isExporting = true);

    try {
      // Let user choose save location
      final result = await FilePicker.platform.saveFile(
        dialogTitle: context.tr('export_cv_as_pdf'),
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

      // Generate PDF using unified PdfService
      await PdfService.instance.generateCvFromUserData(
        personalInfo: userDataProvider.personalInfo!,
        skills: userDataProvider.skills,
        workExperiences: userDataProvider.workExperiences,
        languages: userDataProvider.languages,
        interests: userDataProvider.interests,
        outputPath: result,
        accentColor: settings.accentColor,
      );

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.tr('cv_exported_success')),
            backgroundColor: Theme.of(context).colorScheme.primary,
            action: SnackBarAction(
              label: context.tr('open_folder'),
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
            content: Text('${context.tr('error_exporting_cv')}: $e'),
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
