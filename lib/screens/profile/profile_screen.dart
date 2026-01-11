import 'dart:io';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import '../../providers/user_data_provider.dart';
import '../../models/user_data/interest.dart';
import '../../models/user_data/skill.dart';
import '../../models/user_data/language.dart';
import '../../models/master_profile.dart';
import '../../constants/app_constants.dart';
import '../../dialogs/unified_import_dialog.dart';
import '../../utils/ui_utils.dart';
import '../../utils/dialog_utils.dart';
import '../../widgets/collapsible_card.dart';
import '../../dialogs/interest_edit_dialog.dart';
import '../templates/sections/personal_info_section.dart';
import '../templates/sections/skills_section.dart';
import '../templates/sections/work_experience_section.dart';
import '../templates/sections/education_section.dart';
import '../templates/sections/languages_section.dart';
import '../../constants/ui_constants.dart';
import '../../widgets/profile_section_card.dart';

/// Profile Screen - Central hub for all user data
///
/// This is the master profile that feeds into all CVs and Cover Letters.
/// Users can import from YAML (using unified import) or edit directly in the GUI.
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      color: theme.colorScheme.surface,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header - Simple title with language switcher
            _buildHeader(context),
            const SizedBox(height: 24),

            // Import/Export Card - Accent colored "Start Here" card
            _buildImportExportCard(context),
            const SizedBox(height: 16),

            // Profile Sections
            const _ProfileSections(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final theme = Theme.of(context);
    final userDataProvider = context.watch<UserDataProvider>();
    final currentLang = userDataProvider.currentLanguage;

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Profile Templates',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Master CV data for all your job applications',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.textTheme.bodySmall?.color,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        // Language Switcher
        Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: theme.colorScheme.outline.withOpacity(0.2),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildLanguageToggle(
                context,
                userDataProvider,
                DocumentLanguage.en,
                currentLang == DocumentLanguage.en,
              ),
              Container(
                width: 1,
                height: 32,
                color: theme.colorScheme.outline.withOpacity(0.2),
              ),
              _buildLanguageToggle(
                context,
                userDataProvider,
                DocumentLanguage.de,
                currentLang == DocumentLanguage.de,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildImportExportCard(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primary.withOpacity(0.08),
            theme.colorScheme.primary.withOpacity(0.04),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.primary.withOpacity(0.3),
          width: 2,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Row(
          children: [
            // Icon with accent
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.upload_file,
                color: theme.colorScheme.primary,
                size: 28,
              ),
            ),
            const SizedBox(width: 20),
            // Text content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        'Import & Export',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'START HERE',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: theme.colorScheme.onPrimary,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Import YAML files to populate your profile data, or export your current profile for backup',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.textTheme.bodySmall?.color?.withOpacity(0.8),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 20),
            // Action buttons
            Row(
              children: [
                FilledButton.tonalIcon(
                  onPressed: () => _showImportDialog(context),
                  icon: const Icon(Icons.upload, size: 18),
                  label: const Text('Import'),
                  style: UIConstants.getPrimaryButtonStyle(context).copyWith(
                    backgroundColor: WidgetStateProperty.all(
                      theme.colorScheme.primary.withOpacity(0.15),
                    ),
                    foregroundColor: WidgetStateProperty.all(
                      theme.colorScheme.primary,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                OutlinedButton.icon(
                  onPressed: () => _showExportDialog(context),
                  icon: const Icon(Icons.download, size: 18),
                  label: const Text('Export'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: theme.colorScheme.primary,
                    side: BorderSide(
                      color: theme.colorScheme.primary.withOpacity(0.5),
                    ),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 12),
                    minimumSize: const Size(0, 44),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLanguageToggle(
    BuildContext context,
    UserDataProvider provider,
    DocumentLanguage language,
    bool isSelected,
  ) {
    final theme = Theme.of(context);

    return Material(
      color: isSelected
          ? theme.colorScheme.primary.withOpacity(0.12)
          : Colors.transparent,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: () => provider.switchLanguage(language),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Flag with subtle background
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: isSelected
                      ? theme.colorScheme.primary.withOpacity(0.1)
                      : theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  language.flag,
                  style: const TextStyle(fontSize: 16),
                ),
              ),
              const SizedBox(width: 8),
              // Language label
              Text(
                language.code.toUpperCase(),
                style: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected
                      ? theme.colorScheme.primary
                      : theme.textTheme.bodyMedium?.color?.withOpacity(0.7),
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showImportDialog(BuildContext context) async {
    // First, pick the file
    try {
      final fileResult = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['yaml', 'yml'],
        dialogTitle: 'Select YAML File to Import',
      );

      if (fileResult == null || fileResult.files.single.path == null) {
        return; // User cancelled
      }

      final file = File(fileResult.files.single.path!);

      // Then show the import dialog with the pre-selected file
      if (context.mounted) {
        final result = await showDialog<bool>(
          context: context,
          builder: (context) => UnifiedImportDialog(preSelectedFile: file),
        );

        if (result == true && context.mounted) {
          context.showSuccessSnackBar('Profile data imported successfully!');
        }
      }
    } catch (e) {
      if (context.mounted) {
        context.showErrorSnackBar('Error selecting file: $e');
      }
    }
  }

  void _showExportDialog(BuildContext context) async {
    final provider = context.read<UserDataProvider>();
    final profile = provider.currentProfile;

    if (profile == null) {
      if (context.mounted) {
        context.showErrorSnackBar('No profile data to export');
      }
      return;
    }

    try {
      // Convert profile to YAML format (matching import format)
      final yamlContent = _generateYamlFromProfile(profile);

      // Show save file dialog
      final result = await FilePicker.platform.saveFile(
        dialogTitle: 'Export Profile as YAML',
        fileName: 'profile_${profile.language.code}.yaml',
        type: FileType.custom,
        allowedExtensions: ['yaml', 'yml'],
      );

      if (result != null) {
        final file = File(result);
        await file.writeAsString(yamlContent);

        if (context.mounted) {
          context.showSuccessSnackBar('Profile exported successfully!');
        }
      }
    } catch (e) {
      if (context.mounted) {
        context.showErrorSnackBar('Export failed: $e');
      }
    }
  }

  String _generateYamlFromProfile(MasterProfile profile) {
    final buffer = StringBuffer();

    // Personal Info
    if (profile.personalInfo != null) {
      final info = profile.personalInfo!;
      buffer.writeln('personal_info:');
      buffer.writeln('  full_name: "${info.fullName}"');
      if (info.email != null) buffer.writeln('  email: "${info.email}"');
      if (info.phone != null) buffer.writeln('  phone: "${info.phone}"');
      if (info.address != null) buffer.writeln('  address: "${info.address}"');
      if (info.city != null) buffer.writeln('  city: "${info.city}"');
      if (info.country != null) buffer.writeln('  country: "${info.country}"');
      if (info.linkedin != null)
        buffer.writeln('  linkedin: "${info.linkedin}"');
      if (info.website != null) buffer.writeln('  website: "${info.website}"');
      if (info.jobTitle != null)
        buffer.writeln('  job_title: "${info.jobTitle}"');
      if (info.profileSummary != null && info.profileSummary!.isNotEmpty) {
        buffer.writeln('  profile_summary: |');
        for (final line in info.profileSummary!.split('\n')) {
          buffer.writeln('    $line');
        }
      }
      buffer.writeln();
    }

    // Work Experience
    if (profile.experiences.isNotEmpty) {
      buffer.writeln('work_experience:');
      for (final exp in profile.experiences) {
        buffer.writeln('  - position: "${exp.position}"');
        buffer.writeln('    company: "${exp.company}"');
        if (exp.location != null)
          buffer.writeln('    location: "${exp.location}"');
        buffer.writeln(
            '    start_date: "${exp.startDate.year}-${exp.startDate.month.toString().padLeft(2, '0')}-${exp.startDate.day.toString().padLeft(2, '0')}"');
        if (exp.endDate != null) {
          buffer.writeln(
              '    end_date: "${exp.endDate!.year}-${exp.endDate!.month.toString().padLeft(2, '0')}-${exp.endDate!.day.toString().padLeft(2, '0')}"');
        }
        buffer.writeln('    is_current: ${exp.isCurrent}');
        if (exp.responsibilities.isNotEmpty) {
          buffer.writeln('    responsibilities:');
          for (final resp in exp.responsibilities) {
            buffer.writeln('      - "$resp"');
          }
        }
      }
      buffer.writeln();
    }

    // Education
    if (profile.education.isNotEmpty) {
      buffer.writeln('education:');
      for (final edu in profile.education) {
        buffer.writeln('  - degree: "${edu.degree}"');
        buffer.writeln('    institution: "${edu.institution}"');
        buffer.writeln('    field_of_study: "${edu.fieldOfStudy}"');
        buffer.writeln(
            '    start_date: "${edu.startDate.year}-${edu.startDate.month.toString().padLeft(2, '0')}"');
        if (edu.endDate != null) {
          buffer.writeln(
              '    end_date: "${edu.endDate!.year}-${edu.endDate!.month.toString().padLeft(2, '0')}"');
        }
        if (edu.grade != null) buffer.writeln('    grade: "${edu.grade}"');
      }
      buffer.writeln();
    }

    // Skills
    if (profile.skills.isNotEmpty) {
      buffer.writeln('skills:');
      for (final skill in profile.skills) {
        buffer.writeln('  - name: "${skill.name}"');
        if (skill.category != null)
          buffer.writeln('    category: "${skill.category}"');
        if (skill.level != null)
          buffer.writeln('    level: "${skill.level!.name}"');
      }
      buffer.writeln();
    }

    // Languages
    if (profile.languages.isNotEmpty) {
      buffer.writeln('languages:');
      for (final lang in profile.languages) {
        buffer.writeln('  - name: "${lang.name}"');
        buffer.writeln('    proficiency: "${lang.proficiency.name}"');
      }
      buffer.writeln();
    }

    // Interests
    if (profile.interests.isNotEmpty) {
      buffer.writeln('interests:');
      for (final interest in profile.interests) {
        buffer.writeln('  - "${interest.name}"');
      }
      buffer.writeln();
    }

    // Default cover letter
    if (profile.defaultCoverLetterBody.isNotEmpty) {
      buffer.writeln('default_cover_letter: |');
      for (final line in profile.defaultCoverLetterBody.split('\n')) {
        buffer.writeln('  $line');
      }
    }

    return buffer.toString();
  }
}

/// Profile sections with collapsible cards
class _ProfileSections extends StatelessWidget {
  const _ProfileSections();

  @override
  Widget build(BuildContext context) {
    final userDataProvider = context.watch<UserDataProvider>();
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Personal Info Section - Wrapped (has Add button in inner widget)
        ProfileSectionCard(
          title: 'Personal Information',
          icon: Icons.person_outline,
          count: userDataProvider.personalInfo != null ? 1 : 0,
          actionLabel: '',
          onActionPressed: null,
          collapsedPreview: userDataProvider.personalInfo != null
              ? Row(
                  children: [
                    // Profile picture preview in collapsed state
                    if (userDataProvider.personalInfo!.hasProfilePicture)
                      Container(
                        width: 40,
                        height: 40,
                        margin: const EdgeInsets.only(right: 12),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: theme.colorScheme.primary,
                            width: 2,
                          ),
                        ),
                        child: ClipOval(
                          child: Image.file(
                            File(userDataProvider
                                .personalInfo!.profilePicturePath!),
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                Container(
                              color: theme.colorScheme.primary,
                              child: Center(
                                child: Text(
                                  userDataProvider.personalInfo!.fullName
                                          .isNotEmpty
                                      ? userDataProvider
                                          .personalInfo!.fullName[0]
                                          .toUpperCase()
                                      : '?',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            userDataProvider.personalInfo!.fullName,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          if (userDataProvider.personalInfo!.email != null &&
                              userDataProvider.personalInfo!.email!.isNotEmpty)
                            Text(
                              userDataProvider.personalInfo!.email!,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.textTheme.bodySmall?.color
                                    ?.withOpacity(0.7),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                )
              : Text(
                  'No personal information added',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.textTheme.bodySmall?.color?.withOpacity(0.6),
                  ),
                ),
          content: const PersonalInfoSection(showHeader: false),
        ),
        const SizedBox(height: 16),

        // Work Experience Section - Wrapped
        ProfileSectionCard(
          title: 'Work Experience',
          icon: Icons.work_outline,
          count: userDataProvider.experiences.length,
          actionLabel: '',
          onActionPressed: null,
          collapsedPreview: userDataProvider.experiences.isEmpty
              ? Text(
                  'No work experience added',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.textTheme.bodySmall?.color?.withOpacity(0.6),
                  ),
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: userDataProvider.experiences.map((exp) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Icon(
                              Icons.business,
                              size: 14,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  exp.position,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  exp.company,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.textTheme.bodySmall?.color
                                        ?.withOpacity(0.7),
                                    fontSize: 11,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
          content: const WorkExperienceSection(showHeader: false),
        ),
        const SizedBox(height: 16),

        // Skills Section - Wrapped
        ProfileSectionCard(
          title: 'Skills',
          icon: Icons.psychology_outlined,
          count: userDataProvider.skills.length,
          actionLabel: 'Add',
          actionIcon: Icons.add,
          onActionPressed: () => SkillsSection.showAddSkillDialog(context),
          collapsedPreview: userDataProvider.skills.isEmpty
              ? Text(
                  'No skills added',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.textTheme.bodySmall?.color?.withOpacity(0.6),
                  ),
                )
              : Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: userDataProvider.skills.take(8).map((skill) {
                    final levelColor = _getSkillLevelColor(theme, skill.level);
                    return Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: levelColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: levelColor.withOpacity(0.4),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            skill.name,
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.w500,
                              color: levelColor,
                            ),
                          ),
                          if (skill.level != null) ...[
                            const SizedBox(width: 4),
                            Container(
                              width: 5,
                              height: 5,
                              decoration: BoxDecoration(
                                color: levelColor,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ],
                        ],
                      ),
                    );
                  }).toList(),
                ),
          content: const SkillsSection(showHeader: false),
        ),
        const SizedBox(height: 16),

        // Languages Section - Wrapped
        ProfileSectionCard(
          title: 'Languages',
          icon: Icons.language,
          count: userDataProvider.languages.length,
          actionLabel: 'Add',
          actionIcon: Icons.add,
          onActionPressed: () =>
              LanguagesSection.showAddLanguageDialog(context),
          collapsedPreview: userDataProvider.languages.isEmpty
              ? Text(
                  'No languages added',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.textTheme.bodySmall?.color?.withOpacity(0.6),
                  ),
                )
              : Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: userDataProvider.languages.take(8).map((language) {
                    final proficiencyColor = _getLanguageProficiencyColor(
                        theme, language.proficiency);
                    return Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: proficiencyColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: proficiencyColor.withOpacity(0.4),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            language.name,
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.w500,
                              color: proficiencyColor,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Container(
                            width: 5,
                            height: 5,
                            decoration: BoxDecoration(
                              color: proficiencyColor,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
          content: const LanguagesSection(showHeader: false),
        ),
        const SizedBox(height: 16),

        // Interests Section
        _buildInterestsSection(context),
        const SizedBox(height: 16),

        // Education Section - Wrapped
        _buildWrappedSection(
          context,
          title: 'Education',
          icon: Icons.school_outlined,
          count: userDataProvider.education.length,
          child: const EducationSection(showHeader: false),
        ),
        const SizedBox(height: 16),

        // Default Cover Letter Section
        _buildDefaultCoverLetterSection(context),
      ],
    );
  }

  Widget _buildWrappedSection(
    BuildContext context, {
    required String title,
    required IconData icon,
    required int count,
    required Widget child,
    VoidCallback? onAdd,
  }) {
    final theme = Theme.of(context);

    return ProfileSectionCard(
      title: title,
      icon: icon,
      count: count,
      actionLabel: onAdd != null ? 'Add' : '',
      actionIcon: Icons.add,
      onActionPressed: onAdd,
      collapsedPreview: Text(
        count == 0
            ? 'No ${title.toLowerCase()} added'
            : '$count item${count == 1 ? '' : 's'}',
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.textTheme.bodySmall?.color?.withOpacity(0.6),
        ),
      ),
      content: child,
    );
  }

  // Helper methods for chip colors
  Color _getSkillLevelColor(ThemeData theme, SkillLevel? level) {
    if (level == null) return theme.colorScheme.primary;

    switch (level) {
      case SkillLevel.beginner:
        return Colors.blue;
      case SkillLevel.intermediate:
        return Colors.green;
      case SkillLevel.advanced:
        return Colors.orange;
      case SkillLevel.expert:
        return Colors.purple;
    }
  }

  Color _getLanguageProficiencyColor(
      ThemeData theme, LanguageProficiency proficiency) {
    switch (proficiency) {
      case LanguageProficiency.basic:
        return Colors.blue;
      case LanguageProficiency.intermediate:
        return Colors.lightBlue;
      case LanguageProficiency.advanced:
        return Colors.green;
      case LanguageProficiency.fluent:
        return Colors.orange;
      case LanguageProficiency.native:
        return Colors.purple;
    }
  }

  Widget _buildInterestsSection(BuildContext context) {
    final userDataProvider = context.watch<UserDataProvider>();
    final interests = userDataProvider.interests;
    final theme = Theme.of(context);

    return ProfileSectionCard(
      title: 'Interests',
      icon: Icons.interests_outlined,
      count: interests.length,
      actionLabel: 'Add',
      actionIcon: Icons.add,
      onActionPressed: () => _addInterest(context, userDataProvider),
      collapsedPreview: interests.isEmpty
          ? Text(
              'No interests added yet',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.textTheme.bodySmall?.color?.withOpacity(0.6),
              ),
            )
          : Wrap(
              spacing: 8,
              runSpacing: 8,
              children: interests.take(8).map((i) {
                final color = theme.colorScheme.primary;
                return Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: color.withOpacity(0.4),
                    ),
                  ),
                  child: Text(
                    i.name,
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w500,
                      color: color,
                    ),
                  ),
                );
              }).toList(),
            ),
      content: interests.isEmpty
          ? UIUtils.buildEmptyState(
              context,
              icon: Icons.interests_outlined,
              title: 'No Interests Added',
              message: 'Add your hobbies and interests to personalize your CV.',
              action: FilledButton.icon(
                onPressed: () => _addInterest(context, userDataProvider),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Add Interest'),
              ),
            )
          : Wrap(
              spacing: 10,
              runSpacing: 10,
              children: interests.map((interest) {
                final color = theme.colorScheme.primary;
                return Container(
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: color.withOpacity(0.4),
                    ),
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () =>
                          _editInterest(context, userDataProvider, interest),
                      borderRadius: BorderRadius.circular(8),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              interest.name,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: color,
                              ),
                            ),
                            const SizedBox(width: 6),
                            InkWell(
                              onTap: () => _deleteInterest(
                                  context, userDataProvider, interest),
                              child: Icon(
                                Icons.close,
                                size: 14,
                                color: color.withOpacity(0.6),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
    );
  }

  Widget _buildProfileSummarySection(BuildContext context) {
    final userDataProvider = context.watch<UserDataProvider>();
    final profileSummary = userDataProvider.profileSummary;
    final theme = Theme.of(context);
    final controller = TextEditingController(text: profileSummary);

    return CollapsibleCard(
      title: 'Profile Summary',
      subtitle: 'Default summary for new job applications',
      cardDecoration: UIUtils.getCardDecoration(context),
      collapsedSummary: Text(
        profileSummary.isEmpty
            ? 'No profile summary set'
            : '${profileSummary.split('\n').first.substring(0, profileSummary.split('\n').first.length > 50 ? 50 : profileSummary.split('\n').first.length)}...',
        style: theme.textTheme.bodySmall,
      ),
      expandedContent: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'This summary will be used as the starting point for all new job applications. '
            'You can customize it for each specific job.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: controller,
            maxLines: 4,
            decoration: InputDecoration(
              hintText: 'Enter your professional summary...\n\n'
                  'Example: Experienced professional with 5+ years in software development, '
                  'specializing in full-stack solutions and team leadership.',
              border: const OutlineInputBorder(),
              filled: true,
              fillColor: theme.colorScheme.surface,
            ),
            onChanged: (value) {
              userDataProvider.updateProfileSummary(value);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDefaultCoverLetterSection(BuildContext context) {
    final userDataProvider = context.watch<UserDataProvider>();
    final coverLetterBody = userDataProvider.defaultCoverLetterBody;
    final theme = Theme.of(context);
    final controller = TextEditingController(text: coverLetterBody);
    final paragraphCount =
        coverLetterBody.split('\n\n').where((p) => p.trim().isNotEmpty).length;

    return ProfileSectionCard(
      title: 'Default Cover Letter',
      icon: Icons.article_outlined,
      count: paragraphCount,
      actionLabel: '',
      onActionPressed: null,
      collapsedPreview: Text(
        coverLetterBody.isEmpty
            ? 'No default cover letter set'
            : '${paragraphCount} paragraph${paragraphCount == 1 ? '' : 's'}',
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.textTheme.bodySmall?.color?.withOpacity(0.6),
        ),
      ),
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'This text will be used as the default body for new cover letters. '
            'You can customize it for each job application later.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.textTheme.bodySmall?.color?.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: controller,
            minLines: 8,
            maxLines: null,
            decoration: InputDecoration(
              hintText: 'Enter your default cover letter body...\n\n'
                  'Example:\nDear Hiring Manager,\n\n'
                  'I am writing to express my interest in the [Position] role at [Company]...',
              border: const OutlineInputBorder(),
              filled: true,
              fillColor: theme.colorScheme.surface,
            ),
            onChanged: (value) {
              userDataProvider.updateDefaultCoverLetterBody(value);
            },
          ),
        ],
      ),
    );
  }

  // Interest management helpers
  Future<void> _addInterest(
    BuildContext context,
    UserDataProvider provider,
  ) async {
    final result = await showDialog<Interest>(
      context: context,
      builder: (context) => const InterestEditDialog(),
    );

    if (result != null) {
      provider.addInterest(result);
    }
  }

  Future<void> _editInterest(
    BuildContext context,
    UserDataProvider provider,
    Interest interest,
  ) async {
    final result = await showDialog<Interest>(
      context: context,
      builder: (context) => InterestEditDialog(interest: interest),
    );

    if (result != null) {
      provider.updateInterest(result);
    }
  }

  Future<void> _deleteInterest(
    BuildContext context,
    UserDataProvider provider,
    Interest interest,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Interest'),
        content: Text('Remove "${interest.name}"?'),
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
      provider.deleteInterest(interest.id);
    }
  }
}
