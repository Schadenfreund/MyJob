import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../constants/app_constants.dart';
import '../models/pdf_document_type.dart';
import '../models/master_profile.dart';
import '../models/template_style.dart';
import '../models/template_customization.dart';
import '../models/cv_data.dart';
import '../models/cv_data.dart' as cv_data;
import '../models/cover_letter.dart';
import '../services/pdf_service.dart';
import '../services/storage_service.dart';
import '../utils/data_converters.dart';
import '../widgets/pdf_editor/template_edit_panel.dart';
import '../widgets/pdf_editor/pdf_editor_sidebar.dart'
    show CvSectionAvailability;
import '../localization/app_localizations.dart';
import 'base_template_pdf_preview_dialog.dart';

/// PDF preview and editor for master profile
///
/// Allows users to preview their master profile data as PDF and save
/// style presets that will be used as defaults for new job applications.
class MasterProfilePdfDialog extends BaseTemplatePdfPreviewDialog {
  const MasterProfilePdfDialog({
    required this.profile,
    required this.isCV,
    super.templateStyle,
    super.templateCustomization,
    super.key,
  });

  final MasterProfile profile;
  final bool isCV; // true = CV, false = Cover Letter

  @override
  State<MasterProfilePdfDialog> createState() => _MasterProfilePdfDialogState();

  @override
  TemplateStyle getDefaultStyle() => TemplateStyle.defaultStyle;

  @override
  PdfDocumentType getDocumentType() =>
      isCV ? PdfDocumentType.cv : PdfDocumentType.coverLetter;
}

class _MasterProfilePdfDialogState
    extends BaseTemplatePdfPreviewDialogState<MasterProfilePdfDialog> {
  final StorageService _storage = StorageService.instance;

  @override
  void initState() {
    super.initState();

    // DON'T update controller here - it triggers regeneration!
    // Language will be set when loaded settings are applied

    // IMPORTANT: Remove the base class listener temporarily
    // This prevents it from firing during settings load
    removeBaseControllerListener();

    // Load saved PDF settings FIRST
    _loadSavedSettings().then((_) {
      debugPrint(
          '[Master PDF] Settings loaded - style: ${controller.style.type}, accent: ${controller.style.accentColor}');

      // Re-add the base class listener
      addBaseControllerListener();

      // Add our listener for future changes
      controller.addListener(_onPdfSettingsChanged);

      // Force immediate regeneration with loaded settings
      debugPrint('[Master PDF] Forcing PDF regeneration with loaded settings');
      generatePdf();
    });
  }

  @override
  bool shouldSkipInitialGeneration() => true;

  /// Load saved PDF settings from master profile folder
  Future<void> _loadSavedSettings() async {
    try {
      final settings = widget.isCV
          ? await _storage
              .loadMasterProfileCvPdfSettings(widget.profile.language)
          : await _storage
              .loadMasterProfileClPdfSettings(widget.profile.language);

      if (mounted) {
        final (style, customization) = settings;

        if (style != null && customization != null) {
          controller.updateStyle(style);
          // Respect the user's saved language choice
          controller.updateCustomization(customization);
        } else {
          // No saved settings yet — default to the profile's language
          controller.updateCustomization(
            controller.customization
                .copyWith(language: widget.profile.language),
          );
        }
        debugPrint('[Master PDF Dialog] Loaded saved settings');
      }
    } catch (e) {
      debugPrint('[Master PDF Dialog] No saved settings or error loading: $e');
      // Default to profile language on error
      controller.updateCustomization(
        controller.customization
            .copyWith(language: widget.profile.language),
      );
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

  /// Save template style and customization to master profile folder
  Future<void> _savePdfSettings() async {
    try {
      if (widget.isCV) {
        await _storage.saveMasterProfileCvPdfSettings(
          widget.profile.language,
          selectedStyle,
          controller.customization,
        );
      } else {
        await _storage.saveMasterProfileClPdfSettings(
          widget.profile.language,
          selectedStyle,
          controller.customization,
        );
      }
      debugPrint('[Master PDF Dialog] Settings saved as preset');
    } catch (e) {
      debugPrint('Failed to save PDF settings: $e');
    }
  }

  @override
  bool get useSidebarLayout => true;

  @override
  bool get hidePhotoOptions => !widget.isCV;

  @override
  CvSectionAvailability? getCvSectionAvailability() {
    if (!widget.isCV) return null;

    return CvSectionAvailability(
      hasExperience: widget.profile.experiences.isNotEmpty,
      hasEducation: widget.profile.education.isNotEmpty,
      hasLanguages: widget.profile.languages.isNotEmpty,
      hasSkills: widget.profile.skills.isNotEmpty,
      hasInterests: widget.profile.interests.isNotEmpty,
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
              const Text(
                'DESIGN PRESET',
                style: TextStyle(
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
            'Choose a layout style for your cover letter',
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
                                preset.displayName,
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
                                preset.description,
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
    return null;
  }

  @override
  String getDisplayName() {
    final type = widget.isCV ? context.tr('pdf_doc_type_cv') : context.tr('cover_letter');
    return '${context.tr('pdf_info_master_profile')} · $type';
  }

  @override
  String getDocumentName() {
    final type = widget.isCV ? 'CV' : 'CoverLetter';
    final lang = widget.profile.language.toUpperCase();
    return 'MasterProfile_${lang}_$type';
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
    // Load profile picture if available
    Uint8List? profileImageBytes;
    final profilePicturePath = widget.profile.personalInfo?.profilePicturePath;
    if (profilePicturePath != null && profilePicturePath.isNotEmpty) {
      try {
        final file = File(profilePicturePath);
        if (await file.exists()) {
          profileImageBytes = await file.readAsBytes();
        }
      } catch (e) {
        debugPrint('[Master PDF Gen] Error loading profile picture: $e');
      }
    }

    // Convert MasterProfile to CvData format
    final cvData = CvData(
      id: 'master_${widget.profile.language}',
      name: 'Master Profile - ${widget.profile.language.toUpperCase()}',
      language: DocumentLanguage.fromCode(widget.profile.language),
      profile: widget.profile.profileSummary,
      skills: widget.profile.skills.map((s) => s.name).toList(),
      languages: widget.profile.languages
          .map((l) => LanguageSkill(
                language: l.name,
                level: l.proficiency.name,
              ))
          .toList(),
      interests: widget.profile.interests.map((i) => i.name).toList(),
      contactDetails: widget.profile.personalInfo != null
          ? DataConverters.personalInfoToContactDetails(
              widget.profile.personalInfo!,
            )
          : null,
      experiences: widget.profile.experiences.map((exp) {
        return Experience(
          company: exp.company,
          title: exp.position,
          startDate: _formatDate(exp.startDate),
          endDate: exp.endDate != null ? _formatDate(exp.endDate!) : 'Present',
          description: exp.description ?? '',
          bullets: exp.responsibilities,
        );
      }).toList(),
      education: widget.profile.education
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

    return await PdfService.instance.generateCvPdf(
      cvData,
      selectedStyle,
      customization: customization,
      profileImageBytes: profileImageBytes,
    );
  }

  Future<Uint8List> _generateCoverLetterPdf() async {
    // Create a sample cover letter from the default body
    final coverLetter = CoverLetter(
      id: 'master_${widget.profile.language}',
      name: 'Master Cover Letter - ${widget.profile.language.toUpperCase()}',
      recipientName: 'Hiring Manager',
      companyName: '[Company Name]',
      subject: '',
      greeting: widget.profile.defaultGreeting,
      body: widget.profile.defaultCoverLetterBody,
      closing: widget.profile.defaultClosing,
      senderName: widget.profile.personalInfo?.fullName,
      placeholders: {},
    );

    final contactDetails = widget.profile.personalInfo != null
        ? DataConverters.personalInfoToContactDetails(
            widget.profile.personalInfo!,
          )
        : null;

    return await PdfService.instance.generateCoverLetterPdf(
      coverLetter,
      selectedStyle,
      contactDetails: contactDetails,
      customization: customization,
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
  String? getInitialExportDirectory() {
    // Export to user's Downloads or Documents folder for master profile
    return null; // Use system default
  }

  @override
  Future<void> exportPdf(BuildContext context, String outputPath) async {
    final bytes = await generatePdfBytes();
    final file = File(outputPath);
    await file.writeAsBytes(bytes);
    debugPrint('[Master PDF] Exported to: $outputPath');
  }

  @override
  List<Widget> buildAdditionalSidebarSections() {
    return [
      _buildProfileInfoSection(),
      const SizedBox(height: 16),
      _buildPresetInfoSection(),
    ];
  }

  String _getLanguageName(BuildContext context) {
    final langCode = widget.profile.language;
    final info = AppLocalizations.of(context).availableLanguages.firstWhere(
          (l) => l.code == langCode,
          orElse: () =>
              LanguageInfo(code: langCode, name: langCode.toUpperCase(), flag: '🌐'),
        );
    return info.name;
  }

  Widget _buildProfileInfoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.account_circle_outlined,
                color: selectedStyle.accentColor, size: 18),
            const SizedBox(width: 8),
            Text(
              context.tr('pdf_info_master_profile').toUpperCase(),
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
        _buildInfoRow(context.tr('pdf_info_language'), _getLanguageName(context)),
        _buildInfoRow(
          context.tr('pdf_info_document'),
          widget.isCV ? context.tr('pdf_doc_type_cv') : context.tr('cover_letter'),
        ),
        _buildInfoRow(context.tr('pdf_info_purpose'), context.tr('pdf_purpose_preview_save')),
      ],
    );
  }

  Widget _buildPresetInfoSection() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: selectedStyle.accentColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: selectedStyle.accentColor.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.bookmark_outline,
                  color: selectedStyle.accentColor, size: 16),
              const SizedBox(width: 6),
              Text(
                context.tr('pdf_info_style_preset').toUpperCase(),
                style: TextStyle(
                  color: selectedStyle.accentColor,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            context.tr('pdf_style_preset_desc'),
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.7),
              fontSize: 10,
              height: 1.4,
            ),
          ),
        ],
      ),
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

  @override
  List<EditableField> buildEditableFields() {
    // Master profile PDF is read-only - just for preview
    return [];
  }
}
