import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:uuid/uuid.dart';
import '../models/pdf_document_type.dart';
import '../models/pdf_preset.dart';
import '../services/storage_service.dart';
import '../constants/json_constants.dart';

class PdfPresetsProvider extends ChangeNotifier {
  List<PdfPreset> _presets = [];
  bool _isLoading = false;

  List<PdfPreset> get presets => _presets;
  bool get isLoading => _isLoading;

  /// Get presets filtered by document type
  List<PdfPreset> getPresetsByType(PdfDocumentType type) {
    return _presets.where((p) => p.type == type).toList();
  }

  PdfPresetsProvider() {
    loadPresets();
  }

  Future<String> _getPresetsPath() async {
    final storage = StorageService.instance;
    final userDataPath = await storage.getUserDataPath();
    final presetsPath = p.join(userDataPath, 'pdf_presets');

    final dir = Directory(presetsPath);
    if (!dir.existsSync()) {
      dir.createSync(recursive: true);
    }

    return presetsPath;
  }

  Future<void> loadPresets() async {
    _isLoading = true;
    notifyListeners();

    try {
      final presetsPath = await _getPresetsPath();
      final dir = Directory(presetsPath);
      final List<PdfPreset> loadedPresets = [];

      if (dir.existsSync()) {
        for (final file in dir.listSync().whereType<File>()) {
          if (file.path.endsWith('.json')) {
            try {
              final content = await file.readAsString();
              final json = jsonDecode(content) as Map<String, dynamic>;
              loadedPresets.add(PdfPreset.fromJson(json));
            } catch (e) {
              debugPrint('Error loading preset ${file.path}: $e');
            }
          }
        }
      }

      // Sort by creation date
      loadedPresets.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      _presets = loadedPresets;
    } catch (e) {
      debugPrint('Error loading presets: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<PdfPreset> savePreset(
    String name,
    dynamic style,
    dynamic customization, {
    required PdfDocumentType type,
    String? basedOnPresetName,
  }) async {
    final presetsPath = await _getPresetsPath();
    final id = const Uuid().v4();
    final preset = PdfPreset(
      id: id,
      name: name,
      type: type,
      basedOnPresetName: basedOnPresetName,
      style: style,
      customization: customization,
      createdAt: DateTime.now(),
    );

    final file = File(p.join(presetsPath, '$id.json'));
    await file.writeAsString(
      JsonConstants.prettyEncoder.convert(preset.toJson()),
    );

    _presets.insert(0, preset);
    notifyListeners();
    return preset;
  }

  Future<void> updatePreset(PdfPreset updatedPreset) async {
    final presetsPath = await _getPresetsPath();
    final file = File(p.join(presetsPath, '${updatedPreset.id}.json'));
    await file.writeAsString(
      JsonConstants.prettyEncoder.convert(updatedPreset.toJson()),
    );

    final index = _presets.indexWhere((p) => p.id == updatedPreset.id);
    if (index != -1) {
      _presets[index] = updatedPreset;
      notifyListeners();
    }
  }

  Future<void> deletePreset(String id) async {
    try {
      final presetsPath = await _getPresetsPath();
      final file = File(p.join(presetsPath, '$id.json'));
      if (file.existsSync()) {
        await file.delete();
      }
      _presets.removeWhere((p) => p.id == id);
      notifyListeners();
    } catch (e) {
      debugPrint('Error deleting preset: $e');
    }
  }
}
