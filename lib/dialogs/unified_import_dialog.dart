import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants/app_constants.dart';
import '../localization/app_localizations.dart';
import '../providers/user_data_provider.dart';
import '../services/unified_yaml_import_service.dart';

/// Unified YAML import dialog with auto-detection and smart UI
///
/// Features:
/// - Single file picker for all YAML types
/// - Auto-detects CV vs Cover Letter format
/// - Detects language (English/German)
/// - Smart preview based on detected content
/// - Selective import options for CV data
/// - Always replaces existing data
/// - Cover letters import to Profile tab's default cover letter
/// - Routes data to appropriate providers based on language
class UnifiedImportDialog extends StatefulWidget {
  const UnifiedImportDialog({super.key, this.preSelectedFile});

  final File? preSelectedFile;

  @override
  State<UnifiedImportDialog> createState() => _UnifiedImportDialogState();
}

class _UnifiedImportDialogState extends State<UnifiedImportDialog> {
  File? _selectedFile;
  bool _isLoading = false;
  String? _error;
  UnifiedImportResult? _parseResult;

  // CV import options
  bool _importPersonalInfo = true;
  bool _importSkills = true;
  bool _importLanguages = true;
  bool _importInterests = true;
  bool _importWorkExperience = true;
  bool _importEducation = true;

  @override
  void initState() {
    super.initState();
    // If a file is pre-selected, parse it immediately
    if (widget.preSelectedFile != null) {
      _selectedFile = widget.preSelectedFile;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _parseFile(widget.preSelectedFile!);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: Colors.transparent,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 600, maxHeight: 720),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            _buildHeader(context),

            // Content
            Flexible(
              child: _isLoading && _parseResult == null
                  ? _buildLoadingState(context)
                  : SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Error message
                          if (_error != null) ...[
                            _buildError(context),
                            const SizedBox(height: 16),
                          ],

                          // Parse result preview
                          if (_parseResult != null &&
                              _parseResult!.success) ...[
                            _buildPreview(context),
                            const SizedBox(height: 20),
                            if (_parseResult!.isCvData) ...[
                              _buildCvImportOptions(context),
                            ],
                          ],
                        ],
                      ),
                    ),
            ),

            // Info banner and Actions
            if (!(_isLoading && _parseResult == null)) ...[
              if (_parseResult != null && _parseResult!.success) ...[
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
                  child: _parseResult!.isCvData
                      ? _buildInfoBanner(
                          context,
                          context.tr('import_cv_info'),
                          Icons.info_outline_rounded,
                        )
                      : _buildInfoBanner(
                          context,
                          context.tr('import_cl_info'),
                          Icons.info_outline_rounded,
                        ),
                ),
              ],
              _buildActions(context),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final theme = Theme.of(context);
    final fileName =
        _selectedFile?.path.split(Platform.pathSeparator).last ?? '';
    final userDataProvider = context.watch<UserDataProvider>();
    final currentLang = userDataProvider.currentLanguage;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            theme.colorScheme.primary.withValues(alpha: 0.08),
            theme.colorScheme.primary.withValues(alpha: 0.03),
          ],
        ),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: theme.colorScheme.primary.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.upload_file_rounded,
                  color: theme.colorScheme.onPrimary,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.tr('import_yaml'),
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (fileName.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        fileName,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close_rounded),
                style: IconButton.styleFrom(
                  foregroundColor: theme.textTheme.bodyMedium?.color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Text(
                context.tr('target_language'),
                style: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                  color:
                      theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.7),
                ),
              ),
              const SizedBox(width: 12),
              Container(
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: theme.colorScheme.outline.withValues(alpha: 0.2),
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
                      color: theme.colorScheme.outline.withValues(alpha: 0.2),
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
          ),
        ],
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
          ? theme.colorScheme.primary.withValues(alpha: 0.12)
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
                      ? theme.colorScheme.primary.withValues(alpha: 0.1)
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
                      : theme.textTheme.bodyMedium?.color
                          ?.withValues(alpha: 0.7),
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingState(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(48),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 48,
              height: 48,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              context.tr('analyzing_file'),
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              context.tr('detecting_content'),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoBanner(BuildContext context, String message, IconData icon) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            theme.colorScheme.primary.withValues(alpha: 0.06),
            theme.colorScheme.primary.withValues(alpha: 0.03),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.primary.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              size: 18,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: theme.textTheme.bodyMedium?.copyWith(
                color:
                    theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.85),
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPreview(BuildContext context) {
    final theme = Theme.of(context);
    final result = _parseResult!;
    final items = result.importSummary;

    if (items.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.dividerColor.withValues(alpha: 0.5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.preview_rounded,
                size: 18,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Text(
                context.tr('content_preview'),
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children:
                items.map((item) => _buildPreviewChip(context, item)).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildPreviewChip(BuildContext context, ImportSummaryItem item) {
    final theme = Theme.of(context);

    IconData iconData;
    switch (item.icon) {
      case 'person':
        iconData = Icons.person_rounded;
        break;
      case 'build':
        iconData = Icons.construction_rounded;
        break;
      case 'language':
        iconData = Icons.language_rounded;
        break;
      case 'interests':
        iconData = Icons.favorite_rounded;
        break;
      case 'work':
        iconData = Icons.work_rounded;
        break;
      case 'school':
        iconData = Icons.school_rounded;
        break;
      case 'mail':
        iconData = Icons.mail_rounded;
        break;
      case 'edit':
        iconData = Icons.edit_rounded;
        break;
      default:
        iconData = Icons.check_circle_rounded;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            theme.colorScheme.primary.withValues(alpha: 0.08),
            theme.colorScheme.primary.withValues(alpha: 0.04),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.primary.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(iconData, size: 16, color: theme.colorScheme.primary),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                item.label,
                style: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                item.detail,
                style: theme.textTheme.bodySmall?.copyWith(
                  fontSize: 11,
                  color:
                      theme.textTheme.bodySmall?.color?.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCvImportOptions(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.dividerColor.withValues(alpha: 0.5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.tune_rounded,
                size: 18,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Text(
                context.tr('select_what_to_import'),
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildFilterChip(
                context,
                label: context.tr('personal_info'),
                icon: Icons.person_rounded,
                selected: _importPersonalInfo,
                onSelected: (v) => setState(() => _importPersonalInfo = v),
                enabled: _parseResult?.personalInfo != null,
              ),
              _buildFilterChip(
                context,
                label: context.tr('skills'),
                icon: Icons.construction_rounded,
                selected: _importSkills,
                onSelected: (v) => setState(() => _importSkills = v),
                enabled: _parseResult?.skills.isNotEmpty ?? false,
              ),
              _buildFilterChip(
                context,
                label: context.tr('languages_section'),
                icon: Icons.language_rounded,
                selected: _importLanguages,
                onSelected: (v) => setState(() => _importLanguages = v),
                enabled: _parseResult?.languages.isNotEmpty ?? false,
              ),
              _buildFilterChip(
                context,
                label: context.tr('interests'),
                icon: Icons.favorite_rounded,
                selected: _importInterests,
                onSelected: (v) => setState(() => _importInterests = v),
                enabled: _parseResult?.interests.isNotEmpty ?? false,
              ),
              _buildFilterChip(
                context,
                label: context.tr('work_experience'),
                icon: Icons.work_rounded,
                selected: _importWorkExperience,
                onSelected: (v) => setState(() => _importWorkExperience = v),
                enabled: _parseResult?.workExperiences.isNotEmpty ?? false,
              ),
              _buildFilterChip(
                context,
                label: context.tr('education'),
                icon: Icons.school_rounded,
                selected: _importEducation,
                onSelected: (v) => setState(() => _importEducation = v),
                enabled: _parseResult?.education.isNotEmpty ?? false,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(
    BuildContext context, {
    required String label,
    required IconData icon,
    required bool selected,
    required ValueChanged<bool> onSelected,
    bool enabled = true,
  }) {
    final theme = Theme.of(context);
    final isActive = selected && enabled;
    final chipColor =
        enabled ? theme.colorScheme.primary : theme.colorScheme.outline;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: enabled ? () => onSelected(!selected) : null,
        borderRadius: BorderRadius.circular(20),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: isActive
                ? chipColor.withValues(alpha: 0.15)
                : theme.colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isActive
                  ? chipColor.withValues(alpha: 0.5)
                  : theme.dividerColor.withValues(alpha: 0.3),
              width: isActive ? 1.5 : 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Icon with background
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: isActive
                      ? chipColor.withValues(alpha: 0.2)
                      : theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(
                  icon,
                  size: 14,
                  color: isActive
                      ? chipColor
                      : theme.textTheme.bodyMedium?.color
                          ?.withValues(alpha: 0.5),
                ),
              ),
              const SizedBox(width: 8),
              // Label
              Text(
                label,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                  color: isActive
                      ? chipColor
                      : (enabled
                          ? theme.textTheme.bodyMedium?.color
                              ?.withValues(alpha: 0.7)
                          : theme.textTheme.bodyMedium?.color
                              ?.withValues(alpha: 0.4)),
                ),
              ),
              if (isActive) ...[
                const SizedBox(width: 6),
                Icon(
                  Icons.check_circle,
                  size: 16,
                  color: chipColor,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildError(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            theme.colorScheme.error.withValues(alpha: 0.1),
            theme.colorScheme.error.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.error.withValues(alpha: 0.3),
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: theme.colorScheme.error.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.error_outline_rounded,
              color: theme.colorScheme.error,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _error!,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.error,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActions(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          TextButton(
            onPressed: _isLoading ? null : () => Navigator.pop(context),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              minimumSize: const Size(0, 44),
            ),
            child: Text(context.tr('cancel')),
          ),
          const SizedBox(width: 12),
          FilledButton.icon(
            onPressed:
                (_parseResult != null && _parseResult!.success && !_isLoading)
                    ? _performImport
                    : null,
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              minimumSize: const Size(0, 44),
              backgroundColor: theme.colorScheme.primary,
              foregroundColor: theme.colorScheme.onPrimary,
              disabledBackgroundColor:
                  theme.colorScheme.primary.withValues(alpha: 0.3),
            ),
            icon: _isLoading
                ? SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: theme.colorScheme.onPrimary,
                    ),
                  )
                : const Icon(Icons.download_done_rounded, size: 20),
            label: Text(
              _isLoading ? context.tr('importing') : context.tr('import_now'),
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _parseFile(File file) async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final service = UnifiedYamlImportService();
      final result = await service.importYamlFile(file);

      if (!result.success) {
        setState(() {
          _error = result.error;
          _isLoading = false;
        });
        return;
      }

      setState(() {
        _parseResult = result;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Error parsing YAML: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _performImport() async {
    if (_parseResult == null || !_parseResult!.success) return;

    setState(() => _isLoading = true);

    try {
      if (_parseResult!.isCvData) {
        await _importCvData();
      } else if (_parseResult!.isCoverLetter) {
        await _importCoverLetter();
      }

      // Close dialog immediately after successful import
      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      setState(() {
        _error = 'Import failed: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _importCvData() async {
    final userDataProvider = context.read<UserDataProvider>();
    final result = _parseResult!;

    // Import to Profile (UserDataProvider)
    if (_importPersonalInfo && result.personalInfo != null) {
      await userDataProvider.updatePersonalInfo(result.personalInfo!);
    }

    // Import profile summary
    if (result.profileSummary.isNotEmpty) {
      await userDataProvider.updateProfileSummary(result.profileSummary);
    }

    //Always replace (clear existing data before import)
    if (_importSkills && result.skills.isNotEmpty) {
      for (final skill in userDataProvider.skills) {
        await userDataProvider.deleteSkill(skill.id);
      }
      for (final skill in result.skills) {
        await userDataProvider.addSkill(skill);
      }
    }

    if (_importLanguages && result.languages.isNotEmpty) {
      for (final lang in userDataProvider.languages) {
        await userDataProvider.deleteLanguage(lang.id);
      }
      for (final lang in result.languages) {
        await userDataProvider.addLanguage(lang);
      }
    }

    if (_importInterests && result.interests.isNotEmpty) {
      for (final interest in userDataProvider.interests) {
        await userDataProvider.deleteInterest(interest.id);
      }
      for (final interest in result.interests) {
        await userDataProvider.addInterest(interest);
      }
    }

    if (_importWorkExperience && result.workExperiences.isNotEmpty) {
      for (final exp in userDataProvider.experiences) {
        await userDataProvider.deleteExperience(exp.id);
      }
      for (final exp in result.workExperiences) {
        await userDataProvider.addExperience(exp);
      }
    }

    if (_importEducation && result.education.isNotEmpty) {
      for (final edu in userDataProvider.education) {
        await userDataProvider.deleteEducation(edu.id);
      }
      for (final edu in result.education) {
        await userDataProvider.addEducation(edu);
      }
    }
  }

  Future<void> _importCoverLetter() async {
    final userDataProvider = context.read<UserDataProvider>();
    final result = _parseResult!;

    // Detect language and switch to it if needed
    if (result.language != null) {
      final lang = result.language!.toLowerCase();
      DocumentLanguage targetLang;

      if (lang == 'german' || lang == 'de' || lang == 'deutsch') {
        targetLang = DocumentLanguage.de;
      } else {
        targetLang = DocumentLanguage.en;
      }

      // Switch to the target language
      await userDataProvider.switchLanguage(targetLang);
    }

    // Build the complete cover letter body
    final bodyParts = <String>[];

    if (result.greeting != null && result.greeting!.isNotEmpty) {
      bodyParts.add(result.greeting!);
    }

    if (result.paragraphs.isNotEmpty) {
      bodyParts.add(result.paragraphs.join('\n\n'));
    }

    if (result.closing != null && result.closing!.isNotEmpty) {
      bodyParts.add(result.closing!);
    }

    final fullBody = bodyParts.join('\n\n');

    // Update the default cover letter body for the current language
    await userDataProvider.updateDefaultCoverLetterBody(fullBody);
  }
}
