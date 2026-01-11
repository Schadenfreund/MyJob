import 'package:flutter/material.dart';
import '../../../models/job_application.dart';
import '../../../constants/app_constants.dart';
import '../../../constants/ui_constants.dart';
import '../../../widgets/status_chip.dart';
import '../../../utils/application_status_helper.dart';
import '../../../utils/app_date_utils.dart';

/// Compact, collapsible application card for prototype
class CompactApplicationCard extends StatefulWidget {
  final JobApplication application;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onEditContent;
  final VoidCallback onViewPdf;
  final VoidCallback onViewCoverLetter;
  final VoidCallback onOpenFolder;
  final Function(ApplicationStatus) onStatusChange;
  final bool initiallyExpanded;
  final Function(bool)? onExpandedChanged;

  const CompactApplicationCard({
    required this.application,
    required this.onEdit,
    required this.onDelete,
    required this.onEditContent,
    required this.onViewPdf,
    required this.onViewCoverLetter,
    required this.onOpenFolder,
    required this.onStatusChange,
    this.initiallyExpanded = false,
    this.onExpandedChanged,
    super.key,
  });

  @override
  State<CompactApplicationCard> createState() => _CompactApplicationCardState();
}

class _CompactApplicationCardState extends State<CompactApplicationCard> {
  bool _isHovered = false;
  late bool _isExpanded;

  @override
  void initState() {
    super.initState();
    _isExpanded = widget.initiallyExpanded;
  }

  void _showStatusMenu(BuildContext context) async {
    final theme = Theme.of(context);
    final RenderBox button = context.findRenderObject() as RenderBox;
    final RenderBox overlay =
        Overlay.of(context).context.findRenderObject() as RenderBox;
    final buttonPosition = button.localToGlobal(Offset.zero, ancestor: overlay);

    // Position menu to the LEFT of the button
    final RelativeRect position = RelativeRect.fromLTRB(
      buttonPosition.dx - 200, // Left side (200px width of menu)
      buttonPosition.dy,
      overlay.size.width - buttonPosition.dx,
      overlay.size.height - buttonPosition.dy - button.size.height,
    );

    final status = await showMenu<ApplicationStatus>(
      context: context,
      position: position,
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      items: ApplicationStatus.values.map((status) {
        final isSelected = status == widget.application.status;
        final color = ApplicationStatusHelper.getColor(status);

        return PopupMenuItem<ApplicationStatus>(
          value: status,
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: color.withOpacity(isSelected ? 0.2 : 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border:
                      isSelected ? Border.all(color: color, width: 2) : null,
                ),
                child: Icon(
                  ApplicationStatusHelper.getIcon(status),
                  size: 16,
                  color: color,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                ApplicationStatusHelper.getLabel(status),
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected ? color : null,
                ),
              ),
              if (isSelected) ...[
                const Spacer(),
                Icon(Icons.check, size: 16, color: color),
              ],
            ],
          ),
        );
      }).toList(),
    );

    if (status != null && status != widget.application.status) {
      widget.onStatusChange(status);
    }
  }

  /// Build status timeline showing all status changes
  String _buildStatusTimeline() {
    final app = widget.application;
    final timeline = <String>[];

    // Collect dates for each status (most recent for each)
    final draftDate =
        app.lastUpdated ?? app.getStatusChangeDate(ApplicationStatus.draft);
    final appliedDate = app.applicationDate ??
        app.getStatusChangeDate(ApplicationStatus.applied);
    final interviewingDate =
        app.getStatusChangeDate(ApplicationStatus.interviewing);
    final successfulDate =
        app.getStatusChangeDate(ApplicationStatus.successful);
    final rejectedDate = app.getStatusChangeDate(ApplicationStatus.rejected);
    final noResponseDate =
        app.getStatusChangeDate(ApplicationStatus.noResponse);

    // Build timeline in logical order
    if (draftDate != null) {
      timeline.add('Draft: ${AppDateUtils.formatNumeric(draftDate)}');
    }

    if (appliedDate != null) {
      timeline.add('Applied: ${AppDateUtils.formatNumeric(appliedDate)}');
    }

    if (interviewingDate != null) {
      timeline.add('Interviewing: ${AppDateUtils.formatNumeric(interviewingDate)}');
    }

    // Show final status (only one of these should be present)
    if (successfulDate != null) {
      timeline.add('Successful: ${AppDateUtils.formatNumeric(successfulDate)}');
    } else if (rejectedDate != null) {
      timeline.add('Rejected: ${AppDateUtils.formatNumeric(rejectedDate)}');
    } else if (noResponseDate != null) {
      timeline.add('No Response: ${AppDateUtils.formatNumeric(noResponseDate)}');
    }

    return timeline.join(' | ');
  }

  /// Get the appropriate date and label based on status
  (String label, DateTime? date)? _getStatusDate() {
    final app = widget.application;

    switch (app.status) {
      case ApplicationStatus.draft:
        // Show last updated or creation date
        if (app.lastUpdated != null) {
          return ('Draft', app.lastUpdated);
        }
        return null;

      case ApplicationStatus.applied:
        // Show application date
        if (app.applicationDate != null) {
          return ('Applied', app.applicationDate);
        }
        // Fallback to status change date
        final appliedDate = app.getStatusChangeDate(ApplicationStatus.applied);
        if (appliedDate != null) {
          return ('Applied', appliedDate);
        }
        return null;

      case ApplicationStatus.interviewing:
        // Show when interviewing status was reached
        final interviewDate =
            app.getStatusChangeDate(ApplicationStatus.interviewing);
        if (interviewDate != null) {
          return ('Interviewing since', interviewDate);
        }
        return null;

      case ApplicationStatus.successful:
        // Show when successful status was reached
        final successDate =
            app.getStatusChangeDate(ApplicationStatus.successful);
        if (successDate != null) {
          return ('Successful', successDate);
        }
        return null;

      case ApplicationStatus.rejected:
        // Show when rejected status was reached
        final rejectedDate =
            app.getStatusChangeDate(ApplicationStatus.rejected);
        if (rejectedDate != null) {
          return ('Rejected', rejectedDate);
        }
        return null;

      case ApplicationStatus.noResponse:
        // Show when no response status was reached
        final noResponseDate =
            app.getStatusChangeDate(ApplicationStatus.noResponse);
        if (noResponseDate != null) {
          return ('No Response since', noResponseDate);
        }
        // Or show application date if available
        if (app.applicationDate != null) {
          return ('Applied', app.applicationDate);
        }
        return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final statusDate = _getStatusDate();
    final timeline = _buildStatusTimeline();

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: UIConstants.getCardDecoration(context).copyWith(
          border: Border.all(
            color: _isHovered
                ? theme.colorScheme.primary.withOpacity(0.3)
                : theme.colorScheme.outline.withOpacity(0.2),
            width: 1,
          ),
          boxShadow: _isHovered
              ? [
                  BoxShadow(
                    color: theme.colorScheme.primary.withOpacity(0.1),
                    blurRadius: 12,
                    spreadRadius: 2,
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header - Always visible, clickable
            InkWell(
              onTap: () {
                setState(() => _isExpanded = !_isExpanded);
                widget.onExpandedChanged?.call(_isExpanded);
              },
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Row(
                      children: [
                        // Company icon
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primaryContainer
                                .withOpacity(0.3),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: theme.colorScheme.primary.withOpacity(0.2),
                            ),
                          ),
                          child: Icon(
                            Icons.business,
                            color: theme.colorScheme.primary,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Company and Position
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.application.company,
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                widget.application.position,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: theme.textTheme.bodySmall?.color
                                      ?.withOpacity(0.7),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Language badge
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: theme.colorScheme.primary.withOpacity(0.2),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(2),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.primary
                                      .withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(3),
                                ),
                                child: Text(
                                  widget.application.baseLanguage.flag,
                                  style: const TextStyle(fontSize: 10),
                                ),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                widget.application.baseLanguage.code
                                    .toUpperCase(),
                                style: theme.textTheme.labelSmall?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: theme.colorScheme.primary,
                                  fontSize: 10,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Status chip
                        StatusChip(
                          status: widget.application.status,
                          compact: true,
                        ),
                        const SizedBox(width: 4),
                        // Quick status change button
                        Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () => _showStatusMenu(context),
                            borderRadius: BorderRadius.circular(6),
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              child: Icon(
                                Icons.swap_horiz,
                                size: 16,
                                color:
                                    theme.colorScheme.primary.withOpacity(0.7),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        // Expand icon
                        Icon(
                          _isExpanded ? Icons.expand_less : Icons.expand_more,
                          color: theme.colorScheme.primary,
                          size: 20,
                        ),
                      ],
                    ),

                    // Status date - shown below header
                    if (statusDate != null) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            Icons.schedule_outlined,
                            size: 12,
                            color: theme.colorScheme.primary.withOpacity(0.6),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${statusDate.$1}: ${AppDateUtils.formatNumeric(statusDate.$2!)}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontSize: 11,
                              color: theme.textTheme.bodySmall?.color
                                  ?.withOpacity(0.7),
                            ),
                          ),
                        ],
                      ),
                    ],

                    // Status Timeline - shown below header
                    if (timeline.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surfaceContainerHighest
                              .withOpacity(0.3),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: theme.dividerColor.withOpacity(0.2),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.timeline,
                              size: 12,
                              color: theme.colorScheme.primary.withOpacity(0.6),
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                timeline,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  fontSize: 10,
                                  color: theme.textTheme.bodySmall?.color
                                      ?.withOpacity(0.8),
                                  fontWeight: FontWeight.w500,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),

            // Expanded content with smooth animation
            AnimatedCrossFade(
              firstChild: const SizedBox(width: double.infinity),
              secondChild: Column(
                children: [
                  Divider(
                    height: 1,
                    color: theme.dividerColor.withOpacity(0.3),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Location (if available)
                        if (widget.application.location != null &&
                            widget.application.location!.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.surfaceContainerHighest
                                  .withOpacity(0.3),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.location_on,
                                  size: 14,
                                  color: theme.colorScheme.primary,
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    widget.application.location!,
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      fontWeight: FontWeight.w500,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),

                        // Notes
                        if (widget.application.notes != null &&
                            widget.application.notes!.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.surfaceContainerHighest
                                  .withOpacity(0.3),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: theme.dividerColor.withOpacity(0.3),
                              ),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(
                                  Icons.note_outlined,
                                  size: 14,
                                  color: theme.colorScheme.primary
                                      .withOpacity(0.7),
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    widget.application.notes!,
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: theme.textTheme.bodySmall?.color
                                          ?.withOpacity(0.7),
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],

                        // Actions
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: [
                            if (widget.application.folderPath != null) ...[
                              FilledButton.icon(
                                onPressed: widget.onEditContent,
                                icon: const Icon(Icons.edit_document, size: 16),
                                label: const Text('Edit'),
                                style:
                                    UIConstants.getPrimaryButtonStyle(context),
                              ),
                              FilledButton.tonalIcon(
                                onPressed: widget.onViewPdf,
                                icon:
                                    const Icon(Icons.picture_as_pdf, size: 16),
                                label: const Text('CV'),
                                style: UIConstants.getSecondaryButtonStyle(
                                    context),
                              ),
                              FilledButton.tonalIcon(
                                onPressed: widget.onViewCoverLetter,
                                icon:
                                    const Icon(Icons.email_outlined, size: 16),
                                label: const Text('Letter'),
                                style: UIConstants.getSecondaryButtonStyle(
                                    context),
                              ),
                              OutlinedButton.icon(
                                onPressed: widget.onOpenFolder,
                                icon: const Icon(Icons.folder_open, size: 16),
                                label: const Text('Folder'),
                                style: UIConstants.getSecondaryButtonStyle(
                                    context),
                              ),
                            ],
                            OutlinedButton.icon(
                              onPressed: widget.onDelete,
                              icon: const Icon(Icons.delete_outline, size: 16),
                              label: const Text('Delete'),
                              style: ButtonStyle(
                                foregroundColor: WidgetStateProperty.all(
                                  theme.colorScheme.error,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              crossFadeState: _isExpanded
                  ? CrossFadeState.showSecond
                  : CrossFadeState.showFirst,
              duration: const Duration(milliseconds: 200),
            ),
          ],
        ),
      ),
    );
  }
}
