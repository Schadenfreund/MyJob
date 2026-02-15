import 'dart:convert';
import 'dart:io';
import 'package:archive/archive_io.dart';
import 'package:flutter/foundation.dart';
import '../models/backup_manifest.dart';

/// Validates backup zip files before restoration
class BackupValidator {
  /// Validate a backup zip file
  Future<BackupValidationResult> validateZip(String zipPath) async {
    try {
      // Check if file exists
      final zipFile = File(zipPath);
      if (!zipFile.existsSync()) {
        return BackupValidationResult(
          isValid: false,
          errorMessage: 'Backup file not found at: $zipPath',
        );
      }

      // Try to read and decode the zip
      final bytes = await zipFile.readAsBytes();
      Archive archive;
      try {
        archive = ZipDecoder().decodeBytes(bytes);
      } catch (e) {
        return BackupValidationResult(
          isValid: false,
          errorMessage: 'Backup file is corrupted or not a valid zip file.',
        );
      }

      // Extract and validate manifest
      final manifestResult = await _extractAndValidateManifest(archive);
      if (!manifestResult.isValid) {
        return manifestResult;
      }

      // Validate backup structure
      final structureResult = _validateBackupStructure(archive);
      if (!structureResult.isValid) {
        return structureResult;
      }

      // Check for path traversal attacks
      final securityResult = _checkSecurityIssues(archive);
      if (!securityResult.isValid) {
        return securityResult;
      }

      debugPrint('[Validator] Backup validation successful');
      return BackupValidationResult(
        isValid: true,
        manifest: manifestResult.manifest,
      );
    } catch (e) {
      debugPrint('[Validator] Validation error: $e');
      return BackupValidationResult(
        isValid: false,
        errorMessage: 'Error validating backup: $e',
      );
    }
  }

  /// Extract manifest from zip without extracting entire archive
  Future<BackupManifest?> extractManifest(String zipPath) async {
    try {
      final zipFile = File(zipPath);
      if (!zipFile.existsSync()) return null;

      final bytes = await zipFile.readAsBytes();
      final archive = ZipDecoder().decodeBytes(bytes);

      final manifestFile = archive.firstWhere(
        (file) => file.name == 'manifest.json',
        orElse: () => throw Exception('Manifest not found'),
      );

      final manifestContent = utf8.decode(manifestFile.content as List<int>);
      final manifestJson = jsonDecode(manifestContent) as Map<String, dynamic>;

      return BackupManifest.fromJson(manifestJson);
    } catch (e) {
      debugPrint('[Validator] Error extracting manifest: $e');
      return null;
    }
  }

  /// Extract and validate the manifest
  Future<BackupValidationResult> _extractAndValidateManifest(
      Archive archive) async {
    try {
      // Find manifest file
      final manifestFile = archive.firstWhere(
        (file) => file.name == 'manifest.json',
        orElse: () => throw Exception('Manifest not found'),
      );

      // Decode manifest
      final manifestContent = utf8.decode(manifestFile.content as List<int>);
      final manifestJson = jsonDecode(manifestContent) as Map<String, dynamic>;
      final manifest = BackupManifest.fromJson(manifestJson);

      debugPrint('[Validator] Manifest found: v${manifest.backupVersion}, '
          'app v${manifest.appVersion}, ${manifest.stats.totalFiles} files');

      // Check backup version compatibility
      if (manifest.backupVersion != '1.0') {
        return BackupValidationResult(
          isValid: false,
          errorMessage:
              'Incompatible backup version: ${manifest.backupVersion}. This app supports version 1.0.',
        );
      }

      return BackupValidationResult(
        isValid: true,
        manifest: manifest,
      );
    } catch (e) {
      return BackupValidationResult(
        isValid: false,
        errorMessage:
            'Backup does not contain a valid manifest. This may not be a MyJob backup file.',
      );
    }
  }

  /// Validate backup has required directory structure
  BackupValidationResult _validateBackupStructure(Archive archive) {
    final fileNames = archive.map((file) => file.name).toList();

    // Check for at least one of the critical files/directories
    final hasSettings = fileNames.any((name) => name.contains('settings.json'));
    final hasProfiles = fileNames.any((name) => name.startsWith('profiles/'));
    final hasApplications =
        fileNames.any((name) => name.startsWith('applications/'));

    if (!hasSettings && !hasProfiles && !hasApplications) {
      return BackupValidationResult(
        isValid: false,
        errorMessage:
            'Backup does not contain expected MyJob data (no settings, profiles, or applications found).',
      );
    }

    debugPrint('[Validator] Backup structure validated successfully');
    return BackupValidationResult(isValid: true);
  }

  /// Check for security issues like path traversal
  BackupValidationResult _checkSecurityIssues(Archive archive) {
    for (final file in archive) {
      // Check for path traversal attempts
      if (file.name.contains('..') || file.name.startsWith('/')) {
        return BackupValidationResult(
          isValid: false,
          errorMessage:
              'Backup contains suspicious file paths. This may be a malicious file.',
        );
      }
    }

    return BackupValidationResult(isValid: true);
  }
}

/// Result of backup validation
class BackupValidationResult {
  final bool isValid;
  final String? errorMessage;
  final BackupManifest? manifest;
  final List<String> warnings;

  BackupValidationResult({
    required this.isValid,
    this.errorMessage,
    this.manifest,
    this.warnings = const [],
  });
}
