// ===========================================================================
// App Localizations Service
// ===========================================================================
//
// JSON-based localization system. Ships with English and German built-in.
// Users can add custom languages by dropping locale_xx.json files into
// the UserData/localization/ folder.
//
// Usage:
//   final tr = AppLocalizations.of(context);
//   Text(tr.translate('settings'))        // → "Settings" or "Einstellungen"
//   Text(tr.translate('greeting', {'name': 'Max'})) // → "Hello, Max!"
// ===========================================================================

import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:path/path.dart' as p;
import 'package:provider/provider.dart';

/// Metadata about a language (from the _meta section of the JSON file)
class LanguageInfo {
  const LanguageInfo({
    required this.code,
    required this.name,
    required this.flag,
    this.author,
    this.version,
    this.isBuiltIn = false,
    this.filePath,
  });

  final String code;
  final String name;
  final String flag;
  final String? author;
  final String? version;
  final bool isBuiltIn;
  final String? filePath; // null for built-in, path for custom

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LanguageInfo &&
          runtimeType == other.runtimeType &&
          code == other.code;

  @override
  int get hashCode => code.hashCode;
}

/// The main localization class. Provides string lookup via translate().
class AppLocalizations extends ChangeNotifier {
  /// Built-in language codes
  static const List<String> builtInLanguages = ['en', 'de'];

  /// Current language code
  String _currentLanguageCode = 'en';
  String get currentLanguageCode => _currentLanguageCode;

  /// All loaded translations for the current language
  Map<String, String> _translations = {};

  /// English fallback translations (always loaded)
  Map<String, String> _fallbackTranslations = {};

  /// Available languages (built-in + discovered custom)
  List<LanguageInfo> _availableLanguages = [];
  List<LanguageInfo> get availableLanguages =>
      List.unmodifiable(_availableLanguages);

  /// Whether the service has been initialized
  bool _initialized = false;
  bool get isInitialized => _initialized;

  /// Access from context (for convenience)
  static AppLocalizations of(BuildContext context) {
    return Provider.of<AppLocalizations>(context, listen: false);
  }

  // =========================================================================
  // Initialization
  // =========================================================================

  /// Initialize the localization system. Call once at app startup.
  /// [languageCode] is the saved language preference (from settings.json).
  Future<void> initialize({String languageCode = 'en'}) async {
    if (_initialized) return;

    // 1. Load English fallback (always available)
    _fallbackTranslations = await _loadBuiltInLocale('en');

    // 2. Discover all available languages
    await _discoverLanguages();

    // 3. Load the requested language
    await setLanguage(languageCode, notify: false);

    _initialized = true;
    notifyListeners();
  }

  // =========================================================================
  // Language switching
  // =========================================================================

  /// Switch to a different language. Returns true if successful.
  Future<bool> setLanguage(String code, {bool notify = true}) async {
    try {
      Map<String, String> translations;

      if (builtInLanguages.contains(code)) {
        translations = await _loadBuiltInLocale(code);
      } else {
        // Try to load from UserData/localization/
        final customPath = await _getCustomLocalePath(code);
        if (customPath != null && File(customPath).existsSync()) {
          translations = await _loadLocaleFromFile(customPath);
        } else {
          debugPrint('Locale "$code" not found, falling back to English');
          translations = _fallbackTranslations;
          code = 'en';
        }
      }

      _translations = translations;
      _currentLanguageCode = code;

      if (notify) notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error loading locale "$code": $e');
      _translations = _fallbackTranslations;
      _currentLanguageCode = 'en';
      if (notify) notifyListeners();
      return false;
    }
  }

  // =========================================================================
  // Translation lookup
  // =========================================================================

  /// Translate a key to the current language.
  /// Falls back to English if the key is not found in the current language.
  /// Falls back to the key itself if not found in English either.
  ///
  /// Supports placeholder substitution:
  ///   translate('greeting', {'name': 'Max'})
  ///   JSON: "greeting": "Hello, {name}!"
  ///   Result: "Hello, Max!"
  String translate(String key, [Map<String, String>? params]) {
    String value = _translations[key] ?? _fallbackTranslations[key] ?? key;

    // Replace placeholders
    if (params != null) {
      params.forEach((paramKey, paramValue) {
        value = value.replaceAll('{$paramKey}', paramValue);
      });
    }

    return value;
  }

  /// Shorthand alias for translate
  String tr(String key, [Map<String, String>? params]) =>
      translate(key, params);

  // =========================================================================
  // Language discovery
  // =========================================================================

  /// Discover all available languages (built-in + custom files)
  Future<void> _discoverLanguages() async {
    final languages = <LanguageInfo>[];

    // Built-in languages
    for (final code in builtInLanguages) {
      final jsonString = await rootBundle.loadString(
        'assets/localization/locale_$code.json',
      );
      final meta = _extractMetaFromJson(jsonString);
      languages.add(
        LanguageInfo(
          code: meta['language_code'] ?? code,
          name: meta['language_name'] ?? code.toUpperCase(),
          flag: meta['flag'] ?? '🏳️',
          author: meta['author'],
          version: meta['version'],
          isBuiltIn: true,
        ),
      );
    }

    // Custom languages from UserData/localization/
    try {
      final localizationDir = await _getLocalizationDir();
      if (localizationDir != null && Directory(localizationDir).existsSync()) {
        final dir = Directory(localizationDir);
        final files = dir
            .listSync()
            .whereType<File>()
            .where(
              (f) =>
                  p.basename(f.path).startsWith('locale_') &&
                  f.path.endsWith('.json'),
            )
            .toList();

        for (final file in files) {
          try {
            final code = p
                .basenameWithoutExtension(file.path)
                .replaceFirst('locale_', '');
            // Skip built-in codes (they're already handled)
            if (builtInLanguages.contains(code)) continue;

            final rawJson = await file.readAsString();
            final meta = _extractMetaFromJson(rawJson);
            languages.add(
              LanguageInfo(
                code: meta['language_code'] ?? code,
                name: meta['language_name'] ?? code.toUpperCase(),
                flag: meta['flag'] ?? '🏳️',
                author: meta['author'],
                version: meta['version'],
                isBuiltIn: false,
                filePath: file.path,
              ),
            );
          } catch (e) {
            debugPrint('Error reading custom locale ${file.path}: $e');
          }
        }
      }
    } catch (e) {
      debugPrint('Error scanning for custom locales: $e');
    }

    _availableLanguages = languages;
  }

  /// Refresh available languages (e.g., after importing a new file)
  Future<void> refreshAvailableLanguages() async {
    await _discoverLanguages();
    notifyListeners();
  }

  // =========================================================================
  // File I/O helpers
  // =========================================================================

  /// Load a built-in locale from the assets
  Future<Map<String, String>> _loadBuiltInLocale(String code) async {
    try {
      final jsonString = await rootBundle.loadString(
        'assets/localization/locale_$code.json',
      );
      return _parseLocaleJson(jsonString);
    } catch (e) {
      debugPrint('Error loading built-in locale "$code": $e');
      return {};
    }
  }

  /// Load a locale from a file on disk
  Future<Map<String, String>> _loadLocaleFromFile(String path) async {
    final file = File(path);
    final jsonString = await file.readAsString();
    return _parseLocaleJson(jsonString);
  }

  /// Parse a locale JSON string into a flat key-value map
  Map<String, String> _parseLocaleJson(String jsonString) {
    final Map<String, dynamic> json = jsonDecode(jsonString);
    final result = <String, String>{};

    for (final entry in json.entries) {
      if (entry.key == '_meta') continue; // Skip metadata
      if (entry.value is String) {
        result[entry.key] = entry.value as String;
      }
    }

    return result;
  }

  /// Extract _meta section from a raw JSON string
  Map<String, String> _extractMetaFromJson(String jsonString) {
    try {
      final Map<String, dynamic> json = jsonDecode(jsonString);
      final meta = json['_meta'] as Map<String, dynamic>?;
      if (meta == null) return {};
      return meta.map((k, v) => MapEntry(k, v.toString()));
    } catch (e) {
      return {};
    }
  }

  /// Get the UserData/localization/ directory path
  Future<String?> _getLocalizationDir() async {
    try {
      final exePath = Platform.resolvedExecutable;
      final exeDir = p.dirname(exePath);
      return p.join(exeDir, 'UserData', 'localization');
    } catch (e) {
      return null;
    }
  }

  /// Get path for a custom locale file
  Future<String?> _getCustomLocalePath(String code) async {
    final dir = await _getLocalizationDir();
    if (dir == null) return null;
    return p.join(dir, 'locale_$code.json');
  }

  /// Import a custom locale file (copy to UserData/localization/)
  Future<LanguageInfo?> importLocaleFile(String sourcePath) async {
    try {
      final file = File(sourcePath);
      if (!file.existsSync()) return null;

      // Read and validate the file
      final jsonString = await file.readAsString();
      final Map<String, dynamic> json = jsonDecode(jsonString);

      // Extract meta
      final meta = json['_meta'] as Map<String, dynamic>?;
      if (meta == null || meta['language_code'] == null) {
        debugPrint('Invalid locale file: missing _meta.language_code');
        return null;
      }

      final code = meta['language_code'] as String;

      // Ensure localization directory exists
      final dir = await _getLocalizationDir();
      if (dir == null) return null;
      final locDir = Directory(dir);
      if (!locDir.existsSync()) {
        locDir.createSync(recursive: true);
      }

      // Copy file
      final destPath = p.join(dir, 'locale_$code.json');
      await file.copy(destPath);

      // Refresh available languages
      await refreshAvailableLanguages();

      // Return the new language info
      return _availableLanguages.firstWhere(
        (l) => l.code == code,
        orElse: () => LanguageInfo(
          code: code,
          name: meta['language_name'] as String? ?? code.toUpperCase(),
          flag: meta['flag'] as String? ?? '🏳️',
          filePath: destPath,
        ),
      );
    } catch (e) {
      debugPrint('Error importing locale file: $e');
      return null;
    }
  }

  /// Delete a custom locale file
  Future<bool> deleteCustomLocale(String code) async {
    if (builtInLanguages.contains(code)) return false; // Can't delete built-in

    try {
      final path = await _getCustomLocalePath(code);
      if (path == null) return false;

      final file = File(path);
      if (file.existsSync()) {
        await file.delete();
      }

      // If current language was deleted, switch to English
      if (_currentLanguageCode == code) {
        await setLanguage('en');
      }

      await refreshAvailableLanguages();
      return true;
    } catch (e) {
      debugPrint('Error deleting custom locale: $e');
      return false;
    }
  }

  /// Get the current language info
  LanguageInfo? get currentLanguage {
    try {
      return _availableLanguages.firstWhere(
        (l) => l.code == _currentLanguageCode,
      );
    } catch (_) {
      return null;
    }
  }
}

// ===========================================================================
// BuildContext extension for easy access
// ===========================================================================

/// Extension on BuildContext for convenient translation access.
///
/// Usage:
///   context.tr('settings')  →  "Einstellungen"
extension AppLocalizationsExtension on BuildContext {
  AppLocalizations get loc => Provider.of<AppLocalizations>(this, listen: false);

  String tr(String key, [Map<String, String>? params]) =>
      loc.translate(key, params);
}
