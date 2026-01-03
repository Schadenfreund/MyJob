import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/template_customization.dart';

/// Service for persisting template customization settings
class CustomizationPersistence {
  static const String _key = 'cv_customization';

  /// Save customization settings
  static Future<void> save(TemplateCustomization customization) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final json = customization.toJson();
      await prefs.setString(_key, jsonEncode(json));
    } catch (e) {
      // Silently fail - persistence is not critical
      print('Failed to save customization: $e');
    }
  }

  /// Load customization settings
  static Future<TemplateCustomization?> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_key);
      if (jsonString == null) return null;

      final json = jsonDecode(jsonString) as Map<String, dynamic>;
      return TemplateCustomization.fromJson(json);
    } catch (e) {
      // Return null on error - will use defaults
      print('Failed to load customization: $e');
      return null;
    }
  }

  /// Clear saved settings
  static Future<void> clear() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_key);
    } catch (e) {
      print('Failed to clear customization: $e');
    }
  }
}
