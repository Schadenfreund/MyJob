import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as path;

import '../models/job_application.dart';
import '../models/job_cv_data.dart';
import '../models/job_cover_letter.dart';
import '../models/template_style.dart';
import '../models/template_customization.dart';
import '../models/cv_data.dart';
import '../models/cv_data.dart' as cv_data;
import '../models/cover_letter.dart';
import '../models/user_data/work_experience.dart';
import '../models/user_data/skill.dart';
import '../constants/app_constants.dart';
import '../services/pdf_service.dart';
import '../services/storage_service.dart';
import '../widgets/pdf_editor/template_edit_panel.dart';
import 'base_template_pdf_preview_dialog.dart';

/// PDF preview and editor for job applications
///
/// This dialog extends the base PDF editor to work with job-specific data,
/// allowing users to customize both the PDF appearance and the content
/// for individual job applications.
class JobApplicationPdfDialog extends BaseTemplatePdfPreviewDialog {
  const JobApplicationPdfDialog({
    required this.application,
    required this.cvData,
    this.coverLetter,
    required this.isCV,
    super.templateStyle,
    super.templateCustomization,
    super.key,
  });

  final JobApplication application;
  final JobCvData cvData;
  final JobCoverLetter? coverLetter;
  final bool isCV; // true = CV, false = Cover Letter

  @override
  State<JobApplicationPdfDialog> createState() =>
      _JobApplicationPdfDialogState();

  @override
  TemplateStyle getDefaultStyle() => TemplateStyle.defaultStyle;
}

class _JobApplicationPdfDialogState
    extends BaseTemplatePdfPreviewDialogState<JobApplicationPdfDialog> {
  final StorageService _storage = StorageService.instance;

  @override
  void initState() {
    super.initState();

    // CRITICAL: Set language IMMEDIATELY (synchronously) to prevent wrong language on first open
    final correctLanguage =
        _documentLanguageToCvLanguage(widget.application.baseLanguage);
    controller.updateCustomization(
      controller.customization.copyWith(language: correctLanguage),
    );

    // Then load saved PDF settings if they exist (async - updates other settings)
    _loadSavedSettings();

    // Listen to PDF settings changes to auto-save
    controller.addListener(_onPdfSettingsChanged);
  }

  /// Load saved PDF settings from job folder
  Future<void> _loadSavedSettings() async {
    if (widget.application.folderPath == null) return;

    try {
      final settings = await _storage.loadJobPdfSettings(
        widget.application.folderPath!,
      );

      if (settings != null && mounted) {
        final (style, customization) = settings;

        if (style != null && customization != null) {
          controller.updateStyle(style);
          // Language is already set in initState, just load other settings
          // But ensure it stays correct by overriding any saved wrong language
          final updatedCustomization = customization.copyWith(
            language:
                _documentLanguageToCvLanguage(widget.application.baseLanguage),
          );
          controller.updateCustomization(updatedCustomization);
        }
        debugPrint('[PDF Dialog] Loaded saved settings');
      }
      // No else needed - language already set in initState
    } catch (e) {
      debugPrint('[PDF Dialog] No saved settings or error loading: $e');
      // Language already set in initState, no action needed
    }
  }

  /// Convert DocumentLanguage to CvLanguage
  CvLanguage _documentLanguageToCvLanguage(DocumentLanguage docLang) {
    // DocumentLanguage.de = German document
    // DocumentLanguage.en = English document
    switch (docLang) {
      case DocumentLanguage.de:
        return CvLanguage.german; // German app → German PDF
      case DocumentLanguage.en:
        return CvLanguage.english; // English app → English PDF
    }
  }

  @override
  void dispose() {
    controller.removeListener(_onPdfSettingsChanged);
    super.dispose();
  }

  /// Save PDF settings whenever they change
  void _onPdfSettingsChanged() {
    _savePdfSettings();
  }

  /// Save template style and customization to job folder
  Future<void> _savePdfSettings() async {
    if (widget.application.folderPath == null) return;

    try {
      // Save both style and customization
      await _storage.saveJobPdfSettings(
        widget.application.folderPath!,
        selectedStyle,
        controller.customization,
      );
    } catch (e) {
      debugPrint('Failed to save PDF settings: $e');
    }
  }

  @override
  bool get useSidebarLayout => true;

  @override
  String getDocumentName() {
    // Smart naming: Company_Position_CV or Company_Position_CoverLetter
    final company = widget.application.company.replaceAll(' ', '_');
    final position = widget.application.position.replaceAll(' ', '_');
    final type = widget.isCV ? 'CV' : 'CoverLetter';
    return '${company}_${position}_$type';
  }

  @override
  Future<Uint8List> generatePdfBytes() async {
    if (widget.isCV) {
      return _generateCvPdf();
    } else {
      return _generateCoverLetterPdf();
    }
  }

  Future<Uint8List> _generateCvPdf() async {
    // Debug: Check professional summary value
    debugPrint(
        '[PDF Gen] Professional Summary: "${widget.cvData.professionalSummary}"');
    debugPrint(
        '[PDF Gen] Summary length: ${widget.cvData.professionalSummary.length}');

    // Convert JobCvData to CvData format with proper type conversions
    final cvData = CvData(
      id: widget.application.id,
      name: '${widget.application.position} at ${widget.application.company}',
      language: widget.application.baseLanguage,
      profile: widget.cvData.professionalSummary,
      skills: widget.cvData.skills.map((s) => s.name).toList(),
      languages: widget.cvData.languages
          .map((l) => LanguageSkill(
                language: l.name,
                level: l.proficiency.name,
              ))
          .toList(),
      interests: widget.cvData.interests.map((i) => i.name).toList(),
      contactDetails: widget.cvData.personalInfo != null
          ? ContactDetails(
              fullName: widget.cvData.personalInfo!.fullName,
              jobTitle: widget.cvData.personalInfo!.jobTitle ?? '',
              email: widget.cvData.personalInfo!.email ?? '',
              phone: widget.cvData.personalInfo!.phone ?? '',
              address: widget.cvData.personalInfo!.address ?? '',
              linkedin: widget.cvData.personalInfo!.linkedin ?? '',
              website: widget.cvData.personalInfo!.website ?? '',
              profilePicturePath:
                  widget.cvData.personalInfo!.profilePicturePath,
            )
          : null,
      experiences: widget.cvData.experiences.asMap().entries.map((entry) {
        final i = entry.key;
        final exp = entry.value;
        return Experience(
          company: exp.company,
          title: exp.position,
          startDate: _formatDate(exp.startDate),
          endDate: exp.endDate != null ? _formatDate(exp.endDate!) : 'Present',
          description: getFieldValue('exp_${i}_desc', exp.description ?? ''),
          bullets: exp.responsibilities,
        );
      }).toList(),
      education: widget.cvData.education
          .map((edu) => cv_data.Education(
                institution: edu.institution,
                degree: edu.degree,
                startDate: _formatDate(edu.startDate),
                endDate:
                    edu.endDate != null ? _formatDate(edu.endDate!) : 'Present',
                description: edu.description ?? '',
              ))
          .toList()
          .cast<cv_data.Education>(),
    );

    // Debug: Verify CvData.profile is set
    debugPrint('[PDF Gen] CvData.profile: "${cvData.profile}"');
    debugPrint('[PDF Gen] CvData.profile length: ${cvData.profile.length}');
    debugPrint(
        '[PDF Gen] Application language: ${widget.application.baseLanguage}');
    debugPrint('[PDF Gen] Customization language: ${customization.language}');
    debugPrint('[PDF Gen] CvData.language: ${cvData.language}');

    return await PdfService.instance.generateCvPdf(
      cvData,
      selectedStyle,
      customization: customization,
    );
  }

  Future<Uint8List> _generateCoverLetterPdf() async {
    if (widget.coverLetter == null) {
      return Uint8List(0);
    }

    // Convert JobCoverLetter to CoverLetter format
    final coverLetter = CoverLetter(
      id: widget.application.id,
      name: '${widget.application.position} at ${widget.application.company}',
      recipientName:
          getFieldValue('recipientName', widget.coverLetter!.recipientName),
      companyName:
          getFieldValue('companyName', widget.coverLetter!.companyName),
      greeting: getFieldValue('greeting', widget.coverLetter!.greeting),
      body: getFieldValue('body', widget.coverLetter!.body),
      closing: getFieldValue('closing', widget.coverLetter!.closing),
      senderName: widget.cvData.personalInfo?.fullName,
    );

    return await PdfService.instance.generateCoverLetterPdf(
      coverLetter,
      selectedStyle,
      customization: customization,
    );
  }

  /// Override export to use job application folder as default location
  Future<void> handleExport() async {
    try {
      final result = await FilePicker.platform.saveFile(
        dialogTitle: 'Export PDF',
        fileName: '${getDocumentName()}.pdf',
        initialDirectory: widget.application.folderPath,
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );

      if (result == null || !mounted) return;

      controller.setGenerating(true);

      await exportPdf(context, result);

      if (!mounted) return;
      controller.setGenerating(false);

      // Show success message with just filename
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('PDF exported to ${path.basename(result)}'),
            backgroundColor: Colors.green.shade600,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      controller.setGenerating(false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error exporting PDF: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Future<void> exportPdf(BuildContext context, String outputPath) async {
    final bytes = await generatePdfBytes();
    final file = File(outputPath);
    await file.writeAsBytes(bytes);

    // Auto-open folder after export (job application specific feature)
    if (widget.application.folderPath != null) {
      try {
        await Process.run('explorer', [widget.application.folderPath!]);
      } catch (e) {
        debugPrint('Error opening folder: $e');
      }
    }
  }

  @override
  List<Widget> buildAdditionalSidebarSections() {
    return [
      _buildJobInfoSection(),
      const SizedBox(height: 16),
      _buildStyleInfoSection(),
      const SizedBox(height: 16),
      _buildSaveAndCloseButton(),
    ];
  }

  Widget _buildSaveAndCloseButton() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: ElevatedButton.icon(
        onPressed: () async {
          // If in edit mode, save edits first
          if (controller.isEditMode) {
            controller.setEditMode(false);
            controller.regenerate();
            // Wait a moment for saves to complete
            await Future.delayed(const Duration(milliseconds: 300));
          }

          // Show feedback
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('All changes saved'),
                backgroundColor: Colors.green,
                duration: Duration(seconds: 1),
              ),
            );
          }

          // Close dialog after a brief delay to show the snackbar
          await Future.delayed(const Duration(milliseconds: 500));
          if (mounted) {
            Navigator.pop(context);
          }
        },
        icon: const Icon(Icons.check_circle, size: 18),
        label: const Text('Save & Close'),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.green.shade700,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          minimumSize: const Size(double.infinity, 48),
        ),
      ),
    );
  }

  @override
  List<EditableField> buildEditableFields() {
    if (widget.isCV) {
      // CV editable fields - focus on text that's commonly tailored
      final fields = <EditableField>[
        EditableField(
          id: 'profile',
          label: 'Professional Summary',
          value: getFieldValue('profile', ''),
          onChanged: (value) => updateFieldValue('profile', value),
          maxLines: 5,
          hint: 'Tailor your professional summary for this role...',
        ),
        // Skills editing section
        EditableField(
          id: 'skills',
          label: 'Skills',
          value: widget.cvData.skills.map((s) => s.name).join(', '),
          onChanged: (value) {
            updateFieldValue('skills', value);
            _saveSkillsChanges(value);
          },
          maxLines: 3,
          hint: 'Add or remove skills relevant to this job (comma-separated)',
        ),
      ];

      // Add editable field for each work experience description
      for (int i = 0; i < widget.cvData.experiences.length; i++) {
        final exp = widget.cvData.experiences[i];
        fields.add(
          EditableField(
            id: 'exp_${i}_desc',
            label: '${exp.position} at ${exp.company}',
            value: getFieldValue('exp_${i}_desc', exp.description ?? ''),
            onChanged: (value) {
              updateFieldValue('exp_${i}_desc', value);
              _saveExperienceChanges();
            },
            maxLines: 3,
            hint: 'Highlight achievements relevant to this job...',
            actionIcon: Icons.delete_outline,
            actionTooltip: 'Remove this experience',
            onAction: () => _removeExperience(i),
          ),
        );
      }

      return fields;
    } else {
      // Cover Letter editable fields
      return [
        EditableField(
          id: 'recipientName',
          label: 'Recipient Name',
          value: getFieldValue(
              'recipientName', widget.coverLetter?.recipientName ?? ''),
          onChanged: (value) => updateFieldValue('recipientName', value),
          maxLines: 1,
          hint: 'Hiring Manager',
        ),
        EditableField(
          id: 'companyName',
          label: 'Company Name',
          value: getFieldValue(
              'companyName', widget.coverLetter?.companyName ?? ''),
          onChanged: (value) => updateFieldValue('companyName', value),
          maxLines: 1,
          hint: 'Company name',
        ),
        EditableField(
          id: 'greeting',
          label: 'Greeting',
          value: getFieldValue('greeting',
              widget.coverLetter?.greeting ?? 'Dear Hiring Manager,'),
          onChanged: (value) => updateFieldValue('greeting', value),
          maxLines: 1,
          hint: 'Dear Hiring Manager,',
        ),
        EditableField(
          id: 'body',
          label: 'Letter Body',
          value: getFieldValue('body', widget.coverLetter?.body ?? ''),
          onChanged: (value) => updateFieldValue('body', value),
          maxLines: 12,
          hint: 'Write your personalized cover letter...',
        ),
        EditableField(
          id: 'closing',
          label: 'Closing',
          value: getFieldValue(
              'closing', widget.coverLetter?.closing ?? 'Sincerely,'),
          onChanged: (value) => updateFieldValue('closing', value),
          maxLines: 1,
          hint: 'Sincerely,',
        ),
      ];
    }
  }

  Widget _buildJobInfoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.work_outline,
                color: selectedStyle.accentColor, size: 18),
            const SizedBox(width: 8),
            const Text(
              'JOB APPLICATION',
              style: TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _buildInfoRow('Company', widget.application.company),
        _buildInfoRow('Position', widget.application.position),
        _buildInfoRow('Language', widget.application.baseLanguage.label),
        _buildInfoRow(
          'Document',
          widget.isCV ? 'Curriculum Vitae' : 'Cover Letter',
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.5),
              fontSize: 11,
            ),
          ),
          Flexible(
            child: Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.right,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    return '${months[date.month - 1]} ${date.year}';
  }

  @override
  void updateFieldValue(String fieldId, String value) {
    super.updateFieldValue(fieldId, value);
    // Auto-save changes to the job folder
    _saveFieldChanges();
  }

  Future<void> _saveFieldChanges() async {
    if (widget.application.folderPath == null) return;

    try {
      if (widget.isCV) {
        // For CV, we might not need to save individual field changes
        // since profile summary could be part of PersonalInfo
        // This depends on your data model structure
      } else {
        // Save cover letter changes
        final updatedCoverLetter = widget.coverLetter!.copyWith(
          recipientName:
              getFieldValue('recipientName', widget.coverLetter!.recipientName),
          companyName:
              getFieldValue('companyName', widget.coverLetter!.companyName),
          greeting: getFieldValue('greeting', widget.coverLetter!.greeting),
          body: getFieldValue('body', widget.coverLetter!.body),
          closing: getFieldValue('closing', widget.coverLetter!.closing),
        );

        await _storage.saveJobCoverLetter(
          widget.application.folderPath!,
          updatedCoverLetter,
        );
      }
    } catch (e) {
      // Silent fail - user will see unsaved changes in editor
      debugPrint('Failed to auto-save field changes: $e');
    }
  }

  /// Save experience description changes to CV data
  Future<void> _saveExperienceChanges() async {
    if (widget.application.folderPath == null) return;

    try {
      // Create updated experiences list with edited descriptions
      final updatedExperiences = <WorkExperience>[];
      for (int i = 0; i < widget.cvData.experiences.length; i++) {
        final exp = widget.cvData.experiences[i];
        final editedDesc =
            getFieldValue('exp_${i}_desc', exp.description ?? '');

        updatedExperiences.add(exp.copyWith(
          description: editedDesc,
        ));
      }

      // Create updated CV data
      final updatedCvData = widget.cvData.copyWith(
        experiences: updatedExperiences,
      );

      // Save to job folder
      await _storage.saveJobCvData(
        widget.application.folderPath!,
        updatedCvData,
      );
    } catch (e) {
      debugPrint('Failed to save experience changes: $e');
    }
  }

  /// Save skills changes to CV data
  Future<void> _saveSkillsChanges(String skillsText) async {
    if (widget.application.folderPath == null) return;

    try {
      // Parse comma-separated skills
      final skillNames = skillsText
          .split(',')
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toList();

      // Create updated skills list, preserving existing skill IDs where possible
      final updatedSkills = <Skill>[];
      for (final name in skillNames) {
        // Try to find existing skill with same name
        final existing = widget.cvData.skills.cast<Skill?>().firstWhere(
              (s) => s?.name.toLowerCase() == name.toLowerCase(),
              orElse: () => null,
            );

        if (existing != null) {
          updatedSkills.add(existing);
        } else {
          // Create new skill
          updatedSkills.add(Skill(name: name));
        }
      }

      // Create updated CV data
      final updatedCvData = widget.cvData.copyWith(
        skills: updatedSkills,
      );

      // Save to job folder
      await _storage.saveJobCvData(
        widget.application.folderPath!,
        updatedCvData,
      );
    } catch (e) {
      debugPrint('Failed to save skills changes: $e');
    }
  }

  /// Remove experience at index
  Future<void> _removeExperience(int index) async {
    if (widget.application.folderPath == null) return;
    if (index < 0 || index >= widget.cvData.experiences.length) return;

    try {
      // Create updated experiences list without the removed one
      final updatedExperiences =
          List<WorkExperience>.from(widget.cvData.experiences)..removeAt(index);

      // Create updated CV data
      final updatedCvData = widget.cvData.copyWith(
        experiences: updatedExperiences,
      );

      // Save to job folder
      await _storage.saveJobCvData(
        widget.application.folderPath!,
        updatedCvData,
      );

      // Trigger rebuild to update UI
      setState(() {});
    } catch (e) {
      debugPrint('Failed to remove experience: $e');
    }
  }

  /// Build style info section showing current PDF design settings
  Widget _buildStyleInfoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.palette_outlined,
                color: controller.style.accentColor, size: 18),
            const SizedBox(width: 8),
            const Text(
              'DOCUMENT STYLE',
              style: TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _buildInfoRow('Template', controller.style.type.label),
        _buildInfoRow('Font', controller.style.fontFamily.displayName),
        _buildInfoRow('Mode', controller.style.isDarkMode ? 'Dark' : 'Light'),
        _buildInfoRow('Accent', _getColorName(controller.style.accentColor)),
      ],
    );
  }

  /// Get user-friendly color name
  String _getColorName(Color color) {
    final colorMap = {
      0xFFFFFF00: 'Yellow',
      0xFF00FFFF: 'Cyan',
      0xFFFF00FF: 'Magenta',
      0xFF00FF00: 'Lime',
      0xFFFF6600: 'Orange',
      0xFF9D00FF: 'Purple',
      0xFFFF0066: 'Pink',
      0xFF66FF00: 'Chartreuse',
      0xFF3B82F6: 'Blue',
      0xFF6B7280: 'Gray',
    };
    return colorMap[color.toARGB32()] ?? 'Custom';
  }
}
