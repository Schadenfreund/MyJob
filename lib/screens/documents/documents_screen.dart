import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/cv_template.dart';
import '../../models/cover_letter_template.dart';
import '../../providers/templates_provider.dart';
import '../../widgets/collapsible_card.dart';
import '../../widgets/document_template_card.dart';
import '../../dialogs/cv_template_pdf_preview_launcher.dart';
import '../../dialogs/cover_letter_template_pdf_preview_dialog.dart';
import '../../theme/app_theme.dart';
import '../../utils/ui_utils.dart';
import '../../utils/dialog_utils.dart';
import '../cv_template_editor/cv_template_editor_screen.dart';
import '../cover_letter_template_editor/cover_letter_template_editor_screen.dart';
import '../../widgets/app_card.dart';

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
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Document Templates',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Manage and customize your CV and Cover Letter styles',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.textTheme.bodySmall?.color,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),

            // Top Action Card - Refactored for quick creation
            AppCardContainer(
              useAccentBorder: true,
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.add_circle_outline,
                      color: theme.colorScheme.primary,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Text(
                      'Create new template?',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  AppCardActionButton(
                    onPressed: () => _createNewCv(context),
                    icon: Icons.add,
                    label: 'CV',
                    isFilled: true,
                  ),
                  const SizedBox(width: 8),
                  AppCardActionButton(
                    onPressed: () => _createNewCoverLetter(context),
                    icon: Icons.add,
                    label: 'Letter',
                    isFilled: true,
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xl),

            // CV Templates Section
            CollapsibleCard(
              cardId: 'documents_cv_templates',
              title: 'CV Templates',
              subtitle:
                  '${templatesProvider.cvTemplates.length} template${templatesProvider.cvTemplates.length == 1 ? '' : 's'}',
              status: templatesProvider.cvTemplates.isNotEmpty
                  ? CollapsibleCardStatus.configured
                  : CollapsibleCardStatus.unconfigured,
              initiallyCollapsed: templatesProvider.cvTemplates.isEmpty,
              collapsedSummary: Row(
                children: [
                  Icon(
                    Icons.description_outlined,
                    size: 20,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      templatesProvider.cvTemplates.isEmpty
                          ? 'No CV templates yet. Import or create one to get started.'
                          : '${templatesProvider.cvTemplates.length} ${templatesProvider.cvTemplates.length == 1 ? 'template' : 'templates'} ready to use',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color:
                            theme.textTheme.bodySmall?.color?.withOpacity(0.7),
                      ),
                    ),
                  ),
                ],
              ),
              expandedContent: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (templatesProvider.cvTemplates.isEmpty)
                    _buildInnerEmptyState(
                      context,
                      'No CV templates yet',
                      'Import a CV YAML file or create a new template',
                      Icons.description_outlined,
                    )
                  else
                    ...templatesProvider.cvTemplates.map(
                      (template) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: DocumentTemplateCard(
                          name: template.name,
                          language: 'English',
                          lastModified: template.lastModified ?? DateTime.now(),
                          type: DocumentType.cv,
                          onGeneratePdf: () =>
                              _generateCvPdf(context, template),
                          onEdit: () => _editCvTemplate(context, template),
                          onDuplicate: () =>
                              _duplicateCvTemplate(context, template),
                          onDelete: () => _deleteCvTemplate(context, template),
                          onRename: () => _renameCvTemplate(context, template),
                        ),
                      ),
                    ),
                  const SizedBox(height: AppSpacing.sm),
                  AppCardActionButton(
                    label: 'New CV Template',
                    onPressed: () => _createNewCv(context),
                    icon: Icons.add,
                    isFullWidth: true,
                    isFilled: false,
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppSpacing.md),

            // Cover Letter Templates Section
            CollapsibleCard(
              cardId: 'documents_cover_letter_templates',
              title: 'Cover Letter Templates',
              subtitle:
                  '${templatesProvider.coverLetterTemplates.length} template${templatesProvider.coverLetterTemplates.length == 1 ? '' : 's'}',
              status: templatesProvider.coverLetterTemplates.isNotEmpty
                  ? CollapsibleCardStatus.configured
                  : CollapsibleCardStatus.unconfigured,
              initiallyCollapsed:
                  templatesProvider.coverLetterTemplates.isEmpty,
              collapsedSummary: Row(
                children: [
                  Icon(
                    Icons.mail_outline,
                    size: 20,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      templatesProvider.coverLetterTemplates.isEmpty
                          ? 'No cover letter templates yet. Import or create one to get started.'
                          : '${templatesProvider.coverLetterTemplates.length} ${templatesProvider.coverLetterTemplates.length == 1 ? 'template' : 'templates'} ready to use',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color:
                            theme.textTheme.bodySmall?.color?.withOpacity(0.7),
                      ),
                    ),
                  ),
                ],
              ),
              expandedContent: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (templatesProvider.coverLetterTemplates.isEmpty)
                    _buildInnerEmptyState(
                      context,
                      'No cover letter templates yet',
                      'Import a cover letter YAML file or create a new template',
                      Icons.mail_outline,
                    )
                  else
                    ...templatesProvider.coverLetterTemplates.map(
                      (template) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: DocumentTemplateCard(
                          name: template.name,
                          language: 'English',
                          lastModified: template.lastModified ?? DateTime.now(),
                          type: DocumentType.coverLetter,
                          onGeneratePdf: () =>
                              _generateCoverLetterPdf(context, template),
                          onEdit: () =>
                              _editCoverLetterTemplate(context, template),
                          onDuplicate: () =>
                              _duplicateCoverLetterTemplate(context, template),
                          onDelete: () =>
                              _deleteCoverLetterTemplate(context, template),
                          onRename: () =>
                              _renameCoverLetterTemplate(context, template),
                        ),
                      ),
                    ),
                  const SizedBox(height: AppSpacing.sm),
                  AppCardActionButton(
                    label: 'New Cover Letter Template',
                    onPressed: () => _createNewCoverLetter(context),
                    icon: Icons.add,
                    isFullWidth: true,
                    isFilled: false,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInnerEmptyState(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
      child: Center(
        child: Column(
          children: [
            Icon(
              icon,
              size: 48,
              color: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.color
                  ?.withOpacity(0.3),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // CV Template Methods
  void _generateCvPdf(BuildContext context, CvTemplate template) {
    CvTemplatePdfPreviewLauncher.openPreview(
      context: context,
      cvTemplate: template,
      templateStyle: template.templateStyle,
    );
  }

  void _editCvTemplate(BuildContext context, CvTemplate template) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CvTemplateEditorScreen(templateId: template.id),
      ),
    );
  }

  void _duplicateCvTemplate(BuildContext context, CvTemplate template) async {
    final templatesProvider = context.read<TemplatesProvider>();

    try {
      final newTemplate = await templatesProvider.createCvTemplate(
        name: '${template.name} (Copy)',
        profile: template.profile,
        skills: List<String>.from(template.skills),
        contactDetails: template.contactDetails,
      );

      await templatesProvider.updateCvTemplate(
        newTemplate.copyWith(
          languages: List.from(template.languages),
          interests: List.from(template.interests),
          experiences: List.from(template.experiences),
          education: List.from(template.education),
        ),
      );

      if (context.mounted) {
        UIUtils.showSuccess(context, '${template.name} duplicated');
      }
    } catch (e) {
      if (context.mounted) {
        UIUtils.showError(context, 'Error duplicating template: $e');
      }
    }
  }

  void _renameCvTemplate(BuildContext context, CvTemplate template) async {
    final name = await DialogUtils.showTextInput(
      context,
      title: 'Rename Template',
      initialValue: template.name,
      hintText: 'Enter new name',
      confirmLabel: 'Rename',
    );

    if (name != null &&
        name.isNotEmpty &&
        name != template.name &&
        context.mounted) {
      final templatesProvider = context.read<TemplatesProvider>();
      try {
        await templatesProvider.updateCvTemplate(template.copyWith(name: name));
        if (context.mounted) {
          UIUtils.showSuccess(context, 'Template renamed to "$name"');
        }
      } catch (e) {
        if (context.mounted) {
          UIUtils.showError(context, 'Error renaming template: $e');
        }
      }
    }
  }

  void _deleteCvTemplate(BuildContext context, CvTemplate template) async {
    final confirmed = await DialogUtils.showDeleteConfirmation(
      context,
      title: 'Delete CV Template',
      message:
          'Are you sure you want to delete "${template.name}"?\n\nThis action cannot be undone.',
    );

    if (confirmed && context.mounted) {
      final templatesProvider = context.read<TemplatesProvider>();

      try {
        await templatesProvider.deleteCvTemplate(template.id);
        if (context.mounted) {
          UIUtils.showSuccess(context, '${template.name} deleted');
        }
      } catch (e) {
        if (context.mounted) {
          UIUtils.showError(context, 'Error deleting template: $e');
        }
      }
    }
  }

  void _createNewCv(BuildContext context) async {
    final templatesProvider = context.read<TemplatesProvider>();

    try {
      await templatesProvider.createCvTemplate(
        name: 'New CV Template',
        profile: 'Add your professional summary here...',
      );

      if (context.mounted) {
        UIUtils.showSuccess(context, 'New CV template created');
      }
    } catch (e) {
      if (context.mounted) {
        UIUtils.showError(context, 'Error creating template: $e');
      }
    }
  }

  // Cover Letter Template Methods
  void _generateCoverLetterPdf(
      BuildContext context, CoverLetterTemplate template) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => CoverLetterTemplatePdfPreviewDialog(
          coverLetterTemplate: template,
          contactDetails: null,
          templateStyle: template.templateStyle,
        ),
      ),
    );
  }

  void _editCoverLetterTemplate(
      BuildContext context, CoverLetterTemplate template) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            CoverLetterTemplateEditorScreen(templateId: template.id),
      ),
    );
  }

  void _duplicateCoverLetterTemplate(
      BuildContext context, CoverLetterTemplate template) async {
    final templatesProvider = context.read<TemplatesProvider>();

    try {
      await templatesProvider.createCoverLetterTemplate(
        name: '${template.name} (Copy)',
        greeting: template.greeting,
        body: template.body,
        closing: template.closing,
      );

      if (context.mounted) {
        UIUtils.showSuccess(context, '${template.name} duplicated');
      }
    } catch (e) {
      if (context.mounted) {
        UIUtils.showError(context, 'Error duplicating template: $e');
      }
    }
  }

  void _renameCoverLetterTemplate(
      BuildContext context, CoverLetterTemplate template) async {
    final name = await DialogUtils.showTextInput(
      context,
      title: 'Rename Template',
      initialValue: template.name,
      hintText: 'Enter new name',
      confirmLabel: 'Rename',
    );

    if (name != null &&
        name.isNotEmpty &&
        name != template.name &&
        context.mounted) {
      final templatesProvider = context.read<TemplatesProvider>();
      try {
        await templatesProvider
            .updateCoverLetterTemplate(template.copyWith(name: name));
        if (context.mounted) {
          UIUtils.showSuccess(context, 'Template renamed to "$name"');
        }
      } catch (e) {
        if (context.mounted) {
          UIUtils.showError(context, 'Error renaming template: $e');
        }
      }
    }
  }

  void _deleteCoverLetterTemplate(
      BuildContext context, CoverLetterTemplate template) async {
    final confirmed = await DialogUtils.showDeleteConfirmation(
      context,
      title: 'Delete Cover Letter Template',
      message:
          'Are you sure you want to delete "${template.name}"?\n\nThis action cannot be undone.',
    );

    if (confirmed && context.mounted) {
      final templatesProvider = context.read<TemplatesProvider>();

      try {
        await templatesProvider.deleteCoverLetterTemplate(template.id);
        if (context.mounted) {
          UIUtils.showSuccess(context, '${template.name} deleted');
        }
      } catch (e) {
        if (context.mounted) {
          UIUtils.showError(context, 'Error deleting template: $e');
        }
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
        UIUtils.showSuccess(context, 'New cover letter template created');
      }
    } catch (e) {
      if (context.mounted) {
        UIUtils.showError(context, 'Error creating template: $e');
      }
    }
  }
}

/// Document type enum (redefined if not available elsewhere, but usually in models)
enum DocumentType {
  cv,
  coverLetter,
}
