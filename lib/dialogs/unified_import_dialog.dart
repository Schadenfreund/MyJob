import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
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

  // Target profile language — local state, no global side effects
  String? _targetLanguageCode;

  // CV import options
  bool _importPersonalInfo = true;
  bool _importSkills = true;
  bool _importLanguages = true;
  bool _importInterests = true;
  bool _importWorkExperience = true;
  bool _importEducation = true;

  // YAML editor — auto-opens on parse error to allow manual fixing inline.
  bool _showYamlEditor = false;
  bool _autoFixApplied = false;
  int? _errorLine;
  int? _errorColumn;
  late final _YamlHighlightController _yamlEditorController;
  final _editorScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _yamlEditorController = _YamlHighlightController();
    if (widget.preSelectedFile != null) {
      _selectedFile = widget.preSelectedFile;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _parseFile(widget.preSelectedFile!);
      });
    }
  }

  @override
  void dispose() {
    _yamlEditorController.dispose();
    _editorScrollController.dispose();
    super.dispose();
  }

  /// Effective target language, falling back to the provider's current code.
  String _effectiveTarget(UserDataProvider provider) =>
      _targetLanguageCode ?? provider.currentLanguageCode;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: Colors.transparent,
      child: Container(
        constraints: BoxConstraints(
            maxWidth: 600, maxHeight: _showYamlEditor ? 940 : 720),
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
                          // Error message (only when editor is not open)
                          if (_error != null && !_showYamlEditor) ...[
                            _buildError(context),
                            const SizedBox(height: 16),
                          ],

                          // Inline YAML editor (auto-opens on parse error)
                          if (_showYamlEditor) ...[
                            _buildYamlEditor(context),
                            const SizedBox(height: 16),
                          ],

                          // Auto-fix applied banner
                          if (_autoFixApplied && !_showYamlEditor) ...[
                            _buildAutoFixedBanner(context),
                            const SizedBox(height: 12),
                          ],

                          // Parse result preview
                          if (_parseResult != null &&
                              _parseResult!.success) ...[
                            _buildPreview(context),
                            const SizedBox(height: 20),
                            if (_parseResult is CvImportResult) ...[
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
    final allLanguages = AppLocalizations.of(context).availableLanguages;
    final existingCodes = userDataProvider.profileLanguageCodes.toSet();
    final selectedCode = _effectiveTarget(userDataProvider);

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
                context.tr('import_dialog_target_profile'),
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
                  children: allLanguages.asMap().entries.expand((entry) {
                    final idx = entry.key;
                    final lang = entry.value;
                    return [
                      if (idx > 0)
                        Container(
                          width: 1,
                          height: 32,
                          color: theme.colorScheme.outline
                              .withValues(alpha: 0.2),
                        ),
                      _buildProfileChip(
                        context,
                        lang.code,
                        lang.flag,
                        isSelected: lang.code == selectedCode,
                        hasProfile: existingCodes.contains(lang.code),
                      ),
                    ];
                  }).toList(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProfileChip(
    BuildContext context,
    String langCode,
    String flag, {
    required bool isSelected,
    required bool hasProfile,
  }) {
    final theme = Theme.of(context);

    return Material(
      color: isSelected
          ? theme.colorScheme.primary.withValues(alpha: 0.12)
          : Colors.transparent,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: () => setState(() => _targetLanguageCode = langCode),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(flag, style: const TextStyle(fontSize: 12)),
              const SizedBox(width: 4),
              Text(
                langCode.toUpperCase(),
                style: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected
                      ? theme.colorScheme.primary
                      : theme.textTheme.bodyMedium?.color
                          ?.withValues(alpha: 0.7),
                  letterSpacing: 0.5,
                ),
              ),
              if (!hasProfile) ...[
                const SizedBox(width: 5),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.secondary
                        .withValues(alpha: isSelected ? 0.25 : 0.15),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'NEW',
                    style: TextStyle(
                      fontSize: 8,
                      fontWeight: FontWeight.w800,
                      color: theme.colorScheme.secondary,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
              ],
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
                context.tr(item.label),
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
              if (_parseResult case final CvImportResult cv) ...[
                _buildFilterChip(
                  context,
                  label: context.tr('personal_info'),
                  icon: Icons.person_rounded,
                  selected: _importPersonalInfo,
                  onSelected: (v) => setState(() => _importPersonalInfo = v),
                  enabled: cv.personalInfo != null,
                ),
                _buildFilterChip(
                  context,
                  label: context.tr('skills'),
                  icon: Icons.construction_rounded,
                  selected: _importSkills,
                  onSelected: (v) => setState(() => _importSkills = v),
                  enabled: cv.skills.isNotEmpty,
                ),
                _buildFilterChip(
                  context,
                  label: context.tr('languages_section'),
                  icon: Icons.language_rounded,
                  selected: _importLanguages,
                  onSelected: (v) => setState(() => _importLanguages = v),
                  enabled: cv.languages.isNotEmpty,
                ),
                _buildFilterChip(
                  context,
                  label: context.tr('interests'),
                  icon: Icons.favorite_rounded,
                  selected: _importInterests,
                  onSelected: (v) => setState(() => _importInterests = v),
                  enabled: cv.interests.isNotEmpty,
                ),
                _buildFilterChip(
                  context,
                  label: context.tr('work_experience'),
                  icon: Icons.work_rounded,
                  selected: _importWorkExperience,
                  onSelected: (v) => setState(() => _importWorkExperience = v),
                  enabled: cv.workExperiences.isNotEmpty,
                ),
                _buildFilterChip(
                  context,
                  label: context.tr('education'),
                  icon: Icons.school_rounded,
                  selected: _importEducation,
                  onSelected: (v) => setState(() => _importEducation = v),
                  enabled: cv.education.isNotEmpty,
                ),
              ],
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
        crossAxisAlignment: CrossAxisAlignment.start,
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
    setState(() => _isLoading = true);
    try {
      final content = await file.readAsString();
      await _parseContent(content, file.path);
    } catch (e) {
      setState(() {
        _error = 'Failed to read file: $e';
        _isLoading = false;
      });
    }
  }

  /// Shared parse path used by both the initial file load and the in-dialog
  /// re-parse after manual editing.
  Future<void> _parseContent(String content, String filePath) async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    var result = await UnifiedYamlImportService()
        .importYamlString(content, filePath: filePath);

    // On the first failure (not yet in editor mode), try auto-fix silently.
    if (result is ImportError && !_showYamlEditor) {
      final fixed = UnifiedYamlImportService.autoFixYaml(content);
      if (fixed != content) {
        final fixedResult = await UnifiedYamlImportService()
            .importYamlString(fixed, filePath: filePath);
        if (fixedResult.success) {
          setState(() {
            _parseResult = fixedResult;
            _error = null;
            _errorLine = null;
            _errorColumn = null;
            _showYamlEditor = false;
            _isLoading = false;
            _autoFixApplied = true;
          });
          return;
        }
        // Partial fix: load the improved content into the editor so the
        // remaining error is easier to find and fix manually.
        content = fixed;
        result = fixedResult;
      }
    }

    if (result case ImportError(:final error)) {
      final line = _extractErrorLine(error);
      final col = _extractErrorColumn(error);
      if (!_showYamlEditor) {
        _yamlEditorController.text = content;
      }
      if (line != null && line != _errorLine) _selectErrorLine(line);
      setState(() {
        _error = error;
        _errorLine = line;
        _errorColumn = col;
        _showYamlEditor = true;
        _isLoading = false;
      });
      if (line != null) {
        WidgetsBinding.instance.addPostFrameCallback(
          (_) => _scrollEditorToErrorLine(),
        );
      }
      return;
    }

    setState(() {
      _parseResult = result;
      _error = null;
      _errorLine = null;
      _errorColumn = null;
      _showYamlEditor = false;
      _isLoading = false;
      _autoFixApplied = false;
    });
  }

  Future<void> _performImport() async {
    final result = _parseResult;
    if (result == null || !result.success) return;

    setState(() => _isLoading = true);

    try {
      switch (result) {
        case CvImportResult():
          await _importCvData(result);
        case CoverLetterImportResult():
          await _importCoverLetter(result);
        case ImportError():
          return; // unreachable — guarded above
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

  Future<void> _importCvData(CvImportResult result) async {
    final userDataProvider = context.read<UserDataProvider>();
    final targetCode = _effectiveTarget(userDataProvider);

    // Switch to the target profile, creating it if it doesn't exist yet.
    if (userDataProvider.currentLanguageCode != targetCode ||
        userDataProvider.currentProfile == null) {
      if (userDataProvider.profileLanguageCodes.contains(targetCode)) {
        await userDataProvider.switchProfile(targetCode);
      } else {
        await userDataProvider.addProfile(targetCode);
      }
    }

    // Import to Profile (UserDataProvider)
    if (_importPersonalInfo && result.personalInfo != null) {
      await userDataProvider.updatePersonalInfo(result.personalInfo!);
    }

    // Import profile summary
    if (result.profileSummary.isNotEmpty) {
      await userDataProvider.updateProfileSummary(result.profileSummary);
    }

    // Import default cover letter embedded in the CV file
    if (result.defaultCoverLetterBody.isNotEmpty) {
      await userDataProvider
          .updateDefaultCoverLetterBody(result.defaultCoverLetterBody);
    }

    // Always replace (clear existing data before import)
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

  // ---------------------------------------------------------------------------
  // YAML editor
  // ---------------------------------------------------------------------------

  /// Moves the cursor to [lineNumber] (1-based) by selecting the full line text.
  void _selectErrorLine(int lineNumber) {
    final text = _yamlEditorController.text;
    final lines = text.split('\n');
    if (lines.isEmpty) return;
    final target = (lineNumber - 1).clamp(0, lines.length - 1);
    var start = 0;
    for (var i = 0; i < target; i++) {
      start += lines[i].length + 1;
    }
    _yamlEditorController.selection = TextSelection(
      baseOffset: start,
      extentOffset: start + lines[target].length,
    );
  }

  static final _errorLineRe = RegExp(r'line (\d+)', caseSensitive: false);
  static final _errorColumnRe = RegExp(r'column (\d+)', caseSensitive: false);

  static int? _extractErrorLine(String error) {
    final m = _errorLineRe.firstMatch(error);
    return int.tryParse(m?.group(1) ?? '');
  }

  static int? _extractErrorColumn(String error) {
    final m = _errorColumnRe.firstMatch(error);
    return int.tryParse(m?.group(1) ?? '');
  }

  /// Re-runs the parser against the editor's current text.
  Future<void> _reparseEditorContent() async {
    await _parseContent(
      _yamlEditorController.text,
      _selectedFile?.path ?? '',
    );
  }

  /// Applies heuristic auto-fixes to the editor content, updates the text, and
  /// re-parses.  If the content was already correct the text is left unchanged.
  Future<void> _autoFixAndReparse() async {
    final current = _yamlEditorController.text;
    final fixed = UnifiedYamlImportService.autoFixYaml(current);
    if (fixed != current) {
      _yamlEditorController.text = fixed;
    }
    await _parseContent(fixed, _selectedFile?.path ?? '');
  }

  static String _translateError(String error) {
    final lower = error.toLowerCase();
    if (lower.contains('expected a key while parsing') ||
        lower.contains('block mapping')) {
      return 'A list item or text block is not indented correctly.';
    }
    if (lower.contains("expected ':'")) {
      return 'A line is missing a colon, or its content is not indented enough.';
    }
    if (lower.contains('mapping values are not allowed')) {
      return 'An unexpected colon (:) was found on this line.';
    }
    if (lower.contains('did not find expected key') ||
        lower.contains('could not find expected')) {
      return 'A required key or structure is missing here.';
    }
    if (lower.contains('found character that cannot start any token')) {
      return 'An invalid character was found — check for special symbols.';
    }
    if (lower.contains('tab character')) {
      return 'Tab characters are not allowed — only spaces.';
    }
    return error.replaceFirst(RegExp(r'^line \d+,\s*column \d+:\s*'), '').trim();
  }

  static String _fixGuidance(String error) {
    final lower = error.toLowerCase();
    if (lower.contains('expected a key while parsing') ||
        lower.contains('block mapping') ||
        lower.contains("expected ':'")) {
      return 'Indent the highlighted line further so it sits under its parent key. '
          'Tap Auto-fix to correct indentation automatically.';
    }
    if (lower.contains('mapping values are not allowed')) {
      return 'If the value contains a colon, wrap it in quotes: key: "value: here"';
    }
    if (lower.contains('did not find expected key') ||
        lower.contains('could not find expected')) {
      return 'Each nesting level must be indented 2 spaces more than its parent.';
    }
    if (lower.contains('found character that cannot start any token')) {
      return 'Remove or replace the special character, or wrap the value in quotes.';
    }
    if (lower.contains('tab character')) {
      return 'Auto-fix replaces tabs with spaces automatically.';
    }
    return 'Check the indentation around the highlighted line, or tap Auto-fix.';
  }

  Widget _buildAutoFixedBanner(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: theme.colorScheme.secondary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
            color: theme.colorScheme.secondary.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Icon(Icons.auto_fix_high_rounded,
              size: 16, color: theme.colorScheme.secondary),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              context.tr('yaml_auto_fixed'),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.secondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Animates the editor scroll so the error line is visible with two lines
  /// of context above it.
  void _scrollEditorToErrorLine() {
    if (_errorLine == null || !_editorScrollController.hasClients) return;
    const contextLines = 2.0;
    final target = (_YamlEditorPainter.topPadding +
            (_errorLine! - 1 - contextLines) * _YamlEditorPainter.linePixelHeight)
        .clamp(0.0, _editorScrollController.position.maxScrollExtent);
    _editorScrollController.animateTo(
      target,
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOut,
    );
  }

  Widget _buildYamlEditor(BuildContext context) {
    final theme = Theme.of(context);
    final errorColor = theme.colorScheme.error;
    final hasError = _error != null;
    final msg = _error != null ? _translateError(_error!) : null;
    final guidance = _error != null ? _fixGuidance(_error!) : null;

    _yamlEditorController.errorLine = _errorLine;

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: hasError
              ? errorColor.withValues(alpha: 0.4)
              : theme.colorScheme.outline.withValues(alpha: 0.25),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Header ──────────────────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.fromLTRB(14, 10, 8, 10),
            decoration: BoxDecoration(
              color: hasError
                  ? errorColor.withValues(alpha: 0.07)
                  : theme.colorScheme.surfaceContainerHighest
                      .withValues(alpha: 0.5),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(11),
                topRight: Radius.circular(11),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  hasError
                      ? Icons.warning_amber_rounded
                      : Icons.code_rounded,
                  size: 17,
                  color: hasError ? errorColor : theme.colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  hasError
                      ? context.tr('yaml_error')
                      : context.tr('yaml_editor'),
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: hasError ? errorColor : null,
                  ),
                ),
                if (hasError && _errorLine != null) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: errorColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      _errorColumn != null
                          ? '${context.tr('error_line_label')} $_errorLine, col $_errorColumn'
                          : '${context.tr('error_line_label')} $_errorLine',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: errorColor,
                        fontWeight: FontWeight.w800,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ],
                const Spacer(),
                IconButton(
                  onPressed: () => setState(() => _showYamlEditor = false),
                  icon: const Icon(Icons.close_rounded, size: 18),
                  constraints:
                      const BoxConstraints(minWidth: 32, minHeight: 32),
                  style: IconButton.styleFrom(
                    foregroundColor:
                        theme.colorScheme.onSurface.withValues(alpha: 0.55),
                  ),
                ),
              ],
            ),
          ),

          // ── Error banner ─────────────────────────────────────────────────────
          if (msg != null) ...[
            Divider(height: 1, color: errorColor.withValues(alpha: 0.2)),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.error_outline_rounded,
                          size: 14, color: errorColor),
                      const SizedBox(width: 7),
                      Expanded(
                        child: Text(
                          msg,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: errorColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (guidance != null) ...[
                    const SizedBox(height: 5),
                    Padding(
                      padding: const EdgeInsets.only(left: 21),
                      child: Text(
                        guidance,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],

          Divider(
              height: 1,
              color: theme.colorScheme.outline.withValues(alpha: 0.15)),

          // ── Editor with line-number gutter ───────────────────────────────────
          Container(
            height: 260,
            margin: const EdgeInsets.fromLTRB(8, 8, 8, 0),
            clipBehavior: Clip.hardEdge,
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest
                  .withValues(alpha: 0.35),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                  color: theme.colorScheme.outline.withValues(alpha: 0.15)),
            ),
            child: Stack(
              fit: StackFit.expand,
              children: [
                AnimatedBuilder(
                  animation: Listenable.merge(
                      [_editorScrollController, _yamlEditorController]),
                  builder: (context, _) {
                    final scrollOffset = _editorScrollController.hasClients
                        ? _editorScrollController.offset
                        : 0.0;
                    return CustomPaint(
                      painter: _YamlEditorPainter(
                        lineCount: _yamlEditorController.lineCount,
                        errorLine: _errorLine,
                        errorColumn: _errorColumn,
                        scrollOffset: scrollOffset,
                        gutterBg: theme.colorScheme.surfaceContainerHighest,
                        gutterBorder:
                            theme.colorScheme.outline.withValues(alpha: 0.25),
                        errorLineBg: errorColor.withValues(alpha: 0.13),
                        lineNumberNormal: theme.colorScheme.outline,
                        lineNumberError: errorColor,
                        indentGuideColor: theme.colorScheme.outline
                            .withValues(alpha: 0.15),
                      ),
                    );
                  },
                ),
                TextField(
                  controller: _yamlEditorController,
                  scrollController: _editorScrollController,
                  maxLines: null,
                  expands: true,
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: _YamlEditorPainter.fontSize,
                    height: _YamlEditorPainter.lineHeightMultiplier,
                    color: theme.textTheme.bodyMedium?.color,
                  ),
                  strutStyle: const StrutStyle(
                    fontFamily: 'monospace',
                    fontSize: _YamlEditorPainter.fontSize,
                    height: _YamlEditorPainter.lineHeightMultiplier,
                    forceStrutHeight: true,
                  ),
                  decoration: const InputDecoration(
                    contentPadding: EdgeInsets.fromLTRB(
                      _YamlEditorPainter.gutterWidth + 8,
                      _YamlEditorPainter.topPadding,
                      14,
                      12,
                    ),
                    border: InputBorder.none,
                    isDense: true,
                  ),
                  keyboardType: TextInputType.multiline,
                ),
              ],
            ),
          ),

          // ── Footer: Auto-fix (primary) + Re-parse (secondary) ───────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
            child: Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: _isLoading ? null : _autoFixAndReparse,
                    icon: _isLoading
                        ? const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.auto_fix_high_rounded, size: 16),
                    label: Text(context.tr('auto_fix')),
                    style: FilledButton.styleFrom(
                      backgroundColor: theme.colorScheme.secondary,
                      foregroundColor: theme.colorScheme.onSecondary,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                      textStyle: theme.textTheme.labelMedium
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                OutlinedButton.icon(
                  onPressed: _isLoading ? null : _reparseEditorContent,
                  icon: const Icon(Icons.refresh_rounded, size: 16),
                  label: Text(context.tr('reparse')),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    textStyle: theme.textTheme.labelMedium
                        ?.copyWith(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _importCoverLetter(CoverLetterImportResult result) async {
    final userDataProvider = context.read<UserDataProvider>();
    final targetCode = _effectiveTarget(userDataProvider);

    // Switch to (or create) the user-selected target profile.
    if (userDataProvider.currentLanguageCode != targetCode ||
        userDataProvider.currentProfile == null) {
      if (userDataProvider.profileLanguageCodes.contains(targetCode)) {
        await userDataProvider.switchProfile(targetCode);
      } else {
        await userDataProvider.addProfile(targetCode);
      }
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

// -----------------------------------------------------------------------------
// YAML editor painter — gutter, line numbers, error-line highlight
// -----------------------------------------------------------------------------

class _YamlEditorPainter extends CustomPainter {
  static const double fontSize = 12.5;
  static const double lineHeightMultiplier = 1.55;
  static const double linePixelHeight = fontSize * lineHeightMultiplier;
  static const double topPadding = 12.0;
  static const double gutterWidth = 54.0;
  // Left edge where text content begins — matches TextField contentPadding.left.
  static const double _contentLeft = gutterWidth + 8;

  const _YamlEditorPainter({
    required this.lineCount,
    required this.errorLine,
    required this.errorColumn,
    required this.scrollOffset,
    required this.gutterBg,
    required this.gutterBorder,
    required this.errorLineBg,
    required this.lineNumberNormal,
    required this.lineNumberError,
    required this.indentGuideColor,
  });

  final int lineCount;
  final int? errorLine;
  final int? errorColumn;
  final double scrollOffset;
  final Color gutterBg;
  final Color gutterBorder;
  final Color errorLineBg;
  final Color lineNumberNormal;
  final Color lineNumberError;
  final Color indentGuideColor;

  @override
  void paint(Canvas canvas, Size size) {
    // ── Measure one monospace character for indent-guide placement ──────────
    final charTp = TextPainter(
      text: const TextSpan(
        text: '0',
        style: TextStyle(fontFamily: 'monospace', fontSize: fontSize),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    final charW = charTp.width;
    final indentStep = charW * 2; // 2 spaces per YAML indent level

    // ── Indent guides — thin vertical lines at every 2-space column ─────────
    // Drawn first so the gutter covers the portion that overlaps it.
    final guidePaint = Paint()
      ..color = indentGuideColor
      ..strokeWidth = 0.5;
    for (int n = 1; _contentLeft + n * indentStep < size.width - 4; n++) {
      final x = _contentLeft + n * indentStep;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), guidePaint);
    }

    // ── Gutter background ────────────────────────────────────────────────────
    canvas.drawRect(
      Rect.fromLTWH(0, 0, gutterWidth, size.height),
      Paint()..color = gutterBg,
    );
    canvas.drawLine(
      Offset(gutterWidth, 0),
      Offset(gutterWidth, size.height),
      Paint()
        ..color = gutterBorder
        ..strokeWidth = 1,
    );

    // ── Error-line background + column marker ────────────────────────────────
    if (errorLine != null) {
      final y = topPadding + (errorLine! - 1) * linePixelHeight - scrollOffset;
      if (y + linePixelHeight >= 0 && y <= size.height) {
        canvas.drawRect(
          Rect.fromLTWH(0, y, size.width, linePixelHeight),
          Paint()..color = errorLineBg,
        );
        // Thin vertical bar at the exact column where parsing failed.
        if (errorColumn != null && charW > 0) {
          final colX = _contentLeft + (errorColumn! - 1) * charW;
          if (colX >= _contentLeft && colX < size.width) {
            canvas.drawRect(
              Rect.fromLTWH(colX - 1, y, 2, linePixelHeight),
              Paint()..color = lineNumberError.withValues(alpha: 0.55),
            );
          }
        }
      }
    }

    // ── Line numbers, right-aligned in the gutter ────────────────────────────
    final tp = TextPainter(textDirection: TextDirection.ltr);
    for (var i = 0; i < lineCount; i++) {
      final y = topPadding + i * linePixelHeight - scrollOffset;
      if (y + linePixelHeight < 0) continue;
      if (y > size.height) break;

      final isError = errorLine != null && (i + 1) == errorLine;
      tp.text = TextSpan(
        text: '${i + 1}',
        style: TextStyle(
          fontFamily: 'monospace',
          fontSize: fontSize - 1,
          height: 1.0,
          color: isError ? lineNumberError : lineNumberNormal,
          fontWeight: isError ? FontWeight.bold : FontWeight.normal,
        ),
      );
      tp.layout(maxWidth: gutterWidth - 10);
      tp.paint(
        canvas,
        Offset(
          gutterWidth - tp.width - 6,
          y + (linePixelHeight - tp.height) / 2,
        ),
      );
    }
  }

  @override
  bool shouldRepaint(_YamlEditorPainter old) =>
      old.scrollOffset != scrollOffset ||
      old.errorLine != errorLine ||
      old.errorColumn != errorColumn ||
      old.lineCount != lineCount ||
      old.lineNumberNormal != lineNumberNormal ||
      old.lineNumberError != lineNumberError;
}

// -----------------------------------------------------------------------------
// YAML syntax-highlighting controller
// -----------------------------------------------------------------------------

class _YamlHighlightController extends TextEditingController {
  int? errorLine;
  int _lineCount = 1;

  _YamlHighlightController() {
    addListener(_updateLineCount);
  }

  int get lineCount => _lineCount;

  void _updateLineCount() {
    _lineCount = '\n'.allMatches(text).length + 1;
  }

  @override
  void dispose() {
    removeListener(_updateLineCount);
    super.dispose();
  }

  static final _keyRe = RegExp(r'^(\s*)([\w][\w\s-]*)(:)(.*)$');
  static final _listRe = RegExp(r'^(\s*)(-)(\s.*)$');
  static final _commentRe = RegExp(r'^\s*#');
  static final _blockScalarRe = RegExp(r'^\s*[|>]');

  @override
  TextSpan buildTextSpan(
      {required BuildContext context,
      TextStyle? style,
      required bool withComposing}) {
    final cs = Theme.of(context).colorScheme;
    final lines = text.split('\n');
    final children = <InlineSpan>[];
    for (var i = 0; i < lines.length; i++) {
      if (i > 0) children.add(const TextSpan(text: '\n'));
      children.add(_spanForLine(lines[i], (i + 1) == errorLine, style, cs));
    }
    return TextSpan(children: children, style: style);
  }

  InlineSpan _spanForLine(
      String line, bool isError, TextStyle? base, ColorScheme cs) {
    final base_ = base ?? const TextStyle();
    final errColor = isError ? cs.error : null;
    final indentBg = isError ? cs.error.withValues(alpha: 0.12) : null;

    // Returns a span for leading whitespace with optional error background.
    TextSpan indentSpan(String indent) => TextSpan(
          text: indent,
          style: indentBg != null
              ? base_.copyWith(backgroundColor: indentBg)
              : base_,
        );

    if (_commentRe.hasMatch(line)) {
      return TextSpan(
        text: line,
        style: base_.copyWith(
            color: errColor ?? cs.outline, fontStyle: FontStyle.italic),
      );
    }

    if (_blockScalarRe.hasMatch(line)) {
      return TextSpan(
          text: line, style: base_.copyWith(color: errColor ?? cs.secondary));
    }

    final km = _keyRe.firstMatch(line);
    if (km != null) {
      return TextSpan(style: base, children: [
        if (km.group(1)!.isNotEmpty) indentSpan(km.group(1)!),
        TextSpan(
            text: km.group(2),
            style: base_.copyWith(
                color: errColor ?? cs.primary, fontWeight: FontWeight.w600)),
        TextSpan(
            text: km.group(3),
            style: base_.copyWith(color: errColor ?? cs.outline)),
        TextSpan(text: km.group(4), style: base_.copyWith(color: errColor)),
      ]);
    }

    final lm = _listRe.firstMatch(line);
    if (lm != null) {
      return TextSpan(style: base, children: [
        if (lm.group(1)!.isNotEmpty) indentSpan(lm.group(1)!),
        TextSpan(
            text: lm.group(2),
            style: base_.copyWith(
                color: errColor ?? cs.secondary, fontWeight: FontWeight.bold)),
        TextSpan(text: lm.group(3), style: base_.copyWith(color: errColor)),
      ]);
    }

    // Fallback: split into indent + content for background highlighting.
    if (isError && line.isNotEmpty) {
      final trimmed = line.trimLeft();
      final indent = line.substring(0, line.length - trimmed.length);
      if (indent.isNotEmpty) {
        return TextSpan(style: base, children: [
          indentSpan(indent),
          TextSpan(text: trimmed, style: base_.copyWith(color: errColor)),
        ]);
      }
    }

    return TextSpan(
      text: line,
      style: errColor != null ? base_.copyWith(color: errColor) : base,
    );
  }
}
