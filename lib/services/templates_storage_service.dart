import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import '../models/cv_template.dart';
import '../models/cover_letter_template.dart';

/// Storage service for CV and Cover Letter templates and instances
class TemplatesStorageService {
  TemplatesStorageService._();
  static final TemplatesStorageService instance = TemplatesStorageService._();

  String? _userDataPath;

  /// Get the portable UserData folder path
  Future<String> getUserDataPath() async {
    if (_userDataPath != null) return _userDataPath!;

    final exePath = Platform.resolvedExecutable;
    final exeDir = p.dirname(exePath);
    _userDataPath = p.join(exeDir, 'UserData');

    final userDataDir = Directory(_userDataPath!);
    if (!userDataDir.existsSync()) {
      userDataDir.createSync(recursive: true);
    }

    // Create subdirectories
    for (final subDir in [
      'cv_templates',
      'cover_letter_templates',
      'cv_instances',
      'cover_letter_instances'
    ]) {
      final dir = Directory(p.join(_userDataPath!, subDir));
      if (!dir.existsSync()) {
        dir.createSync(recursive: true);
      }
    }

    return _userDataPath!;
  }

  // ============================================================================
  // CV TEMPLATES
  // ============================================================================

  Future<List<CvTemplate>> loadCvTemplates() async {
    try {
      final userDataPath = await getUserDataPath();
      final dir = Directory(p.join(userDataPath, 'cv_templates'));
      final templates = <CvTemplate>[];

      if (!dir.existsSync()) return templates;

      for (final file in dir.listSync().whereType<File>()) {
        if (file.path.endsWith('.json')) {
          try {
            final content = await file.readAsString();
            final json = jsonDecode(content) as Map<String, dynamic>;
            templates.add(CvTemplate.fromJson(json));
          } catch (e) {
            debugPrint('Error loading CV template ${file.path}: $e');
          }
        }
      }

      templates.sort((a, b) {
        final aDate = a.lastModified ?? a.createdAt ?? DateTime(1970);
        final bDate = b.lastModified ?? b.createdAt ?? DateTime(1970);
        return bDate.compareTo(aDate);
      });

      return templates;
    } catch (e) {
      debugPrint('Error loading CV templates: $e');
      return [];
    }
  }

  Future<void> saveCvTemplate(CvTemplate template) async {
    try {
      final userDataPath = await getUserDataPath();
      final file =
          File(p.join(userDataPath, 'cv_templates', '${template.id}.json'));

      final updatedTemplate = template.copyWith(lastModified: DateTime.now());
      await file.writeAsString(
        const JsonEncoder.withIndent('  ').convert(updatedTemplate.toJson()),
      );

      debugPrint('CV template saved: ${template.id}');
    } catch (e) {
      debugPrint('Error saving CV template: $e');
      rethrow;
    }
  }

  Future<void> deleteCvTemplate(String id) async {
    try {
      final userDataPath = await getUserDataPath();
      final file = File(p.join(userDataPath, 'cv_templates', '$id.json'));

      if (file.existsSync()) {
        await file.delete();
        debugPrint('CV template deleted: $id');
      }
    } catch (e) {
      debugPrint('Error deleting CV template: $e');
      rethrow;
    }
  }

  Future<CvTemplate?> loadCvTemplate(String id) async {
    try {
      final userDataPath = await getUserDataPath();
      final file = File(p.join(userDataPath, 'cv_templates', '$id.json'));

      if (!file.existsSync()) return null;

      final content = await file.readAsString();
      final json = jsonDecode(content) as Map<String, dynamic>;
      return CvTemplate.fromJson(json);
    } catch (e) {
      debugPrint('Error loading CV template $id: $e');
      return null;
    }
  }

  // ============================================================================
  // COVER LETTER TEMPLATES
  // ============================================================================

  Future<List<CoverLetterTemplate>> loadCoverLetterTemplates() async {
    try {
      final userDataPath = await getUserDataPath();
      final dir = Directory(p.join(userDataPath, 'cover_letter_templates'));
      final templates = <CoverLetterTemplate>[];

      if (!dir.existsSync()) return templates;

      for (final file in dir.listSync().whereType<File>()) {
        if (file.path.endsWith('.json')) {
          try {
            final content = await file.readAsString();
            final json = jsonDecode(content) as Map<String, dynamic>;
            templates.add(CoverLetterTemplate.fromJson(json));
          } catch (e) {
            debugPrint('Error loading cover letter template ${file.path}: $e');
          }
        }
      }

      templates.sort((a, b) {
        final aDate = a.lastModified ?? a.createdAt ?? DateTime(1970);
        final bDate = b.lastModified ?? b.createdAt ?? DateTime(1970);
        return bDate.compareTo(aDate);
      });

      return templates;
    } catch (e) {
      debugPrint('Error loading cover letter templates: $e');
      return [];
    }
  }

  Future<void> saveCoverLetterTemplate(CoverLetterTemplate template) async {
    try {
      final userDataPath = await getUserDataPath();
      final file = File(p.join(
          userDataPath, 'cover_letter_templates', '${template.id}.json'));

      final updatedTemplate = template.copyWith(lastModified: DateTime.now());
      await file.writeAsString(
        const JsonEncoder.withIndent('  ').convert(updatedTemplate.toJson()),
      );

      debugPrint('Cover letter template saved: ${template.id}');
    } catch (e) {
      debugPrint('Error saving cover letter template: $e');
      rethrow;
    }
  }

  Future<void> deleteCoverLetterTemplate(String id) async {
    try {
      final userDataPath = await getUserDataPath();
      final file =
          File(p.join(userDataPath, 'cover_letter_templates', '$id.json'));

      if (file.existsSync()) {
        await file.delete();
        debugPrint('Cover letter template deleted: $id');
      }
    } catch (e) {
      debugPrint('Error deleting cover letter template: $e');
      rethrow;
    }
  }

  Future<CoverLetterTemplate?> loadCoverLetterTemplate(String id) async {
    try {
      final userDataPath = await getUserDataPath();
      final file =
          File(p.join(userDataPath, 'cover_letter_templates', '$id.json'));

      if (!file.existsSync()) return null;

      final content = await file.readAsString();
      final json = jsonDecode(content) as Map<String, dynamic>;
      return CoverLetterTemplate.fromJson(json);
    } catch (e) {
      debugPrint('Error loading cover letter template $id: $e');
      return null;
    }
  }

  // ============================================================================
  // CV INSTANCES
  // ============================================================================

  Future<List<CvInstance>> loadCvInstances() async {
    try {
      final userDataPath = await getUserDataPath();
      final dir = Directory(p.join(userDataPath, 'cv_instances'));
      final instances = <CvInstance>[];

      if (!dir.existsSync()) return instances;

      for (final file in dir.listSync().whereType<File>()) {
        if (file.path.endsWith('.json')) {
          try {
            final content = await file.readAsString();
            final json = jsonDecode(content) as Map<String, dynamic>;
            instances.add(CvInstance.fromJson(json));
          } catch (e) {
            debugPrint('Error loading CV instance ${file.path}: $e');
          }
        }
      }

      return instances;
    } catch (e) {
      debugPrint('Error loading CV instances: $e');
      return [];
    }
  }

  Future<void> saveCvInstance(CvInstance instance) async {
    try {
      final userDataPath = await getUserDataPath();
      final file =
          File(p.join(userDataPath, 'cv_instances', '${instance.id}.json'));

      final updatedInstance = instance.copyWith(lastModified: DateTime.now());
      await file.writeAsString(
        const JsonEncoder.withIndent('  ').convert(updatedInstance.toJson()),
      );

      debugPrint('CV instance saved: ${instance.id}');
    } catch (e) {
      debugPrint('Error saving CV instance: $e');
      rethrow;
    }
  }

  Future<void> deleteCvInstance(String id) async {
    try {
      final userDataPath = await getUserDataPath();
      final file = File(p.join(userDataPath, 'cv_instances', '$id.json'));

      if (file.existsSync()) {
        await file.delete();
        debugPrint('CV instance deleted: $id');
      }
    } catch (e) {
      debugPrint('Error deleting CV instance: $e');
      rethrow;
    }
  }

  Future<CvInstance?> loadCvInstance(String id) async {
    try {
      final userDataPath = await getUserDataPath();
      final file = File(p.join(userDataPath, 'cv_instances', '$id.json'));

      if (!file.existsSync()) return null;

      final content = await file.readAsString();
      final json = jsonDecode(content) as Map<String, dynamic>;
      return CvInstance.fromJson(json);
    } catch (e) {
      debugPrint('Error loading CV instance $id: $e');
      return null;
    }
  }

  // ============================================================================
  // COVER LETTER INSTANCES
  // ============================================================================

  Future<List<CoverLetterInstance>> loadCoverLetterInstances() async {
    try {
      final userDataPath = await getUserDataPath();
      final dir = Directory(p.join(userDataPath, 'cover_letter_instances'));
      final instances = <CoverLetterInstance>[];

      if (!dir.existsSync()) return instances;

      for (final file in dir.listSync().whereType<File>()) {
        if (file.path.endsWith('.json')) {
          try {
            final content = await file.readAsString();
            final json = jsonDecode(content) as Map<String, dynamic>;
            instances.add(CoverLetterInstance.fromJson(json));
          } catch (e) {
            debugPrint('Error loading cover letter instance ${file.path}: $e');
          }
        }
      }

      return instances;
    } catch (e) {
      debugPrint('Error loading cover letter instances: $e');
      return [];
    }
  }

  Future<void> saveCoverLetterInstance(CoverLetterInstance instance) async {
    try {
      final userDataPath = await getUserDataPath();
      final file = File(p.join(
          userDataPath, 'cover_letter_instances', '${instance.id}.json'));

      final updatedInstance = instance.copyWith(lastModified: DateTime.now());
      await file.writeAsString(
        const JsonEncoder.withIndent('  ').convert(updatedInstance.toJson()),
      );

      debugPrint('Cover letter instance saved: ${instance.id}');
    } catch (e) {
      debugPrint('Error saving cover letter instance: $e');
      rethrow;
    }
  }

  Future<void> deleteCoverLetterInstance(String id) async {
    try {
      final userDataPath = await getUserDataPath();
      final file =
          File(p.join(userDataPath, 'cover_letter_instances', '$id.json'));

      if (file.existsSync()) {
        await file.delete();
        debugPrint('Cover letter instance deleted: $id');
      }
    } catch (e) {
      debugPrint('Error deleting cover letter instance: $e');
      rethrow;
    }
  }

  Future<CoverLetterInstance?> loadCoverLetterInstance(String id) async {
    try {
      final userDataPath = await getUserDataPath();
      final file =
          File(p.join(userDataPath, 'cover_letter_instances', '$id.json'));

      if (!file.existsSync()) return null;

      final content = await file.readAsString();
      final json = jsonDecode(content) as Map<String, dynamic>;
      return CoverLetterInstance.fromJson(json);
    } catch (e) {
      debugPrint('Error loading cover letter instance $id: $e');
      return null;
    }
  }

  // ============================================================================
  // BULK OPERATIONS
  // ============================================================================

  /// Get instances for a specific application
  Future<List<CvInstance>> getCvInstancesForApplication(
      String applicationId) async {
    final allInstances = await loadCvInstances();
    return allInstances.where((i) => i.applicationId == applicationId).toList();
  }

  Future<List<CoverLetterInstance>> getCoverLetterInstancesForApplication(
      String applicationId) async {
    final allInstances = await loadCoverLetterInstances();
    return allInstances.where((i) => i.applicationId == applicationId).toList();
  }

  /// Delete all instances for an application (when deleting application)
  Future<void> deleteInstancesForApplication(String applicationId) async {
    final cvInstances = await getCvInstancesForApplication(applicationId);
    final clInstances =
        await getCoverLetterInstancesForApplication(applicationId);

    for (final instance in cvInstances) {
      await deleteCvInstance(instance.id);
    }

    for (final instance in clInstances) {
      await deleteCoverLetterInstance(instance.id);
    }
  }
}
