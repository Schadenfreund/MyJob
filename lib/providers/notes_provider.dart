import 'package:flutter/material.dart';
import '../models/notes_data.dart';
import '../services/storage_service.dart';

/// Provider for managing notes
class NotesProvider with ChangeNotifier {
  final _storage = StorageService.instance;
  List<NoteItem> _notes = [];
  bool _isLoading = false;

  List<NoteItem> get notes => _notes;
  bool get isLoading => _isLoading;

  String _searchQuery = '';
  String get searchQuery => _searchQuery;

  /// Set search query and filter notes
  void setSearchQuery(String query) {
    _searchQuery = query.toLowerCase();
    notifyListeners();
  }

  /// Filter notes by search query
  List<NoteItem> _filterBySearch(List<NoteItem> notes) {
    if (_searchQuery.isEmpty) return notes;
    return notes.where((note) {
      return note.title.toLowerCase().contains(_searchQuery) ||
          (note.description?.toLowerCase().contains(_searchQuery) ?? false) ||
          note.tags.any((tag) => tag.toLowerCase().contains(_searchQuery));
    }).toList();
  }

  /// Get active (incomplete and not archived) notes with search filter
  List<NoteItem> get activeNotes => _filterBySearch(
      _notes.where((note) => !note.completed && !note.archived).toList());

  /// Get completed (but not archived) notes with search filter
  List<NoteItem> get completedNotes => _filterBySearch(
      _notes.where((note) => note.completed && !note.archived).toList());

  /// Get archived notes with search filter
  List<NoteItem> get archivedNotes =>
      _filterBySearch(_notes.where((note) => note.archived).toList());

  /// Load all notes
  Future<void> loadNotes() async {
    _isLoading = true;
    notifyListeners();

    try {
      _notes = await _storage.loadNotes();
    } catch (e) {
      debugPrint('Error loading notes: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Add or update a note
  Future<void> saveNote(NoteItem note) async {
    try {
      await _storage.saveNote(note);

      final index = _notes.indexWhere((n) => n.id == note.id);
      if (index >= 0) {
        _notes[index] = note;
      } else {
        _notes.insert(0, note);
      }

      notifyListeners();
    } catch (e) {
      debugPrint('Error saving note: $e');
      rethrow;
    }
  }

  /// Delete a note
  Future<void> deleteNote(String id) async {
    try {
      await _storage.deleteNote(id);
      _notes.removeWhere((note) => note.id == id);
      notifyListeners();
    } catch (e) {
      debugPrint('Error deleting note: $e');
      rethrow;
    }
  }

  /// Toggle note completion
  Future<void> toggleCompletion(String id) async {
    final note = _notes.firstWhere((n) => n.id == id);
    final updated = note.copyWith(
      completed: !note.completed,
      completedAt: !note.completed ? DateTime.now() : null,
    );
    await saveNote(updated);
  }

  /// Archive a note
  Future<void> archiveNote(String id) async {
    final note = _notes.firstWhere((n) => n.id == id);
    final updated = note.copyWith(archived: true);
    await saveNote(updated);
  }

  /// Unarchive a note
  Future<void> unarchiveNote(String id) async {
    final note = _notes.firstWhere((n) => n.id == id);
    final updated = note.copyWith(archived: false);
    await saveNote(updated);
  }
}
