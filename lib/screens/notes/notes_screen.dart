import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import '../../providers/notes_provider.dart';
import '../../models/notes_data.dart';
import '../../theme/app_theme.dart';
import '../../utils/ui_utils.dart';
import '../../utils/platform_utils.dart';
import '../../widgets/app_card.dart';
import '../../widgets/note_card.dart';
import '../../utils/dialog_utils.dart';
import '../../services/preferences_service.dart';
import '../../services/note_export_service.dart';
import '../../screens/applications/application_editor_dialog.dart';
import '../../providers/applications_provider.dart';
import 'note_editor_dialog.dart';
import '../../localization/app_localizations.dart';

/// Notes Screen - Organized by category: Tasks, Leads, Notes
class NotesScreen extends StatefulWidget {
  const NotesScreen({super.key});

  @override
  State<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends State<NotesScreen> {
  // Category filter
  String _selectedCategory = 'all'; // all, todos, reminders, leads, notes, completed

  // Collapsible sections state
  bool _todosExpanded = true;
  bool _remindersExpanded = true;
  bool _companyLeadsExpanded = true;
  bool _generalNotesExpanded = true;
  bool _cheatSheetsExpanded = true;
  bool _archivedExpanded = true;
  bool _timelineExpanded = true;

  // Preference keys
  static const String _prefKeyTodosExpanded = 'notes_todos_expanded';
  static const String _prefKeyRemindersExpanded = 'notes_reminders_expanded';
  static const String _prefKeyCompanyLeadsExpanded = 'notes_company_leads_expanded';
  static const String _prefKeyGeneralNotesExpanded = 'notes_general_notes_expanded';
  static const String _prefKeyCheatSheetsExpanded = 'notes_cheat_sheets_expanded';
  static const String _prefKeyArchivedExpanded = 'notes_archived_expanded';
  static const String _prefKeyTimelineExpanded = 'notes_timeline_expanded';

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
      _todosExpanded = _prefs.getBool(_prefKeyTodosExpanded, defaultValue: true);
      _remindersExpanded = _prefs.getBool(_prefKeyRemindersExpanded, defaultValue: true);
      _companyLeadsExpanded = _prefs.getBool(_prefKeyCompanyLeadsExpanded, defaultValue: true);
      _generalNotesExpanded = _prefs.getBool(_prefKeyGeneralNotesExpanded, defaultValue: true);
      _cheatSheetsExpanded = _prefs.getBool(_prefKeyCheatSheetsExpanded, defaultValue: true);
      _archivedExpanded = _prefs.getBool(_prefKeyArchivedExpanded, defaultValue: true);
      _timelineExpanded = _prefs.getBool(_prefKeyTimelineExpanded, defaultValue: true);
    });
  }

  Future<void> _saveExpandedState(String prefKey, bool value) async {
    await _prefs.setBool(prefKey, value);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final notesProvider = context.watch<NotesProvider>();

    if (notesProvider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (notesProvider.error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 48, color: theme.colorScheme.error),
            const SizedBox(height: 16),
            Text(context.tr('error_loading_notes'),
                style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            FilledButton.icon(
              onPressed: () => notesProvider.loadNotes(),
              icon: const Icon(Icons.refresh),
              label: Text(context.tr('retry')),
            ),
          ],
        ),
      );
    }

    // Get categorized notes
    final activeTodos = notesProvider.activeTodos;
    final completedTodos = notesProvider.completedTodos;
    final activeReminders = notesProvider.activeReminders;
    final completedReminders = notesProvider.completedReminders;
    final companyLeads = notesProvider.companyLeads;
    final generalNotes = notesProvider.generalNotes;
    final interviewCheatSheets = notesProvider.interviewCheatSheets;
    final archivedNotes = notesProvider.archivedNotes;

    // Calculate total counts for category filters
    final todosCount = activeTodos.length + completedTodos.length;
    final remindersCount = activeReminders.length + completedReminders.length;
    final leadsCount = companyLeads.length;
    final notesCount = generalNotes.length;
    final cheatSheetsCount = interviewCheatSheets.length;
    final completedCount = completedTodos.length + completedReminders.length;
    final archivedCount = archivedNotes.length;

    // Apply category filter
    final showTodos = _selectedCategory == 'all' || _selectedCategory == 'todos';
    final showReminders = _selectedCategory == 'all' || _selectedCategory == 'reminders';
    final showLeads = _selectedCategory == 'all' || _selectedCategory == 'leads';
    final showNotes = _selectedCategory == 'all' || _selectedCategory == 'notes';
    final showCheatSheets = _selectedCategory == 'all' || _selectedCategory == 'cheatsheets';
    final showCompleted = _selectedCategory == 'completed';
    final showArchived = _selectedCategory == 'archived';

    // Count search results
    final searchQuery = notesProvider.searchQuery;
    final hasSearchResults = searchQuery.isNotEmpty;
    final totalResults = (showTodos ? activeTodos.length + completedTodos.length : 0) +
        (showReminders ? activeReminders.length + completedReminders.length : 0) +
        (showLeads ? companyLeads.length : 0) +
        (showNotes ? generalNotes.length : 0) +
        (showCheatSheets ? interviewCheatSheets.length : 0) +
        (showCompleted ? completedCount : 0);

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
                  borderRadius: BorderRadius.circular(AppDimensions.cardBorderRadius),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(AppSpacing.sm),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(AppDimensions.inputBorderRadius),
                        ),
                        child: Icon(
                          Icons.add_task,
                          color: theme.colorScheme.primary,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
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
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
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
                            const SizedBox(height: 2),
                            Text(
                              context.tr('notes_action_desc'),
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.textTheme.bodySmall?.color?.withOpacity(0.8),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Row(
                        children: [
                          AppCardActionButton(
                            onPressed: () => _showNoteEditor(context),
                            icon: Icons.add,
                            label: context.tr('add'),
                            isFilled: true,
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          AppCardActionButton(
                            onPressed: () => _exportNotes(context, notesProvider),
                            icon: Icons.download,
                            label: context.tr('notes_export_report'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            // Category filter chips
            _buildCategoryFilters(theme, todosCount, remindersCount, leadsCount, notesCount, cheatSheetsCount, completedCount, archivedCount),
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

            // Upcoming events timeline
            if (_selectedCategory != 'archived')
              _buildUpcomingTimeline(context, theme, notesProvider),

            // Search results counter
            if (hasSearchResults) ...[
              const SizedBox(height: AppSpacing.sm),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                child: Text(
                  totalResults == 1
                      ? context.tr('search_result_singular')
                      : context.tr('search_results_plural', {'count': '$totalResults'}),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.textTheme.bodySmall?.color?.withOpacity(0.6),
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ],
            const SizedBox(height: AppSpacing.md),

            // To-Dos Section (Active + Completed combined for drag-to-complete)
            if (showTodos && !showCompleted && (activeTodos.isNotEmpty || completedTodos.isNotEmpty)) ...[
              _buildCombinedTasksSection(
                context,
                title: context.tr('note_type_todo'),
                icon: Icons.check_circle_outline,
                color: AppColors.statusApplied,
                activeTasks: activeTodos,
                completedTasks: completedTodos,
                isExpanded: _todosExpanded,
                onExpandChanged: (value) {
                  setState(() => _todosExpanded = value);
                  _saveExpandedState(_prefKeyTodosExpanded, value);
                },
              ),
              const SizedBox(height: AppSpacing.md),
            ],

            // Reminders Section (Active + Completed combined for drag-to-complete)
            if (showReminders && !showCompleted && (activeReminders.isNotEmpty || completedReminders.isNotEmpty)) ...[
              _buildCombinedTasksSection(
                context,
                title: context.tr('note_type_reminder'),
                icon: Icons.alarm,
                color: Colors.pink,
                activeTasks: activeReminders,
                completedTasks: completedReminders,
                isExpanded: _remindersExpanded,
                onExpandChanged: (value) {
                  setState(() => _remindersExpanded = value);
                  _saveExpandedState(_prefKeyRemindersExpanded, value);
                },
              ),
              const SizedBox(height: AppSpacing.md),
            ],

            // Company Leads Section
            if (showLeads && !showCompleted) ...[
              if (companyLeads.isNotEmpty)
                _buildReorderableSection(
                  context,
                  title: context.tr('section_company_leads'),
                  subtitle: _buildCountSubtitle(context, companyLeads.length),
                  notes: companyLeads,
                  icon: Icons.business,
                  color: Colors.purple,
                  isExpanded: _companyLeadsExpanded,
                  onExpandChanged: (value) {
                    setState(() => _companyLeadsExpanded = value);
                    _saveExpandedState(_prefKeyCompanyLeadsExpanded, value);
                  },
                  onReorder: (oldIndex, newIndex) => _handleReorder(
                    context,
                    companyLeads,
                    oldIndex,
                    newIndex,
                  ),
                  showArchiveAction: true,
                  collapsedPreview: _buildLeadsCollapsedPreview(context, Theme.of(context), companyLeads),
                ),
              if (companyLeads.isNotEmpty) const SizedBox(height: AppSpacing.md),
            ],

            // General Notes Section
            if (showNotes && !showCompleted) ...[
              if (generalNotes.isNotEmpty)
                _buildReorderableSection(
                  context,
                  title: context.tr('section_general_notes'),
                  subtitle: _buildCountSubtitle(context, generalNotes.length),
                  notes: generalNotes,
                  icon: Icons.note,
                  color: Colors.teal,
                  isExpanded: _generalNotesExpanded,
                  onExpandChanged: (value) {
                    setState(() => _generalNotesExpanded = value);
                    _saveExpandedState(_prefKeyGeneralNotesExpanded, value);
                  },
                  onReorder: (oldIndex, newIndex) => _handleReorder(
                    context,
                    generalNotes,
                    oldIndex,
                    newIndex,
                  ),
                  showArchiveAction: true,
                ),
              if (generalNotes.isNotEmpty) const SizedBox(height: AppSpacing.md),
            ],

            // Interview Cheat Sheets Section
            if (showCheatSheets && !showCompleted) ...[
              if (interviewCheatSheets.isNotEmpty)
                _buildReorderableSection(
                  context,
                  title: context.tr('section_cheat_sheets'),
                  subtitle: _buildCountSubtitle(context, interviewCheatSheets.length),
                  notes: interviewCheatSheets,
                  icon: Icons.assignment,
                  color: Colors.indigo,
                  isExpanded: _cheatSheetsExpanded,
                  onExpandChanged: (value) {
                    setState(() => _cheatSheetsExpanded = value);
                    _saveExpandedState(_prefKeyCheatSheetsExpanded, value);
                  },
                  onReorder: (oldIndex, newIndex) => _handleReorder(
                    context,
                    interviewCheatSheets,
                    oldIndex,
                    newIndex,
                  ),
                  showArchiveAction: true,
                  collapsedPreview: _buildCheatSheetsCollapsedPreview(context, Theme.of(context), interviewCheatSheets),
                ),
              if (interviewCheatSheets.isNotEmpty) const SizedBox(height: AppSpacing.md),
            ],

            // Completed Section
            if (showCompleted) ...[
              if (completedTodos.isNotEmpty)
                _buildReorderableSection(
                  context,
                  title: context.tr('section_completed_todos'),
                  subtitle: _buildCountSubtitle(context, completedTodos.length),
                  notes: completedTodos,
                  icon: Icons.check_circle,
                  color: Colors.green,
                  isExpanded: _todosExpanded,
                  onExpandChanged: (value) {
                    setState(() => _todosExpanded = value);
                    _saveExpandedState(_prefKeyTodosExpanded, value);
                  },
                  onReorder: (oldIndex, newIndex) => _handleReorder(
                    context,
                    completedTodos,
                    oldIndex,
                    newIndex,
                  ),
                  showArchiveAction: true,
                ),
              if (completedTodos.isNotEmpty) const SizedBox(height: AppSpacing.md),
              if (completedReminders.isNotEmpty)
                _buildReorderableSection(
                  context,
                  title: context.tr('section_completed_reminders'),
                  subtitle: _buildCountSubtitle(context, completedReminders.length),
                  notes: completedReminders,
                  icon: Icons.check_circle,
                  color: Colors.green,
                  isExpanded: _remindersExpanded,
                  onExpandChanged: (value) {
                    setState(() => _remindersExpanded = value);
                    _saveExpandedState(_prefKeyRemindersExpanded, value);
                  },
                  onReorder: (oldIndex, newIndex) => _handleReorder(
                    context,
                    completedReminders,
                    oldIndex,
                    newIndex,
                  ),
                  showArchiveAction: true,
                ),
            ],

            // Archived Section
            if (showArchived) ...[
              if (archivedNotes.isNotEmpty)
                _buildReorderableSection(
                  context,
                  title: context.tr('section_archived'),
                  subtitle: _buildCountSubtitle(context, archivedNotes.length),
                  notes: archivedNotes,
                  icon: Icons.archive,
                  color: Colors.grey,
                  isExpanded: _archivedExpanded,
                  onExpandChanged: (value) {
                    setState(() => _archivedExpanded = value);
                    _saveExpandedState(_prefKeyArchivedExpanded, value);
                  },
                  onReorder: (oldIndex, newIndex) => _handleReorder(
                    context,
                    archivedNotes,
                    oldIndex,
                    newIndex,
                  ),
                  showUnarchiveAction: true,
                ),
              if (archivedNotes.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
                  child: UIUtils.buildEmptyState(
                    context,
                    icon: Icons.archive_outlined,
                    title: context.tr('no_archived_notes_title'),
                    message: context.tr('no_archived_notes'),
                  ),
                ),
            ],

            // Empty state
            if (!showCompleted && !showArchived &&
                activeTodos.isEmpty &&
                completedTodos.isEmpty &&
                activeReminders.isEmpty &&
                completedReminders.isEmpty &&
                companyLeads.isEmpty &&
                generalNotes.isEmpty &&
                interviewCheatSheets.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
                child: UIUtils.buildEmptyState(
                  context,
                  icon: hasSearchResults ? Icons.search_off : Icons.note_add_outlined,
                  title: hasSearchResults
                      ? context.tr('no_search_results_title')
                      : context.tr('no_notes_title'),
                  message: hasSearchResults
                      ? context.tr('no_search_results_message')
                      : context.tr('no_notes_message'),
                  action: AppCardActionButton(
                    label: hasSearchResults
                        ? context.tr('clear_search')
                        : context.tr('add'),
                    onPressed: () {
                      if (hasSearchResults) {
                        _searchController.clear();
                        context.read<NotesProvider>().setSearchQuery('');
                      } else {
                        _showNoteEditor(context);
                      }
                    },
                    icon: hasSearchResults ? Icons.clear : Icons.add,
                    isFilled: true,
                  ),
                ),
              ),

            // Completed empty state
            if (showCompleted && completedTodos.isEmpty && completedReminders.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
                child: UIUtils.buildEmptyState(
                  context,
                  icon: Icons.check_circle_outline,
                  title: context.tr('no_completed_notes_title'),
                  message: context.tr('no_completed_notes_message'),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ── Upcoming Events Timeline ──────────────────────────────────────────

  Widget _buildUpcomingTimeline(
    BuildContext context,
    ThemeData theme,
    NotesProvider notesProvider,
  ) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // Collect all notes with dates (not archived)
    final allNotes = [
      ...notesProvider.activeTodos,
      ...notesProvider.completedTodos,
      ...notesProvider.activeReminders,
      ...notesProvider.completedReminders,
      ...notesProvider.companyLeads,
      ...notesProvider.generalNotes,
      ...notesProvider.interviewCheatSheets,
    ];

    // Extract events: (date, note) pairs for notes with upcoming or today dates
    final events = <_TimelineEvent>[];
    for (final note in allNotes) {
      DateTime? date;
      if (note.type == NoteType.interviewCheatSheet && note.interviewDate != null) {
        date = note.interviewDate!;
      } else if (note.dueDate != null) {
        date = note.dueDate!;
      }
      if (date == null) continue;

      final dateOnly = DateTime(date.year, date.month, date.day);
      // Include today and future, plus up to 7 days past (for recent context)
      if (dateOnly.difference(today).inDays >= -7) {
        events.add(_TimelineEvent(date: dateOnly, note: note));
      }
    }

    if (events.isEmpty) return const SizedBox.shrink();

    // Sort by date, then by title
    events.sort((a, b) {
      final cmp = a.date.compareTo(b.date);
      return cmp != 0 ? cmp : a.note.title.compareTo(b.note.title);
    });

    // Split into overdue/today and upcoming
    final overdueAndToday = events.where((e) => e.date.compareTo(today) <= 0).toList();
    final upcoming = events.where((e) => e.date.isAfter(today)).take(8).toList();
    final displayEvents = [...overdueAndToday, ...upcoming];

    if (displayEvents.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.md),
      child: AppCardContainer(
        padding: EdgeInsets.zero,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Tappable header
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  setState(() => _timelineExpanded = !_timelineExpanded);
                  _saveExpandedState(_prefKeyTimelineExpanded, _timelineExpanded);
                },
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(AppDimensions.cardBorderRadius),
                  topRight: Radius.circular(AppDimensions.cardBorderRadius),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Row(
                    children: [
                      Icon(Icons.timeline, size: 18, color: theme.colorScheme.primary),
                      const SizedBox(width: 8),
                      Text(
                        context.tr('upcoming_timeline_title'),
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${displayEvents.length}',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.5),
                        ),
                      ),
                      const Spacer(),
                      Icon(
                        _timelineExpanded ? Icons.expand_less : Icons.expand_more,
                        size: 20,
                        color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.5),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Collapsed: horizontal scrollable chips
            if (!_timelineExpanded)
              _buildTimelineCollapsed(context, theme, displayEvents, today),

            // Expanded: vertical timeline
            if (_timelineExpanded) ...[
              ...displayEvents.asMap().entries.map((entry) {
                final index = entry.key;
                final event = entry.value;
                final isLast = index == displayEvents.length - 1;
                return _buildTimelineEntry(context, theme, event, today, isLast);
              }),
              const SizedBox(height: AppSpacing.xs),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTimelineCollapsed(
    BuildContext context,
    ThemeData theme,
    List<_TimelineEvent> events,
    DateTime today,
  ) {
    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(AppSpacing.md, 0, AppSpacing.md, AppSpacing.sm),
        itemCount: events.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final event = events[index];
          final note = event.note;
          final noteColor = _noteTypeColor(note.type);
          final noteIcon = _noteTypeIcon(note.type);
          final diff = event.date.difference(today).inDays;
          final isPast = diff < 0;

          final String dateLabel;
          if (diff < 0) {
            dateLabel = diff == -1
                ? context.tr('timeline_yesterday')
                : context.tr('timeline_days_ago', {'count': '${-diff}'});
          } else if (diff == 0) {
            dateLabel = context.tr('timeline_today');
          } else if (diff == 1) {
            dateLabel = context.tr('timeline_tomorrow');
          } else if (diff < 7) {
            dateLabel = DateFormat('EEE').format(event.date);
          } else {
            dateLabel = DateFormat('MMM dd').format(event.date);
          }

          return InkWell(
            onTap: () => _showNoteEditor(context, note: note),
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: noteColor.withValues(alpha: isPast ? 0.05 : 0.08),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: noteColor.withValues(alpha: isPast ? 0.15 : 0.25),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(noteIcon, size: 14, color: noteColor.withValues(alpha: isPast ? 0.4 : 0.8)),
                  const SizedBox(width: 6),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 100),
                    child: Text(
                      note.title,
                      style: theme.textTheme.labelSmall?.copyWith(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: isPast
                            ? theme.textTheme.bodySmall?.color?.withValues(alpha: 0.4)
                            : theme.textTheme.bodySmall?.color,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    dateLabel,
                    style: theme.textTheme.labelSmall?.copyWith(
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
                      color: diff == 0 ? Colors.orange : noteColor.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTimelineEntry(
    BuildContext context,
    ThemeData theme,
    _TimelineEvent event,
    DateTime today,
    bool isLast,
  ) {
    final note = event.note;
    final noteColor = _noteTypeColor(note.type);
    final noteIcon = _noteTypeIcon(note.type);
    final diff = event.date.difference(today).inDays;

    // Date label
    final String dateLabel;
    final Color dateColor;
    if (diff < 0) {
      dateLabel = diff == -1
          ? context.tr('timeline_yesterday')
          : context.tr('timeline_days_ago', {'count': '${-diff}'});
      dateColor = AppColors.statusRejected;
    } else if (diff == 0) {
      dateLabel = context.tr('timeline_today');
      dateColor = Colors.orange;
    } else if (diff == 1) {
      dateLabel = context.tr('timeline_tomorrow');
      dateColor = Colors.orange;
    } else if (diff < 7) {
      dateLabel = DateFormat('EEEE').format(event.date); // Day name
      dateColor = noteColor;
    } else {
      dateLabel = DateFormat('MMM dd').format(event.date);
      dateColor = noteColor;
    }

    final isPast = diff < 0;
    final isToday = diff == 0;

    return InkWell(
      onTap: () => _showNoteEditor(context, note: note),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Timeline rail
              SizedBox(
                width: 24,
                child: Column(
                  children: [
                    // Dot
                    Container(
                      width: isToday ? 14 : 10,
                      height: isToday ? 14 : 10,
                      decoration: BoxDecoration(
                        color: noteColor.withValues(alpha: isPast ? 0.4 : 1.0),
                        shape: BoxShape.circle,
                        border: isToday
                            ? Border.all(color: Colors.orange, width: 2)
                            : null,
                      ),
                    ),
                    // Line
                    if (!isLast)
                      Expanded(
                        child: Container(
                          width: 2,
                          color: theme.dividerColor.withValues(alpha: 0.3),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              // Content
              Expanded(
                child: Container(
                  margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: AppSpacing.xs,
                  ),
                  decoration: BoxDecoration(
                    color: noteColor.withValues(alpha: isPast ? 0.03 : 0.06),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: noteColor.withValues(alpha: isPast ? 0.1 : 0.2),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(noteIcon, size: 16, color: noteColor.withValues(alpha: isPast ? 0.4 : 0.8)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              note.title,
                              style: theme.textTheme.bodySmall?.copyWith(
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                                color: isPast
                                    ? theme.textTheme.bodySmall?.color?.withValues(alpha: 0.5)
                                    : null,
                                decoration: note.completed ? TextDecoration.lineThrough : null,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: dateColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          dateLabel,
                          style: theme.textTheme.labelSmall?.copyWith(
                            fontSize: 9,
                            fontWeight: FontWeight.w600,
                            color: dateColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _noteTypeColor(NoteType type) {
    switch (type) {
      case NoteType.todo:
        return AppColors.statusApplied;
      case NoteType.companyLead:
        return Colors.purple;
      case NoteType.generalNote:
        return Colors.teal;
      case NoteType.reminder:
        return Colors.pink;
      case NoteType.interviewCheatSheet:
        return Colors.indigo;
    }
  }

  IconData _noteTypeIcon(NoteType type) {
    switch (type) {
      case NoteType.todo:
        return Icons.check_circle_outline;
      case NoteType.companyLead:
        return Icons.business;
      case NoteType.generalNote:
        return Icons.note;
      case NoteType.reminder:
        return Icons.alarm;
      case NoteType.interviewCheatSheet:
        return Icons.assignment;
    }
  }

  Widget _buildCategoryFilters(
    ThemeData theme,
    int todosCount,
    int remindersCount,
    int leadsCount,
    int notesCount,
    int cheatSheetsCount,
    int completedCount,
    int archivedCount,
  ) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _buildCategoryChip(
            theme,
            label: context.tr('all_filter'),
            isSelected: _selectedCategory == 'all',
            onTap: () => setState(() => _selectedCategory = 'all'),
          ),
          const SizedBox(width: 8),
          _buildCategoryChip(
            theme,
            label: context.tr('note_type_todo'),
            count: todosCount,
            isSelected: _selectedCategory == 'todos',
            onTap: () => setState(() => _selectedCategory = 'todos'),
          ),
          const SizedBox(width: 8),
          _buildCategoryChip(
            theme,
            label: context.tr('note_type_reminder'),
            count: remindersCount,
            isSelected: _selectedCategory == 'reminders',
            onTap: () => setState(() => _selectedCategory = 'reminders'),
          ),
          const SizedBox(width: 8),
          _buildCategoryChip(
            theme,
            label: context.tr('category_leads'),
            count: leadsCount,
            isSelected: _selectedCategory == 'leads',
            onTap: () => setState(() => _selectedCategory = 'leads'),
          ),
          const SizedBox(width: 8),
          _buildCategoryChip(
            theme,
            label: context.tr('category_notes'),
            count: notesCount,
            isSelected: _selectedCategory == 'notes',
            onTap: () => setState(() => _selectedCategory = 'notes'),
          ),
          const SizedBox(width: 8),
          _buildCategoryChip(
            theme,
            label: context.tr('category_cheatsheets'),
            count: cheatSheetsCount,
            isSelected: _selectedCategory == 'cheatsheets',
            onTap: () => setState(() => _selectedCategory = 'cheatsheets'),
          ),
          const SizedBox(width: 8),
          _buildCategoryChip(
            theme,
            label: context.tr('completed_filter'),
            count: completedCount,
            isSelected: _selectedCategory == 'completed',
            onTap: () => setState(() => _selectedCategory = 'completed'),
          ),
          const SizedBox(width: 8),
          _buildCategoryChip(
            theme,
            label: context.tr('archive_filter'),
            count: archivedCount,
            isSelected: _selectedCategory == 'archived',
            onTap: () => setState(() => _selectedCategory = 'archived'),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryChip(
    ThemeData theme, {
    required String label,
    int? count,
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
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: theme.textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: isSelected
                    ? theme.colorScheme.onPrimary
                    : theme.textTheme.bodySmall?.color?.withOpacity(0.7),
              ),
            ),
            if (count != null && count > 0) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                decoration: BoxDecoration(
                  color: isSelected
                      ? theme.colorScheme.onPrimary.withOpacity(0.2)
                      : theme.colorScheme.primary.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$count',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: isSelected
                        ? theme.colorScheme.onPrimary
                        : theme.colorScheme.primary,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _buildCountSubtitle(BuildContext context, int count) {
    return count == 1
        ? context.tr('items_count', {'count': '$count'})
        : context.tr('items_count_plural', {'count': '$count'});
  }

  Widget _buildCombinedTasksSection(
    BuildContext context, {
    required String title,
    required IconData icon,
    required Color color,
    required List<NoteItem> activeTasks,
    required List<NoteItem> completedTasks,
    required bool isExpanded,
    required ValueChanged<bool> onExpandChanged,
  }) {
    final theme = Theme.of(context);
    final allTasks = [...activeTasks, ...completedTasks];
    final activeCount = activeTasks.length;

    return AppCardContainer(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Header
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
                        color: color.withValues(alpha: 0.1),
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
                      '${activeTasks.length} ${context.tr('active_filter').toLowerCase()} · ${completedTasks.length} ${context.tr('section_completed').toLowerCase()}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.6),
                      ),
                    ),
                    const Spacer(),
                    Icon(
                      isExpanded ? Icons.expand_less : Icons.expand_more,
                      size: 24,
                      color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.6),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Collapsed preview
          if (!isExpanded && allTasks.isNotEmpty)
            _buildTasksCollapsedPreview(context, theme, activeTasks, color),

          // Reorderable combined list
          if (isExpanded)
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: ReorderableListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                buildDefaultDragHandles: false,
                itemCount: allTasks.length,
                onReorder: (oldIndex, newIndex) {
                  // Handle cross-completion dragging
                  _handleTaskReorderWithCompletion(
                    context,
                    allTasks,
                    activeCount,
                    oldIndex,
                    newIndex,
                  );
                },
                proxyDecorator: _proxyDecorator,
                itemBuilder: (context, index) {
                  final note = allTasks[index];
                  final isLastActive = index == activeCount - 1;
                  final isFirstCompleted = index == activeCount;

                  return Column(
                    key: ValueKey(note.id),
                    children: [
                      // Visual divider between active and completed
                      if (isFirstCompleted && completedTasks.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                          child: Row(
                            children: [
                              Expanded(child: Divider(color: theme.colorScheme.outline.withOpacity(0.3))),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                                child: Text(
                                  context.tr('section_completed'),
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: theme.textTheme.bodySmall?.color?.withOpacity(0.5),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              Expanded(child: Divider(color: theme.colorScheme.outline.withOpacity(0.3))),
                            ],
                          ),
                        ),
                      // Note card
                      ReorderableDragStartListener(
                        index: index,
                        child: Container(
                          margin: EdgeInsets.only(
                            bottom: index < allTasks.length - 1 ? AppSpacing.md : 0,
                          ),
                          child: NoteCard(
                            note: note,
                            onToggleComplete: () => _toggleCompletion(context, note),
                            onEdit: () => _showNoteEditor(context, note: note),
                            onDelete: () => _confirmDelete(context, note),
                            onArchive: () => _archiveNote(context, note),
                            onExport: () => _exportSingleNote(context, note),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTasksCollapsedPreview(
    BuildContext context,
    ThemeData theme,
    List<NoteItem> activeTasks,
    Color color,
  ) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // Get tasks with due dates
    final tasksWithDates = activeTasks.where((note) => note.dueDate != null).toList()
      ..sort((a, b) => a.dueDate!.compareTo(b.dueDate!));

    // Count overdue and upcoming
    int overdueCount = 0;
    int todayCount = 0;
    int upcomingCount = 0;
    DateTime? nextDueDate;

    for (final task in tasksWithDates) {
      final dueDay = DateTime(task.dueDate!.year, task.dueDate!.month, task.dueDate!.day);
      final diff = dueDay.difference(today).inDays;

      if (diff < 0) {
        overdueCount++;
      } else if (diff == 0) {
        todayCount++;
      } else {
        upcomingCount++;
        nextDueDate ??= task.dueDate;
      }
    }

    if (tasksWithDates.isEmpty) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(AppSpacing.md, 0, AppSpacing.md, AppSpacing.md),
        child: Text(
          context.tr('no_due_dates'),
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.5),
            fontStyle: FontStyle.italic,
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.md, 0, AppSpacing.md, AppSpacing.md),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          if (overdueCount > 0)
            _buildPreviewChip(
              context,
              theme,
              Icons.warning_amber_rounded,
              '$overdueCount ${overdueCount == 1 ? context.tr('overdue') : context.tr('overdue_plural')}',
              AppColors.statusRejected,
            ),
          if (todayCount > 0)
            _buildPreviewChip(
              context,
              theme,
              Icons.today,
              '$todayCount ${context.tr('due_today')}',
              Colors.orange,
            ),
          if (upcomingCount > 0 && nextDueDate != null)
            _buildPreviewChip(
              context,
              theme,
              Icons.calendar_today,
              '${DateFormat('MMM dd').format(nextDueDate)} · $upcomingCount ${context.tr('upcoming')}',
              color,
            ),
        ],
      ),
    );
  }

  Widget _buildPreviewChip(
    BuildContext context,
    ThemeData theme,
    IconData icon,
    String label,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLeadsCollapsedPreview(
    BuildContext context,
    ThemeData theme,
    List<NoteItem> leads,
  ) {
    // Count leads by status
    final statusCounts = <LeadStatus, int>{};
    for (final lead in leads) {
      if (lead.leadStatus != null) {
        statusCounts[lead.leadStatus!] = (statusCounts[lead.leadStatus!] ?? 0) + 1;
      }
    }

    if (statusCounts.isEmpty) {
      return const SizedBox.shrink();
    }

    final statusColors = {
      LeadStatus.researching: Colors.blue,
      LeadStatus.contacted: Colors.orange,
      LeadStatus.applied: Colors.purple,
      LeadStatus.interviewing: AppColors.statusApplied,
    };

    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.md, 0, AppSpacing.md, AppSpacing.md),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: statusCounts.entries.map((entry) {
          final status = entry.key;
          final count = entry.value;
          final color = statusColors[status]!;

          return _buildPreviewChip(
            context,
            theme,
            status.icon,
            '$count ${context.tr(status.localizationKey)}',
            color,
          );
        }).toList(),
      ),
    );
  }

  Widget _buildCheatSheetsCollapsedPreview(
    BuildContext context,
    ThemeData theme,
    List<NoteItem> sheets,
  ) {
    const color = Colors.indigo;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final withDates = sheets.where((s) => s.interviewDate != null).toList();
    final overdueCount = withDates.where((s) {
      final d = DateTime(s.interviewDate!.year, s.interviewDate!.month, s.interviewDate!.day);
      return d.isBefore(today);
    }).length;
    final todayCount = withDates.where((s) {
      final d = DateTime(s.interviewDate!.year, s.interviewDate!.month, s.interviewDate!.day);
      return d.isAtSameMomentAs(today);
    }).length;
    final upcoming = withDates.where((s) {
      final d = DateTime(s.interviewDate!.year, s.interviewDate!.month, s.interviewDate!.day);
      return d.isAfter(today);
    }).toList()
      ..sort((a, b) => a.interviewDate!.compareTo(b.interviewDate!));

    final chips = <Widget>[];

    if (todayCount > 0) {
      chips.add(_buildPreviewChip(
        context, theme, Icons.today,
        '$todayCount ${context.tr('note_cheatsheet_interview_today')}',
        Colors.orange,
      ));
    }
    if (overdueCount > 0) {
      chips.add(_buildPreviewChip(
        context, theme, Icons.event_busy,
        '$overdueCount ${context.tr('note_cheatsheet_interview_passed')}',
        AppColors.statusRejected,
      ));
    }
    if (upcoming.isNotEmpty) {
      final next = upcoming.first.interviewDate!;
      final diff = DateTime(next.year, next.month, next.day).difference(today).inDays;
      chips.add(_buildPreviewChip(
        context, theme, Icons.event,
        '${DateFormat('MMM dd').format(next)} · ${context.tr('note_cheatsheet_interview_in_days', {'count': '$diff'})}',
        color,
      ));
    }

    // Sections fill rate across all sheets
    final totalSections = sheets.length * 5;
    var filledSections = 0;
    for (final s in sheets) {
      if (s.companyBackground != null && s.companyBackground!.isNotEmpty) filledSections++;
      if (s.whyGoodFit != null && s.whyGoodFit!.isNotEmpty) filledSections++;
      if (s.strengths != null && s.strengths!.isNotEmpty) filledSections++;
      if (s.questionsToAsk != null && s.questionsToAsk!.isNotEmpty) filledSections++;
      if (s.researchNotes != null && s.researchNotes!.isNotEmpty) filledSections++;
    }
    if (totalSections > 0) {
      chips.add(_buildPreviewChip(
        context, theme, Icons.checklist,
        '$filledSections / $totalSections ${context.tr('note_cheatsheet_sections_filled')}',
        color,
      ));
    }

    if (chips.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.md, 0, AppSpacing.md, AppSpacing.md),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: chips,
      ),
    );
  }

  Future<void> _handleTaskReorderWithCompletion(
    BuildContext context,
    List<NoteItem> allTasks,
    int activeCount,
    int oldIndex,
    int newIndex,
  ) async {
    try {
      // Adjust newIndex if dragging down
      if (oldIndex < newIndex) {
        newIndex -= 1;
      }

      final movedNote = allTasks[oldIndex];
      final wasActive = oldIndex < activeCount;
      final nowActive = newIndex < activeCount;

      // If dragging across the completion boundary, just toggle completion
      // The provider will handle moving it to the correct list
      if (wasActive != nowActive) {
        await context.read<NotesProvider>().toggleCompletion(movedNote.id);
        return; // Don't reorder - completion toggle handles the move
      }

      // Reorder within the same section
      final activeTasks = context.read<NotesProvider>().activeTasks;
      final completedTasks = context.read<NotesProvider>().completedTasks;

      if (wasActive) {
        // Reordering within active tasks
        await _handleReorder(context, activeTasks, oldIndex, newIndex);
      } else {
        // Reordering within completed tasks
        await _handleReorder(context, completedTasks,
          oldIndex - activeCount,
          newIndex - activeCount,
        );
      }
    } catch (e) {
      if (mounted) {
        UIUtils.showError(context, context.tr('failed_reorder_notes', {'error': e.toString()}));
      }
    }
  }

  Widget _buildReorderableSection(
    BuildContext context, {
    required String title,
    required String subtitle,
    required List<NoteItem> notes,
    required IconData icon,
    required Color color,
    required bool isExpanded,
    required ValueChanged<bool> onExpandChanged,
    required void Function(int, int) onReorder,
    bool showArchiveAction = false,
    bool showUnarchiveAction = false,
    Widget? collapsedPreview,
  }) {
    final theme = Theme.of(context);

    return AppCardContainer(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Header
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
                        color: theme.textTheme.bodySmall?.color?.withOpacity(0.6),
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

          // Collapsed preview
          if (!isExpanded && collapsedPreview != null) collapsedPreview,

          // Reorderable List
          if (isExpanded)
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: ReorderableListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                buildDefaultDragHandles: false,
                itemCount: notes.length,
                onReorder: onReorder,
                proxyDecorator: _proxyDecorator,
                itemBuilder: (context, index) {
                  final note = notes[index];
                  return ReorderableDragStartListener(
                    key: ValueKey(note.id),
                    index: index,
                    child: Container(
                      margin: EdgeInsets.only(
                        bottom: index < notes.length - 1 ? AppSpacing.md : 0,
                      ),
                      child: NoteCard(
                        note: note,
                        onToggleComplete: (note.type == NoteType.todo || note.type == NoteType.reminder)
                            ? () => _toggleCompletion(context, note)
                            : null,
                        onEdit: () => _showNoteEditor(context, note: note),
                        onDelete: () => _confirmDelete(context, note),
                        onArchive: showArchiveAction ? () => _archiveNote(context, note) : null,
                        onUnarchive: showUnarchiveAction ? () => _unarchiveNote(context, note) : null,
                        onCreateApplication: note.type == NoteType.companyLead
                            ? () => _createApplicationFromLead(context, note)
                            : null,
                        onExport: () => _exportSingleNote(context, note),
                        onUpdateLeadStatus: note.type == NoteType.companyLead
                            ? (status) => _updateLeadStatus(context, note, status)
                            : null,
                      ),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _proxyDecorator(Widget child, int index, Animation<double> animation) {
    return AnimatedBuilder(
      animation: animation,
      builder: (BuildContext context, Widget? child) {
        return Material(
          elevation: 6.0,
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          child: child,
        );
      },
      child: child,
    );
  }

  Future<void> _handleReorder(
    BuildContext context,
    List<NoteItem> categoryNotes,
    int oldIndex,
    int newIndex,
  ) async {
    try {
      await context.read<NotesProvider>().reorderNotes(
            categoryNotes,
            oldIndex,
            newIndex,
          );
    } catch (e) {
      if (mounted) {
        UIUtils.showError(context, context.tr('failed_reorder_notes', {'error': e.toString()}));
      }
    }
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
            note == null ? context.tr('note_created') : context.tr('note_updated'),
          );
        }
      } catch (e) {
        if (mounted) {
          UIUtils.showError(context, context.tr('failed_save_note', {'error': e.toString()}));
        }
      }
    }
  }

  Future<void> _toggleCompletion(BuildContext context, NoteItem note) async {
    try {
      await context.read<NotesProvider>().toggleCompletion(note.id);
    } catch (e) {
      if (mounted) {
        UIUtils.showError(context, context.tr('failed_update_note', {'error': e.toString()}));
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
          UIUtils.showError(context, context.tr('failed_delete_note', {'error': e.toString()}));
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
        UIUtils.showError(context, context.tr('failed_archive_note', {'error': e.toString()}));
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
        UIUtils.showError(context, context.tr('failed_unarchive_note', {'error': e.toString()}));
      }
    }
  }

  Future<void> _updateLeadStatus(
    BuildContext context,
    NoteItem note,
    LeadStatus status,
  ) async {
    try {
      await context.read<NotesProvider>().updateLeadStatus(note.id, status);
      if (mounted) {
        UIUtils.showSuccess(context, context.tr('lead_status_updated'));
      }
    } catch (e) {
      if (mounted) {
        UIUtils.showError(context, context.tr('failed_update_lead_status', {'error': e.toString()}));
      }
    }
  }

  Future<void> _createApplicationFromLead(BuildContext context, NoteItem note) async {
    final result = await showDialog(
      context: context,
      builder: (context) => ApplicationEditorDialog(
        prefillCompany: note.title,
        prefillLocation: note.location,
        prefillJobUrl: note.url,
        prefillContactPerson: note.contactPerson,
        prefillContactEmail: note.contactEmail,
        prefillNotes: note.description,
      ),
    );

    if (result != null && mounted) {
      UIUtils.showSuccess(context, context.tr('note_create_application_success'));

      final shouldArchive = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(context.tr('note_archive_after_convert')),
          content: Text(context.tr('note_archive_after_convert_message', {'company': note.title})),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(context.tr('no')),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(context.tr('archive')),
            ),
          ],
        ),
      );

      if (shouldArchive == true && mounted) {
        await context.read<NotesProvider>().archiveNote(note.id);
      }
    }
  }

  Future<void> _exportSingleNote(BuildContext context, NoteItem note) async {
    try {
      final isGerman = context.loc.currentLanguageCode == 'de';

      // Resolve linked application name for cheat sheets
      String? linkedAppName;
      if (note.type == NoteType.interviewCheatSheet &&
          note.linkedApplicationId != null) {
        final apps = context.read<ApplicationsProvider>().allApplications;
        final app = apps.where((a) => a.id == note.linkedApplicationId).firstOrNull;
        if (app != null) {
          linkedAppName = '${app.company} — ${app.position}';
        }
      }

      final markdown = NoteExportService.generateMarkdown(
        note: note,
        isGerman: isGerman,
        linkedApplicationName: linkedAppName,
      );

      final result = await FilePicker.platform.getDirectoryPath(
        dialogTitle: context.tr('select_folder_save'),
      );

      if (result == null) return;

      final dateStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
      final safeName = note.title
          .replaceAll(RegExp(r'[<>:"/\\|?*]'), '_')
          .replaceAll(RegExp(r'\s+'), '_');
      final langSuffix = isGerman ? 'DE' : 'EN';
      final file = File('$result${Platform.pathSeparator}${safeName}_${langSuffix}_$dateStr.md');

      await file.writeAsString(markdown, encoding: utf8);

      if (mounted) {
        UIUtils.showSuccess(context, context.tr('note_export_success'));
      }
    } catch (e) {
      if (mounted) {
        UIUtils.showError(context, context.tr('note_export_failed', {'error': e.toString()}));
      }
    }
  }

  void _exportNotes(BuildContext context, NotesProvider provider) {
    final notes = provider.notes;

    if (notes.isEmpty) {
      UIUtils.showError(context, context.tr('no_notes_to_export'));
      return;
    }

    showDialog(
      context: context,
      builder: (_) => _ExportNotesDialog(notes: notes),
    );
  }
}

// ── Timeline Event ────────────────────────────────────────────────────────

class _TimelineEvent {
  final DateTime date;
  final NoteItem note;
  const _TimelineEvent({required this.date, required this.note});
}

// ── Export Notes Dialog ─────────────────────────────────────────────────────

class _ExportNotesDialog extends StatefulWidget {
  final List<NoteItem> notes;
  const _ExportNotesDialog({required this.notes});

  @override
  State<_ExportNotesDialog> createState() => _ExportNotesDialogState();
}

class _ExportNotesDialogState extends State<_ExportNotesDialog> {
  late final Set<String> _selectedIds;
  bool _exportInGerman = false;
  String? _searchQuery;

  @override
  void initState() {
    super.initState();
    _selectedIds = widget.notes.map((n) => n.id).toSet();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _exportInGerman = context.loc.currentLanguageCode == 'de';
  }

  List<NoteItem> get _filteredNotes {
    if (_searchQuery == null || _searchQuery!.isEmpty) return widget.notes;
    final q = _searchQuery!.toLowerCase();
    return widget.notes.where((n) {
      return n.title.toLowerCase().contains(q) ||
          (n.description ?? '').toLowerCase().contains(q);
    }).toList();
  }

  bool get _allSelected =>
      _filteredNotes.every((n) => _selectedIds.contains(n.id));

  void _toggleAll() {
    setState(() {
      if (_allSelected) {
        for (final n in _filteredNotes) {
          _selectedIds.remove(n.id);
        }
      } else {
        for (final n in _filteredNotes) {
          _selectedIds.add(n.id);
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final filtered = _filteredNotes;

    return AlertDialog(
      title: Row(
        children: [
          const Icon(Icons.download, size: 22),
          const SizedBox(width: 10),
          Expanded(child: Text(context.tr('notes_export_title'))),
        ],
      ),
      content: SizedBox(
        width: 520,
        height: 480,
        child: Column(
          children: [
            // ── Search + language toggle row ──
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 38,
                    child: TextField(
                      onChanged: (v) => setState(() => _searchQuery = v),
                      style: theme.textTheme.bodySmall,
                      decoration: InputDecoration(
                        hintText: context.tr('search'),
                        prefixIcon: const Icon(Icons.search, size: 18),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 0),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        isDense: true,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Language toggle
                Container(
                  height: 38,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: theme.dividerColor),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildLangChip('EN', !_exportInGerman, theme),
                      _buildLangChip('DE', _exportInGerman, theme),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // ── Select all / count row ──
            Row(
              children: [
                SizedBox(
                  width: 20,
                  height: 20,
                  child: Checkbox(
                    value: _allSelected,
                    tristate: false,
                    onChanged: (_) => _toggleAll(),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                GestureDetector(
                  onTap: _toggleAll,
                  child: Text(
                    _allSelected
                        ? context.tr('notes_export_deselect_all')
                        : context.tr('notes_export_select_all'),
                    style: theme.textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  '${_selectedIds.length} / ${widget.notes.length}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.textTheme.bodySmall?.color
                        ?.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Divider(height: 1),

            // ── Notes list ──
            Expanded(
              child: filtered.isEmpty
                  ? Center(
                      child: Text(
                        context.tr('no_results'),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.textTheme.bodySmall?.color
                              ?.withValues(alpha: 0.5),
                        ),
                      ),
                    )
                  : ListView.builder(
                      itemCount: filtered.length,
                      itemBuilder: (context, index) {
                        final note = filtered[index];
                        final isSelected = _selectedIds.contains(note.id);
                        return _buildNoteRow(note, isSelected, theme);
                      },
                    ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(context.tr('cancel')),
        ),
        FilledButton.icon(
          onPressed: _selectedIds.isEmpty ? null : () => _doExport(context),
          icon: const Icon(Icons.download, size: 18),
          label: Text(
            context.tr('notes_export_button', {
              'count': '${_selectedIds.length}',
            }),
          ),
        ),
      ],
    );
  }

  Widget _buildLangChip(String label, bool active, ThemeData theme) {
    return GestureDetector(
      onTap: () => setState(() => _exportInGerman = label == 'DE'),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: active
              ? theme.colorScheme.primary.withValues(alpha: 0.15)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(7),
        ),
        child: Text(
          label,
          style: theme.textTheme.labelMedium?.copyWith(
            fontWeight: active ? FontWeight.w700 : FontWeight.w400,
            color: active
                ? theme.colorScheme.primary
                : theme.textTheme.bodySmall?.color?.withValues(alpha: 0.6),
          ),
        ),
      ),
    );
  }

  Widget _buildNoteRow(NoteItem note, bool isSelected, ThemeData theme) {
    final typeColor = _noteTypeColor(note.type);
    final typeIcon = _noteTypeIcon(note.type);

    return InkWell(
      onTap: () {
        setState(() {
          if (isSelected) {
            _selectedIds.remove(note.id);
          } else {
            _selectedIds.add(note.id);
          }
        });
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 2),
        child: Row(
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: Checkbox(
                value: isSelected,
                onChanged: (_) {
                  setState(() {
                    if (isSelected) {
                      _selectedIds.remove(note.id);
                    } else {
                      _selectedIds.add(note.id);
                    }
                  });
                },
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            const SizedBox(width: 10),
            // Type icon
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: typeColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(typeIcon, size: 14, color: typeColor),
            ),
            const SizedBox(width: 10),
            // Title + type label
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    note.title,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                      decoration:
                          note.completed ? TextDecoration.lineThrough : null,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    context.tr(note.type.localizationKey),
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontSize: 10,
                      color: typeColor,
                    ),
                  ),
                ],
              ),
            ),
            // Date
            Text(
              DateFormat('dd.MM.yy').format(note.createdAt),
              style: theme.textTheme.bodySmall?.copyWith(
                fontSize: 10,
                color:
                    theme.textTheme.bodySmall?.color?.withValues(alpha: 0.5),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _doExport(BuildContext context) async {
    final selected = widget.notes
        .where((n) => _selectedIds.contains(n.id))
        .toList();

    if (selected.isEmpty) return;

    Navigator.pop(context); // Close dialog

    try {
      final result = await FilePicker.platform.getDirectoryPath(
        dialogTitle: context.tr('select_folder_save'),
      );
      if (result == null) return;

      final apps = context.mounted
          ? context.read<ApplicationsProvider>().allApplications
          : <dynamic>[];
      final dateStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
      final langSuffix = _exportInGerman ? 'DE' : 'EN';

      for (final note in selected) {
        // Resolve linked app name for cheat sheets
        String? linkedAppName;
        if (note.type == NoteType.interviewCheatSheet &&
            note.linkedApplicationId != null) {
          final app = apps.where((a) => a.id == note.linkedApplicationId).firstOrNull;
          if (app != null) {
            linkedAppName = '${app.company} — ${app.position}';
          }
        }

        final markdown = NoteExportService.generateMarkdown(
          note: note,
          isGerman: _exportInGerman,
          linkedApplicationName: linkedAppName,
        );

        final safeName = note.title
            .replaceAll(RegExp(r'[<>:"/\\|?*]'), '_')
            .replaceAll(RegExp(r'\s+'), '_');
        final file = File(
            '$result${Platform.pathSeparator}${safeName}_${langSuffix}_$dateStr.md');
        await file.writeAsString(markdown, encoding: utf8);
      }

      if (context.mounted) {
        UIUtils.showSuccess(context, context.tr('notes_exported'));

        final shouldOpen = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Text(ctx.tr('notes_export_successful_title')),
            content: Text(ctx.tr('notes_export_done_message', {
              'count': '${selected.length}',
            })),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: Text(ctx.tr('no')),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: Text(ctx.tr('open_folder')),
              ),
            ],
          ),
        );

        if (shouldOpen == true) {
          await PlatformUtils.openFolder(result);
        }
      }
    } catch (e) {
      if (context.mounted) {
        UIUtils.showError(
            context, context.tr('note_export_failed', {'error': e.toString()}));
      }
    }
  }

  static Color _noteTypeColor(NoteType type) {
    switch (type) {
      case NoteType.todo:
        return AppColors.statusApplied;
      case NoteType.companyLead:
        return Colors.purple;
      case NoteType.generalNote:
        return Colors.teal;
      case NoteType.reminder:
        return Colors.pink;
      case NoteType.interviewCheatSheet:
        return Colors.indigo;
    }
  }

  static IconData _noteTypeIcon(NoteType type) {
    switch (type) {
      case NoteType.todo:
        return Icons.check_circle_outline;
      case NoteType.companyLead:
        return Icons.business;
      case NoteType.generalNote:
        return Icons.note;
      case NoteType.reminder:
        return Icons.alarm;
      case NoteType.interviewCheatSheet:
        return Icons.assignment;
    }
  }
}
