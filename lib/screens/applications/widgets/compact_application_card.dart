import 'dart:io';
import 'package:flutter/material.dart';
import '../../../models/job_application.dart';
import '../../../constants/app_constants.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/status_chip.dart';
import '../../../utils/application_status_helper.dart';
import '../../../utils/app_date_utils.dart';
import '../../../widgets/app_card.dart';
import '../../../localization/app_localizations.dart';

/// Compact, collapsible application card for MyJob
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

    const menuWidth = 200.0;
    final RelativeRect position = RelativeRect.fromLTRB(
      buttonPosition.dx - (menuWidth - button.size.width),
      buttonPosition.dy,
      overlay.size.width - buttonPosition.dx - button.size.width,
      overlay.size.height - buttonPosition.dy - button.size.height,
    );

    final status = await showMenu<ApplicationStatus>(
      context: context,
      position: position,
      elevation: 8,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.cardBorderRadius)),
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

  String _buildStatusTimeline() {
    final app = widget.application;
    final timeline = <String>[];

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

    if (draftDate != null) {
      timeline.add(
          '${context.tr('status_draft')}: ${AppDateUtils.formatNumeric(draftDate)}');
    }
    if (appliedDate != null) {
      timeline.add(
          '${context.tr('status_applied')}: ${AppDateUtils.formatNumeric(appliedDate)}');
    }
    if (interviewingDate != null) {
      timeline.add(
          '${context.tr('status_interviewing')}: ${AppDateUtils.formatNumeric(interviewingDate)}');
    }
    if (successfulDate != null) {
      timeline.add(
          '${context.tr('status_successful')}: ${AppDateUtils.formatNumeric(successfulDate)}');
    } else if (rejectedDate != null) {
      timeline.add(
          '${context.tr('status_rejected')}: ${AppDateUtils.formatNumeric(rejectedDate)}');
    } else if (noResponseDate != null) {
      timeline.add(
          '${context.tr('status_no_response')}: ${AppDateUtils.formatNumeric(noResponseDate)}');
    }

    return timeline.join(' | ');
  }

  (String label, DateTime date)? _getStatusDate() {
    final app = widget.application;
    DateTime? date;
    String label = '';

    switch (app.status) {
      case ApplicationStatus.draft:
        label = context.tr('status_draft');
        date = app.lastUpdated;
        break;
      case ApplicationStatus.applied:
        label = context.tr('status_applied');
        date = app.applicationDate ??
            app.getStatusChangeDate(ApplicationStatus.applied);
        break;
      case ApplicationStatus.interviewing:
        label = context.tr('status_interviewing_since');
        date = app.getStatusChangeDate(ApplicationStatus.interviewing);
        break;
      case ApplicationStatus.successful:
        label = context.tr('status_successful');
        date = app.getStatusChangeDate(ApplicationStatus.successful);
        break;
      case ApplicationStatus.rejected:
        label = context.tr('status_rejected');
        date = app.getStatusChangeDate(ApplicationStatus.rejected);
        break;
      case ApplicationStatus.noResponse:
        label = context.tr('status_no_response_since');
        date = app.getStatusChangeDate(ApplicationStatus.noResponse);
        break;
    }

    if (date == null) return null;
    return (label, date);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final statusDate = _getStatusDate();
    final timeline = _buildStatusTimeline();

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AppCardContainer(
        padding: EdgeInsets.zero,
        useAccentBorder: _isHovered,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            InkWell(
              onTap: () {
                setState(() => _isExpanded = !_isExpanded);
                widget.onExpandedChanged?.call(_isExpanded);
              },
              borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(AppDimensions.cardBorderRadius)),
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  children: [
                    Row(
                      children: [
                        // Company icon
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(
                                AppDimensions.inputBorderRadius),
                          ),
                          child: Icon(
                            Icons.business,
                            color: theme.colorScheme.primary,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
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
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.textTheme.bodySmall?.color
                                      ?.withOpacity(0.7),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        // Language badge
                        AppChip(
                          label: widget.application.baseLanguage.code
                              .toUpperCase(),
                          icon: Icons.language,
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        // Status chip
                        StatusChip(
                          status: widget.application.status,
                          compact: true,
                        ),
                        const SizedBox(width: 4),
                        // Quick status change button
                        IconButton(
                          onPressed: () => _showStatusMenu(context),
                          icon: const Icon(Icons.swap_horiz, size: 16),
                          visualDensity: VisualDensity.compact,
                          color: theme.colorScheme.primary.withOpacity(0.7),
                          tooltip: context.tr('change_status_tooltip'),
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

                    // Status details
                    if (statusDate != null ||
                        timeline.isNotEmpty ||
                        (widget.application.jobUrl != null &&
                            widget.application.jobUrl!.isNotEmpty)) ...[
                      const SizedBox(height: AppSpacing.sm),
                      AppCardStackedSummary(
                        children: [
                          if (statusDate != null)
                            Row(
                              children: [
                                Icon(Icons.schedule_outlined,
                                    size: 12,
                                    color: theme.colorScheme.primary
                                        .withOpacity(0.6)),
                                const SizedBox(width: 4),
                                Text(
                                  '${statusDate.$1}: ${AppDateUtils.formatNumeric(statusDate.$2)}',
                                  style: theme.textTheme.bodySmall
                                      ?.copyWith(fontSize: 10),
                                ),
                              ],
                            ),
                          if (timeline.isNotEmpty)
                            Row(
                              children: [
                                Icon(Icons.timeline,
                                    size: 12,
                                    color: theme.colorScheme.primary
                                        .withOpacity(0.6)),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    timeline,
                                    style: theme.textTheme.bodySmall?.copyWith(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w500),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          if (widget.application.jobUrl != null &&
                              widget.application.jobUrl!.isNotEmpty)
                            InkWell(
                              onTap: () async {
                                try {
                                  final urlString = widget.application.jobUrl!;
                                  // Ensure URL has a scheme
                                  final url = urlString.startsWith('http://') ||
                                          urlString.startsWith('https://')
                                      ? urlString
                                      : 'https://$urlString';

                                  // Use the same method as the support button in settings
                                  if (Platform.isWindows) {
                                    await Process.run(
                                        'cmd', ['/c', 'start', url]);
                                  } else if (Platform.isMacOS) {
                                    await Process.run('open', [url]);
                                  } else if (Platform.isLinux) {
                                    await Process.run('xdg-open', [url]);
                                  }
                                } catch (e) {
                                  debugPrint('Failed to open job URL: $e');
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(context.tr(
                                            'could_not_open_url',
                                            {'error': e.toString()})),
                                        backgroundColor:
                                            theme.colorScheme.error,
                                      ),
                                    );
                                  }
                                }
                              },
                              borderRadius: BorderRadius.circular(4),
                              child: Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 2),
                                child: Row(
                                  children: [
                                    Icon(Icons.link,
                                        size: 12,
                                        color: theme.colorScheme.primary
                                            .withOpacity(0.6)),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                        widget.application.jobUrl!,
                                        style:
                                            theme.textTheme.bodySmall?.copyWith(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w500,
                                          color: theme.colorScheme.primary,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    Icon(Icons.open_in_new,
                                        size: 10,
                                        color: theme.colorScheme.primary
                                            .withOpacity(0.6)),
                                  ],
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),

            // Expanded content
            AnimatedCrossFade(
              firstChild: const SizedBox(width: double.infinity),
              secondChild: Column(
                children: [
                  const SizedBox.shrink(),
                  Padding(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (widget.application.location != null &&
                            widget.application.location!.isNotEmpty)
                          AppCardInfoRow(
                            label: context.tr('card_location'),
                            value: widget.application.location!,
                            icon: Icons.location_on_outlined,
                          ),
                        if (widget.application.notes != null &&
                            widget.application.notes!.isNotEmpty) ...[
                          const SizedBox(height: AppSpacing.sm),
                          Text(
                            context.tr('card_notes'),
                            style: theme.textTheme.labelSmall
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            widget.application.notes!,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.textTheme.bodySmall?.color
                                  ?.withOpacity(0.7),
                            ),
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                        const SizedBox(height: AppSpacing.lg),
                        // Actions
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            if (widget.application.folderPath != null) ...[
                              AppCardActionButton(
                                label: context.tr('card_edit_content'),
                                icon: Icons.edit_document,
                                onPressed: widget.onEditContent,
                                isFilled: true,
                              ),
                              AppCardActionButton(
                                label: context.tr('card_cv'),
                                icon: Icons.picture_as_pdf_outlined,
                                onPressed: widget.onViewPdf,
                              ),
                              AppCardActionButton(
                                label: context.tr('card_letter'),
                                icon: Icons.email_outlined,
                                onPressed: widget.onViewCoverLetter,
                              ),
                              AppCardActionButton(
                                label: context.tr('card_folder'),
                                icon: Icons.folder_open,
                                onPressed: widget.onOpenFolder,
                              ),
                            ],
                            AppCardActionButton(
                              label: context.tr('delete'),
                              icon: Icons.delete_outline,
                              onPressed: widget.onDelete,
                              color: theme.colorScheme.error,
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
              duration: AppDurations.medium,
            ),
          ],
        ),
      ),
    );
  }
}
