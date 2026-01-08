import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/master_profile.dart';
import '../constants/ui_constants.dart';

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
        const SnackBar(content: Text('Please select a start date')),
      );
      return;
    }

    // Validate end date is not before start date
    if (!_isCurrentlyStudying && _endDate != null) {
      if (_endDate!.isBefore(_startDate!)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('End date cannot be before start date'),
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
                          ? 'Add Education'
                          : 'Edit Education',
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
                        decoration: const InputDecoration(
                          labelText: 'Degree *',
                          hintText: 'e.g. Bachelor of Science',
                          prefixIcon: Icon(Icons.school_outlined),
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) =>
                            value?.trim().isEmpty ?? true ? 'Required' : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _fieldOfStudyController,
                        decoration: const InputDecoration(
                          labelText: 'Field of Study *',
                          hintText: 'e.g. Computer Science',
                          prefixIcon: Icon(Icons.book_outlined),
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) =>
                            value?.trim().isEmpty ?? true ? 'Required' : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _institutionController,
                        decoration: const InputDecoration(
                          labelText: 'Institution *',
                          hintText: 'e.g. Stanford University',
                          prefixIcon: Icon(Icons.account_balance_outlined),
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) =>
                            value?.trim().isEmpty ?? true ? 'Required' : null,
                      ),
                      const SizedBox(height: 24),
                      Text('Study Period', style: theme.textTheme.titleSmall),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: _pickStartDate,
                              icon: const Icon(Icons.calendar_today),
                              label: Text(_startDate == null
                                  ? 'Start Date *'
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
                                  ? 'Present'
                                  : _endDate == null
                                      ? 'End Date'
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
                        title: const Text('I am currently studying here'),
                        contentPadding: EdgeInsets.zero,
                      ),
                      const SizedBox(height: 24),
                      TextFormField(
                        controller: _gradeController,
                        decoration: const InputDecoration(
                          labelText: 'Grade/GPA (Optional)',
                          hintText: 'e.g. 3.8/4.0 or First Class Honours',
                          prefixIcon: Icon(Icons.grade_outlined),
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _descriptionController,
                        maxLines: 4,
                        decoration: const InputDecoration(
                          labelText: 'Description (Optional)',
                          hintText:
                              'Relevant coursework, achievements, honors, etc.',
                          prefixIcon: Icon(Icons.description_outlined),
                          border: OutlineInputBorder(),
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
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 12),
                  FilledButton.icon(
                    onPressed: _save,
                    icon: const Icon(Icons.check, size: 18),
                    label: const Text('Save'),
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
