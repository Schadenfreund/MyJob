import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/user_data/personal_info.dart';
import '../models/user_data/language.dart';
import '../providers/user_data_provider.dart';
import '../widgets/collapsible_card.dart';
import '../widgets/common/custom_text_field.dart';
import '../widgets/skill_chip_editor.dart';
import '../widgets/interest_chip_editor.dart';
import '../widgets/proficiency_dropdown.dart';
import '../utils/ui_utils.dart';

/// Comprehensive user profile editor for Settings screen
/// Edits PersonalInfo, Skills, Interests, and Languages
class UserProfileEditor extends StatefulWidget {
  const UserProfileEditor({super.key});

  @override
  State<UserProfileEditor> createState() => _UserProfileEditorState();
}

class _UserProfileEditorState extends State<UserProfileEditor> {
  // Personal info controllers
  late TextEditingController _fullNameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _addressController;
  late TextEditingController _cityController;
  late TextEditingController _countryController;
  late TextEditingController _profileSummaryController;

  // Language editing
  final TextEditingController _languageNameController = TextEditingController();
  LanguageProficiency _selectedProficiency = LanguageProficiency.intermediate;

  bool _hasUnsavedChanges = false;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
  }

  void _initializeControllers() {
    final userDataProvider = context.read<UserDataProvider>();
    final info = userDataProvider.personalInfo;

    _fullNameController = TextEditingController(text: info?.fullName ?? '');
    _emailController = TextEditingController(text: info?.email ?? '');
    _phoneController = TextEditingController(text: info?.phone ?? '');
    _addressController = TextEditingController(text: info?.address ?? '');
    _cityController = TextEditingController(text: info?.city ?? '');
    _countryController = TextEditingController(text: info?.country ?? '');
    _profileSummaryController =
        TextEditingController(text: info?.profileSummary ?? '');

    // Add listeners to track changes
    _fullNameController.addListener(() => setState(() => _hasUnsavedChanges = true));
    _emailController.addListener(() => setState(() => _hasUnsavedChanges = true));
    _phoneController.addListener(() => setState(() => _hasUnsavedChanges = true));
    _addressController.addListener(() => setState(() => _hasUnsavedChanges = true));
    _cityController.addListener(() => setState(() => _hasUnsavedChanges = true));
    _countryController.addListener(() => setState(() => _hasUnsavedChanges = true));
    _profileSummaryController.addListener(() => setState(() => _hasUnsavedChanges = true));
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _countryController.dispose();
    _profileSummaryController.dispose();
    _languageNameController.dispose();
    super.dispose();
  }

  Future<void> _savePersonalInfo() async {
    final userDataProvider = context.read<UserDataProvider>();

    final personalInfo = PersonalInfo(
      id: userDataProvider.personalInfo?.id,
      fullName: _fullNameController.text.trim(),
      email: _emailController.text.trim().isNotEmpty
          ? _emailController.text.trim()
          : null,
      phone: _phoneController.text.trim().isNotEmpty
          ? _phoneController.text.trim()
          : null,
      address: _addressController.text.trim().isNotEmpty
          ? _addressController.text.trim()
          : null,
      city: _cityController.text.trim().isNotEmpty
          ? _cityController.text.trim()
          : null,
      country: _countryController.text.trim().isNotEmpty
          ? _countryController.text.trim()
          : null,
      profileSummary: _profileSummaryController.text.trim().isNotEmpty
          ? _profileSummaryController.text.trim()
          : null,
    );

    await userDataProvider.updatePersonalInfo(personalInfo);
    setState(() => _hasUnsavedChanges = false);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(
                Icons.check_circle,
                color: Theme.of(context).colorScheme.onPrimary,
              ),
              const SizedBox(width: 12),
              const Text('Profile saved successfully'),
            ],
          ),
          backgroundColor: Theme.of(context).colorScheme.primary,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final userDataProvider = context.watch<UserDataProvider>();

    return SingleChildScrollView(
      padding: EdgeInsets.all(UIUtils.spacingMd),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Contact Information Section
          CollapsibleCard(
            cardDecoration: UIUtils.getCardDecoration(context),
            title: 'Contact Information',
            subtitle: 'Basic details used across all documents',
            status: _fullNameController.text.isNotEmpty &&
                    _emailController.text.isNotEmpty
                ? CollapsibleCardStatus.configured
                : CollapsibleCardStatus.unconfigured,
            initiallyCollapsed: false,
            collapsedSummary: Text(
              _fullNameController.text.isNotEmpty
                  ? '${_fullNameController.text}${_emailController.text.isNotEmpty ? ' • ${_emailController.text}' : ''}'
                  : 'Add your contact information',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.7),
              ),
            ),
            expandedContent: Column(
              children: [
                CustomTextField(
                  controller: _fullNameController,
                  label: 'Full Name',
                  hint: 'John Doe',
                  prefixIcon: Icons.person,
                  required: true,
                ),
                SizedBox(height: UIUtils.spacingMd),
                CustomTextField(
                  controller: _emailController,
                  label: 'Email',
                  hint: 'john@example.com',
                  keyboardType: TextInputType.emailAddress,
                  prefixIcon: Icons.email,
                  required: true,
                ),
                SizedBox(height: UIUtils.spacingMd),
                CustomTextField(
                  controller: _phoneController,
                  label: 'Phone',
                  hint: '+1 234 567 8900',
                  keyboardType: TextInputType.phone,
                  prefixIcon: Icons.phone,
                ),
                SizedBox(height: UIUtils.spacingMd),
                CustomTextField(
                  controller: _addressController,
                  label: 'Address',
                  hint: '123 Main Street',
                  prefixIcon: Icons.home,
                ),
                SizedBox(height: UIUtils.spacingMd),
                Row(
                  children: [
                    Expanded(
                      child: CustomTextField(
                        controller: _cityController,
                        label: 'City',
                        hint: 'New York',
                        prefixIcon: Icons.location_city,
                      ),
                    ),
                    SizedBox(width: UIUtils.spacingMd),
                    Expanded(
                      child: CustomTextField(
                        controller: _countryController,
                        label: 'Country',
                        hint: 'USA',
                        prefixIcon: Icons.flag,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          SizedBox(height: UIUtils.spacingMd),

          // Professional Summary Section
          CollapsibleCard(
            cardDecoration: UIUtils.getCardDecoration(context),
            title: 'Professional Summary',
            subtitle: 'Your elevator pitch',
            status: _profileSummaryController.text.isNotEmpty
                ? CollapsibleCardStatus.configured
                : CollapsibleCardStatus.unconfigured,
            initiallyCollapsed: _profileSummaryController.text.isEmpty,
            collapsedSummary: Text(
              _profileSummaryController.text.isNotEmpty
                  ? _profileSummaryController.text.length > 100
                      ? '${_profileSummaryController.text.substring(0, 100)}...'
                      : _profileSummaryController.text
                  : 'Add a brief professional summary',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.7),
              ),
            ),
            expandedContent: CustomTextField(
              controller: _profileSummaryController,
              label: 'Professional Summary',
              hint:
                  'Brief description of your professional background and goals...',
              maxLines: 6,
              minLines: 4,
            ),
          ),

          SizedBox(height: UIUtils.spacingMd),

          // Skills Section
          CollapsibleCard(
            cardDecoration: UIUtils.getCardDecoration(context),
            title: 'Skills',
            subtitle:
                '${userDataProvider.skills.length} skill${userDataProvider.skills.length == 1 ? '' : 's'}',
            status: userDataProvider.skills.isNotEmpty
                ? CollapsibleCardStatus.configured
                : CollapsibleCardStatus.unconfigured,
            initiallyCollapsed: userDataProvider.skills.isEmpty,
            collapsedSummary: Text(
              userDataProvider.skills.isNotEmpty
                  ? userDataProvider.skills
                      .take(3)
                      .map((s) => s.name)
                      .join(', ') +
                      (userDataProvider.skills.length > 3 ? '...' : '')
                  : 'Add your skills with proficiency levels',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.7),
              ),
            ),
            expandedContent: SkillChipEditor(
              skills: userDataProvider.skills,
              onChanged: (skills) {
                setState(() => _hasUnsavedChanges = true);
                // Update skills in parallel
                final currentIds = userDataProvider.skills.map((s) => s.id).toSet();
                final newIds = skills.map((s) => s.id).toSet();

                // Delete removed skills
                for (final id in currentIds.difference(newIds)) {
                  userDataProvider.deleteSkill(id);
                }

                // Add or update skills
                for (final skill in skills) {
                  if (currentIds.contains(skill.id)) {
                    userDataProvider.updateSkill(skill);
                  } else {
                    userDataProvider.addSkill(skill);
                  }
                }
              },
            ),
          ),

          SizedBox(height: UIUtils.spacingMd),

          // Interests Section
          CollapsibleCard(
            cardDecoration: UIUtils.getCardDecoration(context),
            title: 'Interests & Hobbies',
            subtitle:
                '${userDataProvider.interests.length} interest${userDataProvider.interests.length == 1 ? '' : 's'}',
            status: userDataProvider.interests.isNotEmpty
                ? CollapsibleCardStatus.configured
                : CollapsibleCardStatus.unconfigured,
            initiallyCollapsed: userDataProvider.interests.isEmpty,
            collapsedSummary: Text(
              userDataProvider.interests.isNotEmpty
                  ? userDataProvider.interests
                      .take(3)
                      .map((i) => i.name)
                      .join(', ') +
                      (userDataProvider.interests.length > 3 ? '...' : '')
                  : 'Add your interests and hobbies',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.7),
              ),
            ),
            expandedContent: InterestChipEditor(
              interests: userDataProvider.interests,
              onChanged: (interests) {
                setState(() => _hasUnsavedChanges = true);
                // Update interests in parallel
                final currentIds =
                    userDataProvider.interests.map((i) => i.id).toSet();
                final newIds = interests.map((i) => i.id).toSet();

                // Delete removed interests
                for (final id in currentIds.difference(newIds)) {
                  userDataProvider.deleteInterest(id);
                }

                // Add or update interests
                for (final interest in interests) {
                  if (currentIds.contains(interest.id)) {
                    userDataProvider.updateInterest(interest);
                  } else {
                    userDataProvider.addInterest(interest);
                  }
                }
              },
            ),
          ),

          SizedBox(height: UIUtils.spacingMd),

          // Languages Section
          CollapsibleCard(
            cardDecoration: UIUtils.getCardDecoration(context),
            title: 'Languages',
            subtitle:
                '${userDataProvider.languages.length} language${userDataProvider.languages.length == 1 ? '' : 's'}',
            status: userDataProvider.languages.isNotEmpty
                ? CollapsibleCardStatus.configured
                : CollapsibleCardStatus.unconfigured,
            initiallyCollapsed: userDataProvider.languages.isEmpty,
            collapsedSummary: Text(
              userDataProvider.languages.isNotEmpty
                  ? userDataProvider.languages
                      .map((l) =>
                          '${l.name} (${l.proficiency.displayName})')
                      .join(', ')
                  : 'Add languages you speak',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.7),
              ),
            ),
            expandedContent: _buildLanguagesEditor(userDataProvider),
          ),

          SizedBox(height: UIUtils.sectionGap),

          // Save button with enhanced feedback
          Container(
            decoration: _hasUnsavedChanges
                ? BoxDecoration(
                    color: Theme.of(context)
                        .colorScheme
                        .primaryContainer
                        .withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(UIUtils.radiusMd),
                    border: Border.all(
                      color: Theme.of(context)
                          .colorScheme
                          .primary
                          .withValues(alpha: 0.5),
                      width: 2,
                    ),
                  )
                : null,
            padding: _hasUnsavedChanges
                ? const EdgeInsets.all(UIUtils.cardPadding)
                : null,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (_hasUnsavedChanges) ...[
                  Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        size: 20,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'You have unsaved changes',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).colorScheme.primary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: UIUtils.cardInternalGap),
                ],
                FilledButton.icon(
                  onPressed: _hasUnsavedChanges ? _savePersonalInfo : null,
                  icon: const Icon(Icons.save),
                  label: Text(_hasUnsavedChanges
                      ? 'Save All Changes'
                      : 'No Changes to Save'),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(double.infinity, 48),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLanguagesEditor(UserDataProvider userDataProvider) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Existing languages list
        if (userDataProvider.languages.isNotEmpty)
          ...userDataProvider.languages.map((language) {
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: theme.colorScheme.primaryContainer,
                  child: Text(
                    language.name.substring(0, 1).toUpperCase(),
                    style: TextStyle(
                      color: theme.colorScheme.onPrimaryContainer,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                title: Text(language.name),
                subtitle: Text(language.proficiency.displayName),
                trailing: IconButton(
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () {
                    userDataProvider.deleteLanguage(language.id);
                    setState(() => _hasUnsavedChanges = true);
                  },
                ),
              ),
            );
          })
        else
          Text(
            'No languages added yet',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.6),
            ),
          ),

        const SizedBox(height: 16),

        // Add new language
        Card(
          elevation: 0,
          color:
              theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Add New Language',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: TextField(
                        controller: _languageNameController,
                        decoration: InputDecoration(
                          labelText: 'Language',
                          hintText: 'e.g., English, Spanish',
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
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: LanguageProficiencyDropdown(
                        value: _selectedProficiency,
                        onChanged: (proficiency) {
                          if (proficiency != null) {
                            setState(() => _selectedProficiency = proficiency);
                          }
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () {
                      if (_languageNameController.text.trim().isNotEmpty) {
                        final language = Language(
                          name: _languageNameController.text.trim(),
                          proficiency: _selectedProficiency,
                        );
                        userDataProvider.addLanguage(language);
                        _languageNameController.clear();
                        _selectedProficiency = LanguageProficiency.intermediate;
                        setState(() => _hasUnsavedChanges = true);
                      }
                    },
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Add Language'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
