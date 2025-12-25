import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/job_application.dart';
import '../constants/app_constants.dart';
import '../services/storage_service.dart';

/// Provider for managing job applications
class ApplicationsProvider extends ChangeNotifier {
  final StorageService _storage = StorageService.instance;
  final Uuid _uuid = const Uuid();

  List<JobApplication> _applications = [];
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

    return filtered;
  }

  /// Get application count by status
  Map<ApplicationStatus, int> get statusCounts {
    final counts = <ApplicationStatus, int>{};
    for (final status in ApplicationStatus.values) {
      counts[status] =
          _applications.where((app) => app.status == status).length;
    }
    return counts;
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
      _applications = await _storage.loadApplications();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = 'Failed to load applications: $e';
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Create a new application
  Future<JobApplication> createApplication({
    required String company,
    required String position,
    String? location,
    String? jobUrl,
    String? contactPerson,
    String? contactEmail,
    String? notes,
    String? salary,
  }) async {
    final application = JobApplication(
      id: _uuid.v4(),
      company: company,
      position: position,
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

    await _storage.saveApplication(application);
    _applications.insert(0, application);
    notifyListeners();

    return application;
  }

  /// Update an existing application
  Future<void> updateApplication(JobApplication application) async {
    final updated = application.copyWith(lastUpdated: DateTime.now());
    await _storage.saveApplication(updated);

    final index = _applications.indexWhere((app) => app.id == application.id);
    if (index != -1) {
      _applications[index] = updated;
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
      await _storage.saveApplication(updated);
      _applications[index] = updated;
      notifyListeners();
    }
  }

  /// Delete an application
  Future<void> deleteApplication(String id) async {
    await _storage.deleteApplication(id);
    _applications.removeWhere((app) => app.id == id);
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
    notifyListeners();
  }

  /// Set search query
  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  /// Clear filters
  void clearFilters() {
    _statusFilter = null;
    _searchQuery = '';
    notifyListeners();
  }

  /// Link CV instance to application
  Future<void> linkCvInstance(String applicationId, String cvInstanceId) async {
    final index = _applications.indexWhere((app) => app.id == applicationId);
    if (index != -1) {
      final updated = _applications[index].copyWith(
        cvInstanceId: cvInstanceId,
        lastUpdated: DateTime.now(),
      );
      await _storage.saveApplication(updated);
      _applications[index] = updated;
      notifyListeners();
    }
  }

  /// Link cover letter instance to application
  Future<void> linkCoverLetterInstance(
      String applicationId, String coverLetterInstanceId) async {
    final index = _applications.indexWhere((app) => app.id == applicationId);
    if (index != -1) {
      final updated = _applications[index].copyWith(
        coverLetterInstanceId: coverLetterInstanceId,
        lastUpdated: DateTime.now(),
      );
      await _storage.saveApplication(updated);
      _applications[index] = updated;
      notifyListeners();
    }
  }
}
