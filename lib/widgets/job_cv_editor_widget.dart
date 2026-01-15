import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as path;
import '../providers/user_data_provider.dart';
import '../models/job_application.dart';
import '../models/job_cv_data.dart';
import '../models/job_cover_letter.dart';
import '../models/user_data/work_experience.dart';
import '../models/user_data/skill.dart';
import '../models/user_data/language.dart';
import '../models/user_data/interest.dart';
import '../models/user_data/personal_info.dart';
import '../models/master_profile.dart'; // Contains Education class
import '../services/storage_service.dart';
import '../dialogs/experience_edit_dialog.dart';
import '../dialogs/education_edit_dialog.dart';
import '../dialogs/skill_edit_dialog.dart';
import '../dialogs/language_edit_dialog.dart';
import '../dialogs/interest_edit_dialog.dart';
import '../widgets/skill_chip_editor.dart';
import '../widgets/interest_chip_editor.dart';
import '../widgets/profile_picture_picker.dart';
import '../theme/app_theme.dart';
import '../widgets/app_card.dart';
import '../utils/ui_utils.dart';
import '../utils/dialog_utils.dart';
import '../constants/app_constants.dart';

/// Modern tabbed CV content editor for job applications
///
/// Provides comprehensive CRUD for all CV sections with excellent UX.
/// Works with JobCvData and saves to job folder automatically.
class JobCvEditorWidget extends StatefulWidget {
  const JobCvEditorWidget({
    required this.cvData,
    required this.onChanged,
    this.applicationContext,
    this.onApplicationChanged,
    this.coverLetter,
    this.onTabChanged,
    super.key,
  });

  final JobCvData cvData;
  final ValueChanged<JobCvData> onChanged;
  final JobApplication? applicationContext;
  final ValueChanged<JobApplication>? onApplicationChanged;
  final dynamic coverLetter; // JobCoverLetter?
  final ValueChanged<int>? onTabChanged;

  @override
  State<JobCvEditorWidget> createState() => _JobCvEditorWidgetState();
}

class _JobCvEditorWidgetState extends State<JobCvEditorWidget>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late JobCvData _cvData;
  JobCoverLetter? _jobCoverLetter;

  // Cover letter text controllers
  late TextEditingController _recipientNameController;
  late TextEditingController _recipientTitleController;
  late TextEditingController _subjectController;
  late TextEditingController _greetingController;
  late TextEditingController _bodyController;
  late TextEditingController _closingController;

  // Application details controllers - centralized for immediate saving
  late TextEditingController _companyController;
  late TextEditingController _positionController;
  late TextEditingController _locationController;
  late TextEditingController _jobUrlController;
  late TextEditingController _salaryController;
  late TextEditingController _contactPersonController;
  late TextEditingController _contactEmailController;
  late TextEditingController _notesController;

  final _storage = StorageService.instance;

  // No additional controllers needed for CV sections

  @override
  void initState() {
    super.initState();
    _cvData = widget.cvData;
    _tabController = TabController(length: 8, vsync: this);

    // Add listener to notify parent of tab changes
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        widget.onTabChanged?.call(_tabController.index);
      }
    });

    // Load JobCoverLetter from widget
    _jobCoverLetter = widget.coverLetter as JobCoverLetter?;

    // Initialize cover letter controllers with loaded data
    _recipientNameController = TextEditingController(
      text: _jobCoverLetter?.recipientName ??
          widget.applicationContext?.contactPerson ??
          '',
    );
    _recipientTitleController = TextEditingController(
      text: _jobCoverLetter?.recipientTitle ?? '',
    );
    _subjectController = TextEditingController(
      text: _jobCoverLetter?.subject ?? '',
    );
    _greetingController = TextEditingController(
      text: _jobCoverLetter?.greeting ?? 'Dear Hiring Manager,',
    );
    _bodyController = TextEditingController(
      text: _jobCoverLetter?.body ?? '',
    );
    _closingController = TextEditingController(
      text: _jobCoverLetter?.closing ?? 'Sincerely,',
    );

    // Add listeners for auto-save
    _recipientNameController.addListener(_updateCoverLetter);
    _recipientTitleController.addListener(_updateCoverLetter);
    _subjectController.addListener(_updateCoverLetter);
    _greetingController.addListener(_updateCoverLetter);
    _bodyController.addListener(_updateCoverLetter);
    _closingController.addListener(_updateCoverLetter);

    // Initialize application details controllers
    final app = widget.applicationContext;
    _companyController = TextEditingController(text: app?.company ?? '');
    _positionController = TextEditingController(text: app?.position ?? '');
    _locationController = TextEditingController(text: app?.location ?? '');
    _jobUrlController = TextEditingController(text: app?.jobUrl ?? '');
    _salaryController = TextEditingController(text: app?.salary ?? '');
    _contactPersonController =
        TextEditingController(text: app?.contactPerson ?? '');
    _contactEmailController =
        TextEditingController(text: app?.contactEmail ?? '');
    _notesController = TextEditingController(text: app?.notes ?? '');

    // Add debounced save listeners to all application fields
    _companyController.addListener(_onApplicationFieldChanged);
    _positionController.addListener(_onApplicationFieldChanged);
    _locationController.addListener(_onApplicationFieldChanged);
    _jobUrlController.addListener(_onApplicationFieldChanged);
    _salaryController.addListener(_onApplicationFieldChanged);
    _contactPersonController.addListener(_onApplicationFieldChanged);
    _contactEmailController.addListener(_onApplicationFieldChanged);
    _notesController.addListener(_onApplicationFieldChanged);
  }

  @override
  void didUpdateWidget(JobCvEditorWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Update CV data if it changed
    if (widget.cvData != oldWidget.cvData) {
      setState(() {
        _cvData = widget.cvData;
      });
    }

    // Update application details controllers if application context changed
    if (widget.applicationContext != oldWidget.applicationContext) {
      final app = widget.applicationContext;

      // Remove listeners temporarily to avoid triggering saves
      _companyController.removeListener(_onApplicationFieldChanged);
      _positionController.removeListener(_onApplicationFieldChanged);
      _locationController.removeListener(_onApplicationFieldChanged);
      _jobUrlController.removeListener(_onApplicationFieldChanged);
      _salaryController.removeListener(_onApplicationFieldChanged);
      _contactPersonController.removeListener(_onApplicationFieldChanged);
      _contactEmailController.removeListener(_onApplicationFieldChanged);
      _notesController.removeListener(_onApplicationFieldChanged);

      // Update controller values
      _companyController.text = app?.company ?? '';
      _positionController.text = app?.position ?? '';
      _locationController.text = app?.location ?? '';
      _jobUrlController.text = app?.jobUrl ?? '';
      _salaryController.text = app?.salary ?? '';
      _contactPersonController.text = app?.contactPerson ?? '';
      _contactEmailController.text = app?.contactEmail ?? '';
      _notesController.text = app?.notes ?? '';

      // Re-add listeners
      _companyController.addListener(_onApplicationFieldChanged);
      _positionController.addListener(_onApplicationFieldChanged);
      _locationController.addListener(_onApplicationFieldChanged);
      _jobUrlController.addListener(_onApplicationFieldChanged);
      _salaryController.addListener(_onApplicationFieldChanged);
      _contactPersonController.addListener(_onApplicationFieldChanged);
      _contactEmailController.addListener(_onApplicationFieldChanged);
      _notesController.addListener(_onApplicationFieldChanged);
    }

    // Update cover letter controllers if the cover letter data changed
    if (widget.coverLetter != oldWidget.coverLetter) {
      final newCoverLetter = widget.coverLetter as JobCoverLetter?;
      _jobCoverLetter = newCoverLetter;

      // Update controller text without triggering listeners
      _recipientNameController.removeListener(_updateCoverLetter);
      _recipientTitleController.removeListener(_updateCoverLetter);
      _subjectController.removeListener(_updateCoverLetter);
      _greetingController.removeListener(_updateCoverLetter);
      _bodyController.removeListener(_updateCoverLetter);
      _closingController.removeListener(_updateCoverLetter);

      _recipientNameController.text = newCoverLetter?.recipientName ??
          widget.applicationContext?.contactPerson ??
          '';
      _recipientTitleController.text = newCoverLetter?.recipientTitle ?? '';
      _subjectController.text = newCoverLetter?.subject ?? '';
      _greetingController.text =
          newCoverLetter?.greeting ?? 'Dear Hiring Manager,';
      _bodyController.text = newCoverLetter?.body ?? '';
      _closingController.text = newCoverLetter?.closing ?? 'Sincerely,';

      // Re-add listeners
      _recipientNameController.addListener(_updateCoverLetter);
      _recipientTitleController.addListener(_updateCoverLetter);
      _subjectController.addListener(_updateCoverLetter);
      _greetingController.addListener(_updateCoverLetter);
      _bodyController.addListener(_updateCoverLetter);
      _closingController.addListener(_updateCoverLetter);
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _recipientNameController.dispose();
    _recipientTitleController.dispose();
    _subjectController.dispose();
    _greetingController.dispose();
    _bodyController.dispose();
    _closingController.dispose();
    _companyController.dispose();
    _positionController.dispose();
    _locationController.dispose();
    _jobUrlController.dispose();
    _salaryController.dispose();
    _contactPersonController.dispose();
    _contactEmailController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  /// Update CV data and notify parent
  void _updateCvData(JobCvData updatedData) {
    _cvData = updatedData;
    widget.onChanged(updatedData);
  }

  /// Update cover letter instance when text changes
  void _updateCoverLetter() {
    if (_jobCoverLetter == null) return;

    final updatedCoverLetter = _jobCoverLetter!.copyWith(
      recipientName: _recipientNameController.text.isEmpty
          ? null
          : _recipientNameController.text,
      recipientTitle: _recipientTitleController.text.isEmpty
          ? null
          : _recipientTitleController.text,
      subject: _subjectController.text,
      greeting: _greetingController.text,
      body: _bodyController.text,
      closing: _closingController.text,
    );

    setState(() {
      _jobCoverLetter = updatedCoverLetter;
    });

    // Auto-save to storage
    _saveCoverLetter(updatedCoverLetter);
  }

  /// Save cover letter to storage
  Future<void> _saveCoverLetter(JobCoverLetter coverLetter) async {
    final folderPath = widget.applicationContext?.folderPath;
    if (folderPath == null) return;

    try {
      await _storage.saveJobCoverLetter(folderPath, coverLetter);
      debugPrint('[CoverLetter] Auto-saved to $folderPath');
    } catch (e) {
      debugPrint('[CoverLetter] Failed to auto-save: $e');
    }
  }

  /// Centralized handler for application detail field changes
  /// Saves immediately like Personal tab (no snackbar shown)
  void _onApplicationFieldChanged() {
    final application = widget.applicationContext;
    if (application == null) return;

    // Build updated application from all controller values
    final updatedApplication = application.copyWith(
      company: _companyController.text.isEmpty
          ? application.company
          : _companyController.text,
      position: _positionController.text.isEmpty
          ? application.position
          : _positionController.text,
      location:
          _locationController.text.isEmpty ? null : _locationController.text,
      jobUrl: _jobUrlController.text.isEmpty ? null : _jobUrlController.text,
      salary: _salaryController.text.isEmpty ? null : _salaryController.text,
      contactPerson: _contactPersonController.text.isEmpty
          ? null
          : _contactPersonController.text,
      contactEmail: _contactEmailController.text.isEmpty
          ? null
          : _contactEmailController.text,
      notes: _notesController.text.isEmpty ? null : _notesController.text,
    );

    // Call the parent's callback (saves quietly, no snackbar)
    widget.onApplicationChanged?.call(updatedApplication);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        // Modern tab bar
        // Modern tab bar
        Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            border: Border(
              bottom: BorderSide(
                color: theme.dividerColor.withValues(alpha: 0.05),
                width: 1,
              ),
            ),
          ),
          child: TabBar(
            controller: _tabController,
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            labelStyle: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
            unselectedLabelStyle: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w500,
              fontSize: 13,
            ),
            labelColor: theme.colorScheme.primary,
            unselectedLabelColor: theme.textTheme.bodySmall?.color,
            indicator: UnderlineTabIndicator(
              borderSide: BorderSide(
                color: theme.colorScheme.primary,
                width: 3,
              ),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(3)),
            ),
            dividerColor: Colors.transparent,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            tabs: [
              _buildTab(Icons.info_outline, 'Details'),
              _buildTab(Icons.person_outline, 'Personal'),
              _buildTab(Icons.work_outline, 'Experience'),
              _buildTab(Icons.stars_outlined, 'Skills'),
              _buildTab(Icons.language_outlined, 'Languages'),
              _buildTab(Icons.interests_outlined, 'Interests'),
              _buildTab(Icons.school_outlined, 'Education'),
              _buildTab(Icons.email_outlined, 'Cover Letter'),
            ],
          ),
        ),

        // Tab content
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildApplicationDetailsTab(),
              _buildPersonalInfoTab(),
              _buildExperienceTab(),
              _buildSkillsTab(),
              _buildLanguagesTab(),
              _buildInterestsTab(),
              _buildEducationTab(),
              _buildCoverLetterTab(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTab(IconData icon, String label) {
    return Tab(
      height: 48,
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

  /// Application Details Tab - Edit application metadata
  Widget _buildApplicationDetailsTab() {
    final theme = Theme.of(context);
    final application = widget.applicationContext;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          UIUtils.buildSectionHeader(
            context,
            title: 'Application Details',
            subtitle: 'Manage status, dates, and notes for this application',
            icon: Icons.info_outline,
          ),
          const SizedBox(height: AppSpacing.lg),

          // Status Section
          AppCard(
            title: 'Application Status',
            icon: Icons.flag_outlined,
            children: [
              DropdownButtonFormField<ApplicationStatus>(
                initialValue: application?.status ?? ApplicationStatus.draft,
                decoration: const InputDecoration(
                  labelText: 'Status',
                  prefixIcon: Icon(Icons.flag_outlined, size: 20),
                ),
                items: ApplicationStatus.values.map((status) {
                  return DropdownMenuItem(
                    value: status,
                    child: Text(status.name.toUpperCase()),
                  );
                }).toList(),
                onChanged: (newStatus) {
                  if (newStatus != null && application != null) {
                    widget.onApplicationChanged?.call(
                      application.copyWith(status: newStatus),
                    );
                  }
                },
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),

          // Dates Section
          AppCard(
            title: 'Important Dates',
            icon: Icons.calendar_today_outlined,
            children: [
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.calendar_today,
                      size: 18, color: theme.colorScheme.primary),
                ),
                title: Text('Application Date',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    )),
                subtitle: Text(
                  application?.applicationDate != null
                      ? DateFormat('MMMM dd, yyyy')
                          .format(application!.applicationDate!)
                      : 'Not set',
                ),
                trailing: const Icon(Icons.edit, size: 18),
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: application?.applicationDate ?? DateTime.now(),
                    firstDate: DateTime(2000),
                    lastDate: DateTime.now(),
                  );
                  if (date != null && application != null) {
                    widget.onApplicationChanged?.call(
                      application.copyWith(applicationDate: date),
                    );
                  }
                },
              ),
              if (application?.interviewDate != null ||
                  application?.status == ApplicationStatus.interviewing) ...[
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Divider(height: 1),
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.orange.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child:
                        const Icon(Icons.event, size: 18, color: Colors.orange),
                  ),
                  title: Text('Interview Date',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      )),
                  subtitle: Text(
                    application?.interviewDate != null
                        ? DateFormat('MMMM dd, yyyy')
                            .format(application!.interviewDate!)
                        : 'Not scheduled',
                  ),
                  trailing: const Icon(Icons.edit, size: 18),
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: application?.interviewDate ?? DateTime.now(),
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (date != null && application != null) {
                      widget.onApplicationChanged?.call(
                        application.copyWith(interviewDate: date),
                      );
                    }
                  },
                ),
              ],
            ],
          ),
          const SizedBox(height: AppSpacing.md),

          // Contact & Details Section
          AppCard(
            title: 'Job Details',
            icon: Icons.business_outlined,
            children: [
              // Company field
              TextFormField(
                controller: _companyController,
                decoration: const InputDecoration(
                  labelText: 'Company',
                  hintText: 'Company name',
                  prefixIcon: Icon(Icons.business),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              // Position field
              TextFormField(
                controller: _positionController,
                decoration: const InputDecoration(
                  labelText: 'Position',
                  hintText: 'Job title',
                  prefixIcon: Icon(Icons.work_outline),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              // Language field (read-only)
              TextFormField(
                initialValue: application?.baseLanguage.label ?? 'English',
                decoration: const InputDecoration(
                  labelText: 'Application Language',
                  prefixIcon: Icon(Icons.language_outlined),
                  helperText: 'Language cannot be changed after creation',
                ),
                enabled: false,
              ),
              const SizedBox(height: AppSpacing.md),
              TextFormField(
                controller: _locationController,
                decoration: const InputDecoration(
                  labelText: 'Location',
                  hintText: 'City, Country',
                  prefixIcon: Icon(Icons.location_on_outlined),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              TextFormField(
                controller: _jobUrlController,
                decoration: const InputDecoration(
                  labelText: 'Job Posting URL',
                  hintText: 'https://...',
                  prefixIcon: Icon(Icons.link),
                ),
                keyboardType: TextInputType.url,
              ),
              const SizedBox(height: AppSpacing.md),
              TextFormField(
                controller: _salaryController,
                decoration: const InputDecoration(
                  labelText: 'Salary Range',
                  hintText: 'e.g., \$80k - \$100k',
                  prefixIcon: Icon(Icons.attach_money),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              TextFormField(
                controller: _contactPersonController,
                decoration: const InputDecoration(
                  labelText: 'Contact Person',
                  hintText: 'Hiring Manager Name',
                  prefixIcon: Icon(Icons.person_outline),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              TextFormField(
                controller: _contactEmailController,
                decoration: const InputDecoration(
                  labelText: 'Contact Email',
                  hintText: 'hr@company.com',
                  prefixIcon: Icon(Icons.email_outlined),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),

          // Notes Section
          AppCard(
            title: 'Notes',
            icon: Icons.note_outlined,
            children: [
              TextFormField(
                controller: _notesController,
                decoration: const InputDecoration(
                  labelText: 'Application Notes',
                  hintText: 'Add any notes about this application...',
                  prefixIcon: Icon(Icons.note_alt_outlined),
                  alignLabelWithHint: true,
                ),
                maxLines: 5,
                // No onChanged - we save on focus loss and during debounce
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Profile Summary Section - Job-specific tailored summary
  Widget _buildProfessionalSummarySection() {
    final theme = Theme.of(context);
    final position = widget.applicationContext?.position ?? 'this role';
    final company = widget.applicationContext?.company ?? 'the company';

    return AppCard(
      title: 'Profile Summary',
      icon: Icons.stars_outlined,
      children: [
        Text(
          'Tailor your summary for $position at $company',
          style: theme.textTheme.bodySmall,
        ),
        const SizedBox(height: AppSpacing.md),
        TextFormField(
          key: const Key('professional_summary'),
          initialValue: _cvData.professionalSummary,
          maxLines: 6,
          decoration: const InputDecoration(
            hintText:
                'Write a compelling 2-3 sentence summary highlighting your key strengths and how they align with this specific role...\n\nExample: Experienced software engineer with 5+ years in full-stack development, specializing in React and Node.js. Proven track record of delivering scalable solutions and leading cross-functional teams.',
          ),
          onChanged: (value) {
            _updateCvData(_cvData.copyWith(professionalSummary: value));
          },
        ),
      ],
    );
  }

  Widget _buildPersonalInfoTab() {
    final theme = Theme.of(context);
    final info = _cvData.personalInfo;
    final userData = context.watch<UserDataProvider>();
    final masterProfile = widget.applicationContext != null
        ? userData
            .getProfileForLanguage(widget.applicationContext!.baseLanguage)
        : null;
    final masterPicturePath = masterProfile?.personalInfo?.profilePicturePath;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          UIUtils.buildSectionHeader(
            context,
            title: 'Personal Information',
            subtitle: 'Customize contact details for this application',
            icon: Icons.person_outline,
          ),
          const SizedBox(height: AppSpacing.lg),
          Center(
            child: ProfilePicturePicker(
              imagePath: info?.profilePicturePath,
              masterProfilePicturePath: masterPicturePath,
              size: 110,
              placeholderInitial:
                  info?.fullName.isNotEmpty ?? false ? info!.fullName[0] : null,
              backgroundColor: theme.colorScheme.primary,
              onImageSelected: (selectedPath) =>
                  _handleProfilePictureSelected(selectedPath),
              onImageRemoved: () => _handleProfilePictureRemoved(),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          AppCard(
            title: 'Contact Details',
            icon: Icons.contact_mail_outlined,
            children: [
              // Full Name
              TextFormField(
                initialValue: info?.fullName ?? '',
                decoration: const InputDecoration(
                  labelText: 'Full Name *',
                  hintText: 'John Doe',
                  prefixIcon: Icon(Icons.person_outline),
                ),
                onChanged: (value) {
                  _updateCvData(_cvData.copyWith(
                    personalInfo: (info ?? PersonalInfo(fullName: '')).copyWith(
                      fullName: value,
                    ),
                  ));
                },
              ),
              const SizedBox(height: AppSpacing.md),

              // Job Title
              TextFormField(
                initialValue: info?.jobTitle ?? '',
                decoration: const InputDecoration(
                  labelText: 'Job Title',
                  hintText: 'Senior Software Engineer',
                  prefixIcon: Icon(Icons.work_outline),
                ),
                onChanged: (value) {
                  _updateCvData(_cvData.copyWith(
                    personalInfo: (info ?? PersonalInfo(fullName: '')).copyWith(
                      jobTitle: value.isEmpty ? null : value,
                    ),
                  ));
                },
              ),
              const SizedBox(height: AppSpacing.md),

              // Email
              TextFormField(
                initialValue: info?.email ?? '',
                decoration: const InputDecoration(
                  labelText: 'Email',
                  hintText: 'john.doe@example.com',
                  prefixIcon: Icon(Icons.email_outlined),
                ),
                keyboardType: TextInputType.emailAddress,
                onChanged: (value) {
                  _updateCvData(_cvData.copyWith(
                    personalInfo: (info ?? PersonalInfo(fullName: '')).copyWith(
                      email: value.isEmpty ? null : value,
                    ),
                  ));
                },
              ),
              const SizedBox(height: AppSpacing.md),

              // Phone
              TextFormField(
                initialValue: info?.phone ?? '',
                decoration: const InputDecoration(
                  labelText: 'Phone',
                  hintText: '+1 (555) 123-4567',
                  prefixIcon: Icon(Icons.phone_outlined),
                ),
                keyboardType: TextInputType.phone,
                onChanged: (value) {
                  _updateCvData(_cvData.copyWith(
                    personalInfo: (info ?? PersonalInfo(fullName: '')).copyWith(
                      phone: value.isEmpty ? null : value,
                    ),
                  ));
                },
              ),
              const SizedBox(height: AppSpacing.md),

              // Address
              TextFormField(
                initialValue: info?.address ?? '',
                decoration: const InputDecoration(
                  labelText: 'Address',
                  hintText: '123 Main Street',
                  prefixIcon: Icon(Icons.home_outlined),
                ),
                onChanged: (value) {
                  _updateCvData(_cvData.copyWith(
                    personalInfo: (info ?? PersonalInfo(fullName: '')).copyWith(
                      address: value.isEmpty ? null : value,
                    ),
                  ));
                },
              ),
              const SizedBox(height: AppSpacing.md),

              // City & Country Row
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      initialValue: info?.city ?? '',
                      decoration: const InputDecoration(
                        labelText: 'City',
                        hintText: 'New York',
                        prefixIcon: Icon(Icons.location_city_outlined),
                      ),
                      onChanged: (value) {
                        _updateCvData(_cvData.copyWith(
                          personalInfo:
                              (info ?? PersonalInfo(fullName: '')).copyWith(
                            city: value.isEmpty ? null : value,
                          ),
                        ));
                      },
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: TextFormField(
                      initialValue: info?.country ?? '',
                      decoration: const InputDecoration(
                        labelText: 'Country',
                        hintText: 'USA',
                        prefixIcon: Icon(Icons.public_outlined),
                      ),
                      onChanged: (value) {
                        _updateCvData(_cvData.copyWith(
                          personalInfo:
                              (info ?? PersonalInfo(fullName: '')).copyWith(
                            country: value.isEmpty ? null : value,
                          ),
                        ));
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),

              // LinkedIn
              TextFormField(
                initialValue: info?.linkedin ?? '',
                decoration: const InputDecoration(
                  labelText: 'LinkedIn',
                  hintText: 'linkedin.com/in/johndoe',
                  prefixIcon: Icon(Icons.link_outlined),
                ),
                keyboardType: TextInputType.url,
                onChanged: (value) {
                  _updateCvData(_cvData.copyWith(
                    personalInfo: (info ?? PersonalInfo(fullName: '')).copyWith(
                      linkedin: value.isEmpty ? null : value,
                    ),
                  ));
                },
              ),
              const SizedBox(height: AppSpacing.md),

              // Website
              TextFormField(
                initialValue: info?.website ?? '',
                decoration: const InputDecoration(
                  labelText: 'Website',
                  hintText: 'johndoe.com',
                  prefixIcon: Icon(Icons.language_outlined),
                ),
                keyboardType: TextInputType.url,
                onChanged: (value) {
                  _updateCvData(_cvData.copyWith(
                    personalInfo: (info ?? PersonalInfo(fullName: '')).copyWith(
                      website: value.isEmpty ? null : value,
                    ),
                  ));
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildExperienceTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Profile Summary Section
          _buildProfessionalSummarySection(),
          const SizedBox(height: AppSpacing.lg),

          // Work Experience Header
          UIUtils.buildSectionHeader(
            context,
            title: 'Work Experience',
            subtitle:
                '${_cvData.experiences.length} ${_cvData.experiences.length == 1 ? 'entry' : 'entries'} tailored for this role',
            icon: Icons.work_outline,
            action: AppCardActionButton(
              onPressed: _addExperience,
              icon: Icons.add,
              label: 'Add Entry',
              isFilled: true,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          if (_cvData.experiences.isEmpty)
            _buildEmptyState(
              icon: Icons.work_outline,
              title: 'No work experience yet',
              subtitle:
                  'Add your professional experience to showcase your career journey',
            )
          else
            ..._cvData.experiences.asMap().entries.map((entry) {
              final index = entry.key;
              final exp = entry.value;
              return _buildExperienceCard(exp, index);
            }),
        ],
      ),
    );
  }

  Widget _buildExperienceCard(WorkExperience exp, int index) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: AppCardContainer(
        padding: EdgeInsets.zero,
        child: InkWell(
          onTap: () => _editExperience(index),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            exp.position,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            exp.company,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.edit_outlined, size: 20),
                      onPressed: () => _editExperience(index),
                      tooltip: 'Edit',
                    ),
                    IconButton(
                      icon: Icon(Icons.delete_outline,
                          size: 20, color: theme.colorScheme.error),
                      onPressed: () => _deleteExperience(index),
                      tooltip: 'Delete',
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    if (exp.location != null) ...[
                      Icon(Icons.location_on_outlined,
                          size: 16, color: theme.textTheme.bodySmall?.color),
                      const SizedBox(width: 4),
                      Text(exp.location!, style: theme.textTheme.bodySmall),
                      const SizedBox(width: 16),
                    ],
                    Icon(Icons.calendar_today_outlined,
                        size: 16, color: theme.textTheme.bodySmall?.color),
                    const SizedBox(width: 4),
                    Text(
                      '${DateFormat('MMM yyyy').format(exp.startDate)} - ${exp.endDate != null ? DateFormat('MMM yyyy').format(exp.endDate!) : 'Present'}',
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
                if (exp.description != null && exp.description!.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(
                    exp.description!,
                    style: theme.textTheme.bodyMedium,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEducationTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          UIUtils.buildSectionHeader(
            context,
            title: 'Education',
            subtitle:
                '${_cvData.education.length} ${_cvData.education.length == 1 ? 'entry' : 'entries'} available',
            icon: Icons.school_outlined,
            action: AppCardActionButton(
              onPressed: _addEducation,
              icon: Icons.add,
              label: 'Add Entry',
              isFilled: true,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          if (_cvData.education.isEmpty)
            _buildEmptyState(
              icon: Icons.school_outlined,
              title: 'No education yet',
              subtitle: 'Add your educational background and qualifications',
            )
          else
            ..._cvData.education.asMap().entries.map((entry) {
              final index = entry.key;
              final edu = entry.value;
              return _buildEducationCard(edu, index);
            }),
        ],
      ),
    );
  }

  Widget _buildEducationCard(Education edu, int index) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: AppCardContainer(
        padding: EdgeInsets.zero,
        child: InkWell(
          onTap: () => _editEducation(index),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            edu.degree,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            edu.institution,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.edit_outlined, size: 20),
                      onPressed: () => _editEducation(index),
                      tooltip: 'Edit',
                    ),
                    IconButton(
                      icon: Icon(Icons.delete_outline,
                          size: 20, color: theme.colorScheme.error),
                      onPressed: () => _deleteEducation(index),
                      tooltip: 'Delete',
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.calendar_today_outlined,
                        size: 16, color: theme.textTheme.bodySmall?.color),
                    const SizedBox(width: 4),
                    Text(
                      '${DateFormat('MMM yyyy').format(edu.startDate)} - ${edu.endDate != null ? DateFormat('MMM yyyy').format(edu.endDate!) : 'Present'}',
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSkillsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          UIUtils.buildSectionHeader(
            context,
            title: 'Skills',
            subtitle: 'Add relevant skills for this position',
            icon: Icons.stars_outlined,
            action: AppCardActionButton(
              onPressed: _addSkill,
              icon: Icons.add,
              label: 'Add Skill',
              isFilled: true,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          SkillChipEditor(
            skills: _cvData.skills,
            onChanged: (skills) {
              _updateCvData(_cvData.copyWith(skills: skills));
            },
            onEditRequested: _editSkill,
            showCategories: true,
            hideAddSection: true,
          ),
        ],
      ),
    );
  }

  Widget _buildLanguagesTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          UIUtils.buildSectionHeader(
            context,
            title: 'Languages',
            subtitle: 'Add languages and specify your proficiency level',
            icon: Icons.language_outlined,
            action: AppCardActionButton(
              onPressed: _addLanguage,
              icon: Icons.add,
              label: 'Add Language',
              isFilled: true,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          if (_cvData.languages.isEmpty)
            _buildEmptyState(
              icon: Icons.language_outlined,
              title: 'No languages added',
              subtitle: 'Add languages to showcase your communication skills',
            )
          else
            ..._cvData.languages.asMap().entries.map((entry) {
              final index = entry.key;
              final lang = entry.value;
              final theme = Theme.of(context);
              return Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.md),
                child: AppCardContainer(
                  padding: EdgeInsets.zero,
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: theme.colorScheme.primaryContainer,
                      child: Icon(
                        Icons.translate,
                        color: theme.colorScheme.onPrimaryContainer,
                        size: 20,
                      ),
                    ),
                    title: Text(
                      lang.name,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    subtitle: Text(
                      lang.proficiency.displayName,
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit_outlined, size: 20),
                          onPressed: () => _editLanguage(index),
                          tooltip: 'Edit',
                        ),
                        IconButton(
                          icon: Icon(
                            Icons.delete_outline,
                            size: 20,
                            color: theme.colorScheme.error,
                          ),
                          onPressed: () => _deleteLanguage(index),
                          tooltip: 'Delete',
                        ),
                      ],
                    ),
                    onTap: () => _editLanguage(index),
                  ),
                ),
              );
            }),
        ],
      ),
    );
  }

  Widget _buildInterestsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          UIUtils.buildSectionHeader(
            context,
            title: 'Interests',
            subtitle: 'Add personal interests to your CV',
            icon: Icons.interests_outlined,
            action: AppCardActionButton(
              onPressed: _addInterest,
              icon: Icons.add,
              label: 'Add Interest',
              isFilled: true,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          InterestChipEditor(
            interests: _cvData.interests,
            onChanged: (interests) {
              _updateCvData(_cvData.copyWith(interests: interests));
            },
            onEditRequested: _editInterest,
            hideAddSection: true,
          ),
        ],
      ),
    );
  }

  Widget _buildCoverLetterTab() {
    final theme = Theme.of(context);
    final application = widget.applicationContext;
    final wordCount = _bodyController.text
        .trim()
        .split(RegExp(r'\s+'))
        .where((word) => word.isNotEmpty)
        .length;
    final charCount = _bodyController.text.length;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          UIUtils.buildSectionHeader(
            context,
            title: 'Cover Letter',
            subtitle: 'Personalize your cover letter for this application',
            icon: Icons.email_outlined,
          ),
          const SizedBox(height: AppSpacing.lg),

          // Recipient Information Card
          AppCard(
            title: 'Recipient Information',
            icon: Icons.person_outline,
            children: [
              TextFormField(
                controller: _recipientNameController,
                decoration: const InputDecoration(
                  labelText: 'Recipient Name',
                  hintText: 'e.g., Jane Smith',
                  prefixIcon: Icon(Icons.person_outline),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              TextFormField(
                controller: _recipientTitleController,
                decoration: const InputDecoration(
                  labelText: 'Recipient Title',
                  hintText: 'e.g., HR Manager',
                  prefixIcon: Icon(Icons.badge_outlined),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              TextFormField(
                controller: _subjectController,
                decoration: InputDecoration(
                  labelText: widget.applicationContext?.baseLanguage ==
                          DocumentLanguage.de
                      ? 'Betreff'
                      : 'Subject',
                  hintText: widget.applicationContext?.baseLanguage ==
                          DocumentLanguage.de
                      ? 'Bewerbung als ...'
                      : 'Application for ...',
                  prefixIcon: const Icon(Icons.subject_outlined),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              TextFormField(
                initialValue: application?.company ?? '',
                decoration: const InputDecoration(
                  labelText: 'Company Name',
                  prefixIcon: Icon(Icons.business_outlined),
                ),
                enabled: false,
              ),
              const SizedBox(height: AppSpacing.md),
              TextFormField(
                initialValue: application?.position ?? '',
                decoration: const InputDecoration(
                  labelText: 'Position',
                  prefixIcon: Icon(Icons.work_outline),
                ),
                enabled: false,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),

          // Letter Content Card
          AppCard(
            title: 'Letter Content',
            icon: Icons.article_outlined,
            children: [
              TextFormField(
                controller: _greetingController,
                decoration: const InputDecoration(
                  labelText: 'Greeting',
                  hintText: 'Dear [Name],',
                  prefixIcon: Icon(Icons.waving_hand_outlined),
                ),
              ),
              const SizedBox(height: AppSpacing.md),

              // Placeholder guide
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: theme.colorScheme.primary.withValues(alpha: 0.1),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.lightbulb_outline,
                      size: 20,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Use ==COMPANY== and ==POSITION== as placeholders. They will be replaced automatically.',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),

              TextFormField(
                controller: _bodyController,
                decoration: const InputDecoration(
                  labelText: 'Letter Body',
                  hintText:
                      'Write your cover letter here...\n\nExample:\nI am writing to express my interest in the ==POSITION== position at ==COMPANY==...',
                  alignLabelWithHint: true,
                ),
                maxLines: 15,
                minLines: 10,
              ),
              const SizedBox(height: 8),

              // Word and character count
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    '$charCount chars • $wordCount words',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.textTheme.bodySmall?.color
                          ?.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),

              TextFormField(
                controller: _closingController,
                decoration: const InputDecoration(
                  labelText: 'Closing',
                  hintText: 'e.g., Best regards,',
                  prefixIcon: Icon(Icons.edit_note_outlined),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Empty state widget
  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return UIUtils.buildEmptyState(
      context,
      icon: icon,
      title: title,
      message: subtitle,
    );
  }

  /// Add new experience
  Future<void> _addExperience() async {
    final newExp = await showDialog<WorkExperience>(
      context: context,
      builder: (context) => const ExperienceEditDialog(),
    );

    if (newExp != null) {
      final updated = _cvData.copyWith(
        experiences: [..._cvData.experiences, newExp],
      );
      _updateCvData(updated);
    }
  }

  /// Edit existing experience
  Future<void> _editExperience(int index) async {
    final exp = _cvData.experiences[index];
    final updatedExp = await showDialog<WorkExperience>(
      context: context,
      builder: (context) => ExperienceEditDialog(experience: exp),
    );

    if (updatedExp != null) {
      final experiences = List<WorkExperience>.from(_cvData.experiences);
      experiences[index] = updatedExp;
      _updateCvData(_cvData.copyWith(experiences: experiences));
    }
  }

  /// Delete experience
  Future<void> _deleteExperience(int index) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Experience'),
        content: Text(
          'Are you sure you want to delete "${_cvData.experiences[index].position}" at ${_cvData.experiences[index].company}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final experiences = List<WorkExperience>.from(_cvData.experiences);
      experiences.removeAt(index);
      _updateCvData(_cvData.copyWith(experiences: experiences));
    }
  }

  /// Add new education
  Future<void> _addEducation() async {
    final newEdu = await showDialog<Education>(
      context: context,
      builder: (context) => const EducationEditDialog(),
    );

    if (newEdu != null) {
      final updated = _cvData.copyWith(
        education: [..._cvData.education, newEdu],
      );
      _updateCvData(updated);
    }
  }

  /// Edit existing education
  Future<void> _editEducation(int index) async {
    final edu = _cvData.education[index];
    final updatedEdu = await showDialog<Education>(
      context: context,
      builder: (context) => EducationEditDialog(education: edu),
    );

    if (updatedEdu != null) {
      final education = List<Education>.from(_cvData.education);
      education[index] = updatedEdu;
      _updateCvData(_cvData.copyWith(education: education));
    }
  }

  /// Delete education
  Future<void> _deleteEducation(int index) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Education'),
        content: Text(
          'Are you sure you want to delete "${_cvData.education[index].degree}" from ${_cvData.education[index].institution}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final education = List<Education>.from(_cvData.education);
      education.removeAt(index);
      _updateCvData(_cvData.copyWith(education: education));
    }
  }

  /// Handle profile picture selected
  Future<void> _handleProfilePictureSelected(String selectedPath) async {
    final folderPath = widget.applicationContext?.folderPath;
    if (folderPath == null) {
      debugPrint('[ProfilePicture] No folder path for application');
      return;
    }

    try {
      // Create a unique filename based on the original
      final extension = path.extension(selectedPath);
      final filename = 'profile_picture$extension';
      final targetPath = path.join(folderPath, filename);

      // Copy the selected image to the job application folder
      final sourceFile = File(selectedPath);
      final targetFile = await sourceFile.copy(targetPath);

      debugPrint('[ProfilePicture] Copied to: $targetPath');

      // Update CV data with the new path
      final info = _cvData.personalInfo ?? PersonalInfo(fullName: '');
      _updateCvData(_cvData.copyWith(
        personalInfo: info.copyWith(profilePicturePath: targetFile.path),
      ));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white, size: 18),
                SizedBox(width: 8),
                Text('Profile picture updated'),
              ],
            ),
            backgroundColor: Colors.green.shade600,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      debugPrint('[ProfilePicture] Error copying image: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to set profile picture: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  /// Handle profile picture removed
  void _handleProfilePictureRemoved() {
    final info = _cvData.personalInfo;
    if (info == null) return;

    // Remove the profile picture path
    _updateCvData(_cvData.copyWith(
      personalInfo: info.copyWith(profilePicturePath: ''),
    ));

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white, size: 18),
              SizedBox(width: 8),
              Text('Profile picture removed'),
            ],
          ),
          backgroundColor: Colors.orange.shade600,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  // --- Skill Methods ---
  void _addSkill() async {
    final result = await showDialog<Skill>(
      context: context,
      builder: (context) => const SkillEditDialog(),
    );
    if (result != null) {
      _updateCvData(_cvData.copyWith(skills: [..._cvData.skills, result]));
    }
  }

  void _editSkill(int index) async {
    final result = await showDialog<Skill>(
      context: context,
      builder: (context) => SkillEditDialog(skill: _cvData.skills[index]),
    );
    if (result != null) {
      final updated = List<Skill>.from(_cvData.skills);
      updated[index] = result;
      _updateCvData(_cvData.copyWith(skills: updated));
    }
  }

  void _deleteSkill(int index) async {
    final confirmed = await DialogUtils.showDeleteConfirmation(
      context,
      title: 'Delete Skill',
      message: 'Remove "${_cvData.skills[index].name}" from this CV?',
    );
    if (confirmed == true) {
      final updated = List<Skill>.from(_cvData.skills);
      updated.removeAt(index);
      _updateCvData(_cvData.copyWith(skills: updated));
    }
  }

  // --- Interest Methods ---
  void _addInterest() async {
    final result = await showDialog<Interest>(
      context: context,
      builder: (context) => const InterestEditDialog(),
    );
    if (result != null) {
      _updateCvData(
          _cvData.copyWith(interests: [..._cvData.interests, result]));
    }
  }

  void _editInterest(int index) async {
    final result = await showDialog<Interest>(
      context: context,
      builder: (context) =>
          InterestEditDialog(interest: _cvData.interests[index]),
    );
    if (result != null) {
      final updated = List<Interest>.from(_cvData.interests);
      updated[index] = result;
      _updateCvData(_cvData.copyWith(interests: updated));
    }
  }

  void _deleteInterest(int index) async {
    final confirmed = await DialogUtils.showDeleteConfirmation(
      context,
      title: 'Delete Interest',
      message: 'Remove "${_cvData.interests[index].name}" from this CV?',
    );
    if (confirmed == true) {
      final updated = List<Interest>.from(_cvData.interests);
      updated.removeAt(index);
      _updateCvData(_cvData.copyWith(interests: updated));
    }
  }

  // --- Language Methods ---
  void _addLanguage() async {
    final result = await showDialog<Language>(
      context: context,
      builder: (context) => const LanguageEditDialog(),
    );
    if (result != null) {
      _updateCvData(
          _cvData.copyWith(languages: [..._cvData.languages, result]));
    }
  }

  void _editLanguage(int index) async {
    final result = await showDialog<Language>(
      context: context,
      builder: (context) =>
          LanguageEditDialog(language: _cvData.languages[index]),
    );
    if (result != null) {
      final updated = List<Language>.from(_cvData.languages);
      updated[index] = result;
      _updateCvData(_cvData.copyWith(languages: updated));
    }
  }

  void _deleteLanguage(int index) async {
    final confirmed = await DialogUtils.showDeleteConfirmation(
      context,
      title: 'Delete Language',
      message: 'Remove "${_cvData.languages[index].name}" from this CV?',
    );
    if (confirmed == true) {
      final updated = List<Language>.from(_cvData.languages);
      updated.removeAt(index);
      _updateCvData(_cvData.copyWith(languages: updated));
    }
  }
}
