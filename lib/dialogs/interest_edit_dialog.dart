import 'package:flutter/material.dart';
import '../models/user_data/interest.dart';
import '../localization/app_localizations.dart';
import '../theme/app_theme.dart';

/// Simple dialog for adding or editing an interest
class InterestEditDialog extends StatefulWidget {
  const InterestEditDialog({
    this.interest,
    super.key,
  });

  final Interest? interest;

  @override
  State<InterestEditDialog> createState() => _InterestEditDialogState();
}

class _InterestEditDialogState extends State<InterestEditDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  InterestLevel? _selectedLevel;

  @override
  void initState() {
    super.initState();
    if (widget.interest != null) {
      _nameController.text = widget.interest!.name;
      _selectedLevel = widget.interest!.level;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;

    final interest = (widget.interest ?? Interest(name: '')).copyWith(
      name: _nameController.text.trim(),
      level: _selectedLevel,
    );

    Navigator.pop(context, interest);
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
                      Icons.interests_outlined,
                      color: theme.colorScheme.primary,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    widget.interest == null ? context.tr('add_interest') : context.tr('edit_interest'),
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
                  labelText: context.tr('interest_label'),
                  hintText: context.tr('interest_hint'),
                  prefixIcon: const Icon(Icons.favorite_outline),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return context.tr('please_enter_interest');
                  }
                  return null;
                },
                autofocus: true,
                textCapitalization: TextCapitalization.words,
              ),
              const SizedBox(height: AppSpacing.lg),

              // Passion Level
              Text(
                context.tr('passion_level_optional'),
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Wrap(
                spacing: AppSpacing.sm,
                children: [
                  ChoiceChip(
                    label: Text(context.tr('none')),
                    selected: _selectedLevel == null,
                    onSelected: (selected) {
                      if (selected) setState(() => _selectedLevel = null);
                    },
                  ),
                  ...InterestLevel.values.map((level) {
                    final isSelected = _selectedLevel == level;
                    return ChoiceChip(
                      label: Text(context.tr(level.localizationKey)),
                      selected: isSelected,
                      onSelected: (selected) {
                        if (selected) setState(() => _selectedLevel = level);
                      },
                    );
                  }),
                ],
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
                    label: Text(context.tr('save_interest')),
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
