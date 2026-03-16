import 'dart:convert';
import 'dart:io';
import 'package:archive/archive_io.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'storage_service.dart';
import '../models/backup_manifest.dart';
import '../constants/app_constants.dart';
import 'backup_validator.dart';
import 'log_service.dart';
import '../exceptions/backup_exceptions.dart';

/// Service for creating zips of UserData for backups
class BackupService {
  BackupService._();
  static final BackupService instance = BackupService._();

  /// Internal folders that are never included in backup zips
  static const _excludedFolders = {'.backup_safety', '.restore_temp'};

  /// Whitelist of known UserData directories to restore
  static const _knownDirs = [
    'applications',
    'profiles',
    'notes',
    'pdf_presets',
    'localization', // custom language files
    'cvs', // legacy
    'cover_letters', // legacy
  ];

  /// Whitelist of known UserData files to restore
  static const _knownFiles = [
    'settings.json',
    'preferences.json',
    'cv_customization.json',
    '.migrated',
  ];

  /// Create a zip backup of the entire UserData folder at the specified destination path.
  /// Destination must be outside UserData to prevent recursion.
  Future<File?> createBackup(String destinationDir) async {
    try {
      final userDataPath = await StorageService.instance.getUserDataPath();
      final userDataDir = Directory(userDataPath);

      if (!userDataDir.existsSync()) {
        logWarning('UserData folder does not exist at $userDataPath', tag: 'Backup');
        return null;
      }

      // Check destination is not inside UserData to avoid recursion/locking
      final absoluteDestDir = Directory(destinationDir).absolute.path;
      final absoluteUserDataPath = userDataDir.absolute.path;

      if (absoluteDestDir.startsWith(absoluteUserDataPath)) {
        throw Exception(
            'Cannot backup to a folder inside UserData. Please select a location outside the application folder.');
      }

      final destDir = Directory(destinationDir);
      if (!destDir.existsSync()) {
        destDir.createSync(recursive: true);
      }

      return await _createBackupZip(absoluteUserDataPath, destinationDir);
    } catch (e) {
      logError('Error creating backup', error: e, tag: 'Backup');
      rethrow;
    }
  }

  /// Restore UserData from a zip backup with atomic operations and safety backup
  Future<bool> restoreBackup(String zipPath) async {
    String? tempDir;
    try {
      final userDataPath = await StorageService.instance.getUserDataPath();

      logInfo('Starting restore: $zipPath -> $userDataPath', tag: 'Backup');

      // Step 1: Validate backup file
      logInfo('Step 1: Validating backup file...', tag: 'Backup');
      final validator = BackupValidator();
      final validationResult = await validator.validateZip(zipPath);

      if (!validationResult.isValid) {
        throw BackupValidationException(
            validationResult.errorMessage ?? 'Backup validation failed');
      }
      logInfo('Validation successful', tag: 'Backup');

      // Step 2: Create safety backup of current UserData
      logInfo('Step 2: Creating safety backup...', tag: 'Backup');
      await _createSafetyBackup();
      logInfo('Safety backup created', tag: 'Backup');

      // Step 3: Extract to temporary directory
      logInfo('Step 3: Extracting to temporary directory...', tag: 'Backup');
      tempDir = await _extractToTemp(zipPath);
      logInfo('Extraction complete: $tempDir', tag: 'Backup');

      // Step 4: Atomic replacement
      logInfo('Step 4: Performing atomic replacement...', tag: 'Backup');
      await _atomicReplace(tempDir);
      logInfo('Atomic replacement complete', tag: 'Backup');

      // Step 4.5: Remap absolute paths (folderPath, profilePicturePath)
      // Backups store absolute paths, which are stale when restored to a
      // different location. Detect the old UserData prefix and rewrite it.
      logInfo('Step 4.5: Remapping absolute paths...', tag: 'Backup');
      await _remapAbsolutePaths(userDataPath);
      logInfo('Path remapping complete', tag: 'Backup');

      // Step 5: Cleanup temp directory
      logInfo('Step 5: Cleaning up...', tag: 'Backup');
      await Directory(tempDir).delete(recursive: true);
      logInfo('Cleanup complete', tag: 'Backup');

      // Step 6: Cleanup old safety backups (keep last 2)
      await _cleanupSafetyBackups();

      logInfo('Restore completed successfully', tag: 'Backup');
      return true;
    } catch (e) {
      logError('Restore failed', error: e, tag: 'Backup');
      logWarning('Attempting rollback...', tag: 'Backup');

      try {
        await _rollback();
        logInfo('Rollback successful - original data restored', tag: 'Backup');
      } catch (rollbackError) {
        logError('CRITICAL: Rollback failed. Check .backup_safety/ for manual recovery', error: rollbackError, tag: 'Backup');
      }

      if (tempDir != null) {
        try {
          final tempDirectory = Directory(tempDir);
          if (tempDirectory.existsSync()) {
            await tempDirectory.delete(recursive: true);
          }
        } catch (e) {
          logWarning('Failed to clean up temp directory', tag: 'Backup');
        }
      }

      rethrow;
    }
  }

  /// Create a safety backup before restore.
  /// Saves into .backup_safety inside UserData using the internal zip method
  /// (bypasses the user-facing destination check that prevents backups inside UserData).
  Future<File> _createSafetyBackup() async {
    final userDataPath = await StorageService.instance.getUserDataPath();
    final safetyDir = Directory(p.join(userDataPath, '.backup_safety'));

    if (!safetyDir.existsSync()) {
      safetyDir.createSync(recursive: true);
    }

    final file = await _createBackupZip(userDataPath, safetyDir.path);
    if (file == null) {
      throw BackupException('Failed to create safety backup');
    }
    return file;
  }

  /// Internal: create a timestamped backup zip from [sourcePath] into [destinationDir].
  /// Does NOT validate that dest is outside source — callers are responsible.
  Future<File?> _createBackupZip(
      String sourcePath, String destinationDir) async {
    final timestamp =
        DateTime.now().toIso8601String().replaceAll(':', '-').split('.')[0];
    final backupFileName = 'MyJob_Backup_$timestamp.zip';
    final backupPath = p.join(destinationDir, backupFileName);

    logInfo('Creating zip: $sourcePath -> $backupPath', tag: 'Backup');

    final resultPath = await compute(_zipUserData, {
      'sourcePath': sourcePath,
      'destPath': backupPath,
    });

    return resultPath != null ? File(resultPath) : null;
  }

  /// Extract backup to a temporary directory inside UserData
  Future<String> _extractToTemp(String zipPath) async {
    final userDataPath = await StorageService.instance.getUserDataPath();
    final tempDir = Directory(p.join(userDataPath, '.restore_temp'));

    if (tempDir.existsSync()) {
      await tempDir.delete(recursive: true);
    }
    tempDir.createSync(recursive: true);

    final success = await compute(_extractZip, {
      'zipPath': zipPath,
      'destPath': tempDir.path,
    });

    if (!success) {
      throw BackupException('Failed to extract backup to temporary directory');
    }

    return tempDir.path;
  }

  /// Atomic replacement of UserData using a whitelist of known entries.
  ///
  /// Phase 1 — rename existing -> .old_ (preserves originals for rollback)
  /// Phase 2 — move from temp -> UserData (only whitelisted entries)
  /// Phase 3 — delete .old_ entries (commit; only reached if phase 2 succeeded)
  Future<void> _atomicReplace(String tempDir) async {
    final userDataPath = await StorageService.instance.getUserDataPath();

    // Phase 1: rename existing entries to .old_
    for (final dirName in _knownDirs) {
      final existing = Directory(p.join(userDataPath, dirName));
      if (existing.existsSync()) {
        final oldPath = p.join(userDataPath, '.old_$dirName');
        final oldDir = Directory(oldPath);
        if (oldDir.existsSync()) await oldDir.delete(recursive: true);
        await existing.rename(oldPath);
        logDebug('Renamed $dirName -> .old_$dirName', tag: 'Backup');
      }
    }
    for (final fileName in _knownFiles) {
      final existing = File(p.join(userDataPath, fileName));
      if (existing.existsSync()) {
        final oldPath = p.join(userDataPath, '.old_$fileName');
        final oldFile = File(oldPath);
        if (oldFile.existsSync()) await oldFile.delete();
        await existing.rename(oldPath);
        logDebug('Renamed $fileName -> .old_$fileName', tag: 'Backup');
      }
    }

    // Phase 2: move whitelisted entries from temp to UserData
    for (final dirName in _knownDirs) {
      final src = Directory(p.join(tempDir, dirName));
      if (src.existsSync()) {
        await src.rename(p.join(userDataPath, dirName));
        logDebug('Moved $dirName to UserData', tag: 'Backup');
      }
    }
    for (final fileName in _knownFiles) {
      final src = File(p.join(tempDir, fileName));
      if (src.existsSync()) {
        await src.rename(p.join(userDataPath, fileName));
        logDebug('Moved $fileName to UserData', tag: 'Backup');
      }
    }

    // Phase 3: delete .old_ entries (commit point)
    for (final dirName in _knownDirs) {
      final oldDir = Directory(p.join(userDataPath, '.old_$dirName'));
      if (oldDir.existsSync()) {
        await oldDir.delete(recursive: true);
        logDebug('Deleted .old_$dirName', tag: 'Backup');
      }
    }
    for (final fileName in _knownFiles) {
      final oldFile = File(p.join(userDataPath, '.old_$fileName'));
      if (oldFile.existsSync()) {
        await oldFile.delete();
        logDebug('Deleted .old_$fileName', tag: 'Backup');
      }
    }
  }

  /// Rollback failed restore by moving .old_ entries back to their original names
  Future<void> _rollback() async {
    final userDataPath = await StorageService.instance.getUserDataPath();

    for (final dirName in _knownDirs) {
      final oldDir = Directory(p.join(userDataPath, '.old_$dirName'));
      if (oldDir.existsSync()) {
        final dest = Directory(p.join(userDataPath, dirName));
        if (dest.existsSync()) await dest.delete(recursive: true);
        await oldDir.rename(dest.path);
        logInfo('Restored .old_$dirName -> $dirName', tag: 'Backup');
      }
    }
    for (final fileName in _knownFiles) {
      final oldFile = File(p.join(userDataPath, '.old_$fileName'));
      if (oldFile.existsSync()) {
        final dest = File(p.join(userDataPath, fileName));
        if (dest.existsSync()) await dest.delete();
        await oldFile.rename(dest.path);
        logInfo('Restored .old_$fileName -> $fileName', tag: 'Backup');
      }
    }
  }

  /// Cleanup old safety backups, keeping only the most recent [keepCount]
  Future<void> _cleanupSafetyBackups({int keepCount = 2}) async {
    try {
      final userDataPath = await StorageService.instance.getUserDataPath();
      final safetyDir = Directory(p.join(userDataPath, '.backup_safety'));

      if (!safetyDir.existsSync()) return;

      final backups = safetyDir
          .listSync()
          .whereType<File>()
          .where((f) => f.path.endsWith('.zip'))
          .toList();

      backups.sort(
          (a, b) => b.lastModifiedSync().compareTo(a.lastModifiedSync()));

      for (int i = keepCount; i < backups.length; i++) {
        await backups[i].delete();
        logInfo('Deleted old safety backup: ${backups[i].path}', tag: 'Backup');
      }
    } catch (e) {
      logWarning('Error cleaning up safety backups: $e', tag: 'Backup');
      // Non-critical — don't rethrow
    }
  }

  /// After restore, rewrite all absolute UserData paths stored inside JSON files.
  ///
  /// Backups store absolute paths (e.g. folderPath, profilePicturePath). When
  /// restored to a different drive/machine these are stale. We detect the old
  /// UserData prefix from the data itself and replace it with the current one.
  Future<void> _remapAbsolutePaths(String userDataPath) async {
    final oldUserDataPath = await _detectOldUserDataPath(userDataPath);
    if (oldUserDataPath == null) {
      logInfo('No stored absolute paths found, skipping remapping', tag: 'Backup');
      return;
    }

    if (p.normalize(oldUserDataPath) == p.normalize(userDataPath)) {
      logInfo('Paths are identical, no remapping needed', tag: 'Backup');
      return;
    }

    logInfo('Remapping: "$oldUserDataPath" -> "$userDataPath"', tag: 'Restore');

    // JSON stores Windows backslashes doubled: C:\\foo\\bar
    final oldJson = oldUserDataPath.replaceAll(r'\', r'\\');
    final newJson = userDataPath.replaceAll(r'\', r'\\');
    // Some paths may have been stored with forward slashes
    final oldFwd = oldUserDataPath.replaceAll(r'\', '/');
    final newFwd = userDataPath.replaceAll(r'\', '/');

    int count = 0;

    // Patch application metadata JSONs (folderPath) and cv_data.json
    // inside each application subfolder (personalInfo.profilePicturePath)
    final appDir = Directory(p.join(userDataPath, 'applications'));
    if (appDir.existsSync()) {
      for (final entity in appDir.listSync()) {
        if (entity is File && entity.path.endsWith('.json')) {
          if (await _patchFile(entity, oldJson, newJson, oldFwd, newFwd)) {
            count++;
          }
        } else if (entity is Directory) {
          final cvFile = File(p.join(entity.path, 'cv_data.json'));
          if (cvFile.existsSync()) {
            if (await _patchFile(cvFile, oldJson, newJson, oldFwd, newFwd)) {
              count++;
            }
          }
        }
      }
    }

    // Patch profile base_data.json (personalInfo.profilePicturePath)
    final profilesDir = Directory(p.join(userDataPath, 'profiles'));
    if (profilesDir.existsSync()) {
      for (final langDir in profilesDir.listSync().whereType<Directory>()) {
        final baseData = File(p.join(langDir.path, 'base_data.json'));
        if (baseData.existsSync()) {
          if (await _patchFile(baseData, oldJson, newJson, oldFwd, newFwd)) {
            count++;
          }
        }
      }
    }

    logInfo('Path remapping done: $count file(s) patched', tag: 'Restore');
  }

  /// Detect the old UserData base path by reading absolute paths stored inside
  /// the restored JSON files. Tries application folderPaths first, then falls
  /// back to profile picture paths.
  Future<String?> _detectOldUserDataPath(String userDataPath) async {
    // Try application metadata JSONs (folderPath field)
    final appDir = Directory(p.join(userDataPath, 'applications'));
    if (appDir.existsSync()) {
      for (final file in appDir.listSync().whereType<File>()) {
        if (!file.path.endsWith('.json')) continue;
        try {
          final json =
              jsonDecode(await file.readAsString()) as Map<String, dynamic>;
          final folderPath = json['folderPath'] as String?;
          if (folderPath != null && folderPath.isNotEmpty && p.isAbsolute(folderPath)) {
            // folderPath = <oldUserData>/applications/<foldername>
            return p.dirname(p.dirname(folderPath));
          }
        } catch (e) {
          logDebug('Skipping ${file.path} during path detection: $e', tag: 'Restore');
        }
      }
    }

    // Fallback: profile base_data.json (profilePicturePath field)
    final profilesDir = Directory(p.join(userDataPath, 'profiles'));
    if (profilesDir.existsSync()) {
      for (final langDir in profilesDir.listSync().whereType<Directory>()) {
        final f = File(p.join(langDir.path, 'base_data.json'));
        if (!f.existsSync()) continue;
        try {
          final json =
              jsonDecode(await f.readAsString()) as Map<String, dynamic>;
          final picPath =
              (json['personalInfo'] as Map<String, dynamic>?)?['profilePicturePath']
                  as String?;
          if (picPath != null && picPath.isNotEmpty && p.isAbsolute(picPath)) {
            // picPath = <oldUserData>/profiles/<lang>/profile_picture.<ext>
            return p.dirname(p.dirname(p.dirname(picPath)));
          }
        } catch (e) {
          logDebug('Skipping ${f.path} during path detection: $e', tag: 'Restore');
        }
      }
    }

    return null;
  }

  /// Replace [oldJson] and [oldFwd] occurrences in [file] with their new
  /// equivalents. Returns true if the file was modified.
  Future<bool> _patchFile(
    File file,
    String oldJson,
    String newJson,
    String oldFwd,
    String newFwd,
  ) async {
    try {
      final original = await file.readAsString();
      var patched = original.replaceAll(oldJson, newJson);
      if (oldFwd != oldJson) patched = patched.replaceAll(oldFwd, newFwd);
      if (patched == original) return false;
      await file.writeAsString(patched);
      logDebug('Patched paths in: ${p.basename(file.path)}', tag: 'Restore');
      return true;
    } catch (e) {
      logError('Error patching ${file.path}', error: e, tag: 'Restore');
      return false;
    }
  }

  /// Zip UserData into a file, skipping internal app folders.
  /// Runs in a separate isolate via compute().
  static Future<String?> _zipUserData(Map<String, String> params) async {
    try {
      final sourcePath = params['sourcePath']!;
      final destPath = params['destPath']!;

      debugPrint('[Backup Isolate] Starting zip: $sourcePath');
      final dir = Directory(sourcePath);
      if (!dir.existsSync()) {
        debugPrint('[Backup Isolate] ERROR: Source does not exist: $sourcePath');
        return null;
      }

      final archive = Archive();
      final entities = dir.listSync(recursive: true);

      int applicationCount = 0;
      int profileCount = 0;
      int noteCount = 0;
      int fileCount = 0;

      for (final entity in entities) {
        if (entity is File) {
          try {
            final relativePath = p.relative(entity.path, from: sourcePath);
            // Zip standard uses forward slashes
            final normalizedPath = relativePath.replaceAll('\\', '/');

            // Skip internal app folders (safety backups, restore temp)
            final topFolder = normalizedPath.split('/').first;
            if (_excludedFolders.contains(topFolder)) continue;

            final fileBytes = entity.readAsBytesSync();

            if (normalizedPath.startsWith('applications/') &&
                normalizedPath.endsWith('.json')) {
              applicationCount++;
            } else if (normalizedPath.startsWith('profiles/') &&
                normalizedPath.contains('base_data.json')) {
              profileCount++;
            } else if (normalizedPath.startsWith('notes/') &&
                (normalizedPath.endsWith('.yaml') ||
                    normalizedPath.endsWith('.yml'))) {
              noteCount++;
            }

            if (fileCount % 10 == 0 || fileCount < 5) {
              debugPrint(
                  '[Backup Isolate] Adding: $normalizedPath (${fileBytes.length} bytes)');
            }

            archive.addFile(
                ArchiveFile(normalizedPath, fileBytes.length, fileBytes));
            fileCount++;
          } catch (e) {
            debugPrint(
                '[Backup Isolate] Error reading file ${entity.path}: $e');
          }
        }
      }

      // Add manifest
      final manifest = BackupManifest(
        appVersion: AppInfo.version,
        timestamp: DateTime.now(),
        stats: BackupStats(
          applicationCount: applicationCount,
          profileCount: profileCount,
          noteCount: noteCount,
          totalFiles: fileCount,
        ),
      );
      final manifestBytes = utf8.encode(jsonEncode(manifest.toJson()));
      archive.addFile(
          ArchiveFile('manifest.json', manifestBytes.length, manifestBytes));

      debugPrint(
          '[Backup Isolate] Encoding $fileCount files ($applicationCount apps, $profileCount profiles, $noteCount notes)...');

      final encodedBytes = ZipEncoder().encode(archive);
      debugPrint(
          '[Backup Isolate] Writing ${encodedBytes.length} bytes to $destPath');
      File(destPath).writeAsBytesSync(encodedBytes);

      debugPrint('[Backup Isolate] Done.');
      return destPath;
    } catch (e, stack) {
      debugPrint('[Backup Isolate] CRITICAL ERROR: $e\n$stack');
      return null;
    }
  }

  /// Extract zip to destination directory. Runs in a separate isolate via compute().
  static Future<bool> _extractZip(Map<String, String> params) async {
    try {
      final zipPath = params['zipPath']!;
      final destPath = params['destPath']!;

      final bytes = File(zipPath).readAsBytesSync();
      final archive = ZipDecoder().decodeBytes(bytes);

      debugPrint(
          '[Restore Isolate] Extracting ${archive.length} entries to $destPath');

      int fileCount = 0;
      for (final file in archive) {
        final filename = file.name;

        // Path traversal guard — skip entries that escape destPath
        if (filename.contains('..') || filename.startsWith('/') || filename.startsWith('\\')) {
          debugPrint('[Restore Isolate] Skipping suspicious entry: $filename');
          continue;
        }
        final resolvedPath = p.normalize(p.join(destPath, filename));
        if (!resolvedPath.startsWith(destPath)) {
          debugPrint('[Restore Isolate] Skipping path traversal: $filename');
          continue;
        }

        if (file.isFile) {
          final data = file.content as List<int>;
          final outFile = File(resolvedPath);
          outFile.parent.createSync(recursive: true);
          outFile.writeAsBytesSync(data);
          fileCount++;
        } else {
          Directory(resolvedPath).createSync(recursive: true);
        }
      }

      debugPrint('[Restore Isolate] Extracted $fileCount files.');
      return true;
    } catch (e, stack) {
      debugPrint('[Restore Isolate] CRITICAL ERROR: $e\n$stack');
      return false;
    }
  }
}
