import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/user_data/work_experience.dart';

/// Dialog for adding or editing work experience
///
/// Provides a comprehensive form for all experience details.
class ExperienceEditDialog extends StatefulWidget {
  const ExperienceEditDialog({
    this.experience,
    super.key,
  });

  final WorkExperience? experience;

  @override
  State<ExperienceEditDialog> createState() => _ExperienceEditDialogState();
}

class _ExperienceEditDialogState extends State<ExperienceEditDialog> {
  final _formKey = GlobalKey<FormState>();
  final _positionController = TextEditingController();
  final _companyController = TextEditingController();
  final _locationController = TextEditingController();
  final _descriptionController = TextEditingController();

  DateTime? _startDate;
  DateTime? _endDate;
  bool _isCurrentPosition = false;
  List<String> _responsibilities = [];

  @override
  void initState() {
    super.initState();

    if (widget.experience != null) {
      _positionController.text = widget.experience!.position;
      _companyController.text = widget.experience!.company;
      _locationController.text = widget.experience!.location ?? '';
      _startDate = widget.experience!.startDate;
      _endDate = widget.experience!.endDate;
      _descriptionController.text = widget.experience!.description ?? '';
      _isCurrentPosition = widget.experience!.isCurrent;
      _responsibilities = List.from(widget.experience!.responsibilities);
    }
  }

  @override
  void dispose() {
    _positionController.dispose();
    _companyController.dispose();
    _locationController.dispose();
    _descriptionController.dispose();
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
    if (!_isCurrentPosition && _endDate != null) {
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

    final experience = WorkExperience(
      id: widget.experience?.id,
      position: _positionController.text.trim(),
      company: _companyController.text.trim(),
      location: _locationController.text.trim().isEmpty
          ? null
          : _locationController.text.trim(),
      startDate: _startDate!,
      endDate: _isCurrentPosition ? null : _endDate,
      isCurrent: _isCurrentPosition,
      description: _descriptionController.text.trim().isEmpty
          ? null
          : _descriptionController.text.trim(),
      responsibilities: _responsibilities,
    );

    Navigator.pop(context, experience);
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
      lastDate: DateTime.now(),
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
        constraints: const BoxConstraints(maxHeight: 700),
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
                    Icons.work_outline,
                    color: theme.colorScheme.onPrimaryContainer,
                    size: 28,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      widget.experience == null
                          ? 'Add Work Experience'
                          : 'Edit Work Experience',
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
                        controller: _positionController,
                        decoration: const InputDecoration(
                          labelText: 'Position *',
                          hintText: 'e.g. Senior Software Engineer',
                          prefixIcon: Icon(Icons.badge_outlined),
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) =>
                            value?.trim().isEmpty ?? true ? 'Required' : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _companyController,
                        decoration: const InputDecoration(
                          labelText: 'Company *',
                          hintText: 'e.g. Google Inc.',
                          prefixIcon: Icon(Icons.business_outlined),
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) =>
                            value?.trim().isEmpty ?? true ? 'Required' : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _locationController,
                        decoration: const InputDecoration(
                          labelText: 'Location',
                          hintText: 'e.g. San Francisco, CA',
                          prefixIcon: Icon(Icons.location_on_outlined),
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text('Employment Period',
                          style: theme.textTheme.titleSmall),
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
                                  _isCurrentPosition ? null : _pickEndDate,
                              icon: const Icon(Icons.event),
                              label: Text(_isCurrentPosition
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
                        value: _isCurrentPosition,
                        onChanged: (value) {
                          setState(() => _isCurrentPosition = value ?? false);
                        },
                        title: const Text('I currently work here'),
                        contentPadding: EdgeInsets.zero,
                      ),
                      const SizedBox(height: 24),
                      Text('Responsibilities',
                          style: theme.textTheme.titleSmall),
                      const SizedBox(height: 8),
                      Text(
                        'Add bullet points that highlight your key achievements and responsibilities',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.textTheme.bodySmall?.color
                              ?.withValues(alpha: 0.7),
                        ),
                      ),
                      const SizedBox(height: 12),
                      ..._responsibilities.asMap().entries.map((entry) {
                        final index = entry.key;
                        final responsibility = entry.value;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: theme
                                        .colorScheme.surfaceContainerHighest,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.circle,
                                        size: 6,
                                        color: theme.colorScheme.primary,
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Text(responsibility),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              IconButton(
                                icon: const Icon(Icons.edit, size: 18),
                                onPressed: () => _editResponsibility(index),
                                tooltip: 'Edit',
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete, size: 18),
                                onPressed: () => _deleteResponsibility(index),
                                tooltip: 'Delete',
                                color: theme.colorScheme.error,
                              ),
                            ],
                          ),
                        );
                      }),
                      OutlinedButton.icon(
                        onPressed: _addResponsibility,
                        icon: const Icon(Icons.add, size: 18),
                        label: const Text('Add Responsibility'),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size.fromHeight(44),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text('Description (Optional)',
                          style: theme.textTheme.titleSmall),
                      const SizedBox(height: 8),
                      Text(
                        'Additional context about this role',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.textTheme.bodySmall?.color
                              ?.withValues(alpha: 0.7),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _descriptionController,
                        maxLines: 4,
                        decoration: const InputDecoration(
                          hintText: 'Brief overview of the role and company...',
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

  Future<void> _addResponsibility() async {
    final controller = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Responsibility'),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLines: 3,
          decoration: const InputDecoration(
            hintText:
                'e.g. Led development of new feature that increased revenue by 25%',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final text = controller.text.trim();
              if (text.isNotEmpty) {
                Navigator.pop(context, text);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );

    if (result != null && result.isNotEmpty) {
      setState(() => _responsibilities.add(result));
    }
  }

  Future<void> _editResponsibility(int index) async {
    final controller = TextEditingController(text: _responsibilities[index]);
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Responsibility'),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLines: 3,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final text = controller.text.trim();
              if (text.isNotEmpty) {
                Navigator.pop(context, text);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (result != null && result.isNotEmpty) {
      setState(() => _responsibilities[index] = result);
    }
  }

  void _deleteResponsibility(int index) {
    setState(() => _responsibilities.removeAt(index));
  }
}
