import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as path;
import '../../constants/app_constants.dart';
import '../../providers/applications_provider.dart';
import '../../providers/templates_provider.dart';
import '../../widgets/status_badge.dart';
import '../../widgets/collapsible_card.dart';
import '../../utils/ui_utils.dart';
import '../../utils/dialog_utils.dart';
import '../../utils/app_date_utils.dart';
import '../../services/pdf_service.dart';
import 'application_editor_dialog.dart';

/// Applications screen - Organized with CollapsibleCard sections by status
class ApplicationsScreen extends StatelessWidget {
  const ApplicationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final applicationsProvider = context.watch<ApplicationsProvider>();

    if (applicationsProvider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    // Group applications by status
    final activeApps = applicationsProvider.applications
        .where((app) =>
            app.status == ApplicationStatus.draft ||
            app.status == ApplicationStatus.applied ||
            app.status == ApplicationStatus.interviewing)
        .toList();

    final successfulApps = applicationsProvider.applications
        .where((app) =>
            app.status == ApplicationStatus.offered ||
            app.status == ApplicationStatus.accepted)
        .toList();

    final closedApps = applicationsProvider.applications
        .where((app) =>
            app.status == ApplicationStatus.rejected ||
            app.status == ApplicationStatus.withdrawn)
        .toList();

    final hasApplications = applicationsProvider.applications.isNotEmpty;

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
              title: 'Application Tracking',
              subtitle: 'Keep track of where you sent your documents',
              icon: Icons.work_outline,
              action: UIUtils.buildPrimaryButton(
                label: 'Add Application',
                onPressed: () => _showAddDialog(context),
                icon: Icons.add,
              ),
            ),
            SizedBox(height: UIUtils.spacingXl),

            // Empty state
            if (!hasApplications)
              UIUtils.buildEmptyState(
                context,
                icon: Icons.work_outline,
                title: 'No applications yet',
                message: 'Track where you send your CV and cover letters',
                action: UIUtils.buildPrimaryButton(
                  label: 'Add Your First Application',
                  onPressed: () => _showAddDialog(context),
                  icon: Icons.add,
                ),
              )
            else ...[
              // Active Applications Section
              CollapsibleCard(
                cardDecoration: UIUtils.getCardDecoration(context),
                title: 'Active Applications',
                subtitle:
                    '${activeApps.length} ${activeApps.length == 1 ? 'application' : 'applications'}',
                status: activeApps.isNotEmpty
                    ? CollapsibleCardStatus.configured
                    : CollapsibleCardStatus.unconfigured,
                initiallyCollapsed: activeApps.isEmpty,
                collapsedSummary: Row(
                  children: [
                    Icon(
                      Icons.pending_actions,
                      size: 20,
                      color: theme.colorScheme.primary,
                    ),
                    SizedBox(width: UIUtils.spacingSm),
                    Expanded(
                      child: Text(
                        activeApps.isEmpty
                            ? 'No active applications'
                            : '${activeApps.length} ${activeApps.length == 1 ? 'application' : 'applications'} in progress',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.textTheme.bodySmall?.color
                              ?.withValues(alpha: 0.7),
                        ),
                      ),
                    ),
                  ],
                ),
                expandedContent: activeApps.isEmpty
                    ? Padding(
                        padding: EdgeInsets.symmetric(
                          vertical: UIUtils.spacingMd,
                        ),
                        child: Text(
                          'Applications with status Draft, Applied, or Interviewing will appear here',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.textTheme.bodySmall?.color
                                ?.withValues(alpha: 0.6),
                          ),
                        ),
                      )
                    : Column(
                        children: activeApps
                            .map((app) => Padding(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: _ApplicationCard(
                                    application: app,
                                    onEdit: () => _showEditDialog(context, app),
                                    onDelete: () =>
                                        _deleteApplication(context, app.id),
                                  ),
                                ))
                            .toList(),
                      ),
              ),
              SizedBox(height: UIUtils.spacingMd),

              // Successful Applications Section
              CollapsibleCard(
                cardDecoration: UIUtils.getCardDecoration(context),
                title: 'Successful',
                subtitle:
                    '${successfulApps.length} ${successfulApps.length == 1 ? 'application' : 'applications'}',
                status: successfulApps.isNotEmpty
                    ? CollapsibleCardStatus.configured
                    : CollapsibleCardStatus.unconfigured,
                initiallyCollapsed: successfulApps.isEmpty,
                collapsedSummary: Row(
                  children: [
                    Icon(
                      Icons.check_circle_outline,
                      size: 20,
                      color: Colors.green,
                    ),
                    SizedBox(width: UIUtils.spacingSm),
                    Expanded(
                      child: Text(
                        successfulApps.isEmpty
                            ? 'No offers yet'
                            : '${successfulApps.length} ${successfulApps.length == 1 ? 'offer' : 'offers'} received',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.textTheme.bodySmall?.color
                              ?.withValues(alpha: 0.7),
                        ),
                      ),
                    ),
                  ],
                ),
                expandedContent: successfulApps.isEmpty
                    ? Padding(
                        padding: EdgeInsets.symmetric(
                          vertical: UIUtils.spacingMd,
                        ),
                        child: Text(
                          'Applications with status Offered or Accepted will appear here',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.textTheme.bodySmall?.color
                                ?.withValues(alpha: 0.6),
                          ),
                        ),
                      )
                    : Column(
                        children: successfulApps
                            .map((app) => Padding(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: _ApplicationCard(
                                    application: app,
                                    onEdit: () => _showEditDialog(context, app),
                                    onDelete: () =>
                                        _deleteApplication(context, app.id),
                                  ),
                                ))
                            .toList(),
                      ),
              ),
              SizedBox(height: UIUtils.spacingMd),

              // Closed Applications Section
              CollapsibleCard(
                cardDecoration: UIUtils.getCardDecoration(context),
                title: 'Closed',
                subtitle:
                    '${closedApps.length} ${closedApps.length == 1 ? 'application' : 'applications'}',
                status: closedApps.isNotEmpty
                    ? CollapsibleCardStatus.needsAttention
                    : CollapsibleCardStatus.unconfigured,
                initiallyCollapsed: true, // Collapsed by default
                collapsedSummary: Row(
                  children: [
                    Icon(
                      Icons.archive_outlined,
                      size: 20,
                      color: theme.colorScheme.primary,
                    ),
                    SizedBox(width: UIUtils.spacingSm),
                    Expanded(
                      child: Text(
                        closedApps.isEmpty
                            ? 'No closed applications'
                            : '${closedApps.length} ${closedApps.length == 1 ? 'application' : 'applications'} archived',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.textTheme.bodySmall?.color
                              ?.withValues(alpha: 0.7),
                        ),
                      ),
                    ),
                  ],
                ),
                expandedContent: closedApps.isEmpty
                    ? Padding(
                        padding: EdgeInsets.symmetric(
                          vertical: UIUtils.spacingMd,
                        ),
                        child: Text(
                          'Applications with status Rejected or Withdrawn will appear here',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.textTheme.bodySmall?.color
                                ?.withValues(alpha: 0.6),
                          ),
                        ),
                      )
                    : Column(
                        children: closedApps
                            .map((app) => Padding(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: _ApplicationCard(
                                    application: app,
                                    onEdit: () => _showEditDialog(context, app),
                                    onDelete: () =>
                                        _deleteApplication(context, app.id),
                                  ),
                                ))
                            .toList(),
                      ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showAddDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const ApplicationEditorDialog(),
    );
  }

  void _showEditDialog(BuildContext context, dynamic application) {
    showDialog(
      context: context,
      builder: (context) =>
          ApplicationEditorDialog(applicationId: application.id),
    );
  }

  Future<void> _deleteApplication(BuildContext context, String id) async {
    final confirmed = await DialogUtils.showDeleteConfirmation(
      context,
      title: 'Delete Application',
      message:
          'Are you sure you want to delete this application?\n\nThis action cannot be undone.',
    );

    if (confirmed && context.mounted) {
      await context.read<ApplicationsProvider>().deleteApplication(id);
      if (context.mounted) {
        context.showSuccessSnackBar('Application deleted');
      }
    }
  }
}

/// Simplified application card
class _ApplicationCard extends StatefulWidget {
  const _ApplicationCard({
    required this.application,
    required this.onEdit,
    required this.onDelete,
  });

  final dynamic application;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  State<_ApplicationCard> createState() => _ApplicationCardState();
}

class _ApplicationCardState extends State<_ApplicationCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final templatesProvider = context.watch<TemplatesProvider>();

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _isHovered
                ? theme.colorScheme.primary.withValues(alpha: 0.3)
                : theme.dividerColor.withValues(alpha: 0.3),
            width: 1,
          ),
          boxShadow: _isHovered
              ? [
                  BoxShadow(
                    color: theme.colorScheme.primary.withValues(alpha: 0.05),
                    blurRadius: 12,
                    spreadRadius: 2,
                  ),
                ]
              : [],
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.application.company,
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.application.position,
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: theme.textTheme.bodySmall?.color
                                ?.withValues(alpha: 0.8),
                          ),
                        ),
                      ],
                    ),
                  ),
                  StatusBadge(status: widget.application.status),
                ],
              ),
              const SizedBox(height: 16),

              // Info row
              Wrap(
                spacing: 24,
                runSpacing: 8,
                children: [
                  if (widget.application.applicationDate != null)
                    _InfoItem(
                      icon: Icons.calendar_today,
                      label: 'Applied',
                      value: _formatDate(widget.application.applicationDate!),
                    ),
                  if (widget.application.cvInstanceId != null)
                    _InfoItem(
                      icon: Icons.description,
                      label: 'CV',
                      value: _getTemplateName(
                        templatesProvider,
                        widget.application.cvInstanceId,
                        isCV: true,
                      ),
                    ),
                  if (widget.application.coverLetterInstanceId != null)
                    _InfoItem(
                      icon: Icons.mail,
                      label: 'Cover Letter',
                      value: _getTemplateName(
                        templatesProvider,
                        widget.application.coverLetterInstanceId,
                        isCV: false,
                      ),
                    ),
                ],
              ),

              // Notes
              if (widget.application.notes != null &&
                  widget.application.notes!.isNotEmpty) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest
                        .withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    widget.application.notes!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.textTheme.bodySmall?.color
                          ?.withValues(alpha: 0.7),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],

              // Actions
              const SizedBox(height: 16),
              Row(
                children: [
                  TextButton.icon(
                    onPressed: widget.onEdit,
                    icon: const Icon(Icons.edit, size: 16),
                    label: const Text('Edit'),
                  ),
                  const SizedBox(width: 8),
                  TextButton.icon(
                    onPressed: widget.onDelete,
                    icon: const Icon(Icons.delete, size: 16),
                    label: const Text('Delete'),
                    style: TextButton.styleFrom(
                      foregroundColor: theme.colorScheme.error,
                    ),
                  ),
                  const Spacer(),
                  OutlinedButton.icon(
                    onPressed: () => _regeneratePdfs(
                        context, widget.application, templatesProvider),
                    icon: const Icon(Icons.refresh, size: 16),
                    label: const Text('Regenerate PDFs'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return AppDateUtils.formatTimeAgo(date);
  }

  String _getTemplateName(TemplatesProvider provider, String? templateId,
      {required bool isCV}) {
    if (templateId == null) return 'None';

    if (isCV) {
      final template = provider.getCvTemplateById(templateId);
      return template?.name ?? 'Unknown';
    } else {
      final template = provider.getCoverLetterTemplateById(templateId);
      return template?.name ?? 'Unknown';
    }
  }

  Future<void> _regeneratePdfs(
    BuildContext context,
    dynamic application,
    TemplatesProvider templatesProvider,
  ) async {
    try {
      // Pick directory to save PDFs
      final outputPath = await FilePicker.platform.getDirectoryPath(
        dialogTitle: 'Select folder to save PDFs',
      );

      if (outputPath == null) return;

      var generatedCount = 0;
      final errors = <String>[];

      // Generate CV PDF if instance exists
      if (application.cvInstanceId != null) {
        try {
          final cvInstance =
              templatesProvider.getCvInstanceById(application.cvInstanceId!);
          if (cvInstance != null) {
            final cvData = cvInstance.toCvData();
            final fileName =
                '${application.company}_${application.position}_CV.pdf'
                    .replaceAll(' ', '_')
                    .replaceAll(RegExp(r'[^\w\-\.]'), '');

            await PdfService.instance.generateCvToFile(
              cvData: cvData,
              outputPath: path.join(outputPath, fileName),
            );
            generatedCount++;
          } else {
            errors.add('CV instance not found');
          }
        } catch (e) {
          errors.add('CV generation failed: $e');
        }
      }

      // Generate Cover Letter PDF if instance exists
      if (application.coverLetterInstanceId != null) {
        try {
          final clInstance = templatesProvider.getCoverLetterInstanceById(
            application.coverLetterInstanceId!,
          );
          if (clInstance != null) {
            final coverLetter = clInstance.toCoverLetter();
            final fileName =
                '${application.company}_${application.position}_CoverLetter.pdf'
                    .replaceAll(' ', '_')
                    .replaceAll(RegExp(r'[^\w\-\.]'), '');

            await PdfService.instance.generateCoverLetterToFile(
              coverLetter: coverLetter,
              outputPath: path.join(outputPath, fileName),
            );
            generatedCount++;
          } else {
            errors.add('Cover letter instance not found');
          }
        } catch (e) {
          errors.add('Cover letter generation failed: $e');
        }
      }

      if (context.mounted) {
        if (generatedCount > 0) {
          final message =
              'Generated $generatedCount PDF${generatedCount > 1 ? 's' : ''} successfully'
              '${errors.isNotEmpty ? ' (${errors.length} error${errors.length > 1 ? 's' : ''})' : ''}';
          if (errors.isEmpty) {
            context.showSuccessSnackBar(message);
          } else {
            context.showWarningSnackBar(message);
          }
        } else {
          context.showErrorSnackBar(
            errors.isEmpty
                ? 'No documents to regenerate'
                : 'Failed to generate PDFs: ${errors.join(', ')}',
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        context.showErrorSnackBar('Error: $e');
      }
    }
  }
}

/// Info item widget
class _InfoItem extends StatelessWidget {
  const _InfoItem({
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

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 16,
          color: theme.colorScheme.primary,
        ),
        const SizedBox(width: 6),
        Text(
          '$label: ',
          style: theme.textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.w600,
            fontSize: 12,
          ),
        ),
        Text(
          value,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.7),
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}
