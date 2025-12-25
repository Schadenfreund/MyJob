import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/cv_template.dart';
import '../../providers/templates_provider.dart';
import '../../widgets/yaml_import_section.dart';
import '../../widgets/document_template_card.dart';
import '../../dialogs/template_style_picker_dialog.dart';
import '../../dialogs/pdf_preview_dialog.dart';
import '../cv_template_editor/cv_template_editor_screen.dart';

/// Main Documents screen - YAML-first workflow for CV/Cover Letter creation
class DocumentsScreen extends StatelessWidget {
  const DocumentsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final templatesProvider = context.watch<TemplatesProvider>();

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
                    Icons.description,
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
                        'Documents',
                        style: theme.textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Import YAML templates and generate beautiful PDFs',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.textTheme.bodySmall?.color
                              ?.withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),

            // YAML Import Section
            const YamlImportSection(),
            const SizedBox(height: 32),

            // Your Documents Section
            Text(
              'Your Documents',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),

            // Two-column layout: CV Documents | Cover Letters
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // CV Documents Column
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Column Header
                      Row(
                        children: [
                          Icon(
                            Icons.description_outlined,
                            size: 20,
                            color: theme.colorScheme.primary,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'CV Documents',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            '${templatesProvider.cvTemplates.length}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.textTheme.bodySmall?.color
                                  ?.withValues(alpha: 0.6),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // CV Template Cards
                      if (templatesProvider.cvTemplates.isEmpty)
                        _buildEmptyState(
                          context,
                          'No CV templates yet',
                          'Import a CV YAML file or create a new template',
                          Icons.description_outlined,
                        )
                      else
                        ...templatesProvider.cvTemplates.map(
                          (template) => Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: DocumentTemplateCard(
                              name: template.name,
                              language: 'English', // TODO: Get from template
                              lastModified: DateTime.now(),
                              type: DocumentType.cv,
                              onGeneratePdf: () =>
                                  _generateCvPdf(context, template),
                              onEdit: () => _editTemplate(context, template),
                              onDuplicate: () =>
                                  _duplicateTemplate(context, template),
                              onDelete: () =>
                                  _deleteTemplate(context, template),
                            ),
                          ),
                        ),

                      // Add New CV Button
                      const SizedBox(height: 8),
                      OutlinedButton.icon(
                        onPressed: () => _createNewCv(context),
                        icon: const Icon(Icons.add, size: 18),
                        label: const Text('New CV Template'),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 48),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 24),

                // Cover Letters Column
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Column Header
                      Row(
                        children: [
                          Icon(
                            Icons.mail_outline,
                            size: 20,
                            color: theme.colorScheme.primary,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Cover Letters',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            '${templatesProvider.coverLetterTemplates.length}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.textTheme.bodySmall?.color
                                  ?.withValues(alpha: 0.6),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Cover Letter Template Cards
                      if (templatesProvider.coverLetterTemplates.isEmpty)
                        _buildEmptyState(
                          context,
                          'No cover letter templates yet',
                          'Import a cover letter YAML file or create a new template',
                          Icons.mail_outline,
                        )
                      else
                        ...templatesProvider.coverLetterTemplates.map(
                          (template) => Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: DocumentTemplateCard(
                              name: template.name,
                              language: 'English', // TODO: Get from template
                              lastModified: DateTime.now(),
                              type: DocumentType.coverLetter,
                              onGeneratePdf: () =>
                                  _generateCoverLetterPdf(context, template),
                              onEdit: () => _editTemplate(context, template),
                              onDuplicate: () =>
                                  _duplicateTemplate(context, template),
                              onDelete: () =>
                                  _deleteTemplate(context, template),
                            ),
                          ),
                        ),

                      // Add New Cover Letter Button
                      const SizedBox(height: 8),
                      OutlinedButton.icon(
                        onPressed: () => _createNewCoverLetter(context),
                        icon: const Icon(Icons.add, size: 18),
                        label: const Text('New Cover Letter'),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 48),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon,
  ) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.dividerColor.withValues(alpha: 0.5),
        ),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            size: 48,
            color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.7),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  void _generateCvPdf(BuildContext context, dynamic template) {
    showDialog(
      context: context,
      builder: (context) => TemplateStylePickerDialog(
        onStyleSelected: (style) {
          showDialog(
            context: context,
            builder: (context) => PdfPreviewDialog(templateStyle: style),
          );
        },
      ),
    );
  }

  void _generateCoverLetterPdf(BuildContext context, dynamic template) {
    // Show template style picker for cover letters too
    showDialog(
      context: context,
      builder: (context) => TemplateStylePickerDialog(
        onStyleSelected: (style) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Cover letter PDF generation coming soon'),
            ),
          );
        },
      ),
    );
  }

  void _editTemplate(BuildContext context, dynamic template) {
    final isCv = template.runtimeType.toString().contains('Cv');

    if (isCv && template is CvTemplate) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => CvTemplateEditorScreen(template: template),
        ),
      );
    } else {
      // Cover letter editor - coming soon
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cover letter editor coming soon')),
      );
    }
  }

  void _duplicateTemplate(BuildContext context, dynamic template) async {
    final templatesProvider = context.read<TemplatesProvider>();
    final isCv = template.runtimeType.toString().contains('Cv');

    try {
      if (isCv) {
        await templatesProvider.createCvTemplate(
          name: '${template.name} (Copy)',
          profile: template.profile,
          skills: List<String>.from(template.skills ?? []),
          contactDetails: template.contactDetails,
        );
      } else {
        await templatesProvider.createCoverLetterTemplate(
          name: '${template.name} (Copy)',
          greeting: template.greeting,
          body: template.body,
          closing: template.closing,
        );
      }

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${template.name} duplicated'),
            backgroundColor: Theme.of(context).colorScheme.primary,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error duplicating template: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  void _deleteTemplate(BuildContext context, dynamic template) {
    final isCv = template.runtimeType.toString().contains('Cv');

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Template'),
        content: Text(
          'Are you sure you want to delete "${template.name}"?\n\nThis action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              final templatesProvider = context.read<TemplatesProvider>();

              try {
                if (isCv) {
                  await templatesProvider.deleteCvTemplate(template.id);
                } else {
                  await templatesProvider
                      .deleteCoverLetterTemplate(template.id);
                }

                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('${template.name} deleted'),
                      backgroundColor: Theme.of(context).colorScheme.primary,
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error deleting template: $e'),
                      backgroundColor: Theme.of(context).colorScheme.error,
                    ),
                  );
                }
              }
            },
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(dialogContext).colorScheme.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _createNewCv(BuildContext context) async {
    final templatesProvider = context.read<TemplatesProvider>();

    try {
      await templatesProvider.createCvTemplate(
        name: 'New CV Template',
        profile: 'Add your professional summary here...',
      );

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('New CV template created'),
            backgroundColor: Theme.of(context).colorScheme.primary,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error creating template: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  void _createNewCoverLetter(BuildContext context) async {
    final templatesProvider = context.read<TemplatesProvider>();

    try {
      await templatesProvider.createCoverLetterTemplate(
        name: 'New Cover Letter',
        greeting: 'Dear Hiring Manager,',
        body: 'Write your cover letter content here...',
        closing: 'Kind regards,',
      );

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('New cover letter template created'),
            backgroundColor: Theme.of(context).colorScheme.primary,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error creating template: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }
}

/// Document type enum
enum DocumentType {
  cv,
  coverLetter,
}
