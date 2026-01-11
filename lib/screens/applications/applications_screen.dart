import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import '../../providers/applications_provider.dart';
import '../../models/job_application.dart';
import '../../constants/app_constants.dart';
import '../../constants/ui_constants.dart';
import '../../utils/ui_utils.dart';
import '../../utils/dialog_utils.dart';
import '../../services/storage_service.dart';
import '../../services/preferences_service.dart';
import '../../models/template_style.dart';
import '../../models/template_customization.dart';
import 'application_editor_dialog.dart';
import '../../dialogs/job_application_pdf_dialog.dart';
import '../job_cv_editor/job_cv_editor_screen.dart';
import 'widgets/compact_application_card.dart';

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

  // Track individual card expanded states
  final Map<String, bool> _cardExpandedStates = {};

  // Preference keys
  static const String _prefKeyStatsExpanded = 'apps_stats_expanded';
  static const String _prefKeyActiveExpanded = 'apps_active_expanded';
  static const String _prefKeySuccessfulExpanded = 'apps_successful_expanded';
  static const String _prefKeyNoResponseExpanded = 'apps_noresponse_expanded';
  static const String _prefKeyRejectedExpanded = 'apps_rejected_expanded';
  static const String _prefKeyCardPrefix = 'apps_card_';

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
      _statsExpanded = _prefs.getBool(_prefKeyStatsExpanded, defaultValue: true);
      _activeExpanded = _prefs.getBool(_prefKeyActiveExpanded, defaultValue: true);
      _successfulExpanded = _prefs.getBool(_prefKeySuccessfulExpanded, defaultValue: true);
      _noResponseExpanded = _prefs.getBool(_prefKeyNoResponseExpanded, defaultValue: true);
      _rejectedExpanded = _prefs.getBool(_prefKeyRejectedExpanded, defaultValue: false);

      // Load card states
      final keys = _prefs.getKeys();
      for (final key in keys) {
        if (key.startsWith(_prefKeyCardPrefix)) {
          final cardId = key.substring(_prefKeyCardPrefix.length);
          _cardExpandedStates[cardId] = _prefs.getBool(key, defaultValue: false);
        }
      }
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
  Future<void> _saveStatsExpanded(bool value) =>
      _saveExpandedState(_prefKeyStatsExpanded, value, (v) => _statsExpanded = v);

  /// Save active section expanded state
  Future<void> _saveActiveExpanded(bool value) =>
      _saveExpandedState(_prefKeyActiveExpanded, value, (v) => _activeExpanded = v);

  /// Save successful section expanded state
  Future<void> _saveSuccessfulExpanded(bool value) =>
      _saveExpandedState(_prefKeySuccessfulExpanded, value, (v) => _successfulExpanded = v);

  /// Save no response section expanded state
  Future<void> _saveNoResponseExpanded(bool value) =>
      _saveExpandedState(_prefKeyNoResponseExpanded, value, (v) => _noResponseExpanded = v);

  /// Save rejected section expanded state
  Future<void> _saveRejectedExpanded(bool value) =>
      _saveExpandedState(_prefKeyRejectedExpanded, value, (v) => _rejectedExpanded = v);

  /// Save individual card expanded state
  Future<void> _saveCardExpanded(String cardId, bool value) async {
    await _prefs.setBool('$_prefKeyCardPrefix$cardId', value);
    setState(() => _cardExpandedStates[cardId] = value);
  }

  List<dynamic> _filterApplicationsByTimeRange(List<dynamic> apps) {
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
        padding: EdgeInsets.all(UIUtils.spacingLg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with Add Button
            Row(
              children: [
                Expanded(
                  child: UIUtils.buildSectionHeader(
                    context,
                    title: 'Job Applications',
                    subtitle: 'Track and manage all your job applications',
                    icon: Icons.work_history_outlined,
                  ),
                ),
                UIUtils.buildPrimaryButton(
                  label: 'Add Application',
                  onPressed: () => _showAddDialog(context),
                  icon: Icons.add,
                ),
              ],
            ),
            SizedBox(height: UIUtils.spacingMd),

            // Search and Filter Bar
            _buildSearchBar(context, applicationsProvider),
            SizedBox(height: UIUtils.spacingMd),

            // Applications List
            _buildApplicationsList(context, applicationsProvider),
            SizedBox(height: UIUtils.spacingLg),

            // Statistics Dashboard - at bottom
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

    // Calculate statistics based on new simplified statuses
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

    // Active = draft + applied + interviewing
    final active = draft + applied + interviewing;

    return Container(
      decoration: UIConstants.getCardDecoration(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Compact Header with collapse button
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => _saveStatsExpanded(!_statsExpanded),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(
                      Icons.analytics_outlined,
                      color: theme.colorScheme.primary,
                      size: 18,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'Statistics',
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
          ),

          // Animated content with AnimatedCrossFade
          AnimatedCrossFade(
            firstChild: const SizedBox(width: double.infinity),
            secondChild: Column(
              children: [
                if (!_statsExpanded) ...[
                  // Collapsed preview - inline stats (like language toggle)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: theme.colorScheme.outline.withOpacity(0.2),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildInlineStat(context, total.toString(), 'Total',
                              theme.colorScheme.primary),
                          _buildStatDivider(theme),
                          _buildInlineStat(context, active.toString(), 'Active',
                              Colors.orange),
                          _buildStatDivider(theme),
                          _buildInlineStat(context, successful.toString(),
                              'Success', Colors.green),
                          _buildStatDivider(theme),
                          _buildInlineStat(context, rejected.toString(),
                              'Rejected', Colors.red.withOpacity(0.7)),
                          _buildStatDivider(theme),
                          _buildInlineStat(context, noResponse.toString(),
                              'No Response', Colors.grey),
                        ],
                      ),
                    ),
                  ),
                ] else ...[
                  // Expanded content
                  Divider(
                      height: 1, color: theme.dividerColor.withOpacity(0.3)),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Time range filters
                        Row(
                          children: [
                            Text(
                              'Period:',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: theme.textTheme.bodySmall?.color
                                    ?.withOpacity(0.7),
                              ),
                            ),
                            const SizedBox(width: 8),
                            _buildTimeRangeButton(context, 'All', 'all'),
                            const SizedBox(width: 6),
                            _buildTimeRangeButton(context, 'Month', 'month'),
                            const SizedBox(width: 6),
                            _buildTimeRangeButton(
                                context, 'Quarter', 'quarter'),
                            const SizedBox(width: 6),
                            _buildTimeRangeButton(context, 'Year', 'year'),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Compact Statistics - Single Row
                        Row(
                          children: [
                            Expanded(
                              child: _buildCompactStatItem(
                                context,
                                label: 'Total',
                                value: total.toString(),
                                icon: Icons.folder_outlined,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _buildCompactStatItem(
                                context,
                                label: 'Active',
                                value: active.toString(),
                                icon: Icons.pending_actions,
                                color: Colors.orange,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _buildCompactStatItem(
                                context,
                                label: 'Successful',
                                value: successful.toString(),
                                icon: Icons.check_circle_outline,
                                color: Colors.green,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _buildCompactStatItem(
                                context,
                                label: 'Rejected',
                                value: rejected.toString(),
                                icon: Icons.cancel_outlined,
                                color: Colors.red.withOpacity(0.7),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _buildCompactStatItem(
                                context,
                                label: 'No Response',
                                value: noResponse.toString(),
                                icon: Icons.schedule,
                                color: Colors.grey,
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
            crossFadeState: _statsExpanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showSecond, // Always show second for preview
            duration: const Duration(milliseconds: 200),
          ),
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
      child: Container(
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

  Widget _buildInlineStat(
    BuildContext context,
    String value,
    String label,
    Color color,
  ) {
    final theme = Theme.of(context);

    return Column(
      children: [
        Text(
          value,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w700,
            color: color,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.textTheme.bodySmall?.color?.withOpacity(0.6),
            fontSize: 9,
          ),
        ),
      ],
    );
  }

  Widget _buildStatDivider(ThemeData theme) {
    return Container(
      width: 1,
      height: 24,
      color: theme.dividerColor.withOpacity(0.3),
    );
  }

  Widget _buildSearchBar(BuildContext context, ApplicationsProvider provider) {
    final theme = Theme.of(context);

    return TextField(
      decoration: InputDecoration(
        hintText: 'Search by company, position, or location...',
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
        title: 'No applications yet',
        message: 'Track where you send your CV and cover letters',
        action: UIUtils.buildPrimaryButton(
          label: 'Add Your First Application',
          onPressed: () => _showAddDialog(context),
          icon: Icons.add,
        ),
      );
    }

    // Group by status - include successful
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
        // Active Applications - Collapsible
        if (activeApps.isNotEmpty) ...[
          _buildCollapsibleSection(
            context,
            title: 'Active',
            count: activeApps.length,
            icon: Icons.pending_actions,
            color: Colors.orange,
            isExpanded: _activeExpanded,
            onToggle: () => _saveActiveExpanded(!_activeExpanded),
            apps: activeApps,
            provider: provider,
          ),
          const SizedBox(height: 16),
        ],

        // Successful Applications - Collapsible
        if (successfulApps.isNotEmpty) ...[
          _buildCollapsibleSection(
            context,
            title: 'Successful',
            count: successfulApps.length,
            icon: Icons.check_circle,
            color: Colors.green,
            isExpanded: _successfulExpanded,
            onToggle: () => _saveSuccessfulExpanded(!_successfulExpanded),
            apps: successfulApps,
            provider: provider,
          ),
          const SizedBox(height: 16),
        ],

        // No Response Applications - Collapsible
        if (noResponseApps.isNotEmpty) ...[
          _buildCollapsibleSection(
            context,
            title: 'No Response',
            count: noResponseApps.length,
            icon: Icons.schedule,
            color: Colors.grey,
            isExpanded: _noResponseExpanded,
            onToggle: () => _saveNoResponseExpanded(!_noResponseExpanded),
            apps: noResponseApps,
            provider: provider,
          ),
          const SizedBox(height: 16),
        ],

        // Rejected Applications - Collapsible (collapsed by default)
        if (rejectedApps.isNotEmpty) ...[
          _buildCollapsibleSection(
            context,
            title: 'Rejected',
            count: rejectedApps.length,
            icon: Icons.cancel,
            color: Colors.red.withOpacity(0.7),
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
    required List<dynamic> apps,
    required ApplicationsProvider provider,
  }) {
    final theme = Theme.of(context);

    return Container(
      decoration: UIConstants.getCardDecoration(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Collapsible Header
          InkWell(
            onTap: onToggle,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16),
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

          // Expanded Content with smooth animation
          AnimatedCrossFade(
            firstChild: const SizedBox(width: double.infinity),
            secondChild: Column(
              children: [
                Divider(height: 1, color: theme.dividerColor.withOpacity(0.3)),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: apps
                        .map((app) => Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: _buildApplicationCard(context, app, provider),
                            ))
                        .toList(),
                  ),
                ),
              ],
            ),
            crossFadeState: isExpanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 200),
          ),
        ],
      ),
    );
  }

  // Dead code removed - replaced by _buildCollapsibleSection

  Widget _buildApplicationCard(BuildContext context, JobApplication application,
      ApplicationsProvider provider) {
    return CompactApplicationCard(
      application: application,
      onEdit: () => _showEditDialog(context, application, provider),
      onDelete: () => _deleteApplication(context, application.id, provider),
      onEditContent: () => _editContent(context, application),
      onViewPdf: () => _viewPdf(context, application),
      onViewCoverLetter: () => _viewCoverLetterPdf(context, application),
      onOpenFolder: () => _openJobFolder(application),
      onStatusChange: (newStatus) =>
          _changeApplicationStatus(context, application, newStatus, provider),
      initiallyExpanded: _cardExpandedStates[application.id] ?? false,
      onExpandedChanged: (expanded) => _saveCardExpanded(application.id, expanded),
    );
  }

  Future<void> _changeApplicationStatus(
    BuildContext context,
    JobApplication application,
    ApplicationStatus newStatus,
    ApplicationsProvider provider,
  ) async {
    // Update application with new status and track history
    final updatedApplication = application.withStatusChange(newStatus);
    await provider.updateApplication(updatedApplication);

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Status changed to ${newStatus.name}',
          ),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  void _showAddDialog(BuildContext context) async {
    // Open the application creation dialog
    final newApplication = await showDialog(
      context: context,
      builder: (context) => const ApplicationEditorDialog(),
    );

    // If an application was created, open PDF editor for the new application
    if (newApplication != null && mounted) {
      await _editContent(context, newApplication);
    }
  }

  void _showEditDialog(BuildContext context, JobApplication application,
      ApplicationsProvider provider) {
    showDialog(
      context: context,
      builder: (context) =>
          ApplicationEditorDialog(applicationId: application.id),
    );
  }

  Future<void> _deleteApplication(
      BuildContext context, String id, ApplicationsProvider provider) async {
    final confirmed = await DialogUtils.showDeleteConfirmation(
      context,
      title: 'Delete Application',
      message:
          'Are you sure you want to delete this application?\n\nThis action cannot be undone.',
    );

    if (confirmed && context.mounted) {
      await provider.deleteApplication(id);
    }
  }

  Future<void> _editContent(
      BuildContext context, JobApplication application) async {
    if (application.folderPath == null) return;

    final storage = StorageService.instance;

    // Load CV data and cover letter
    final cvData = await storage.loadJobCvData(application.folderPath!);
    final coverLetter =
        await storage.loadJobCoverLetter(application.folderPath!);

    if (cvData == null) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('No CV data found for this application')),
        );
      }
      return;
    }

    if (!context.mounted) return;

    // Navigate to CV editor with cover letter data
    final editor = JobCvEditorScreen(
      application: application,
      cvData: cvData,
      coverLetter: coverLetter,
    );
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => editor),
    );
  }

  Future<void> _viewPdf(
      BuildContext context, JobApplication application) async {
    if (application.folderPath == null) return;

    final storage = StorageService.instance;

    // Load CV and cover letter data
    final cvData = await storage.loadJobCvData(application.folderPath!);
    final coverLetter =
        await storage.loadJobCoverLetter(application.folderPath!);

    // Load PDF settings
    final (loadedStyle, loadedCustomization) =
        await storage.loadJobPdfSettings(application.folderPath!);

    final templateStyle = loadedStyle ?? TemplateStyle.defaultStyle;
    final customization = loadedCustomization ?? const TemplateCustomization();

    if (cvData == null) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('No CV data found for this application')),
        );
      }
      return;
    }

    if (!context.mounted) return;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => JobApplicationPdfDialog(
        application: application,
        cvData: cvData,
        coverLetter: coverLetter,
        isCV: true,
        templateStyle: templateStyle,
        templateCustomization: customization,
      ),
    );
  }

  Future<void> _viewCoverLetterPdf(
      BuildContext context, JobApplication application) async {
    if (application.folderPath == null) return;

    final storage = StorageService.instance;

    // Load CV and cover letter data
    final cvData = await storage.loadJobCvData(application.folderPath!);
    final coverLetter =
        await storage.loadJobCoverLetter(application.folderPath!);

    // Load PDF settings
    final (loadedStyle, loadedCustomization) =
        await storage.loadJobPdfSettings(application.folderPath!);

    final templateStyle = loadedStyle ?? TemplateStyle.defaultStyle;
    final customization = loadedCustomization ?? const TemplateCustomization();

    if (coverLetter == null) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('No cover letter data found for this application')),
        );
      }
      return;
    }

    // cvData is also needed for the dialog structure
    if (cvData == null) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('No CV data found for this application')),
        );
      }
      return;
    }

    if (!context.mounted) return;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => JobApplicationPdfDialog(
        application: application,
        cvData: cvData,
        coverLetter: coverLetter,
        isCV: false,
        templateStyle: templateStyle,
        templateCustomization: customization,
      ),
    );
  }

  void _openJobFolder(JobApplication application) {
    if (application.folderPath == null) return;

    final folderPath = application.folderPath!;
    if (Directory(folderPath).existsSync()) {
      Process.run('explorer', [folderPath]);
    }
  }
}
