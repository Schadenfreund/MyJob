import 'dart:io';
import 'package:archive/archive_io.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'storage_service.dart';

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

  /// Restore UserData from a zip backup
  Future<bool> restoreBackup(String zipPath) async {
    try {
      final userDataPath = await StorageService.instance.getUserDataPath();

      debugPrint('Starting restore: $zipPath -> $userDataPath');

      // Ensure zip file exists
      final zipFile = File(zipPath);
      if (!zipFile.existsSync()) {
        throw Exception('Backup file not found at $zipPath');
      }

      // We use compute for extraction to keep UI responsive
      return await compute(_extractZip, {
        'zipPath': zipPath,
        'destPath': userDataPath,
      });
    } catch (e) {
      debugPrint('Error restoring backup: $e');
      rethrow;
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

      int fileCount = 0;
      for (final entity in entities) {
        if (entity is File) {
          try {
            final fileBytes = entity.readAsBytesSync();
            final relativePath = p.relative(entity.path, from: sourcePath);

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
