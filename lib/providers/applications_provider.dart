import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/job_application.dart';
import '../models/master_profile.dart';
import '../constants/app_constants.dart';
import '../services/storage_service.dart';
import '../services/application_repository.dart';
import '../services/log_service.dart';

/// Pre-computed statistics for the applications dashboard.
///
/// Avoids inline counting in build methods — compute once, display everywhere.
class ApplicationStatistics {
  const ApplicationStatistics({
    required this.total,
    required this.draft,
    required this.applied,
    required this.interviewing,
    required this.successful,
    required this.rejected,
    required this.noResponse,
  });

  final int total;
  final int draft;
  final int applied;
  final int interviewing;
  final int successful;
  final int rejected;
  final int noResponse;

  int get active => draft + applied + interviewing;
  int get closed => successful + rejected + noResponse;
}

/// Provider for managing job applications
class ApplicationsProvider extends ChangeNotifier {
  final _appRepo = StorageService.instance.applications;
  final _profileRepo = StorageService.instance.profiles;
  final Uuid _uuid = const Uuid();

  ApplicationRepository get storage => _appRepo;

  List<JobApplication> _applications = [];
  List<JobApplication>? _cachedFiltered;
  bool _isLoading = false;
  String? _error;
  ApplicationStatus? _statusFilter;
  String _searchQuery = '';

  List<JobApplication> get applications => _filteredApplications;
  List<JobApplication> get allApplications => _applications;
  bool get isLoading => _isLoading;
  String? get error => _error;
  ApplicationStatus? get statusFilter => _statusFilter;
  String get searchQuery => _searchQuery;

  List<JobApplication> get _filteredApplications {
    if (_cachedFiltered != null) return _cachedFiltered!;

    var filtered = _applications;

    if (_statusFilter != null) {
      filtered = filtered.where((app) => app.status == _statusFilter).toList();
    }

    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      filtered = filtered.where((app) {
        return app.company.toLowerCase().contains(query) ||
            app.position.toLowerCase().contains(query) ||
            (app.location?.toLowerCase().contains(query) ?? false);
      }).toList();
    }

    _cachedFiltered = filtered;
    return filtered;
  }

  void _invalidateCache() {
    _cachedFiltered = null;
  }

  // ===========================================================================
  // STATISTICS & GROUPING
  // ===========================================================================

  /// Filter applications by a named time range.
  ///
  /// [timeRange] is one of `'all'`, `'month'`, `'quarter'`, `'year'`.
  List<JobApplication> filterByTimeRange(
    List<JobApplication> apps,
    String timeRange,
  ) {
    if (timeRange == 'all') return apps;

    final now = DateTime.now();
    final DateTime cutoffDate;

    switch (timeRange) {
      case 'month':
        cutoffDate = DateTime(now.year, now.month - 1, now.day);
      case 'quarter':
        cutoffDate = DateTime(now.year, now.month - 3, now.day);
      case 'year':
        cutoffDate = DateTime(now.year - 1, now.month, now.day);
      default:
        return apps;
    }

    return apps.where((app) {
      if (app.applicationDate == null) return false;
      return app.applicationDate!.isAfter(cutoffDate);
    }).toList();
  }

  /// Compute statistics for the given list of applications.
  ApplicationStatistics computeStatistics(List<JobApplication> apps) {
    int draft = 0, applied = 0, interviewing = 0;
    int successful = 0, rejected = 0, noResponse = 0;

    for (final app in apps) {
      switch (app.status) {
        case ApplicationStatus.draft:
          draft++;
        case ApplicationStatus.applied:
          applied++;
        case ApplicationStatus.interviewing:
          interviewing++;
        case ApplicationStatus.successful:
          successful++;
        case ApplicationStatus.rejected:
          rejected++;
        case ApplicationStatus.noResponse:
          noResponse++;
      }
    }

    return ApplicationStatistics(
      total: apps.length,
      draft: draft,
      applied: applied,
      interviewing: interviewing,
      successful: successful,
      rejected: rejected,
      noResponse: noResponse,
    );
  }

  /// Group applications by status category for the collapsible sections.
  ///
  /// Returns a map with keys: `active`, `successful`, `noResponse`, `rejected`.
  Map<String, List<JobApplication>> groupByCategory(
      List<JobApplication> apps) {
    final active = <JobApplication>[];
    final successful = <JobApplication>[];
    final noResponse = <JobApplication>[];
    final rejected = <JobApplication>[];

    for (final app in apps) {
      switch (app.status) {
        case ApplicationStatus.draft:
        case ApplicationStatus.applied:
        case ApplicationStatus.interviewing:
          active.add(app);
        case ApplicationStatus.successful:
          successful.add(app);
        case ApplicationStatus.noResponse:
          noResponse.add(app);
        case ApplicationStatus.rejected:
          rejected.add(app);
      }
    }

    return {
      'active': active,
      'successful': successful,
      'noResponse': noResponse,
      'rejected': rejected,
    };
  }

  /// Get total application count
  int get totalCount => _applications.length;

  /// Get recent applications (last 5)
  List<JobApplication> get recentApplications => _applications.take(5).toList();

  /// Load all applications from storage
  Future<void> loadApplications() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _applications = await _appRepo.loadAll();
      _invalidateCache();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = 'Failed to load applications: $e';
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Create a new application and clone profile data
  Future<JobApplication> createApplication({
    required String company,
    required String position,
    required DocumentLanguage baseLanguage,
    String? location,
    String? jobUrl,
    String? contactPerson,
    String? contactEmail,
    String? notes,
    String? salary,
    MasterProfile? masterProfile,
  }) async {
    final application = JobApplication(
      id: _uuid.v4(),
      company: company,
      position: position,
      baseLanguage: baseLanguage,
      status: ApplicationStatus.draft,
      applicationDate: DateTime.now(),
      lastUpdated: DateTime.now(),
      location: location,
      jobUrl: jobUrl,
      contactPerson: contactPerson,
      contactEmail: contactEmail,
      notes: notes,
      salary: salary,
    );

    // Load the master profile for the selected language if not provided
    final profileToUse =
        masterProfile ?? await _profileRepo.load(baseLanguage.code);

    logDebug('Language selected: $baseLanguage', tag: 'Applications');
    logDebug('Profile summary in master: "${profileToUse.profileSummary}"', tag: 'Applications');
    logDebug('Cover letter body in master (chars: ${profileToUse.defaultCoverLetterBody.length})', tag: 'Applications');

    // Clone the profile data to the job application folder
    await _appRepo.cloneProfile(profileToUse, application);

    // Reload the application to get the updated folderPath
    final applications = await _appRepo.loadAll();
    final createdApp =
        applications.firstWhere((app) => app.id == application.id);

    _applications.insert(0, createdApp);
    _invalidateCache();
    notifyListeners();

    return createdApp;
  }

  /// Update an existing application
  Future<void> updateApplication(JobApplication application) async {
    final updated = application.copyWith(lastUpdated: DateTime.now());
    await _appRepo.save(updated);

    final index = _applications.indexWhere((app) => app.id == application.id);
    if (index != -1) {
      _applications[index] = updated;
      _invalidateCache();
      notifyListeners();
    }
  }

  /// Update application status
  Future<void> updateStatus(String id, ApplicationStatus status) async {
    final index = _applications.indexWhere((app) => app.id == id);
    if (index != -1) {
      final updated = _applications[index].copyWith(
        status: status,
        lastUpdated: DateTime.now(),
        applicationDate: status == ApplicationStatus.applied
            ? DateTime.now()
            : _applications[index].applicationDate,
      );
      await _appRepo.save(updated);
      _applications[index] = updated;
      _invalidateCache();
      notifyListeners();
    }
  }

  /// Delete an application
  Future<void> deleteApplication(String id) async {
    await _appRepo.delete(id);
    _applications.removeWhere((app) => app.id == id);
    _invalidateCache();
    notifyListeners();
  }

  /// Get application by ID
  JobApplication? getApplicationById(String id) {
    try {
      return _applications.firstWhere((app) => app.id == id);
    } catch (e) {
      return null;
    }
  }

  /// Set status filter
  void setStatusFilter(ApplicationStatus? status) {
    _statusFilter = status;
    _invalidateCache();
    notifyListeners();
  }

  /// Set search query
  void setSearchQuery(String query) {
    _searchQuery = query;
    _invalidateCache();
    notifyListeners();
  }

  /// Clear filters
  void clearFilters() {
    _statusFilter = null;
    _searchQuery = '';
    _invalidateCache();
    notifyListeners();
  }
}
