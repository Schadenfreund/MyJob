import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import '../models/job_application.dart';
import '../models/cv_data.dart';
import '../models/cover_letter.dart';

/// Storage service for persisting application data as JSON files
class StorageService {
  StorageService._();
  static final StorageService instance = StorageService._();

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
    for (final subDir in ['applications', 'cvs', 'cover_letters']) {
      final dir = Directory(p.join(_userDataPath!, subDir));
      if (!dir.existsSync()) {
        dir.createSync(recursive: true);
      }
    }

    return _userDataPath!;
  }

  // ============================================================================
  // JOB APPLICATIONS
  // ============================================================================

  Future<List<JobApplication>> loadApplications() async {
    try {
      final userDataPath = await getUserDataPath();
      final dir = Directory(p.join(userDataPath, 'applications'));
      final applications = <JobApplication>[];

      if (!dir.existsSync()) return applications;

      for (final file in dir.listSync().whereType<File>()) {
        if (file.path.endsWith('.json')) {
          try {
            final content = await file.readAsString();
            final json = jsonDecode(content) as Map<String, dynamic>;
            applications.add(JobApplication.fromJson(json));
          } catch (e) {
            debugPrint('Error loading application ${file.path}: $e');
          }
        }
      }

      // Sort by last updated, newest first
      applications.sort((a, b) {
        final aDate = a.lastUpdated ?? a.applicationDate ?? DateTime(1970);
        final bDate = b.lastUpdated ?? b.applicationDate ?? DateTime(1970);
        return bDate.compareTo(aDate);
      });

      return applications;
    } catch (e) {
      debugPrint('Error loading applications: $e');
      return [];
    }
  }

  Future<void> saveApplication(JobApplication application) async {
    try {
      final userDataPath = await getUserDataPath();
      final file =
          File(p.join(userDataPath, 'applications', '${application.id}.json'));

      final updatedApp = application.copyWith(lastUpdated: DateTime.now());
      await file.writeAsString(
        const JsonEncoder.withIndent('  ').convert(updatedApp.toJson()),
      );

      debugPrint('Application saved: ${application.id}');
    } catch (e) {
      debugPrint('Error saving application: $e');
      rethrow;
    }
  }

  Future<void> deleteApplication(String id) async {
    try {
      final userDataPath = await getUserDataPath();
      final file = File(p.join(userDataPath, 'applications', '$id.json'));

      if (file.existsSync()) {
        await file.delete();
        debugPrint('Application deleted: $id');
      }
    } catch (e) {
      debugPrint('Error deleting application: $e');
      rethrow;
    }
  }

  // ============================================================================
  // CVS
  // ============================================================================

  Future<List<CvData>> loadCvs() async {
    try {
      final userDataPath = await getUserDataPath();
      final dir = Directory(p.join(userDataPath, 'cvs'));
      final cvs = <CvData>[];

      if (!dir.existsSync()) return cvs;

      for (final file in dir.listSync().whereType<File>()) {
        if (file.path.endsWith('.json')) {
          try {
            final content = await file.readAsString();
            final json = jsonDecode(content) as Map<String, dynamic>;
            cvs.add(CvData.fromJson(json));
          } catch (e) {
            debugPrint('Error loading CV ${file.path}: $e');
          }
        }
      }

      // Sort by last modified, newest first
      cvs.sort((a, b) {
        final aDate = a.lastModified ?? DateTime(1970);
        final bDate = b.lastModified ?? DateTime(1970);
        return bDate.compareTo(aDate);
      });

      return cvs;
    } catch (e) {
      debugPrint('Error loading CVs: $e');
      return [];
    }
  }

  Future<void> saveCv(CvData cv) async {
    try {
      final userDataPath = await getUserDataPath();
      final file = File(p.join(userDataPath, 'cvs', '${cv.id}.json'));

      final updatedCv = cv.copyWith(lastModified: DateTime.now());
      await file.writeAsString(
        const JsonEncoder.withIndent('  ').convert(updatedCv.toJson()),
      );

      debugPrint('CV saved: ${cv.id}');
    } catch (e) {
      debugPrint('Error saving CV: $e');
      rethrow;
    }
  }

  Future<void> deleteCv(String id) async {
    try {
      final userDataPath = await getUserDataPath();
      final file = File(p.join(userDataPath, 'cvs', '$id.json'));

      if (file.existsSync()) {
        await file.delete();
        debugPrint('CV deleted: $id');
      }
    } catch (e) {
      debugPrint('Error deleting CV: $e');
      rethrow;
    }
  }

  Future<CvData?> loadCv(String id) async {
    try {
      final userDataPath = await getUserDataPath();
      final file = File(p.join(userDataPath, 'cvs', '$id.json'));

      if (!file.existsSync()) return null;

      final content = await file.readAsString();
      final json = jsonDecode(content) as Map<String, dynamic>;
      return CvData.fromJson(json);
    } catch (e) {
      debugPrint('Error loading CV $id: $e');
      return null;
    }
  }

  // ============================================================================
  // COVER LETTERS
  // ============================================================================

  Future<List<CoverLetter>> loadCoverLetters() async {
    try {
      final userDataPath = await getUserDataPath();
      final dir = Directory(p.join(userDataPath, 'cover_letters'));
      final letters = <CoverLetter>[];

      if (!dir.existsSync()) return letters;

      for (final file in dir.listSync().whereType<File>()) {
        if (file.path.endsWith('.json')) {
          try {
            final content = await file.readAsString();
            final json = jsonDecode(content) as Map<String, dynamic>;
            letters.add(CoverLetter.fromJson(json));
          } catch (e) {
            debugPrint('Error loading cover letter ${file.path}: $e');
          }
        }
      }

      // Sort by last modified, newest first
      letters.sort((a, b) {
        final aDate = a.lastModified ?? DateTime(1970);
        final bDate = b.lastModified ?? DateTime(1970);
        return bDate.compareTo(aDate);
      });

      return letters;
    } catch (e) {
      debugPrint('Error loading cover letters: $e');
      return [];
    }
  }

  Future<void> saveCoverLetter(CoverLetter letter) async {
    try {
      final userDataPath = await getUserDataPath();
      final file =
          File(p.join(userDataPath, 'cover_letters', '${letter.id}.json'));

      final updatedLetter = letter.copyWith(lastModified: DateTime.now());
      await file.writeAsString(
        const JsonEncoder.withIndent('  ').convert(updatedLetter.toJson()),
      );

      debugPrint('Cover letter saved: ${letter.id}');
    } catch (e) {
      debugPrint('Error saving cover letter: $e');
      rethrow;
    }
  }

  Future<void> deleteCoverLetter(String id) async {
    try {
      final userDataPath = await getUserDataPath();
      final file = File(p.join(userDataPath, 'cover_letters', '$id.json'));

      if (file.existsSync()) {
        await file.delete();
        debugPrint('Cover letter deleted: $id');
      }
    } catch (e) {
      debugPrint('Error deleting cover letter: $e');
      rethrow;
    }
  }

  Future<CoverLetter?> loadCoverLetter(String id) async {
    try {
      final userDataPath = await getUserDataPath();
      final file = File(p.join(userDataPath, 'cover_letters', '$id.json'));

      if (!file.existsSync()) return null;

      final content = await file.readAsString();
      final json = jsonDecode(content) as Map<String, dynamic>;
      return CoverLetter.fromJson(json);
    } catch (e) {
      debugPrint('Error loading cover letter $id: $e');
      return null;
    }
  }

  // ============================================================================
  // EXPORT / IMPORT
  // ============================================================================

  Future<String> exportAllData() async {
    final applications = await loadApplications();
    final cvs = await loadCvs();
    final coverLetters = await loadCoverLetters();

    final exportData = {
      'version': '1.0',
      'exportDate': DateTime.now().toIso8601String(),
      'applications': applications.map((a) => a.toJson()).toList(),
      'cvs': cvs.map((c) => c.toJson()).toList(),
      'coverLetters': coverLetters.map((l) => l.toJson()).toList(),
    };

    return const JsonEncoder.withIndent('  ').convert(exportData);
  }

  Future<void> importData(String jsonData) async {
    try {
      final data = jsonDecode(jsonData) as Map<String, dynamic>;

      // Import applications
      if (data['applications'] != null) {
        for (final appJson in data['applications'] as List) {
          final app = JobApplication.fromJson(appJson as Map<String, dynamic>);
          await saveApplication(app);
        }
      }

      // Import CVs
      if (data['cvs'] != null) {
        for (final cvJson in data['cvs'] as List) {
          final cv = CvData.fromJson(cvJson as Map<String, dynamic>);
          await saveCv(cv);
        }
      }

      // Import cover letters
      if (data['coverLetters'] != null) {
        for (final letterJson in data['coverLetters'] as List) {
          final letter =
              CoverLetter.fromJson(letterJson as Map<String, dynamic>);
          await saveCoverLetter(letter);
        }
      }

      debugPrint('Data imported successfully');
    } catch (e) {
      debugPrint('Error importing data: $e');
      rethrow;
    }
  }
}
