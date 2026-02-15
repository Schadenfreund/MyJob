import 'dart:convert';
import 'dart:io';
import 'package:archive/archive_io.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'storage_service.dart';
import '../models/backup_manifest.dart';
import '../constants/app_constants.dart';
import 'backup_validator.dart';
import '../exceptions/backup_exceptions.dart';

/// Service for creating zips of UserData for backups
class BackupService {
  BackupService._();
  static final BackupService instance = BackupService._();

  /// Create a zip backup of the entire UserData folder at the specified destination path
  Future<File?> createBackup(String destinationDir) async {
    try {
      final userDataPath = await StorageService.instance.getUserDataPath();
      final userDataDir = Directory(userDataPath);

      if (!userDataDir.existsSync()) {
        debugPrint('UserData folder does not exist at $userDataPath');
        return null;
      }

      // Check if destination is inside UserData to avoid recursion/locking
      final absoluteDestDir = Directory(destinationDir).absolute.path;
      final absoluteUserDataPath = userDataDir.absolute.path;

      if (absoluteDestDir.startsWith(absoluteUserDataPath)) {
        throw Exception(
            'Cannot backup to a folder inside UserData. Please select a location outside the application folder.');
      }

      // Ensure destination directory exists
      final destDir = Directory(destinationDir);
      if (!destDir.existsSync()) {
        destDir.createSync(recursive: true);
      }

      // Create filename with timestamp
      final timestamp =
          DateTime.now().toIso8601String().replaceAll(':', '-').split('.')[0];
      final backupFileName = 'MyJob_Backup_$timestamp.zip';
      final backupPath = p.join(destinationDir, backupFileName);

      debugPrint('Starting backup: $absoluteUserDataPath -> $backupPath');

      // We use compute for zipping to keep UI responsive if it's large
      final resultPath = await compute(_zipUserData, {
        'sourcePath': absoluteUserDataPath,
        'destPath': backupPath,
      });

      if (resultPath != null) {
        return File(resultPath);
      }
      return null;
    } catch (e) {
      debugPrint('Error creating backup: $e');
      rethrow;
    }
  }

  /// Restore UserData from a zip backup with atomic operations and safety backup
  Future<bool> restoreBackup(String zipPath) async {
    String? tempDir;
    try {
      final userDataPath = await StorageService.instance.getUserDataPath();

      debugPrint('Starting restore: $zipPath -> $userDataPath');

      // Step 1: Validate backup file
      debugPrint('[Restore] Step 1: Validating backup file...');
      final validator = BackupValidator();
      final validationResult = await validator.validateZip(zipPath);

      if (!validationResult.isValid) {
        throw BackupValidationException(
            validationResult.errorMessage ?? 'Backup validation failed');
      }

      debugPrint('[Restore] Validation successful');

      // Step 2: Create safety backup of current UserData
      debugPrint('[Restore] Step 2: Creating safety backup...');
      await _createSafetyBackup();
      debugPrint('[Restore] Safety backup created');

      // Step 3: Extract to temporary directory
      debugPrint('[Restore] Step 3: Extracting to temporary directory...');
      tempDir = await _extractToTemp(zipPath);
      debugPrint('[Restore] Extraction complete: $tempDir');

      // Step 4: Atomic replacement
      debugPrint('[Restore] Step 4: Performing atomic replacement...');
      await _atomicReplace(tempDir);
      debugPrint('[Restore] Atomic replacement complete');

      // Step 5: Cleanup temp directory
      debugPrint('[Restore] Step 5: Cleaning up...');
      await Directory(tempDir).delete(recursive: true);
      debugPrint('[Restore] Cleanup complete');

      // Step 6: Cleanup old safety backups (keep last 2)
      await _cleanupSafetyBackups();

      debugPrint('[Restore] Restore completed successfully!');
      return true;
    } catch (e) {
      debugPrint('[Restore] ERROR: Restore failed - $e');
      debugPrint('[Restore] Attempting rollback...');

      try {
        await _rollback();
        debugPrint('[Restore] Rollback successful - original data restored');
      } catch (rollbackError) {
        debugPrint(
            '[Restore] CRITICAL: Rollback failed - $rollbackError. Check .backup_safety/ for manual recovery');
      }

      // Cleanup temp directory if it exists
      if (tempDir != null) {
        try {
          final tempDirectory = Directory(tempDir);
          if (tempDirectory.existsSync()) {
            await tempDirectory.delete(recursive: true);
          }
        } catch (_) {
          // Ignore cleanup errors
        }
      }

      rethrow;
    }
  }

  /// Create a safety backup before restore
  Future<File> _createSafetyBackup() async {
    final userDataPath = await StorageService.instance.getUserDataPath();
    final safetyDir = Directory(p.join(userDataPath, '.backup_safety'));

    if (!safetyDir.existsSync()) {
      safetyDir.createSync(recursive: true);
    }

    // Create backup in safety directory
    return (await createBackup(safetyDir.path))!;
  }

  /// Extract backup to temporary directory
  Future<String> _extractToTemp(String zipPath) async {
    final userDataPath = await StorageService.instance.getUserDataPath();
    final tempDir = Directory(p.join(userDataPath, '.restore_temp'));

    // Remove old temp directory if it exists
    if (tempDir.existsSync()) {
      await tempDir.delete(recursive: true);
    }

    tempDir.createSync(recursive: true);

    // Extract using compute to keep UI responsive
    final success = await compute(_extractZip, {
      'zipPath': zipPath,
      'destPath': tempDir.path,
    });

    if (!success) {
      throw BackupException('Failed to extract backup to temporary directory');
    }

    return tempDir.path;
  }

  /// Perform atomic replacement of UserData
  Future<void> _atomicReplace(String tempDir) async {
    final userDataPath = await StorageService.instance.getUserDataPath();

    // List of directories to rename
    final toRename = ['applications', 'profiles', 'notes'];

    // Step 1: Rename existing directories to .old_
    for (final dirName in toRename) {
      final existing = Directory(p.join(userDataPath, dirName));
      if (existing.existsSync()) {
        final oldName = p.join(userDataPath, '.old_$dirName');
        // Delete old .old_ directory if it exists
        final oldDir = Directory(oldName);
        if (oldDir.existsSync()) {
          await oldDir.delete(recursive: true);
        }
        await existing.rename(oldName);
        debugPrint('[Restore] Renamed $dirName -> .old_$dirName');
      }
    }

    // Also handle settings.json
    final settingsFile = File(p.join(userDataPath, 'settings.json'));
    if (settingsFile.existsSync()) {
      final oldSettings = File(p.join(userDataPath, '.old_settings.json'));
      if (oldSettings.existsSync()) await oldSettings.delete();
      await settingsFile.rename(oldSettings.path);
      debugPrint('[Restore] Renamed settings.json -> .old_settings.json');
    }

    // Step 2: Move new data from temp to UserData
    final tempContents = Directory(tempDir).listSync();
    for (final entity in tempContents) {
      final name = p.basename(entity.path);
      final dest = p.join(userDataPath, name);

      // Skip manifest.json - we don't need it in UserData
      if (name == 'manifest.json') {
        continue;
      }

      try {
        await entity.rename(dest);
        debugPrint('[Restore] Moved $name to UserData');
      } catch (e) {
        debugPrint('[Restore] Error moving $name: $e');
        throw BackupException('Failed to move $name to UserData: $e');
      }
    }

    // Step 3: Delete .old_ directories (only if everything succeeded)
    for (final dirName in toRename) {
      final oldDir = Directory(p.join(userDataPath, '.old_$dirName'));
      if (oldDir.existsSync()) {
        await oldDir.delete(recursive: true);
        debugPrint('[Restore] Deleted .old_$dirName');
      }
    }

    final oldSettings = File(p.join(userDataPath, '.old_settings.json'));
    if (oldSettings.existsSync()) {
      await oldSettings.delete();
      debugPrint('[Restore] Deleted .old_settings.json');
    }
  }

  /// Rollback failed restore by moving .old_ directories back
  Future<void> _rollback() async {
    final userDataPath = await StorageService.instance.getUserDataPath();
    final toRestore = ['applications', 'profiles', 'notes'];

    for (final dirName in toRestore) {
      final oldDir = Directory(p.join(userDataPath, '.old_$dirName'));
      if (oldDir.existsSync()) {
        final dest = Directory(p.join(userDataPath, dirName));

        // Delete corrupted new directory if it exists
        if (dest.existsSync()) {
          await dest.delete(recursive: true);
        }

        // Restore old directory
        await oldDir.rename(dest.path);
        debugPrint('[Rollback] Restored .old_$dirName -> $dirName');
      }
    }

    // Restore settings.json
    final oldSettings = File(p.join(userDataPath, '.old_settings.json'));
    if (oldSettings.existsSync()) {
      final settingsFile = File(p.join(userDataPath, 'settings.json'));
      if (settingsFile.existsSync()) await settingsFile.delete();
      await oldSettings.rename(settingsFile.path);
      debugPrint('[Rollback] Restored .old_settings.json -> settings.json');
    }
  }

  /// Cleanup old safety backups, keeping only the most recent ones
  Future<void> _cleanupSafetyBackups({int keepCount = 2}) async {
    try {
      final userDataPath = await StorageService.instance.getUserDataPath();
      final safetyDir = Directory(p.join(userDataPath, '.backup_safety'));

      if (!safetyDir.existsSync()) return;

      // Get all safety backup files
      final backups = safetyDir
          .listSync()
          .whereType<File>()
          .where((f) => f.path.endsWith('.zip'))
          .toList();

      // Sort by modification time (newest first)
      backups.sort((a, b) =>
          b.lastModifiedSync().compareTo(a.lastModifiedSync()));

      // Delete old backups beyond keepCount
      for (int i = keepCount; i < backups.length; i++) {
        await backups[i].delete();
        debugPrint('[Cleanup] Deleted old safety backup: ${backups[i].path}');
      }

      debugPrint(
          '[Cleanup] Kept ${backups.length < keepCount ? backups.length : keepCount} most recent safety backups');
    } catch (e) {
      debugPrint('[Cleanup] Error cleaning up safety backups: $e');
      // Don't rethrow - cleanup is not critical
    }
  }

  /// Helper function to perform zipping in a separate isolate
  static Future<String?> _zipUserData(Map<String, String> params) async {
    try {
      final sourcePath = params['sourcePath']!;
      final destPath = params['destPath']!;

      debugPrint('[Backup Isolate] Starting zip: $sourcePath');
      final dir = Directory(sourcePath);
      if (!dir.existsSync()) {
        debugPrint(
            '[Backup Isolate] ERROR: Source directory does not exist or is inaccessible: $sourcePath');
        return null;
      }

      final archive = Archive();
      final entities = dir.listSync(recursive: true);

      debugPrint(
          '[Backup Isolate] Found ${entities.length} entities in $sourcePath');

      // Count files by type for manifest
      int applicationCount = 0;
      int profileCount = 0;
      int noteCount = 0;
      int fileCount = 0;

      for (final entity in entities) {
        if (entity is File) {
          try {
            final fileBytes = entity.readAsBytesSync();
            final relativePath = p.relative(entity.path, from: sourcePath);

            // Count file types
            if (relativePath.startsWith('applications${p.separator}') &&
                relativePath.endsWith('.json')) {
              applicationCount++;
            } else if (relativePath.startsWith('profiles${p.separator}') &&
                relativePath.contains('base_data.json')) {
              profileCount++;
            } else if (relativePath.startsWith('notes${p.separator}') &&
                (relativePath.endsWith('.yaml') ||
                    relativePath.endsWith('.yml'))) {
              noteCount++;
            }

            // Log every 10th file or important files to avoid logflooding but still show progress
            if (fileCount % 10 == 0 || fileCount < 5) {
              debugPrint(
                  '[Backup Isolate] Adding file: $relativePath (${fileBytes.length} bytes)');
            }

            final archiveFile = ArchiveFile(
              relativePath.replaceAll(
                  '\\', '/'), // Zip standard uses forward slashes
              fileBytes.length,
              fileBytes,
            );
            archive.addFile(archiveFile);
            fileCount++;
          } catch (e) {
            debugPrint(
                '[Backup Isolate] Error reading file ${entity.path}: $e');
          }
        }
      }

      // Create and add manifest as first file
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

      final manifestJson = jsonEncode(manifest.toJson());
      final manifestBytes = utf8.encode(manifestJson);
      final manifestFile = ArchiveFile(
        'manifest.json',
        manifestBytes.length,
        manifestBytes,
      );
      archive.addFile(manifestFile);

      debugPrint(
          '[Backup Isolate] Added manifest: $applicationCount apps, $profileCount profiles, $noteCount notes');

      if (fileCount == 0) {
        debugPrint('[Backup Isolate] WARNING: No files found to backup!');
      }

      debugPrint('[Backup Isolate] Encoding $fileCount files into zip...');
      final zipEncoder = ZipEncoder();
      final encodedBytes = zipEncoder.encode(archive);

      debugPrint(
          '[Backup Isolate] Writing ${encodedBytes.length} bytes to $destPath');
      final destFile = File(destPath);
      destFile.writeAsBytesSync(encodedBytes);

      debugPrint('[Backup Isolate] Zip creation finished successfully.');
      return destPath;
    } catch (e, stack) {
      debugPrint('[Backup Isolate] CRITICAL ERROR: $e');
      debugPrint('[Backup Isolate] Stack trace: $stack');
      return null;
    }
  }

  /// Helper function to perform extraction in a separate isolate
  static Future<bool> _extractZip(Map<String, String> params) async {
    try {
      final zipPath = params['zipPath']!;
      final destPath = params['destPath']!;

      final bytes = File(zipPath).readAsBytesSync();
      final archive = ZipDecoder().decodeBytes(bytes);

      debugPrint(
          '[Restore Isolate] Extracting ${archive.length} entities to $destPath');

      int fileCount = 0;
      for (final file in archive) {
        final filename = file.name;
        if (file.isFile) {
          final data = file.content as List<int>;
          final outFile = File(p.join(destPath, filename));

          // Ensure parent directory exists
          outFile.parent.createSync(recursive: true);

          outFile.writeAsBytesSync(data);
          fileCount++;
        } else {
          // It's a directory
          final outDir = Directory(p.join(destPath, filename));
          outDir.createSync(recursive: true);
        }
      }

      debugPrint(
          '[Restore Isolate] Extraction complete. Restored $fileCount files.');
      return true;
    } catch (e, stack) {
      debugPrint('[Restore Isolate] CRITICAL ERROR: $e');
      debugPrint('[Restore Isolate] Stack trace: $stack');
      return false;
    }
  }
}
