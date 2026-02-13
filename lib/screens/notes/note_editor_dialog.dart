import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/notes_data.dart';
import '../../theme/app_theme.dart';
import '../../utils/ui_utils.dart';
import '../../localization/app_localizations.dart';

/// Dialog for creating or editing a note
class NoteEditorDialog extends StatefulWidget {
  final NoteItem? note;

  const NoteEditorDialog({super.key, this.note});

  @override
  State<NoteEditorDialog> createState() => _NoteEditorDialogState();
}

class _NoteEditorDialogState extends State<NoteEditorDialog> {
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late TextEditingController _tagsController;

  late NoteType _selectedType;
  late NotePriority _selectedPriority;
  DateTime? _dueDate;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.note?.title ?? '');
    _descriptionController =
        TextEditingController(text: widget.note?.description ?? '');
    _tagsController = TextEditingController(
      text: widget.note?.tags.join(', ') ?? '',
    );
    _selectedType = widget.note?.type ?? NoteType.todo;
    _selectedPriority = widget.note?.priority ?? NotePriority.medium;
    _dueDate = widget.note?.dueDate;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _tagsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isEdit = widget.note != null;

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimensions.cardBorderRadius),
      ),
      child: Container(
        width: 600,
        constraints: const BoxConstraints(maxHeight: 700),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withOpacity(0.05),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(AppDimensions.cardBorderRadius),
                  topRight: Radius.circular(AppDimensions.cardBorderRadius),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      isEdit ? Icons.edit_note : Icons.add_task,
                      color: theme.colorScheme.primary,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      isEdit
                          ? context.tr('edit_note_title')
                          : context.tr('create_note_title'),
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),

            // Form
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title
                    TextFormField(
                      controller: _titleController,
                      decoration: InputDecoration(
                        labelText: context.tr('note_title_label'),
                        hintText: context.tr('note_title_hint'),
                        prefixIcon: Icon(Icons.title),
                      ),
                      autofocus: !isEdit,
                    ),
                    const SizedBox(height: AppSpacing.md),

                    // Description
                    TextFormField(
                      controller: _descriptionController,
                      decoration: InputDecoration(
                        labelText: context.tr('note_description_label'),
                        hintText: context.tr('note_description_hint'),
                        prefixIcon: Icon(Icons.description_outlined),
                        alignLabelWithHint: true,
                      ),
                      maxLines: 4,
                    ),
                    const SizedBox(height: AppSpacing.md),

                    // Type and Priority
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<NoteType>(
                            value: _selectedType,
                            decoration: InputDecoration(
                              labelText: context.tr('note_type_label'),
                              prefixIcon: Icon(Icons.category_outlined),
                            ),
                            items: NoteType.values.map((type) {
                              return DropdownMenuItem(
                                value: type,
                                child: Text(context.tr(type.localizationKey)),
                              );
                            }).toList(),
                            onChanged: (value) {
                              if (value != null) {
                                setState(() => _selectedType = value);
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: DropdownButtonFormField<NotePriority>(
                            value: _selectedPriority,
                            decoration: InputDecoration(
                              labelText: context.tr('note_priority_label'),
                              prefixIcon: Icon(Icons.flag_outlined),
                            ),
                            items: NotePriority.values.map((priority) {
                              return DropdownMenuItem(
                                value: priority,
                                child: Row(
                                  children: [
                                    Container(
                                      width: 8,
                                      height: 8,
                                      decoration: BoxDecoration(
                                        color: _getPriorityColor(priority),
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(context.tr(priority.localizationKey)),
                                  ],
                                ),
                              );
                            }).toList(),
                            onChanged: (value) {
                              if (value != null) {
                                setState(() => _selectedPriority = value);
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),

                    // Due Date
                    InkWell(
                      onTap: _selectDueDate,
                      borderRadius: BorderRadius.circular(12),
                      child: InputDecorator(
                        decoration: InputDecoration(
                          labelText: context.tr('note_due_date_label'),
                          prefixIcon: Icon(Icons.calendar_today),
                          suffixIcon: Icon(Icons.arrow_drop_down),
                        ),
                        child: Text(
                          _dueDate != null
                              ? DateFormat('MMM dd, yyyy').format(_dueDate!)
                              : context.tr('no_due_date'),
                          style: theme.textTheme.bodyMedium,
                        ),
                      ),
                    ),
                    if (_dueDate != null) ...[
                      const SizedBox(height: 4),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton.icon(
                          onPressed: () => setState(() => _dueDate = null),
                          icon: const Icon(Icons.clear, size: 16),
                          label: Text(context.tr('clear_date')),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: AppSpacing.md),

                    // Tags
                    TextFormField(
                      controller: _tagsController,
                      decoration: InputDecoration(
                        labelText: context.tr('note_tags_label'),
                        hintText: context.tr('note_tags_hint'),
                        prefixIcon: Icon(Icons.label_outlined),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Actions
            Container(
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                color:
                    theme.colorScheme.surfaceContainerHighest.withOpacity(0.3),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(AppDimensions.cardBorderRadius),
                  bottomRight: Radius.circular(AppDimensions.cardBorderRadius),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(context.tr('cancel')),
                  ),
                  const SizedBox(width: 12),
                  FilledButton.icon(
                    onPressed: _saveNote,
                    icon: const Icon(Icons.check, size: 18),
                    label: Text(
                        isEdit ? context.tr('update') : context.tr('create')),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _selectDueDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _dueDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (date != null) {
      setState(() => _dueDate = date);
    }
  }

  void _saveNote() {
    final title = _titleController.text.trim();

    if (title.isEmpty) {
      UIUtils.showError(context, context.tr('please_enter_title'));
      return;
    }

    final tags = _tagsController.text
        .split(',')
        .map((tag) => tag.trim())
        .where((tag) => tag.isNotEmpty)
        .toList();

    final note = widget.note?.copyWith(
          title: title,
          description: _descriptionController.text.trim().isEmpty
              ? null
              : _descriptionController.text.trim(),
          type: _selectedType,
          priority: _selectedPriority,
          dueDate: _dueDate,
          tags: tags,
        ) ??
        NoteItem(
          title: title,
          description: _descriptionController.text.trim().isEmpty
              ? null
              : _descriptionController.text.trim(),
          type: _selectedType,
          priority: _selectedPriority,
          dueDate: _dueDate,
          tags: tags,
        );

    Navigator.of(context).pop(note);
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
}
