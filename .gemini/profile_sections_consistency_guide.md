# Profile Tab Section Consistency - Implementation Guide

## Current Status ✅

### Completed:
1. ✅ **ProfileSectionCard** widget created - provides consistent collapsible styling
2. ✅ **PersonalInfoSection** - Updated with `showHeader` parameter
3. ✅ **Import/Export Card** - Beautiful accent-colored starting point
4. ✅ **Interests & Cover Letter** - Using ProfileSectionCard directly  
5. ✅ **All sections wrapped** in ProfileSectionCard in profile_screen.dart

## Remaining Tasks 🔧

The following sections need to be updated to support `showHeader: false` parameter, similar to PersonalInfoSection:

### 1. WorkExperienceSection
**File:** `lib/screens/templates/sections/work_experience_section.dart`

**Changes needed:**
- Add `showHeader` parameter (default: true)
- Wrap content in conditional header
- Make icon match ProfileSectionCard style (in background container)
- Change button text from "Add Experience" to "Add"

### 2. EducationSection  
**File:** `lib/screens/templates/sections/education_section.dart`

**Changes needed:**
- Add `showHeader` parameter (default: true)
- Wrap content in conditional header
- Make icon match ProfileSectionCard style
- Change button text to "Add"

### 3. SkillsSection
**File:** `lib/screens/templates/sections/skills_section.dart`

**Changes needed:**
- Add `showHeader` parameter (default: true)
- Wrap content in conditional header
- Make icon match ProfileSectionCard style
- Change button text from "Add Skill" to "Add"

### 4. LanguagesSection
**File:** `lib/screens/templates/sections/languages_section.dart`

**Changes needed:**
- Add `showHeader` parameter (default: true)
- Wrap content in conditional header
- Make icon match ProfileSectionCard style
- Change button text from "Add Language" to "Add"

## Pattern to Follow

```dart
class XxxSection extends StatelessWidget {
  const XxxSection({
    this.showHeader = true,
    super.key,
  });

  final bool showHeader;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final userDataProvider = context.watch<UserDataProvider>();
    final items = userDataProvider.xxxItems;

    // Extract content
    final content = Padding(
      padding: showHeader ? UIConstants.cardPadding : EdgeInsets.zero,
      child: items.isEmpty
          ? _buildEmptyState(context)
          : _buildItemsList(context, items),
    );

    // Return content only if no header
    if (!showHeader) {
      return content;
    }

    // Return with header
    return Container(
      decoration: UIConstants.getCardDecoration(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: UIConstants.cardPadding,
            child: Row(
              children: [
                // Icon with background (like ProfileSectionCard)
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.xxx_outlined,
                    color: theme.colorScheme.primary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Section Name',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                // Count badge
                if (items.isNotEmpty) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${items.length}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ),
                ],
                const Spacer(),
                // Unified Add button
                OutlinedButton.icon(
                  onPressed: () => _showAddDialog(context),
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('Add'),
                  style: UIConstants.getSecondaryButtonStyle(context),
                ),
              ],
            ),
          ),
          content,
        ],
      ),
    );
  }
}
```

## Then Update profile_screen.dart

```dart
// Work Experience - Wrapped
_buildWrappedSection(
  context,
  title: 'Work Experience',
  icon: Icons.work_outline,
  count: userDataProvider.experiences.length,
  child: const WorkExperienceSection(showHeader: false),
),

// Education - Wrapped
_buildWrappedSection(
  context,
  title: 'Education',
  icon: Icons.school_outlined,
  count: userDataProvider.education.length,
  child: const EducationSection(showHeader: false),
),

// Skills - Wrapped
_buildWrappedSection(
  context,
  title: 'Skills',
  icon: Icons.psychology_outlined,
  count: userDataProvider.skills.length,
  child: const SkillsSection(showHeader: false),
),

// Languages - Wrapped
_buildWrappedSection(
  context,
  title: 'Languages',
  icon: Icons.language,
  count: userDataProvider.languages.length,
  child: const LanguagesSection(showHeader: false),
),
```

## Benefits of This Approach

✅ **All sections collapsible** with ProfileSectionCard wrapper
✅ **Consistent button styling** - all "Add" buttons use UIConstants
✅ **Consistent icons** - all have background containers
✅ **Unified count badges** - consistent styling across all sections
✅ **DRY principle** - single source of truth for section styling
✅ **Backward compatible** - showHeader:true keeps original behavior

## Testing Checklist

- [ ] All sections can collapse/expand
- [ ] Collapsed state shows item count
- [ ] All "Add" buttons look the same
- [ ] All section icons have background containers
- [ ] Count badges appear consistently
- [ ] Hot reload works correctly
