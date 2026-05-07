import 'package:flutter/material.dart';
import '../../../models/job_application.dart';
import '../../../constants/app_constants.dart';
import '../../../utils/app_date_utils.dart';
import '../../../utils/application_status_helper.dart';
import '../../../localization/app_localizations.dart';

/// Dialog that shows the full status history of an application and allows
/// editing / amending individual entries (date, notes) or adding new ones.
class StatusHistoryDialog extends StatefulWidget {
  const StatusHistoryDialog({
    required this.application,
    required this.onSave,
    super.key,
  });

  final JobApplication application;
  final Future<void> Function(List<StatusChange>) onSave;

  @override
  State<StatusHistoryDialog> createState() => _StatusHistoryDialogState();
}

class _StatusHistoryDialogState extends State<StatusHistoryDialog> {
  late List<StatusChange> _entries;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    // Work on a mutable copy; fall back to a synthetic draft entry for legacy
    // applications that have no statusHistory yet.
    _entries = _initialEntries();
  }

  List<StatusChange> _initialEntries() {
    if (widget.application.safeStatusHistory.isNotEmpty) {
      return [...widget.application.chronologicalStatusHistory];
    }
    // Synthesise from legacy fields so the editor is never empty.
    final created =
        widget.application.applicationDate ?? widget.application.lastUpdated;
    final synthetic = <StatusChange>[
      if (created != null)
        StatusChange(
            status: ApplicationStatus.draft, changedAt: created, notes: null),
    ];
    if (widget.application.status != ApplicationStatus.draft &&
        widget.application.applicationDate != null) {
      synthetic.add(StatusChange(
          status: ApplicationStatus.applied,
          changedAt: widget.application.applicationDate!,
          notes: null));
    }
    if (widget.application.status != ApplicationStatus.draft &&
        widget.application.status != ApplicationStatus.applied) {
      final fallback = widget.application.lastUpdated ?? DateTime.now();
      synthetic.add(StatusChange(
          status: widget.application.status,
          changedAt: fallback,
          notes: null));
    }
    return synthetic;
  }

  Future<void> _pickDate(int index) async {
    final current = _entries[index].changedAt;
    final picked = await showDatePicker(
      context: context,
      initialDate: current,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked == null) return;
    setState(() {
      _entries[index] = _entries[index].copyWith(
        changedAt: DateTime(
            picked.year, picked.month, picked.day,
            current.hour, current.minute),
      );
    });
  }

  void _editNotes(int index) async {
    final controller =
        TextEditingController(text: _entries[index].notes ?? '');
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(ctx.tr('history_notes')),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLines: 3,
          decoration: InputDecoration(
            hintText: ctx.tr('history_notes_hint'),
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(ctx.tr('cancel'))),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, controller.text),
              child: Text(ctx.tr('save_changes'))),
        ],
      ),
    );
    if (result != null) {
      setState(() {
        _entries[index] = _entries[index].copyWith(
          notes: result.trim().isEmpty ? null : result.trim(),
        );
      });
    }
  }

  void _deleteEntry(int index) {
    if (_entries.length <= 1) return; // keep at least one entry
    setState(() => _entries.removeAt(index));
  }

  Future<void> _addEntry() async {
    ApplicationStatus? chosenStatus;
    await showDialog<void>(
      context: context,
      builder: (ctx) {
        ApplicationStatus selected = ApplicationStatus.applied;
        return StatefulBuilder(builder: (ctx, setLocal) {
          return AlertDialog(
            title: Text(ctx.tr('add_history_entry')),
            content: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: ApplicationStatus.values.map((s) {
                final isSelected = s == selected;
                final color = ApplicationStatusHelper.getColor(s);
                return ChoiceChip(
                  label: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(ApplicationStatusHelper.getIcon(s),
                          size: 14,
                          color: isSelected ? color : null),
                      const SizedBox(width: 6),
                      Text(ApplicationStatusHelper.getLabel(s)),
                    ],
                  ),
                  selected: isSelected,
                  selectedColor: color.withValues(alpha: 0.15),
                  onSelected: (_) => setLocal(() => selected = s),
                );
              }).toList(),
            ),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: Text(ctx.tr('cancel'))),
              FilledButton(
                  onPressed: () {
                    chosenStatus = selected;
                    Navigator.pop(ctx);
                  },
                  child: Text(ctx.tr('add'))),
            ],
          );
        });
      },
    );
    if (chosenStatus == null || !mounted) return;
    setState(() {
      _entries.add(StatusChange(
          status: chosenStatus!, changedAt: DateTime.now(), notes: null));
      _entries.sort((a, b) => a.changedAt.compareTo(b.changedAt));
    });
  }

  Future<void> _save() async {
    setState(() => _isSaving = true);
    try {
      await widget.onSave(_entries);
      if (mounted) Navigator.pop(context);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.history, color: theme.colorScheme.primary, size: 20),
          const SizedBox(width: 8),
          Text(context.tr('status_history')),
        ],
      ),
      contentPadding: const EdgeInsets.fromLTRB(0, 16, 0, 0),
      content: SizedBox(
        width: 480,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_entries.isEmpty)
              Padding(
                padding: const EdgeInsets.all(24),
                child: Text(context.tr('no_history'),
                    style: theme.textTheme.bodySmall),
              )
            else
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 380),
                child: ListView.separated(
                  shrinkWrap: true,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: _entries.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (ctx, i) => _EntryRow(
                    entry: _entries[i],
                    canDelete: _entries.length > 1,
                    onPickDate: () => _pickDate(i),
                    onEditNotes: () => _editNotes(i),
                    onDelete: () => _deleteEntry(i),
                  ),
                ),
              ),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Row(
                children: [
                  TextButton.icon(
                    onPressed: _addEntry,
                    icon: const Icon(Icons.add, size: 16),
                    label: Text(context.tr('add_history_entry')),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed:
                        _isSaving ? null : () => Navigator.pop(context),
                    child: Text(context.tr('cancel')),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: _isSaving ? null : _save,
                    child: _isSaving
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child:
                                CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(context.tr('save_changes')),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EntryRow extends StatelessWidget {
  const _EntryRow({
    required this.entry,
    required this.canDelete,
    required this.onPickDate,
    required this.onEditNotes,
    required this.onDelete,
  });

  final StatusChange entry;
  final bool canDelete;
  final VoidCallback onPickDate;
  final VoidCallback onEditNotes;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = ApplicationStatusHelper.getColor(entry.status);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          // Status indicator
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(ApplicationStatusHelper.getIcon(entry.status),
                size: 14, color: color),
          ),
          const SizedBox(width: 10),
          // Label + notes
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(ApplicationStatusHelper.getLabel(entry.status),
                    style: theme.textTheme.labelMedium
                        ?.copyWith(fontWeight: FontWeight.w600, color: color)),
                if (entry.notes != null && entry.notes!.isNotEmpty)
                  Text(entry.notes!,
                      style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.textTheme.bodySmall?.color
                              ?.withValues(alpha: 0.6)),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          // Date button
          TextButton(
            onPressed: onPickDate,
            style: TextButton.styleFrom(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              minimumSize: Size.zero,
            ),
            child: Row(
              children: [
                Icon(Icons.calendar_today_outlined,
                    size: 12,
                    color: theme.colorScheme.primary.withValues(alpha: 0.7)),
                const SizedBox(width: 4),
                Text(AppDateUtils.formatNumeric(entry.changedAt),
                    style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.primary)),
              ],
            ),
          ),
          // Notes edit
          IconButton(
            onPressed: onEditNotes,
            icon: Icon(
              entry.notes?.isNotEmpty == true
                  ? Icons.note
                  : Icons.note_add_outlined,
              size: 16,
            ),
            tooltip: context.tr('history_notes'),
            color: theme.colorScheme.outline,
            visualDensity: VisualDensity.compact,
          ),
          // Delete
          if (canDelete)
            IconButton(
              onPressed: onDelete,
              icon: const Icon(Icons.delete_outline, size: 16),
              tooltip: context.tr('delete'),
              color: theme.colorScheme.error.withValues(alpha: 0.7),
              visualDensity: VisualDensity.compact,
            )
          else
            const SizedBox(width: 40),
        ],
      ),
    );
  }
}
