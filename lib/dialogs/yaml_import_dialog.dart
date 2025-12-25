import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';
import '../services/yaml_import_service.dart';
import '../providers/templates_provider.dart';
import '../models/cv_data.dart';

/// Dialog for importing CV or Cover Letter from YAML files
class YamlImportDialog extends StatefulWidget {
  const YamlImportDialog({
    required this.importType,
    super.key,
  });

  final YamlImportType importType;

  @override
  State<YamlImportDialog> createState() => _YamlImportDialogState();
}

class _YamlImportDialogState extends State<YamlImportDialog> {
  bool _isImporting = false;
  String? _errorMessage;
  bool _importSuccess = false;
  String? _importedTemplateName;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isCv = widget.importType == YamlImportType.cv;

    return AlertDialog(
      title: Row(
        children: [
          Icon(
            isCv ? Icons.description : Icons.mail,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(width: 12),
          Text('Import ${isCv ? 'CV' : 'Cover Letter'} YAML'),
        ],
      ),
      content: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!_isImporting && !_importSuccess) ...[
              Text(
                'Select a YAML file to import your ${isCv ? 'CV' : 'cover letter'} data.',
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest
                      .withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: theme.dividerColor.withValues(alpha: 0.5),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          size: 16,
                          color: theme.colorScheme.primary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Expected file location:',
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      isCv
                          ? 'UserData/CV/cv_data_*.yaml'
                          : 'UserData/CoverLetter/cover_letter_*.yaml',
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontFamily: 'monospace',
                        color: theme.textTheme.bodySmall?.color
                            ?.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            if (_isImporting) ...[
              Center(
                child: Column(
                  children: [
                    const CircularProgressIndicator(),
                    const SizedBox(height: 16),
                    Text(
                      'Importing YAML file...',
                      style: theme.textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
            ],
            if (_importSuccess) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Colors.green.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle, color: Colors.green),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Import Successful!',
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: Colors.green.shade700,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Template "$_importedTemplateName" has been created.',
                            style: theme.textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
            if (_errorMessage != null) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.colorScheme.error.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: theme.colorScheme.error.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.error_outline,
                      color: theme.colorScheme.error,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Import Failed',
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: theme.colorScheme.error,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _errorMessage!,
                            style: theme.textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        if (!_isImporting && !_importSuccess)
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        if (!_isImporting && !_importSuccess)
          ElevatedButton.icon(
            onPressed: _pickAndImportFile,
            icon: const Icon(Icons.folder_open, size: 18),
            label: const Text('Choose File'),
          ),
        if (_importSuccess)
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Done'),
          ),
        if (_errorMessage != null && !_isImporting)
          ElevatedButton(
            onPressed: () {
              setState(() {
                _errorMessage = null;
              });
              _pickAndImportFile();
            },
            child: const Text('Try Again'),
          ),
      ],
    );
  }

  Future<void> _pickAndImportFile() async {
    setState(() {
      _isImporting = true;
      _errorMessage = null;
    });

    try {
      // Show file picker
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['yaml', 'yml'],
        dialogTitle:
            'Select ${widget.importType == YamlImportType.cv ? 'CV' : 'Cover Letter'} YAML file',
      );

      if (result == null) {
        setState(() => _isImporting = false);
        return;
      }

      final file = File(result.files.single.path!);

      if (widget.importType == YamlImportType.cv) {
        await _importCvYaml(file);
      } else {
        await _importCoverLetterYaml(file);
      }
    } catch (e) {
      setState(() {
        _isImporting = false;
        _errorMessage = e.toString();
      });
    }
  }

  Future<void> _importCvYaml(File file) async {
    if (!mounted) return;

    final importService = YamlImportService();
    final templatesProvider = context.read<TemplatesProvider>();

    try {
      // Import YAML and parse data
      final result = await importService.importCvData(file);

      if (!result.success || !mounted) {
        throw Exception(result.error ?? 'Failed to parse YAML file');
      }

      // Convert imported data to CV template format
      final templateName = result.personalInfo?.fullName ?? 'Imported CV';

      // Build skills list
      final skills = result.skills.map((s) => s.name).toList();

      // Build languages list
      final languages = result.languages.map((lang) {
        return LanguageSkill(
          language: lang.name,
          level: _languageProficiencyToString(lang.proficiency),
        );
      }).toList();

      // Build interests list
      final interests = result.interests.map((i) => i.name).toList();

      // Build contact details
      ContactDetails? contactDetails;
      if (result.personalInfo != null) {
        final pi = result.personalInfo!;
        contactDetails = ContactDetails(
          fullName: pi.fullName,
          email: pi.email,
          phone: pi.phone,
          address: pi.address != null && pi.city != null && pi.country != null
              ? '${pi.address}, ${pi.city}, ${pi.country}'
              : pi.address ?? pi.city ?? pi.country,
        );
      }

      // Build experiences
      final experiences = result.workExperiences.map((exp) {
        return Experience(
          company: exp.company,
          title: exp.position,
          startDate: _formatDate(exp.startDate),
          endDate: exp.endDate != null
              ? _formatDate(exp.endDate!)
              : (exp.isCurrent ? 'Present' : null),
          description: exp.description,
          bullets: exp.responsibilities,
        );
      }).toList();

      // Create CV template
      final template = await templatesProvider.createCvTemplate(
        name: templateName,
        profile: result.personalInfo?.profileSummary ?? '',
        skills: skills,
        contactDetails: contactDetails,
      );

      // Update template with additional data
      final updatedTemplate = template.copyWith(
        languages: languages,
        interests: interests,
        experiences: experiences,
        lastModified: DateTime.now(),
      );

      await templatesProvider.updateCvTemplate(updatedTemplate);

      setState(() {
        _isImporting = false;
        _importSuccess = true;
        _importedTemplateName = templateName;
      });
    } catch (e) {
      setState(() {
        _isImporting = false;
        _errorMessage = 'Failed to import CV: ${e.toString()}';
      });
    }
  }

  String _languageProficiencyToString(dynamic proficiency) {
    return proficiency.toString().split('.').last;
  }

  String _formatDate(DateTime date) {
    final months = [
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

  Future<void> _importCoverLetterYaml(File file) async {
    if (!mounted) return;

    final importService = YamlImportService();
    final templatesProvider = context.read<TemplatesProvider>();

    try {
      // Import cover letter template
      final result = await importService.importCoverLetterTemplate(file);

      if (!result.success || !mounted) {
        throw Exception(result.error ?? 'Failed to parse YAML file');
      }

      // Extract file name (without extension) for template name
      final fileName = file.path.split('/').last.split('\\').last;
      final templateName = fileName
          .replaceAll('.yaml', '')
          .replaceAll('.yml', '')
          .replaceAll('_', ' ');
      final capitalizedName = templateName.split(' ').map((word) {
        if (word.isEmpty) return word;
        return word[0].toUpperCase() + word.substring(1);
      }).join(' ');

      // Build the body from paragraphs
      final body = result.paragraphs.join('\n\n');

      // Create cover letter template
      await templatesProvider.createCoverLetterTemplate(
        name: capitalizedName,
        greeting: result.greeting,
        body: body,
        closing: result.closing,
      );

      setState(() {
        _isImporting = false;
        _importSuccess = true;
        _importedTemplateName = capitalizedName;
      });
    } catch (e) {
      setState(() {
        _isImporting = false;
        _errorMessage = 'Failed to import cover letter: ${e.toString()}';
      });
    }
  }
}

enum YamlImportType {
  cv,
  coverLetter,
}
