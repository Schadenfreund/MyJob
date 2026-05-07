import 'package:flutter/material.dart';
import '../../../models/job_application.dart';
import '../../../constants/app_constants.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/status_chip.dart';
import '../../../utils/application_status_helper.dart';
import '../../../utils/app_date_utils.dart';
import '../../../widgets/app_card.dart';
import '../../../localization/app_localizations.dart';
import '../../../services/log_service.dart';
import '../../../utils/platform_utils.dart';
import 'status_history_dialog.dart';

/// Compact, collapsible application card for MyJob
class CompactApplicationCard extends StatefulWidget {
  const CompactApplicationCard({
    required this.application,
    required this.onEdit,
    required this.onDelete,
    required this.onEditContent,
    required this.onViewPdf,
    required this.onViewCoverLetter,
    required this.onOpenFolder,
    required this.onStatusChange,
    required this.onHistoryChanged,
    this.initiallyExpanded = false,
    this.onExpandedChanged,
    super.key,
  });

  final JobApplication application;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onEditContent;
  final VoidCallback onViewPdf;
  final VoidCallback onViewCoverLetter;
  final VoidCallback onOpenFolder;
  final Function(ApplicationStatus) onStatusChange;
  final Future<void> Function(List<StatusChange>) onHistoryChanged;
  final bool initiallyExpanded;
  final Function(bool)? onExpandedChanged;

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

  // ── Status menu ─────────────────────────────────────────────────────────────

  static const _kHistoryAction = 'history';

  void _showStatusMenu(BuildContext context) async {
    final theme = Theme.of(context);
    final RenderBox button = context.findRenderObject() as RenderBox;
    final RenderBox overlay =
        Overlay.of(context).context.findRenderObject() as RenderBox;
    final buttonPos = button.localToGlobal(Offset.zero, ancestor: overlay);

    const menuWidth = 220.0;
    final position = RelativeRect.fromLTRB(
      buttonPos.dx - (menuWidth - button.size.width),
      buttonPos.dy,
      overlay.size.width - buttonPos.dx - button.size.width,
      overlay.size.height - buttonPos.dy - button.size.height,
    );

    final result = await showMenu<Object>(
      context: context,
      position: position,
      elevation: 8,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.cardBorderRadius)),
      items: [
        // Status items
        ...ApplicationStatus.values.map((s) {
          final isSelected = s == widget.application.status;
          final color = ApplicationStatusHelper.getColor(s);
          return PopupMenuItem<Object>(
            value: s,
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: isSelected ? 0.2 : 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: isSelected
                        ? Border.all(color: color, width: 2)
                        : null,
                  ),
                  child: Icon(ApplicationStatusHelper.getIcon(s),
                      size: 16, color: color),
                ),
                const SizedBox(width: 12),
                Text(
                  ApplicationStatusHelper.getLabel(s),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight:
                        isSelected ? FontWeight.w700 : FontWeight.w500,
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
        }),
        // Divider + history entry
        const PopupMenuDivider(),
        PopupMenuItem<Object>(
          value: _kHistoryAction,
          child: Row(
            children: [
              Icon(Icons.history,
                  size: 18,
                  color: theme.colorScheme.primary.withValues(alpha: 0.8)),
              const SizedBox(width: 12),
              Text(context.tr('edit_history'),
                  style: theme.textTheme.bodyMedium),
            ],
          ),
        ),
      ],
    );

    if (!mounted) return;
    if (result is ApplicationStatus &&
        result != widget.application.status) {
      widget.onStatusChange(result);
    } else if (result == _kHistoryAction) {
      _showHistoryEditor();
    }
  }

  void _showHistoryEditor() {
    showDialog<void>(
      context: context,
      builder: (_) => StatusHistoryDialog(
        application: widget.application,
        onSave: widget.onHistoryChanged,
      ),
    );
  }

  // ── Collapsed header helpers ─────────────────────────────────────────────

  /// Single-line timeline shown in the collapsed header, e.g.
  /// "Draft: 01.01.25 | Applied: 05.01.25 | Interviewing: 10.01.25"
  String _buildTimelineSummary() {
    final app = widget.application;
    final parts = <String>[];

    void add(ApplicationStatus s, DateTime? fallback) {
      final date = app.getStatusChangeDate(s) ?? fallback;
      if (date != null) {
        parts.add(
            '${ApplicationStatusHelper.getLabel(s)}: ${AppDateUtils.formatNumeric(date)}');
      }
    }

    add(ApplicationStatus.draft,
        app.lastUpdated ?? app.getStatusChangeDate(ApplicationStatus.draft));
    add(ApplicationStatus.applied, app.applicationDate);
    add(ApplicationStatus.interviewing, null);
    add(ApplicationStatus.successful, null);
    add(ApplicationStatus.rejected, null);
    add(ApplicationStatus.noResponse, null);

    return parts.join(' · ');
  }

  /// The most relevant single date for the current status (shown with clock icon).
  (String label, DateTime date)? _currentStatusDate() {
    final app = widget.application;
    DateTime? date;
    String label;

    switch (app.status) {
      case ApplicationStatus.draft:
        label = context.tr('status_draft');
        date = app.getStatusChangeDate(ApplicationStatus.draft) ??
            app.lastUpdated;
      case ApplicationStatus.applied:
        label = context.tr('status_applied');
        date = app.getStatusChangeDate(ApplicationStatus.applied) ??
            app.applicationDate;
      case ApplicationStatus.interviewing:
        label = context.tr('status_interviewing_since');
        date = app.getStatusChangeDate(ApplicationStatus.interviewing);
      case ApplicationStatus.successful:
        label = context.tr('status_successful');
        date = app.getStatusChangeDate(ApplicationStatus.successful);
      case ApplicationStatus.rejected:
        label = context.tr('status_rejected');
        date = app.getStatusChangeDate(ApplicationStatus.rejected);
      case ApplicationStatus.noResponse:
        label = context.tr('status_no_response_since');
        date = app.getStatusChangeDate(ApplicationStatus.noResponse);
    }

    return date == null ? null : (label, date);
  }

  // ── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final statusDate = _currentStatusDate();
    final timeline = _buildTimelineSummary();

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AppCardContainer(
        padding: EdgeInsets.zero,
        useAccentBorder: _isHovered,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Collapsed header ───────────────────────────────────────────
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
                            color: theme.colorScheme.primary
                                .withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(
                                AppDimensions.inputBorderRadius),
                          ),
                          child: Icon(Icons.business,
                              color: theme.colorScheme.primary, size: 20),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        // Company + position
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(widget.application.company,
                                  style: theme.textTheme.titleMedium
                                      ?.copyWith(fontWeight: FontWeight.w700)),
                              const SizedBox(height: 2),
                              Text(
                                widget.application.position,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.textTheme.bodySmall?.color
                                      ?.withValues(alpha: 0.7),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        AppChip(
                          label: widget.application.baseLanguage.code
                              .toUpperCase(),
                          icon: Icons.language,
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        StatusChip(
                            status: widget.application.status, compact: true),
                        const SizedBox(width: 4),
                        // Quick status change
                        IconButton(
                          onPressed: () => _showStatusMenu(context),
                          icon: const Icon(Icons.swap_horiz, size: 16),
                          visualDensity: VisualDensity.compact,
                          color: theme.colorScheme.primary
                              .withValues(alpha: 0.7),
                          tooltip: context.tr('change_status_tooltip'),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          _isExpanded
                              ? Icons.expand_less
                              : Icons.expand_more,
                          color: theme.colorScheme.primary,
                          size: 20,
                        ),
                      ],
                    ),

                    // Status summary rows (always visible in collapsed state)
                    if (statusDate != null ||
                        timeline.isNotEmpty ||
                        widget.application.jobUrl?.isNotEmpty == true) ...[
                      const SizedBox(height: AppSpacing.sm),
                      AppCardStackedSummary(
                        children: [
                          if (statusDate != null)
                            Row(children: [
                              Icon(Icons.schedule_outlined,
                                  size: 12,
                                  color: theme.colorScheme.primary
                                      .withValues(alpha: 0.6)),
                              const SizedBox(width: 4),
                              Text(
                                '${statusDate.$1}: ${AppDateUtils.formatNumeric(statusDate.$2)}',
                                style: theme.textTheme.bodySmall
                                    ?.copyWith(fontSize: 10),
                              ),
                            ]),
                          if (timeline.isNotEmpty)
                            Row(children: [
                              Icon(Icons.timeline,
                                  size: 12,
                                  color: theme.colorScheme.primary
                                      .withValues(alpha: 0.6)),
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
                            ]),
                          if (widget.application.jobUrl?.isNotEmpty == true)
                            InkWell(
                              onTap: () async {
                                try {
                                  await PlatformUtils.openUrl(
                                      widget.application.jobUrl!);
                                } catch (e) {
                                  logError('Failed to open job URL',
                                      error: e, tag: 'AppCard');
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context)
                                        .showSnackBar(SnackBar(
                                      content: Text(context.tr(
                                          'could_not_open_url',
                                          {'error': e.toString()})),
                                      backgroundColor:
                                          theme.colorScheme.error,
                                    ));
                                  }
                                }
                              },
                              borderRadius: BorderRadius.circular(4),
                              child: Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 2),
                                child: Row(children: [
                                  Icon(Icons.link,
                                      size: 12,
                                      color: theme.colorScheme.primary
                                          .withValues(alpha: 0.6)),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      widget.application.jobUrl!,
                                      style: theme.textTheme.bodySmall
                                          ?.copyWith(
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
                                          .withValues(alpha: 0.6)),
                                ]),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),

            // ── Expanded content ───────────────────────────────────────────
            AnimatedCrossFade(
              firstChild: const SizedBox(width: double.infinity),
              secondChild: _ExpandedContent(
                application: widget.application,
                onShowHistoryEditor: _showHistoryEditor,
                onEditContent: widget.onEditContent,
                onViewPdf: widget.onViewPdf,
                onViewCoverLetter: widget.onViewCoverLetter,
                onOpenFolder: widget.onOpenFolder,
                onDelete: widget.onDelete,
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

// ── Expanded content widget ──────────────────────────────────────────────────

class _ExpandedContent extends StatelessWidget {
  const _ExpandedContent({
    required this.application,
    required this.onShowHistoryEditor,
    required this.onEditContent,
    required this.onViewPdf,
    required this.onViewCoverLetter,
    required this.onOpenFolder,
    required this.onDelete,
  });

  final JobApplication application;
  final VoidCallback onShowHistoryEditor;
  final VoidCallback onEditContent;
  final VoidCallback onViewPdf;
  final VoidCallback onViewCoverLetter;
  final VoidCallback onOpenFolder;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final history = application.chronologicalStatusHistory;

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Status history panel ─────────────────────────────────────────
          _StatusHistoryPanel(
            history: history,
            application: application,
            onEditHistory: onShowHistoryEditor,
          ),

          if (application.location?.isNotEmpty == true) ...[
            const SizedBox(height: AppSpacing.sm),
            AppCardInfoRow(
              label: context.tr('card_location'),
              value: application.location!,
              icon: Icons.location_on_outlined,
            ),
          ],

          if (application.notes?.isNotEmpty == true) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(context.tr('card_notes'),
                style: theme.textTheme.labelSmall
                    ?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(
              application.notes!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.textTheme.bodySmall?.color
                    ?.withValues(alpha: 0.7),
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ],

          const SizedBox(height: AppSpacing.lg),

          // ── Action buttons ───────────────────────────────────────────────
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (application.folderPath != null) ...[
                AppCardActionButton(
                  label: context.tr('card_edit_content'),
                  icon: Icons.edit_document,
                  onPressed: onEditContent,
                  isFilled: true,
                ),
                AppCardActionButton(
                  label: context.tr('card_cv'),
                  icon: Icons.picture_as_pdf_outlined,
                  onPressed: onViewPdf,
                ),
                AppCardActionButton(
                  label: context.tr('card_letter'),
                  icon: Icons.email_outlined,
                  onPressed: onViewCoverLetter,
                ),
                AppCardActionButton(
                  label: context.tr('card_folder'),
                  icon: Icons.folder_open,
                  onPressed: onOpenFolder,
                ),
              ],
              AppCardActionButton(
                label: context.tr('delete'),
                icon: Icons.delete_outline,
                onPressed: onDelete,
                color: theme.colorScheme.error,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Status history panel ─────────────────────────────────────────────────────

class _StatusHistoryPanel extends StatelessWidget {
  const _StatusHistoryPanel({
    required this.history,
    required this.application,
    required this.onEditHistory,
  });

  final List<StatusChange> history;
  final JobApplication application;
  final VoidCallback onEditHistory;

  /// Synthesise a minimal history for legacy applications that predate
  /// statusHistory tracking, so the panel is never empty.
  List<StatusChange> _effectiveHistory() {
    if (history.isNotEmpty) return history;
    final synthetic = <StatusChange>[];
    final created =
        application.applicationDate ?? application.lastUpdated;
    if (created != null) {
      synthetic.add(StatusChange(
          status: ApplicationStatus.draft,
          changedAt: created,
          notes: null));
    }
    if (application.status != ApplicationStatus.draft &&
        application.applicationDate != null) {
      synthetic.add(StatusChange(
          status: ApplicationStatus.applied,
          changedAt: application.applicationDate!,
          notes: null));
    }
    if (application.status != ApplicationStatus.draft &&
        application.status != ApplicationStatus.applied) {
      synthetic.add(StatusChange(
          status: application.status,
          changedAt: application.lastUpdated ?? DateTime.now(),
          notes: null));
    }
    return synthetic;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final entries = _effectiveHistory();
    final isLegacy = history.isEmpty && entries.isNotEmpty;

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest
            .withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
            color: theme.colorScheme.outline.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                Icon(Icons.history,
                    size: 14,
                    color: theme.colorScheme.primary.withValues(alpha: 0.8)),
                const SizedBox(width: 6),
                Text(
                  context.tr('status_history'),
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: theme.colorScheme.primary,
                  ),
                ),
                if (isLegacy) ...[
                  const SizedBox(width: 6),
                  Tooltip(
                    message: context.tr('history_legacy_tooltip'),
                    child: Icon(Icons.info_outline,
                        size: 12,
                        color: theme.colorScheme.outline
                            .withValues(alpha: 0.6)),
                  ),
                ],
                const Spacer(),
                TextButton.icon(
                  onPressed: onEditHistory,
                  icon: const Icon(Icons.edit_outlined, size: 13),
                  label: Text(context.tr('edit_history')),
                  style: TextButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    textStyle: theme.textTheme.labelSmall,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          // Entry rows
          ...entries.asMap().entries.map((e) {
            final i = e.key;
            final entry = e.value;
            final isLast = i == entries.length - 1;
            final color = ApplicationStatusHelper.getColor(entry.status);
            return _HistoryRow(
              entry: entry,
              color: color,
              isLast: isLast,
            );
          }),
          const SizedBox(height: 4),
        ],
      ),
    );
  }
}

class _HistoryRow extends StatelessWidget {
  const _HistoryRow({
    required this.entry,
    required this.color,
    required this.isLast,
  });

  final StatusChange entry;
  final Color color;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timeline dot + connector
          SizedBox(
            width: 20,
            child: Column(
              children: [
                Container(
                  width: 10,
                  height: 10,
                  margin: const EdgeInsets.only(top: 3),
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                    border: Border.all(
                        color: color.withValues(alpha: 0.3), width: 2),
                  ),
                ),
                if (!isLast)
                  Container(
                    width: 2,
                    height: 16,
                    color: theme.colorScheme.outline.withValues(alpha: 0.25),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      ApplicationStatusHelper.getLabel(entry.status),
                      style: theme.textTheme.labelSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: color,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      AppDateUtils.formatNumeric(entry.changedAt),
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontSize: 10,
                        color: theme.textTheme.bodySmall?.color
                            ?.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
                if (entry.notes?.isNotEmpty == true)
                  Text(
                    entry.notes!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontSize: 10,
                      color: theme.textTheme.bodySmall?.color
                          ?.withValues(alpha: 0.55),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
