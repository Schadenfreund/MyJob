import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import '../models/master_profile.dart';
import '../models/user_data/personal_info.dart';
import '../models/user_data/skill.dart';
import '../models/user_data/work_experience.dart';
import '../models/user_data/language.dart';
import '../models/user_data/interest.dart';
import '../services/storage_service.dart';
import '../constants/app_constants.dart';

/// Service to migrate legacy user data to new bilingual structure
class MigrationService {
  static final MigrationService instance = MigrationService._();
  MigrationService._();

  final StorageService _storage = StorageService.instance;

  /// Check if migration is needed and perform it
  Future<bool> migrateIfNeeded() async {
    try {
      final userDataPath = await _storage.getUserDataPath();
      final oldDataFile = File(p.join(userDataPath, 'user_data.json'));
      final migrationMarkerFile = File(p.join(userDataPath, '.migrated'));

      // Check if already migrated
      if (migrationMarkerFile.existsSync()) {
        debugPrint('Migration already completed');
        return false;
      }

      // Check if old data exists
      if (!oldDataFile.existsSync()) {
        debugPrint('No legacy data found, creating migration marker');
        // Create marker to prevent future checks
        await migrationMarkerFile
            .writeAsString(DateTime.now().toIso8601String());
        return false;
      }

      debugPrint('Legacy user data found, starting migration...');

      // Read old data
      final content = await oldDataFile.readAsString();
      final json = jsonDecode(content) as Map<String, dynamic>;

      // Create English profile from old data
      final enProfile = _createProfileFromLegacyData(json, DocumentLanguage.en);

      // Save to new location
      await _storage.saveMasterProfile(enProfile);

      // Create empty German profile
      final deProfile = MasterProfile.empty(DocumentLanguage.de);
      await _storage.saveMasterProfile(deProfile);

      // Create migration marker
      await migrationMarkerFile.writeAsString(DateTime.now().toIso8601String());

      // Optionally backup old file
      final backupFile = File(p.join(userDataPath, 'user_data.json.backup'));
      await oldDataFile.copy(backupFile.path);

      debugPrint('Migration completed successfully');
      debugPrint('- English profile created with legacy data');
      debugPrint('- German profile created (empty)');
      debugPrint('- Legacy data backed up to user_data.json.backup');

      return true;
    } catch (e) {
      debugPrint('Error during migration: $e');
      return false;
    }
  }

  /// Create MasterProfile from legacy user_data.json format
  MasterProfile _createProfileFromLegacyData(
    Map<String, dynamic> json,
    DocumentLanguage language,
  ) {
    return MasterProfile(
      language: language,
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
      debugPrint('Error checking migration status: $e');
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
