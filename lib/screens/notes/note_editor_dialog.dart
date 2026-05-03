import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/notes_data.dart';
import '../../models/job_application.dart';
import '../../providers/applications_provider.dart';
import '../../theme/app_theme.dart';
import '../../utils/ui_utils.dart';
import '../../localization/app_localizations.dart';

/// Dialog for creating or editing a note with type-specific fields
class NoteEditorDialog extends StatefulWidget {
  final NoteItem? note;

  const NoteEditorDialog({super.key, this.note});

  @override
  State<NoteEditorDialog> createState() => _NoteEditorDialogState();
}

class _NoteEditorDialogState extends State<NoteEditorDialog> {
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late TextEditingController _tagsController;
  late TextEditingController _urlController;
  late TextEditingController _contactPersonController;
  late TextEditingController _contactEmailController;
  late TextEditingController _locationController;
  late TextEditingController _salaryExpectationController;
  late TextEditingController _companyBackgroundController;
  late TextEditingController _whyGoodFitController;
  late TextEditingController _questionsToAskController;
  late TextEditingController _strengthsController;
  late TextEditingController _researchNotesController;

  late NoteType _selectedType;
  late NotePriority _selectedPriority;
  LeadStatus? _selectedLeadStatus;
  DateTime? _dueDate;
  DateTime? _interviewDate;
  String? _linkedApplicationId;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.note?.title ?? '');
    _descriptionController =
        TextEditingController(text: widget.note?.description ?? '');
    _tagsController = TextEditingController(
      text: widget.note?.tags.join(', ') ?? '',
    );
    _urlController = TextEditingController(text: widget.note?.url ?? '');
    _contactPersonController =
        TextEditingController(text: widget.note?.contactPerson ?? '');
    _contactEmailController =
        TextEditingController(text: widget.note?.contactEmail ?? '');
    _locationController =
        TextEditingController(text: widget.note?.location ?? '');
    _salaryExpectationController =
        TextEditingController(text: widget.note?.salaryExpectation ?? '');
    _companyBackgroundController =
        TextEditingController(text: widget.note?.companyBackground ?? '');
    _whyGoodFitController =
        TextEditingController(text: widget.note?.whyGoodFit ?? '');
    _questionsToAskController =
        TextEditingController(text: widget.note?.questionsToAsk ?? '');
    _strengthsController =
        TextEditingController(text: widget.note?.strengths ?? '');
    _researchNotesController =
        TextEditingController(text: widget.note?.researchNotes ?? '');
    _selectedType = widget.note?.type ?? NoteType.todo;
    _selectedPriority = widget.note?.priority ?? NotePriority.medium;
    _selectedLeadStatus = widget.note?.leadStatus;
    _dueDate = widget.note?.dueDate;
    _interviewDate = widget.note?.interviewDate;
    _linkedApplicationId = widget.note?.linkedApplicationId;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _tagsController.dispose();
    _urlController.dispose();
    _contactPersonController.dispose();
    _contactEmailController.dispose();
    _locationController.dispose();
    _salaryExpectationController.dispose();
    _companyBackgroundController.dispose();
    _whyGoodFitController.dispose();
    _questionsToAskController.dispose();
    _strengthsController.dispose();
    _researchNotesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isEdit = widget.note != null;

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimensions.cardBorderRadius),
      ),
      child: Container(
        width: 600,
        constraints: const BoxConstraints(maxHeight: 750),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            _buildHeader(theme, isEdit),

            // Form
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Type selector
                    Text(context.tr('note_select_type'),
                        style: theme.textTheme.labelLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        )),
                    const SizedBox(height: AppSpacing.sm),
                    _buildTypeSelector(theme),
                    const SizedBox(height: AppSpacing.lg),

                    // Type-specific fields
                    ..._buildTypeSpecificFields(theme),
                  ],
                ),
              ),
            ),

            // Actions
            _buildActions(theme, isEdit),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeData theme, bool isEdit) {
    final typeIcon = _getTypeIcon(_selectedType);
    final typeColor = _getTypeColor(_selectedType);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: typeColor.withValues(alpha:0.05),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(AppDimensions.cardBorderRadius),
          topRight: Radius.circular(AppDimensions.cardBorderRadius),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: typeColor.withValues(alpha:0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              isEdit ? Icons.edit_note : typeIcon,
              color: typeColor,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              isEdit
                  ? context.tr('edit_note_title')
                  : context.tr('create_note_title'),
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  Widget _buildTypeSelector(ThemeData theme) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: NoteType.values.map((type) {
        final isSelected = _selectedType == type;
        final color = _getTypeColor(type);
        return InkWell(
          onTap: () => setState(() => _selectedType = type),
          borderRadius: BorderRadius.circular(10),
          child: AnimatedContainer(
            duration: AppDurations.quick,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: isSelected
                  ? color.withValues(alpha:0.12)
                  : theme.colorScheme.surfaceContainerHighest
                      .withValues(alpha:0.4),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isSelected
                    ? color
                    : theme.colorScheme.outline.withValues(alpha:0.2),
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(_getTypeIcon(type), size: 16, color: isSelected ? color : theme.textTheme.bodySmall?.color?.withValues(alpha:0.6)),
                const SizedBox(width: 6),
                Text(
                  context.tr(type.localizationKey),
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    color: isSelected
                        ? color
                        : theme.textTheme.bodyMedium?.color?.withValues(alpha:0.8),
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  List<Widget> _buildTypeSpecificFields(ThemeData theme) {
    switch (_selectedType) {
      case NoteType.todo:
        return _buildTodoFields(theme);
      case NoteType.companyLead:
        return _buildCompanyLeadFields(theme);
      case NoteType.generalNote:
        return _buildGeneralNoteFields(theme);
      case NoteType.reminder:
        return _buildReminderFields(theme);
      case NoteType.interviewCheatSheet:
        return _buildInterviewCheatSheetFields(theme);
    }
  }

  // ── To-Do Fields ──────────────────────────────────────────────────────

  List<Widget> _buildTodoFields(ThemeData theme) {
    return [
      TextFormField(
        controller: _titleController,
        decoration: InputDecoration(
          labelText: context.tr('note_title_label'),
          hintText: context.tr('note_title_hint'),
          prefixIcon: const Icon(Icons.check_circle_outline),
        ),
        autofocus: widget.note == null,
      ),
      const SizedBox(height: AppSpacing.md),
      TextFormField(
        controller: _descriptionController,
        decoration: InputDecoration(
          labelText: context.tr('note_description_label'),
          hintText: context.tr('note_description_hint'),
          prefixIcon: const Icon(Icons.description_outlined),
          alignLabelWithHint: true,
        ),
        maxLines: 3,
      ),
      const SizedBox(height: AppSpacing.md),
      Row(
        children: [
          Expanded(child: _buildPriorityDropdown(theme)),
          const SizedBox(width: AppSpacing.md),
          Expanded(child: _buildDueDatePicker(theme)),
        ],
      ),
      const SizedBox(height: AppSpacing.md),
      _buildTagsField(),
    ];
  }

  // ── Company Lead Fields ───────────────────────────────────────────────

  List<Widget> _buildCompanyLeadFields(ThemeData theme) {
    return [
      TextFormField(
        controller: _titleController,
        decoration: InputDecoration(
          labelText: context.tr('note_company_name_label'),
          hintText: context.tr('note_company_name_hint'),
          prefixIcon: const Icon(Icons.business),
        ),
        autofocus: widget.note == null,
      ),
      const SizedBox(height: AppSpacing.md),
      TextFormField(
        controller: _descriptionController,
        decoration: InputDecoration(
          labelText: context.tr('note_why_interesting_label'),
          hintText: context.tr('note_why_interesting_hint'),
          prefixIcon: const Icon(Icons.lightbulb_outline),
          alignLabelWithHint: true,
        ),
        maxLines: 3,
      ),
      const SizedBox(height: AppSpacing.md),
      Row(
        children: [
          Expanded(
            child: TextFormField(
              controller: _urlController,
              decoration: InputDecoration(
                labelText: context.tr('note_website_label'),
                hintText: context.tr('note_website_hint'),
                prefixIcon: const Icon(Icons.link),
              ),
              keyboardType: TextInputType.url,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: TextFormField(
              controller: _locationController,
              decoration: InputDecoration(
                labelText: context.tr('note_location_label'),
                hintText: context.tr('note_location_hint'),
                prefixIcon: const Icon(Icons.location_on_outlined),
              ),
            ),
          ),
        ],
      ),
      const SizedBox(height: AppSpacing.md),
      Row(
        children: [
          Expanded(
            child: TextFormField(
              controller: _contactPersonController,
              decoration: InputDecoration(
                labelText: context.tr('note_contact_person_label'),
                hintText: context.tr('note_contact_person_hint'),
                prefixIcon: const Icon(Icons.person_outline),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: TextFormField(
              controller: _contactEmailController,
              decoration: InputDecoration(
                labelText: context.tr('note_contact_email_label'),
                hintText: context.tr('note_contact_email_hint'),
                prefixIcon: const Icon(Icons.email_outlined),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
          ),
        ],
      ),
      const SizedBox(height: AppSpacing.md),
      Row(
        children: [
          Expanded(child: _buildPriorityDropdown(theme)),
          const SizedBox(width: AppSpacing.md),
          Expanded(child: _buildLeadStatusDropdown(theme)),
        ],
      ),
      const SizedBox(height: AppSpacing.md),
      _buildTagsField(),
    ];
  }

  // ── General Note Fields ───────────────────────────────────────────────

  List<Widget> _buildGeneralNoteFields(ThemeData theme) {
    return [
      TextFormField(
        controller: _titleController,
        decoration: InputDecoration(
          labelText: context.tr('note_general_title_label'),
          hintText: context.tr('note_general_title_hint'),
          prefixIcon: const Icon(Icons.note_outlined),
        ),
        autofocus: widget.note == null,
      ),
      const SizedBox(height: AppSpacing.md),
      TextFormField(
        controller: _descriptionController,
        decoration: InputDecoration(
          labelText: context.tr('note_general_body_label'),
          hintText: context.tr('note_general_body_hint'),
          prefixIcon: const Icon(Icons.edit_outlined),
          alignLabelWithHint: true,
        ),
        maxLines: 8,
      ),
      const SizedBox(height: AppSpacing.md),
      _buildTagsField(),
    ];
  }

  // ── Reminder Fields ───────────────────────────────────────────────────

  List<Widget> _buildReminderFields(ThemeData theme) {
    return [
      TextFormField(
        controller: _titleController,
        decoration: InputDecoration(
          labelText: context.tr('note_reminder_title_label'),
          hintText: context.tr('note_reminder_title_hint'),
          prefixIcon: const Icon(Icons.alarm),
        ),
        autofocus: widget.note == null,
      ),
      const SizedBox(height: AppSpacing.md),
      // Due date is the main feature for reminders
      _buildDueDatePicker(theme, required: true),
      const SizedBox(height: AppSpacing.md),
      TextFormField(
        controller: _descriptionController,
        decoration: InputDecoration(
          labelText: context.tr('note_reminder_desc_label'),
          hintText: context.tr('note_reminder_desc_hint'),
          prefixIcon: const Icon(Icons.description_outlined),
          alignLabelWithHint: true,
        ),
        maxLines: 3,
      ),
      const SizedBox(height: AppSpacing.md),
      _buildPriorityDropdown(theme),
      const SizedBox(height: AppSpacing.md),
      _buildTagsField(),
    ];
  }

  // ── Interview Cheat Sheet Fields ─────────────────────────────────────

  List<Widget> _buildInterviewCheatSheetFields(ThemeData theme) {
    final applications = context.read<ApplicationsProvider>().allApplications;

    return [
      // Title (company / position)
      TextFormField(
        controller: _titleController,
        decoration: InputDecoration(
          labelText: context.tr('note_cheatsheet_title_label'),
          hintText: context.tr('note_cheatsheet_title_hint'),
          prefixIcon: const Icon(Icons.assignment),
        ),
        autofocus: widget.note == null,
      ),
      const SizedBox(height: AppSpacing.md),

      // Link to existing application
      DropdownButtonFormField<String>(
        value: _linkedApplicationId,
        decoration: InputDecoration(
          labelText: context.tr('note_cheatsheet_linked_app_label'),
          hintText: context.tr('note_cheatsheet_linked_app_hint'),
          prefixIcon: const Icon(Icons.link),
        ),
        items: [
          DropdownMenuItem<String>(
            value: null,
            child: Text(
              context.tr('note_cheatsheet_no_link'),
              style: theme.textTheme.bodyMedium?.copyWith(
                fontStyle: FontStyle.italic,
                color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.5),
              ),
            ),
          ),
          ...applications.map((app) => DropdownMenuItem<String>(
                value: app.id,
                child: Text(
                  '${app.company} — ${app.position}',
                  overflow: TextOverflow.ellipsis,
                ),
              )),
        ],
        onChanged: (value) => setState(() => _linkedApplicationId = value),
        isExpanded: true,
      ),
      const SizedBox(height: AppSpacing.md),

      // Interview date
      _buildInterviewDatePicker(theme),
      const SizedBox(height: AppSpacing.lg),

      // Salary expectation
      TextFormField(
        controller: _salaryExpectationController,
        decoration: InputDecoration(
          labelText: context.tr('note_cheatsheet_salary_label'),
          hintText: context.tr('note_cheatsheet_salary_hint'),
          prefixIcon: const Icon(Icons.euro),
        ),
      ),
      const SizedBox(height: AppSpacing.md),

      // Company background
      TextFormField(
        controller: _companyBackgroundController,
        decoration: InputDecoration(
          labelText: context.tr('note_cheatsheet_company_bg_label'),
          hintText: context.tr('note_cheatsheet_company_bg_hint'),
          prefixIcon: const Icon(Icons.business),
          alignLabelWithHint: true,
        ),
        maxLines: 4,
      ),
      const SizedBox(height: AppSpacing.md),

      // Why I'm a good fit
      TextFormField(
        controller: _whyGoodFitController,
        decoration: InputDecoration(
          labelText: context.tr('note_cheatsheet_why_fit_label'),
          hintText: context.tr('note_cheatsheet_why_fit_hint'),
          prefixIcon: const Icon(Icons.star_outline),
          alignLabelWithHint: true,
        ),
        maxLines: 4,
      ),
      const SizedBox(height: AppSpacing.md),

      // My strengths for this role
      TextFormField(
        controller: _strengthsController,
        decoration: InputDecoration(
          labelText: context.tr('note_cheatsheet_strengths_label'),
          hintText: context.tr('note_cheatsheet_strengths_hint'),
          prefixIcon: const Icon(Icons.fitness_center),
          alignLabelWithHint: true,
        ),
        maxLines: 3,
      ),
      const SizedBox(height: AppSpacing.md),

      // Questions to ask
      TextFormField(
        controller: _questionsToAskController,
        decoration: InputDecoration(
          labelText: context.tr('note_cheatsheet_questions_label'),
          hintText: context.tr('note_cheatsheet_questions_hint'),
          prefixIcon: const Icon(Icons.help_outline),
          alignLabelWithHint: true,
        ),
        maxLines: 4,
      ),
      const SizedBox(height: AppSpacing.md),

      // Research notes / additional prep
      TextFormField(
        controller: _researchNotesController,
        decoration: InputDecoration(
          labelText: context.tr('note_cheatsheet_research_label'),
          hintText: context.tr('note_cheatsheet_research_hint'),
          prefixIcon: const Icon(Icons.science_outlined),
          alignLabelWithHint: true,
        ),
        maxLines: 3,
      ),
      const SizedBox(height: AppSpacing.md),

      // General notes / description
      TextFormField(
        controller: _descriptionController,
        decoration: InputDecoration(
          labelText: context.tr('note_cheatsheet_notes_label'),
          hintText: context.tr('note_cheatsheet_notes_hint'),
          prefixIcon: const Icon(Icons.edit_outlined),
          alignLabelWithHint: true,
        ),
        maxLines: 3,
      ),
      const SizedBox(height: AppSpacing.md),

      _buildPriorityDropdown(theme),
      const SizedBox(height: AppSpacing.md),
      _buildTagsField(),
    ];
  }

  Widget _buildInterviewDatePicker(ThemeData theme) {
    return InkWell(
      onTap: () async {
        final date = await showDatePicker(
          context: context,
          initialDate: _interviewDate ?? DateTime.now(),
          firstDate: DateTime.now().subtract(const Duration(days: 365)),
          lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
        );
        if (date != null) {
          setState(() => _interviewDate = date);
        }
      },
      borderRadius: BorderRadius.circular(12),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: context.tr('note_cheatsheet_interview_date_label'),
          prefixIcon: const Icon(Icons.event),
          suffixIcon: _interviewDate != null
              ? IconButton(
                  icon: const Icon(Icons.clear, size: 18),
                  onPressed: () => setState(() => _interviewDate = null),
                )
              : const Icon(Icons.arrow_drop_down),
        ),
        child: Text(
          _interviewDate != null
              ? DateFormat('MMM dd, yyyy').format(_interviewDate!)
              : context.tr('note_cheatsheet_no_date'),
          style: theme.textTheme.bodyMedium,
        ),
      ),
    );
  }

  // ── Shared Widgets ────────────────────────────────────────────────────

  Widget _buildPriorityDropdown(ThemeData theme) {
    return DropdownButtonFormField<NotePriority>(
      initialValue: _selectedPriority,
      decoration: InputDecoration(
        labelText: context.tr('note_priority_label'),
        prefixIcon: const Icon(Icons.flag_outlined),
      ),
      items: NotePriority.values.map((priority) {
        return DropdownMenuItem(
          value: priority,
          child: Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: _getPriorityColor(priority),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text(context.tr(priority.localizationKey)),
            ],
          ),
        );
      }).toList(),
      onChanged: (value) {
        if (value != null) {
          setState(() => _selectedPriority = value);
        }
      },
    );
  }

  Widget _buildLeadStatusDropdown(ThemeData theme) {
    return DropdownButtonFormField<LeadStatus>(
      value: _selectedLeadStatus,
      decoration: InputDecoration(
        labelText: context.tr('lead_status_label'),
        prefixIcon: const Icon(Icons.business_center),
      ),
      items: LeadStatus.values.map((status) {
        return DropdownMenuItem(
          value: status,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(status.icon, size: 18),
              const SizedBox(width: 8),
              Text(context.tr(status.localizationKey)),
            ],
          ),
        );
      }).toList(),
      onChanged: (value) {
        setState(() => _selectedLeadStatus = value);
      },
    );
  }

  Widget _buildDueDatePicker(ThemeData theme, {bool required = false}) {
    return InkWell(
      onTap: _selectDueDate,
      borderRadius: BorderRadius.circular(12),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: required
              ? context.tr('note_reminder_due_required')
              : context.tr('note_due_date_label'),
          prefixIcon: const Icon(Icons.calendar_today),
          suffixIcon: _dueDate != null
              ? IconButton(
                  icon: const Icon(Icons.clear, size: 18),
                  onPressed: () => setState(() => _dueDate = null),
                )
              : const Icon(Icons.arrow_drop_down),
        ),
        child: Text(
          _dueDate != null
              ? DateFormat('MMM dd, yyyy').format(_dueDate!)
              : context.tr('no_due_date'),
          style: theme.textTheme.bodyMedium,
        ),
      ),
    );
  }

  Widget _buildTagsField() {
    return TextFormField(
      controller: _tagsController,
      decoration: InputDecoration(
        labelText: context.tr('note_tags_label'),
        hintText: context.tr('note_tags_hint'),
        prefixIcon: const Icon(Icons.label_outlined),
      ),
    );
  }

  Widget _buildActions(ThemeData theme, bool isEdit) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha:0.3),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(AppDimensions.cardBorderRadius),
          bottomRight: Radius.circular(AppDimensions.cardBorderRadius),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(context.tr('cancel')),
          ),
          const SizedBox(width: 12),
          FilledButton.icon(
            onPressed: _saveNote,
            icon: const Icon(Icons.check, size: 18),
            label:
                Text(isEdit ? context.tr('update') : context.tr('create')),
          ),
        ],
      ),
    );
  }

  Future<void> _selectDueDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _dueDate ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
    );

    if (date != null) {
      setState(() => _dueDate = date);
    }
  }

  void _saveNote() {
    final title = _titleController.text.trim();

    if (title.isEmpty) {
      UIUtils.showError(context, context.tr('please_enter_title'));
      return;
    }

    final tags = _tagsController.text
        .split(',')
        .map((tag) => tag.trim())
        .where((tag) => tag.isNotEmpty)
        .toList();

    String? trimOrNull(TextEditingController c) {
      final v = c.text.trim();
      return v.isEmpty ? null : v;
    }

    final isCheatSheet = _selectedType == NoteType.interviewCheatSheet;

    final note = widget.note?.copyWith(
          title: title,
          description: trimOrNull(_descriptionController),
          type: _selectedType,
          priority: _selectedPriority,
          dueDate: _dueDate,
          tags: tags,
          url: trimOrNull(_urlController),
          contactPerson: trimOrNull(_contactPersonController),
          contactEmail: trimOrNull(_contactEmailController),
          location: trimOrNull(_locationController),
          leadStatus: _selectedType == NoteType.companyLead
              ? _selectedLeadStatus
              : null,
          linkedApplicationId: isCheatSheet ? _linkedApplicationId : null,
          salaryExpectation: isCheatSheet ? trimOrNull(_salaryExpectationController) : null,
          companyBackground: isCheatSheet ? trimOrNull(_companyBackgroundController) : null,
          whyGoodFit: isCheatSheet ? trimOrNull(_whyGoodFitController) : null,
          questionsToAsk: isCheatSheet ? trimOrNull(_questionsToAskController) : null,
          strengths: isCheatSheet ? trimOrNull(_strengthsController) : null,
          researchNotes: isCheatSheet ? trimOrNull(_researchNotesController) : null,
          interviewDate: isCheatSheet ? _interviewDate : null,
        ) ??
        NoteItem(
          title: title,
          description: trimOrNull(_descriptionController),
          type: _selectedType,
          priority: _selectedPriority,
          dueDate: _dueDate,
          tags: tags,
          url: trimOrNull(_urlController),
          contactPerson: trimOrNull(_contactPersonController),
          contactEmail: trimOrNull(_contactEmailController),
          location: trimOrNull(_locationController),
          leadStatus: _selectedType == NoteType.companyLead
              ? (_selectedLeadStatus ?? LeadStatus.researching)
              : null,
          linkedApplicationId: isCheatSheet ? _linkedApplicationId : null,
          salaryExpectation: isCheatSheet ? trimOrNull(_salaryExpectationController) : null,
          companyBackground: isCheatSheet ? trimOrNull(_companyBackgroundController) : null,
          whyGoodFit: isCheatSheet ? trimOrNull(_whyGoodFitController) : null,
          questionsToAsk: isCheatSheet ? trimOrNull(_questionsToAskController) : null,
          strengths: isCheatSheet ? trimOrNull(_strengthsController) : null,
          researchNotes: isCheatSheet ? trimOrNull(_researchNotesController) : null,
          interviewDate: isCheatSheet ? _interviewDate : null,
        );

    Navigator.of(context).pop(note);
  }

  Color _getPriorityColor(NotePriority priority) {
    switch (priority) {
      case NotePriority.urgent:
        return AppColors.statusRejected;
      case NotePriority.high:
        return Colors.orange;
      case NotePriority.medium:
        return AppColors.statusApplied;
      case NotePriority.low:
        return AppColors.statusAccepted;
    }
  }

  Color _getTypeColor(NoteType type) {
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

  IconData _getTypeIcon(NoteType type) {
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
