import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/master_profile.dart';
import '../localization/app_localizations.dart';

/// Dialog for adding or editing education entries
class EducationEditDialog extends StatefulWidget {
  const EducationEditDialog({
    this.education,
    super.key,
  });

  final Education? education;

  @override
  State<EducationEditDialog> createState() => _EducationEditDialogState();
}

class _EducationEditDialogState extends State<EducationEditDialog> {
  final _formKey = GlobalKey<FormState>();
  final _degreeController = TextEditingController();
  final _institutionController = TextEditingController();
  final _fieldOfStudyController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _gradeController = TextEditingController();

  DateTime? _startDate;
  DateTime? _endDate;
  bool _isCurrentlyStudying = false;

  @override
  void initState() {
    super.initState();

    if (widget.education != null) {
      _degreeController.text = widget.education!.degree;
      _institutionController.text = widget.education!.institution;
      _fieldOfStudyController.text = widget.education!.fieldOfStudy;
      _startDate = widget.education!.startDate;
      _endDate = widget.education!.endDate;
      _isCurrentlyStudying = widget.education!.isCurrent;
      _descriptionController.text = widget.education!.description ?? '';
      _gradeController.text = widget.education!.grade ?? '';
    }
  }

  @override
  void dispose() {
    _degreeController.dispose();
    _institutionController.dispose();
    _fieldOfStudyController.dispose();
    _descriptionController.dispose();
    _gradeController.dispose();
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    if (_startDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.tr('please_select_start_date'))),
      );
      return;
    }

    // Validate end date is not before start date
    if (!_isCurrentlyStudying && _endDate != null) {
      if (_endDate!.isBefore(_startDate!)) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.tr('end_date_before_start')),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
    }

    final education = Education(
      id: widget.education?.id ?? DateTime.now().toIso8601String(),
      degree: _degreeController.text.trim(),
      institution: _institutionController.text.trim(),
      fieldOfStudy: _fieldOfStudyController.text.trim(),
      startDate: _startDate!,
      endDate: _isCurrentlyStudying ? null : _endDate,
      isCurrent: _isCurrentlyStudying,
      description: _descriptionController.text.trim().isEmpty
          ? null
          : _descriptionController.text.trim(),
      grade: _gradeController.text.trim().isEmpty
          ? null
          : _gradeController.text.trim(),
    );

    Navigator.pop(context, education);
  }

  Future<void> _pickStartDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _startDate ?? DateTime.now(),
      firstDate: DateTime(1950),
      lastDate: DateTime.now(),
    );
    if (date != null) {
      setState(() => _startDate = date);
    }
  }

  Future<void> _pickEndDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _endDate ?? DateTime.now(),
      firstDate: _startDate ?? DateTime(1950),
      lastDate: DateTime.now()
          .add(const Duration(days: 3650)), // Allow future graduation
    );
    if (date != null) {
      setState(() => _endDate = date);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateFormat = DateFormat('MMM yyyy');

    return Dialog(
      child: Container(
        width: 600,
        constraints: const BoxConstraints(maxHeight: 600),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(12),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.school_outlined,
                    color: theme.colorScheme.onPrimaryContainer,
                    size: 28,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      widget.education == null
                          ? context.tr('add_education')
                          : context.tr('edit_education'),
                      style: theme.textTheme.titleLarge?.copyWith(
                        color: theme.colorScheme.onPrimaryContainer,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                    color: theme.colorScheme.onPrimaryContainer,
                  ),
                ],
              ),
            ),

            // Form
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextFormField(
                        controller: _degreeController,
                        decoration: InputDecoration(
                          labelText: context.tr('edu_degree_label'),
                          hintText: context.tr('edu_degree_hint'),
                          prefixIcon: const Icon(Icons.school_outlined),
                          border: const OutlineInputBorder(),
                        ),
                        validator: (value) =>
                            value?.trim().isEmpty ?? true ? context.tr('required') : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _fieldOfStudyController,
                        decoration: InputDecoration(
                          labelText: context.tr('edu_field_label'),
                          hintText: context.tr('edu_field_hint'),
                          prefixIcon: const Icon(Icons.book_outlined),
                          border: const OutlineInputBorder(),
                        ),
                        validator: (value) =>
                            value?.trim().isEmpty ?? true ? context.tr('required') : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _institutionController,
                        decoration: InputDecoration(
                          labelText: context.tr('edu_institution_label'),
                          hintText: context.tr('edu_institution_hint'),
                          prefixIcon: const Icon(Icons.account_balance_outlined),
                          border: const OutlineInputBorder(),
                        ),
                        validator: (value) =>
                            value?.trim().isEmpty ?? true ? context.tr('required') : null,
                      ),
                      const SizedBox(height: 24),
                      Text(context.tr('study_period'), style: theme.textTheme.titleSmall),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: _pickStartDate,
                              icon: const Icon(Icons.calendar_today),
                              label: Text(_startDate == null
                                  ? context.tr('start_date_required')
                                  : dateFormat.format(_startDate!)),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed:
                                  _isCurrentlyStudying ? null : _pickEndDate,
                              icon: const Icon(Icons.event),
                              label: Text(_isCurrentlyStudying
                                  ? context.tr('present')
                                  : _endDate == null
                                      ? context.tr('end_date')
                                      : dateFormat.format(_endDate!)),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      CheckboxListTile(
                        value: _isCurrentlyStudying,
                        onChanged: (value) {
                          setState(() => _isCurrentlyStudying = value ?? false);
                        },
                        title: Text(context.tr('currently_studying_here')),
                        contentPadding: EdgeInsets.zero,
                      ),
                      const SizedBox(height: 24),
                      TextFormField(
                        controller: _gradeController,
                        decoration: InputDecoration(
                          labelText: context.tr('edu_grade_label'),
                          hintText: context.tr('edu_grade_hint'),
                          prefixIcon: const Icon(Icons.grade_outlined),
                          border: const OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _descriptionController,
                        maxLines: 4,
                        decoration: InputDecoration(
                          labelText: context.tr('description_optional'),
                          hintText: context.tr('edu_description_hint'),
                          prefixIcon: const Icon(Icons.description_outlined),
                          border: const OutlineInputBorder(),
                          filled: true,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Actions
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(context.tr('cancel')),
                  ),
                  const SizedBox(width: 12),
                  FilledButton.icon(
                    onPressed: _save,
                    icon: const Icon(Icons.check, size: 18),
                    label: Text(context.tr('save')),
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
