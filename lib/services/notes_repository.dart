import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:yaml/yaml.dart';
import 'log_service.dart';
import 'storage_service.dart';
import '../models/notes_data.dart';

/// Repository for notes persistence.
///
/// Handles notes CRUD using YAML files with human-readable filenames.
class NotesRepository {
  NotesRepository(this._storageService);

  final StorageService _storageService;

  // ── Notes CRUD ─────────────────────────────────────────────────────

  /// Load all notes.
  Future<List<NoteItem>> loadAll() async {
    try {
      final userDataPath = await _storageService.getUserDataPath();
      final dir = Directory(p.join(userDataPath, 'notes'));
      final notes = <NoteItem>[];

      if (!dir.existsSync()) return notes;

      for (final file in dir.listSync().whereType<File>()) {
        if (file.path.endsWith('.yaml') || file.path.endsWith('.yml')) {
          try {
            final content = await file.readAsString();
            final yaml = loadYaml(content);

            if (yaml is! YamlMap) {
              logWarning(
                  '${file.path} does not contain a valid YAML map, skipping',
                  tag: 'NotesRepo');
              continue;
            }

            final json = _yamlToJson(yaml);
            notes.add(NoteItem.fromJson(json));
          } catch (e, stackTrace) {
            logError('Error loading note ${file.path}',
                error: e, stackTrace: stackTrace, tag: 'NotesRepo');
          }
        }
      }

      // Sort by created date, newest first
      notes.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      return notes;
    } catch (e) {
      logError('Error loading notes', error: e, tag: 'NotesRepo');
      return [];
    }
  }

  /// Save a note.
  Future<void> save(NoteItem note) async {
    try {
      final userDataPath = await _storageService.getUserDataPath();
      final notesDir = Directory(p.join(userDataPath, 'notes'));

      if (!notesDir.existsSync()) {
        notesDir.createSync(recursive: true);
      }

      // First, delete any existing files for this note ID (in case title changed)
      for (final entity in notesDir.listSync()) {
        if (entity is File && entity.path.contains(note.id)) {
          await entity.delete();
        }
      }

      // Create human-readable filename: sanitized title + ID
      final sanitizedTitle = _sanitizeFileName(note.title);
      final fileName = '${sanitizedTitle}_${note.id}.yaml';
      final file = File(p.join(notesDir.path, fileName));

      final yaml = _jsonToYaml(note.toJson());

      await file.writeAsString(yaml);
      logDebug('Note saved: $fileName', tag: 'NotesRepo');
    } catch (e) {
      logError('Error saving note', error: e, tag: 'NotesRepo');
      rethrow;
    }
  }

  /// Delete a note.
  Future<void> delete(String id) async {
    try {
      final userDataPath = await _storageService.getUserDataPath();
      final notesDir = Directory(p.join(userDataPath, 'notes'));

      if (notesDir.existsSync()) {
        for (final entity in notesDir.listSync()) {
          if (entity is File && entity.path.contains(id)) {
            await entity.delete();
            logDebug('Note file deleted for ID: $id', tag: 'NotesRepo');
          }
        }
      }
    } catch (e) {
      logError('Error deleting note', error: e, tag: 'NotesRepo');
      rethrow;
    }
  }

  /// Save all notes (used for batch operations like reordering).
  Future<void> saveAll(List<NoteItem> notes) async {
    try {
      for (final note in notes) {
        await save(note);
      }
      logDebug('All notes saved (${notes.length} notes)', tag: 'NotesRepo');
    } catch (e) {
      logError('Error saving all notes', error: e, tag: 'NotesRepo');
      rethrow;
    }
  }

  // ── Private Helpers ────────────────────────────────────────────────

  String _sanitizeFileName(String name) {
    return name.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_').trim();
  }

  /// Convert YAML map to JSON-compatible map.
  Map<String, dynamic> _yamlToJson(dynamic yaml) {
    if (yaml is YamlMap) {
      return yaml.map((key, value) => MapEntry(
            key.toString(),
            _yamlToJsonValue(value),
          ));
    }
    return {};
  }

  dynamic _yamlToJsonValue(dynamic value) {
    if (value is YamlMap) {
      return value.map((key, val) => MapEntry(
            key.toString(),
            _yamlToJsonValue(val),
          ));
    } else if (value is YamlList) {
      return value.map((e) => _yamlToJsonValue(e)).toList();
    } else {
      return value;
    }
  }

  /// Convert JSON map to YAML string.
  String _jsonToYaml(Map<String, dynamic> json, [int indent = 0]) {
    final buffer = StringBuffer();
    final indentStr = '  ' * indent;

    json.forEach((key, value) {
      if (value == null) {
        buffer.writeln('$indentStr$key: null');
      } else if (value is Map) {
        buffer.writeln('$indentStr$key:');
        buffer.write(_jsonToYaml(value as Map<String, dynamic>, indent + 1));
      } else if (value is List) {
        if (value.isEmpty) {
          buffer.writeln('$indentStr$key: []');
        } else {
          buffer.writeln('$indentStr$key:');
          for (final item in value) {
            if (item is Map) {
              buffer.writeln('${indentStr}  -');
              buffer
                  .write(_jsonToYaml(item as Map<String, dynamic>, indent + 2));
            } else {
              buffer.writeln('${indentStr}  - $item');
            }
          }
        }
      } else if (value is String) {
        final escaped = value
            .replaceAll(r'\', r'\\')
            .replaceAll('"', r'\"')
            .replaceAll('\r\n', r'\n')
            .replaceAll('\n', r'\n')
            .replaceAll('\r', r'\r');
        buffer.writeln('$indentStr$key: "$escaped"');
      } else {
        buffer.writeln('$indentStr$key: $value');
      }
    });

    return buffer.toString();
  }
}
