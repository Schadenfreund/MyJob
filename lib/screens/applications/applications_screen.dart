import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/applications_provider.dart';
import '../../providers/templates_provider.dart';
import '../../widgets/status_badge.dart';
import 'application_editor_dialog.dart';

/// Simplified Applications screen - Light tracking for documents
class ApplicationsScreen extends StatelessWidget {
  const ApplicationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final applicationsProvider = context.watch<ApplicationsProvider>();

    return Container(
      color: theme.colorScheme.surface,
      child: Column(
        children: [
          // Simple header
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: theme.dividerColor.withValues(alpha: 0.3),
                ),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.work_outline,
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
                        'Application Tracking',
                        style: theme.textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Keep track of where you sent your documents',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.textTheme.bodySmall?.color
                              ?.withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () => _showAddDialog(context),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Add Application'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 14),
                  ),
                ),
              ],
            ),
          ),

          // Applications list
          Expanded(
            child: applicationsProvider.isLoading
                ? const Center(child: CircularProgressIndicator())
                : applicationsProvider.applications.isEmpty
                    ? _buildEmptyState(context)
                    : ListView.builder(
                        padding: const EdgeInsets.all(24),
                        itemCount: applicationsProvider.applications.length,
                        itemBuilder: (context, index) {
                          final application =
                              applicationsProvider.applications[index];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: _ApplicationCard(
                              application: application,
                              onEdit: () =>
                                  _showEditDialog(context, application),
                              onDelete: () =>
                                  _deleteApplication(context, application.id),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(48),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.work_outline,
              size: 80,
              color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 24),
            Text(
              'No applications yet',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Track where you send your CV and cover letters',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.6),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () => _showAddDialog(context),
              icon: const Icon(Icons.add),
              label: const Text('Add Your First Application'),
            ),
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
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Application'),
        content:
            const Text('Are you sure you want to delete this application?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      await context.read<ApplicationsProvider>().deleteApplication(id);
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
                  _InfoItem(
                    icon: Icons.calendar_today,
                    label: 'Applied',
                    value: _formatDate(widget.application.dateApplied),
                  ),
                  if (widget.application.cvTemplateId != null)
                    _InfoItem(
                      icon: Icons.description,
                      label: 'CV',
                      value: _getTemplateName(
                        templatesProvider,
                        widget.application.cvTemplateId,
                        isCV: true,
                      ),
                    ),
                  if (widget.application.coverLetterTemplateId != null)
                    _InfoItem(
                      icon: Icons.mail,
                      label: 'Cover Letter',
                      value: _getTemplateName(
                        templatesProvider,
                        widget.application.coverLetterTemplateId,
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
                    onPressed: () {
                      // TODO: Regenerate PDFs
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('PDF regeneration coming soon')),
                      );
                    },
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
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) return 'Today';
    if (difference.inDays == 1) return 'Yesterday';
    if (difference.inDays < 7) return '${difference.inDays} days ago';
    if (difference.inDays < 30) {
      return '${(difference.inDays / 7).floor()} weeks ago';
    }

    return '${date.day}/${date.month}/${date.year}';
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
