import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as p;
import 'log_service.dart';
import 'storage_service.dart';
import '../constants/json_constants.dart';
import '../models/job_application.dart';
import '../models/job_cv_data.dart';
import '../models/job_cover_letter.dart';
import '../models/master_profile.dart';
import '../models/template_customization.dart';
import '../models/template_style.dart';

/// Repository for job application persistence.
///
/// Handles application CRUD, job-specific CV/CL data, folder management,
/// profile cloning, and job-specific PDF settings.
class ApplicationRepository {
  ApplicationRepository(this._storageService);

  final StorageService _storageService;

  // ── Application CRUD ───────────────────────────────────────────────

  /// Load all job applications.
  Future<List<JobApplication>> loadAll() async {
    try {
      final userDataPath = await _storageService.getUserDataPath();
      final dir = Directory(p.join(userDataPath, 'applications'));
      final applications = <JobApplication>[];

      if (!dir.existsSync()) return applications;

      for (final file in dir.listSync().whereType<File>()) {
        if (file.path.endsWith('.json')) {
          try {
            final content = await file.readAsString();
            final json = jsonDecode(content) as Map<String, dynamic>;
            final app = JobApplication.fromJson(json);
            final resolvedPath =
                _storageService.toAbsolutePath(app.folderPath, userDataPath);
            applications.add(
              resolvedPath != app.folderPath
                  ? app.copyWith(folderPath: resolvedPath)
                  : app,
            );
          } catch (e) {
            logError('Error loading application ${file.path}',
                error: e, tag: 'AppRepo');
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
      logError('Error loading applications', error: e, tag: 'AppRepo');
      return [];
    }
  }

  /// Save a single job application.
  Future<void> save(JobApplication application) async {
    try {
      final userDataPath = await _storageService.getUserDataPath();
      final file = File(
          p.join(userDataPath, 'applications', '${application.id}.json'));

      final updatedApp = application.copyWith(lastUpdated: DateTime.now());
      final json = updatedApp.toJson();
      json['folderPath'] =
          _storageService.toRelativePath(json['folderPath'] as String?, userDataPath);
      await file.writeAsString(JsonConstants.prettyEncoder.convert(json));

      logInfo('Application saved: ${application.id}', tag: 'AppRepo');
    } catch (e) {
      logError('Error saving application', error: e, tag: 'AppRepo');
      rethrow;
    }
  }

  /// Delete an application and its folder.
  Future<void> delete(String id) async {
    try {
      final userDataPath = await _storageService.getUserDataPath();
      final file = File(p.join(userDataPath, 'applications', '$id.json'));

      // Load application to get folder path before deleting
      JobApplication? application;
      if (file.existsSync()) {
        try {
          final content = await file.readAsString();
          final json = jsonDecode(content) as Map<String, dynamic>;
          final app = JobApplication.fromJson(json);
          final resolvedPath =
              _storageService.toAbsolutePath(app.folderPath, userDataPath);
          application = resolvedPath != app.folderPath
              ? app.copyWith(folderPath: resolvedPath)
              : app;
        } catch (e) {
          logError('Error loading application for deletion',
              error: e, tag: 'AppRepo');
        }
      }

      // Delete the application folder and all its contents
      if (application?.folderPath != null) {
        final folderDir = Directory(application!.folderPath!);
        if (folderDir.existsSync()) {
          await folderDir.delete(recursive: true);
          logInfo('Application folder deleted: ${application.folderPath}',
              tag: 'AppRepo');
        }
      }

      // Delete the JSON metadata file
      if (file.existsSync()) {
        await file.delete();
        logInfo('Application metadata deleted: $id', tag: 'AppRepo');
      }
    } catch (e) {
      logError('Error deleting application', error: e, tag: 'AppRepo');
      rethrow;
    }
  }

  // ── Job Application Folder ─────────────────────────────────────────

  /// Create job application folder structure.
  Future<String> createFolder(JobApplication application) async {
    final userDataPath = await _storageService.getUserDataPath();
    final date = (application.applicationDate ?? DateTime.now())
        .toIso8601String()
        .split('T')[0];
    final sanitizedCompany =
        application.company.replaceAll(RegExp(r'[^\w\s-]'), '');
    final sanitizedPosition =
        application.position.replaceAll(RegExp(r'[^\w\s-]'), '');

    final folderName =
        '${date}_${sanitizedCompany}_${sanitizedPosition}_${application.id.substring(0, 8)}';
    final folderPath = p.join(userDataPath, 'applications', folderName);

    final dir = Directory(folderPath);
    if (!dir.existsSync()) {
      dir.createSync(recursive: true);

      // Create exports subfolder
      final exportsDir = Directory(p.join(folderPath, 'exports'));
      exportsDir.createSync();
    }

    return folderPath;
  }

  /// Clone master profile to job application.
  Future<void> cloneProfile(
    MasterProfile profile,
    JobApplication application,
  ) async {
    try {
      final userDataPath = await _storageService.getUserDataPath();
      final folderPath = await createFolder(application);

      logDebug(
          'Profile Summary from MasterProfile: "${profile.profileSummary}"',
          tag: 'AppRepo');

      // Clone CV data
      var cvData = JobCvData.fromMasterProfile(profile);

      logDebug(
          'CV Data Professional Summary: "${cvData.professionalSummary}"',
          tag: 'AppRepo');

      // Copy profile picture if it exists in master profile
      if (profile.personalInfo?.profilePicturePath != null &&
          profile.personalInfo!.profilePicturePath!.isNotEmpty) {
        try {
          final sourcePath = profile.personalInfo!.profilePicturePath!;
          final sourceFile = File(sourcePath);

          if (await sourceFile.exists()) {
            final extension = p.extension(sourcePath);
            final targetFileName = 'profile_picture$extension';
            final targetPath = p.join(folderPath, targetFileName);

            await sourceFile.copy(targetPath);
            logInfo('Profile picture copied successfully', tag: 'AppRepo');

            cvData = cvData.copyWith(
              personalInfo: profile.personalInfo!.copyWith(
                profilePicturePath: targetPath,
              ),
            );
          } else {
            logWarning('Source profile picture not found: $sourcePath',
                tag: 'AppRepo');
          }
        } catch (e) {
          logError('Error copying profile picture', error: e, tag: 'AppRepo');
          // Continue without profile picture - not a critical error
        }
      }

      final cvFile = File(p.join(folderPath, 'cv_data.json'));
      final cvJson = cvData.toJson();
      if (cvJson['personalInfo'] is Map<String, dynamic>) {
        final pi = cvJson['personalInfo'] as Map<String, dynamic>;
        pi['profilePicturePath'] = _storageService.toRelativePath(
          pi['profilePicturePath'] as String?,
          userDataPath,
        );
      }
      await cvFile
          .writeAsString(JsonConstants.prettyEncoder.convert(cvJson));

      // Clone cover letter with defaults from profile
      final coverLetter = JobCoverLetter.fromDefault(
        defaultBody: profile.defaultCoverLetterBody,
        companyName: application.company,
        defaultGreeting: profile.defaultGreeting,
        defaultClosing: profile.defaultClosing,
      );

      final clFile = File(p.join(folderPath, 'cl_data.json'));
      await clFile.writeAsString(
        JsonConstants.prettyEncoder.convert(coverLetter.toJson()),
      );

      // Create default PDF settings with the application's base language
      final pdfSettings =
          TemplateCustomization(language: application.baseLanguage.code);
      final pdfFile = File(p.join(folderPath, 'pdf_settings.json'));
      await pdfFile.writeAsString(
        JsonConstants.prettyEncoder.convert(pdfSettings.toJson()),
      );

      // Save application metadata with folder path
      final updatedApp = application.copyWith(folderPath: folderPath);
      await save(updatedApp);

      logInfo('Profile cloned to: $folderPath', tag: 'AppRepo');
    } catch (e) {
      logError('Error cloning profile to application',
          error: e, tag: 'AppRepo');
      rethrow;
    }
  }

  // ── Job-Specific CV Data ───────────────────────────────────────────

  /// Load job-specific CV data.
  Future<JobCvData?> loadCvData(String folderPath) async {
    try {
      final file = File(p.join(folderPath, 'cv_data.json'));
      if (!file.existsSync()) return null;

      final userDataPath = await _storageService.getUserDataPath();
      final content = await file.readAsString();
      final json = jsonDecode(content) as Map<String, dynamic>;
      if (json['personalInfo'] is Map<String, dynamic>) {
        final pi = json['personalInfo'] as Map<String, dynamic>;
        pi['profilePicturePath'] = _storageService.toAbsolutePath(
          pi['profilePicturePath'] as String?,
          userDataPath,
        );
      }
      return JobCvData.fromJson(json);
    } catch (e) {
      logError('Error loading job CV data', error: e, tag: 'AppRepo');
      return null;
    }
  }

  /// Save job-specific CV data.
  Future<void> saveCvData(String folderPath, JobCvData data) async {
    try {
      final file = File(p.join(folderPath, 'cv_data.json'));
      final userDataPath = await _storageService.getUserDataPath();
      final json = data.toJson();
      if (json['personalInfo'] is Map<String, dynamic>) {
        final pi = json['personalInfo'] as Map<String, dynamic>;
        pi['profilePicturePath'] = _storageService.toRelativePath(
          pi['profilePicturePath'] as String?,
          userDataPath,
        );
      }
      await file.writeAsString(JsonConstants.prettyEncoder.convert(json));
      logDebug('Job CV data saved', tag: 'AppRepo');
    } catch (e) {
      logError('Error saving job CV data', error: e, tag: 'AppRepo');
      rethrow;
    }
  }

  // ── Job-Specific Cover Letter ──────────────────────────────────────

  /// Load job-specific cover letter.
  Future<JobCoverLetter?> loadCoverLetter(String folderPath) async {
    try {
      final file = File(p.join(folderPath, 'cl_data.json'));
      if (!file.existsSync()) return null;

      final content = await file.readAsString();
      final json = jsonDecode(content) as Map<String, dynamic>;
      return JobCoverLetter.fromJson(json);
    } catch (e) {
      logError('Error loading job cover letter', error: e, tag: 'AppRepo');
      return null;
    }
  }

  /// Save job-specific cover letter.
  Future<void> saveCoverLetter(
      String folderPath, JobCoverLetter letter) async {
    try {
      final file = File(p.join(folderPath, 'cl_data.json'));
      await file.writeAsString(
        JsonConstants.prettyEncoder.convert(letter.toJson()),
      );
      logDebug('Job cover letter saved', tag: 'AppRepo');
    } catch (e) {
      logError('Error saving job cover letter', error: e, tag: 'AppRepo');
      rethrow;
    }
  }

  // ── Job-Specific PDF Settings ──────────────────────────────────────

  /// Load job-specific PDF settings (legacy - loads CV settings).
  Future<(TemplateStyle?, TemplateCustomization?)> loadPdfSettings(
      String folderPath) async {
    return loadCvPdfSettings(folderPath);
  }

  /// Load job-specific CV PDF settings.
  Future<(TemplateStyle?, TemplateCustomization?)> loadCvPdfSettings(
      String folderPath) async {
    final result = await _storageService
        .loadPdfSettings(p.join(folderPath, 'cv_pdf_settings.json'));
    if (result.$1 != null || result.$2 != null) return result;
    // Fall back to legacy file
    return _storageService
        .loadPdfSettings(p.join(folderPath, 'pdf_settings.json'));
  }

  /// Load job-specific Cover Letter PDF settings.
  Future<(TemplateStyle?, TemplateCustomization?)> loadClPdfSettings(
      String folderPath) async {
    final result = await _storageService
        .loadPdfSettings(p.join(folderPath, 'cl_pdf_settings.json'));
    if (result.$1 != null || result.$2 != null) return result;
    // Fall back to legacy file
    return _storageService
        .loadPdfSettings(p.join(folderPath, 'pdf_settings.json'));
  }

  /// Save job-specific PDF settings (legacy - saves to CV).
  Future<void> savePdfSettings(
    String folderPath,
    TemplateStyle style,
    TemplateCustomization customization,
  ) async {
    await saveCvPdfSettings(folderPath, style, customization);
  }

  /// Save job-specific CV PDF settings.
  Future<void> saveCvPdfSettings(
    String folderPath,
    TemplateStyle style,
    TemplateCustomization customization,
  ) async {
    await _storageService.savePdfSettings(
        p.join(folderPath, 'cv_pdf_settings.json'), style, customization);
  }

  /// Save job-specific Cover Letter PDF settings.
  Future<void> saveClPdfSettings(
    String folderPath,
    TemplateStyle style,
    TemplateCustomization customization,
  ) async {
    await _storageService.savePdfSettings(
        p.join(folderPath, 'cl_pdf_settings.json'), style, customization);
  }
}
