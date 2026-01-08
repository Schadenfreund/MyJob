import 'package:flutter/material.dart';
import '../models/user_data/language.dart';

/// Language editor with proficiency levels
///
/// Allows adding, editing, and removing languages with proficiency selection.
class LanguageEditor extends StatelessWidget {
  const LanguageEditor({
    required this.languages,
    required this.onChanged,
    super.key,
  });

  final List<Language> languages;
  final ValueChanged<List<Language>> onChanged;

  void _addLanguage(BuildContext context) async {
    final result = await showDialog<Language>(
      context: context,
      builder: (context) => const _LanguageEditDialog(),
    );

    if (result != null) {
      onChanged([...languages, result]);
    }
  }

  void _editLanguage(BuildContext context, int index) async {
    final result = await showDialog<Language>(
      context: context,
      builder: (context) => _LanguageEditDialog(language: languages[index]),
    );

    if (result != null) {
      final updated = List<Language>.from(languages);
      updated[index] = result;
      onChanged(updated);
    }
  }

  void _deleteLanguage(BuildContext context, int index) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Language'),
        content: Text('Remove ${languages[index].name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final updated = List<Language>.from(languages);
      updated.removeAt(index);
      onChanged(updated);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '${languages.length} ${languages.length == 1 ? 'language' : 'languages'}',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
            FilledButton.icon(
              onPressed: () => _addLanguage(context),
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Add Language'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (languages.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                children: [
                  Icon(
                    Icons.language_outlined,
                    size: 64,
                    color: theme.colorScheme.onSurface.withOpacity(0.3),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No languages added yet',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: languages.length,
            itemBuilder: (context, index) {
              final lang = languages[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: theme.colorScheme.primaryContainer,
                    child: Icon(
                      Icons.translate,
                      color: theme.colorScheme.onPrimaryContainer,
                      size: 20,
                    ),
                  ),
                  title: Text(
                    lang.name,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  subtitle: Text(
                    lang.proficiency.displayName,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: _getProficiencyColor(theme, lang.proficiency),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit_outlined, size: 20),
                        onPressed: () => _editLanguage(context, index),
                        tooltip: 'Edit',
                      ),
                      IconButton(
                        icon: Icon(
                          Icons.delete_outline,
                          size: 20,
                          color: theme.colorScheme.error,
                        ),
                        onPressed: () => _deleteLanguage(context, index),
                        tooltip: 'Delete',
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
      ],
    );
  }

  Color _getProficiencyColor(ThemeData theme, LanguageProficiency proficiency) {
    switch (proficiency) {
      case LanguageProficiency.native:
      case LanguageProficiency.fluent:
        return Colors.green;
      case LanguageProficiency.advanced:
        return Colors.blue;
      case LanguageProficiency.intermediate:
        return Colors.orange;
      case LanguageProficiency.basic:
        return Colors.grey;
    }
  }
}

/// Dialog for adding/editing a language
class _LanguageEditDialog extends StatefulWidget {
  const _LanguageEditDialog({this.language});

  final Language? language;

  @override
  State<_LanguageEditDialog> createState() => _LanguageEditDialogState();
}

class _LanguageEditDialogState extends State<_LanguageEditDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  LanguageProficiency _proficiency = LanguageProficiency.intermediate;

  @override
  void initState() {
    super.initState();
    if (widget.language != null) {
      _nameController.text = widget.language!.name;
      _proficiency = widget.language!.proficiency;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;

    final language = Language(
      id: widget.language?.id,
      name: _nameController.text.trim(),
      proficiency: _proficiency,
    );

    Navigator.pop(context, language);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Dialog(
      child: Container(
        width: 500,
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.language, color: theme.colorScheme.primary),
                  const SizedBox(width: 12),
                  Text(
                    widget.language == null ? 'Add Language' : 'Edit Language',
                    style: theme.textTheme.titleLarge,
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Language *',
                  hintText: 'e.g. English, Spanish, German',
                  prefixIcon: Icon(Icons.abc),
                  border: OutlineInputBorder(),
                ),
                validator: (value) =>
                    value?.trim().isEmpty ?? true ? 'Required' : null,
                autofocus: true,
              ),
              const SizedBox(height: 20),
              Text(
                'Proficiency Level',
                style: theme.textTheme.titleSmall,
              ),
              const SizedBox(height: 12),
              ...LanguageProficiency.values.map((level) {
                return RadioListTile<LanguageProficiency>(
                  title: Text(level.displayName),
                  value: level,
                  groupValue: _proficiency,
                  onChanged: (value) {
                    setState(() => _proficiency = value!);
                  },
                  contentPadding: EdgeInsets.zero,
                );
              }),
              const SizedBox(height: 24),
              Row(
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
            ],
          ),
        ),
      ),
    );
  }
}
