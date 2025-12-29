import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';
import '../services/unified_yaml_import_service.dart';
import '../providers/user_data_provider.dart';
import '../providers/templates_provider.dart';
import '../models/cv_data.dart';

/// Unified YAML import dialog with auto-detection and smart UI
///
/// Features:
/// - Single file picker for all YAML types
/// - Auto-detects CV vs Cover Letter format
/// - Smart preview based on detected content
/// - Selective import options for CV data
/// - Merge vs Replace modes
/// - Routes data to appropriate providers
class UnifiedImportDialog extends StatefulWidget {
  const UnifiedImportDialog({super.key});

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
  bool _createTemplate = true; // Also create a CV template
  bool _mergeData = true;

  // Import state
  bool _importComplete = false;
  String? _importSummary;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560, maxHeight: 700),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            _buildHeader(context),
            const Divider(height: 1),

            // Content
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (!_importComplete) ...[
                      // File selector
                      _buildFileSelector(context),

                      // Error message
                      if (_error != null) ...[
                        const SizedBox(height: 16),
                        _buildError(context),
                      ],

                      // Parse result preview
                      if (_parseResult != null && _parseResult!.success) ...[
                        const SizedBox(height: 20),
                        _buildDetectedType(context),
                        const SizedBox(height: 16),
                        _buildPreview(context),
                        const SizedBox(height: 20),
                        if (_parseResult!.isCvData) ...[
                          _buildCvImportOptions(context),
                          const SizedBox(height: 16),
                          _buildImportMode(context),
                        ],
                      ],
                    ] else ...[
                      // Success state
                      _buildSuccessState(context),
                    ],
                  ],
                ),
              ),
            ),

            // Actions
            const Divider(height: 1),
            _buildActions(context),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              Icons.upload_file,
              color: theme.colorScheme.primary,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Import YAML',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Auto-detects CV or Cover Letter format',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.textTheme.bodySmall?.color
                        ?.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.close),
            style: IconButton.styleFrom(
              foregroundColor: theme.textTheme.bodySmall?.color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFileSelector(BuildContext context) {
    final theme = Theme.of(context);
    final hasFile = _selectedFile != null;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _isLoading ? null : _selectFile,
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            border: Border.all(
              color: hasFile ? theme.colorScheme.primary : theme.dividerColor,
              width: hasFile ? 2 : 1,
            ),
            borderRadius: BorderRadius.circular(12),
            color: hasFile
                ? theme.colorScheme.primary.withValues(alpha: 0.03)
                : theme.colorScheme.surfaceContainerHighest
                    .withValues(alpha: 0.3),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: hasFile
                      ? theme.colorScheme.primary.withValues(alpha: 0.1)
                      : theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  hasFile ? Icons.description : Icons.folder_open,
                  color: hasFile
                      ? theme.colorScheme.primary
                      : theme.textTheme.bodySmall?.color,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      hasFile
                          ? _selectedFile!.path
                              .split(Platform.pathSeparator)
                              .last
                          : 'Choose YAML File',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      hasFile
                          ? _truncatePath(_selectedFile!.path)
                          : 'Supports CV data and Cover Letter templates',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.textTheme.bodySmall?.color
                            ?.withValues(alpha: 0.7),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              if (_isLoading)
                const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else
                Icon(
                  hasFile ? Icons.check_circle : Icons.chevron_right,
                  color: hasFile
                      ? theme.colorScheme.primary
                      : theme.textTheme.bodySmall?.color
                          ?.withValues(alpha: 0.5),
                ),
            ],
          ),
        ),
      ),
    );
  }

  String _truncatePath(String path) {
    if (path.length <= 50) return path;
    final parts = path.split(Platform.pathSeparator);
    if (parts.length <= 3) return path;
    return '...${Platform.pathSeparator}${parts.sublist(parts.length - 3).join(Platform.pathSeparator)}';
  }

  Widget _buildDetectedType(BuildContext context) {
    final theme = Theme.of(context);
    final result = _parseResult!;

    final isCv = result.isCvData;
    final icon = isCv ? Icons.description : Icons.mail;
    final color = isCv ? theme.colorScheme.primary : Colors.green;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Detected: ${result.fileTypeDisplay}',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  isCv
                      ? 'Will update your Profile and optionally create a template'
                      : 'Will create a new Cover Letter template',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.textTheme.bodySmall?.color
                        ?.withValues(alpha: 0.7),
                  ),
                ),
              ],
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Content Preview',
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children:
              items.map((item) => _buildPreviewChip(context, item)).toList(),
        ),
      ],
    );
  }

  Widget _buildPreviewChip(BuildContext context, ImportSummaryItem item) {
    final theme = Theme.of(context);

    IconData iconData;
    switch (item.icon) {
      case 'person':
        iconData = Icons.person;
        break;
      case 'build':
        iconData = Icons.build;
        break;
      case 'language':
        iconData = Icons.language;
        break;
      case 'interests':
        iconData = Icons.interests;
        break;
      case 'work':
        iconData = Icons.work;
        break;
      case 'mail':
        iconData = Icons.mail;
        break;
      case 'edit':
        iconData = Icons.edit;
        break;
      default:
        iconData = Icons.check;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: theme.dividerColor.withValues(alpha: 0.5),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(iconData, size: 16, color: theme.colorScheme.primary),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                item.label,
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w600,
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Select what to import:',
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _buildFilterChip(
              context,
              label: 'Personal Info',
              selected: _importPersonalInfo,
              onSelected: (v) => setState(() => _importPersonalInfo = v),
              enabled: _parseResult?.personalInfo != null,
            ),
            _buildFilterChip(
              context,
              label: 'Skills',
              selected: _importSkills,
              onSelected: (v) => setState(() => _importSkills = v),
              enabled: _parseResult?.skills.isNotEmpty ?? false,
            ),
            _buildFilterChip(
              context,
              label: 'Languages',
              selected: _importLanguages,
              onSelected: (v) => setState(() => _importLanguages = v),
              enabled: _parseResult?.languages.isNotEmpty ?? false,
            ),
            _buildFilterChip(
              context,
              label: 'Interests',
              selected: _importInterests,
              onSelected: (v) => setState(() => _importInterests = v),
              enabled: _parseResult?.interests.isNotEmpty ?? false,
            ),
            _buildFilterChip(
              context,
              label: 'Work Experience',
              selected: _importWorkExperience,
              onSelected: (v) => setState(() => _importWorkExperience = v),
              enabled: _parseResult?.workExperiences.isNotEmpty ?? false,
            ),
          ],
        ),
        const SizedBox(height: 12),
        // Create template option
        CheckboxListTile(
          value: _createTemplate,
          onChanged: (v) => setState(() => _createTemplate = v ?? true),
          title: const Text('Also create a CV template'),
          subtitle: Text(
            'Creates a ready-to-use document template',
            style: theme.textTheme.bodySmall,
          ),
          dense: true,
          contentPadding: EdgeInsets.zero,
          controlAffinity: ListTileControlAffinity.leading,
        ),
      ],
    );
  }

  Widget _buildFilterChip(
    BuildContext context, {
    required String label,
    required bool selected,
    required ValueChanged<bool> onSelected,
    bool enabled = true,
  }) {
    return FilterChip(
      label: Text(label),
      selected: selected && enabled,
      onSelected: enabled ? onSelected : null,
      showCheckmark: true,
      visualDensity: VisualDensity.compact,
    );
  }

  Widget _buildImportMode(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Import mode:',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildModeOption(
                  context,
                  title: 'Merge',
                  subtitle: 'Add to existing',
                  icon: Icons.merge,
                  isSelected: _mergeData,
                  onTap: () => setState(() => _mergeData = true),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildModeOption(
                  context,
                  title: 'Replace',
                  subtitle: 'Overwrite existing',
                  icon: Icons.swap_horiz,
                  isSelected: !_mergeData,
                  onTap: () => setState(() => _mergeData = false),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildModeOption(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isSelected
                ? theme.colorScheme.primary.withValues(alpha: 0.1)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color:
                  isSelected ? theme.colorScheme.primary : theme.dividerColor,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                size: 18,
                color: isSelected
                    ? theme.colorScheme.primary
                    : theme.textTheme.bodySmall?.color,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: isSelected ? theme.colorScheme.primary : null,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontSize: 11,
                        color: theme.textTheme.bodySmall?.color
                            ?.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              ),
              if (isSelected)
                Icon(
                  Icons.check_circle,
                  size: 18,
                  color: theme.colorScheme.primary,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildError(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.error.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border:
            Border.all(color: theme.colorScheme.error.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: theme.colorScheme.error, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _error!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.error,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessState(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_circle,
                color: Colors.green,
                size: 48,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Import Complete!',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
                color: Colors.green.shade700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _importSummary ?? 'Your data has been imported successfully.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.textTheme.bodySmall?.color,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActions(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          if (!_importComplete) ...[
            TextButton(
              onPressed: _isLoading ? null : () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            const SizedBox(width: 12),
            FilledButton.icon(
              onPressed:
                  (_parseResult != null && _parseResult!.success && !_isLoading)
                      ? _performImport
                      : null,
              icon: _isLoading
                  ? SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: theme.colorScheme.onPrimary,
                      ),
                    )
                  : const Icon(Icons.download_done, size: 18),
              label: Text(_isLoading ? 'Importing...' : 'Import'),
            ),
          ] else ...[
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Done'),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _selectFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['yaml', 'yml'],
        dialogTitle: 'Select YAML File',
      );

      if (result != null && result.files.single.path != null) {
        final file = File(result.files.single.path!);
        setState(() {
          _selectedFile = file;
          _error = null;
          _parseResult = null;
        });
        await _parseFile(file);
      }
    } catch (e) {
      setState(() {
        _error = 'Error selecting file: $e';
      });
    }
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

      setState(() {
        _isLoading = false;
        _importComplete = true;
      });
    } catch (e) {
      setState(() {
        _error = 'Import failed: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _importCvData() async {
    final userDataProvider = context.read<UserDataProvider>();
    final templatesProvider = context.read<TemplatesProvider>();
    final result = _parseResult!;

    final importedItems = <String>[];

    // Import to Profile (UserDataProvider)
    if (_importPersonalInfo && result.personalInfo != null) {
      await userDataProvider.updatePersonalInfo(result.personalInfo!);
      importedItems.add('personal info');
    }

    if (_importSkills && result.skills.isNotEmpty) {
      if (!_mergeData) {
        for (final skill in userDataProvider.skills) {
          await userDataProvider.deleteSkill(skill.id);
        }
      }
      for (final skill in result.skills) {
        await userDataProvider.addSkill(skill);
      }
      importedItems.add('${result.skills.length} skills');
    }

    if (_importLanguages && result.languages.isNotEmpty) {
      if (!_mergeData) {
        for (final lang in userDataProvider.languages) {
          await userDataProvider.deleteLanguage(lang.id);
        }
      }
      for (final lang in result.languages) {
        await userDataProvider.addLanguage(lang);
      }
      importedItems.add('${result.languages.length} languages');
    }

    if (_importInterests && result.interests.isNotEmpty) {
      if (!_mergeData) {
        for (final interest in userDataProvider.interests) {
          await userDataProvider.deleteInterest(interest.id);
        }
      }
      for (final interest in result.interests) {
        await userDataProvider.addInterest(interest);
      }
      importedItems.add('${result.interests.length} interests');
    }

    if (_importWorkExperience && result.workExperiences.isNotEmpty) {
      if (!_mergeData) {
        for (final exp in userDataProvider.workExperiences) {
          await userDataProvider.deleteWorkExperience(exp.id);
        }
      }
      for (final exp in result.workExperiences) {
        await userDataProvider.addWorkExperience(exp);
      }
      importedItems.add('${result.workExperiences.length} work experiences');
    }

    // Optionally create a CV Template
    if (_createTemplate) {
      final templateName = result.personalInfo?.fullName ?? 'Imported CV';
      final skills = result.skills.map((s) => s.name).toList();
      final languages = result.languages.map((lang) {
        return LanguageSkill(
          language: lang.name,
          level: lang.proficiency.toString().split('.').last,
        );
      }).toList();
      final interests = result.interests.map((i) => i.name).toList();

      ContactDetails? contactDetails;
      if (result.personalInfo != null) {
        final pi = result.personalInfo!;
        contactDetails = ContactDetails(
          fullName: pi.fullName,
          jobTitle: pi.jobTitle,
          email: pi.email,
          phone: pi.phone,
          address: _buildAddress(pi.address, pi.city, pi.country),
          linkedin: pi.linkedin,
          website: pi.website,
        );
      }

      final experiences = result.workExperiences.map((exp) {
        return Experience(
          company: exp.company,
          title: exp.position,
          startDate: _formatDate(exp.startDate),
          endDate: exp.endDate != null
              ? _formatDate(exp.endDate!)
              : (exp.isCurrent ? 'Present' : null),
          description: exp.description,
          bullets: exp.responsibilities,
        );
      }).toList();

      final template = await templatesProvider.createCvTemplate(
        name: templateName,
        profile: result.personalInfo?.profileSummary ?? '',
        skills: skills,
        contactDetails: contactDetails,
      );

      await templatesProvider.updateCvTemplate(
        template.copyWith(
          languages: languages,
          interests: interests,
          experiences: experiences,
          lastModified: DateTime.now(),
        ),
      );

      importedItems.add('CV template');
    }

    _importSummary = 'Imported: ${importedItems.join(', ')}';
  }

  String? _buildAddress(String? address, String? city, String? country) {
    final parts =
        [address, city, country].where((p) => p != null && p.isNotEmpty);
    return parts.isNotEmpty ? parts.join(', ') : null;
  }

  String _formatDate(DateTime date) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    return '${months[date.month - 1]} ${date.year}';
  }

  Future<void> _importCoverLetter() async {
    final templatesProvider = context.read<TemplatesProvider>();
    final result = _parseResult!;

    final body = result.paragraphs.join('\n\n');

    await templatesProvider.createCoverLetterTemplate(
      name: result.templateName ?? 'Imported Cover Letter',
      greeting: result.greeting ?? '',
      body: body,
      closing: result.closing ?? '',
    );

    _importSummary = 'Created cover letter template: ${result.templateName}';
  }
}
