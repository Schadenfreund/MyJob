import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import '../../providers/applications_provider.dart';
import '../../providers/user_data_provider.dart';
import '../../providers/app_state.dart';
import '../../models/job_application.dart';
import '../../constants/app_constants.dart';
import '../../theme/app_theme.dart';
import '../../utils/ui_utils.dart';
import '../../utils/dialog_utils.dart';
import '../../services/preferences_service.dart';
import '../../services/storage_service.dart';
import '../../services/application_statistics_markdown_service.dart';
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

  List<JobApplication> _filterApplicationsByTimeRange(
      List<JobApplication> apps) {
    if (_timeRange == 'all') return apps;

    final now = DateTime.now();
    DateTime cutoffDate;

    switch (_timeRange) {
      case 'month':
        cutoffDate = DateTime(now.year, now.month - 1, now.day);
        break;
      case 'quarter':
        cutoffDate = DateTime(now.year, now.month - 3, now.day);
        break;
      case 'year':
        cutoffDate = DateTime(now.year - 1, now.month, now.day);
        break;
      default:
        return apps;
    }

    return apps.where((app) {
      if (app.applicationDate == null) return false;
      return app.applicationDate!.isAfter(cutoffDate);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final applicationsProvider = context.watch<ApplicationsProvider>();

    if (applicationsProvider.isLoading) {
      return const Center(child: CircularProgressIndicator());
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

            // Top Action Card - Refactored to match Profile style
            AppCardContainer(
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
                            onPressed: () => _exportStatisticsPdf(context, applicationsProvider),
                            icon: Icons.download,
                            label: context.tr('export_report'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
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

  Widget _buildStatisticsCard(
      BuildContext context, ApplicationsProvider provider) {
    final theme = Theme.of(context);
    final allApps = provider.allApplications;
    final apps = _filterApplicationsByTimeRange(allApps);

    final total = apps.length;
    final draft =
        apps.where((app) => app.status == ApplicationStatus.draft).length;
    final applied =
        apps.where((app) => app.status == ApplicationStatus.applied).length;
    final interviewing = apps
        .where((app) => app.status == ApplicationStatus.interviewing)
        .length;
    final successful =
        apps.where((app) => app.status == ApplicationStatus.successful).length;
    final rejected =
        apps.where((app) => app.status == ApplicationStatus.rejected).length;
    final noResponse =
        apps.where((app) => app.status == ApplicationStatus.noResponse).length;

    final active = draft + applied + interviewing;

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
              child: Row(
                children: [
                  Expanded(
                    child: _buildCompactStatItem(
                      context,
                      label: context.tr('stat_total'),
                      value: total.toString(),
                      icon: Icons.folder_outlined,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildCompactStatItem(
                      context,
                      label: context.tr('stat_active'),
                      value: active.toString(),
                      icon: Icons.pending_actions,
                      color: AppColors.statusApplied,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildCompactStatItem(
                      context,
                      label: context.tr('stat_success'),
                      value: successful.toString(),
                      icon: Icons.check_circle_outline,
                      color: AppColors.statusAccepted,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildCompactStatItem(
                      context,
                      label: context.tr('stat_rejected'),
                      value: rejected.toString(),
                      icon: Icons.cancel_outlined,
                      color: AppColors.statusRejected,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildCompactStatItem(
                      context,
                      label: context.tr('stat_no_response'),
                      value: noResponse.toString(),
                      icon: Icons.schedule,
                      color: AppColors.statusWithdrawn,
                    ),
                  ),
                ],
              ),
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
                              ?.withOpacity(0.7),
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
                  Row(
                    children: [
                      Expanded(
                        child: _buildCompactStatItem(
                          context,
                          label: context.tr('stat_total'),
                          value: total.toString(),
                          icon: Icons.folder_outlined,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _buildCompactStatItem(
                          context,
                          label: context.tr('stat_active'),
                          value: active.toString(),
                          icon: Icons.pending_actions,
                          color: AppColors.statusApplied,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _buildCompactStatItem(
                          context,
                          label: context.tr('stat_successful'),
                          value: successful.toString(),
                          icon: Icons.check_circle_outline,
                          color: AppColors.statusAccepted,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _buildCompactStatItem(
                          context,
                          label: context.tr('stat_rejected'),
                          value: rejected.toString(),
                          icon: Icons.cancel_outlined,
                          color: AppColors.statusRejected,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _buildCompactStatItem(
                          context,
                          label: context.tr('stat_no_response'),
                          value: noResponse.toString(),
                          icon: Icons.schedule,
                          color: AppColors.statusWithdrawn,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
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
              : theme.colorScheme.surfaceContainerHighest.withOpacity(0.3),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isSelected
                ? theme.colorScheme.primary
                : theme.colorScheme.outline.withOpacity(0.2),
          ),
        ),
        child: Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: isSelected
                ? theme.colorScheme.onPrimary
                : theme.textTheme.bodySmall?.color?.withOpacity(0.7),
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
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: color.withOpacity(0.2),
        ),
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
              color: theme.textTheme.bodySmall?.color?.withOpacity(0.7),
              fontSize: 10,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

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

    final activeApps = apps
        .where((app) =>
            app.status == ApplicationStatus.draft ||
            app.status == ApplicationStatus.applied ||
            app.status == ApplicationStatus.interviewing)
        .toList();

    final successfulApps = apps
        .where((app) => app.status == ApplicationStatus.successful)
        .toList();

    final noResponseApps = apps
        .where((app) => app.status == ApplicationStatus.noResponse)
        .toList();

    final rejectedApps =
        apps.where((app) => app.status == ApplicationStatus.rejected).toList();

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
        if (successfulApps.isNotEmpty) ...[
          _buildCollapsibleSection(
            context,
            title: context.tr('section_successful'),
            count: successfulApps.length,
            icon: Icons.check_circle,
            color: AppColors.statusAccepted,
            isExpanded: _successfulExpanded,
            onToggle: () => _saveSuccessfulExpanded(!_successfulExpanded),
            apps: successfulApps,
            provider: provider,
          ),
          const SizedBox(height: AppSpacing.md),
        ],
        if (noResponseApps.isNotEmpty) ...[
          _buildCollapsibleSection(
            context,
            title: context.tr('section_no_response'),
            count: noResponseApps.length,
            icon: Icons.schedule,
            color: AppColors.statusWithdrawn,
            isExpanded: _noResponseExpanded,
            onToggle: () => _saveNoResponseExpanded(!_noResponseExpanded),
            apps: noResponseApps,
            provider: provider,
          ),
          const SizedBox(height: AppSpacing.md),
        ],
        if (rejectedApps.isNotEmpty) ...[
          _buildCollapsibleSection(
            context,
            title: context.tr('section_rejected'),
            count: rejectedApps.length,
            icon: Icons.cancel,
            color: AppColors.statusRejected,
            isExpanded: _rejectedExpanded,
            onToggle: () => _saveRejectedExpanded(!_rejectedExpanded),
            apps: rejectedApps,
            provider: provider,
          ),
        ],
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
                      color: color.withOpacity(0.1),
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
                      color: color.withOpacity(0.1),
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
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }

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
      final storage = StorageService.instance;
      final cvData = await storage.loadJobCvData(application.folderPath!);
      final coverLetter =
          await storage.loadJobCoverLetter(application.folderPath!);

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
      final storage = StorageService.instance;
      final cvData = await storage.loadJobCvData(application.folderPath!);
      final coverLetter =
          await storage.loadJobCoverLetter(application.folderPath!);

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
      if (Platform.isWindows) {
        await Process.run('explorer.exe', [folderPath]);
      } else if (Platform.isMacOS) {
        await Process.run('open', [folderPath]);
      } else if (Platform.isLinux) {
        await Process.run('xdg-open', [folderPath]);
      }
    } catch (e) {
      if (context.mounted) {
        UIUtils.showError(
            context, context.tr('failed_open_folder', {'error': e.toString()}));
      }
    }
  }

  /// Export comprehensive statistics as separate English and German markdowns
  Future<void> _exportStatisticsPdf(
      BuildContext context, ApplicationsProvider provider) async {
    try {
      final apps = provider.allApplications;

      if (apps.isEmpty) {
        if (context.mounted) {
          UIUtils.showError(context, context.tr('no_apps_to_export'));
        }
        return;
      }

      // Show loading
      if (context.mounted) {
        DialogUtils.showLoading(context,
            message: context.tr('generating_statistics'));
      }

      // Generate both English and German markdown
      final englishMarkdown =
          ApplicationStatisticsMarkdownService.generateEnglishMarkdown(
        applications: apps,
      );

      final germanMarkdown =
          ApplicationStatisticsMarkdownService.generateGermanMarkdown(
        applications: apps,
      );

      if (context.mounted) {
        Navigator.of(context).pop(); // Close loading
      }

      // Let user choose save location for the folder
      final result = await FilePicker.platform.getDirectoryPath(
        dialogTitle: context.tr('select_folder_save'),
      );

      if (result == null) return;

      // Create filenames with date
      final dateStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
      final englishFile =
          File('$result\\Application_Statistics_EN_$dateStr.md');
      final germanFile = File('$result\\Application_Statistics_DE_$dateStr.md');

      // Save both files
      await englishFile.writeAsString(englishMarkdown, encoding: utf8);
      await germanFile.writeAsString(germanMarkdown, encoding: utf8);

      if (context.mounted) {
        UIUtils.showSuccess(context, context.tr('stats_exported'));

        // Offer to open folder
        final shouldOpen = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(context.tr('export_successful_title')),
            content: Text(
                context.tr('export_successful_message', {'date': dateStr})),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(context.tr('no')),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text(context.tr('open_folder')),
              ),
            ],
          ),
        );

        if (shouldOpen == true) {
          try {
            if (Platform.isWindows) {
              await Process.run('explorer', [result]);
            } else if (Platform.isMacOS) {
              await Process.run('open', [result]);
            } else if (Platform.isLinux) {
              await Process.run('xdg-open', [result]);
            }
          } catch (e) {
            debugPrint('Failed to open folder: $e');
          }
        }
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.of(context).pop(); // Close loading if still open
        UIUtils.showError(context,
            context.tr('failed_export_stats', {'error': e.toString()}));
      }
    }
  }
}
