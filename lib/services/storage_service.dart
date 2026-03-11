import 'dart:convert';
import 'dart:io';
import 'log_service.dart';
import 'package:path/path.dart' as p;
import 'package:yaml/yaml.dart';
import '../models/job_application.dart';
import '../models/cv_data.dart';
import '../models/cover_letter.dart';
import '../models/master_profile.dart';
import '../models/job_cv_data.dart';
import '../models/job_cover_letter.dart';
import '../models/notes_data.dart';
import '../constants/json_constants.dart';
import '../models/template_customization.dart';
import '../models/template_style.dart';

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

    // Create base directory structure
    for (final subDir in [
      'applications',
      'pdf_presets',
      'notes',
      'cvs', // Legacy
      'cover_letters' // Legacy
    ]) {
      final dir = Directory(p.join(_userDataPath!, subDir));
      if (!dir.existsSync()) {
        dir.createSync(recursive: true);
      }
    }

    return _userDataPath!;
  }

  // ============================================================================
  // PATH PORTABILITY HELPERS
  // ============================================================================

  /// Convert a stored path (relative or stale absolute) to an absolute runtime path.
  ///
  /// Handles three cases:
  /// - Relative path (new format) → joins with userDataPath.
  /// - Absolute and already under the current userDataPath → returned as-is.
  /// - Stale absolute from a previous UserData location → the relative portion
  ///   is recovered by scanning for the first known top-level UserData directory
  ///   name from the right, then re-anchored to the current userDataPath.
  String? _toAbsolutePath(String? stored, String userDataPath) {
    if (stored == null || stored.isEmpty) return stored;
    final norm = p.normalize(stored);
    if (!p.isAbsolute(norm)) {
      return p.normalize(p.join(userDataPath, norm));
    }
    final base = p.normalize(userDataPath);
    if (norm == base || p.isWithin(base, norm)) return norm;
    // Stale absolute path from a moved UserData location.
    // Recover the relative portion by finding the last segment that matches a
    // known top-level UserData subdirectory (scanning right-to-left so that a
    // coincidental occurrence earlier in the path is ignored).
    const knownDirs = {
      'applications',
      'profiles',
      'notes',
      'pdf_presets',
      'profile_pictures',
      'cvs',
      'cover_letters',
    };
    final segments = p.split(norm);
    for (int i = segments.length - 1; i >= 0; i--) {
      if (knownDirs.contains(segments[i])) {
        return p.normalize(p.joinAll([userDataPath, ...segments.sublist(i)]));
      }
    }
    return stored; // Unknown structure – leave unchanged.
  }

  /// Convert an absolute path that lives inside UserData to a path relative to
  /// userDataPath (for storage in JSON).
  ///
  /// Paths that are not under userDataPath are returned unchanged.
  String? _toRelativePath(String? absolute, String userDataPath) {
    if (absolute == null || absolute.isEmpty) return absolute;
    final norm = p.normalize(absolute);
    final base = p.normalize(userDataPath);
    if (p.isWithin(base, norm)) {
      return p.relative(norm, from: base);
    }
    return absolute;
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
            final app = JobApplication.fromJson(json);
            final resolvedPath = _toAbsolutePath(app.folderPath, userDataPath);
            applications.add(
              resolvedPath != app.folderPath
                  ? app.copyWith(folderPath: resolvedPath)
                  : app,
            );
          } catch (e) {
            logError('Error loading application ${file.path}', error: e, tag: 'Storage');
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
      logError('Error loading applications', error: e, tag: 'Storage');
      return [];
    }
  }

  Future<void> saveApplication(JobApplication application) async {
    try {
      final userDataPath = await getUserDataPath();
      final file =
          File(p.join(userDataPath, 'applications', '${application.id}.json'));

      final updatedApp = application.copyWith(lastUpdated: DateTime.now());
      final json = updatedApp.toJson();
      json['folderPath'] = _toRelativePath(json['folderPath'] as String?, userDataPath);
      await file.writeAsString(JsonConstants.prettyEncoder.convert(json));

      logInfo('Application saved: ${application.id}', tag: 'Storage');
    } catch (e) {
      logError('Error saving application', error: e, tag: 'Storage');
      rethrow;
    }
  }

  Future<void> deleteApplication(String id) async {
    try {
      final userDataPath = await getUserDataPath();
      final file = File(p.join(userDataPath, 'applications', '$id.json'));

      // Load application to get folder path before deleting
      JobApplication? application;
      if (file.existsSync()) {
        try {
          final content = await file.readAsString();
          final json = jsonDecode(content) as Map<String, dynamic>;
          final app = JobApplication.fromJson(json);
          final resolvedPath = _toAbsolutePath(app.folderPath, userDataPath);
          application = resolvedPath != app.folderPath
              ? app.copyWith(folderPath: resolvedPath)
              : app;
        } catch (e) {
          logError('Error loading application for deletion', error: e, tag: 'Storage');
        }
      }

      // Delete the application folder and all its contents
      if (application?.folderPath != null) {
        final folderDir = Directory(application!.folderPath!);
        if (folderDir.existsSync()) {
          await folderDir.delete(recursive: true);
          logInfo('Application folder deleted: ${application.folderPath}', tag: 'Storage');
        }
      }

      // Delete the JSON metadata file
      if (file.existsSync()) {
        await file.delete();
        logInfo('Application metadata deleted: $id', tag: 'Storage');
      }
    } catch (e) {
      logError('Error deleting application', error: e, tag: 'Storage');
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
            logError('Error loading CV ${file.path}', error: e, tag: 'Storage');
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
      logError('Error loading CVs', error: e, tag: 'Storage');
      return [];
    }
  }

  Future<void> saveCv(CvData cv) async {
    try {
      final userDataPath = await getUserDataPath();
      final file = File(p.join(userDataPath, 'cvs', '${cv.id}.json'));

      final updatedCv = cv.copyWith(lastModified: DateTime.now());
      await file.writeAsString(
        JsonConstants.prettyEncoder.convert(updatedCv.toJson()),
      );

      logInfo('CV saved: ${cv.id}', tag: 'Storage');
    } catch (e) {
      logError('Error saving CV', error: e, tag: 'Storage');
      rethrow;
    }
  }

  Future<void> deleteCv(String id) async {
    try {
      final userDataPath = await getUserDataPath();
      final file = File(p.join(userDataPath, 'cvs', '$id.json'));

      if (file.existsSync()) {
        await file.delete();
        logInfo('CV deleted: $id', tag: 'Storage');
      }
    } catch (e) {
      logError('Error deleting CV', error: e, tag: 'Storage');
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
      logError('Error loading CV $id', error: e, tag: 'Storage');
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
            logError('Error loading cover letter ${file.path}', error: e, tag: 'Storage');
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
      logError('Error loading cover letters', error: e, tag: 'Storage');
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
        JsonConstants.prettyEncoder.convert(updatedLetter.toJson()),
      );

      logInfo('Cover letter saved: ${letter.id}', tag: 'Storage');
    } catch (e) {
      logError('Error saving cover letter', error: e, tag: 'Storage');
      rethrow;
    }
  }

  Future<void> deleteCoverLetter(String id) async {
    try {
      final userDataPath = await getUserDataPath();
      final file = File(p.join(userDataPath, 'cover_letters', '$id.json'));

      if (file.existsSync()) {
        await file.delete();
        logInfo('Cover letter deleted: $id', tag: 'Storage');
      }
    } catch (e) {
      logError('Error deleting cover letter', error: e, tag: 'Storage');
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
      logError('Error loading cover letter $id', error: e, tag: 'Storage');
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
    final notes = await loadNotes();

    final exportData = {
      'version': '1.0',
      'exportDate': DateTime.now().toIso8601String(),
      'applications': applications.map((a) => a.toJson()).toList(),
      'cvs': cvs.map((c) => c.toJson()).toList(),
      'coverLetters': coverLetters.map((l) => l.toJson()).toList(),
      'notes': notes.map((n) => n.toJson()).toList(),
    };

    return JsonConstants.prettyEncoder.convert(exportData);
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

      // Import notes
      if (data['notes'] != null) {
        for (final noteJson in data['notes'] as List) {
          final note = NoteItem.fromJson(noteJson as Map<String, dynamic>);
          await saveNote(note);
        }
      }

      logInfo('Data imported successfully', tag: 'Storage');
    } catch (e) {
      logError('Error importing data', error: e, tag: 'Storage');
      rethrow;
    }
  }

  // ============================================================================
  // MASTER PROFILES (Bilingual Support)
  // ============================================================================

  /// Discover all profile language codes by scanning the profiles/ directory
  Future<List<String>> discoverProfileLanguageCodes() async {
    try {
      final userDataPath = await getUserDataPath();
      final profilesDir = Directory(p.join(userDataPath, 'profiles'));
      if (!profilesDir.existsSync()) return [];
      final codes = <String>[];
      for (final entity in profilesDir.listSync()) {
        if (entity is Directory) {
          final dataFile = File(p.join(entity.path, 'base_data.json'));
          if (dataFile.existsSync()) {
            codes.add(p.basename(entity.path));
          }
        }
      }
      return codes;
    } catch (e) {
      logError('Error discovering profile language codes', error: e, tag: 'Storage');
      return [];
    }
  }

  /// Delete the entire profile folder for a language
  Future<void> deleteProfileFolder(String langCode) async {
    try {
      final userDataPath = await getUserDataPath();
      final dir = Directory(p.join(userDataPath, 'profiles', langCode));
      if (dir.existsSync()) {
        await dir.delete(recursive: true);
        logInfo('Profile folder deleted ($langCode)', tag: 'Storage');
      }
    } catch (e) {
      logError('Error deleting profile folder ($langCode)', error: e, tag: 'Storage');
      rethrow;
    }
  }

  /// Load master profile for a specific language code
  Future<MasterProfile> loadMasterProfile(String langCode) async {
    try {
      final userDataPath = await getUserDataPath();
      final file = File(
          p.join(userDataPath, 'profiles', langCode, 'base_data.json'));

      if (!file.existsSync()) {
        return MasterProfile.empty(langCode);
      }

      final content = await file.readAsString();
      final json = jsonDecode(content) as Map<String, dynamic>;
      if (json['personalInfo'] is Map<String, dynamic>) {
        final pi = json['personalInfo'] as Map<String, dynamic>;
        pi['profilePicturePath'] = _toAbsolutePath(
          pi['profilePicturePath'] as String?,
          userDataPath,
        );
      }
      return MasterProfile.fromJson(json);
    } catch (e) {
      logError('Error loading master profile ($langCode)', error: e, tag: 'Storage');
      return MasterProfile.empty(langCode);
    }
  }

  /// Save master profile
  Future<void> saveMasterProfile(MasterProfile profile) async {
    try {
      final userDataPath = await getUserDataPath();
      final dir = Directory(p.join(userDataPath, 'profiles', profile.language));
      if (!dir.existsSync()) {
        dir.createSync(recursive: true);
      }
      final file = File(p.join(dir.path, 'base_data.json'));

      final json = profile.toJson();
      if (json['personalInfo'] is Map<String, dynamic>) {
        final pi = json['personalInfo'] as Map<String, dynamic>;
        pi['profilePicturePath'] = _toRelativePath(
          pi['profilePicturePath'] as String?,
          userDataPath,
        );
      }
      await file.writeAsString(JsonConstants.prettyEncoder.convert(json));

      logInfo('Master profile saved (${profile.language})', tag: 'Storage');
    } catch (e) {
      logError('Error saving master profile', error: e, tag: 'Storage');
      rethrow;
    }
  }

  // ============================================================================
  // JOB-SPECIFIC DATA (Per-Application Storage)
  // ============================================================================

  /// Create job application folder structure
  Future<String> createJobApplicationFolder(JobApplication application) async {
    final userDataPath = await getUserDataPath();
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

  /// Clone master profile to job application
  Future<void> cloneProfileToApplication(
    MasterProfile profile,
    JobApplication application,
  ) async {
    try {
      final userDataPath = await getUserDataPath();
      final folderPath = await createJobApplicationFolder(application);

      // Debug: Check what's being cloned
      logDebug('Profile Summary from MasterProfile: "${profile.profileSummary}"', tag: 'Storage');
      logDebug('Profile Summary length: ${profile.profileSummary.length}', tag: 'Storage');

      // Clone CV data
      var cvData = JobCvData.fromMasterProfile(profile);

      // Debug: Verify it was copied
      logDebug('CV Data Professional Summary: "${cvData.professionalSummary}"', tag: 'Storage');
      logDebug('CV Data Professional Summary length: ${cvData.professionalSummary.length}', tag: 'Storage');

      // Debug: Check profile picture state
      logDebug('=== Profile Picture Cloning ===', tag: 'Storage');
      logDebug('Has PersonalInfo: ${profile.personalInfo != null}', tag: 'Storage');
      if (profile.personalInfo != null) {
        logDebug('Profile picture path: "${profile.personalInfo!.profilePicturePath}"', tag: 'Storage');
        logDebug('Has profile picture: ${profile.personalInfo!.hasProfilePicture}', tag: 'Storage');
      }

      // Copy profile picture if it exists in master profile
      if (profile.personalInfo?.profilePicturePath != null &&
          profile.personalInfo!.profilePicturePath!.isNotEmpty) {
        try {
          final sourcePath = profile.personalInfo!.profilePicturePath!;
          logDebug('Attempting to copy from: $sourcePath', tag: 'Storage');

          final sourceFile = File(sourcePath);
          final fileExists = await sourceFile.exists();
          logDebug('Source file exists: $fileExists', tag: 'Storage');

          if (fileExists) {
            // Determine file extension
            final extension = p.extension(sourcePath);
            final targetFileName = 'profile_picture$extension';
            final targetPath = p.join(folderPath, targetFileName);

            logDebug('Copying to: $targetPath', tag: 'Storage');

            // Copy the file
            await sourceFile.copy(targetPath);

            logInfo('Profile picture copied successfully', tag: 'Storage');

            // Update CV data with new path
            cvData = cvData.copyWith(
              personalInfo: profile.personalInfo!.copyWith(
                profilePicturePath: targetPath,
              ),
            );

            logDebug('CV data updated with new path', tag: 'Storage');
          } else {
            logWarning('Source profile picture not found: $sourcePath', tag: 'Storage');
          }
        } catch (e) {
          logError('Error copying profile picture', error: e, tag: 'Storage');
          // Continue without profile picture - not a critical error
        }
      } else {
        logDebug('No profile picture to copy (path is null or empty)', tag: 'Storage');
      }

      final cvFile = File(p.join(folderPath, 'cv_data.json'));
      final cvJson = cvData.toJson();
      if (cvJson['personalInfo'] is Map<String, dynamic>) {
        final pi = cvJson['personalInfo'] as Map<String, dynamic>;
        pi['profilePicturePath'] = _toRelativePath(
          pi['profilePicturePath'] as String?,
          userDataPath,
        );
      }
      await cvFile.writeAsString(JsonConstants.prettyEncoder.convert(cvJson));

      // Clone cover letter with defaults from profile
      logDebug('Default cover letter body length: ${profile.defaultCoverLetterBody.length}', tag: 'Storage');
      logDebug('Default cover letter preview: "${profile.defaultCoverLetterBody.length > 50 ? '${profile.defaultCoverLetterBody.substring(0, 50)}...' : profile.defaultCoverLetterBody}"', tag: 'Storage');
      logDebug('Default greeting: "${profile.defaultGreeting}"', tag: 'Storage');
      logDebug('Default closing: "${profile.defaultClosing}"', tag: 'Storage');

      final coverLetter = JobCoverLetter.fromDefault(
        defaultBody: profile.defaultCoverLetterBody,
        companyName: application.company,
        defaultGreeting: profile.defaultGreeting,
        defaultClosing: profile.defaultClosing,
      );

      logDebug('JobCoverLetter body length: ${coverLetter.body.length}', tag: 'Storage');
      logDebug('JobCoverLetter greeting: "${coverLetter.greeting}"', tag: 'Storage');
      logDebug('JobCoverLetter closing: "${coverLetter.closing}"', tag: 'Storage');

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
      await saveApplication(updatedApp);

      logInfo('Profile cloned to: $folderPath', tag: 'Storage');
    } catch (e) {
      logError('Error cloning profile to application', error: e, tag: 'Storage');
      rethrow;
    }
  }

  /// Load job-specific CV data
  Future<JobCvData?> loadJobCvData(String folderPath) async {
    try {
      final file = File(p.join(folderPath, 'cv_data.json'));
      if (!file.existsSync()) return null;

      final userDataPath = await getUserDataPath();
      final content = await file.readAsString();
      final json = jsonDecode(content) as Map<String, dynamic>;
      if (json['personalInfo'] is Map<String, dynamic>) {
        final pi = json['personalInfo'] as Map<String, dynamic>;
        pi['profilePicturePath'] = _toAbsolutePath(
          pi['profilePicturePath'] as String?,
          userDataPath,
        );
      }
      return JobCvData.fromJson(json);
    } catch (e) {
      logError('Error loading job CV data', error: e, tag: 'Storage');
      return null;
    }
  }

  /// Save job-specific CV data
  Future<void> saveJobCvData(String folderPath, JobCvData data) async {
    try {
      final file = File(p.join(folderPath, 'cv_data.json'));
      final userDataPath = await getUserDataPath();
      final json = data.toJson();
      if (json['personalInfo'] is Map<String, dynamic>) {
        final pi = json['personalInfo'] as Map<String, dynamic>;
        pi['profilePicturePath'] = _toRelativePath(
          pi['profilePicturePath'] as String?,
          userDataPath,
        );
      }
      await file.writeAsString(JsonConstants.prettyEncoder.convert(json));
      logDebug('Job CV data saved', tag: 'Storage');
    } catch (e) {
      logError('Error saving job CV data', error: e, tag: 'Storage');
      rethrow;
    }
  }

  /// Load job-specific cover letter
  Future<JobCoverLetter?> loadJobCoverLetter(String folderPath) async {
    try {
      final file = File(p.join(folderPath, 'cl_data.json'));
      if (!file.existsSync()) return null;

      final content = await file.readAsString();
      final json = jsonDecode(content) as Map<String, dynamic>;
      return JobCoverLetter.fromJson(json);
    } catch (e) {
      logError('Error loading job cover letter', error: e, tag: 'Storage');
      return null;
    }
  }

  /// Save job-specific cover letter
  Future<void> saveJobCoverLetter(
      String folderPath, JobCoverLetter letter) async {
    try {
      final file = File(p.join(folderPath, 'cl_data.json'));
      await file.writeAsString(
        JsonConstants.prettyEncoder.convert(letter.toJson()),
      );
      logDebug('Job cover letter saved', tag: 'Storage');
    } catch (e) {
      logError('Error saving job cover letter', error: e, tag: 'Storage');
      rethrow;
    }
  }

  // ── Generic PDF Settings I/O ──────────────────────────────────────────

  /// Load style + customization from a JSON file with `style` and
  /// `customization` keys. Returns `(null, null)` if the file does
  /// not exist or cannot be parsed.
  Future<(TemplateStyle?, TemplateCustomization?)> _loadPdfSettings(
      String filePath) async {
    try {
      final file = File(filePath);
      if (!file.existsSync()) return (null, null);

      final content = await file.readAsString();
      final json = jsonDecode(content) as Map<String, dynamic>;

      final style = json.containsKey('style')
          ? TemplateStyle.fromJson(json['style'] as Map<String, dynamic>)
          : null;

      final customization = json.containsKey('customization')
          ? TemplateCustomization.fromJson(
              json['customization'] as Map<String, dynamic>)
          : null;

      return (style, customization);
    } catch (e) {
      logError('Error loading PDF settings from $filePath', error: e, tag: 'Storage');
      return (null, null);
    }
  }

  /// Save style + customization to a JSON file.
  Future<void> _savePdfSettings(
    String filePath,
    TemplateStyle style,
    TemplateCustomization customization,
  ) async {
    try {
      final file = File(filePath);
      final settings = {
        'style': style.toJson(),
        'customization': customization.toJson(),
      };
      await file.writeAsString(
        JsonConstants.prettyEncoder.convert(settings),
      );
    } catch (e) {
      logError('Error saving PDF settings to $filePath', error: e, tag: 'Storage');
      rethrow;
    }
  }

  // ── Job-Specific PDF Settings ───────────────────────────────────────

  /// Load job-specific PDF settings (legacy - loads CV settings)
  Future<(TemplateStyle?, TemplateCustomization?)> loadJobPdfSettings(
      String folderPath) async {
    return loadJobCvPdfSettings(folderPath);
  }

  /// Load job-specific CV PDF settings
  Future<(TemplateStyle?, TemplateCustomization?)> loadJobCvPdfSettings(
      String folderPath) async {
    final result =
        await _loadPdfSettings(p.join(folderPath, 'cv_pdf_settings.json'));
    if (result.$1 != null || result.$2 != null) return result;
    // Fall back to legacy file
    return _loadPdfSettings(p.join(folderPath, 'pdf_settings.json'));
  }

  /// Load job-specific Cover Letter PDF settings
  Future<(TemplateStyle?, TemplateCustomization?)> loadJobClPdfSettings(
      String folderPath) async {
    final result =
        await _loadPdfSettings(p.join(folderPath, 'cl_pdf_settings.json'));
    if (result.$1 != null || result.$2 != null) return result;
    // Fall back to legacy file
    return _loadPdfSettings(p.join(folderPath, 'pdf_settings.json'));
  }

  /// Save job-specific PDF settings (legacy - saves to CV)
  Future<void> saveJobPdfSettings(
    String folderPath,
    TemplateStyle style,
    TemplateCustomization customization,
  ) async {
    await saveJobCvPdfSettings(folderPath, style, customization);
  }

  /// Save job-specific CV PDF settings
  Future<void> saveJobCvPdfSettings(
    String folderPath,
    TemplateStyle style,
    TemplateCustomization customization,
  ) async {
    await _savePdfSettings(
        p.join(folderPath, 'cv_pdf_settings.json'), style, customization);
  }

  /// Save job-specific Cover Letter PDF settings
  Future<void> saveJobClPdfSettings(
    String folderPath,
    TemplateStyle style,
    TemplateCustomization customization,
  ) async {
    await _savePdfSettings(
        p.join(folderPath, 'cl_pdf_settings.json'), style, customization);
  }

  // ============================================================================
  // MASTER PROFILE PDF SETTINGS (Default Presets)
  // ============================================================================

  /// Load master profile CV PDF settings
  Future<(TemplateStyle?, TemplateCustomization?)>
      loadMasterProfileCvPdfSettings(String langCode) async {
    final userDataPath = await getUserDataPath();
    return _loadPdfSettings(
        p.join(userDataPath, 'profiles', langCode, 'cv_pdf_settings.json'));
  }

  /// Save master profile CV PDF settings
  Future<void> saveMasterProfileCvPdfSettings(
    String langCode,
    TemplateStyle style,
    TemplateCustomization customization,
  ) async {
    final userDataPath = await getUserDataPath();
    await _savePdfSettings(
      p.join(userDataPath, 'profiles', langCode, 'cv_pdf_settings.json'),
      style,
      customization,
    );
  }

  /// Load master profile Cover Letter PDF settings
  Future<(TemplateStyle?, TemplateCustomization?)>
      loadMasterProfileClPdfSettings(String langCode) async {
    final userDataPath = await getUserDataPath();
    return _loadPdfSettings(
        p.join(userDataPath, 'profiles', langCode, 'cl_pdf_settings.json'));
  }

  /// Save master profile Cover Letter PDF settings
  Future<void> saveMasterProfileClPdfSettings(
    String langCode,
    TemplateStyle style,
    TemplateCustomization customization,
  ) async {
    final userDataPath = await getUserDataPath();
    await _savePdfSettings(
      p.join(userDataPath, 'profiles', langCode, 'cl_pdf_settings.json'),
      style,
      customization,
    );
  }

  // ============================================================================
  // NOTES
  // ============================================================================

  /// Load all notes
  Future<List<NoteItem>> loadNotes() async {
    try {
      final userDataPath = await getUserDataPath();
      final dir = Directory(p.join(userDataPath, 'notes'));
      final notes = <NoteItem>[];

      if (!dir.existsSync()) return notes;

      for (final file in dir.listSync().whereType<File>()) {
        if (file.path.endsWith('.yaml') || file.path.endsWith('.yml')) {
          try {
            final content = await file.readAsString();
            final yaml = loadYaml(content);

            if (yaml is! YamlMap) {
              logWarning(
                  '${file.path} does not contain a valid YAML map, skipping', tag: 'Storage');
              continue;
            }

            final json = _yamlToJson(yaml);
            notes.add(NoteItem.fromJson(json));
          } catch (e, stackTrace) {
            logError('Error loading note ${file.path}', error: e, stackTrace: stackTrace, tag: 'Storage');
            // Continue loading other notes even if one fails
          }
        }
      }

      // Sort by created date, newest first
      notes.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      return notes;
    } catch (e) {
      logError('Error loading notes', error: e, tag: 'Storage');
      return [];
    }
  }

  /// Save a note
  Future<void> saveNote(NoteItem note) async {
    try {
      final userDataPath = await getUserDataPath();
      final notesDir = Directory(p.join(userDataPath, 'notes'));

      if (!notesDir.existsSync()) {
        notesDir.createSync(recursive: true);
      }

      // First, delete any existing files for this note ID (in case title changed)
      for (final entity in notesDir.listSync()) {
        if (entity is File && entity.path.contains(note.id)) {
          await entity.delete();
        }
      }

      // Create human-readable filename: sanitized title + ID
      final sanitizedTitle = _sanitizeFileName(note.title);
      final fileName = '${sanitizedTitle}_${note.id}.yaml';
      final file = File(p.join(notesDir.path, fileName));

      final yaml = _jsonToYaml(note.toJson());

      await file.writeAsString(yaml);
      logDebug('Note saved: $fileName', tag: 'Storage');
    } catch (e) {
      logError('Error saving note', error: e, tag: 'Storage');
      rethrow;
    }
  }

  /// Delete a note
  Future<void> deleteNote(String id) async {
    try {
      final userDataPath = await getUserDataPath();
      final notesDir = Directory(p.join(userDataPath, 'notes'));

      if (notesDir.existsSync()) {
        for (final entity in notesDir.listSync()) {
          if (entity is File && entity.path.contains(id)) {
            await entity.delete();
            logDebug('Note file deleted for ID: $id', tag: 'Storage');
          }
        }
      }
    } catch (e) {
      logError('Error deleting note', error: e, tag: 'Storage');
      rethrow;
    }
  }

  /// Save all notes (used for batch operations like reordering)
  Future<void> saveAllNotes(List<NoteItem> notes) async {
    try {
      for (final note in notes) {
        await saveNote(note);
      }
      logDebug('All notes saved (${notes.length} notes)', tag: 'Storage');
    } catch (e) {
      logError('Error saving all notes', error: e, tag: 'Storage');
      rethrow;
    }
  }

  String _sanitizeFileName(String name) {
    // Replace invalid Windows filename characters with underscores
    return name.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_').trim();
  }

  /// Convert YAML map to JSON-compatible map
  Map<String, dynamic> _yamlToJson(dynamic yaml) {
    if (yaml is YamlMap) {
      return yaml.map((key, value) => MapEntry(
            key.toString(),
            _yamlToJsonValue(value),
          ));
    }
    return {};
  }

  /// Helper to convert individual YAML values to JSON-compatible values
  dynamic _yamlToJsonValue(dynamic value) {
    if (value is YamlMap) {
      return value.map((key, val) => MapEntry(
            key.toString(),
            _yamlToJsonValue(val),
          ));
    } else if (value is YamlList) {
      return value.map((e) => _yamlToJsonValue(e)).toList();
    } else {
      return value;
    }
  }

  /// Convert JSON map to YAML string
  String _jsonToYaml(Map<String, dynamic> json, [int indent = 0]) {
    final buffer = StringBuffer();
    final indentStr = '  ' * indent;

    json.forEach((key, value) {
      if (value == null) {
        buffer.writeln('$indentStr$key: null');
      } else if (value is Map) {
        buffer.writeln('$indentStr$key:');
        buffer.write(_jsonToYaml(value as Map<String, dynamic>, indent + 1));
      } else if (value is List) {
        if (value.isEmpty) {
          buffer.writeln('$indentStr$key: []');
        } else {
          buffer.writeln('$indentStr$key:');
          for (final item in value) {
            if (item is Map) {
              buffer.writeln('${indentStr}  -');
              buffer
                  .write(_jsonToYaml(item as Map<String, dynamic>, indent + 2));
            } else {
              buffer.writeln('${indentStr}  - $item');
            }
          }
        }
      } else if (value is String) {
        // Escape for YAML double-quoted scalar: backslash first, then special chars.
        // Raw newlines in a double-quoted YAML value are treated as folded spaces
        // on load, destroying multi-line formatting — they must be written as \n.
        final escaped = value
            .replaceAll(r'\', r'\\')
            .replaceAll('"', r'\"')
            .replaceAll('\r\n', r'\n')
            .replaceAll('\n', r'\n')
            .replaceAll('\r', r'\r');
        buffer.writeln('$indentStr$key: "$escaped"');
      } else {
        buffer.writeln('$indentStr$key: $value');
      }
    });

    return buffer.toString();
  }
}
