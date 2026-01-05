import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import '../../models/job_application.dart';
import '../../models/job_cv_data.dart';
import '../../models/job_cover_letter.dart';
import '../../models/template_customization.dart';
import '../../models/template_style.dart';
import '../../models/cv_data.dart';
import '../../models/cv_data.dart' as cv_data;
import '../../models/cover_letter.dart';
import '../../services/storage_service.dart';
import '../../services/pdf_service.dart';
import '../../utils/dialog_utils.dart';

/// Tailoring Workspace - Split-screen CV/Cover Letter editor with live PDF preview
///
/// This is the core workspace where users customize their documents for each job.
/// - Left panel: Content editor (CV or Cover Letter)
/// - Right panel: Live PDF preview with template/style controls
class TailoringWorkspace extends StatefulWidget {
  const TailoringWorkspace({
    super.key,
    required this.application,
  });

  final JobApplication application;

  @override
  State<TailoringWorkspace> createState() => _TailoringWorkspaceState();
}

class _TailoringWorkspaceState extends State<TailoringWorkspace>
    with SingleTickerProviderStateMixin {
  final StorageService _storage = StorageService.instance;

  // Data
  JobCvData? _cvData;
  JobCoverLetter? _coverLetter;
  TemplateCustomization? _pdfSettings;

  // UI State
  late TabController _tabController;
  bool _isLoading = true;
  String? _error;
  double _dividerPosition = 0.5; // 50% split

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() => setState(() {})); // Rebuild on tab change
    _loadJobData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  /// Load job-specific data from folder
  Future<void> _loadJobData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final folderPath = widget.application.folderPath;

      if (folderPath == null || folderPath.isEmpty) {
        throw Exception('Job application folder path is missing');
      }

      // Load all job-specific data in parallel
      final results = await Future.wait([
        _storage.loadJobCvData(folderPath),
        _storage.loadJobCoverLetter(folderPath),
        _storage.loadJobPdfSettings(folderPath),
      ]);

      setState(() {
        _cvData = results[0] as JobCvData?;
        _coverLetter = results[1] as JobCoverLetter?;
        _pdfSettings = results[2] as TemplateCustomization?;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load job data: $e';
        _isLoading = false;
      });
    }
  }

  /// Save cover letter data
  Future<void> _saveCoverLetter() async {
    if (_coverLetter == null || widget.application.folderPath == null) return;

    try {
      await _storage.saveJobCoverLetter(
          widget.application.folderPath!, _coverLetter!);
    } catch (e) {
      if (mounted) {
        context.showErrorSnackBar('Failed to save cover letter: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
                '${widget.application.company} - ${widget.application.position}'),
            Text(
              'Tailoring Workspace',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
        actions: [
          // Language indicator
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Center(
              child: Chip(
                avatar: Text(widget.application.baseLanguage.flag),
                label: Text(widget.application.baseLanguage.label),
                visualDensity: VisualDensity.compact,
              ),
            ),
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Loading job data...'),
          ],
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red.shade300),
            const SizedBox(height: 16),
            Text(_error!),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _loadJobData,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    return _buildSplitView();
  }

  Widget _buildSplitView() {
    final theme = Theme.of(context);

    return Column(
      children: [
        // Tab bar for CV / Cover Letter
        Container(
          color: theme.colorScheme.surfaceContainerHighest,
          child: TabBar(
            controller: _tabController,
            tabs: const [
              Tab(
                icon: Icon(Icons.description),
                text: 'CV Content',
              ),
              Tab(
                icon: Icon(Icons.email),
                text: 'Cover Letter',
              ),
            ],
          ),
        ),

        // Split-screen content
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final leftWidth = constraints.maxWidth * _dividerPosition;
              final rightWidth = constraints.maxWidth * (1 - _dividerPosition);

              return Row(
                children: [
                  // Left panel - Editor
                  SizedBox(
                    width: leftWidth,
                    child: _buildEditorPanel(),
                  ),

                  // Divider
                  MouseRegion(
                    cursor: SystemMouseCursors.resizeColumn,
                    child: GestureDetector(
                      onHorizontalDragUpdate: (details) {
                        setState(() {
                          _dividerPosition = (leftWidth + details.delta.dx) /
                              constraints.maxWidth;
                          _dividerPosition = _dividerPosition.clamp(0.3, 0.7);
                        });
                      },
                      child: Container(
                        width: 8,
                        color: theme.dividerColor,
                        child: Center(
                          child: Container(
                            width: 2,
                            color: theme.colorScheme.primary
                                .withValues(alpha: 0.3),
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Right panel - PDF Preview
                  SizedBox(
                    width: rightWidth - 8,
                    child: _buildPreviewPanel(),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildEditorPanel() {
    return Container(
      color: Theme.of(context).colorScheme.surface,
      child: TabBarView(
        controller: _tabController,
        children: [
          _buildCvEditor(),
          _buildCoverLetterEditor(),
        ],
      ),
    );
  }

  Widget _buildCvEditor() {
    if (_cvData == null) {
      return const Center(child: Text('No CV data available'));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'CV Content Editor',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 16),
          Text(
            'Customize your CV for this specific job. Changes are saved automatically and only affect this application.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.color
                      ?.withValues(alpha: 0.7),
                ),
          ),
          const SizedBox(height: 24),

          // Display CV data summary
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'CV Data Summary',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 12),
                  if (_cvData!.personalInfo != null) ...[
                    Text('Name: ${_cvData!.personalInfo!.fullName}'),
                    if (_cvData!.personalInfo!.email != null)
                      Text('Email: ${_cvData!.personalInfo!.email}'),
                    const SizedBox(height: 8),
                  ],
                  Text('Experiences: ${_cvData!.experiences.length}'),
                  Text('Education: ${_cvData!.education.length}'),
                  Text('Skills: ${_cvData!.skills.length}'),
                  Text('Languages: ${_cvData!.languages.length}'),
                  const SizedBox(height: 12),
                  Text(
                    'Full CV editing coming in Phase 2',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontStyle: FontStyle.italic,
                        ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCoverLetterEditor() {
    if (_coverLetter == null) {
      return const Center(child: Text('No cover letter data available'));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Cover Letter Editor',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 24),
          TextField(
            controller: TextEditingController(text: _coverLetter!.greeting),
            decoration: const InputDecoration(
              labelText: 'Greeting',
              border: OutlineInputBorder(),
            ),
            onChanged: (value) {
              _coverLetter = _coverLetter!.copyWith(greeting: value);
              _saveCoverLetter();
            },
          ),
          const SizedBox(height: 16),
          TextField(
            controller: TextEditingController(text: _coverLetter!.body),
            decoration: const InputDecoration(
              labelText: 'Body',
              border: OutlineInputBorder(),
            ),
            maxLines: 15,
            onChanged: (value) {
              _coverLetter = _coverLetter!.copyWith(body: value);
              _saveCoverLetter();
              setState(() {}); // Trigger PDF preview update
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPreviewPanel() {
    if (_cvData == null && _coverLetter == null) {
      return Container(
        color: Theme.of(context).colorScheme.surfaceContainerLow,
        child: const Center(child: Text('No data to preview')),
      );
    }

    return Container(
      color: Theme.of(context).colorScheme.surfaceContainerLow,
      child: PdfPreview(
        build: (format) => _generatePdf(),
        canChangeOrientation: false,
        canDebug: false,
        allowPrinting: true,
        allowSharing: true,
        maxPageWidth: 700,
        pdfFileName:
            '${widget.application.company}_${widget.application.position}_${_tabController.index == 0 ? 'CV' : 'CoverLetter'}.pdf',
      ),
    );
  }

  /// Generate PDF bytes based on current tab
  Future<Uint8List> _generatePdf() async {
    try {
      final style = TemplateStyle.defaultStyle;

      if (_tabController.index == 0) {
        // CV Preview
        if (_cvData == null || _cvData!.personalInfo == null) {
          return Uint8List(0);
        }

        // Convert JobCvData to CvData format with proper type conversions
        final cvData = CvData(
          id: widget.application.id,
          name:
              '${widget.application.position} at ${widget.application.company}',
          language: widget.application.baseLanguage,
          profile: '', // PersonalInfo doesn't have summary field
          skills: _cvData!.skills.map((s) => s.name).toList(),
          languages: _cvData!.languages
              .map((l) => LanguageSkill(
                    language: l.name,
                    level: l.proficiency.name, // Convert enum to string
                  ))
              .toList(),
          interests: _cvData!.interests.map((i) => i.name).toList(),
          contactDetails: ContactDetails(
            fullName: _cvData!.personalInfo!.fullName,
            jobTitle: _cvData!.personalInfo!.jobTitle ?? '',
            email: _cvData!.personalInfo!.email ?? '',
            phone: _cvData!.personalInfo!.phone ?? '',
            address: _cvData!.personalInfo!.address ?? '',
            linkedin:
                _cvData!.personalInfo!.linkedin ?? '', // Correct field name
            website: _cvData!.personalInfo!.website ?? '',
            profilePicturePath: _cvData!.personalInfo!.profilePicturePath,
          ),
          experiences: _cvData!.experiences
              .map((exp) => Experience(
                    company: exp.company,
                    title:
                        exp.position, // Correct field name: position not title
                    startDate: _formatDate(exp.startDate),
                    endDate: exp.endDate != null
                        ? _formatDate(exp.endDate!)
                        : 'Present',
                    description: exp.description ?? '',
                    bullets: exp.responsibilities,
                  ))
              .toList(),
          education: _cvData!.education
              .map((edu) => cv_data.Education(
                    institution: edu.institution,
                    degree: edu.degree,
                    // No 'field' parameter - Education model doesn't have it
                    startDate: _formatDate(edu.startDate),
                    endDate: edu.endDate != null
                        ? _formatDate(edu.endDate!)
                        : 'Present',
                    description: edu.description ?? '',
                  ))
              .toList()
              .cast<cv_data.Education>(), // Explicit cast for type safety
        );

        return await PdfService.instance.generateCvPdf(
          cvData,
          style,
          customization: _pdfSettings,
        );
      } else {
        // Cover Letter Preview
        if (_coverLetter == null) {
          return Uint8List(0);
        }

        // Convert JobCoverLetter to CoverLetter format
        final coverLetter = CoverLetter(
          id: widget.application.id,
          name:
              '${widget.application.position} at ${widget.application.company}',
          recipientName: _coverLetter!.recipientName,
          companyName: _coverLetter!.companyName,
          // No companyAddress, opening, sender fields in CoverLetter model
          greeting: _coverLetter!.greeting,
          body: _coverLetter!.body,
          closing: _coverLetter!.closing,
          senderName: _cvData?.personalInfo?.fullName,
        );

        return await PdfService.instance.generateCoverLetterPdf(
          coverLetter,
          style,
          customization: _pdfSettings,
        );
      }
    } catch (e) {
      debugPrint('Error generating PDF: $e');
      return Uint8List(0);
    }
  }

  /// Format DateTime to string for PDF
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
}
