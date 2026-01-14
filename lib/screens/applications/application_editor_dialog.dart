import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/applications_provider.dart';
import '../../providers/templates_provider.dart';
import '../../providers/user_data_provider.dart';
import '../../models/job_application.dart';

import '../../constants/app_constants.dart';
import '../../widgets/status_badge.dart';

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

    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 700, maxHeight: 800),
        child: Scaffold(
          appBar: AppBar(
            title: Text(_isEditing ? 'Edit Application' : 'New Application'),
            leading: IconButton(
              icon: const Icon(Icons.close),
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
                  Text('Status', style: theme.textTheme.labelLarge),
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
                                status: status, size: StatusBadgeSize.small),
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
                  Divider(color: theme.dividerColor),
                  const SizedBox(height: 24),
                ],

                // Job Information Section
                Text('Job Information',
                    style: theme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.w600)),
                const SizedBox(height: 16),

                // Company
                TextFormField(
                  controller: _companyController,
                  decoration: const InputDecoration(
                    labelText: 'Company *',
                    hintText: 'Enter company name',
                    prefixIcon: Icon(Icons.business, size: 20),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Company is required';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Position
                TextFormField(
                  controller: _positionController,
                  decoration: const InputDecoration(
                    labelText: 'Position *',
                    hintText: 'Enter job title',
                    prefixIcon: Icon(Icons.work, size: 20),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Position is required';
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
                        ? 'Betreff / Referenz'
                        : 'Subject / Reference',
                    hintText: _baseLanguage == DocumentLanguage.de
                        ? 'z.B. Bewerbung als ...'
                        : 'e.g. Application for ...',
                    prefixIcon: const Icon(Icons.subject, size: 20),
                  ),
                ),
                const SizedBox(height: 16),

                // Location
                TextFormField(
                  controller: _locationController,
                  decoration: const InputDecoration(
                    labelText: 'Location',
                    hintText: 'City, Country or Remote',
                    prefixIcon: Icon(Icons.location_on, size: 20),
                  ),
                ),
                const SizedBox(height: 16),

                // Job URL
                TextFormField(
                  controller: _jobUrlController,
                  decoration: const InputDecoration(
                    labelText: 'Job URL',
                    hintText: 'Link to job posting',
                    prefixIcon: Icon(Icons.link, size: 20),
                  ),
                  keyboardType: TextInputType.url,
                ),
                const SizedBox(height: 16),

                // Salary
                TextFormField(
                  controller: _salaryController,
                  decoration: const InputDecoration(
                    labelText: 'Salary Range',
                    hintText: 'e.g., 50,000 - 70,000 EUR',
                    prefixIcon: Icon(Icons.attach_money, size: 20),
                  ),
                ),
                const SizedBox(height: 24),

                // Language Selection (only for new applications)
                if (!_isEditing) ...[
                  Divider(color: theme.dividerColor),
                  const SizedBox(height: 24),
                  Text('Application Language',
                      style: theme.textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  Text(
                    'Select the language for your application documents',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.textTheme.bodySmall?.color
                          ?.withValues(alpha: 0.7),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Language selector with consistent styling
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: theme.colorScheme.outline.withOpacity(0.2),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        for (var i = 0;
                            i < DocumentLanguage.values.length;
                            i++) ...[
                          if (i > 0)
                            Container(
                              width: 1,
                              height: 32,
                              color: theme.colorScheme.outline.withOpacity(0.2),
                            ),
                          _buildLanguageOption(
                            theme,
                            DocumentLanguage.values[i],
                            _baseLanguage == DocumentLanguage.values[i],
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                ],

                // Contact section
                Divider(color: theme.dividerColor),
                const SizedBox(height: 24),
                Text('Contact Person (Optional)',
                    style: theme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.w600)),
                const SizedBox(height: 16),

                TextFormField(
                  controller: _contactPersonController,
                  decoration: const InputDecoration(
                    labelText: 'Name',
                    hintText: 'Contact person name',
                    prefixIcon: Icon(Icons.person, size: 20),
                  ),
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: _contactEmailController,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    hintText: 'Contact email',
                    prefixIcon: Icon(Icons.email, size: 20),
                  ),
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 24),

                // Notes
                Divider(color: theme.dividerColor),
                const SizedBox(height: 24),
                TextFormField(
                  controller: _notesController,
                  decoration: const InputDecoration(
                    labelText: 'Notes',
                    hintText: 'Add notes about this application',
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
                    _isEditing ? 'Save Changes' : 'Create Application',
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
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
        title: const Text('Delete Application?'),
        content: const Text(
            'This will delete the application and all associated documents. This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
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
            child: const Text('Delete'),
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
    return Material(
      color: isSelected
          ? theme.colorScheme.primary.withOpacity(0.12)
          : Colors.transparent,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: () => setState(() => _baseLanguage = language),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Flag with background
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: isSelected
                      ? theme.colorScheme.primary.withOpacity(0.1)
                      : theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  language.flag,
                  style: const TextStyle(fontSize: 16),
                ),
              ),
              const SizedBox(width: 8),
              // Language code
              Text(
                language.code.toUpperCase(),
                style: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected
                      ? theme.colorScheme.primary
                      : theme.textTheme.bodyMedium?.color?.withOpacity(0.7),
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
