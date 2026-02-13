import 'package:flutter/material.dart';
import '../models/user_data/language.dart';
import '../localization/app_localizations.dart';
import '../theme/app_theme.dart';

/// Dialog for adding or editing a language
class LanguageEditDialog extends StatefulWidget {
  const LanguageEditDialog({
    this.language,
    super.key,
  });

  final Language? language;

  @override
  State<LanguageEditDialog> createState() => _LanguageEditDialogState();
}

class _LanguageEditDialogState extends State<LanguageEditDialog> {
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

    final language = (widget.language ??
            Language(name: '', proficiency: LanguageProficiency.intermediate))
        .copyWith(
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
        width: 450,
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.sm),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.translate_outlined,
                      color: theme.colorScheme.primary,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    widget.language == null ? context.tr('add_language') : context.tr('edit_language'),
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xl),

              // Name field
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: context.tr('language_name_label'),
                  hintText: context.tr('language_name_hint'),
                  prefixIcon: const Icon(Icons.language_outlined),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return context.tr('please_enter_language');
                  }
                  return null;
                },
                autofocus: true,
                textCapitalization: TextCapitalization.words,
              ),
              const SizedBox(height: AppSpacing.lg),

              // Proficiency Level
              Text(
                context.tr('proficiency_level'),
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: LanguageProficiency.values.length,
                itemBuilder: (context, index) {
                  final level = LanguageProficiency.values[index];
                  return RadioListTile<LanguageProficiency>(
                    title: Text(context.tr(level.localizationKey)),
                    subtitle: Text(_getProficiencyDescription(level)),
                    value: level,
                    groupValue: _proficiency,
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => _proficiency = value);
                      }
                    },
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                  );
                },
              ),
              const SizedBox(height: AppSpacing.xl),

              // Actions
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(context.tr('cancel')),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  FilledButton.icon(
                    onPressed: _save,
                    icon: const Icon(Icons.check, size: 18),
                    label: Text(context.tr('save_language')),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getProficiencyDescription(LanguageProficiency level) {
    switch (level) {
      case LanguageProficiency.basic:
        return context.tr('proficiency_basic_desc');
      case LanguageProficiency.intermediate:
        return context.tr('proficiency_intermediate_desc');
      case LanguageProficiency.advanced:
        return context.tr('proficiency_advanced_desc');
      case LanguageProficiency.fluent:
        return context.tr('proficiency_fluent_desc');
      case LanguageProficiency.native:
        return context.tr('proficiency_native_desc');
    }
  }
}
