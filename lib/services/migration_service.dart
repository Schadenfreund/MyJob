import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as p;
import '../models/master_profile.dart';
import '../models/user_data/personal_info.dart';
import '../models/user_data/skill.dart';
import '../models/user_data/work_experience.dart';
import '../models/user_data/language.dart';
import '../models/user_data/interest.dart';
import '../services/storage_service.dart';
import '../services/log_service.dart';

/// Service to migrate legacy user data to new bilingual structure
class MigrationService {
  static final MigrationService instance = MigrationService._();
  MigrationService._();

  final StorageService _storage = StorageService.instance;
  final _profileRepo = StorageService.instance.profiles;

  /// Check if migration is needed and perform it
  Future<bool> migrateIfNeeded() async {
    try {
      final userDataPath = await _storage.getUserDataPath();
      final oldDataFile = File(p.join(userDataPath, 'user_data.json'));
      final migrationMarkerFile = File(p.join(userDataPath, '.migrated'));

      // Check if already migrated
      if (migrationMarkerFile.existsSync()) {
        logDebug('Migration already completed', tag: 'Migration');
        return false;
      }

      // Check if old data exists
      if (!oldDataFile.existsSync()) {
        logDebug('No legacy data found, creating migration marker', tag: 'Migration');
        // Create marker to prevent future checks
        await migrationMarkerFile
            .writeAsString(DateTime.now().toIso8601String());
        return false;
      }

      logInfo('Legacy user data found, starting migration...', tag: 'Migration');

      // Read old data
      final content = await oldDataFile.readAsString();
      final json = jsonDecode(content) as Map<String, dynamic>;

      // Create English profile from old data
      final enProfile = _createProfileFromLegacyData(json, 'en');

      // Save to new location
      await _profileRepo.save(enProfile);

      // Create empty German profile
      final deProfile = MasterProfile.empty('de');
      await _profileRepo.save(deProfile);

      // Create migration marker
      await migrationMarkerFile.writeAsString(DateTime.now().toIso8601String());

      // Optionally backup old file
      final backupFile = File(p.join(userDataPath, 'user_data.json.backup'));
      await oldDataFile.copy(backupFile.path);

      logInfo('Migration completed: EN profile from legacy data, DE profile empty, backup created', tag: 'Migration');

      return true;
    } catch (e) {
      logError('Error during migration', error: e, tag: 'Migration');
      return false;
    }
  }

  /// Create MasterProfile from legacy user_data.json format
  MasterProfile _createProfileFromLegacyData(
    Map<String, dynamic> json,
    String langCode,
  ) {
    return MasterProfile(
      language: langCode,
      personalInfo: json['personalInfo'] != null
          ? PersonalInfo.fromJson(json['personalInfo'] as Map<String, dynamic>)
          : null,
      experiences: (json['workExperiences'] as List<dynamic>?)
              ?.map((e) => WorkExperience.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      education: [], // Old format didn't have education in user_data.json
      skills: (json['skills'] as List<dynamic>?)
              ?.map((e) => Skill.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      languages: (json['languages'] as List<dynamic>?)
              ?.map((e) => Language.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      interests: (json['interests'] as List<dynamic>?)
              ?.map((e) => Interest.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      defaultCoverLetterBody: '', // Old format didn't have this
    );
  }

  /// Get migration status for display
  Future<MigrationStatus> getStatus() async {
    try {
      final userDataPath = await _storage.getUserDataPath();
      final oldDataFile = File(p.join(userDataPath, 'user_data.json'));
      final migrationMarkerFile = File(p.join(userDataPath, '.migrated'));

      if (migrationMarkerFile.existsSync()) {
        return MigrationStatus.completed;
      }

      if (oldDataFile.existsSync()) {
        return MigrationStatus.needed;
      }

      return MigrationStatus.notNeeded;
    } catch (e) {
      logError('Error checking migration status', error: e, tag: 'Migration');
      return MigrationStatus.error;
    }
  }
}

/// Migration status enum
enum MigrationStatus {
  notNeeded,
  needed,
  completed,
  error,
}
