import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/cv_template.dart';
import '../models/cover_letter_template.dart';
import '../models/cv_data.dart';
import '../services/templates_storage_service.dart';

/// Provider for managing CV and Cover Letter templates
class TemplatesProvider extends ChangeNotifier {
  final TemplatesStorageService _storage = TemplatesStorageService.instance;
  final Uuid _uuid = const Uuid();

  List<CvTemplate> _cvTemplates = [];
  List<CoverLetterTemplate> _coverLetterTemplates = [];
  List<CvInstance> _cvInstances = [];
  List<CoverLetterInstance> _coverLetterInstances = [];

  bool _isLoading = false;
  String? _error;

  List<CvTemplate> get cvTemplates => _cvTemplates;
  List<CoverLetterTemplate> get coverLetterTemplates => _coverLetterTemplates;
  List<CvInstance> get cvInstances => _cvInstances;
  List<CoverLetterInstance> get coverLetterInstances => _coverLetterInstances;
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Load all templates and instances
  Future<void> loadAll() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _cvTemplates = await _storage.loadCvTemplates();
      _coverLetterTemplates = await _storage.loadCoverLetterTemplates();
      _cvInstances = await _storage.loadCvInstances();
      _coverLetterInstances = await _storage.loadCoverLetterInstances();

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = 'Failed to load templates: $e';
      _isLoading = false;
      notifyListeners();
    }
  }

  // ============================================================================
  // CV TEMPLATES
  // ============================================================================

  Future<CvTemplate> createCvTemplate({
    required String name,
    String? profile,
    List<String>? skills,
    ContactDetails? contactDetails,
  }) async {
    final template = CvTemplate(
      id: _uuid.v4(),
      name: name,
      profile: profile ?? '',
      skills: skills ?? [],
      contactDetails: contactDetails,
      createdAt: DateTime.now(),
      lastModified: DateTime.now(),
    );

    await _storage.saveCvTemplate(template);
    _cvTemplates.insert(0, template);
    notifyListeners();

    return template;
  }

  Future<void> updateCvTemplate(CvTemplate template) async {
    await _storage.saveCvTemplate(template);

    final index = _cvTemplates.indexWhere((t) => t.id == template.id);
    if (index != -1) {
      _cvTemplates[index] = template;
      notifyListeners();
    }
  }

  Future<void> deleteCvTemplate(String id) async {
    await _storage.deleteCvTemplate(id);
    _cvTemplates.removeWhere((t) => t.id == id);
    notifyListeners();
  }

  CvTemplate? getCvTemplateById(String id) {
    try {
      return _cvTemplates.firstWhere((t) => t.id == id);
    } catch (e) {
      return null;
    }
  }

  // ============================================================================
  // COVER LETTER TEMPLATES
  // ============================================================================

  Future<CoverLetterTemplate> createCoverLetterTemplate({
    required String name,
    String? greeting,
    String? body,
    String? closing,
  }) async {
    final template = CoverLetterTemplate(
      id: _uuid.v4(),
      name: name,
      greeting: greeting ?? 'Dear Hiring Manager,',
      body: body ?? '',
      closing: closing ?? 'Kind regards,',
      createdAt: DateTime.now(),
      lastModified: DateTime.now(),
    );

    await _storage.saveCoverLetterTemplate(template);
    _coverLetterTemplates.insert(0, template);
    notifyListeners();

    return template;
  }

  Future<void> updateCoverLetterTemplate(CoverLetterTemplate template) async {
    await _storage.saveCoverLetterTemplate(template);

    final index = _coverLetterTemplates.indexWhere((t) => t.id == template.id);
    if (index != -1) {
      _coverLetterTemplates[index] = template;
      notifyListeners();
    }
  }

  Future<void> deleteCoverLetterTemplate(String id) async {
    await _storage.deleteCoverLetterTemplate(id);
    _coverLetterTemplates.removeWhere((t) => t.id == id);
    notifyListeners();
  }

  CoverLetterTemplate? getCoverLetterTemplateById(String id) {
    try {
      return _coverLetterTemplates.firstWhere((t) => t.id == id);
    } catch (e) {
      return null;
    }
  }

  // ============================================================================
  // CV INSTANCES
  // ============================================================================

  Future<CvInstance> createCvInstanceFromTemplate({
    required String templateId,
    required String applicationId,
  }) async {
    final template = getCvTemplateById(templateId);
    if (template == null) {
      throw Exception('Template not found: $templateId');
    }

    final instance = CvInstance.fromTemplate(
      template,
      instanceId: _uuid.v4(),
      applicationId: applicationId,
    );

    await _storage.saveCvInstance(instance);
    _cvInstances.add(instance);
    notifyListeners();

    return instance;
  }

  Future<void> updateCvInstance(CvInstance instance) async {
    await _storage.saveCvInstance(instance);

    final index = _cvInstances.indexWhere((i) => i.id == instance.id);
    if (index != -1) {
      _cvInstances[index] = instance;
      notifyListeners();
    }
  }

  Future<void> deleteCvInstance(String id) async {
    await _storage.deleteCvInstance(id);
    _cvInstances.removeWhere((i) => i.id == id);
    notifyListeners();
  }

  CvInstance? getCvInstanceById(String id) {
    try {
      return _cvInstances.firstWhere((i) => i.id == id);
    } catch (e) {
      return null;
    }
  }

  List<CvInstance> getCvInstancesForApplication(String applicationId) {
    return _cvInstances.where((i) => i.applicationId == applicationId).toList();
  }

  // ============================================================================
  // COVER LETTER INSTANCES
  // ============================================================================

  Future<CoverLetterInstance> createCoverLetterInstanceFromTemplate({
    required String templateId,
    required String applicationId,
    String? companyName,
    String? jobTitle,
  }) async {
    final template = getCoverLetterTemplateById(templateId);
    if (template == null) {
      throw Exception('Template not found: $templateId');
    }

    final instance = CoverLetterInstance.fromTemplate(
      template,
      instanceId: _uuid.v4(),
      applicationId: applicationId,
      companyName: companyName,
      jobTitle: jobTitle,
    );

    await _storage.saveCoverLetterInstance(instance);
    _coverLetterInstances.add(instance);
    notifyListeners();

    return instance;
  }

  Future<void> updateCoverLetterInstance(CoverLetterInstance instance) async {
    await _storage.saveCoverLetterInstance(instance);

    final index = _coverLetterInstances.indexWhere((i) => i.id == instance.id);
    if (index != -1) {
      _coverLetterInstances[index] = instance;
      notifyListeners();
    }
  }

  Future<void> deleteCoverLetterInstance(String id) async {
    await _storage.deleteCoverLetterInstance(id);
    _coverLetterInstances.removeWhere((i) => i.id == id);
    notifyListeners();
  }

  CoverLetterInstance? getCoverLetterInstanceById(String id) {
    try {
      return _coverLetterInstances.firstWhere((i) => i.id == id);
    } catch (e) {
      return null;
    }
  }

  List<CoverLetterInstance> getCoverLetterInstancesForApplication(
      String applicationId) {
    return _coverLetterInstances
        .where((i) => i.applicationId == applicationId)
        .toList();
  }

  // ============================================================================
  // BULK OPERATIONS
  // ============================================================================

  /// Delete all instances for an application
  Future<void> deleteInstancesForApplication(String applicationId) async {
    await _storage.deleteInstancesForApplication(applicationId);

    _cvInstances.removeWhere((i) => i.applicationId == applicationId);
    _coverLetterInstances.removeWhere((i) => i.applicationId == applicationId);

    notifyListeners();
  }

  /// Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }
}
