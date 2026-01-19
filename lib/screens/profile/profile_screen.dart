import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import '../../providers/user_data_provider.dart';
import '../../models/user_data/skill.dart';
import '../../models/user_data/language.dart';
import '../../models/master_profile.dart';
import '../../constants/app_constants.dart';
import '../../dialogs/unified_import_dialog.dart';
import '../../dialogs/master_profile_pdf_dialog.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_card.dart';
import '../../widgets/profile_section_card.dart';
import '../../widgets/profile_long_text_editor.dart';
import '../../utils/ui_utils.dart';
import '../../utils/dialog_utils.dart';
import '../templates/sections/personal_info_section.dart';
import '../templates/sections/work_experience_section.dart';
import '../templates/sections/skills_section.dart';
import '../templates/sections/languages_section.dart';
import '../templates/sections/education_section.dart';
import '../templates/sections/interests_section.dart';

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
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header - Simple title with language switcher
            _buildHeader(context),
            const SizedBox(height: AppSpacing.lg),

            // Import/Export Card - Accent colored "Start Here" card
            _buildImportExportCard(context),
            const SizedBox(height: AppSpacing.md),

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

    return UIUtils.buildSectionHeader(
      context,
      title: 'Profile Template',
      subtitle:
          'Start here! Fill out your master profile data once, then use it for all job applications.',
      icon: Icons.account_circle_outlined,
      action: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Delete Button (only if data exists)
          if (userDataProvider.hasData) ...[
            IconButton.filledTonal(
              onPressed: () => _confirmDeleteProfile(context),
              icon: const Icon(Icons.delete_outline, size: 20),
              tooltip: 'Clear ${currentLang.code.toUpperCase()} Profile',
              style: IconButton.styleFrom(
                backgroundColor: theme.colorScheme.error.withValues(alpha: 0.1),
                foregroundColor: theme.colorScheme.error,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: const EdgeInsets.all(10),
              ),
            ),
            const SizedBox(width: 12),
          ],

          // Language Switcher
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildLanguageToggle(
                context,
                userDataProvider,
                DocumentLanguage.en,
                currentLang == DocumentLanguage.en,
              ),
              const SizedBox(width: 4),
              _buildLanguageToggle(
                context,
                userDataProvider,
                DocumentLanguage.de,
                currentLang == DocumentLanguage.de,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildImportExportCard(BuildContext context) {
    final theme = Theme.of(context);

    return AppCardContainer(
      padding: EdgeInsets.zero,
      useAccentBorder: true,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              theme.colorScheme.primary.withOpacity(0.08),
              theme.colorScheme.primary.withOpacity(0.02),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(AppDimensions.cardBorderRadius),
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Row(
            children: [
              // Icon with accent
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withOpacity(0.15),
                  borderRadius:
                      BorderRadius.circular(AppDimensions.inputBorderRadius),
                ),
                child: Icon(
                  Icons.upload_file,
                  color: theme.colorScheme.primary,
                  size: 28,
                ),
              ),
              const SizedBox(width: AppSpacing.lg),
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
                          ),
                        ),
                        const SizedBox(width: 12),
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
                    const SizedBox(height: 4),
                    Text(
                      'Import YAML files to populate your profile data, or export your current profile for backup',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color:
                            theme.textTheme.bodySmall?.color?.withOpacity(0.8),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.lg),
              // Action buttons
              Row(
                children: [
                  AppCardActionButton(
                    label: 'Import',
                    icon: Icons.upload,
                    onPressed: () => _showImportDialog(context),
                    isFilled: true,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  AppCardActionButton(
                    label: 'Export',
                    icon: Icons.download,
                    onPressed: () => _showExportDialog(context),
                  ),
                ],
              ),
            ],
          ),
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

    return OutlinedButton(
      onPressed: () => provider.switchLanguage(language),
      style: OutlinedButton.styleFrom(
        backgroundColor: isSelected
            ? theme.colorScheme.primary.withOpacity(0.08)
            : Colors.transparent,
        foregroundColor: isSelected
            ? theme.colorScheme.primary
            : theme.textTheme.bodyMedium?.color,
        side: BorderSide(
          color: isSelected
              ? theme.colorScheme.primary
              : theme.colorScheme.outline.withOpacity(0.3),
          width: isSelected ? 1.5 : 1,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            language.flag,
            style: const TextStyle(fontSize: 16),
          ),
          const SizedBox(width: 6),
          Text(
            language.code.toUpperCase(),
            style: TextStyle(
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              letterSpacing: 0.5,
            ),
          ),
        ],
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
          UIUtils.showSuccess(context, 'Profile data imported successfully!');
        }
      }
    } catch (e) {
      if (context.mounted) {
        UIUtils.showError(context, 'Error selecting file: $e');
      }
    }
  }

  void _showExportDialog(BuildContext context) async {
    final provider = context.read<UserDataProvider>();
    final profile = provider.currentProfile;

    if (profile == null) {
      if (context.mounted) {
        UIUtils.showError(context, 'No profile data to export');
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
      if (info.linkedin != null) {
        buffer.writeln('  linkedin: "${info.linkedin}"');
      }
      if (info.website != null) buffer.writeln('  website: "${info.website}"');
      if (info.jobTitle != null) {
        buffer.writeln('  job_title: "${info.jobTitle}"');
      }

      // Profile summary is stored at MasterProfile level, not in PersonalInfo
      if (profile.profileSummary.isNotEmpty) {
        buffer.writeln('  profile_summary: |');
        for (final line in profile.profileSummary.split('\n')) {
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
        if (exp.location != null) {
          buffer.writeln('    location: "${exp.location}"');
        }
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
        if (skill.category != null) {
          buffer.writeln('    category: "${skill.category}"');
        }
        if (skill.level != null) {
          buffer.writeln('    level: "${skill.level!.name}"');
        }
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

  void _confirmDeleteProfile(BuildContext context) async {
    final provider = context.read<UserDataProvider>();
    final lang = provider.currentLanguage;

    final confirmed = await DialogUtils.showDeleteConfirmation(
      context,
      title: 'Delete ${lang.code.toUpperCase()} Profile?',
      message:
          'This will permanently clear all personal info, work experience, skills, and other data for the ${lang.code.toUpperCase()} profile. This cannot be undone.',
      confirmLabel: 'Delete Profile',
    );

    if (confirmed && context.mounted) {
      await provider.clearCurrentProfile();
      if (context.mounted) {
        context.showSuccessSnackBar(
            '${lang.code.toUpperCase()} profile data cleared');
      }
    }
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
          cardId: 'personal_info',
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
                                  userDataProvider
                                          .personalInfo!.fullName.isNotEmpty
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

        // Profile Summary Section
        _buildProfileSummarySection(context),
        const SizedBox(height: 16),

        // Work Experience Section - Wrapped
        ProfileSectionCard(
          cardId: 'work_experience',
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
          cardId: 'skills',
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
          cardId: 'languages',
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
        ProfileSectionCard(
          cardId: 'interests',
          title: 'Interests',
          icon: Icons.interests_outlined,
          count: userDataProvider.interests.length,
          actionLabel: 'Add',
          actionIcon: Icons.add,
          onActionPressed: () => InterestsSection.showAddDialog(context),
          collapsedPreview: userDataProvider.interests.isEmpty
              ? Text(
                  'No interests added yet',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.textTheme.bodySmall?.color?.withOpacity(0.6),
                  ),
                )
              : Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: userDataProvider.interests.take(10).map((i) {
                    final color = theme.colorScheme.primary;
                    return Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
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
          content: const InterestsSection(showHeader: false),
        ),
        const SizedBox(height: 16),

        // Education Section
        ProfileSectionCard(
          cardId: 'education',
          title: 'Education',
          icon: Icons.school_outlined,
          count: userDataProvider.education.length,
          actionLabel: 'Add',
          actionIcon: Icons.add,
          onActionPressed: () => EducationSection.showAddDialog(context),
          collapsedPreview: userDataProvider.education.isEmpty
              ? Text(
                  'No education added',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.textTheme.bodySmall?.color
                        ?.withValues(alpha: 0.6),
                  ),
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: userDataProvider.education.take(3).map((edu) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        children: [
                          Icon(
                            Icons.school,
                            size: 14,
                            color: theme.colorScheme.primary
                                .withValues(alpha: 0.7),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              '${edu.degree} - ${edu.institution}',
                              style: theme.textTheme.bodySmall?.copyWith(
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
          content: const EducationSection(showHeader: false),
        ),
        const SizedBox(height: 16),

        // Default Cover Letter Section
        _buildDefaultCoverLetterSection(context),
      ],
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

  Widget _buildProfileSummarySection(BuildContext context) {
    final userDataProvider = context.watch<UserDataProvider>();
    final profileSummary = userDataProvider.profileSummary;
    final theme = Theme.of(context);

    return ProfileSectionCard(
      cardId: 'profile_summary',
      title: 'Profile Summary',
      icon: Icons.description_outlined,
      count: profileSummary.isNotEmpty ? 1 : 0,
      actionLabel: 'Preview PDF',
      actionIcon: Icons.picture_as_pdf_outlined,
      onActionPressed: profileSummary.isNotEmpty
          ? () => _showMasterProfilePdfPreview(context, isCV: true)
          : null,
      collapsedPreview: Text(
        profileSummary.isEmpty
            ? 'No profile summary set'
            : '${profileSummary.split('\n').first.substring(0, profileSummary.split('\n').first.length > 50 ? 50 : profileSummary.split('\n').first.length)}${profileSummary.length > 50 ? '...' : ''}',
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.textTheme.bodySmall?.color?.withOpacity(0.6),
        ),
      ),
      content: ProfileLongTextEditor(
        initialValue: profileSummary,
        onSave: (val) => userDataProvider.updateProfileSummary(val),
        hintText: 'Enter your professional summary...\n\n'
            'Example: Experienced professional with 5+ years in software development, '
            'specializing in full-stack solutions and team leadership.',
        helpText:
            'This summary will be used as the starting point for all new job applications. '
            'You can customize it for each specific job.',
        minLines: 4,
      ),
    );
  }

  Widget _buildDefaultCoverLetterSection(BuildContext context) {
    final userDataProvider = context.watch<UserDataProvider>();
    final coverLetterBody = userDataProvider.defaultCoverLetterBody;
    final theme = Theme.of(context);
    final paragraphCount =
        coverLetterBody.split('\n\n').where((p) => p.trim().isNotEmpty).length;

    return ProfileSectionCard(
      cardId: 'default_cover_letter',
      title: 'Default Cover Letter',
      icon: Icons.article_outlined,
      count: paragraphCount,
      actionLabel: 'Preview PDF',
      actionIcon: Icons.picture_as_pdf_outlined,
      onActionPressed: coverLetterBody.isNotEmpty
          ? () => _showMasterProfilePdfPreview(context, isCV: false)
          : null,
      collapsedPreview: Text(
        coverLetterBody.isEmpty
            ? 'No default cover letter set'
            : '$paragraphCount paragraph${paragraphCount == 1 ? '' : 's'}',
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.textTheme.bodySmall?.color?.withOpacity(0.6),
        ),
      ),
      content: ProfileLongTextEditor(
        initialValue: coverLetterBody,
        onSave: (val) => userDataProvider.updateDefaultCoverLetterBody(val),
        hintText: 'Enter your default cover letter body...\n\n'
            'Example:\nDear Hiring Manager,\n\n'
            'I am writing to express my interest in the [Position] role at [Company]...',
        helpText:
            'This text will be used as the default body for new cover letters. '
            'You can customize it for each job application later.',
        minLines: 8,
      ),
    );
  }

  static void _showMasterProfilePdfPreview(
    BuildContext context, {
    required bool isCV,
  }) async {
    final userDataProvider = context.read<UserDataProvider>();
    final profile = userDataProvider.currentProfile;

    if (profile == null) {
      UIUtils.showError(context, 'No profile data available');
      return;
    }

    await showDialog(
      context: context,
      builder: (context) => MasterProfilePdfDialog(
        profile: profile,
        isCV: isCV,
      ),
    );
  }
}
