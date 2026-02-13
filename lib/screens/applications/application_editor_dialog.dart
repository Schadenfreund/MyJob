import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/applications_provider.dart';
import '../../providers/templates_provider.dart';
import '../../providers/user_data_provider.dart';
import '../../models/job_application.dart';

import '../../constants/app_constants.dart';
import '../../theme/app_theme.dart';
import '../../widgets/status_badge.dart';
import '../../localization/app_localizations.dart';

class ApplicationEditorDialog extends StatefulWidget {
  const ApplicationEditorDialog({
    super.key,
    this.applicationId,
  });

  final String? applicationId;

  @override
  State<ApplicationEditorDialog> createState() =>
      _ApplicationEditorDialogState();
}

class _ApplicationEditorDialogState extends State<ApplicationEditorDialog> {
  final _formKey = GlobalKey<FormState>();
  final _companyController = TextEditingController();
  final _positionController = TextEditingController();
  final _locationController = TextEditingController();
  final _jobUrlController = TextEditingController();
  final _contactPersonController = TextEditingController();
  final _contactEmailController = TextEditingController();
  final _notesController = TextEditingController();
  final _salaryController = TextEditingController();
  final _subjectController = TextEditingController();

  ApplicationStatus _status = ApplicationStatus.draft;
  DocumentLanguage _baseLanguage = DocumentLanguage.en; // Default to English
  bool _isEditing = false;
  JobApplication? _existingApplication;

  @override
  void initState() {
    super.initState();

    // Set default language from current active language
    final userDataProvider = context.read<UserDataProvider>();
    _baseLanguage = userDataProvider.currentLanguage;

    if (widget.applicationId != null) {
      _isEditing = true;
      _loadApplication();
    }
  }

  Future<void> _loadApplication() async {
    final provider = context.read<ApplicationsProvider>();
    _existingApplication = provider.getApplicationById(widget.applicationId!);
    if (_existingApplication != null) {
      _companyController.text = _existingApplication!.company;
      _positionController.text = _existingApplication!.position;
      _locationController.text = _existingApplication!.location ?? '';
      _jobUrlController.text = _existingApplication!.jobUrl ?? '';
      _contactPersonController.text = _existingApplication!.contactPerson ?? '';
      _contactEmailController.text = _existingApplication!.contactEmail ?? '';
      _notesController.text = _existingApplication!.notes ?? '';
      _salaryController.text = _existingApplication!.salary ?? '';
      _status = _existingApplication!.status;
      _baseLanguage = _existingApplication!.baseLanguage;

      // Load cover letter to get subject
      if (_existingApplication!.folderPath != null) {
        final cl = await provider.storage
            .loadJobCoverLetter(_existingApplication!.folderPath!);
        if (cl != null) {
          _subjectController.text = cl.subject;
        }
      }
      if (mounted) setState(() {});
    }
  }

  @override
  void dispose() {
    _companyController.dispose();
    _positionController.dispose();
    _locationController.dispose();
    _jobUrlController.dispose();
    _contactPersonController.dispose();
    _contactEmailController.dispose();
    _notesController.dispose();
    _salaryController.dispose();
    _subjectController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return PopScope(
        canPop: false, // Prevent back button from closing
        child: Dialog(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 700, maxHeight: 800),
            child: Scaffold(
              appBar: AppBar(
                title: Text(_isEditing
                    ? context.tr('edit_application_title')
                    : context.tr('new_application_title')),
                leading: IconButton(
                  icon: Icon(Icons.close, color: theme.colorScheme.primary),
                  onPressed: () => Navigator.pop(context),
                ),
                actions: [
                  if (_isEditing)
                    IconButton(
                      icon: const Icon(Icons.delete_outline),
                      onPressed: _confirmDelete,
                    ),
                ],
              ),
              body: Form(
                key: _formKey,
                child: ListView(
                  padding: const EdgeInsets.all(24),
                  children: [
                    // Status selector (only for editing)
                    if (_isEditing) ...[
                      Text(context.tr('status_label'),
                          style: theme.textTheme.labelLarge),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: ApplicationStatus.values.map((status) {
                          final isSelected = _status == status;
                          return ChoiceChip(
                            label: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                StatusBadge(
                                    status: status,
                                    size: StatusBadgeSize.small),
                              ],
                            ),
                            selected: isSelected,
                            onSelected: (selected) {
                              if (selected) {
                                setState(() => _status = status);
                              }
                            },
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 24),
                      const SizedBox(height: AppSpacing.md),
                      const SizedBox(height: 24),
                    ],

                    // Job Information Section
                    Text(context.tr('job_info_section'),
                        style: theme.textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 16),

                    // Company
                    TextFormField(
                      controller: _companyController,
                      decoration: InputDecoration(
                        labelText: context.tr('company_label'),
                        hintText: context.tr('company_hint'),
                        prefixIcon: Icon(Icons.business, size: 20),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return context.tr('company_required');
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Position
                    TextFormField(
                      controller: _positionController,
                      decoration: InputDecoration(
                        labelText: context.tr('position_label'),
                        hintText: context.tr('position_hint'),
                        prefixIcon: Icon(Icons.work, size: 20),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return context.tr('position_required');
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Subject / Reference
                    TextFormField(
                      controller: _subjectController,
                      decoration: InputDecoration(
                        labelText: _baseLanguage == DocumentLanguage.de
                            ? context.tr('subject_label_de')
                            : context.tr('subject_label_en'),
                        hintText: _baseLanguage == DocumentLanguage.de
                            ? context.tr('subject_hint_de')
                            : context.tr('subject_hint_en'),
                        prefixIcon: const Icon(Icons.subject, size: 20),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Location
                    TextFormField(
                      controller: _locationController,
                      decoration: InputDecoration(
                        labelText: context.tr('location_label'),
                        hintText: context.tr('location_hint'),
                        prefixIcon: Icon(Icons.location_on, size: 20),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Job URL
                    TextFormField(
                      controller: _jobUrlController,
                      decoration: InputDecoration(
                        labelText: context.tr('job_url_label'),
                        hintText: context.tr('job_url_hint'),
                        prefixIcon: Icon(Icons.link, size: 20),
                      ),
                      keyboardType: TextInputType.url,
                    ),
                    const SizedBox(height: 16),

                    // Salary
                    TextFormField(
                      controller: _salaryController,
                      decoration: InputDecoration(
                        labelText: context.tr('salary_label'),
                        hintText: context.tr('salary_hint'),
                        prefixIcon: Icon(Icons.attach_money, size: 20),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Language Selection (only for new applications)
                    if (!_isEditing) ...[
                      const SizedBox(height: AppSpacing.md),
                      const SizedBox(height: 24),
                      Text(context.tr('app_language_section'),
                          style: theme.textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w600)),
                      const SizedBox(height: 8),
                      Text(
                        context.tr('app_language_desc'),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.textTheme.bodySmall?.color
                              ?.withValues(alpha: 0.7),
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Language selector with consistent styling
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: DocumentLanguage.values.map((lang) {
                          return _buildLanguageOption(
                            theme,
                            lang,
                            _baseLanguage == lang,
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 24),
                    ],

                    // Contact section
                    const SizedBox(height: AppSpacing.md),
                    const SizedBox(height: 24),
                    Text(context.tr('contact_section'),
                        style: theme.textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 16),

                    TextFormField(
                      controller: _contactPersonController,
                      decoration: InputDecoration(
                        labelText: context.tr('contact_name_label'),
                        hintText: context.tr('contact_name_hint'),
                        prefixIcon: Icon(Icons.person, size: 20),
                      ),
                    ),
                    const SizedBox(height: 16),

                    TextFormField(
                      controller: _contactEmailController,
                      decoration: InputDecoration(
                        labelText: context.tr('contact_email_label'),
                        hintText: context.tr('contact_email_hint'),
                        prefixIcon: Icon(Icons.email, size: 20),
                      ),
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 24),

                    // Notes
                    const SizedBox(height: AppSpacing.md),
                    const SizedBox(height: 24),
                    TextFormField(
                      controller: _notesController,
                      decoration: InputDecoration(
                        labelText: context.tr('notes_label'),
                        hintText: context.tr('notes_hint'),
                        prefixIcon: Icon(Icons.note, size: 20),
                      ),
                      maxLines: 4,
                    ),
                    const SizedBox(height: 32),

                    // Save button
                    ElevatedButton(
                      onPressed: _save,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.colorScheme.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.all(16),
                      ),
                      child: Text(
                        _isEditing
                            ? context.tr('save_changes')
                            : context.tr('create_application'),
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ));
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final applicationsProvider = context.read<ApplicationsProvider>();

    if (_isEditing && _existingApplication != null) {
      await applicationsProvider.updateApplication(
        _existingApplication!.copyWith(
          company: _companyController.text,
          position: _positionController.text,
          location: _locationController.text.isEmpty
              ? null
              : _locationController.text,
          jobUrl:
              _jobUrlController.text.isEmpty ? null : _jobUrlController.text,
          contactPerson: _contactPersonController.text.isEmpty
              ? null
              : _contactPersonController.text,
          contactEmail: _contactEmailController.text.isEmpty
              ? null
              : _contactEmailController.text,
          notes: _notesController.text.isEmpty ? null : _notesController.text,
          salary:
              _salaryController.text.isEmpty ? null : _salaryController.text,
          status: _status,
        ),
      );

      // Save subject to cover letter if it changed
      if (_existingApplication!.folderPath != null) {
        final cl = await applicationsProvider.storage
            .loadJobCoverLetter(_existingApplication!.folderPath!);
        if (cl != null) {
          await applicationsProvider.storage.saveJobCoverLetter(
            _existingApplication!.folderPath!,
            cl.copyWith(subject: _subjectController.text),
          );
        }
      }

      if (mounted) {
        Navigator.pop(context);
      }
    } else {
      // Create new application - profile data is automatically cloned
      final userDataProvider = context.read<UserDataProvider>();
      final profile = userDataProvider.getProfileForLanguage(_baseLanguage);

      final newApp = await applicationsProvider.createApplication(
        company: _companyController.text,
        position: _positionController.text,
        baseLanguage: _baseLanguage,
        masterProfile: profile,
        location:
            _locationController.text.isEmpty ? null : _locationController.text,
        jobUrl: _jobUrlController.text.isEmpty ? null : _jobUrlController.text,
        contactPerson: _contactPersonController.text.isEmpty
            ? null
            : _contactPersonController.text,
        contactEmail: _contactEmailController.text.isEmpty
            ? null
            : _contactEmailController.text,
        notes: _notesController.text.isEmpty ? null : _notesController.text,
        salary: _salaryController.text.isEmpty ? null : _salaryController.text,
      );

      // Save subject to newly created cover letter if provided
      if (_subjectController.text.isNotEmpty && newApp.folderPath != null) {
        final cl = await applicationsProvider.storage
            .loadJobCoverLetter(newApp.folderPath!);
        if (cl != null) {
          await applicationsProvider.storage.saveJobCoverLetter(
            newApp.folderPath!,
            cl.copyWith(subject: _subjectController.text),
          );
        }
      }

      // Close this dialog and return the created application
      // The caller will open the PDF editor
      if (mounted) {
        Navigator.pop(context, newApp);
      }
    }
  }

  void _confirmDelete() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.tr('delete_application_confirm_title')),
        content: Text(context.tr('delete_application_confirm_message')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(context.tr('cancel')),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              final applicationsProvider = context.read<ApplicationsProvider>();
              final templatesProvider = context.read<TemplatesProvider>();

              // Delete associated instances first
              await templatesProvider
                  .deleteInstancesForApplication(widget.applicationId!);

              // Then delete the application
              await applicationsProvider
                  .deleteApplication(widget.applicationId!);

              if (mounted) {
                Navigator.pop(context); // Close confirm dialog
                Navigator.pop(context); // Close editor dialog
              }
            },
            child: Text(context.tr('delete')),
          ),
        ],
      ),
    );
  }

  Widget _buildLanguageOption(
    ThemeData theme,
    DocumentLanguage language,
    bool isSelected,
  ) {
    final accentColor = theme.colorScheme.primary;

    return InkWell(
      onTap: () => setState(() => _baseLanguage = language),
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: AppDurations.quick,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? accentColor.withValues(alpha: 0.12)
              : theme.colorScheme.surfaceContainerHighest
                  .withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? accentColor
                : AppColors.getColor(
                        context, AppColors.lightBorder, AppColors.darkBorder)
                    .withValues(alpha: 0.5),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: isSelected
                    ? accentColor.withValues(alpha: 0.2)
                    : theme.colorScheme.surfaceContainerHighest,
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected
                      ? accentColor.withValues(alpha: 0.6)
                      : theme.dividerColor.withValues(alpha: 0.3),
                  width: 1.5,
                ),
              ),
              child: Center(
                child: Text(
                  language.code.toUpperCase(),
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: isSelected
                        ? accentColor
                        : theme.textTheme.bodySmall?.color
                            ?.withValues(alpha: 0.7),
                    fontSize: 10,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Text(
              language.label,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected
                    ? accentColor
                    : theme.textTheme.bodyMedium?.color
                        ?.withValues(alpha: 0.8),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
