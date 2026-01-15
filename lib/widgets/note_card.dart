import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/notes_data.dart';
import '../theme/app_theme.dart';

/// Compact card for displaying a note item
class NoteCard extends StatelessWidget {
  final NoteItem note;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onToggleComplete;
  final VoidCallback? onArchive;
  final VoidCallback? onUnarchive;

  const NoteCard({
    super.key,
    required this.note,
    this.onEdit,
    this.onDelete,
    this.onToggleComplete,
    this.onArchive,
    this.onUnarchive,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isOverdue = note.dueDate != null &&
        note.dueDate!.isBefore(DateTime.now()) &&
        !note.completed;

    return Container(
      decoration: BoxDecoration(
        color: note.completed
            ? theme.colorScheme.surfaceContainerHighest.withOpacity(0.3)
            : theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _getPriorityColor(note.priority).withOpacity(0.3),
          width: 1.5,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onEdit,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Checkbox
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: Checkbox(
                      value: note.completed,
                      onChanged: (_) => onToggleComplete?.call(),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                      side: BorderSide(
                        color: _getPriorityColor(note.priority),
                        width: 2,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          // Type badge
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: _getTypeColor(note.type).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(
                                color:
                                    _getTypeColor(note.type).withOpacity(0.3),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  _getTypeIcon(note.type),
                                  size: 10,
                                  color: _getTypeColor(note.type),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  note.type.displayName,
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w600,
                                    color: _getTypeColor(note.type),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 6),

                          // Priority indicator
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
                            note.priority.displayName,
                            style: theme.textTheme.labelSmall?.copyWith(
                              fontSize: 9,
                              color: theme.textTheme.bodySmall?.color
                                  ?.withOpacity(0.6),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),

                      // Title
                      Text(
                        note.title,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          decoration: note.completed
                              ? TextDecoration.lineThrough
                              : null,
                          color: note.completed
                              ? theme.textTheme.bodySmall?.color
                                  ?.withOpacity(0.5)
                              : null,
                        ),
                      ),

                      // Description
                      if (note.description != null &&
                          note.description!.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          note.description!,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.textTheme.bodySmall?.color
                                ?.withOpacity(0.7),
                            fontSize: 12,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],

                      // Due date and tags
                      if (note.dueDate != null || note.tags.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 6,
                          runSpacing: 4,
                          children: [
                            // Due date
                            if (note.dueDate != null)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: isOverdue
                                      ? AppColors.statusRejected
                                          .withOpacity(0.1)
                                      : theme
                                          .colorScheme.surfaceContainerHighest
                                          .withOpacity(0.5),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.calendar_today,
                                      size: 9,
                                      color: isOverdue
                                          ? AppColors.statusRejected
                                          : theme.textTheme.bodySmall?.color
                                              ?.withOpacity(0.6),
                                    ),
                                    const SizedBox(width: 3),
                                    Text(
                                      DateFormat('MMM dd')
                                          .format(note.dueDate!),
                                      style:
                                          theme.textTheme.labelSmall?.copyWith(
                                        fontSize: 9,
                                        color: isOverdue
                                            ? AppColors.statusRejected
                                            : theme.textTheme.bodySmall?.color
                                                ?.withOpacity(0.6),
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                            // Tags
                            ...note.tags.take(3).map((tag) => Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: theme.colorScheme.primary
                                        .withOpacity(0.1),
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
                      ],
                    ],
                  ),
                ),

                // Actions
                const SizedBox(width: 8),
                PopupMenuButton<String>(
                  icon: Icon(
                    Icons.more_vert,
                    size: 18,
                    color: theme.textTheme.bodySmall?.color?.withOpacity(0.5),
                  ),
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit_outlined,
                              size: 16, color: theme.colorScheme.primary),
                          const SizedBox(width: 8),
                          const Text('Edit'),
                        ],
                      ),
                    ),
                    if (onArchive != null)
                      PopupMenuItem(
                        value: 'archive',
                        child: Row(
                          children: [
                            const Icon(Icons.archive_outlined,
                                size: 16, color: Colors.orange),
                            const SizedBox(width: 8),
                            const Text('Archive'),
                          ],
                        ),
                      ),
                    if (onUnarchive != null)
                      PopupMenuItem(
                        value: 'unarchive',
                        child: Row(
                          children: [
                            const Icon(Icons.unarchive_outlined,
                                size: 16, color: Colors.green),
                            const SizedBox(width: 8),
                            const Text('Unarchive'),
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
                          const Text('Delete'),
                        ],
                      ),
                    ),
                  ],
                  onSelected: (value) {
                    if (value == 'edit') {
                      onEdit?.call();
                    } else if (value == 'archive') {
                      onArchive?.call();
                    } else if (value == 'unarchive') {
                      onUnarchive?.call();
                    } else if (value == 'delete') {
                      onDelete?.call();
                    }
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

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
        return Colors.orange;
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
