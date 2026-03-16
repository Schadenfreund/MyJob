import 'dart:convert';
import 'dart:io';
import 'log_service.dart';
import 'package:path/path.dart' as p;
import '../models/job_application.dart';
import '../models/cv_data.dart';
import '../models/cover_letter.dart';
import '../models/notes_data.dart';
import '../constants/json_constants.dart';
import '../models/template_customization.dart';
import '../models/template_style.dart';
import 'profile_repository.dart';
import 'application_repository.dart';
import 'notes_repository.dart';

/// Central storage coordinator.
///
/// Owns the UserData path, path portability helpers, and shared PDF settings
/// I/O. Domain-specific persistence is delegated to repositories:
/// - [profiles] — master profiles, language discovery, profile PDF settings
/// - [applications] — job applications, job data, job PDF settings
/// - [notes] — notes CRUD (YAML files)
///
/// Legacy standalone CV/CoverLetter methods and export/import remain here.
class StorageService {
  StorageService._();
  static final StorageService instance = StorageService._();

  String? _userDataPath;

  // ── Domain Repositories ────────────────────────────────────────────

  late final ProfileRepository profiles = ProfileRepository(this);
  late final ApplicationRepository applications = ApplicationRepository(this);
  late final NotesRepository notes = NotesRepository(this);

  // ============================================================================
  // USER DATA PATH
  // ============================================================================

  /// Get the portable UserData folder path.
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
  String? toAbsolutePath(String? stored, String userDataPath) {
    if (stored == null || stored.isEmpty) return stored;
    final norm = p.normalize(stored);
    if (!p.isAbsolute(norm)) {
      return p.normalize(p.join(userDataPath, norm));
    }
    final base = p.normalize(userDataPath);
    if (norm == base || p.isWithin(base, norm)) return norm;
    // Stale absolute path from a moved UserData location.
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
  String? toRelativePath(String? absolute, String userDataPath) {
    if (absolute == null || absolute.isEmpty) return absolute;
    final norm = p.normalize(absolute);
    final base = p.normalize(userDataPath);
    if (p.isWithin(base, norm)) {
      return p.relative(norm, from: base);
    }
    return absolute;
  }

  // ============================================================================
  // SHARED PDF SETTINGS I/O
  // ============================================================================

  /// Load style + customization from a JSON file with `style` and
  /// `customization` keys. Returns `(null, null)` if the file does
  /// not exist or cannot be parsed.
  Future<(TemplateStyle?, TemplateCustomization?)> loadPdfSettings(
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
      logError('Error loading PDF settings from $filePath',
          error: e, tag: 'Storage');
      return (null, null);
    }
  }

  /// Save style + customization to a JSON file.
  Future<void> savePdfSettings(
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
      logError('Error saving PDF settings to $filePath',
          error: e, tag: 'Storage');
      rethrow;
    }
  }

  // ============================================================================
  // LEGACY CVS (standalone, used by export/import)
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
            logError('Error loading CV ${file.path}',
                error: e, tag: 'Storage');
          }
        }
      }

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
  // LEGACY COVER LETTERS (standalone, used by export/import)
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
            logError('Error loading cover letter ${file.path}',
                error: e, tag: 'Storage');
          }
        }
      }

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
    final apps = await applications.loadAll();
    final cvs = await loadCvs();
    final coverLetters = await loadCoverLetters();
    final allNotes = await notes.loadAll();

    final exportData = {
      'version': '1.0',
      'exportDate': DateTime.now().toIso8601String(),
      'applications': apps.map((a) => a.toJson()).toList(),
      'cvs': cvs.map((c) => c.toJson()).toList(),
      'coverLetters': coverLetters.map((l) => l.toJson()).toList(),
      'notes': allNotes.map((n) => n.toJson()).toList(),
    };

    return JsonConstants.prettyEncoder.convert(exportData);
  }

  Future<void> importData(String jsonData) async {
    try {
      final data = jsonDecode(jsonData) as Map<String, dynamic>;

      if (data['applications'] != null) {
        for (final appJson in data['applications'] as List) {
          final app =
              JobApplication.fromJson(appJson as Map<String, dynamic>);
          await applications.save(app);
        }
      }

      if (data['cvs'] != null) {
        for (final cvJson in data['cvs'] as List) {
          final cv = CvData.fromJson(cvJson as Map<String, dynamic>);
          await saveCv(cv);
        }
      }

      if (data['coverLetters'] != null) {
        for (final letterJson in data['coverLetters'] as List) {
          final letter =
              CoverLetter.fromJson(letterJson as Map<String, dynamic>);
          await saveCoverLetter(letter);
        }
      }

      if (data['notes'] != null) {
        for (final noteJson in data['notes'] as List) {
          final note = NoteItem.fromJson(noteJson as Map<String, dynamic>);
          await notes.save(note);
        }
      }

      logInfo('Data imported successfully', tag: 'Storage');
    } catch (e) {
      logError('Error importing data', error: e, tag: 'Storage');
      rethrow;
    }
  }
}
