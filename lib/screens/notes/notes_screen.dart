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
import '../../widgets/app_card.dart';
import '../../widgets/note_card.dart';
import '../../utils/dialog_utils.dart';
import '../../services/preferences_service.dart';
import '../../services/notes_statistics_markdown_service.dart';
import '../../services/note_export_service.dart';
import '../../screens/applications/application_editor_dialog.dart';
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

  // Preference keys
  static const String _prefKeyTodosExpanded = 'notes_todos_expanded';
  static const String _prefKeyRemindersExpanded = 'notes_reminders_expanded';
  static const String _prefKeyCompanyLeadsExpanded = 'notes_company_leads_expanded';
  static const String _prefKeyGeneralNotesExpanded = 'notes_general_notes_expanded';

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

    // Get categorized notes
    final activeTodos = notesProvider.activeTodos;
    final completedTodos = notesProvider.completedTodos;
    final activeReminders = notesProvider.activeReminders;
    final completedReminders = notesProvider.completedReminders;
    final companyLeads = notesProvider.companyLeads;
    final generalNotes = notesProvider.generalNotes;

    // Calculate total counts for category filters
    final todosCount = activeTodos.length + completedTodos.length;
    final remindersCount = activeReminders.length + completedReminders.length;
    final leadsCount = companyLeads.length;
    final notesCount = generalNotes.length;
    final completedCount = completedTodos.length + completedReminders.length;

    // Apply category filter
    final showTodos = _selectedCategory == 'all' || _selectedCategory == 'todos';
    final showReminders = _selectedCategory == 'all' || _selectedCategory == 'reminders';
    final showLeads = _selectedCategory == 'all' || _selectedCategory == 'leads';
    final showNotes = _selectedCategory == 'all' || _selectedCategory == 'notes';
    final showCompleted = _selectedCategory == 'completed';

    // Count search results
    final searchQuery = notesProvider.searchQuery;
    final hasSearchResults = searchQuery.isNotEmpty;
    final totalResults = (showTodos ? activeTodos.length + completedTodos.length : 0) +
        (showReminders ? activeReminders.length + completedReminders.length : 0) +
        (showLeads ? companyLeads.length : 0) +
        (showNotes ? generalNotes.length : 0) +
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
            _buildCategoryFilters(theme, todosCount, remindersCount, leadsCount, notesCount, completedCount),
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

            // Empty state
            if (!showCompleted &&
                activeTodos.isEmpty &&
                completedTodos.isEmpty &&
                activeReminders.isEmpty &&
                completedReminders.isEmpty &&
                companyLeads.isEmpty &&
                generalNotes.isEmpty)
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

  Widget _buildCategoryFilters(
    ThemeData theme,
    int todosCount,
    int remindersCount,
    int leadsCount,
    int notesCount,
    int completedCount,
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
            label: context.tr('completed_filter'),
            count: completedCount,
            isSelected: _selectedCategory == 'completed',
            onTap: () => setState(() => _selectedCategory = 'completed'),
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
            Icons.circle,
            '${status.icon} $count ${context.tr(status.localizationKey)}',
            color,
          );
        }).toList(),
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
      final englishMarkdown = NoteExportService.generateEnglishMarkdown(note: note);
      final germanMarkdown = NoteExportService.generateGermanMarkdown(note: note);

      final result = await FilePicker.platform.getDirectoryPath(
        dialogTitle: context.tr('select_folder_save'),
      );

      if (result == null) return;

      final dateStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
      final safeName = note.title
          .replaceAll(RegExp(r'[<>:"/\\|?*]'), '_')
          .replaceAll(RegExp(r'\s+'), '_');
      final englishFile = File('$result${Platform.pathSeparator}${safeName}_EN_$dateStr.md');
      final germanFile = File('$result${Platform.pathSeparator}${safeName}_DE_$dateStr.md');

      await englishFile.writeAsString(englishMarkdown, encoding: utf8);
      await germanFile.writeAsString(germanMarkdown, encoding: utf8);

      if (mounted) {
        UIUtils.showSuccess(context, context.tr('note_export_success'));
      }
    } catch (e) {
      if (mounted) {
        UIUtils.showError(context, context.tr('note_export_failed', {'error': e.toString()}));
      }
    }
  }

  Future<void> _exportNotes(BuildContext context, NotesProvider provider) async {
    try {
      final notes = provider.notes;

      if (notes.isEmpty) {
        if (context.mounted) {
          UIUtils.showError(context, context.tr('no_notes_to_export'));
        }
        return;
      }

      if (context.mounted) {
        DialogUtils.showLoading(context, message: context.tr('generating_notes_report'));
      }

      final englishMarkdown = NotesStatisticsMarkdownService.generateEnglishMarkdown(notes: notes);
      final germanMarkdown = NotesStatisticsMarkdownService.generateGermanMarkdown(notes: notes);

      if (context.mounted) {
        Navigator.of(context).pop(); // Close loading
      }

      final result = await FilePicker.platform.getDirectoryPath(
        dialogTitle: context.tr('select_folder_save'),
      );

      if (result == null) return;

      final dateStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
      final englishFile = File('$result${Platform.pathSeparator}Notes_Report_EN_$dateStr.md');
      final germanFile = File('$result${Platform.pathSeparator}Notes_Report_DE_$dateStr.md');

      await englishFile.writeAsString(englishMarkdown, encoding: utf8);
      await germanFile.writeAsString(germanMarkdown, encoding: utf8);

      if (context.mounted) {
        UIUtils.showSuccess(context, context.tr('notes_exported'));

        final shouldOpen = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(context.tr('notes_export_successful_title')),
            content: Text(context.tr('notes_export_successful_message', {'date': dateStr})),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(context.tr('no')),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text(context.tr('open_folder')),
              ),
            ],
          ),
        );

        if (shouldOpen == true) {
          try {
            if (Platform.isWindows) {
              await Process.run('explorer', [result]);
            } else if (Platform.isMacOS) {
              await Process.run('open', [result]);
            } else if (Platform.isLinux) {
              await Process.run('xdg-open', [result]);
            }
          } catch (e) {
            debugPrint('Failed to open folder: $e');
          }
        }
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.of(context).pop();
        UIUtils.showError(context, context.tr('failed_export_notes', {'error': e.toString()}));
      }
    }
  }
}
