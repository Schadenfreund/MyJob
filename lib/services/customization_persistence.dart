import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import '../models/template_customization.dart';
import 'storage_service.dart';
import '../constants/json_constants.dart';

/// Service for persisting template customization settings in UserData folder
class CustomizationPersistence {
  static const String _fileName = 'cv_customization.json';

  /// Get customization file path in UserData folder
  static Future<String> _getFilePath() async {
    final userDataPath = await StorageService.instance.getUserDataPath();
    return p.join(userDataPath, _fileName);
  }

  /// Save customization settings
  static Future<void> save(TemplateCustomization customization) async {
    try {
      final filePath = await _getFilePath();
      final file = File(filePath);
      final json = customization.toJson();
      await file.writeAsString(
        JsonConstants.prettyEncoder.convert(json),
      );
    } catch (e) {
      debugPrint('[CustomizationPersistence] Failed to save: $e');
    }
  }

  /// Load customization settings
  static Future<TemplateCustomization?> load() async {
    try {
      final filePath = await _getFilePath();
      final file = File(filePath);

      if (!await file.exists()) return null;

      final jsonString = await file.readAsString();

      // Handle empty or whitespace-only files
      if (jsonString.trim().isEmpty) {
        debugPrint('[CustomizationPersistence] File is empty, using defaults');
        await _safeDeleteFile(file);
        return null;
      }

      final json = jsonDecode(jsonString) as Map<String, dynamic>;
      return TemplateCustomization.fromJson(json);
    } catch (e) {
      debugPrint('[CustomizationPersistence] Failed to load: $e');
      // Delete corrupted file to prevent repeated errors
      await _deleteCorruptedFile();
      return null;
    }
  }

  /// Clear saved settings
  static Future<void> clear() async {
    try {
      final filePath = await _getFilePath();
      final file = File(filePath);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      debugPrint('[CustomizationPersistence] Failed to clear: $e');
    }
  }

  /// Safely delete a file, ignoring errors
  static Future<void> _safeDeleteFile(File file) async {
    try {
      if (await file.exists()) {
        await file.delete();
        debugPrint('[CustomizationPersistence] Deleted file: ${file.path}');
      }
    } catch (e) {
      debugPrint('[CustomizationPersistence] Failed to delete file: $e');
    }
  }

  /// Delete corrupted customization file
  static Future<void> _deleteCorruptedFile() async {
    try {
      final filePath = await _getFilePath();
      await _safeDeleteFile(File(filePath));
    } catch (e) {
      debugPrint('[CustomizationPersistence] Failed to delete corrupted file: $e');
    }
  }
}
