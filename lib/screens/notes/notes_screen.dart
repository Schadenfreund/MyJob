import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/notes_provider.dart';
import '../../models/notes_data.dart';
import '../../theme/app_theme.dart';
import '../../utils/ui_utils.dart';
import '../../widgets/app_card.dart';
import '../../widgets/note_card.dart';
import '../../utils/dialog_utils.dart';
import '../../services/preferences_service.dart';
import 'note_editor_dialog.dart';
import '../../localization/app_localizations.dart';

/// Notes Screen - Todo tracker and notes management
class NotesScreen extends StatefulWidget {
  const NotesScreen({super.key});

  @override
  State<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends State<NotesScreen> {
  NoteType? _filterType;
  bool _showArchived = false; // New filter for archived notes

  // Collapsible sections state
  bool _activeExpanded = true;
  bool _completedExpanded = true;
  bool _archivedExpanded = true;

  // Preference keys
  static const String _prefKeyActiveExpanded = 'notes_active_expanded';
  static const String _prefKeyCompletedExpanded = 'notes_completed_expanded';
  static const String _prefKeyArchivedExpanded = 'notes_archived_expanded';

  final _prefs = PreferencesService.instance;
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _initializePreferences();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _initializePreferences() async {
    await _prefs.initialize();
    _loadExpandedStates();
  }

  void _loadExpandedStates() {
    setState(() {
      _activeExpanded =
          _prefs.getBool(_prefKeyActiveExpanded, defaultValue: true);
      _completedExpanded =
          _prefs.getBool(_prefKeyCompletedExpanded, defaultValue: true);
      _archivedExpanded =
          _prefs.getBool(_prefKeyArchivedExpanded, defaultValue: true);
    });
  }

  Future<void> _saveExpandedState(
    String prefKey,
    bool value,
    void Function(bool) updateState,
  ) async {
    await _prefs.setBool(prefKey, value);
    setState(() => updateState(value));
  }

  Future<void> _saveActiveExpanded(bool value) => _saveExpandedState(
      _prefKeyActiveExpanded, value, (v) => _activeExpanded = v);

  Future<void> _saveCompletedExpanded(bool value) => _saveExpandedState(
      _prefKeyCompletedExpanded, value, (v) => _completedExpanded = v);

  Future<void> _saveArchivedExpanded(bool value) => _saveExpandedState(
      _prefKeyArchivedExpanded, value, (v) => _archivedExpanded = v);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final notesProvider = context.watch<NotesProvider>();

    if (notesProvider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    // Filter notes based on archive state
    final activeNotes =
        _showArchived ? <NoteItem>[] : _filterNotes(notesProvider.activeNotes);
    final completedNotes = _showArchived
        ? <NoteItem>[]
        : _filterNotes(notesProvider.completedNotes);
    final archivedNotes = _showArchived
        ? _filterNotes(notesProvider.archivedNotes)
        : <NoteItem>[];

    return Container(
      color: theme.colorScheme.surface,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            UIUtils.buildSectionHeader(
              context,
              title: context.tr('notes_title'),
              subtitle: context.tr('notes_subtitle'),
              icon: Icons.sticky_note_2_outlined,
            ),
            const SizedBox(height: AppSpacing.lg),

            // Quick Action Card
            AppCardContainer(
              padding: EdgeInsets.zero,
              useAccentBorder: true,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      theme.colorScheme.primary.withOpacity(0.08),
                      theme.colorScheme.primary.withOpacity(0.02),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius:
                      BorderRadius.circular(AppDimensions.cardBorderRadius),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(
                              AppDimensions.inputBorderRadius),
                        ),
                        child: Icon(
                          Icons.add_task,
                          color: theme.colorScheme.primary,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.lg),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  context.tr('stay_organized'),
                                  style: theme.textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: theme.colorScheme.primary,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    context.tr('add_note_badge'),
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      color: theme.colorScheme.onPrimary,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              context.tr('notes_action_desc'),
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.textTheme.bodySmall?.color
                                    ?.withOpacity(0.8),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: AppSpacing.lg),
                      AppCardActionButton(
                        onPressed: () => _showNoteEditor(context),
                        icon: Icons.add,
                        label: context.tr('add_note'),
                        isFilled: true,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            // Filter chips
            _buildFilterChips(theme),
            const SizedBox(height: AppSpacing.md),

            // Search Bar
            TextField(
              controller: _searchController,
              onChanged: (value) {
                context.read<NotesProvider>().setSearchQuery(value);
              },
              decoration: InputDecoration(
                hintText: context.tr('search_notes_placeholder'),
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          context.read<NotesProvider>().setSearchQuery('');
                        },
                      )
                    : null,
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            // Active Notes Section
            if (activeNotes.isNotEmpty) ...[
              _buildNotesSection(
                context,
                title: context.tr('active_filter'),
                subtitle: activeNotes.length != 1
                    ? context.tr('items_count_plural',
                        {'count': activeNotes.length.toString()})
                    : context.tr('items_count',
                        {'count': activeNotes.length.toString()}),
                notes: activeNotes,
                icon: Icons.pending_actions,
                color: AppColors.statusApplied,
                showArchiveAction: true,
                isExpanded: _activeExpanded,
                onExpandChanged: (value) => _saveActiveExpanded(value),
              ),
              const SizedBox(height: AppSpacing.md),
            ],

            // Completed Notes Section
            if (completedNotes.isNotEmpty) ...[
              _buildNotesSection(
                context,
                title: context.tr('section_completed'),
                subtitle: completedNotes.length != 1
                    ? context.tr('items_count_plural',
                        {'count': completedNotes.length.toString()})
                    : context.tr('items_count',
                        {'count': completedNotes.length.toString()}),
                notes: completedNotes,
                icon: Icons.check_circle,
                color: AppColors.statusAccepted,
                showArchiveAction: true,
                isExpanded: _completedExpanded,
                onExpandChanged: (value) => _saveCompletedExpanded(value),
              ),
              const SizedBox(height: AppSpacing.md),
            ],

            // Archived Notes Section
            if (archivedNotes.isNotEmpty) ...[
              _buildNotesSection(
                context,
                title: context.tr('archived_filter'),
                subtitle: archivedNotes.length != 1
                    ? context.tr('items_count_plural',
                        {'count': archivedNotes.length.toString()})
                    : context.tr('items_count',
                        {'count': archivedNotes.length.toString()}),
                notes: archivedNotes,
                icon: Icons.archive,
                color: Colors.grey,
                showUnarchiveAction: true,
                isExpanded: _archivedExpanded,
                onExpandChanged: (value) => _saveArchivedExpanded(value),
              ),
            ],

            //Empty state
            if (activeNotes.isEmpty &&
                completedNotes.isEmpty &&
                archivedNotes.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
                child: UIUtils.buildEmptyState(
                  context,
                  icon: _filterType != null
                      ? Icons.filter_list_off
                      : Icons.note_add_outlined,
                  title: _filterType != null
                      ? context.tr('no_filtered_notes_title',
                          {'type': context.tr(_filterType!.localizationKey)})
                      : context.tr('no_notes_title'),
                  message: _filterType != null
                      ? context.tr('no_filtered_notes_message')
                      : context.tr('no_notes_message'),
                  action: AppCardActionButton(
                    label: _filterType != null
                        ? context.tr('clear_filter')
                        : context.tr('add_note'),
                    onPressed: () {
                      if (_filterType != null) {
                        setState(() => _filterType = null);
                      } else {
                        _showNoteEditor(context);
                      }
                    },
                    icon:
                        _filterType != null ? Icons.filter_list_off : Icons.add,
                    isFilled: true,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChips(ThemeData theme) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _buildFilterChip(
            theme,
            label: context.tr('all_filter'),
            isSelected: !_showArchived && _filterType == null,
            onTap: () => setState(() {
              _showArchived = false;
              _filterType = null;
            }),
          ),
          const SizedBox(width: 8),
          ...NoteType.values.map((type) => Padding(
                padding: const EdgeInsets.only(right: 8),
                child: _buildFilterChip(
                  theme,
                  label: context.tr(type.localizationKey),
                  isSelected: !_showArchived && _filterType == type,
                  onTap: () => setState(() {
                    _showArchived = false;
                    _filterType = type;
                  }),
                ),
              )),
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: _buildFilterChip(
              theme,
              label: context.tr('archive_filter'),
              isSelected: _showArchived,
              onTap: () => setState(() {
                _showArchived = true;
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(
    ThemeData theme, {
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: AnimatedContainer(
        duration: AppDurations.quick,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? theme.colorScheme.primary
              : theme.colorScheme.surfaceContainerHighest.withOpacity(0.3),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected
                ? theme.colorScheme.primary
                : theme.colorScheme.outline.withOpacity(0.2),
          ),
        ),
        child: Text(
          label,
          style: theme.textTheme.labelMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: isSelected
                ? theme.colorScheme.onPrimary
                : theme.textTheme.bodySmall?.color?.withOpacity(0.7),
          ),
        ),
      ),
    );
  }

  Widget _buildNotesSection(
    BuildContext context, {
    required String title,
    required String subtitle,
    required List<NoteItem> notes,
    required IconData icon,
    required Color color,
    bool showArchiveAction = false,
    bool showUnarchiveAction = false,
    required bool isExpanded,
    required ValueChanged<bool> onExpandChanged,
  }) {
    final theme = Theme.of(context);

    return AppCardContainer(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => onExpandChanged(!isExpanded),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(AppDimensions.cardBorderRadius),
                topRight: Radius.circular(AppDimensions.cardBorderRadius),
              ),
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(icon, size: 18, color: color),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color:
                            theme.textTheme.bodySmall?.color?.withOpacity(0.6),
                      ),
                    ),
                    const Spacer(),
                    Icon(
                      isExpanded ? Icons.expand_less : Icons.expand_more,
                      size: 24,
                      color: theme.textTheme.bodySmall?.color?.withOpacity(0.6),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (isExpanded)
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: notes.length,
                separatorBuilder: (context, index) =>
                    const SizedBox(height: AppSpacing.md),
                itemBuilder: (context, index) {
                  final note = notes[index];
                  return NoteCard(
                    note: note,
                    onToggleComplete: () => _toggleCompletion(context, note),
                    onEdit: () => _showNoteEditor(context, note: note),
                    onDelete: () => _confirmDelete(context, note),
                    onArchive: showArchiveAction
                        ? () => _archiveNote(context, note)
                        : null,
                    onUnarchive: showUnarchiveAction
                        ? () => _unarchiveNote(context, note)
                        : null,
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  List<NoteItem> _filterNotes(List<NoteItem> notes) {
    if (_filterType == null) return notes;
    return notes.where((note) => note.type == _filterType).toList();
  }

  Future<void> _showNoteEditor(BuildContext context, {NoteItem? note}) async {
    final result = await showDialog<NoteItem>(
      context: context,
      builder: (context) => NoteEditorDialog(note: note),
    );

    if (result != null && mounted) {
      try {
        await context.read<NotesProvider>().saveNote(result);
        if (mounted) {
          UIUtils.showSuccess(
            context,
            note == null
                ? context.tr('note_created')
                : context.tr('note_updated'),
          );
        }
      } catch (e) {
        if (mounted) {
          UIUtils.showError(
              context, context.tr('failed_save_note', {'error': e.toString()}));
        }
      }
    }
  }

  Future<void> _toggleCompletion(BuildContext context, NoteItem note) async {
    try {
      await context.read<NotesProvider>().toggleCompletion(note.id);
    } catch (e) {
      if (mounted) {
        UIUtils.showError(
            context, context.tr('failed_update_note', {'error': e.toString()}));
      }
    }
  }

  Future<void> _confirmDelete(BuildContext context, NoteItem note) async {
    final confirmed = await DialogUtils.showDeleteConfirmation(
      context,
      title: context.tr('delete_note_title'),
      message: context.tr('delete_note_message', {'title': note.title}),
    );

    if (confirmed && mounted) {
      try {
        await context.read<NotesProvider>().deleteNote(note.id);
        if (mounted) {
          UIUtils.showSuccess(context, context.tr('note_deleted'));
        }
      } catch (e) {
        if (mounted) {
          UIUtils.showError(context,
              context.tr('failed_delete_note', {'error': e.toString()}));
        }
      }
    }
  }

  Future<void> _archiveNote(BuildContext context, NoteItem note) async {
    try {
      await context.read<NotesProvider>().archiveNote(note.id);
      if (mounted) {
        UIUtils.showSuccess(context, context.tr('note_archived'));
      }
    } catch (e) {
      if (mounted) {
        UIUtils.showError(context,
            context.tr('failed_archive_note', {'error': e.toString()}));
      }
    }
  }

  Future<void> _unarchiveNote(BuildContext context, NoteItem note) async {
    try {
      await context.read<NotesProvider>().unarchiveNote(note.id);
      if (mounted) {
        UIUtils.showSuccess(context, context.tr('note_unarchived'));
      }
    } catch (e) {
      if (mounted) {
        UIUtils.showError(context,
            context.tr('failed_unarchive_note', {'error': e.toString()}));
      }
    }
  }
}
