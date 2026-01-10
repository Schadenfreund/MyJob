import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as p;
import 'storage_service.dart';

/// Service for managing user preferences stored in UserData folder
class PreferencesService {
  PreferencesService._();
  static final PreferencesService instance = PreferencesService._();

  Map<String, dynamic> _preferences = {};
  bool _isInitialized = false;

  /// Get preferences file path in UserData folder
  Future<String> _getPreferencesPath() async {
    final userDataPath = await StorageService.instance.getUserDataPath();
    return p.join(userDataPath, 'preferences.json');
  }

  /// Initialize preferences by loading from file
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      final filePath = await _getPreferencesPath();
      final file = File(filePath);

      if (await file.exists()) {
        final contents = await file.readAsString();
        _preferences = json.decode(contents) as Map<String, dynamic>;
      }
    } catch (e) {
      // If file doesn't exist or is corrupted, start with empty preferences
      _preferences = {};
    }

    _isInitialized = true;
  }

  /// Save preferences to file
  Future<void> _save() async {
    try {
      final filePath = await _getPreferencesPath();
      final file = File(filePath);
      await file.writeAsString(
        const JsonEncoder.withIndent('  ').convert(_preferences),
      );
    } catch (e) {
      // Handle save errors silently or log them
      print('Error saving preferences: $e');
    }
  }

  /// Get a boolean preference
  bool getBool(String key, {bool defaultValue = false}) {
    return _preferences[key] as bool? ?? defaultValue;
  }

  /// Set a boolean preference
  Future<void> setBool(String key, bool value) async {
    _preferences[key] = value;
    await _save();
  }

  /// Get a string preference
  String? getString(String key, {String? defaultValue}) {
    return _preferences[key] as String? ?? defaultValue;
  }

  /// Set a string preference
  Future<void> setString(String key, String value) async {
    _preferences[key] = value;
    await _save();
  }

  /// Get an integer preference
  int getInt(String key, {int defaultValue = 0}) {
    return _preferences[key] as int? ?? defaultValue;
  }

  /// Set an integer preference
  Future<void> setInt(String key, int value) async {
    _preferences[key] = value;
    await _save();
  }

  /// Get a double preference
  double getDouble(String key, {double defaultValue = 0.0}) {
    return _preferences[key] as double? ?? defaultValue;
  }

  /// Set a double preference
  Future<void> setDouble(String key, double value) async {
    _preferences[key] = value;
    await _save();
  }

  /// Remove a preference
  Future<void> remove(String key) async {
    _preferences.remove(key);
    await _save();
  }

  /// Clear all preferences
  Future<void> clear() async {
    _preferences.clear();
    await _save();
  }

  /// Check if a key exists
  bool containsKey(String key) {
    return _preferences.containsKey(key);
  }

  /// Get all keys
  Set<String> getKeys() {
    return _preferences.keys.toSet();
  }
}
