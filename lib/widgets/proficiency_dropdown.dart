import 'package:flutter/material.dart';
import '../localization/app_localizations.dart';
import '../models/user_data/skill.dart';
import '../models/user_data/language.dart';
import '../models/user_data/interest.dart';
import '../utils/data_converters.dart';

/// Generic proficiency/level dropdown widget
/// Works with SkillLevel, LanguageProficiency, and InterestLevel enums
class ProficiencyDropdown<T extends Enum> extends StatelessWidget {
  const ProficiencyDropdown({
    required this.value,
    required this.items,
    required this.onChanged,
    this.label,
    this.hint,
    this.isRequired = false,
    super.key,
  });

  final T? value;
  final List<T> items;
  final ValueChanged<T?> onChanged;
  final String? label;
  final String? hint;
  final bool isRequired;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DropdownButtonFormField<T>(
      initialValue: value,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
        filled: true,
        fillColor: theme.colorScheme.surface,
      ),
      items: items.map((item) {
        return DropdownMenuItem<T>(
          value: item,
          child: Row(
            children: [
              // Level indicator icon
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _getColorForLevel(item),
                ),
              ),
              const SizedBox(width: 12),
              // Display name
              Text(_getDisplayName(context, item)),
            ],
          ),
        );
      }).toList(),
      onChanged: onChanged,
      validator: isRequired
          ? (value) => value == null ? 'Please select a level' : null
          : null,
      dropdownColor: theme.colorScheme.surface,
      icon: Icon(
        Icons.arrow_drop_down,
        color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
      ),
    );
  }

  /// Get display name for any proficiency enum
  String _getDisplayName(BuildContext context, T level) {
    if (level is SkillLevel) {
      return context.tr(level.localizationKey);
    } else if (level is LanguageProficiency) {
      return context.tr(level.localizationKey);
    } else if (level is InterestLevel) {
      return context.tr(level.localizationKey);
    }
    return level.name;
  }

  /// Get color for any proficiency level
  Color _getColorForLevel(T level) {
    if (level is SkillLevel) {
      return DataConverters.getSkillLevelColor(level);
    } else if (level is LanguageProficiency) {
      return DataConverters.getLanguageProficiencyColor(level);
    } else if (level is InterestLevel) {
      // Interest levels: casual (grey), moderate (blue), passionate (red)
      switch (level) {
        case InterestLevel.casual:
          return const Color(0xFF9E9E9E); // Grey
        case InterestLevel.moderate:
          return const Color(0xFF2196F3); // Blue
        case InterestLevel.passionate:
          return const Color(0xFFE91E63); // Pink/Red
      }
    }
    return const Color(0xFF9E9E9E); // Default grey
  }
}

/// Skill level dropdown - convenience widget
class SkillLevelDropdown extends StatelessWidget {
  const SkillLevelDropdown({
    required this.value,
    required this.onChanged,
    this.label = 'Skill Level',
    this.isRequired = false,
    super.key,
  });

  final SkillLevel? value;
  final ValueChanged<SkillLevel?> onChanged;
  final String label;
  final bool isRequired;

  @override
  Widget build(BuildContext context) {
    return ProficiencyDropdown<SkillLevel>(
      value: value,
      items: SkillLevel.values,
      onChanged: onChanged,
      label: label,
      hint: 'Select skill level',
      isRequired: isRequired,
    );
  }
}

/// Language proficiency dropdown - convenience widget
class LanguageProficiencyDropdown extends StatelessWidget {
  const LanguageProficiencyDropdown({
    required this.value,
    required this.onChanged,
    this.label = 'Proficiency',
    this.isRequired = false,
    super.key,
  });

  final LanguageProficiency? value;
  final ValueChanged<LanguageProficiency?> onChanged;
  final String label;
  final bool isRequired;

  @override
  Widget build(BuildContext context) {
    return ProficiencyDropdown<LanguageProficiency>(
      value: value,
      items: LanguageProficiency.values,
      onChanged: onChanged,
      label: label,
      hint: 'Select proficiency level',
      isRequired: isRequired,
    );
  }
}

/// Interest level dropdown - convenience widget
class InterestLevelDropdown extends StatelessWidget {
  const InterestLevelDropdown({
    required this.value,
    required this.onChanged,
    this.label = 'Interest Level',
    this.isRequired = false,
    super.key,
  });

  final InterestLevel? value;
  final ValueChanged<InterestLevel?> onChanged;
  final String label;
  final bool isRequired;

  @override
  Widget build(BuildContext context) {
    return ProficiencyDropdown<InterestLevel>(
      value: value,
      items: InterestLevel.values,
      onChanged: onChanged,
      label: label,
      hint: 'Select interest level',
      isRequired: isRequired,
    );
  }
}
