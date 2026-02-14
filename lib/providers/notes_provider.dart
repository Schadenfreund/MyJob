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

  /// Get active to-dos (incomplete and not archived)
  List<NoteItem> get activeTodos => _filterBySearch(_notes
      .where((note) =>
          !note.completed &&
          !note.archived &&
          note.type == NoteType.todo)
      .toList()
    ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder)));

  /// Get completed to-dos (completed but not archived)
  List<NoteItem> get completedTodos => _filterBySearch(_notes
      .where((note) =>
          note.completed &&
          !note.archived &&
          note.type == NoteType.todo)
      .toList()
    ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder)));

  /// Get active reminders (incomplete and not archived)
  List<NoteItem> get activeReminders => _filterBySearch(_notes
      .where((note) =>
          !note.completed &&
          !note.archived &&
          note.type == NoteType.reminder)
      .toList()
    ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder)));

  /// Get completed reminders (completed but not archived)
  List<NoteItem> get completedReminders => _filterBySearch(_notes
      .where((note) =>
          note.completed &&
          !note.archived &&
          note.type == NoteType.reminder)
      .toList()
    ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder)));

  /// Legacy: Get active tasks (todos & reminders that are incomplete and not archived)
  @Deprecated('Use activeTodos and activeReminders separately')
  List<NoteItem> get activeTasks => _filterBySearch(_notes
      .where((note) =>
          !note.completed &&
          !note.archived &&
          (note.type == NoteType.todo || note.type == NoteType.reminder))
      .toList()
    ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder)));

  /// Legacy: Get completed tasks (todos & reminders that are completed but not archived)
  @Deprecated('Use completedTodos and completedReminders separately')
  List<NoteItem> get completedTasks => _filterBySearch(_notes
      .where((note) =>
          note.completed &&
          !note.archived &&
          (note.type == NoteType.todo || note.type == NoteType.reminder))
      .toList()
    ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder)));

  /// Get company leads (not archived)
  List<NoteItem> get companyLeads => _filterBySearch(_notes
      .where((note) => note.type == NoteType.companyLead && !note.archived)
      .toList()
    ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder)));

  /// Get general notes (not archived)
  List<NoteItem> get generalNotes => _filterBySearch(_notes
      .where((note) => note.type == NoteType.generalNote && !note.archived)
      .toList()
    ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder)));

  /// Get archived notes with search filter
  List<NoteItem> get archivedNotes => _filterBySearch(
      _notes.where((note) => note.archived).toList()
        ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder)));

  // Legacy getters for backward compatibility
  @Deprecated('Use activeTasks or other category-specific getters')
  List<NoteItem> get activeNotes => _filterBySearch(
      _notes.where((note) => !note.completed && !note.archived).toList());

  @Deprecated('Use completedTasks or other category-specific getters')
  List<NoteItem> get completedNotes => _filterBySearch(
      _notes.where((note) => note.completed && !note.archived).toList());

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

  /// Update lead status for company lead
  Future<void> updateLeadStatus(String id, LeadStatus status) async {
    final note = _notes.firstWhere((n) => n.id == id);
    final updated = note.copyWith(leadStatus: status);
    await saveNote(updated);
  }

  /// Reorder notes within a category
  Future<void> reorderNotes(
    List<NoteItem> categoryNotes,
    int oldIndex,
    int newIndex,
  ) async {
    try {
      // Adjust newIndex if dragging down
      if (oldIndex < newIndex) {
        newIndex -= 1;
      }

      // Get the note being moved
      final movedNote = categoryNotes[oldIndex];

      // Remove from old position
      categoryNotes.removeAt(oldIndex);

      // Insert at new position
      categoryNotes.insert(newIndex, movedNote);

      // Update sortOrder for all notes in this category
      for (var i = 0; i < categoryNotes.length; i++) {
        final note = categoryNotes[i];
        final updated = note.copyWith(sortOrder: i);
        final globalIndex = _notes.indexWhere((n) => n.id == note.id);
        if (globalIndex >= 0) {
          _notes[globalIndex] = updated;
        }
      }

      // Save all updated notes
      await _storage.saveAllNotes(_notes);
      notifyListeners();
    } catch (e) {
      debugPrint('Error reordering notes: $e');
      rethrow;
    }
  }
}
