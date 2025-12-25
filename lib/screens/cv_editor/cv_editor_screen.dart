import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:printing/printing.dart';
import '../../providers/documents_provider.dart';
import '../../models/cv_data.dart';
import '../../models/template_style.dart';
import '../../services/settings_service.dart';

class CvEditorScreen extends StatefulWidget {
  const CvEditorScreen({super.key, required this.cvId});

  final String cvId;

  @override
  State<CvEditorScreen> createState() => _CvEditorScreenState();
}

class _CvEditorScreenState extends State<CvEditorScreen> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final _nameController = TextEditingController();
  final _profileController = TextEditingController();
  final _skillsController = TextEditingController();
  final _interestsController = TextEditingController();

  // Contact controllers
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _linkedinController = TextEditingController();

  CvData? _cv;
  List<Experience> _experiences = [];
  List<Education> _education = [];
  List<LanguageSkill> _languages = [];
  TemplateStyle _selectedTemplate = TemplateStyle.professional;

  @override
  void initState() {
    super.initState();
    _loadCv();
  }

  void _loadCv() {
    final provider = context.read<DocumentsProvider>();
    _cv = provider.getCvById(widget.cvId);
    if (_cv != null) {
      _nameController.text = _cv!.name;
      _profileController.text = _cv!.profile;
      _skillsController.text = _cv!.skills.join(', ');
      _interestsController.text = _cv!.interests.join(', ');
      _experiences = List.from(_cv!.experiences);
      _education = List.from(_cv!.education);
      _languages = List.from(_cv!.languages);

      if (_cv!.contactDetails != null) {
        _fullNameController.text = _cv!.contactDetails!.fullName;
        _emailController.text = _cv!.contactDetails!.email ?? '';
        _phoneController.text = _cv!.contactDetails!.phone ?? '';
        _addressController.text = _cv!.contactDetails!.address ?? '';
        _linkedinController.text = _cv!.contactDetails!.linkedin ?? '';
      }
    }

    final settings = context.read<SettingsService>();
    _selectedTemplate = settings.defaultCvTemplate;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _profileController.dispose();
    _skillsController.dispose();
    _interestsController.dispose();
    _fullNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _linkedinController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(_cv?.name ?? 'Edit CV'),
        actions: [
          IconButton(
            icon: const Icon(Icons.preview),
            tooltip: 'Preview PDF',
            onPressed: _previewPdf,
          ),
          IconButton(
            icon: const Icon(Icons.save),
            tooltip: 'Save',
            onPressed: _save,
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: Row(
          children: [
            // Editor
            Expanded(
              flex: 2,
              child: ListView(
                padding: const EdgeInsets.all(24),
                children: [
                  // Name
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'CV Name',
                      hintText: 'e.g., Main CV',
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Contact Details Section
                  Text('Contact Details', style: theme.textTheme.headlineSmall),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _fullNameController,
                    decoration: const InputDecoration(labelText: 'Full Name *'),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _emailController,
                          decoration: const InputDecoration(labelText: 'Email'),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextFormField(
                          controller: _phoneController,
                          decoration: const InputDecoration(labelText: 'Phone'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _addressController,
                    decoration: const InputDecoration(labelText: 'Address'),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _linkedinController,
                    decoration: const InputDecoration(labelText: 'LinkedIn'),
                  ),
                  const SizedBox(height: 24),

                  // Profile
                  Text('Profile', style: theme.textTheme.headlineSmall),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _profileController,
                    decoration: const InputDecoration(
                      labelText: 'Professional Summary',
                      hintText: 'Write a brief summary of your experience...',
                    ),
                    maxLines: 5,
                  ),
                  const SizedBox(height: 24),

                  // Skills
                  Text('Skills', style: theme.textTheme.headlineSmall),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _skillsController,
                    decoration: const InputDecoration(
                      labelText: 'Skills (comma separated)',
                      hintText:
                          'e.g., Project Management, Communication, Leadership',
                    ),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 24),

                  // Interests
                  Text('Interests', style: theme.textTheme.headlineSmall),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _interestsController,
                    decoration: const InputDecoration(
                      labelText: 'Interests (comma separated)',
                      hintText: 'e.g., Technology, Travel, Photography',
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Work Experience
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Work Experience',
                          style: theme.textTheme.headlineSmall),
                      TextButton.icon(
                        onPressed: _addExperience,
                        icon: const Icon(Icons.add),
                        label: const Text('Add Experience'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  ..._experiences.asMap().entries.map((entry) {
                    final index = entry.key;
                    final exp = entry.value;
                    return _ExperienceCard(
                      experience: exp,
                      onEdit: () => _editExperience(index),
                      onDelete: () => _deleteExperience(index),
                    );
                  }).toList(),
                  if (_experiences.isEmpty)
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Center(
                          child: Text(
                            'No work experience added yet',
                            style: theme.textTheme.bodyLarge
                                ?.copyWith(color: theme.hintColor),
                          ),
                        ),
                      ),
                    ),
                  const SizedBox(height: 32),

                  // Education
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Education', style: theme.textTheme.headlineSmall),
                      TextButton.icon(
                        onPressed: _addEducation,
                        icon: const Icon(Icons.add),
                        label: const Text('Add Education'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  ..._education.asMap().entries.map((entry) {
                    final index = entry.key;
                    final edu = entry.value;
                    return _EducationCard(
                      education: edu,
                      onEdit: () => _editEducation(index),
                      onDelete: () => _deleteEducation(index),
                    );
                  }).toList(),
                  if (_education.isEmpty)
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Center(
                          child: Text(
                            'No education added yet',
                            style: theme.textTheme.bodyLarge
                                ?.copyWith(color: theme.hintColor),
                          ),
                        ),
                      ),
                    ),
                  const SizedBox(height: 32),

                  // Languages
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Languages', style: theme.textTheme.headlineSmall),
                      TextButton.icon(
                        onPressed: _addLanguage,
                        icon: const Icon(Icons.add),
                        label: const Text('Add Language'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  ..._languages.asMap().entries.map((entry) {
                    final index = entry.key;
                    final lang = entry.value;
                    return _LanguageCard(
                      language: lang,
                      onEdit: () => _editLanguage(index),
                      onDelete: () => _deleteLanguage(index),
                    );
                  }).toList(),
                  if (_languages.isEmpty)
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Center(
                          child: Text(
                            'No languages added yet',
                            style: theme.textTheme.bodyLarge
                                ?.copyWith(color: theme.hintColor),
                          ),
                        ),
                      ),
                    ),
                  const SizedBox(height: 32),

                  // Save button
                  ElevatedButton.icon(
                    onPressed: _save,
                    icon: const Icon(Icons.save),
                    label: const Padding(
                      padding: EdgeInsets.all(12),
                      child: Text('Save CV'),
                    ),
                  ),
                ],
              ),
            ),

            // Template selector sidebar
            Container(
              width: 280,
              decoration: BoxDecoration(
                color: theme.cardColor,
                border: Border(
                  left: BorderSide(color: theme.dividerColor),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      'Template',
                      style: theme.textTheme.titleMedium,
                    ),
                  ),
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      children: TemplateStyle.allPresets.map((template) {
                        final isSelected =
                            _selectedTemplate.type == template.type &&
                                _selectedTemplate.primaryColor.toARGB32() ==
                                    template.primaryColor.toARGB32();
                        return _TemplateCard(
                          template: template,
                          isSelected: isSelected,
                          onTap: () {
                            setState(() => _selectedTemplate = template);
                          },
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Experience methods
  Future<void> _addExperience() async {
    final result = await showDialog<Experience>(
      context: context,
      builder: (context) => _ExperienceDialog(),
    );
    if (result != null) {
      setState(() {
        _experiences.add(result);
      });
    }
  }

  Future<void> _editExperience(int index) async {
    final result = await showDialog<Experience>(
      context: context,
      builder: (context) => _ExperienceDialog(experience: _experiences[index]),
    );
    if (result != null) {
      setState(() {
        _experiences[index] = result;
      });
    }
  }

  void _deleteExperience(int index) {
    setState(() {
      _experiences.removeAt(index);
    });
  }

  // Education methods
  Future<void> _addEducation() async {
    final result = await showDialog<Education>(
      context: context,
      builder: (context) => _EducationDialog(),
    );
    if (result != null) {
      setState(() {
        _education.add(result);
      });
    }
  }

  Future<void> _editEducation(int index) async {
    final result = await showDialog<Education>(
      context: context,
      builder: (context) => _EducationDialog(education: _education[index]),
    );
    if (result != null) {
      setState(() {
        _education[index] = result;
      });
    }
  }

  void _deleteEducation(int index) {
    setState(() {
      _education.removeAt(index);
    });
  }

  // Language methods
  Future<void> _addLanguage() async {
    final result = await showDialog<LanguageSkill>(
      context: context,
      builder: (context) => _LanguageDialog(),
    );
    if (result != null) {
      setState(() {
        _languages.add(result);
      });
    }
  }

  Future<void> _editLanguage(int index) async {
    final result = await showDialog<LanguageSkill>(
      context: context,
      builder: (context) => _LanguageDialog(language: _languages[index]),
    );
    if (result != null) {
      setState(() {
        _languages[index] = result;
      });
    }
  }

  void _deleteLanguage(int index) {
    setState(() {
      _languages.removeAt(index);
    });
  }

  Future<void> _save() async {
    if (_cv == null) return;

    final skills = _skillsController.text
        .split(',')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();

    final interests = _interestsController.text
        .split(',')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();

    final updatedCv = _cv!.copyWith(
      name: _nameController.text,
      profile: _profileController.text,
      skills: skills,
      interests: interests,
      experiences: _experiences,
      education: _education,
      languages: _languages,
      contactDetails: ContactDetails(
        fullName: _fullNameController.text,
        email: _emailController.text.isEmpty ? null : _emailController.text,
        phone: _phoneController.text.isEmpty ? null : _phoneController.text,
        address:
            _addressController.text.isEmpty ? null : _addressController.text,
        linkedin:
            _linkedinController.text.isEmpty ? null : _linkedinController.text,
      ),
    );

    await context.read<DocumentsProvider>().updateCv(updatedCv);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('CV saved successfully')),
      );
    }
  }

  Future<void> _previewPdf() async {
    await _save();

    if (_cv == null) return;

    final provider = context.read<DocumentsProvider>();
    final cv = provider.getCvById(widget.cvId);
    if (cv == null) return;

    try {
      final bytes = await provider.generateCvPdf(cv, _selectedTemplate);
      if (mounted) {
        await Printing.layoutPdf(onLayout: (_) => bytes);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error generating PDF: $e')),
        );
      }
    }
  }
}

class _TemplateCard extends StatelessWidget {
  const _TemplateCard({
    required this.template,
    required this.isSelected,
    required this.onTap,
  });

  final TemplateStyle template;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(
          color: isSelected ? theme.colorScheme.primary : Colors.transparent,
          width: 2,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 50,
                decoration: BoxDecoration(
                  color: template.primaryColor,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Column(
                  children: [
                    Container(
                      height: 12,
                      color: template.accentColor,
                    ),
                    const Spacer(),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      template.type.label,
                      style: theme.textTheme.titleSmall,
                    ),
                    Text(
                      template.type.description,
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              if (isSelected)
                Icon(
                  Icons.check_circle,
                  color: theme.colorScheme.primary,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// Experience Card Widget
class _ExperienceCard extends StatelessWidget {
  const _ExperienceCard({
    required this.experience,
    required this.onEdit,
    required this.onDelete,
  });

  final Experience experience;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    experience.title,
                    style: theme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit, size: 20),
                      onPressed: onEdit,
                      tooltip: 'Edit',
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, size: 20),
                      onPressed: onDelete,
                      tooltip: 'Delete',
                    ),
                  ],
                ),
              ],
            ),
            Text(
              experience.company,
              style: theme.textTheme.titleSmall,
            ),
            const SizedBox(height: 4),
            Text(
              experience.dateRange,
              style: theme.textTheme.bodySmall,
            ),
            if (experience.description != null) ...[
              const SizedBox(height: 8),
              Text(experience.description!),
            ],
            if (experience.bullets.isNotEmpty) ...[
              const SizedBox(height: 8),
              ...experience.bullets.map((bullet) => Padding(
                    padding: const EdgeInsets.only(left: 16, bottom: 4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('• '),
                        Expanded(child: Text(bullet)),
                      ],
                    ),
                  )),
            ],
          ],
        ),
      ),
    );
  }
}

// Education Card Widget
class _EducationCard extends StatelessWidget {
  const _EducationCard({
    required this.education,
    required this.onEdit,
    required this.onDelete,
  });

  final Education education;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    education.degree,
                    style: theme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit, size: 20),
                      onPressed: onEdit,
                      tooltip: 'Edit',
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, size: 20),
                      onPressed: onDelete,
                      tooltip: 'Delete',
                    ),
                  ],
                ),
              ],
            ),
            Text(
              education.institution,
              style: theme.textTheme.titleSmall,
            ),
            const SizedBox(height: 4),
            Text(
              education.dateRange,
              style: theme.textTheme.bodySmall,
            ),
            if (education.description != null) ...[
              const SizedBox(height: 8),
              Text(education.description!),
            ],
          ],
        ),
      ),
    );
  }
}

// Language Card Widget
class _LanguageCard extends StatelessWidget {
  const _LanguageCard({
    required this.language,
    required this.onEdit,
    required this.onDelete,
  });

  final LanguageSkill language;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        title: Text(language.language),
        subtitle: Text(language.level),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit, size: 20),
              onPressed: onEdit,
              tooltip: 'Edit',
            ),
            IconButton(
              icon: const Icon(Icons.delete, size: 20),
              onPressed: onDelete,
              tooltip: 'Delete',
            ),
          ],
        ),
      ),
    );
  }
}

// Experience Dialog
class _ExperienceDialog extends StatefulWidget {
  const _ExperienceDialog({this.experience});

  final Experience? experience;

  @override
  State<_ExperienceDialog> createState() => _ExperienceDialogState();
}

class _ExperienceDialogState extends State<_ExperienceDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _companyController;
  late TextEditingController _titleController;
  late TextEditingController _startDateController;
  late TextEditingController _endDateController;
  late TextEditingController _descriptionController;
  final List<TextEditingController> _bulletControllers = [];

  @override
  void initState() {
    super.initState();
    _companyController =
        TextEditingController(text: widget.experience?.company ?? '');
    _titleController =
        TextEditingController(text: widget.experience?.title ?? '');
    _startDateController =
        TextEditingController(text: widget.experience?.startDate ?? '');
    _endDateController =
        TextEditingController(text: widget.experience?.endDate ?? '');
    _descriptionController =
        TextEditingController(text: widget.experience?.description ?? '');

    // Initialize bullet controllers
    if (widget.experience != null) {
      for (var bullet in widget.experience!.bullets) {
        _bulletControllers.add(TextEditingController(text: bullet));
      }
    }
  }

  @override
  void dispose() {
    _companyController.dispose();
    _titleController.dispose();
    _startDateController.dispose();
    _endDateController.dispose();
    _descriptionController.dispose();
    for (var controller in _bulletControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _addBullet() {
    setState(() {
      _bulletControllers.add(TextEditingController());
    });
  }

  void _removeBullet(int index) {
    setState(() {
      _bulletControllers[index].dispose();
      _bulletControllers.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.experience == null
          ? 'Add Work Experience'
          : 'Edit Work Experience'),
      content: SizedBox(
        width: 600,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _companyController,
                  decoration: const InputDecoration(labelText: 'Company *'),
                  validator: (value) =>
                      value?.isEmpty ?? true ? 'Required' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _titleController,
                  decoration: const InputDecoration(labelText: 'Position *'),
                  validator: (value) =>
                      value?.isEmpty ?? true ? 'Required' : null,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _startDateController,
                        decoration: const InputDecoration(
                          labelText: 'Start Date *',
                          hintText: 'e.g., Jan 2020 or 2020-01-01',
                        ),
                        validator: (value) =>
                            value?.isEmpty ?? true ? 'Required' : null,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextFormField(
                        controller: _endDateController,
                        decoration: const InputDecoration(
                          labelText: 'End Date',
                          hintText: 'Present or Dec 2023',
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(
                      labelText: 'Description (optional)'),
                  maxLines: 2,
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Responsibilities / Achievements'),
                    TextButton.icon(
                      onPressed: _addBullet,
                      icon: const Icon(Icons.add),
                      label: const Text('Add'),
                    ),
                  ],
                ),
                ..._bulletControllers.asMap().entries.map((entry) {
                  final index = entry.key;
                  final controller = entry.value;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: controller,
                            decoration: InputDecoration(
                              labelText: 'Point ${index + 1}',
                              prefixText: '• ',
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete),
                          onPressed: () => _removeBullet(index),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_formKey.currentState?.validate() ?? false) {
              final bullets = _bulletControllers
                  .map((c) => c.text)
                  .where((t) => t.isNotEmpty)
                  .toList();

              Navigator.pop(
                context,
                Experience(
                  company: _companyController.text,
                  title: _titleController.text,
                  startDate: _startDateController.text,
                  endDate: _endDateController.text.isEmpty
                      ? null
                      : _endDateController.text,
                  description: _descriptionController.text.isEmpty
                      ? null
                      : _descriptionController.text,
                  bullets: bullets,
                ),
              );
            }
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}

// Education Dialog
class _EducationDialog extends StatefulWidget {
  const _EducationDialog({this.education});

  final Education? education;

  @override
  State<_EducationDialog> createState() => _EducationDialogState();
}

class _EducationDialogState extends State<_EducationDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _institutionController;
  late TextEditingController _degreeController;
  late TextEditingController _startDateController;
  late TextEditingController _endDateController;
  late TextEditingController _descriptionController;

  @override
  void initState() {
    super.initState();
    _institutionController =
        TextEditingController(text: widget.education?.institution ?? '');
    _degreeController =
        TextEditingController(text: widget.education?.degree ?? '');
    _startDateController =
        TextEditingController(text: widget.education?.startDate ?? '');
    _endDateController =
        TextEditingController(text: widget.education?.endDate ?? '');
    _descriptionController =
        TextEditingController(text: widget.education?.description ?? '');
  }

  @override
  void dispose() {
    _institutionController.dispose();
    _degreeController.dispose();
    _startDateController.dispose();
    _endDateController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
          widget.education == null ? 'Add Education' : 'Edit Education'),
      content: SizedBox(
        width: 600,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _institutionController,
                  decoration: const InputDecoration(labelText: 'Institution *'),
                  validator: (value) =>
                      value?.isEmpty ?? true ? 'Required' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _degreeController,
                  decoration: const InputDecoration(labelText: 'Degree *'),
                  validator: (value) =>
                      value?.isEmpty ?? true ? 'Required' : null,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _startDateController,
                        decoration: const InputDecoration(
                          labelText: 'Start Date *',
                          hintText: 'e.g., 2015',
                        ),
                        validator: (value) =>
                            value?.isEmpty ?? true ? 'Required' : null,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextFormField(
                        controller: _endDateController,
                        decoration: const InputDecoration(
                          labelText: 'End Date',
                          hintText: 'e.g., 2019',
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(
                      labelText: 'Description (optional)'),
                  maxLines: 2,
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_formKey.currentState?.validate() ?? false) {
              Navigator.pop(
                context,
                Education(
                  institution: _institutionController.text,
                  degree: _degreeController.text,
                  startDate: _startDateController.text,
                  endDate: _endDateController.text.isEmpty
                      ? null
                      : _endDateController.text,
                  description: _descriptionController.text.isEmpty
                      ? null
                      : _descriptionController.text,
                ),
              );
            }
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}

// Language Dialog
class _LanguageDialog extends StatefulWidget {
  const _LanguageDialog({this.language});

  final LanguageSkill? language;

  @override
  State<_LanguageDialog> createState() => _LanguageDialogState();
}

class _LanguageDialogState extends State<_LanguageDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _languageController;
  late TextEditingController _levelController;

  @override
  void initState() {
    super.initState();
    _languageController =
        TextEditingController(text: widget.language?.language ?? '');
    _levelController =
        TextEditingController(text: widget.language?.level ?? '');
  }

  @override
  void dispose() {
    _languageController.dispose();
    _levelController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.language == null ? 'Add Language' : 'Edit Language'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _languageController,
              decoration: const InputDecoration(
                labelText: 'Language *',
                hintText: 'e.g., English',
              ),
              validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _levelController,
              decoration: const InputDecoration(
                labelText: 'Proficiency Level *',
                hintText: 'e.g., Native, Fluent, Basic',
              ),
              validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_formKey.currentState?.validate() ?? false) {
              Navigator.pop(
                context,
                LanguageSkill(
                  language: _languageController.text,
                  level: _levelController.text,
                ),
              );
            }
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}
