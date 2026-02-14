import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/notes_data.dart';
import '../theme/app_theme.dart';
import '../localization/app_localizations.dart';

/// Type-specific card for displaying notes with distinct visual styles
class NoteCard extends StatefulWidget {
  final NoteItem note;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onToggleComplete;
  final VoidCallback? onArchive;
  final VoidCallback? onUnarchive;
  final VoidCallback? onCreateApplication;
  final VoidCallback? onExport;
  final void Function(LeadStatus)? onUpdateLeadStatus;

  const NoteCard({
    super.key,
    required this.note,
    this.onEdit,
    this.onDelete,
    this.onToggleComplete,
    this.onArchive,
    this.onUnarchive,
    this.onCreateApplication,
    this.onExport,
    this.onUpdateLeadStatus,
  });

  @override
  State<NoteCard> createState() => _NoteCardState();
}

class _NoteCardState extends State<NoteCard> {
  bool _isExpanded = false;

  NoteItem get note => widget.note;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final typeColor = _getTypeColor(note.type);

    return Container(
      decoration: BoxDecoration(
        color: note.completed
            ? theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3)
            : typeColor.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: typeColor.withValues(alpha: note.completed ? 0.2 : 0.4),
          width: 2,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: widget.onEdit,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Checkbox for to-dos and reminders
                if (note.type == NoteType.todo || note.type == NoteType.reminder) ...[
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: Checkbox(
                        value: note.completed,
                        onChanged: (_) => widget.onToggleComplete?.call(),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4),
                        ),
                        side: BorderSide(
                          color: typeColor,
                          width: 2,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                ],

                // Content — type-specific
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildBadgeRow(context, theme),
                      const SizedBox(height: 6),
                      _buildTitle(theme),
                      // Lead status badge for company leads
                      if (note.type == NoteType.companyLead && note.leadStatus != null) ...[
                        const SizedBox(height: 6),
                        _buildLeadStatusBadge(context, theme),
                      ],
                      ..._buildTypeSpecificContent(context, theme),
                      _buildFooter(context, theme),
                    ],
                  ),
                ),

                // Actions menu
                const SizedBox(width: 8),
                _buildPopupMenu(context, theme),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Lead Status Badge ─────────────────────────────────────────────────

  Widget _buildLeadStatusBadge(BuildContext context, ThemeData theme) {
    if (note.leadStatus == null) return const SizedBox.shrink();

    final status = note.leadStatus!;
    final Color statusColor;

    switch (status) {
      case LeadStatus.researching:
        statusColor = Colors.blue;
        break;
      case LeadStatus.contacted:
        statusColor = Colors.orange;
        break;
      case LeadStatus.applied:
        statusColor = Colors.purple;
        break;
      case LeadStatus.interviewing:
        statusColor = AppColors.statusApplied;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: statusColor.withOpacity(0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            status.icon,
            style: const TextStyle(fontSize: 12),
          ),
          const SizedBox(width: 6),
          Text(
            context.tr(status.localizationKey),
            style: theme.textTheme.labelSmall?.copyWith(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: statusColor,
            ),
          ),
        ],
      ),
    );
  }

  // ── Badge Row (type + priority) ───────────────────────────────────────

  Widget _buildBadgeRow(BuildContext context, ThemeData theme) {
    final typeColor = _getTypeColor(note.type);

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: typeColor.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(4),
            border: Border.all(
              color: typeColor.withValues(alpha: 0.4),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(_getTypeIcon(note.type),
                  size: 10, color: typeColor),
              const SizedBox(width: 4),
              Text(
                context.tr(note.type.localizationKey),
                style: theme.textTheme.labelSmall?.copyWith(
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
                  color: typeColor,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 6),
        Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(
            color: _getPriorityColor(note.priority),
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          context.tr(note.priority.localizationKey),
          style: theme.textTheme.labelSmall?.copyWith(
            fontSize: 9,
            color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.6),
          ),
        ),
      ],
    );
  }

  // ── Title ─────────────────────────────────────────────────────────────

  Widget _buildTitle(ThemeData theme) {
    return Text(
      note.title,
      style: theme.textTheme.titleSmall?.copyWith(
        fontWeight: FontWeight.w600,
        decoration: note.completed ? TextDecoration.lineThrough : null,
        color: note.completed
            ? theme.textTheme.bodySmall?.color?.withValues(alpha: 0.5)
            : null,
      ),
    );
  }

  // ── Type-Specific Content ─────────────────────────────────────────────

  List<Widget> _buildTypeSpecificContent(
      BuildContext context, ThemeData theme) {
    switch (note.type) {
      case NoteType.companyLead:
        return _buildCompanyLeadContent(context, theme);
      case NoteType.reminder:
        return _buildReminderContent(context, theme);
      case NoteType.generalNote:
        return _buildGeneralNoteContent(context, theme);
      case NoteType.todo:
        return _buildTodoContent(context, theme);
    }
  }

  List<Widget> _buildTodoContent(BuildContext context, ThemeData theme) {
    final items = <Widget>[];

    // Countdown chip for due dates
    if (note.dueDate != null) {
      items.add(const SizedBox(height: 6));
      if (note.completed && note.completedAt != null) {
        items.add(_buildCompletedContextChip(context, theme));
      } else {
        items.add(_buildCountdownChip(context, theme));
      }
    }

    if (note.description != null && note.description!.isNotEmpty) {
      items.add(const SizedBox(height: 4));
      items.add(Text(
        note.description!,
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.7),
          fontSize: 12,
        ),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ));
    }

    return items;
  }

  List<Widget> _buildCompanyLeadContent(
      BuildContext context, ThemeData theme) {
    final items = <Widget>[];

    // Structured company info grid
    items.add(const SizedBox(height: 8));
    items.add(Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.purple.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Colors.purple.withValues(alpha: 0.15),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (note.location != null && note.location!.isNotEmpty)
            _buildInfoRow(
                theme, Icons.location_on, note.location!, Colors.purple),
          if (note.url != null && note.url!.isNotEmpty) ...[
            if (note.location != null && note.location!.isNotEmpty)
              const SizedBox(height: 6),
            _buildTappableInfoRow(
              theme,
              Icons.link,
              note.url!,
              Colors.purple,
              onTap: () => _openUrl(note.url!),
            ),
          ],
          if (note.contactPerson != null && note.contactPerson!.isNotEmpty) ...[
            if ((note.location != null && note.location!.isNotEmpty) ||
                (note.url != null && note.url!.isNotEmpty))
              const SizedBox(height: 6),
            _buildInfoRow(
                theme, Icons.person, note.contactPerson!, Colors.purple),
          ],
          if (note.contactEmail != null && note.contactEmail!.isNotEmpty) ...[
            if ((note.location != null && note.location!.isNotEmpty) ||
                (note.url != null && note.url!.isNotEmpty) ||
                (note.contactPerson != null && note.contactPerson!.isNotEmpty))
              const SizedBox(height: 6),
            _buildTappableInfoRow(
              theme,
              Icons.email,
              note.contactEmail!,
              Colors.purple,
              onTap: () => _openUrl('mailto:${note.contactEmail!}'),
            ),
          ],
        ],
      ),
    ));

    if (note.description != null && note.description!.isNotEmpty) {
      items.add(const SizedBox(height: 8));
      items.add(Text(
        note.description!,
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.7),
          fontSize: 12,
        ),
        maxLines: 3,
        overflow: TextOverflow.ellipsis,
      ));
    }

    return items;
  }

  Widget _buildInfoRow(
      ThemeData theme, IconData icon, String text, Color color) {
    return Row(
      children: [
        Icon(icon, size: 14, color: color.withValues(alpha: 0.7)),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: theme.textTheme.bodySmall?.copyWith(
              fontSize: 12,
              color: theme.textTheme.bodyMedium?.color,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildTappableInfoRow(
    ThemeData theme,
    IconData icon,
    String text,
    Color color, {
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: Row(
          children: [
            Icon(icon, size: 14, color: color.withValues(alpha: 0.7)),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                text,
                style: theme.textTheme.bodySmall?.copyWith(
                  fontSize: 12,
                  color: color,
                  decoration: TextDecoration.underline,
                  decorationColor: color.withValues(alpha: 0.4),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildReminderContent(BuildContext context, ThemeData theme) {
    final items = <Widget>[];

    // Calendar-style date display for reminders
    if (note.dueDate != null) {
      items.add(const SizedBox(height: 8));
      items.add(_buildCalendarDateDisplay(context, theme));
    }

    if (note.description != null && note.description!.isNotEmpty) {
      items.add(const SizedBox(height: 8));
      items.add(Text(
        note.description!,
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.7),
          fontSize: 12,
        ),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ));
    }

    return items;
  }

  Widget _buildCalendarDateDisplay(BuildContext context, ThemeData theme) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dueDay =
        DateTime(note.dueDate!.year, note.dueDate!.month, note.dueDate!.day);
    final diff = dueDay.difference(today).inDays;
    final isOverdue = diff < 0 && !note.completed;

    // Determine urgency color
    final Color urgencyColor;
    if (note.completed) {
      urgencyColor = AppColors.statusAccepted;
    } else if (isOverdue) {
      urgencyColor = AppColors.statusRejected;
    } else if (diff == 0) {
      urgencyColor = Colors.orange;
    } else if (diff <= 2) {
      urgencyColor = Colors.orange;
    } else if (diff <= 7) {
      urgencyColor = AppColors.statusApplied;
    } else {
      urgencyColor = AppColors.statusAccepted;
    }

    // Build countdown label
    String countdownLabel;
    if (note.completed && note.completedAt != null) {
      final completedDay = DateTime(note.completedAt!.year,
          note.completedAt!.month, note.completedAt!.day);
      final completedDiff = dueDay.difference(completedDay).inDays;
      if (completedDiff > 1) {
        countdownLabel = context.tr('note_completed_early', {'count': '$completedDiff'});
      } else if (completedDiff == 1) {
        countdownLabel = context.tr('note_completed_early_one');
      } else if (completedDiff == 0) {
        countdownLabel = context.tr('note_completed_on_time');
      } else if (completedDiff == -1) {
        countdownLabel = context.tr('note_completed_late_one');
      } else {
        countdownLabel = context.tr('note_completed_late', {'count': '${-completedDiff}'});
      }
    } else if (diff < 0) {
      countdownLabel = diff == -1
          ? context.tr('note_overdue_day')
          : context.tr('note_overdue_days', {'count': '${-diff}'});
    } else if (diff == 0) {
      countdownLabel = context.tr('note_due_today');
    } else if (diff == 1) {
      countdownLabel = context.tr('note_due_in_day');
    } else {
      countdownLabel = context.tr('note_due_in_days', {'count': '$diff'});
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: urgencyColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: urgencyColor.withValues(alpha: 0.3),
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          // Calendar icon display
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: urgencyColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  DateFormat('MMM').format(note.dueDate!).toUpperCase(),
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    color: urgencyColor,
                    letterSpacing: 0.5,
                  ),
                ),
                Text(
                  DateFormat('dd').format(note.dueDate!),
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: urgencyColor,
                    height: 1,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      note.completed
                          ? Icons.check_circle
                          : (isOverdue
                              ? Icons.warning_amber_rounded
                              : Icons.alarm),
                      size: 16,
                      color: urgencyColor,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        countdownLabel,
                        style: theme.textTheme.labelMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: urgencyColor,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  DateFormat('EEEE, MMMM d, y').format(note.dueDate!),
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontSize: 11,
                    color:
                        theme.textTheme.bodySmall?.color?.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildGeneralNoteContent(
      BuildContext context, ThemeData theme) {
    if (note.description == null || note.description!.isEmpty) return [];

    final needsExpansion = note.description!.length > 200 ||
        '\n'.allMatches(note.description!).length > 3;

    return [
      const SizedBox(height: 4),
      AnimatedCrossFade(
        duration: const Duration(milliseconds: 200),
        crossFadeState:
            _isExpanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
        firstChild: Text(
          note.description!,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.7),
            fontSize: 12,
          ),
          maxLines: 4,
          overflow: TextOverflow.ellipsis,
        ),
        secondChild: Text(
          note.description!,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.7),
            fontSize: 12,
          ),
        ),
      ),
      if (needsExpansion)
        GestureDetector(
          onTap: () => setState(() => _isExpanded = !_isExpanded),
          child: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              _isExpanded
                  ? context.tr('note_show_less')
                  : context.tr('note_show_more'),
              style: theme.textTheme.labelSmall?.copyWith(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: Colors.teal,
              ),
            ),
          ),
        ),
    ];
  }

  // ── Countdown Chip (for to-dos with due dates) ───────────────────────

  Widget _buildCountdownChip(BuildContext context, ThemeData theme) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dueDay =
        DateTime(note.dueDate!.year, note.dueDate!.month, note.dueDate!.day);
    final diff = dueDay.difference(today).inDays;
    final isOverdue = diff < 0 && !note.completed;

    String label;
    if (diff < 0) {
      label = diff == -1
          ? context.tr('note_overdue_day')
          : context.tr('note_overdue_days', {'count': '${-diff}'});
    } else if (diff == 0) {
      label = context.tr('note_due_today');
    } else if (diff == 1) {
      label = context.tr('note_due_in_day');
    } else {
      label = context.tr('note_due_in_days', {'count': '$diff'});
    }

    // Graduated urgency colors
    final Color chipColor;
    if (isOverdue) {
      chipColor = AppColors.statusRejected;
    } else if (diff <= 0) {
      chipColor = Colors.orange;
    } else if (diff <= 2) {
      chipColor = Colors.orange;
    } else if (diff <= 7) {
      chipColor = AppColors.statusApplied;
    } else {
      chipColor = AppColors.statusAccepted;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: chipColor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: chipColor.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isOverdue ? Icons.warning_amber_rounded : Icons.alarm,
            size: 12,
            color: chipColor,
          ),
          const SizedBox(width: 4),
          Text(
            '${DateFormat('MMM dd').format(note.dueDate!)} · $label',
            style: theme.textTheme.labelSmall?.copyWith(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: chipColor,
            ),
          ),
        ],
      ),
    );
  }

  // ── Completed Context Chip (shows how timely the completion was) ─────

  Widget _buildCompletedContextChip(BuildContext context, ThemeData theme) {
    final completedDay = DateTime(
        note.completedAt!.year, note.completedAt!.month, note.completedAt!.day);
    final dueDay =
        DateTime(note.dueDate!.year, note.dueDate!.month, note.dueDate!.day);
    final diff = dueDay.difference(completedDay).inDays;

    String label;
    Color chipColor;
    if (diff > 1) {
      label = context.tr('note_completed_early', {'count': '$diff'});
      chipColor = AppColors.statusAccepted;
    } else if (diff == 1) {
      label = context.tr('note_completed_early_one');
      chipColor = AppColors.statusAccepted;
    } else if (diff == 0) {
      label = context.tr('note_completed_on_time');
      chipColor = AppColors.statusApplied;
    } else if (diff == -1) {
      label = context.tr('note_completed_late_one');
      chipColor = Colors.orange;
    } else {
      label = context.tr('note_completed_late', {'count': '${-diff}'});
      chipColor = Colors.orange;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: chipColor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: chipColor.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.check_circle_outline, size: 12, color: chipColor),
          const SizedBox(width: 4),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: chipColor,
            ),
          ),
        ],
      ),
    );
  }

  // ── Footer (tags + created date) ──────────────────────────────────────

  Widget _buildFooter(BuildContext context, ThemeData theme) {
    // Show completion date for completed notes
    final showCompletedDate = note.completed && note.completedAt != null && note.type != NoteType.reminder;

    // Show created date as fallback when footer would otherwise be empty
    final showCreatedDate = !showCompletedDate && note.tags.isEmpty;

    if (!showCompletedDate && !showCreatedDate && note.tags.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Wrap(
        spacing: 6,
        runSpacing: 4,
        children: [
          if (showCompletedDate)
            _buildDateChip(
              theme,
              Icons.check_circle_outline,
              context.tr('note_completed_on', {
                'date': DateFormat('MMM dd').format(note.completedAt!),
              }),
            ),
          if (showCreatedDate)
            _buildDateChip(
              theme,
              Icons.schedule,
              context.tr('note_created_on', {
                'date': DateFormat('MMM dd').format(note.createdAt),
              }),
            ),
          ...note.tags.take(3).map((tag) => Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  tag,
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontSize: 9,
                    color: theme.colorScheme.primary,
                  ),
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildDateChip(ThemeData theme, IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 9,
            color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.6),
          ),
          const SizedBox(width: 3),
          Text(
            text,
            style: theme.textTheme.labelSmall?.copyWith(
              fontSize: 9,
              color:
                  theme.textTheme.bodySmall?.color?.withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
  }

  // ── Popup Menu ────────────────────────────────────────────────────────

  Widget _buildPopupMenu(BuildContext context, ThemeData theme) {
    return PopupMenuButton<String>(
      icon: Icon(
        Icons.more_vert,
        size: 18,
        color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.5),
      ),
      itemBuilder: (context) => [
        PopupMenuItem(
          value: 'edit',
          child: Row(
            children: [
              Icon(Icons.edit_outlined,
                  size: 16, color: theme.colorScheme.primary),
              const SizedBox(width: 8),
              Text(context.tr('edit')),
            ],
          ),
        ),
        // Lead status change
        if (note.type == NoteType.companyLead && widget.onUpdateLeadStatus != null)
          PopupMenuItem(
            value: 'change_status',
            child: Row(
              children: [
                const Icon(Icons.swap_horiz, size: 16, color: Colors.purple),
                const SizedBox(width: 8),
                Text(context.tr('change_lead_status')),
              ],
            ),
          ),
        if (note.type == NoteType.companyLead &&
            widget.onCreateApplication != null)
          PopupMenuItem(
            value: 'create_application',
            child: Row(
              children: [
                Icon(Icons.work_outline,
                    size: 16, color: AppColors.statusApplied),
                const SizedBox(width: 8),
                Text(context.tr('note_create_application')),
              ],
            ),
          ),
        if (widget.onExport != null)
          PopupMenuItem(
            value: 'export',
            child: Row(
              children: [
                Icon(Icons.download_outlined,
                    size: 16, color: Colors.teal),
                const SizedBox(width: 8),
                Text(context.tr('note_export')),
              ],
            ),
          ),
        if (widget.onArchive != null)
          PopupMenuItem(
            value: 'archive',
            child: Row(
              children: [
                const Icon(Icons.archive_outlined,
                    size: 16, color: Colors.orange),
                const SizedBox(width: 8),
                Text(context.tr('archive')),
              ],
            ),
          ),
        if (widget.onUnarchive != null)
          PopupMenuItem(
            value: 'unarchive',
            child: Row(
              children: [
                const Icon(Icons.unarchive_outlined,
                    size: 16, color: Colors.green),
                const SizedBox(width: 8),
                Text(context.tr('unarchive')),
              ],
            ),
          ),
        PopupMenuItem(
          value: 'delete',
          child: Row(
            children: [
              const Icon(Icons.delete_outlined,
                  size: 16, color: AppColors.statusRejected),
              const SizedBox(width: 8),
              Text(context.tr('delete')),
            ],
          ),
        ),
      ],
      onSelected: (value) {
        if (value == 'edit') {
          widget.onEdit?.call();
        } else if (value == 'change_status') {
          _showLeadStatusDialog(context);
        } else if (value == 'create_application') {
          widget.onCreateApplication?.call();
        } else if (value == 'export') {
          widget.onExport?.call();
        } else if (value == 'archive') {
          widget.onArchive?.call();
        } else if (value == 'unarchive') {
          widget.onUnarchive?.call();
        } else if (value == 'delete') {
          widget.onDelete?.call();
        }
      },
    );
  }

  // ── Lead Status Dialog ────────────────────────────────────────────────

  Future<void> _showLeadStatusDialog(BuildContext context) async {
    final theme = Theme.of(context);
    final currentStatus = note.leadStatus ?? LeadStatus.researching;

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.tr('change_lead_status')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: LeadStatus.values.map((status) {
            final isSelected = status == currentStatus;
            final Color statusColor;

            switch (status) {
              case LeadStatus.researching:
                statusColor = Colors.blue;
                break;
              case LeadStatus.contacted:
                statusColor = Colors.orange;
                break;
              case LeadStatus.applied:
                statusColor = Colors.purple;
                break;
              case LeadStatus.interviewing:
                statusColor = AppColors.statusApplied;
                break;
            }

            return InkWell(
              onTap: () {
                widget.onUpdateLeadStatus?.call(status);
                Navigator.of(context).pop();
              },
              borderRadius: BorderRadius.circular(8),
              child: Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isSelected
                      ? statusColor.withOpacity(0.12)
                      : theme.colorScheme.surfaceContainerHighest.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isSelected
                        ? statusColor
                        : theme.colorScheme.outline.withOpacity(0.2),
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    Text(
                      status.icon,
                      style: const TextStyle(fontSize: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        context.tr(status.localizationKey),
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                          color: isSelected ? statusColor : null,
                        ),
                      ),
                    ),
                    if (isSelected)
                      Icon(Icons.check_circle, color: statusColor, size: 20),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(context.tr('cancel')),
          ),
        ],
      ),
    );
  }

  // ── URL/Email Opening ─────────────────────────────────────────────────

  Future<void> _openUrl(String urlString) async {
    try {
      final url = urlString.startsWith('http://') ||
              urlString.startsWith('https://') ||
              urlString.startsWith('mailto:')
          ? urlString
          : 'https://$urlString';

      if (Platform.isWindows) {
        await Process.run('cmd', ['/c', 'start', url]);
      } else if (Platform.isMacOS) {
        await Process.run('open', [url]);
      } else if (Platform.isLinux) {
        await Process.run('xdg-open', [url]);
      }
    } catch (e) {
      debugPrint('Failed to open URL: $e');
    }
  }

  // ── Color/Icon Helpers ────────────────────────────────────────────────

  Color _getPriorityColor(NotePriority priority) {
    switch (priority) {
      case NotePriority.urgent:
        return AppColors.statusRejected;
      case NotePriority.high:
        return Colors.orange;
      case NotePriority.medium:
        return AppColors.statusApplied;
      case NotePriority.low:
        return AppColors.statusAccepted;
    }
  }

  Color _getTypeColor(NoteType type) {
    switch (type) {
      case NoteType.todo:
        return AppColors.statusApplied;
      case NoteType.companyLead:
        return Colors.purple;
      case NoteType.generalNote:
        return Colors.teal;
      case NoteType.reminder:
        return Colors.pink;
    }
  }

  IconData _getTypeIcon(NoteType type) {
    switch (type) {
      case NoteType.todo:
        return Icons.check_circle_outline;
      case NoteType.companyLead:
        return Icons.business;
      case NoteType.generalNote:
        return Icons.note;
      case NoteType.reminder:
        return Icons.alarm;
    }
  }
}
