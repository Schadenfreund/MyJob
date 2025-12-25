import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/applications_provider.dart';
import '../../providers/templates_provider.dart';
import '../../models/job_application.dart';
import '../../models/cv_template.dart';
import '../../models/cover_letter_template.dart';
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

  ApplicationStatus _status = ApplicationStatus.draft;
  bool _isEditing = false;
  JobApplication? _existingApplication;

  // Template selection
  CvTemplate? _selectedCvTemplate;
  CoverLetterTemplate? _selectedCoverLetterTemplate;

  @override
  void initState() {
    super.initState();
    if (widget.applicationId != null) {
      _isEditing = true;
      _loadApplication();
    }
  }

  void _loadApplication() {
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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final templatesProvider = context.watch<TemplatesProvider>();

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

                // Template Selection (only for new applications)
                if (!_isEditing) ...[
                  Divider(color: theme.dividerColor),
                  const SizedBox(height: 24),
                  Text('Documents',
                      style: theme.textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  Text(
                    'Select templates to create customized documents for this application',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.textTheme.bodySmall?.color
                          ?.withValues(alpha: 0.7),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // CV Template Selection
                  _buildTemplateSelector(
                    theme,
                    'CV Template',
                    Icons.description,
                    _selectedCvTemplate?.name ?? 'Select CV template',
                    templatesProvider.cvTemplates.isEmpty,
                    () =>
                        _showCvTemplateSelector(templatesProvider.cvTemplates),
                  ),
                  const SizedBox(height: 12),

                  // Cover Letter Template Selection
                  _buildTemplateSelector(
                    theme,
                    'Cover Letter Template',
                    Icons.email,
                    _selectedCoverLetterTemplate?.name ??
                        'Select cover letter template',
                    templatesProvider.coverLetterTemplates.isEmpty,
                    () => _showCoverLetterTemplateSelector(
                        templatesProvider.coverLetterTemplates),
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

  Widget _buildTemplateSelector(
    ThemeData theme,
    String label,
    IconData icon,
    String value,
    bool isEmpty,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: isEmpty ? null : onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.brightness == Brightness.dark
              ? Colors.white.withValues(alpha: 0.05)
              : Colors.black.withValues(alpha: 0.03),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: theme.dividerColor,
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: theme.colorScheme.primary,
                size: 20,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.textTheme.bodySmall?.color
                          ?.withValues(alpha: 0.7),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    isEmpty ? 'No templates available' : value,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: isEmpty
                          ? theme.textTheme.bodySmall?.color
                              ?.withValues(alpha: 0.4)
                          : null,
                    ),
                  ),
                ],
              ),
            ),
            if (!isEmpty)
              Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.4),
              ),
          ],
        ),
      ),
    );
  }

  void _showCvTemplateSelector(List<CvTemplate> templates) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select CV Template'),
        content: SizedBox(
          width: 400,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: templates.length,
            itemBuilder: (context, index) {
              final template = templates[index];
              final isSelected = _selectedCvTemplate?.id == template.id;
              return ListTile(
                leading: Icon(
                  Icons.description,
                  color: Theme.of(context).colorScheme.primary,
                ),
                title: Text(template.name),
                subtitle: Text(
                  '${template.experiences.length} experiences • ${template.skills.length} skills',
                ),
                trailing: isSelected
                    ? const Icon(Icons.check_circle, color: Colors.green)
                    : null,
                selected: isSelected,
                onTap: () {
                  setState(() {
                    _selectedCvTemplate = template;
                  });
                  Navigator.pop(context);
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void _showCoverLetterTemplateSelector(List<CoverLetterTemplate> templates) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Cover Letter Template'),
        content: SizedBox(
          width: 400,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: templates.length,
            itemBuilder: (context, index) {
              final template = templates[index];
              final isSelected =
                  _selectedCoverLetterTemplate?.id == template.id;
              return ListTile(
                leading: Icon(
                  Icons.email,
                  color: Theme.of(context).colorScheme.primary,
                ),
                title: Text(template.name),
                subtitle: Text(
                  template.body.isEmpty
                      ? 'No content yet'
                      : '${template.body.length} characters',
                ),
                trailing: isSelected
                    ? const Icon(Icons.check_circle, color: Colors.green)
                    : null,
                selected: isSelected,
                onTap: () {
                  setState(() {
                    _selectedCoverLetterTemplate = template;
                  });
                  Navigator.pop(context);
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final applicationsProvider = context.read<ApplicationsProvider>();
    final templatesProvider = context.read<TemplatesProvider>();

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
    } else {
      // Create new application
      final newApp = await applicationsProvider.createApplication(
        company: _companyController.text,
        position: _positionController.text,
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

      // Create instances from selected templates
      if (_selectedCvTemplate != null) {
        final cvInstance = await templatesProvider.createCvInstanceFromTemplate(
          templateId: _selectedCvTemplate!.id,
          applicationId: newApp.id,
        );
        await applicationsProvider.linkCvInstance(newApp.id, cvInstance.id);
      }

      if (_selectedCoverLetterTemplate != null) {
        final clInstance =
            await templatesProvider.createCoverLetterInstanceFromTemplate(
          templateId: _selectedCoverLetterTemplate!.id,
          applicationId: newApp.id,
          companyName: _companyController.text,
          jobTitle: _positionController.text,
        );
        await applicationsProvider.linkCoverLetterInstance(
            newApp.id, clInstance.id);
      }
    }

    if (mounted) {
      Navigator.pop(context);
    }
  }

  void _confirmDelete() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Application?'),
        content: const Text(
            'This will also delete associated CV and cover letter instances. This action cannot be undone.'),
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
}
