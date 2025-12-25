import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import '../models/template_style.dart';

/// Portable settings service that stores configuration in a JSON file
class SettingsService extends ChangeNotifier {
  static const Color defaultAccentColor = Color(0xFF6366F1);

  ThemeMode _themeMode = ThemeMode.system;
  Color _accentColor = defaultAccentColor;
  TemplateStyle _defaultCvTemplate = TemplateStyle.professional;
  TemplateStyle _defaultCoverLetterTemplate = TemplateStyle.professional;

  ThemeMode get themeMode => _themeMode;
  Color get accentColor => _accentColor;
  bool get isDarkMode => _themeMode == ThemeMode.dark;
  TemplateStyle get defaultCvTemplate => _defaultCvTemplate;
  TemplateStyle get defaultCoverLetterTemplate => _defaultCoverLetterTemplate;

  Future<String> _getUserDataPath() async {
    final exePath = Platform.resolvedExecutable;
    final exeDir = p.dirname(exePath);
    final userDataPath = p.join(exeDir, 'UserData');

    final userDataDir = Directory(userDataPath);
    if (!userDataDir.existsSync()) {
      userDataDir.createSync(recursive: true);
    }

    return userDataPath;
  }

  Future<File> _getSettingsFile() async {
    final userDataPath = await _getUserDataPath();
    return File(p.join(userDataPath, 'settings.json'));
  }

  Future<void> loadSettings() async {
    try {
      final file = await _getSettingsFile();

      if (!file.existsSync()) {
        debugPrint('No settings file found, using defaults');
        return;
      }

      final content = await file.readAsString();
      final json = jsonDecode(content) as Map<String, dynamic>;

      final themeModeStr = json['themeMode'] as String?;
      if (themeModeStr != null) {
        _themeMode = ThemeMode.values.firstWhere(
          (e) => e.toString() == themeModeStr,
          orElse: () => ThemeMode.system,
        );
      }

      final accentColorInt = json['accentColor'] as int?;
      if (accentColorInt != null) {
        _accentColor = Color(accentColorInt);
      }

      if (json['defaultCvTemplate'] != null) {
        _defaultCvTemplate = TemplateStyle.fromJson(
          json['defaultCvTemplate'] as Map<String, dynamic>,
        );
      }

      if (json['defaultCoverLetterTemplate'] != null) {
        _defaultCoverLetterTemplate = TemplateStyle.fromJson(
          json['defaultCoverLetterTemplate'] as Map<String, dynamic>,
        );
      }

      debugPrint('Settings loaded successfully');
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading settings: $e');
    }
  }

  Future<void> _saveSettings() async {
    try {
      final file = await _getSettingsFile();

      final json = {
        'themeMode': _themeMode.toString(),
        'accentColor': _accentColor.toARGB32(),
        'defaultCvTemplate': _defaultCvTemplate.toJson(),
        'defaultCoverLetterTemplate': _defaultCoverLetterTemplate.toJson(),
      };

      await file.writeAsString(
        const JsonEncoder.withIndent('  ').convert(json),
      );

      debugPrint('Settings saved');
    } catch (e) {
      debugPrint('Error saving settings: $e');
    }
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    notifyListeners();
    await _saveSettings();
  }

  Future<void> setAccentColor(Color color) async {
    _accentColor = color;
    notifyListeners();
    await _saveSettings();
  }

  Future<void> toggleTheme() async {
    if (_themeMode == ThemeMode.dark) {
      await setThemeMode(ThemeMode.light);
    } else {
      await setThemeMode(ThemeMode.dark);
    }
  }

  Future<void> setDefaultCvTemplate(TemplateStyle template) async {
    _defaultCvTemplate = template;
    notifyListeners();
    await _saveSettings();
  }

  Future<void> setDefaultCoverLetterTemplate(TemplateStyle template) async {
    _defaultCoverLetterTemplate = template;
    notifyListeners();
    await _saveSettings();
  }

  Future<void> resetSettings() async {
    _themeMode = ThemeMode.system;
    _accentColor = defaultAccentColor;
    _defaultCvTemplate = TemplateStyle.professional;
    _defaultCoverLetterTemplate = TemplateStyle.professional;

    notifyListeners();
    await _saveSettings();

    debugPrint('Settings reset to defaults');
  }
}
