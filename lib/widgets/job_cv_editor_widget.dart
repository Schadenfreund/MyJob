import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/job_application.dart';
import '../models/job_cv_data.dart';
import '../models/user_data/work_experience.dart';
import '../models/user_data/personal_info.dart';
import '../models/master_profile.dart'; // Contains Education class
import '../models/user_data/skill.dart';
import '../models/user_data/language.dart';
import '../models/user_data/interest.dart';
import '../models/cover_letter_template.dart';
import '../dialogs/experience_edit_dialog.dart';
import '../dialogs/education_edit_dialog.dart';
import '../widgets/skill_chip_editor.dart';
import '../widgets/language_editor.dart';
import '../widgets/interest_chip_editor.dart';
import '../utils/ui_utils.dart';
import '../constants/app_constants.dart';
import '../constants/ui_constants.dart';

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
    super.key,
  });

  final JobCvData cvData;
  final ValueChanged<JobCvData> onChanged;
  final JobApplication? applicationContext;
  final ValueChanged<JobApplication>? onApplicationChanged;

  @override
  State<JobCvEditorWidget> createState() => _JobCvEditorWidgetState();
}

class _JobCvEditorWidgetState extends State<JobCvEditorWidget>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late JobCvData _cvData;
  CoverLetterInstance? _coverLetterInstance;

  // Cover letter text controllers
  late TextEditingController _recipientNameController;
  late TextEditingController _recipientTitleController;
  late TextEditingController _greetingController;
  late TextEditingController _bodyController;
  late TextEditingController _closingController;

  // No additional controllers needed for CV sections

  @override
  void initState() {
    super.initState();
    _cvData = widget.cvData;
    _tabController = TabController(length: 8, vsync: this);

    // Initialize cover letter instance (will load from storage later)
    _initializeCoverLetterInstance();

    // Initialize cover letter controllers
    _recipientNameController = TextEditingController(
      text: _coverLetterInstance?.recipientName ??
          widget.applicationContext?.contactPerson ??
          '',
    );
    _recipientTitleController = TextEditingController(
      text: _coverLetterInstance?.recipientTitle ?? '',
    );
    _greetingController = TextEditingController(
      text: _coverLetterInstance?.greeting ?? 'Dear Hiring Manager,',
    );
    _bodyController = TextEditingController(
      text: _coverLetterInstance?.body ?? '',
    );
    _closingController = TextEditingController(
      text: _coverLetterInstance?.closing ?? 'Sincerely,',
    );

    // Add listeners for auto-save
    _recipientNameController.addListener(_updateCoverLetter);
    _recipientTitleController.addListener(_updateCoverLetter);
    _greetingController.addListener(_updateCoverLetter);
    _bodyController.addListener(_updateCoverLetter);
    _closingController.addListener(_updateCoverLetter);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _recipientNameController.dispose();
    _recipientTitleController.dispose();
    _greetingController.dispose();
    _bodyController.dispose();
    _closingController.dispose();
    super.dispose();
  }

  /// Update CV data and notify parent
  void _updateCvData(JobCvData updatedData) {
    setState(() => _cvData = updatedData);
    widget.onChanged(updatedData);
  }

  /// Initialize cover letter instance
  void _initializeCoverLetterInstance() {
    // TODO: Load from storage when implemented
    // For now, create a new instance if needed
    final app = widget.applicationContext;
    if (app != null) {
      _coverLetterInstance = CoverLetterInstance(
        id: 'cl_${app.id}',
        applicationId: app.id,
        templateId:
            'default', // Will be updated when template selection is implemented
        name: 'Cover Letter for ${app.company}',
        language: app.baseLanguage,
        companyName: app.company,
        jobTitle: app.position,
        recipientName: app.contactPerson,
        greeting: 'Dear Hiring Manager,',
        body: '',
        closing: 'Sincerely,',
        lastModified: DateTime.now(),
      );
    }
  }

  /// Update cover letter instance when text changes
  void _updateCoverLetter() {
    if (_coverLetterInstance == null) return;

    setState(() {
      _coverLetterInstance = _coverLetterInstance!.copyWith(
        recipientName: _recipientNameController.text.trim().isNotEmpty
            ? _recipientNameController.text.trim()
            : null,
        recipientTitle: _recipientTitleController.text.trim().isNotEmpty
            ? _recipientTitleController.text.trim()
            : null,
        greeting: _greetingController.text,
        body: _bodyController.text,
        closing: _closingController.text,
        lastModified: DateTime.now(),
      );
    });

    // TODO: Auto-save to storage
    // For now, just update state
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        // Modern tab bar
        Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: TabBar(
            controller: _tabController,
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            labelColor: theme.colorScheme.primary,
            unselectedLabelColor: theme.colorScheme.onSurface.withOpacity(0.6),
            indicatorColor: theme.colorScheme.primary,
            indicatorWeight: 3,
            tabs: [
              _buildTab(Icons.info_outline, 'Details'),
              _buildTab(Icons.person_outline, 'Personal Info'),
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
      height: 60,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 20),
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
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Icon(Icons.work, color: theme.colorScheme.primary, size: 28),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Application Details',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Manage status, dates, and notes for this application',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Status Section
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Application Status',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<ApplicationStatus>(
                    value: application?.status ?? ApplicationStatus.draft,
                    decoration: const InputDecoration(
                      labelText: 'Status',
                      prefixIcon: Icon(Icons.flag),
                      border: OutlineInputBorder(),
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
            ),
          ),
          const SizedBox(height: 16),

          // Dates Section
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Important Dates',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ListTile(
                    leading: const Icon(Icons.calendar_today),
                    title: const Text('Application Date'),
                    subtitle: Text(
                      application?.applicationDate != null
                          ? DateFormat('MMMM dd, yyyy')
                              .format(application!.applicationDate!)
                          : 'Not set',
                    ),
                    trailing: const Icon(Icons.edit),
                    onTap: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate:
                            application?.applicationDate ?? DateTime.now(),
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
                      application?.status ==
                          ApplicationStatus.interviewing) ...[
                    const Divider(),
                    ListTile(
                      leading: const Icon(Icons.event),
                      title: const Text('Interview Date'),
                      subtitle: Text(
                        application?.interviewDate != null
                            ? DateFormat('MMMM dd, yyyy')
                                .format(application!.interviewDate!)
                            : 'Not scheduled',
                      ),
                      trailing: const Icon(Icons.edit),
                      onTap: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate:
                              application?.interviewDate ?? DateTime.now(),
                          firstDate: DateTime.now(),
                          lastDate:
                              DateTime.now().add(const Duration(days: 365)),
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
            ),
          ),
          const SizedBox(height: 16),

          // Contact & Details Section
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Job Details',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    initialValue: application?.location ?? '',
                    decoration: const InputDecoration(
                      labelText: 'Location',
                      hintText: 'City, Country',
                      prefixIcon: Icon(Icons.location_on),
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (value) {
                      if (application != null) {
                        widget.onApplicationChanged?.call(
                          application.copyWith(
                            location: value.isEmpty ? null : value,
                          ),
                        );
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    initialValue: application?.jobUrl ?? '',
                    decoration: const InputDecoration(
                      labelText: 'Job Posting URL',
                      hintText: 'https://...',
                      prefixIcon: Icon(Icons.link),
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.url,
                    onChanged: (value) {
                      if (application != null) {
                        widget.onApplicationChanged?.call(
                          application.copyWith(
                            jobUrl: value.isEmpty ? null : value,
                          ),
                        );
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    initialValue: application?.salary ?? '',
                    decoration: const InputDecoration(
                      labelText: 'Salary Range',
                      hintText: 'e.g., \$80k - \$100k',
                      prefixIcon: Icon(Icons.attach_money),
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (value) {
                      if (application != null) {
                        widget.onApplicationChanged?.call(
                          application.copyWith(
                            salary: value.isEmpty ? null : value,
                          ),
                        );
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    initialValue: application?.contactPerson ?? '',
                    decoration: const InputDecoration(
                      labelText: 'Contact Person',
                      hintText: 'Hiring Manager Name',
                      prefixIcon: Icon(Icons.person),
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (value) {
                      if (application != null) {
                        widget.onApplicationChanged?.call(
                          application.copyWith(
                            contactPerson: value.isEmpty ? null : value,
                          ),
                        );
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    initialValue: application?.contactEmail ?? '',
                    decoration: const InputDecoration(
                      labelText: 'Contact Email',
                      hintText: 'hr@company.com',
                      prefixIcon: Icon(Icons.email),
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.emailAddress,
                    onChanged: (value) {
                      if (application != null) {
                        widget.onApplicationChanged?.call(
                          application.copyWith(
                            contactEmail: value.isEmpty ? null : value,
                          ),
                        );
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Notes Section
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Notes',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    initialValue: application?.notes ?? '',
                    decoration: const InputDecoration(
                      labelText: 'Application Notes',
                      hintText: 'Add any notes about this application...',
                      prefixIcon: Icon(Icons.note),
                      border: OutlineInputBorder(),
                      alignLabelWithHint: true,
                    ),
                    maxLines: 5,
                    onChanged: (value) {
                      if (application != null) {
                        widget.onApplicationChanged?.call(
                          application.copyWith(
                            notes: value.isEmpty ? null : value,
                          ),
                        );
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Profile Summary Section - Job-specific tailored summary
  Widget _buildProfessionalSummarySection() {
    final theme = Theme.of(context);
    final company = widget.applicationContext?.company ?? 'this company';
    final position = widget.applicationContext?.position ?? 'this position';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.primary.withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.stars,
                color: theme.colorScheme.primary,
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Profile Summary',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Tailor your summary for $position at $company',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextFormField(
            key: const Key('professional_summary'),
            initialValue: _cvData.professionalSummary,
            maxLines: 6,
            decoration: InputDecoration(
              hintText:
                  'Write a compelling 2-3 sentence summary highlighting your key strengths and how they align with this specific role...\n\nExample: Experienced software engineer with 5+ years in full-stack development, specializing in React and Node.js. Proven track record of delivering scalable solutions and leading cross-functional teams.',
              border: const OutlineInputBorder(),
              filled: true,
              fillColor: theme.colorScheme.surface,
            ),
            onChanged: (value) {
              _updateCvData(_cvData.copyWith(professionalSummary: value));
            },
          ),
        ],
      ),
    );
  }

  /// Personal Info Tab - Contact details and basic info
  Widget _buildPersonalInfoTab() {
    final theme = Theme.of(context);
    final info = _cvData.personalInfo;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Icon(Icons.person, color: theme.colorScheme.primary, size: 28),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Personal Information',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Customize contact details for this application',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Full Name
          TextFormField(
            initialValue: info?.fullName ?? '',
            decoration: InputDecoration(
              labelText: 'Full Name *',
              hintText: 'John Doe',
              prefixIcon: Icon(Icons.person_outline),
              border: OutlineInputBorder(),
            ),
            onChanged: (value) {
              _updateCvData(_cvData.copyWith(
                personalInfo: (info ?? PersonalInfo(fullName: '')).copyWith(
                  fullName: value,
                ),
              ));
            },
          ),
          const SizedBox(height: 16),

          // Job Title
          TextFormField(
            initialValue: info?.jobTitle ?? '',
            decoration: InputDecoration(
              labelText: 'Job Title',
              hintText: 'Senior Software Engineer',
              prefixIcon: Icon(Icons.work_outline),
              border: OutlineInputBorder(),
            ),
            onChanged: (value) {
              _updateCvData(_cvData.copyWith(
                personalInfo: (info ?? PersonalInfo(fullName: '')).copyWith(
                  jobTitle: value.isEmpty ? null : value,
                ),
              ));
            },
          ),
          const SizedBox(height: 16),

          // Email
          TextFormField(
            initialValue: info?.email ?? '',
            decoration: InputDecoration(
              labelText: 'Email',
              hintText: 'john.doe@example.com',
              prefixIcon: Icon(Icons.email_outlined),
              border: OutlineInputBorder(),
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
          const SizedBox(height: 16),

          // Phone
          TextFormField(
            initialValue: info?.phone ?? '',
            decoration: InputDecoration(
              labelText: 'Phone',
              hintText: '+1 (555) 123-4567',
              prefixIcon: Icon(Icons.phone_outlined),
              border: OutlineInputBorder(),
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
          const SizedBox(height: 16),

          // Address
          TextFormField(
            initialValue: info?.address ?? '',
            decoration: InputDecoration(
              labelText: 'Address',
              hintText: '123 Main Street',
              prefixIcon: Icon(Icons.home_outlined),
              border: OutlineInputBorder(),
            ),
            onChanged: (value) {
              _updateCvData(_cvData.copyWith(
                personalInfo: (info ?? PersonalInfo(fullName: '')).copyWith(
                  address: value.isEmpty ? null : value,
                ),
              ));
            },
          ),
          const SizedBox(height: 16),

          // City & Country Row
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  initialValue: info?.city ?? '',
                  decoration: InputDecoration(
                    labelText: 'City',
                    hintText: 'New York',
                    prefixIcon: Icon(Icons.location_city_outlined),
                    border: OutlineInputBorder(),
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
              const SizedBox(width: 16),
              Expanded(
                child: TextFormField(
                  initialValue: info?.country ?? '',
                  decoration: InputDecoration(
                    labelText: 'Country',
                    hintText: 'USA',
                    prefixIcon: Icon(Icons.public_outlined),
                    border: OutlineInputBorder(),
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
          const SizedBox(height: 16),

          // LinkedIn
          TextFormField(
            initialValue: info?.linkedin ?? '',
            decoration: InputDecoration(
              labelText: 'LinkedIn',
              hintText: 'linkedin.com/in/johndoe',
              prefixIcon: Icon(Icons.link_outlined),
              border: OutlineInputBorder(),
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
          const SizedBox(height: 16),

          // Website
          TextFormField(
            initialValue: info?.website ?? '',
            decoration: InputDecoration(
              labelText: 'Website',
              hintText: 'johndoe.com',
              prefixIcon: Icon(Icons.language_outlined),
              border: OutlineInputBorder(),
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
    );
  }

  /// Experience tab - Work history with full CRUD
  Widget _buildExperienceTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Profile Summary Section
          _buildProfessionalSummarySection(),
          const SizedBox(height: 32),
          const Divider(),
          const SizedBox(height: 24),

          // Work Experience Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Work Experience',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${_cvData.experiences.length} ${_cvData.experiences.length == 1 ? 'entry' : 'entries'}',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withOpacity(0.6),
                        ),
                  ),
                ],
              ),
              FilledButton.icon(
                onPressed: _addExperience,
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Add Experience'),
              ),
            ],
          ),
          const SizedBox(height: 24),
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

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      child: InkWell(
        onTap: () => _editExperience(index),
        borderRadius: BorderRadius.circular(UIConstants.radiusMedium),
        child: Padding(
          padding: UIConstants.cardPadding,
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
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: theme.colorScheme.primary,
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
                        size: 16,
                        color: theme.colorScheme.onSurface.withOpacity(0.6)),
                    const SizedBox(width: 4),
                    Text(exp.location!, style: theme.textTheme.bodySmall),
                    const SizedBox(width: 16),
                  ],
                  Icon(Icons.calendar_today_outlined,
                      size: 16,
                      color: theme.colorScheme.onSurface.withOpacity(0.6)),
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
    );
  }

  /// Education tab - Educational background with full CRUD
  Widget _buildEducationTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Education',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${_cvData.education.length} ${_cvData.education.length == 1 ? 'entry' : 'entries'}',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withOpacity(0.6),
                        ),
                  ),
                ],
              ),
              FilledButton.icon(
                onPressed: _addEducation,
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Add Education'),
              ),
            ],
          ),
          const SizedBox(height: 24),
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

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
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
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: theme.colorScheme.primary,
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
                      size: 16,
                      color: theme.colorScheme.onSurface.withOpacity(0.6)),
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
    );
  }

  /// Skills tab - Chip-based skills editor
  Widget _buildSkillsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Skills',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            'Add relevant skills for this position',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color:
                      Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                ),
          ),
          const SizedBox(height: 24),
          SkillChipEditor(
            skills: _cvData.skills,
            onChanged: (skills) {
              _updateCvData(_cvData.copyWith(skills: skills));
            },
          ),
        ],
      ),
    );
  }

  /// Languages tab - Language proficiency management
  Widget _buildLanguagesTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Languages',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            'Add languages and specify your proficiency level',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color:
                      Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                ),
          ),
          const SizedBox(height: 24),
          LanguageEditor(
            languages: _cvData.languages,
            onChanged: (languages) {
              _updateCvData(_cvData.copyWith(languages: languages));
            },
          ),
        ],
      ),
    );
  }

  /// Interests tab - Personal interests
  Widget _buildInterestsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Interests',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 24),
          InterestChipEditor(
            interests: _cvData.interests,
            onChanged: (interests) {
              _updateCvData(_cvData.copyWith(interests: interests));
            },
          ),
        ],
      ),
    );
  }

  /// Cover Letter tab - Create and edit cover letter for this application
  Widget _buildCoverLetterTab() {
    final theme = Theme.of(context);
    final application = widget.applicationContext;
    final hasContent = _bodyController.text.isNotEmpty;
    final wordCount = _bodyController.text
        .trim()
        .split(RegExp(r'\s+'))
        .where((word) => word.isNotEmpty)
        .length;
    final charCount = _bodyController.text.length;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Icon(Icons.email, color: theme.colorScheme.primary, size: 28),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Cover Letter',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Personalize your cover letter for this application',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ),
              OutlinedButton.icon(
                onPressed: () {
                  // TODO: Implement template selector
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Template selection coming soon!'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                },
                icon: const Icon(Icons.library_books, size: 18),
                label: const Text('From Template'),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Recipient Information Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.person_outline,
                          color: theme.colorScheme.primary),
                      const SizedBox(width: 8),
                      Text(
                        'Recipient Information',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _recipientNameController,
                    decoration: const InputDecoration(
                      labelText: 'Recipient Name',
                      hintText: 'e.g., Jane Smith',
                      prefixIcon: Icon(Icons.person),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _recipientTitleController,
                    decoration: const InputDecoration(
                      labelText: 'Recipient Title',
                      hintText: 'e.g., HR Manager',
                      prefixIcon: Icon(Icons.badge),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    initialValue: application?.company ?? '',
                    decoration: const InputDecoration(
                      labelText: 'Company Name',
                      prefixIcon: Icon(Icons.business),
                      border: OutlineInputBorder(),
                      enabled: false,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    initialValue: application?.position ?? '',
                    decoration: const InputDecoration(
                      labelText: 'Position',
                      prefixIcon: Icon(Icons.work),
                      border: OutlineInputBorder(),
                      enabled: false,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Letter Content Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.article_outlined,
                          color: theme.colorScheme.primary),
                      const SizedBox(width: 8),
                      Text(
                        'Letter Content',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _greetingController,
                    decoration: const InputDecoration(
                      labelText: 'Greeting',
                      hintText: 'Dear [Name],',
                      prefixIcon: Icon(Icons.waving_hand),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Placeholder guide
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color:
                          theme.colorScheme.primaryContainer.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: theme.colorScheme.primary.withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.lightbulb_outline,
                          size: 18,
                          color: theme.colorScheme.primary,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Use ==COMPANY== and ==POSITION== as placeholders. They will be replaced automatically.',
                            style: theme.textTheme.bodySmall,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  TextFormField(
                    controller: _bodyController,
                    decoration: const InputDecoration(
                      labelText: 'Letter Body',
                      hintText:
                          'Write your cover letter here...\n\nExample:\nI am writing to express my interest in the ==POSITION== position at ==COMPANY==...',
                      border: OutlineInputBorder(),
                      alignLabelWithHint: true,
                    ),
                    maxLines: 15,
                    minLines: 10,
                  ),
                  const SizedBox(height: 8),

                  // Word and character count
                  Row(
                    children: [
                      Icon(
                        Icons.text_fields,
                        size: 14,
                        color:
                            theme.textTheme.bodySmall?.color?.withOpacity(0.6),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '$charCount characters • $wordCount words',
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontSize: 12,
                          color: theme.textTheme.bodySmall?.color
                              ?.withOpacity(0.6),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  TextFormField(
                    controller: _closingController,
                    decoration: const InputDecoration(
                      labelText: 'Closing',
                      hintText: 'e.g., Best regards,',
                      prefixIcon: Icon(Icons.edit_note),
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Preview button
          if (hasContent)
            SizedBox(
              width: double.infinity,
              child: FilledButton.tonalIcon(
                onPressed: () {
                  // TODO: Show PDF preview
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('PDF preview coming soon!'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                },
                icon: const Icon(Icons.picture_as_pdf),
                label: const Text('Preview Cover Letter PDF'),
              ),
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
}
