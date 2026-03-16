import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as p;
import 'log_service.dart';
import 'storage_service.dart';
import '../constants/json_constants.dart';
import '../models/master_profile.dart';
import '../models/template_customization.dart';
import '../models/template_style.dart';

/// Repository for master profile persistence.
///
/// Handles profile CRUD, language discovery, and master-profile PDF settings.
/// All paths are resolved via [StorageService.getUserDataPath].
class ProfileRepository {
  ProfileRepository(this._storageService);

  final StorageService _storageService;

  // ── Language Discovery ──────────────────────────────────────────────

  /// Discover all profile language codes by scanning the profiles/ directory.
  Future<List<String>> discoverLanguageCodes() async {
    try {
      final userDataPath = await _storageService.getUserDataPath();
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
      logError('Error discovering profile language codes',
          error: e, tag: 'ProfileRepo');
      return [];
    }
  }

  // ── Profile CRUD ───────────────────────────────────────────────────

  /// Load master profile for a specific language code.
  Future<MasterProfile> load(String langCode) async {
    try {
      final userDataPath = await _storageService.getUserDataPath();
      final file =
          File(p.join(userDataPath, 'profiles', langCode, 'base_data.json'));

      if (!file.existsSync()) {
        return MasterProfile.empty(langCode);
      }

      final content = await file.readAsString();
      final json = jsonDecode(content) as Map<String, dynamic>;
      if (json['personalInfo'] is Map<String, dynamic>) {
        final pi = json['personalInfo'] as Map<String, dynamic>;
        pi['profilePicturePath'] = _storageService.toAbsolutePath(
          pi['profilePicturePath'] as String?,
          userDataPath,
        );
      }
      return MasterProfile.fromJson(json);
    } catch (e) {
      logError('Error loading master profile ($langCode)',
          error: e, tag: 'ProfileRepo');
      return MasterProfile.empty(langCode);
    }
  }

  /// Save master profile.
  Future<void> save(MasterProfile profile) async {
    try {
      final userDataPath = await _storageService.getUserDataPath();
      final dir =
          Directory(p.join(userDataPath, 'profiles', profile.language));
      if (!dir.existsSync()) {
        dir.createSync(recursive: true);
      }
      final file = File(p.join(dir.path, 'base_data.json'));

      final json = profile.toJson();
      if (json['personalInfo'] is Map<String, dynamic>) {
        final pi = json['personalInfo'] as Map<String, dynamic>;
        pi['profilePicturePath'] = _storageService.toRelativePath(
          pi['profilePicturePath'] as String?,
          userDataPath,
        );
      }
      await file.writeAsString(JsonConstants.prettyEncoder.convert(json));

      logInfo('Master profile saved (${profile.language})',
          tag: 'ProfileRepo');
    } catch (e) {
      logError('Error saving master profile', error: e, tag: 'ProfileRepo');
      rethrow;
    }
  }

  /// Delete the entire profile folder for a language.
  Future<void> deleteFolder(String langCode) async {
    try {
      final userDataPath = await _storageService.getUserDataPath();
      final dir = Directory(p.join(userDataPath, 'profiles', langCode));
      if (dir.existsSync()) {
        await dir.delete(recursive: true);
        logInfo('Profile folder deleted ($langCode)', tag: 'ProfileRepo');
      }
    } catch (e) {
      logError('Error deleting profile folder ($langCode)',
          error: e, tag: 'ProfileRepo');
      rethrow;
    }
  }

  // ── Master Profile PDF Settings ────────────────────────────────────

  /// Load master profile CV PDF settings.
  Future<(TemplateStyle?, TemplateCustomization?)> loadCvPdfSettings(
      String langCode) async {
    final userDataPath = await _storageService.getUserDataPath();
    return _storageService.loadPdfSettings(
        p.join(userDataPath, 'profiles', langCode, 'cv_pdf_settings.json'));
  }

  /// Save master profile CV PDF settings.
  Future<void> saveCvPdfSettings(
    String langCode,
    TemplateStyle style,
    TemplateCustomization customization,
  ) async {
    final userDataPath = await _storageService.getUserDataPath();
    await _storageService.savePdfSettings(
      p.join(userDataPath, 'profiles', langCode, 'cv_pdf_settings.json'),
      style,
      customization,
    );
  }

  /// Load master profile Cover Letter PDF settings.
  Future<(TemplateStyle?, TemplateCustomization?)> loadClPdfSettings(
      String langCode) async {
    final userDataPath = await _storageService.getUserDataPath();
    return _storageService.loadPdfSettings(
        p.join(userDataPath, 'profiles', langCode, 'cl_pdf_settings.json'));
  }

  /// Save master profile Cover Letter PDF settings.
  Future<void> saveClPdfSettings(
    String langCode,
    TemplateStyle style,
    TemplateCustomization customization,
  ) async {
    final userDataPath = await _storageService.getUserDataPath();
    await _storageService.savePdfSettings(
      p.join(userDataPath, 'profiles', langCode, 'cl_pdf_settings.json'),
      style,
      customization,
    );
  }
}
