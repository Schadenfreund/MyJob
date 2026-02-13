import 'package:flutter/material.dart';
import '../../localization/app_localizations.dart';
import 'sections/personal_info_section.dart';
import 'sections/skills_section.dart';
import 'sections/work_experience_section.dart';
import 'sections/languages_section.dart';
import 'sections/templates_section.dart';
import 'dialogs/cv_export_dialog.dart';

/// Redesigned Templates screen with card-based sections
class TemplatesScreen extends StatelessWidget {
  const TemplatesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      color: theme.colorScheme.surface,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.person,
                    color: theme.colorScheme.primary,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        context.tr('user_data_templates'),
                        style: theme.textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        context.tr('user_data_templates_desc'),
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.textTheme.bodySmall?.color
                              ?.withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ),
                ),
                Row(
                  children: [
                    _ExportPdfButton(),
                    const SizedBox(width: 12),
                    _ImportDataButton(),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 32),

            // Personal Info Section
            const PersonalInfoSection(),
            const SizedBox(height: 24),

            // Skills Section
            const SkillsSection(),
            const SizedBox(height: 24),

            // Work Experience Section
            const WorkExperienceSection(),
            const SizedBox(height: 24),

            // Languages Section
            const LanguagesSection(),
            const SizedBox(height: 24),

            // Document Templates Section
            const TemplatesSection(),
          ],
        ),
      ),
    );
  }
}

/// Export PDF button widget
class _ExportPdfButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return OutlinedButton.icon(
      onPressed: () => _showExportDialog(context),
      icon: const Icon(Icons.picture_as_pdf, size: 18),
      label: Text(context.tr('pdf_dialog_export')),
      style: OutlinedButton.styleFrom(
        foregroundColor: theme.colorScheme.primary,
        side: BorderSide(color: theme.colorScheme.primary),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      ),
    );
  }

  void _showExportDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => _ExportPdfDialog(),
    );
  }
}

/// Export PDF dialog
class _ExportPdfDialog extends StatefulWidget {
  @override
  State<_ExportPdfDialog> createState() => _ExportPdfDialogState();
}

class _ExportPdfDialogState extends State<_ExportPdfDialog> {
  int _selectedOption = 0; // 0 = CV, 1 = Cover Letter

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(context.tr('export_as_pdf')),
      content: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(context.tr('choose_export')),
            const SizedBox(height: 16),

            // Option tiles
            _buildOptionTile(
              context: context,
              index: 0,
              icon: Icons.description,
              title: context.tr('cv_full_name'),
              description: context.tr('cv_export_desc'),
            ),
            const SizedBox(height: 12),
            _buildOptionTile(
              context: context,
              index: 1,
              icon: Icons.mail,
              title: context.tr('cover_letter'),
              description: context.tr('cl_export_desc'),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(context.tr('cancel')),
        ),
        ElevatedButton.icon(
          onPressed: () {
            Navigator.pop(context);
            if (_selectedOption == 0) {
              _showCvExportDialog(context);
            } else {
              _showCoverLetterDialog(context);
            }
          },
          icon: const Icon(Icons.arrow_forward, size: 18),
          label: Text(context.tr('continue_button')),
        ),
      ],
    );
  }

  Widget _buildOptionTile({
    required BuildContext context,
    required int index,
    required IconData icon,
    required String title,
    required String description,
  }) {
    final theme = Theme.of(context);
    final isSelected = _selectedOption == index;

    return InkWell(
      onTap: () => setState(() => _selectedOption = index),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected ? theme.colorScheme.primary : theme.dividerColor,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
          color: isSelected
              ? theme.colorScheme.primary.withValues(alpha: 0.05)
              : Colors.transparent,
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: isSelected
                    ? theme.colorScheme.primary.withValues(alpha: 0.1)
                    : theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                color: isSelected
                    ? theme.colorScheme.primary
                    : theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.6),
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: isSelected ? theme.colorScheme.primary : null,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.textTheme.bodySmall?.color
                          ?.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(
                Icons.check_circle,
                color: theme.colorScheme.primary,
                size: 24,
              ),
          ],
        ),
      ),
    );
  }

  void _showCvExportDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const CvExportDialog(),
    );
  }

  void _showCoverLetterDialog(BuildContext context) {
    // TODO: Implement cover letter export dialog
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(context.tr('cl_export_coming_soon'))),
    );
  }
}

/// Import data button widget
class _ImportDataButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ElevatedButton.icon(
      onPressed: () => _showImportDialog(context),
      icon: const Icon(Icons.upload_file, size: 18),
      label: Text(context.tr('import_data')),
      style: ElevatedButton.styleFrom(
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      ),
    );
  }

  void _showImportDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.tr('import_user_data')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(context.tr('import_yaml_desc')),
            const SizedBox(height: 16),
            Text(
              context.tr('template_files_location'),
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              'UserData/CV/\n  • cv_data_english.yaml\n  • cv_data_german.yaml',
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 12,
                color: Theme.of(context).textTheme.bodySmall?.color,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(context.tr('close')),
          ),
          ElevatedButton(
            onPressed: () {
              // TODO: Implement file picker for YAML import
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(context.tr('file_picker_coming_soon'))),
              );
            },
            child: Text(context.tr('select_file')),
          ),
        ],
      ),
    );
  }
}
