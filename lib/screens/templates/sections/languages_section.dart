import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/user_data_provider.dart';
import '../../../models/user_data/language.dart';
import '../../../theme/app_theme.dart';
import '../../../constants/ui_constants.dart';

/// Languages management section
class LanguagesSection extends StatelessWidget {
  const LanguagesSection({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final userDataProvider = context.watch<UserDataProvider>();
    final languages = userDataProvider.languages;

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.dividerColor, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Icon(
                  Icons.language,
                  color: theme.colorScheme.primary,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  'Languages',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${languages.length}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ),
                const Spacer(),
                OutlinedButton.icon(
                  onPressed: () => _showAddLanguageDialog(context),
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('Add Language'),
                ),
              ],
            ),
          ),
          // Content
          Padding(
            padding: const EdgeInsets.all(20),
            child: languages.isEmpty
                ? _buildEmptyState(context)
                : _buildLanguagesList(context, languages),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 32),
        child: Column(
          children: [
            Icon(
              Icons.language,
              size: 48,
              color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 12),
            Text(
              'No languages added yet',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.textTheme.bodySmall?.color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLanguagesList(BuildContext context, List<Language> languages) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children:
          languages.map((lang) => _buildLanguageCard(context, lang)).toList(),
    );
  }

  Widget _buildLanguageCard(BuildContext context, Language language) {
    final theme = Theme.of(context);

    return Container(
      width: 180,
      decoration: BoxDecoration(
        color: theme.brightness == Brightness.dark
            ? Colors.white.withValues(alpha: 0.03)
            : Colors.black.withValues(alpha: 0.02),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.dividerColor.withValues(alpha: 0.5),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showEditLanguageDialog(context, language),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        language.name,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Icon(
                      Icons.edit,
                      size: 14,
                      color: theme.textTheme.bodySmall?.color
                          ?.withValues(alpha: 0.5),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getProficiencyColor(theme, language.proficiency)
                        .withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    language.proficiency.displayName,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: _getProficiencyColor(theme, language.proficiency),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _getProficiencyColor(ThemeData theme, LanguageProficiency proficiency) {
    switch (proficiency) {
      case LanguageProficiency.native:
        return const Color(0xFF10B981); // Green
      case LanguageProficiency.fluent:
        return const Color(0xFF3B82F6); // Blue
      case LanguageProficiency.advanced:
        return theme.colorScheme.primary;
      case LanguageProficiency.intermediate:
        return const Color(0xFFF59E0B); // Orange
      case LanguageProficiency.basic:
        return const Color(0xFF6B7280); // Gray
    }
  }

  void _showAddLanguageDialog(BuildContext context) {
    _showLanguageDialog(context, null);
  }

  void _showEditLanguageDialog(BuildContext context, Language language) {
    _showLanguageDialog(context, language);
  }

  void _showLanguageDialog(BuildContext context, Language? existingLang) {
    final nameController =
        TextEditingController(text: existingLang?.name ?? '');
    LanguageProficiency selectedProficiency =
        existingLang?.proficiency ?? LanguageProficiency.intermediate;

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(existingLang == null ? 'Add Language' : 'Edit Language'),
          content: SizedBox(
            width: 400,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Language *',
                    prefixIcon: Icon(Icons.language),
                    hintText: 'e.g., English, Spanish',
                  ),
                  autofocus: true,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<LanguageProficiency>(
                  initialValue: selectedProficiency,
                  decoration: const InputDecoration(
                    labelText: 'Proficiency Level',
                    prefixIcon: Icon(Icons.trending_up),
                  ),
                  items: LanguageProficiency.values.map((proficiency) {
                    return DropdownMenuItem(
                      value: proficiency,
                      child: Text(proficiency.displayName),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => selectedProficiency = value);
                    }
                  },
                ),
              ],
            ),
          ),
          actions: [
            if (existingLang != null)
              TextButton.icon(
                onPressed: () async {
                  await context
                      .read<UserDataProvider>()
                      .deleteLanguage(existingLang.id);
                  if (dialogContext.mounted) Navigator.pop(dialogContext);
                },
                icon: const Icon(Icons.delete, color: Colors.red),
                label:
                    const Text('Delete', style: TextStyle(color: Colors.red)),
              ),
            const Spacer(),
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (nameController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Language name is required')),
                  );
                  return;
                }

                final language = existingLang?.copyWith(
                      name: nameController.text.trim(),
                      proficiency: selectedProficiency,
                    ) ??
                    Language(
                      name: nameController.text.trim(),
                      proficiency: selectedProficiency,
                    );

                if (existingLang == null) {
                  await context.read<UserDataProvider>().addLanguage(language);
                } else {
                  await context
                      .read<UserDataProvider>()
                      .updateLanguage(language);
                }

                if (dialogContext.mounted) Navigator.pop(dialogContext);
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }
}
