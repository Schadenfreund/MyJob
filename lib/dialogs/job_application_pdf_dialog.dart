import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:path/path.dart' as path;

import '../models/pdf_document_type.dart';
import '../models/job_application.dart';
import '../models/job_cv_data.dart';
import '../models/job_cover_letter.dart';
import '../models/template_style.dart';
import '../models/template_customization.dart';
import '../models/cv_data.dart';

import '../models/cover_letter.dart';
import '../utils/platform_utils.dart';
import '../models/user_data/work_experience.dart';
import '../models/user_data/skill.dart';
import '../constants/app_constants.dart';
import '../services/log_service.dart';
import '../services/pdf_service.dart';
import '../services/storage_service.dart';
import '../utils/app_date_utils.dart';
import '../utils/data_converters.dart';
import '../widgets/pdf_editor/template_edit_panel.dart';
import '../widgets/pdf_editor/pdf_editor_sidebar.dart'
    show CvSectionAvailability;
import '../localization/app_localizations.dart';
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

  @override
  PdfDocumentType getDocumentType() =>
      isCV ? PdfDocumentType.cv : PdfDocumentType.coverLetter;
}

class _JobApplicationPdfDialogState
    extends BaseTemplatePdfPreviewDialogState<JobApplicationPdfDialog> {
  final _appRepo = StorageService.instance.applications;

  @override
  void initState() {
    super.initState();

    // IMPORTANT: Remove the base class listener temporarily
    // This prevents it from firing during settings load
    removeBaseControllerListener();

    // Load saved PDF settings FIRST
    _loadSavedSettings().then((_) {
      logDebug(
          'Settings loaded - style: ${controller.style.type}, accent: ${controller.style.accentColor}', tag: 'JobPDF');

      // Re-add the base class listener
      addBaseControllerListener();

      // Add our listener for future changes
      controller.addListener(_onPdfSettingsChanged);

      // Force immediate regeneration with loaded settings
      logDebug('Forcing PDF regeneration with loaded settings', tag: 'JobPDF');
      generatePdf();
    });
  }

  @override
  bool shouldSkipInitialGeneration() => true;

  /// Load saved PDF settings from job folder
  Future<void> _loadSavedSettings() async {
    if (widget.application.folderPath == null) return;

    try {
      // Load settings based on document type (CV or Cover Letter)
      final settings = widget.isCV
          ? await _appRepo.loadCvPdfSettings(widget.application.folderPath!)
          : await _appRepo.loadClPdfSettings(widget.application.folderPath!);

      if (mounted) {
        final (style, customization) = settings;

        if (style != null && customization != null) {
          controller.updateStyle(style);
          // Respect the user's saved language choice
          controller.updateCustomization(customization);
        }
        logDebug('Loaded saved settings', tag: 'JobPDF');
        // No else needed: StorageService initialises pdf_settings.json with
        // the correct baseLanguage when the application folder is created.
      }
    } catch (e) {
      logError('No saved settings or error loading', error: e, tag: 'JobPDF');
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
      // Save to correct file based on document type (CV or Cover Letter)
      if (widget.isCV) {
        await _appRepo.saveCvPdfSettings(
          widget.application.folderPath!,
          selectedStyle,
          controller.customization,
        );
      } else {
        await _appRepo.saveClPdfSettings(
          widget.application.folderPath!,
          selectedStyle,
          controller.customization,
        );
      }
    } catch (e) {
      logError('Failed to save PDF settings', error: e, tag: 'JobPDF');
      showError('Failed to save PDF settings: $e');
    }
  }

  @override
  bool get useSidebarLayout => true;

  @override
  bool get hidePhotoOptions =>
      !widget.isCV; // Hide photo options for cover letters

  @override
  CvSectionAvailability? getCvSectionAvailability() {
    // Only relevant for CV documents
    if (!widget.isCV) return null;

    // Build availability based on actual CV data
    final cvData = widget.cvData;
    return CvSectionAvailability(
      hasExperience: cvData.experiences.isNotEmpty,
      hasEducation: cvData.education.isNotEmpty,
      hasLanguages: cvData.languages.isNotEmpty,
      hasSkills: cvData.skills.isNotEmpty,
      hasInterests: cvData.interests.isNotEmpty,
    );
  }

  @override
  Widget? buildCustomPresets() {
    // For cover letters, show all presets except Two-Column
    if (!widget.isCV) {
      final coverLetterPresets = LayoutPreset.values
          .where((preset) => preset != LayoutPreset.twoColumn)
          .toList();

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.style, color: controller.style.accentColor, size: 18),
              const SizedBox(width: 8),
              Text(
                context.tr('sidebar_design_preset').toUpperCase(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            context.tr('sidebar_design_preset_desc'),
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.5),
              fontSize: 10,
            ),
          ),
          const SizedBox(height: 12),
          ...coverLetterPresets.map((preset) {
            final isSelected = controller.customization.layoutMode ==
                preset.toCustomization().layoutMode;

            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => controller.setLayoutPreset(preset),
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? controller.style.accentColor.withValues(alpha: 0.15)
                          : Colors.white.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isSelected
                            ? controller.style.accentColor
                            : Colors.white.withValues(alpha: 0.1),
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: isSelected
                                ? controller.style.accentColor
                                : Colors.white.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            preset.icon,
                            color: isSelected ? Colors.black : Colors.white,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _layoutPresetName(preset),
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 13,
                                  fontWeight: isSelected
                                      ? FontWeight.bold
                                      : FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _layoutPresetDesc(preset),
                                style: TextStyle(
                                  color: isSelected
                                      ? controller.style.accentColor
                                      : Colors.white.withValues(alpha: 0.6),
                                  fontSize: 10,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (isSelected)
                          Icon(
                            Icons.check_circle,
                            color: controller.style.accentColor,
                            size: 20,
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }),
        ],
      );
    }
    // For CV, use default presets (all of them)
    return null;
  }

  String _layoutPresetName(LayoutPreset preset) {
    switch (preset) {
      case LayoutPreset.modern:
        return context.tr('layout_preset_modern');
      case LayoutPreset.compact:
        return context.tr('layout_preset_compact');
      case LayoutPreset.traditional:
        return context.tr('layout_preset_traditional');
      case LayoutPreset.twoColumn:
        return context.tr('layout_preset_two_column');
    }
  }

  String _layoutPresetDesc(LayoutPreset preset) {
    switch (preset) {
      case LayoutPreset.modern:
        return context.tr('layout_preset_modern_desc');
      case LayoutPreset.compact:
        return context.tr('layout_preset_compact_desc');
      case LayoutPreset.traditional:
        return context.tr('layout_preset_traditional_desc');
      case LayoutPreset.twoColumn:
        return context.tr('layout_preset_two_column_desc');
    }
  }

  @override
  String getDisplayName() {
    final type = widget.isCV ? context.tr('pdf_doc_type_cv') : context.tr('cover_letter');
    return '${widget.application.company} · ${widget.application.position} · $type';
  }

  @override
  String getDocumentName() {
    // Sanitize filename by removing/replacing invalid characters
    // Windows invalid chars: < > : " / \ | ? *
    // Also remove control characters and trim whitespace
    final company = _sanitizeFilename(widget.application.company);
    final position = _sanitizeFilename(widget.application.position);
    final type = widget.isCV ? 'CV' : 'CoverLetter';

    // Ensure we have valid names (fallback to generic if sanitization results in empty string)
    final safeName = company.isEmpty || position.isEmpty
        ? 'Application_$type'
        : '${company}_${position}_$type';

    return safeName;
  }

  String _sanitizeFilename(String input) =>
      FileConfig.sanitizeFilename(input, useUnderscores: true);

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
    logDebug(
        'Professional Summary: "${widget.cvData.professionalSummary}"', tag: 'JobPDF');
    logDebug(
        'Summary length: ${widget.cvData.professionalSummary.length}', tag: 'JobPDF');

    // Load profile picture if available
    Uint8List? profileImageBytes;
    final profilePicturePath = widget.cvData.personalInfo?.profilePicturePath;
    if (profilePicturePath != null && profilePicturePath.isNotEmpty) {
      try {
        final file = File(profilePicturePath);
        if (await file.exists()) {
          profileImageBytes = await file.readAsBytes();
          logDebug('Loaded profile picture: $profilePicturePath', tag: 'JobPDF');
        } else {
          logWarning(
              'Profile picture file not found: $profilePicturePath', tag: 'JobPDF');
        }
      } catch (e) {
        logError('Error loading profile picture', error: e, tag: 'JobPDF');
      }
    }

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
          ? DataConverters.personalInfoToContactDetails(
              widget.cvData.personalInfo!,
            )
          : null,
      experiences: widget.cvData.experiences.asMap().entries.map((entry) {
        final i = entry.key;
        final exp = entry.value;
        return Experience(
          company: exp.company,
          title: exp.position,
          startDate: _formatDate(exp.startDate),
          endDate: exp.endDate != null ? _formatDate(exp.endDate!) : context.tr('present'),
          description: getFieldValue('exp_${i}_desc', exp.description ?? ''),
          bullets: exp.responsibilities,
        );
      }).toList(),
      education: widget.cvData.education
          .map((edu) => CvEducation(
                institution: edu.institution,
                degree: edu.degree,
                startDate: _formatDate(edu.startDate),
                endDate:
                    edu.endDate != null ? _formatDate(edu.endDate!) : context.tr('present'),
                description: edu.description ?? '',
              ))
          .toList(),
    );

    // Debug: Verify CvData.profile is set
    logDebug('CvData.profile: "${cvData.profile}"', tag: 'JobPDF');
    logDebug('CvData.profile length: ${cvData.profile.length}', tag: 'JobPDF');
    logDebug(
        'Application language: ${widget.application.baseLanguage}', tag: 'JobPDF');
    logDebug('Customization language: ${customization.language}', tag: 'JobPDF');
    logDebug('CvData.language: ${cvData.language}', tag: 'JobPDF');
    logDebug(
        'Profile picture loaded: ${profileImageBytes != null}', tag: 'JobPDF');
    logDebug(
        '*** Using style: ${selectedStyle.type}, accent: ${selectedStyle.accentColor}', tag: 'JobPDF');

    return await PdfService.instance.generateCvPdf(
      cvData,
      selectedStyle,
      customization: customization,
      profileImageBytes: profileImageBytes,
    );
  }

  Future<Uint8List> _generateCoverLetterPdf() async {
    if (widget.coverLetter == null) {
      return Uint8List(0);
    }

    // Create placeholders map for template variables
    final placeholders = <String, String>{
      'COMPANY': widget.application.company,
      'POSITION': widget.application.position,
    };

    // Convert JobCoverLetter to CoverLetter format
    final coverLetter = CoverLetter(
      id: widget.application.id,
      name: '${widget.application.position} at ${widget.application.company}',
      recipientName:
          getFieldValue('recipientName', widget.coverLetter!.recipientName),
      companyName:
          getFieldValue('companyName', widget.coverLetter!.companyName),
      subject: getFieldValue('subject', widget.coverLetter!.subject),
      greeting: getFieldValue('greeting', widget.coverLetter!.greeting),
      body: getFieldValue('body', widget.coverLetter!.body),
      closing: getFieldValue('closing', widget.coverLetter!.closing),
      senderName: widget.cvData.personalInfo?.fullName,
      placeholders: placeholders,
    );

    // Create contact details from personal info for the header
    final contactDetails = widget.cvData.personalInfo != null
        ? DataConverters.personalInfoToContactDetails(
            widget.cvData.personalInfo!,
          )
        : null;

    return await PdfService.instance.generateCoverLetterPdf(
      coverLetter,
      selectedStyle,
      contactDetails: contactDetails,
      customization: customization,
    );
  }

  /// Get and ensure exports folder exists
  String? _getOrCreateExportsFolder() {
    if (widget.application.folderPath == null) {
      logWarning('No folder path set for application', tag: 'JobPDF');
      return null;
    }

    final exportsPath = path.join(widget.application.folderPath!, 'exports');
    final exportsDir = Directory(exportsPath);

    // Create exports folder if it doesn't exist
    if (!exportsDir.existsSync()) {
      exportsDir.createSync(recursive: true);
      logDebug('Created exports folder: $exportsPath', tag: 'JobPDF');
    }

    return exportsPath;
  }

  /// Override to provide job application exports folder as default location
  @override
  String? getInitialExportDirectory() {
    final exportsPath = _getOrCreateExportsFolder();
    if (exportsPath != null) {
      logDebug('Initial directory set to: $exportsPath', tag: 'JobPDF');
    }
    return exportsPath;
  }

  @override
  Future<void> exportPdf(BuildContext context, String outputPath) async {
    final bytes = await generatePdfBytes();
    final file = File(outputPath);
    await file.writeAsBytes(bytes);

    // Auto-open exports folder after successful export
    await _openExportsFolder();
  }

  /// Open the exports folder in the system file explorer
  Future<void> _openExportsFolder() async {
    final exportsPath = _getOrCreateExportsFolder();
    if (exportsPath == null) return;

    await PlatformUtils.openFolder(exportsPath);
  }

  @override
  List<Widget> buildAdditionalSidebarSections() {
    return [
      _buildJobInfoSection(),
      const SizedBox(height: 16),
      _buildStyleInfoSection(),
    ];
  }

  @override
  List<EditableField> buildEditableFields() {
    if (widget.isCV) {
      // CV editable fields - focus on text that's commonly tailored
      final fields = <EditableField>[
        EditableField(
          id: 'profile',
          label: context.tr('pdf_field_professional_summary'),
          value: getFieldValue('profile', ''),
          onChanged: (value) => updateFieldValue('profile', value),
          maxLines: 5,
          hint: context.tr('pdf_hint_summary'),
        ),
        // Skills editing section
        EditableField(
          id: 'skills',
          label: context.tr('skills'),
          value: widget.cvData.skills.map((s) => s.name).join(', '),
          onChanged: (value) {
            updateFieldValue('skills', value);
            _saveSkillsChanges(value);
          },
          maxLines: 3,
          hint: context.tr('pdf_hint_skills'),
        ),
      ];

      // Add editable field for each work experience description
      for (int i = 0; i < widget.cvData.experiences.length; i++) {
        final exp = widget.cvData.experiences[i];
        fields.add(
          EditableField(
            id: 'exp_${i}_desc',
            label: context.tr('pdf_position_at_company', {'position': exp.position, 'company': exp.company}),
            value: getFieldValue('exp_${i}_desc', exp.description ?? ''),
            onChanged: (value) {
              updateFieldValue('exp_${i}_desc', value);
              _saveExperienceChanges();
            },
            maxLines: 3,
            hint: context.tr('pdf_hint_experience'),
            actionIcon: Icons.delete_outline,
            actionTooltip: context.tr('pdf_remove_experience'),
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
          label: context.tr('pdf_field_recipient_name'),
          value: getFieldValue(
              'recipientName', widget.coverLetter?.recipientName ?? ''),
          onChanged: (value) => updateFieldValue('recipientName', value),
          maxLines: 1,
          hint: context.tr('pdf_hint_recipient_name'),
        ),
        EditableField(
          id: 'companyName',
          label: context.tr('pdf_field_company_name'),
          value: getFieldValue(
              'companyName', widget.coverLetter?.companyName ?? ''),
          onChanged: (value) => updateFieldValue('companyName', value),
          maxLines: 1,
          hint: context.tr('pdf_hint_company_name'),
        ),
        EditableField(
          id: 'subject',
          label: context.tr('pdf_field_subject'),
          value: getFieldValue('subject', widget.coverLetter?.subject ?? ''),
          onChanged: (value) => updateFieldValue('subject', value),
          maxLines: 1,
          hint: widget.application.baseLanguage == DocumentLanguage.de
              ? context.tr('pdf_hint_subject_de')
              : context.tr('pdf_hint_subject_en'),
        ),
        EditableField(
          id: 'greeting',
          label: context.tr('pdf_field_greeting'),
          value: getFieldValue('greeting',
              widget.coverLetter?.greeting ?? context.tr('pdf_hint_greeting')),
          onChanged: (value) => updateFieldValue('greeting', value),
          maxLines: 1,
          hint: context.tr('pdf_hint_greeting'),
        ),
        EditableField(
          id: 'body',
          label: context.tr('pdf_field_letter_body'),
          value: getFieldValue('body', widget.coverLetter?.body ?? ''),
          onChanged: (value) => updateFieldValue('body', value),
          maxLines: 12,
          hint: context.tr('pdf_hint_letter_body'),
        ),
        EditableField(
          id: 'closing',
          label: context.tr('pdf_field_closing'),
          value: getFieldValue(
              'closing', widget.coverLetter?.closing ?? context.tr('pdf_hint_closing')),
          onChanged: (value) => updateFieldValue('closing', value),
          maxLines: 1,
          hint: context.tr('pdf_hint_closing'),
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
            Text(
              context.tr('pdf_info_job_application').toUpperCase(),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _buildInfoRow(context.tr('company'), widget.application.company),
        _buildInfoRow(context.tr('position'), widget.application.position),
        _buildInfoRow(context.tr('pdf_info_language'), widget.application.baseLanguage.label),
        _buildInfoRow(
          context.tr('pdf_info_document'),
          widget.isCV ? context.tr('pdf_doc_type_cv') : context.tr('cover_letter'),
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

  String _formatDate(DateTime date) => AppDateUtils.formatShort(date);

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
          subject: getFieldValue('subject', widget.coverLetter!.subject),
          greeting: getFieldValue('greeting', widget.coverLetter!.greeting),
          body: getFieldValue('body', widget.coverLetter!.body),
          closing: getFieldValue('closing', widget.coverLetter!.closing),
        );

        await _appRepo.saveCoverLetter(
          widget.application.folderPath!,
          updatedCoverLetter,
        );
      }
    } catch (e) {
      logError('Failed to auto-save field changes', error: e, tag: 'JobPDF');
      showError('Failed to save field changes: $e');
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
      await _appRepo.saveCvData(
        widget.application.folderPath!,
        updatedCvData,
      );
    } catch (e) {
      logError('Failed to save experience changes', error: e, tag: 'JobPDF');
      showError('Failed to save experience changes: $e');
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
      await _appRepo.saveCvData(
        widget.application.folderPath!,
        updatedCvData,
      );
    } catch (e) {
      logError('Failed to save skills changes', error: e, tag: 'JobPDF');
      showError('Failed to save skills changes: $e');
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
      await _appRepo.saveCvData(
        widget.application.folderPath!,
        updatedCvData,
      );

      // Trigger rebuild to update UI
      setState(() {});
    } catch (e) {
      logError('Failed to remove experience', error: e, tag: 'JobPDF');
      showError('Failed to remove experience: $e');
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
            Text(
              context.tr('pdf_info_document_style').toUpperCase(),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _buildInfoRow(context.tr('pdf_info_template'), controller.style.type.label),
        _buildInfoRow(context.tr('pdf_info_font'), controller.style.fontFamily.displayName),
        _buildInfoRow(context.tr('pdf_info_mode'), controller.style.isDarkMode ? context.tr('pdf_mode_dark') : context.tr('pdf_mode_light')),
        _buildInfoRow(context.tr('pdf_info_accent'), _getColorName(controller.style.accentColor)),
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
