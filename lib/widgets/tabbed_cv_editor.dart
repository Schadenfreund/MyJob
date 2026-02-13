import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/cv_template.dart';
import '../models/cv_data.dart';
import '../models/user_data/skill.dart';
import '../models/user_data/interest.dart';
import '../providers/user_data_provider.dart';
import '../services/profile_autofill_service.dart';
import '../widgets/common/custom_text_field.dart';
import '../widgets/skill_chip_editor.dart';
import '../widgets/interest_chip_editor.dart';
import '../widgets/autofill_button.dart';
import '../utils/data_converters.dart';
import '../utils/ui_utils.dart';
import '../localization/app_localizations.dart';

/// Tabbed CV editor with organized sections
class TabbedCvEditor extends StatefulWidget {
  const TabbedCvEditor({
    required this.template,
    required this.onChanged,
    super.key,
  });

  final CvTemplate template;
  final ValueChanged<CvTemplate> onChanged;

  @override
  State<TabbedCvEditor> createState() => _TabbedCvEditorState();
}

class _TabbedCvEditorState extends State<TabbedCvEditor>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Contact info controllers
  late TextEditingController _fullNameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _addressController;
  late TextEditingController _linkedinController;
  late TextEditingController _websiteController;

  // Profile controller
  late TextEditingController _profileController;

  // Skills and interests (using parsed data from template)
  List<Skill> _skills = [];
  List<Interest> _interests = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);

    // Initialize contact details
    final contact = widget.template.contactDetails;
    _fullNameController = TextEditingController(text: contact?.fullName ?? '');
    _emailController = TextEditingController(text: contact?.email ?? '');
    _phoneController = TextEditingController(text: contact?.phone ?? '');
    _addressController = TextEditingController(text: contact?.address ?? '');
    _linkedinController = TextEditingController(text: contact?.linkedin ?? '');
    _websiteController = TextEditingController(text: contact?.website ?? '');

    // Initialize profile
    _profileController = TextEditingController(text: widget.template.profile);

    // Parse skills and interests from template
    _skills = DataConverters.parseSkillStrings(widget.template.skills);
    _interests = DataConverters.parseInterestStrings(widget.template.interests);

    // Add listeners
    _fullNameController.addListener(_updateTemplate);
    _emailController.addListener(_updateTemplate);
    _phoneController.addListener(_updateTemplate);
    _addressController.addListener(_updateTemplate);
    _linkedinController.addListener(_updateTemplate);
    _websiteController.addListener(_updateTemplate);
    _profileController.addListener(_updateTemplate);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _fullNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _linkedinController.dispose();
    _websiteController.dispose();
    _profileController.dispose();
    super.dispose();
  }

  void _updateTemplate() {
    final updatedTemplate = widget.template.copyWith(
      contactDetails: ContactDetails(
        fullName: _fullNameController.text.trim(),
        email: _emailController.text.trim().isNotEmpty
            ? _emailController.text.trim()
            : null,
        phone: _phoneController.text.trim().isNotEmpty
            ? _phoneController.text.trim()
            : null,
        address: _addressController.text.trim().isNotEmpty
            ? _addressController.text.trim()
            : null,
        linkedin: _linkedinController.text.trim().isNotEmpty
            ? _linkedinController.text.trim()
            : null,
        website: _websiteController.text.trim().isNotEmpty
            ? _websiteController.text.trim()
            : null,
      ),
      profile: _profileController.text,
      skills: DataConverters.skillsToStrings(_skills),
      interests: DataConverters.interestsToStrings(_interests),
    );

    widget.onChanged(updatedTemplate);
  }

  void _autofillFromProfile() {
    final userDataProvider = context.read<UserDataProvider>();
    final autofillService = ProfileAutofillService(userDataProvider);

    final autofilled = autofillService.autofillCvTemplate(widget.template);

    // Update controllers
    final contact = autofilled.contactDetails;
    if (contact != null) {
      _fullNameController.text = contact.fullName;
      _emailController.text = contact.email ?? '';
      _phoneController.text = contact.phone ?? '';
      _addressController.text = contact.address ?? '';
      _linkedinController.text = contact.linkedin ?? '';
      _websiteController.text = contact.website ?? '';
    }

    _profileController.text = autofilled.profile;

    // Update skills and interests
    setState(() {
      _skills = DataConverters.parseSkillStrings(autofilled.skills);
      _interests = DataConverters.parseInterestStrings(autofilled.interests);
    });

    _updateTemplate();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        // Tab bar
        Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            border: Border(
              bottom: BorderSide(
                color: theme.dividerColor,
                width: 1,
              ),
            ),
          ),
          child: TabBar(
            controller: _tabController,
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            tabs: [
              _buildTab(Icons.contact_mail, context.tr('tab_contact')),
              _buildTab(Icons.person, context.tr('tab_profile')),
              _buildTab(Icons.star, context.tr('tab_skills_interests')),
              _buildTab(Icons.work, context.tr('tab_experience')),
              _buildTab(Icons.school, context.tr('tab_education')),
            ],
          ),
        ),

        // Tab content
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildContactTab(),
              _buildProfileTab(),
              _buildSkillsTab(),
              _buildExperienceTab(),
              _buildEducationTab(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTab(IconData icon, String label) {
    return Tab(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18),
          const SizedBox(width: 8),
          Text(label),
        ],
      ),
    );
  }

  Widget _buildContactTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Auto-fill section - more compact
          AutofillSection(
            onAutofill: _autofillFromProfile,
            fieldsToFill: const ['Name', 'Email', 'Phone', 'Address'],
            title: context.tr('autofill_from_profile'),
            description: '',
          ),

          const SizedBox(height: 20),

          // Contact fields with reduced spacing
          CustomTextField(
            controller: _fullNameController,
            label: context.tr('full_name'),
            hint: 'John Doe',
            prefixIcon: Icons.person,
            required: true,
          ),
          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child: CustomTextField(
                  controller: _emailController,
                  label: context.tr('email'),
                  hint: 'john@example.com',
                  keyboardType: TextInputType.emailAddress,
                  prefixIcon: Icons.email,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: CustomTextField(
                  controller: _phoneController,
                  label: context.tr('phone'),
                  hint: '+1 234 567 8900',
                  keyboardType: TextInputType.phone,
                  prefixIcon: Icons.phone,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          CustomTextField(
            controller: _addressController,
            label: context.tr('address'),
            hint: 'City, Country',
            prefixIcon: Icons.location_on,
          ),
          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child: CustomTextField(
                  controller: _linkedinController,
                  label: context.tr('linkedin'),
                  hint: 'linkedin.com/in/johndoe',
                  keyboardType: TextInputType.url,
                  prefixIcon: Icons.link,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: CustomTextField(
                  controller: _websiteController,
                  label: context.tr('website'),
                  hint: 'www.johndoe.com',
                  keyboardType: TextInputType.url,
                  prefixIcon: Icons.language,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProfileTab() {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.tr('professional_summary'),
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),

          CustomTextField(
            controller: _profileController,
            label: context.tr('profile_summary_label'),
            hint: 'Experienced professional with a proven track record in...',
            maxLines: 12,
            minLines: 8,
            keyboardType: TextInputType.multiline,
            textInputAction: TextInputAction.newline,
          ),

          const SizedBox(height: 12),

          // Character and word count
          Row(
            children: [
              Icon(
                Icons.info_outline,
                size: 14,
                color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.6),
              ),
              const SizedBox(width: 6),
              Text(
                context.tr('chars_words_count', {
                  'chars': '${_profileController.text.length}',
                  'words': '${_profileController.text.trim().split(RegExp(r'\s+')).where((word) => word.isNotEmpty).length}',
                }),
                style: theme.textTheme.bodySmall?.copyWith(
                  fontSize: 12,
                  color:
                      theme.textTheme.bodySmall?.color?.withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSkillsTab() {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Skills section
          Text(
            context.tr('skills'),
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),

          SkillChipEditor(
            skills: _skills,
            onChanged: (skills) {
              setState(() => _skills = skills);
              _updateTemplate();
            },
          ),

          const SizedBox(height: 28),

          // Divider between sections
          const Divider(height: 1, thickness: 1),

          const SizedBox(height: 28),

          // Interests section
          Text(
            context.tr('interests_hobbies'),
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),

          InterestChipEditor(
            interests: _interests,
            onChanged: (interests) {
              setState(() => _interests = interests);
              _updateTemplate();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildExperienceTab() {
    final theme = Theme.of(context);
    final experiences = widget.template.experiences;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                context.tr('work_experience'),
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              FilledButton.tonalIcon(
                onPressed: _addExperience,
                icon: const Icon(Icons.add, size: 16),
                label: Text(context.tr('add')),
                style: FilledButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  minimumSize: const Size(0, 36),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Show existing experiences with edit/delete
          if (experiences.isEmpty)
            UIUtils.buildEmptyState(
              context,
              icon: Icons.work_outline,
              title: context.tr('no_work_experience'),
              message: context.tr('no_work_exp_message'),
            )
          else
            ...experiences.asMap().entries.map((entry) {
              final index = entry.key;
              final exp = entry.value;
              final isCurrent = exp.endDate == null ||
                  exp.endDate!.toLowerCase().contains('present') ||
                  exp.endDate!.toLowerCase().contains('current');

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              exp.title,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          if (isCurrent)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primaryContainer,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                context.tr('current'),
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onPrimaryContainer,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          IconButton(
                            icon: const Icon(Icons.edit, size: 20),
                            onPressed: () => _editExperience(index),
                            tooltip: context.tr('edit'),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, size: 20),
                            onPressed: () => _deleteExperience(index),
                            tooltip: context.tr('delete'),
                            color: theme.colorScheme.error,
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        exp.company,
                        style: theme.textTheme.titleSmall,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.calendar_today,
                            size: 14,
                            color: theme.textTheme.bodySmall?.color
                                ?.withValues(alpha: 0.7),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${exp.startDate} - ${exp.endDate ?? context.tr('present')}',
                            style: theme.textTheme.bodySmall,
                          ),
                        ],
                      ),
                      if (exp.description != null &&
                          exp.description!.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Text(
                          exp.description!,
                          style: theme.textTheme.bodyMedium,
                        ),
                      ],
                      if (exp.bullets.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        ...exp.bullets.map((bullet) => Padding(
                              padding:
                                  const EdgeInsets.only(left: 16, bottom: 4),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('• ', style: theme.textTheme.bodyMedium),
                                  Expanded(
                                    child: Text(
                                      bullet,
                                      style: theme.textTheme.bodyMedium,
                                    ),
                                  ),
                                ],
                              ),
                            )),
                      ],
                    ],
                  ),
                ),
              );
            }),
        ],
      ),
    );
  }

  Future<void> _addExperience() async {
    final result = await showDialog<Experience>(
      context: context,
      builder: (context) => _ExperienceDialog(),
    );

    if (result != null) {
      final updatedTemplate = widget.template.copyWith(
        experiences: [...widget.template.experiences, result],
      );
      widget.onChanged(updatedTemplate);
    }
  }

  Future<void> _editExperience(int index) async {
    final result = await showDialog<Experience>(
      context: context,
      builder: (context) =>
          _ExperienceDialog(experience: widget.template.experiences[index]),
    );

    if (result != null) {
      final updatedExperiences = [...widget.template.experiences];
      updatedExperiences[index] = result;
      final updatedTemplate = widget.template.copyWith(
        experiences: updatedExperiences,
      );
      widget.onChanged(updatedTemplate);
    }
  }

  void _deleteExperience(int index) {
    final updatedExperiences = [...widget.template.experiences];
    updatedExperiences.removeAt(index);
    final updatedTemplate = widget.template.copyWith(
      experiences: updatedExperiences,
    );
    widget.onChanged(updatedTemplate);
  }

  Widget _buildEducationTab() {
    final theme = Theme.of(context);
    final education = widget.template.education;
    final languages = widget.template.languages;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Education section
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                context.tr('education'),
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              FilledButton.tonalIcon(
                onPressed: _addEducation,
                icon: const Icon(Icons.add, size: 16),
                label: Text(context.tr('add')),
                style: FilledButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  minimumSize: const Size(0, 36),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          if (education.isEmpty)
            UIUtils.buildEmptyState(
              context,
              icon: Icons.school_outlined,
              title: context.tr('no_education_added'),
              message: context.tr('no_education_message_short'),
            )
          else
            ...education.asMap().entries.map((entry) {
              final index = entry.key;
              final edu = entry.value;

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              edu.degree,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.edit, size: 20),
                            onPressed: () => _editEducation(index),
                            tooltip: context.tr('edit'),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, size: 20),
                            onPressed: () => _deleteEducation(index),
                            tooltip: context.tr('delete'),
                            color: theme.colorScheme.error,
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        edu.institution,
                        style: theme.textTheme.titleSmall,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.calendar_today,
                            size: 14,
                            color: theme.textTheme.bodySmall?.color
                                ?.withValues(alpha: 0.7),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${edu.startDate} - ${edu.endDate ?? context.tr('present')}',
                            style: theme.textTheme.bodySmall,
                          ),
                        ],
                      ),
                      if (edu.description != null &&
                          edu.description!.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Text(
                          edu.description!,
                          style: theme.textTheme.bodyMedium,
                        ),
                      ],
                    ],
                  ),
                ),
              );
            }),

          const SizedBox(height: 28),

          // Divider between sections
          const Divider(height: 1, thickness: 1),

          const SizedBox(height: 28),

          // Languages section
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                context.tr('languages'),
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              FilledButton.tonalIcon(
                onPressed: _addLanguage,
                icon: const Icon(Icons.add, size: 16),
                label: Text(context.tr('add')),
                style: FilledButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  minimumSize: const Size(0, 36),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          if (languages.isEmpty)
            UIUtils.buildEmptyState(
              context,
              icon: Icons.language,
              title: context.tr('no_languages_added'),
              message: context.tr('no_languages_message'),
            )
          else
            ...languages.asMap().entries.map((entry) {
              final index = entry.key;
              final lang = entry.value;

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: theme.colorScheme.primaryContainer,
                        child: Text(
                          lang.language.substring(0, 1).toUpperCase(),
                          style: TextStyle(
                            color: theme.colorScheme.onPrimaryContainer,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              lang.language,
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              lang.level,
                              style: theme.textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.edit, size: 20),
                        onPressed: () => _editLanguage(index),
                        tooltip: context.tr('edit'),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, size: 20),
                        onPressed: () => _deleteLanguage(index),
                        tooltip: context.tr('delete'),
                        color: theme.colorScheme.error,
                      ),
                    ],
                  ),
                ),
              );
            }),
        ],
      ),
    );
  }

  Future<void> _addEducation() async {
    final result = await showDialog<Education>(
      context: context,
      builder: (context) => const _EducationDialog(),
    );

    if (result != null) {
      final updatedTemplate = widget.template.copyWith(
        education: [...widget.template.education, result],
      );
      widget.onChanged(updatedTemplate);
    }
  }

  Future<void> _editEducation(int index) async {
    final result = await showDialog<Education>(
      context: context,
      builder: (context) =>
          _EducationDialog(education: widget.template.education[index]),
    );

    if (result != null) {
      final updatedEducation = [...widget.template.education];
      updatedEducation[index] = result;
      final updatedTemplate = widget.template.copyWith(
        education: updatedEducation,
      );
      widget.onChanged(updatedTemplate);
    }
  }

  void _deleteEducation(int index) {
    final updatedEducation = [...widget.template.education];
    updatedEducation.removeAt(index);
    final updatedTemplate = widget.template.copyWith(
      education: updatedEducation,
    );
    widget.onChanged(updatedTemplate);
  }

  Future<void> _addLanguage() async {
    final result = await showDialog<LanguageSkill>(
      context: context,
      builder: (context) => const _LanguageDialog(),
    );

    if (result != null) {
      final updatedTemplate = widget.template.copyWith(
        languages: [...widget.template.languages, result],
      );
      widget.onChanged(updatedTemplate);
    }
  }

  Future<void> _editLanguage(int index) async {
    final result = await showDialog<LanguageSkill>(
      context: context,
      builder: (context) =>
          _LanguageDialog(language: widget.template.languages[index]),
    );

    if (result != null) {
      final updatedLanguages = [...widget.template.languages];
      updatedLanguages[index] = result;
      final updatedTemplate = widget.template.copyWith(
        languages: updatedLanguages,
      );
      widget.onChanged(updatedTemplate);
    }
  }

  void _deleteLanguage(int index) {
    final updatedLanguages = [...widget.template.languages];
    updatedLanguages.removeAt(index);
    final updatedTemplate = widget.template.copyWith(
      languages: updatedLanguages,
    );
    widget.onChanged(updatedTemplate);
  }
}

// Experience Dialog for adding/editing work experience
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
      title: Text(
          widget.experience == null ? context.tr('add_work_experience') : context.tr('edit_work_experience')),
      content: SizedBox(
        width: 550,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CustomTextField(
                  controller: _companyController,
                  label: context.tr('company'),
                  hint: 'Google Inc.',
                  prefixIcon: Icons.business,
                  required: true,
                  validator: (value) =>
                      value?.trim().isEmpty ?? true ? context.tr('required') : null,
                ),
                const SizedBox(height: 12),
                CustomTextField(
                  controller: _titleController,
                  label: context.tr('position'),
                  hint: 'Senior Software Engineer',
                  prefixIcon: Icons.work,
                  required: true,
                  validator: (value) =>
                      value?.trim().isEmpty ?? true ? context.tr('required') : null,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: CustomTextField(
                        controller: _startDateController,
                        label: context.tr('start_date'),
                        hint: 'Jan 2020',
                        prefixIcon: Icons.calendar_today,
                        required: true,
                        validator: (value) =>
                            value?.trim().isEmpty ?? true ? context.tr('required') : null,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: CustomTextField(
                        controller: _endDateController,
                        label: context.tr('end_date_label'),
                        hint: 'Present',
                        prefixIcon: Icons.event,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                CustomTextField(
                  controller: _descriptionController,
                  label: context.tr('description'),
                  hint: 'Brief overview...',
                  maxLines: 3,
                  minLines: 2,
                  keyboardType: TextInputType.multiline,
                  textInputAction: TextInputAction.newline,
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      context.tr('key_points'),
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    FilledButton.tonalIcon(
                      onPressed: _addBullet,
                      icon: const Icon(Icons.add, size: 14),
                      label: Text(context.tr('add')),
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        minimumSize: const Size(0, 32),
                        textStyle: const TextStyle(fontSize: 13),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ..._bulletControllers.asMap().entries.map((entry) {
                  final index = entry.key;
                  final controller = entry.value;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Padding(
                          padding: EdgeInsets.only(top: 14),
                          child: Text('•  '),
                        ),
                        Expanded(
                          child: CustomTextField(
                            controller: controller,
                            label: '#${index + 1}',
                            hint: 'Achievement or responsibility...',
                            maxLines: 2,
                            keyboardType: TextInputType.multiline,
                            textInputAction: TextInputAction.newline,
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.close,
                              size: 18,
                              color: Theme.of(context).colorScheme.error),
                          onPressed: () => _removeBullet(index),
                          tooltip: context.tr('remove'),
                          visualDensity: VisualDensity.compact,
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(context.tr('cancel')),
        ),
        FilledButton(
          onPressed: () {
            if (_formKey.currentState?.validate() ?? false) {
              final bullets = _bulletControllers
                  .map((c) => c.text.trim())
                  .where((t) => t.isNotEmpty)
                  .toList();

              Navigator.pop(
                context,
                Experience(
                  company: _companyController.text.trim(),
                  title: _titleController.text.trim(),
                  startDate: _startDateController.text.trim(),
                  endDate: _endDateController.text.trim().isEmpty
                      ? null
                      : _endDateController.text.trim(),
                  description: _descriptionController.text.trim().isEmpty
                      ? null
                      : _descriptionController.text.trim(),
                  bullets: bullets,
                ),
              );
            }
          },
          child: Text(context.tr('save')),
        ),
      ],
    );
  }
}

// Education Dialog for adding/editing education
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
      title:
          Text(widget.education == null ? context.tr('add_education') : context.tr('edit_education')),
      content: SizedBox(
        width: 550,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CustomTextField(
                  controller: _institutionController,
                  label: context.tr('institution'),
                  hint: 'Harvard University',
                  prefixIcon: Icons.school,
                  required: true,
                  validator: (value) =>
                      value?.trim().isEmpty ?? true ? context.tr('required') : null,
                ),
                const SizedBox(height: 12),
                CustomTextField(
                  controller: _degreeController,
                  label: context.tr('degree'),
                  hint: 'Bachelor of Science in Computer Science',
                  prefixIcon: Icons.workspace_premium,
                  required: true,
                  validator: (value) =>
                      value?.trim().isEmpty ?? true ? context.tr('required') : null,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: CustomTextField(
                        controller: _startDateController,
                        label: context.tr('start_date'),
                        hint: '2015',
                        prefixIcon: Icons.calendar_today,
                        required: true,
                        validator: (value) =>
                            value?.trim().isEmpty ?? true ? context.tr('required') : null,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: CustomTextField(
                        controller: _endDateController,
                        label: context.tr('end_date_label'),
                        hint: '2019',
                        prefixIcon: Icons.event,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                CustomTextField(
                  controller: _descriptionController,
                  label: context.tr('description'),
                  hint: 'GPA, honors, relevant coursework...',
                  maxLines: 3,
                  minLines: 2,
                  keyboardType: TextInputType.multiline,
                  textInputAction: TextInputAction.newline,
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(context.tr('cancel')),
        ),
        FilledButton(
          onPressed: () {
            if (_formKey.currentState?.validate() ?? false) {
              Navigator.pop(
                context,
                Education(
                  institution: _institutionController.text.trim(),
                  degree: _degreeController.text.trim(),
                  startDate: _startDateController.text.trim(),
                  endDate: _endDateController.text.trim().isEmpty
                      ? null
                      : _endDateController.text.trim(),
                  description: _descriptionController.text.trim().isEmpty
                      ? null
                      : _descriptionController.text.trim(),
                ),
              );
            }
          },
          child: Text(context.tr('save')),
        ),
      ],
    );
  }
}

// Language Dialog for adding/editing languages
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
      title: Text(widget.language == null ? context.tr('add_language') : context.tr('edit_language')),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CustomTextField(
              controller: _languageController,
              label: context.tr('language_word'),
              hint: 'English',
              prefixIcon: Icons.language,
              required: true,
              validator: (value) =>
                  value?.trim().isEmpty ?? true ? context.tr('required') : null,
            ),
            const SizedBox(height: 12),
            CustomTextField(
              controller: _levelController,
              label: context.tr('proficiency_level_label'),
              hint: 'Native, Fluent, Intermediate, Basic',
              prefixIcon: Icons.star,
              required: true,
              validator: (value) =>
                  value?.trim().isEmpty ?? true ? context.tr('required') : null,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(context.tr('cancel')),
        ),
        FilledButton(
          onPressed: () {
            if (_formKey.currentState?.validate() ?? false) {
              Navigator.pop(
                context,
                LanguageSkill(
                  language: _languageController.text.trim(),
                  level: _levelController.text.trim(),
                ),
              );
            }
          },
          child: Text(context.tr('save')),
        ),
      ],
    );
  }
}
