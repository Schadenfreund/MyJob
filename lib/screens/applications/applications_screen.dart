import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import '../../providers/applications_provider.dart';
import '../../providers/user_data_provider.dart';
import '../../providers/app_state.dart';
import '../../constants/app_constants.dart';
import '../../models/job_application.dart';
import '../../theme/app_theme.dart';
import '../../utils/application_status_helper.dart';
import '../../utils/ui_utils.dart';
import '../../utils/dialog_utils.dart';
import '../../utils/platform_utils.dart';
import '../../services/preferences_service.dart';
import '../../services/storage_service.dart';
import '../../services/application_export_service.dart';
import 'application_editor_dialog.dart';
import '../../dialogs/job_application_pdf_dialog.dart';
import '../job_cv_editor/job_cv_editor_screen.dart';
import 'widgets/compact_application_card.dart';
import '../../widgets/app_card.dart';
import '../../localization/app_localizations.dart';

/// Applications Screen - Modern job application tracking with statistics
class ApplicationsScreen extends StatefulWidget {
  const ApplicationsScreen({super.key});

  @override
  State<ApplicationsScreen> createState() => _ApplicationsScreenState();
}

class _ApplicationsScreenState extends State<ApplicationsScreen> {
  bool _statsExpanded = true;
  bool _activeExpanded = true;
  bool _successfulExpanded = true;
  bool _noResponseExpanded = true;
  bool _rejectedExpanded = false;
  String _timeRange = 'all';

  // Preference keys
  static const String _prefKeyStatsExpanded = 'apps_stats_expanded';
  static const String _prefKeyActiveExpanded = 'apps_active_expanded';
  static const String _prefKeySuccessfulExpanded = 'apps_successful_expanded';
  static const String _prefKeyNoResponseExpanded = 'apps_noresponse_expanded';
  static const String _prefKeyRejectedExpanded = 'apps_rejected_expanded';

  final _prefs = PreferencesService.instance;

  @override
  void initState() {
    super.initState();
    _initializePreferences();
  }

  Future<void> _initializePreferences() async {
    await _prefs.initialize();
    _loadExpandedStates();
  }

  void _loadExpandedStates() {
    setState(() {
      _statsExpanded =
          _prefs.getBool(_prefKeyStatsExpanded, defaultValue: true);
      _activeExpanded =
          _prefs.getBool(_prefKeyActiveExpanded, defaultValue: true);
      _successfulExpanded =
          _prefs.getBool(_prefKeySuccessfulExpanded, defaultValue: true);
      _noResponseExpanded =
          _prefs.getBool(_prefKeyNoResponseExpanded, defaultValue: true);
      _rejectedExpanded =
          _prefs.getBool(_prefKeyRejectedExpanded, defaultValue: false);
    });
  }

  /// Generic method to save expanded state (DRY principle)
  Future<void> _saveExpandedState(
    String prefKey,
    bool value,
    void Function(bool) updateState,
  ) async {
    await _prefs.setBool(prefKey, value);
    setState(() => updateState(value));
  }

  /// Save stats section expanded state
  Future<void> _saveStatsExpanded(bool value) => _saveExpandedState(
      _prefKeyStatsExpanded, value, (v) => _statsExpanded = v);

  /// Save active section expanded state
  Future<void> _saveActiveExpanded(bool value) => _saveExpandedState(
      _prefKeyActiveExpanded, value, (v) => _activeExpanded = v);

  /// Save successful section expanded state
  Future<void> _saveSuccessfulExpanded(bool value) => _saveExpandedState(
      _prefKeySuccessfulExpanded, value, (v) => _successfulExpanded = v);

  /// Save no response section expanded state
  Future<void> _saveNoResponseExpanded(bool value) => _saveExpandedState(
      _prefKeyNoResponseExpanded, value, (v) => _noResponseExpanded = v);

  /// Save rejected section expanded state
  Future<void> _saveRejectedExpanded(bool value) => _saveExpandedState(
      _prefKeyRejectedExpanded, value, (v) => _rejectedExpanded = v);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final applicationsProvider = context.watch<ApplicationsProvider>();

    if (applicationsProvider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (applicationsProvider.error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline,
                size: 48, color: theme.colorScheme.error),
            const SizedBox(height: 16),
            Text(context.tr('error_loading_applications'),
                style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            FilledButton.icon(
              onPressed: () => applicationsProvider.loadApplications(),
              icon: const Icon(Icons.refresh),
              label: Text(context.tr('retry')),
            ),
          ],
        ),
      );
    }

    return Container(
      color: theme.colorScheme.surface,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            UIUtils.buildSectionHeader(
              context,
              title: context.tr('applications_title'),
              subtitle: context.tr('applications_subtitle'),
              icon: Icons.assignment_outlined,
            ),
            const SizedBox(height: AppSpacing.lg),

            // Top Action Card
            _buildActionCard(context, applicationsProvider),
            const SizedBox(height: AppSpacing.md),

            // Search Bar
            _buildSearchBar(context, applicationsProvider),
            const SizedBox(height: AppSpacing.md),

            // Applications List
            _buildApplicationsList(context, applicationsProvider),
            const SizedBox(height: AppSpacing.lg),

            // Statistics Dashboard
            _buildStatisticsCard(context, applicationsProvider),
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // ACTION CARD
  // ===========================================================================

  Widget _buildActionCard(
      BuildContext context, ApplicationsProvider provider) {
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
          borderRadius:
              BorderRadius.circular(AppDimensions.cardBorderRadius),
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              // Icon with accent
              Container(
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(
                      AppDimensions.inputBorderRadius),
                ),
                child: Icon(
                  Icons.add_task_outlined,
                  color: theme.colorScheme.primary,
                  size: 24,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              // Text content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          context.tr('new_opportunity'),
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
                            context.tr('add_here'),
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
                    const SizedBox(height: 2),
                    Text(
                      context.tr('new_opportunity_desc'),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.textTheme.bodySmall?.color
                            ?.withOpacity(0.8),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Row(
                children: [
                  AppCardActionButton(
                    onPressed: () => _showAddDialog(context),
                    icon: Icons.add,
                    label: context.tr('add'),
                    isFilled: true,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  AppCardActionButton(
                    onPressed: () =>
                        _exportStatistics(context, provider),
                    icon: Icons.download,
                    label: context.tr('export_report'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ===========================================================================
  // STATISTICS CARD
  // ===========================================================================

  Widget _buildStatisticsCard(
      BuildContext context, ApplicationsProvider provider) {
    final theme = Theme.of(context);
    final apps = provider.filterByTimeRange(
        provider.allApplications, _timeRange);
    final stats = provider.computeStatistics(apps);
    final sankeyData = _SankeyData.compute(apps);

    return AppCardContainer(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: () => _saveStatsExpanded(!_statsExpanded),
            borderRadius: BorderRadius.circular(AppDimensions.cardBorderRadius),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Row(
                children: [
                  Icon(
                    Icons.analytics_outlined,
                    color: theme.colorScheme.primary,
                    size: 18,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    context.tr('statistics'),
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    _statsExpanded ? Icons.expand_less : Icons.expand_more,
                    color: theme.colorScheme.primary,
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
          if (!_statsExpanded) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.md, 0, AppSpacing.md, AppSpacing.md),
              child: _buildStatRow(context, stats),
            ),
          ] else ...[
            const SizedBox.shrink(),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        context.tr('period'),
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.textTheme.bodySmall?.color
                              ?.withValues(alpha: 0.7),
                        ),
                      ),
                      const SizedBox(width: 8),
                      _buildTimeRangeButton(
                          context, context.tr('period_all'), 'all'),
                      const SizedBox(width: 6),
                      _buildTimeRangeButton(
                          context, context.tr('period_month'), 'month'),
                      const SizedBox(width: 6),
                      _buildTimeRangeButton(
                          context, context.tr('period_quarter'), 'quarter'),
                      const SizedBox(width: 6),
                      _buildTimeRangeButton(
                          context, context.tr('period_year'), 'year'),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _buildStatRow(context, stats),
                  if (sankeyData.applied > 0) ...[
                    const SizedBox(height: AppSpacing.md),
                    const Divider(height: 1),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      context.tr('application_funnel'),
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.3,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    _ApplicationSankey(data: sankeyData),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Builds the row of stat items — used in both collapsed and expanded views.
  Widget _buildStatRow(BuildContext context, ApplicationStatistics stats) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Expanded(
          child: _buildCompactStatItem(
            context,
            label: context.tr('stat_total'),
            value: stats.total.toString(),
            icon: Icons.folder_outlined,
            color: theme.colorScheme.primary,
          ),
        ),
        ...[
          (ApplicationStatus.applied,     context.tr('stat_applied'),      stats.applied),
          (ApplicationStatus.interviewing, context.tr('stat_interviewing'), stats.interviewing),
          (ApplicationStatus.successful,
              _statsExpanded ? context.tr('stat_successful') : context.tr('stat_success'),
              stats.successful),
          (ApplicationStatus.rejected,    context.tr('stat_rejected'),     stats.rejected),
          (ApplicationStatus.noResponse,  context.tr('stat_no_response'),  stats.noResponse),
        ].expand((entry) => [
          const SizedBox(width: 10),
          Expanded(
            child: _buildCompactStatItem(
              context,
              label: entry.$2,
              value: entry.$3.toString(),
              icon: ApplicationStatusHelper.getIcon(entry.$1),
              color: ApplicationStatusHelper.getColor(entry.$1),
            ),
          ),
        ]),
      ],
    );
  }

  Widget _buildTimeRangeButton(
      BuildContext context, String label, String value) {
    final theme = Theme.of(context);
    final isSelected = _timeRange == value;

    return InkWell(
      onTap: () => setState(() => _timeRange = value),
      borderRadius: BorderRadius.circular(6),
      child: AnimatedContainer(
        duration: AppDurations.quick,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected
              ? theme.colorScheme.primary
              : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isSelected
                ? theme.colorScheme.primary
                : theme.colorScheme.outline.withValues(alpha: 0.2),
          ),
        ),
        child: Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: isSelected
                ? theme.colorScheme.onPrimary
                : theme.textTheme.bodySmall?.color?.withValues(alpha: 0.7),
            fontSize: 11,
          ),
        ),
      ),
    );
  }

  Widget _buildCompactStatItem(
    BuildContext context, {
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 14),
              const Spacer(),
              Text(
                value,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 3),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.7),
              fontSize: 10,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // SEARCH BAR
  // ===========================================================================

  Widget _buildSearchBar(BuildContext context, ApplicationsProvider provider) {
    final theme = Theme.of(context);

    return TextField(
      decoration: InputDecoration(
        hintText: context.tr('search_placeholder'),
        prefixIcon: const Icon(Icons.search, size: 20),
        suffixIcon: provider.searchQuery.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.clear, size: 20),
                onPressed: () => provider.setSearchQuery(''),
              )
            : null,
        filled: true,
        fillColor: theme.colorScheme.surfaceContainerHighest.withOpacity(0.3),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
      ),
      onChanged: provider.setSearchQuery,
    );
  }

  // ===========================================================================
  // APPLICATIONS LIST
  // ===========================================================================

  Widget _buildApplicationsList(
      BuildContext context, ApplicationsProvider provider) {
    final apps = provider.applications;

    if (apps.isEmpty) {
      return UIUtils.buildEmptyState(
        context,
        icon: Icons.work_outline,
        title: context.tr('no_applications_title'),
        message: context.tr('no_applications_message'),
        action: AppCardActionButton(
          label: context.tr('add_first_application'),
          onPressed: () => _showAddDialog(context),
          icon: Icons.add,
          isFilled: true,
        ),
      );
    }

    final groups = provider.groupByCategory(apps);
    final activeApps = groups['active']!;
    final successfulApps = groups['successful']!;
    final noResponseApps = groups['noResponse']!;
    final rejectedApps = groups['rejected']!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (activeApps.isNotEmpty) ...[
          _buildCollapsibleSection(
            context,
            title: context.tr('section_active'),
            count: activeApps.length,
            icon: Icons.pending_actions,
            color: AppColors.statusApplied,
            isExpanded: _activeExpanded,
            onToggle: () => _saveActiveExpanded(!_activeExpanded),
            apps: activeApps,
            provider: provider,
          ),
          const SizedBox(height: AppSpacing.md),
        ],
        ...[
          (ApplicationStatus.successful, context.tr('section_successful'),
              successfulApps, _successfulExpanded, _saveSuccessfulExpanded),
          (ApplicationStatus.noResponse, context.tr('section_no_response'),
              noResponseApps, _noResponseExpanded, _saveNoResponseExpanded),
          (ApplicationStatus.rejected, context.tr('section_rejected'),
              rejectedApps, _rejectedExpanded, _saveRejectedExpanded),
        ].expand((e) {
          if (e.$3.isEmpty) return const <Widget>[];
          return [
            _buildCollapsibleSection(
              context,
              title: e.$2,
              count: e.$3.length,
              icon: ApplicationStatusHelper.getIcon(e.$1),
              color: ApplicationStatusHelper.getColor(e.$1),
              isExpanded: e.$4,
              onToggle: () => e.$5(!e.$4),
              apps: e.$3,
              provider: provider,
            ),
            const SizedBox(height: AppSpacing.md),
          ];
        }),
      ],
    );
  }

  Widget _buildCollapsibleSection(
    BuildContext context, {
    required String title,
    required int count,
    required IconData icon,
    required Color color,
    required bool isExpanded,
    required VoidCallback onToggle,
    required List<JobApplication> apps,
    required ApplicationsProvider provider,
  }) {
    final theme = Theme.of(context);

    return AppCardContainer(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: onToggle,
            borderRadius: BorderRadius.circular(AppDimensions.cardBorderRadius),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(icon, size: 18, color: color),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      count.toString(),
                      style: theme.textTheme.labelSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: color,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    isExpanded ? Icons.expand_less : Icons.expand_more,
                    color: theme.colorScheme.primary,
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
          if (isExpanded) ...[
            const SizedBox.shrink(),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: apps.length,
                separatorBuilder: (context, index) =>
                    const SizedBox(height: AppSpacing.md),
                itemBuilder: (context, index) {
                  final application = apps[index];
                  return CompactApplicationCard(
                    application: application,
                    onEdit: () => _showEditDialog(context, application),
                    onDelete: () => _confirmDelete(context, application),
                    onEditContent: () => _editContent(context, application),
                    onViewPdf: () => _viewPdf(context, application),
                    onViewCoverLetter: () =>
                        _viewCoverLetter(context, application),
                    onOpenFolder: () => _openFolder(context, application),
                    onStatusChange: (status) =>
                        provider.updateStatus(application.id, status),
                    onHistoryChanged: (history) =>
                        provider.updateStatusHistory(application.id, history),
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ===========================================================================
  // USER ACTIONS
  // ===========================================================================

  void _showAddDialog(BuildContext context) async {
    // Check if profile has data
    final userDataProvider = context.read<UserDataProvider>();
    final profile = userDataProvider.currentProfile;

    final bool isEmpty = profile == null ||
        (profile.personalInfo == null &&
            profile.experiences.isEmpty &&
            profile.education.isEmpty &&
            profile.skills.isEmpty);

    if (isEmpty) {
      // Show warning dialog
      final shouldContinue = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          icon: Icon(
            Icons.info_outline,
            color: Theme.of(context).colorScheme.primary,
            size: 48,
          ),
          title: Text(context.tr('no_profile_data_title')),
          content: Text(context.tr('no_profile_data_message')),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(context.tr('continue_button')),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(context).pop(false);
                // Navigate to Profile tab (index 0)
                context.read<AppState>().setNavIndex(0);
              },
              child: Text(context.tr('fill_profile_first')),
            ),
          ],
        ),
      );

      if (shouldContinue != true) {
        return; // User chose not to continue
      }
    }

    final result = await showDialog<JobApplication>(
      context: context,
      builder: (context) => const ApplicationEditorDialog(),
    );

    if (result != null && context.mounted) {
      UIUtils.showSuccess(context, context.tr('application_added'));
    }
  }

  void _showEditDialog(BuildContext context, JobApplication application) async {
    final result = await showDialog<JobApplication>(
      context: context,
      builder: (context) =>
          ApplicationEditorDialog(applicationId: application.id),
    );

    if (result != null && context.mounted) {
      UIUtils.showSuccess(context, context.tr('application_updated'));
    }
  }

  void _confirmDelete(BuildContext context, JobApplication application) async {
    final confirmed = await DialogUtils.showDeleteConfirmation(
      context,
      title: context.tr('delete_application_title'),
      message: context
          .tr('delete_application_message', {'company': application.company}),
    );

    if (confirmed && context.mounted) {
      context.read<ApplicationsProvider>().deleteApplication(application.id);
      UIUtils.showSuccess(context, context.tr('application_deleted'));
    }
  }

  void _editContent(BuildContext context, JobApplication application) async {
    if (application.folderPath == null) {
      UIUtils.showError(context, context.tr('app_folder_not_found'));
      return;
    }

    final closeLoading =
        DialogUtils.showLoading(context, message: context.tr('opening_editor'));

    try {
      final appRepo = StorageService.instance.applications;
      final cvData = await appRepo.loadCvData(application.folderPath!);
      final coverLetter =
          await appRepo.loadCoverLetter(application.folderPath!);

      if (context.mounted) {
        closeLoading();

        if (cvData == null) {
          UIUtils.showError(context, context.tr('failed_load_cv'));
          return;
        }

        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => JobCvEditorScreen(
              application: application,
              cvData: cvData,
              coverLetter: coverLetter,
            ),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        closeLoading();
        UIUtils.showError(
            context, context.tr('error_loading_data', {'error': e.toString()}));
      }
    }
  }

  void _viewPdf(BuildContext context, JobApplication application) async {
    _openPdfDialog(context, application, true);
  }

  void _viewCoverLetter(
      BuildContext context, JobApplication application) async {
    _openPdfDialog(context, application, false);
  }

  Future<void> _openPdfDialog(
      BuildContext context, JobApplication application, bool isCV) async {
    if (application.folderPath == null) {
      UIUtils.showError(context, context.tr('app_folder_not_found'));
      return;
    }

    final closeLoading = DialogUtils.showLoading(context,
        message: context.tr('loading_document'));

    try {
      final appRepo = StorageService.instance.applications;
      final cvData = await appRepo.loadCvData(application.folderPath!);
      final coverLetter =
          await appRepo.loadCoverLetter(application.folderPath!);

      if (context.mounted) {
        closeLoading();

        if (cvData == null) {
          UIUtils.showError(context, context.tr('failed_load_cv'));
          return;
        }

        showDialog(
          context: context,
          builder: (context) => JobApplicationPdfDialog(
            application: application,
            cvData: cvData,
            coverLetter: coverLetter,
            isCV: isCV,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        closeLoading();
        UIUtils.showError(
            context, context.tr('error_loading_data', {'error': e.toString()}));
      }
    }
  }

  void _openFolder(BuildContext context, JobApplication application) async {
    final folderPath = application.folderPath;
    if (folderPath == null) {
      UIUtils.showError(context, context.tr('folder_path_not_found'));
      return;
    }

    final directory = Directory(folderPath);
    if (!await directory.exists()) {
      UIUtils.showError(context, context.tr('folder_not_exist'));
      return;
    }

    try {
      await PlatformUtils.openFolder(folderPath);
    } catch (e) {
      if (context.mounted) {
        UIUtils.showError(
            context, context.tr('failed_open_folder', {'error': e.toString()}));
      }
    }
  }

  // ===========================================================================
  // EXPORT
  // ===========================================================================

  /// Export comprehensive statistics as separate English and German markdowns
  Future<void> _exportStatistics(
      BuildContext context, ApplicationsProvider provider) async {
    final apps = provider.allApplications;

    if (apps.isEmpty) {
      if (context.mounted) {
        UIUtils.showError(context, context.tr('no_apps_to_export'));
      }
      return;
    }

    // Let user choose save location
    final outputDir = await FilePicker.platform.getDirectoryPath(
      dialogTitle: context.tr('select_folder_save'),
    );

    if (outputDir == null) return; // User cancelled

    if (!context.mounted) return;

    final closeLoading = DialogUtils.showLoading(context,
        message: context.tr('generating_statistics'));

    try {
      final result = await ApplicationExportService.instance
          .exportStatisticsMarkdown(
        applications: apps,
        outputDir: outputDir,
      );

      if (!context.mounted) return;
      closeLoading();

      if (!result.success) {
        UIUtils.showError(context,
            context.tr('failed_export_stats', {'error': result.error ?? ''}));
        return;
      }

      UIUtils.showSuccess(context, context.tr('stats_exported'));

      final shouldOpen = await DialogUtils.showExportSuccess(
        context,
        title: context.tr('export_successful_title'),
        message: context.tr('export_successful_message',
            {'date': result.dateString ?? ''}),
        noLabel: context.tr('no'),
        openFolderLabel: context.tr('open_folder'),
      );

      if (shouldOpen) {
        await PlatformUtils.openFolder(outputDir);
      }
    } catch (e) {
      if (context.mounted) {
        closeLoading();
        UIUtils.showError(context,
            context.tr('failed_export_stats', {'error': e.toString()}));
      }
    }
  }
}

// ── Application Funnel Sankey ────────────────────────────────────────────────

/// Computed funnel data for the Sankey chart.
class _SankeyData {
  const _SankeyData({
    required this.applied,
    required this.interviewed,
    required this.successful,
    required this.successfulViaInterview,
    required this.activeInterviewing,
    required this.rejectedAfterInterview,
    required this.noResponseAfterInterview,
    required this.activeApplied,
    required this.rejectedWithoutInterview,
    required this.noResponseWithoutInterview,
  });

  final int applied;
  final int interviewed;
  final int successful;
  final int successfulViaInterview;
  final int activeInterviewing;
  final int rejectedAfterInterview;
  final int noResponseAfterInterview;
  final int activeApplied;
  final int rejectedWithoutInterview;
  final int noResponseWithoutInterview;

  int get successfulDirect => successful - successfulViaInterview;
  int get notInterviewed => applied - interviewed;
  int get activeTotal => activeInterviewing + activeApplied;
  int get rejectedTotal => rejectedAfterInterview + rejectedWithoutInterview;
  int get noResponseTotal => noResponseAfterInterview + noResponseWithoutInterview;

  static _SankeyData compute(List<JobApplication> apps) {
    int successfulViaInterview = 0, activeInterviewing = 0;
    int rejectedAfterInterview = 0, noResponseAfterInterview = 0;
    int successfulDirect = 0, activeApplied = 0;
    int rejectedDirect = 0, noResponseDirect = 0;

    for (final app in apps) {
      if (app.status == ApplicationStatus.draft) continue;

      final hadInterview =
          app.status == ApplicationStatus.interviewing ||
          app.safeStatusHistory
              .any((e) => e.status == ApplicationStatus.interviewing);
      // Apps reverted to applied after interview are counted as "not interviewed"
      // to keep flows visually clean.
      final passedInterview =
          hadInterview && app.status != ApplicationStatus.applied;

      if (passedInterview) {
        switch (app.status) {
          case ApplicationStatus.successful:
            successfulViaInterview++;
          case ApplicationStatus.interviewing:
            activeInterviewing++;
          case ApplicationStatus.rejected:
            rejectedAfterInterview++;
          default:
            noResponseAfterInterview++;
        }
      } else {
        switch (app.status) {
          case ApplicationStatus.applied:
            activeApplied++;
          case ApplicationStatus.successful:
            successfulDirect++;
          case ApplicationStatus.rejected:
            rejectedDirect++;
          case ApplicationStatus.noResponse:
            noResponseDirect++;
          default:
            break;
        }
      }
    }

    final interviewed = successfulViaInterview +
        activeInterviewing +
        rejectedAfterInterview +
        noResponseAfterInterview;

    return _SankeyData(
      applied: interviewed + successfulDirect + activeApplied +
          rejectedDirect + noResponseDirect,
      interviewed: interviewed,
      successful: successfulViaInterview + successfulDirect,
      successfulViaInterview: successfulViaInterview,
      activeInterviewing: activeInterviewing,
      rejectedAfterInterview: rejectedAfterInterview,
      noResponseAfterInterview: noResponseAfterInterview,
      activeApplied: activeApplied,
      rejectedWithoutInterview: rejectedDirect,
      noResponseWithoutInterview: noResponseDirect,
    );
  }
}

/// Sankey funnel chart showing the application pipeline.
class _ApplicationSankey extends StatelessWidget {
  const _ApplicationSankey({required this.data});

  final _SankeyData data;

  @override
  Widget build(BuildContext context) {
    if (data.applied == 0) return const SizedBox.shrink();
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: 190,
          child: CustomPaint(
            painter: _SankeyPainter(
              data: data,
              primaryColor: theme.colorScheme.primary,
            ),
          ),
        ),
        // Middle-column legend (interviewed / not-interviewed split)
        if (data.interviewed > 0 && data.notInterviewed > 0)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _SankeyLegend(
                    'Interviewed: ${data.interviewed}',
                    ApplicationStatusHelper.getColor(ApplicationStatus.interviewing)),
                const SizedBox(width: 16),
                _SankeyLegend(
                    'Not Interviewed: ${data.notInterviewed}',
                    AppColors.statusDraft),
              ],
            ),
          ),
      ],
    );
  }
}

class _SankeyLegend extends StatelessWidget {
  const _SankeyLegend(this.label, this.color);

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration:
              BoxDecoration(color: color, borderRadius: BorderRadius.circular(2)),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: color,
                fontSize: 9.5,
                fontWeight: FontWeight.w600,
              ),
        ),
      ],
    );
  }
}

class _SankeyPainter extends CustomPainter {
  _SankeyPainter({required this.data, required this.primaryColor});

  final _SankeyData data;
  final Color primaryColor;

  // Right-column colors routed through the single source of truth.
  Color get _cSuccess        => ApplicationStatusHelper.getColor(ApplicationStatus.successful);
  Color get _cActive         => ApplicationStatusHelper.getColor(ApplicationStatus.applied);
  Color get _cRejected       => ApplicationStatusHelper.getColor(ApplicationStatus.rejected);
  Color get _cNoResp         => ApplicationStatusHelper.getColor(ApplicationStatus.noResponse);
  // Middle-column colors: interviewing status color for the "interviewed" path;
  // draft color for the "never reached interview" path (neutral, distinct from _cNoResp).
  Color get _cInterview      => ApplicationStatusHelper.getColor(ApplicationStatus.interviewing);
  Color get _cNotInterviewed => AppColors.statusDraft;

  static const _nw = 13.0; // node width
  static const _gap = 5.0; // gap between stacked nodes
  static const _lw = 58.0; // left-side label reserve
  static const _rw = 90.0; // right-side label reserve
  static const _vPad = 8.0;

  @override
  void paint(Canvas canvas, Size size) {
    final avH = size.height - 2 * _vPad;
    if (avH <= 0 || data.applied == 0) return;

    final c0 = _lw; // left node x
    final c2 = size.width - _rw - _nw; // right node x
    final c1 = c0 + (c2 - c0) / 2 - _nw / 2; // middle node x

    // Proportional height relative to total applied pool
    double rh(int n, double pool) => n > 0 ? n / data.applied * pool : 0.0;

    // ── Middle column ──────────────────────────────────────────────────────
    final mGap =
        (data.interviewed > 0 && data.notInterviewed > 0) ? _gap : 0.0;
    final mAvH = avH - mGap;
    final iH = rh(data.interviewed, mAvH);
    final nIH = rh(data.notInterviewed, mAvH);
    final iTop = _vPad;
    final nITop = _vPad + iH + mGap;

    // ── Right column ───────────────────────────────────────────────────────
    final rights = <(int, Color, String)>[
      (data.successful, _cSuccess, 'Successful'),
      (data.activeTotal, _cActive, 'Active'),
      (data.rejectedTotal, _cRejected, 'Rejected'),
      (data.noResponseTotal, _cNoResp, 'No Response'),
    ].where((r) => r.$1 > 0).toList();

    final nR = rights.length;
    final rGapTotal = nR > 1 ? (nR - 1) * _gap : 0.0;
    final rAvH = avH - rGapTotal;

    final rects = <(Rect, Color, String, int)>[];
    var rY = _vPad;
    for (final (count, color, label) in rights) {
      final h = rh(count, rAvH);
      rects.add((Rect.fromLTWH(c2, rY, _nw, h), color, label, count));
      rY += h + _gap;
    }

    // ── Flows ──────────────────────────────────────────────────────────────
    void drawFlow(double sx, double sy1, double sy2, double tx, double ty1,
        double ty2, Color c) {
      if (sy2 - sy1 < 0.5 || ty2 - ty1 < 0.5) return;
      final mx = (sx + tx) / 2;
      final path = Path()
        ..moveTo(sx, sy1)
        ..cubicTo(mx, sy1, mx, ty1, tx, ty1)
        ..lineTo(tx, ty2)
        ..cubicTo(mx, ty2, mx, sy2, sx, sy2)
        ..close();
      canvas.drawPath(
          path,
          Paint()
            ..color = c.withValues(alpha: 0.22)
            ..style = PaintingStyle.fill);
    }

    // Left → middle
    var lOff = _vPad;
    if (data.interviewed > 0) {
      final lH = rh(data.interviewed, avH);
      drawFlow(c0 + _nw, lOff, lOff + lH, c1, iTop, iTop + iH, _cInterview);
      lOff += lH;
    }
    if (data.notInterviewed > 0) {
      final lH = rh(data.notInterviewed, avH);
      drawFlow(c0 + _nw, lOff, lOff + lH, c1, nITop, nITop + nIH, _cNotInterviewed);
    }

    // Middle → right (track fill offset per right-node color)
    var iOff = iTop;
    var nIOff = nITop;
    final rFill = {for (final (r, c, _, _) in rects) c: r.top};

    void midFlow(int count, bool fromInterview, Color rc) {
      if (count == 0) return;
      final tH = rh(count, rAvH);
      final tY1 = rFill[rc]!;
      rFill[rc] = tY1 + tH;
      if (fromInterview && data.interviewed > 0) {
        final sH = count / data.interviewed * iH;
        drawFlow(c1 + _nw, iOff, iOff + sH, c2, tY1, tY1 + tH, rc);
        iOff += sH;
      } else if (!fromInterview && data.notInterviewed > 0) {
        final sH = count / data.notInterviewed * nIH;
        drawFlow(c1 + _nw, nIOff, nIOff + sH, c2, tY1, tY1 + tH, rc);
        nIOff += sH;
      }
    }

    midFlow(data.successfulViaInterview, true, _cSuccess);
    midFlow(data.successfulDirect, false, _cSuccess);
    midFlow(data.activeInterviewing, true, _cActive);
    midFlow(data.rejectedAfterInterview, true, _cRejected);
    midFlow(data.noResponseAfterInterview, true, _cNoResp);
    midFlow(data.activeApplied, false, _cActive);
    midFlow(data.rejectedWithoutInterview, false, _cRejected);
    midFlow(data.noResponseWithoutInterview, false, _cNoResp);

    // ── Nodes ──────────────────────────────────────────────────────────────
    const r = Radius.circular(3);
    void node(Rect rect, Color c) => canvas.drawRRect(
        RRect.fromRectAndRadius(rect, r),
        Paint()
          ..color = c
          ..style = PaintingStyle.fill);

    node(Rect.fromLTWH(c0, _vPad, _nw, avH), primaryColor);
    if (iH >= 1) node(Rect.fromLTWH(c1, iTop, _nw, iH), _cInterview);
    if (nIH >= 1) node(Rect.fromLTWH(c1, nITop, _nw, nIH), _cNotInterviewed);
    for (final (rect, color, _, _) in rects) {
      node(rect, color);
    }

    // ── Labels ─────────────────────────────────────────────────────────────
    void lbl(String text, Color c, double x, double y, TextAlign align,
        double maxW) {
      final tp = TextPainter(
        text: TextSpan(
            text: text,
            style: TextStyle(
                color: c,
                fontSize: 9,
                fontWeight: FontWeight.w600,
                height: 1.3)),
        textAlign: align,
        textDirection: TextDirection.ltr,
      )..layout(maxWidth: maxW);
      tp.paint(canvas,
          Offset(align == TextAlign.right ? x - tp.width : x, y - tp.height / 2));
    }

    // Left label
    lbl('Applied\n${data.applied}', primaryColor, c0 - 4, _vPad + avH / 2,
        TextAlign.right, _lw - 8);

    // Right labels: resolve overlaps so every node always gets a label.
    // Preferred Y = node centre. "Push down" pass ensures no two labels
    // overlap (assuming ~24 px per 2-line label).
    const lblH = 24.0;
    final preferred = [
      for (final (rect, _, _, _) in rects) rect.top + rect.height / 2,
    ];
    final resolved = List<double>.from(preferred);
    for (var i = 1; i < resolved.length; i++) {
      final minY = resolved[i - 1] + lblH + 2;
      if (resolved[i] < minY) resolved[i] = minY;
    }

    final tickPaint = Paint()..strokeWidth = 0.7..style = PaintingStyle.stroke;
    for (var i = 0; i < rects.length; i++) {
      final (rect, color, label, count) = rects[i];
      final nodeY = rect.top + rect.height / 2;
      final labelY = resolved[i];
      // Draw a small tick line when the label had to be shifted
      if ((labelY - nodeY).abs() > 4) {
        tickPaint.color = color.withValues(alpha: 0.45);
        canvas.drawLine(
            Offset(c2 + _nw + 2, nodeY), Offset(c2 + _nw + 6, labelY), tickPaint);
      }
      lbl('$label\n$count', color, c2 + _nw + 6, labelY, TextAlign.left, _rw - 8);
    }
  }

  @override
  bool shouldRepaint(_SankeyPainter old) =>
      old.data != data || old.primaryColor != primaryColor;
}
