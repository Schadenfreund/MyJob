import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/cv_template.dart';
import '../../providers/templates_provider.dart';

/// CV Template Editor Screen
class CvTemplateEditorScreen extends StatefulWidget {
  const CvTemplateEditorScreen({
    required this.template,
    super.key,
  });

  final CvTemplate template;

  @override
  State<CvTemplateEditorScreen> createState() => _CvTemplateEditorScreenState();
}

class _CvTemplateEditorScreenState extends State<CvTemplateEditorScreen> {
  late TextEditingController _nameController;
  late TextEditingController _profileController;
  late List<String> _skills;
  bool _hasChanges = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.template.name);
    _profileController = TextEditingController(text: widget.template.profile);
    _skills = List.from(widget.template.skills);

    _nameController.addListener(_markChanged);
    _profileController.addListener(_markChanged);
  }

  void _markChanged() {
    if (!_hasChanges) {
      setState(() => _hasChanges = true);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _profileController.dispose();
    super.dispose();
  }

  Future<void> _saveTemplate() async {
    final provider = context.read<TemplatesProvider>();

    final updatedTemplate = CvTemplate(
      id: widget.template.id,
      name: _nameController.text.trim(),
      profile: _profileController.text.trim(),
      skills: _skills,
      contactDetails: widget.template.contactDetails,
      createdAt: widget.template.createdAt,
      lastModified: DateTime.now(),
    );

    await provider.updateCvTemplate(updatedTemplate);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Template saved successfully'),
          backgroundColor: Theme.of(context).colorScheme.primary,
        ),
      );
      Navigator.pop(context, true);
    }
  }

  void _addSkill() {
    showDialog(
      context: context,
      builder: (context) {
        final controller = TextEditingController();
        return AlertDialog(
          title: const Text('Add Skill'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(
              labelText: 'Skill name',
              hintText: 'e.g., Python, Project Management',
            ),
            autofocus: true,
            onSubmitted: (value) {
              if (value.trim().isNotEmpty) {
                setState(() {
                  _skills.add(value.trim());
                  _hasChanges = true;
                });
                Navigator.pop(context);
              }
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (controller.text.trim().isNotEmpty) {
                  setState(() {
                    _skills.add(controller.text.trim());
                    _hasChanges = true;
                  });
                  Navigator.pop(context);
                }
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }

  void _removeSkill(int index) {
    setState(() {
      _skills.removeAt(index);
      _hasChanges = true;
    });
  }

  Future<bool> _onWillPop() async {
    if (!_hasChanges) return true;

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Discard Changes?'),
        content: const Text(
          'You have unsaved changes. Are you sure you want to discard them?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Discard'),
          ),
        ],
      ),
    );

    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return PopScope(
      canPop: !_hasChanges,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final shouldPop = await _onWillPop();
        if (shouldPop && context.mounted) {
          Navigator.pop(context);
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(_nameController.text.isEmpty
              ? 'Edit Template'
              : 'Edit: ${_nameController.text}'),
          actions: [
            if (_hasChanges)
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: TextButton.icon(
                  onPressed: _saveTemplate,
                  icon: const Icon(Icons.save, size: 18),
                  label: const Text('Save'),
                  style: TextButton.styleFrom(
                    foregroundColor: theme.colorScheme.primary,
                  ),
                ),
              ),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Template Name
              Text(
                'Template Name',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(
                  hintText: 'Enter template name',
                ),
              ),
              const SizedBox(height: 24),

              // Profile Summary
              Text(
                'Profile Summary',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _profileController,
                decoration: const InputDecoration(
                  hintText: 'Enter your professional summary...',
                  alignLabelWithHint: true,
                ),
                maxLines: 5,
              ),
              const SizedBox(height: 24),

              // Skills
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Skills',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  TextButton.icon(
                    onPressed: _addSkill,
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Add Skill'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (_skills.isEmpty)
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest
                        .withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: theme.dividerColor.withValues(alpha: 0.5),
                    ),
                  ),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(
                          Icons.psychology_outlined,
                          size: 32,
                          color: theme.textTheme.bodySmall?.color
                              ?.withValues(alpha: 0.5),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'No skills added yet',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.textTheme.bodySmall?.color
                                ?.withValues(alpha: 0.6),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _skills.asMap().entries.map((entry) {
                    return Chip(
                      label: Text(entry.value),
                      deleteIcon: const Icon(Icons.close, size: 16),
                      onDeleted: () => _removeSkill(entry.key),
                      backgroundColor:
                          theme.colorScheme.primary.withValues(alpha: 0.1),
                      side: BorderSide(
                        color: theme.colorScheme.primary.withValues(alpha: 0.3),
                      ),
                    );
                  }).toList(),
                ),
              const SizedBox(height: 32),

              // Contact Details (read-only info)
              if (widget.template.contactDetails != null) ...[
                Text(
                  'Contact Details',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: theme.dividerColor),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (widget.template.contactDetails!.email != null)
                        _buildInfoRow(
                          Icons.email_outlined,
                          widget.template.contactDetails!.email!,
                          theme,
                        ),
                      if (widget.template.contactDetails!.phone != null) ...[
                        const SizedBox(height: 8),
                        _buildInfoRow(
                          Icons.phone_outlined,
                          widget.template.contactDetails!.phone!,
                          theme,
                        ),
                      ],
                      if (widget.template.contactDetails!.website != null) ...[
                        const SizedBox(height: 8),
                        _buildInfoRow(
                          Icons.language_outlined,
                          widget.template.contactDetails!.website!,
                          theme,
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
        bottomNavigationBar: _hasChanges
            ? Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  border: Border(
                    top: BorderSide(color: theme.dividerColor),
                  ),
                ),
                child: SafeArea(
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () async {
                            final shouldPop = await _onWillPop();
                            if (shouldPop && context.mounted) {
                              Navigator.pop(context);
                            }
                          },
                          child: const Text('Discard'),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton.icon(
                          onPressed: _saveTemplate,
                          icon: const Icon(Icons.save, size: 18),
                          label: const Text('Save Changes'),
                        ),
                      ),
                    ],
                  ),
                ),
              )
            : null,
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text, ThemeData theme) {
    return Row(
      children: [
        Icon(
          icon,
          size: 18,
          color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.6),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: theme.textTheme.bodyMedium,
          ),
        ),
      ],
    );
  }
}
