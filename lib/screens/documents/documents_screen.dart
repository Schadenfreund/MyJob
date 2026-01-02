import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/cv_template.dart';
import '../../models/cover_letter_template.dart';
import '../../providers/templates_provider.dart';
import '../../widgets/collapsible_card.dart';
import '../../widgets/document_template_card.dart';
import '../../dialogs/cv_template_pdf_preview_launcher.dart';
import '../../dialogs/cover_letter_template_pdf_preview_dialog.dart';
import '../../widgets/draggable_dialog_wrapper.dart';
import '../../utils/ui_utils.dart';
import '../../utils/dialog_utils.dart';
import '../cv_template_editor/cv_template_editor_screen.dart';
import '../cover_letter_template_editor/cover_letter_template_editor_screen.dart';

/// Main Documents screen - YAML-first workflow for CV/Cover Letter creation
/// Refactored to use CollapsibleCard pattern for better organization
class DocumentsScreen extends StatelessWidget {
  const DocumentsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final templatesProvider = context.watch<TemplatesProvider>();

    return Container(
      color: theme.colorScheme.surface,
      child: SingleChildScrollView(
        padding: EdgeInsets.all(UIUtils.spacingLg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            UIUtils.buildSectionHeader(
              context,
              title: 'Documents',
              subtitle:
                  'Manage CV and Cover Letter templates • Import data in Profile',
              icon: Icons.description,
            ),
            SizedBox(height: UIUtils.spacingXl),

            // CV Templates Section - CollapsibleCard
            CollapsibleCard(
              cardDecoration: UIUtils.getCardDecoration(context),
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
                  SizedBox(width: UIUtils.spacingSm),
                  Expanded(
                    child: Text(
                      templatesProvider.cvTemplates.isEmpty
                          ? 'No CV templates yet. Import or create one to get started.'
                          : '${templatesProvider.cvTemplates.length} ${templatesProvider.cvTemplates.length == 1 ? 'template' : 'templates'} ready to use',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.textTheme.bodySmall?.color
                            ?.withValues(alpha: 0.7),
                      ),
                    ),
                  ),
                ],
              ),
              expandedContent: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Template Cards
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
                        ),
                      ),
                    ),

                  // Add New Button
                  SizedBox(height: UIUtils.spacingSm),
                  UIUtils.buildOutlinedButton(
                    label: 'New CV Template',
                    onPressed: () => _createNewCv(context),
                    icon: Icons.add,
                    fullWidth: true,
                  ),
                ],
              ),
            ),

            SizedBox(height: UIUtils.spacingMd),

            // Cover Letter Templates Section - CollapsibleCard
            CollapsibleCard(
              cardDecoration: UIUtils.getCardDecoration(context),
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
                  SizedBox(width: UIUtils.spacingSm),
                  Expanded(
                    child: Text(
                      templatesProvider.coverLetterTemplates.isEmpty
                          ? 'No cover letter templates yet. Import or create one to get started.'
                          : '${templatesProvider.coverLetterTemplates.length} ${templatesProvider.coverLetterTemplates.length == 1 ? 'template' : 'templates'} ready to use',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.textTheme.bodySmall?.color
                            ?.withValues(alpha: 0.7),
                      ),
                    ),
                  ),
                ],
              ),
              expandedContent: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Template Cards
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
                        ),
                      ),
                    ),

                  // Add New Button
                  SizedBox(height: UIUtils.spacingSm),
                  UIUtils.buildOutlinedButton(
                    label: 'New Cover Letter Template',
                    onPressed: () => _createNewCoverLetter(context),
                    icon: Icons.add,
                    fullWidth: true,
                  ),
                ],
              ),
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
    return UIUtils.buildEmptyState(
      context,
      icon: icon,
      title: title,
      message: subtitle,
    );
  }

  // CV Template Methods
  /// STREAMLINED UX: Direct preview with integrated style selector
  /// Eliminates redundant style picker dialog - users can now change styles
  /// in real-time within the preview dialog
  /// Opens a floating window that can exist outside the main app
  void _generateCvPdf(BuildContext context, CvTemplate template) {
    CvTemplatePdfPreviewLauncher.openPreview(
      context: context,
      cvTemplate: template,
      templateStyle: template.templateStyle, // Use saved style as default
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

      // Copy additional data
      await templatesProvider.updateCvTemplate(
        newTemplate.copyWith(
          languages: List.from(template.languages),
          interests: List.from(template.interests),
          experiences: List.from(template.experiences),
          education: List.from(template.education),
        ),
      );

      if (context.mounted) {
        context.showSuccessSnackBar('${template.name} duplicated');
      }
    } catch (e) {
      if (context.mounted) {
        context.showErrorSnackBar('Error duplicating template: $e');
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
          context.showSuccessSnackBar('${template.name} deleted');
        }
      } catch (e) {
        if (context.mounted) {
          context.showErrorSnackBar('Error deleting template: $e');
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
        context.showSuccessSnackBar('New CV template created');
      }
    } catch (e) {
      if (context.mounted) {
        context.showErrorSnackBar('Error creating template: $e');
      }
    }
  }

  // Cover Letter Template Methods
  /// STREAMLINED UX: Direct preview with integrated style selector
  /// Eliminates redundant style picker dialog - users can now change styles
  /// in real-time within the preview dialog
  void _generateCoverLetterPdf(
      BuildContext context, CoverLetterTemplate template) {
    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black54,
      builder: (context) => DraggableDialogWrapper(
        child: CoverLetterTemplatePdfPreviewDialog(
          coverLetterTemplate: template,
          contactDetails: null, // Could extract from template if needed
          templateStyle: template.templateStyle, // Use saved style as default
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
        context.showSuccessSnackBar('${template.name} duplicated');
      }
    } catch (e) {
      if (context.mounted) {
        context.showErrorSnackBar('Error duplicating template: $e');
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
          context.showSuccessSnackBar('${template.name} deleted');
        }
      } catch (e) {
        if (context.mounted) {
          context.showErrorSnackBar('Error deleting template: $e');
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
        context.showSuccessSnackBar('New cover letter template created');
      }
    } catch (e) {
      if (context.mounted) {
        context.showErrorSnackBar('Error creating template: $e');
      }
    }
  }
}

/// Document type enum
enum DocumentType {
  cv,
  coverLetter,
}
