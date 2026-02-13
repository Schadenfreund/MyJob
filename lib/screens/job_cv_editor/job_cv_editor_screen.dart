import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';
import 'package:provider/provider.dart';
import '../../models/job_application.dart';
import '../../models/job_cv_data.dart';
import '../../services/storage_service.dart';
import '../../providers/applications_provider.dart';
import '../../widgets/job_cv_editor_widget.dart';
import '../../dialogs/job_application_pdf_dialog.dart';
import '../../widgets/draggable_dialog_wrapper.dart';
import '../../localization/app_localizations.dart';

/// Full content editor for job-specific CV
///
/// Provides comprehensive editing of all CV sections for a specific job application.
/// Users can add/edit/delete experiences, education, skills, and all other CV content.
class JobCvEditorScreen extends StatefulWidget {
  const JobCvEditorScreen({
    required this.application,
    required this.cvData,
    this.coverLetter,
    super.key,
  });

  final JobApplication application;
  final JobCvData cvData;
  final dynamic coverLetter; // JobCoverLetter

  @override
  State<JobCvEditorScreen> createState() => _JobCvEditorScreenState();
}

class _JobCvEditorScreenState extends State<JobCvEditorScreen> {
  late JobCvData _currentCvData;
  dynamic _currentCoverLetter; // JobCoverLetter
  bool _hasUnsavedChanges = false;
  bool _isSaving = false;
  int _currentTabIndex = 0; // Track current tab (0-7, where 7 is Cover Letter)
  final _storage = StorageService.instance;

  @override
  void initState() {
    super.initState();
    _currentCvData = widget.cvData;
    _currentCoverLetter = widget.coverLetter;

    // Reload cover letter from storage to ensure we have the latest data
    _reloadCoverLetter();
  }

  /// Reload cover letter from storage
  Future<void> _reloadCoverLetter() async {
    if (widget.application.folderPath == null) return;

    try {
      final coverLetter = await _storage.loadJobCoverLetter(
        widget.application.folderPath!,
      );

      if (mounted && coverLetter != null) {
        setState(() {
          _currentCoverLetter = coverLetter;
        });
      }
    } catch (e) {
      debugPrint('Failed to reload cover letter: $e');
    }
  }

  /// Handle CV data changes from the editor widget
  void _onCvDataChanged(JobCvData updatedData) {
    setState(() {
      _currentCvData = updatedData;
      _hasUnsavedChanges = true;
    });
    // Auto-save after a short delay
    _autoSave();
  }

  /// Handle application metadata changes from the Details tab
  void _onApplicationChanged(JobApplication updatedApplication) async {
    try {
      final provider = context.read<ApplicationsProvider>();
      await provider.updateApplication(updatedApplication);

      // Silently saved - no snackbar needed (matches behavior of CV data changes)
    } catch (e) {
      debugPrint('Failed to save application metadata: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${context.tr('failed_update_app_details')}: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  /// Auto-save changes to job folder
  Future<void> _autoSave() async {
    if (widget.application.folderPath == null) return;

    setState(() => _isSaving = true);

    try {
      await _storage.saveJobCvData(
        widget.application.folderPath!,
        _currentCvData,
      );

      if (mounted) {
        setState(() {
          _hasUnsavedChanges = false;
          _isSaving = false;
        });
      }
    } catch (e) {
      debugPrint('Auto-save failed: $e');
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  /// Manually save changes
  Future<void> _save() async {
    if (widget.application.folderPath == null) return;

    setState(() => _isSaving = true);

    try {
      await _storage.saveJobCvData(
        widget.application.folderPath!,
        _currentCvData,
      );

      if (mounted) {
        setState(() {
          _hasUnsavedChanges = false;
          _isSaving = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 12),
                Text(context.tr('all_changes_saved')),
              ],
            ),
            backgroundColor: Colors.green.shade600,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${context.tr('failed_save_changes')}: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  /// Show PDF preview/customization dialog
  Future<void> _showPdfCustomization() async {
    // Auto-save before showing preview
    if (_hasUnsavedChanges) {
      await _save();
    }

    // Reload cover letter to ensure we have the latest changes
    await _reloadCoverLetter();

    if (!mounted) return;

    // Determine if user is on Cover Letter tab (index 7)
    final isCoverLetterTab = _currentTabIndex == 7;

    await showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black54,
      builder: (context) => DraggableDialogWrapper(
        child: JobApplicationPdfDialog(
          application: widget.application,
          cvData: _currentCvData,
          coverLetter: _currentCoverLetter,
          isCV:
              !isCoverLetterTab, // Show cover letter PDF if on cover letter tab
        ),
      ),
    );
  }

  /// Handle back navigation with unsaved changes warning
  Future<bool> _onWillPop() async {
    if (!_hasUnsavedChanges) return true;

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.tr('unsaved_changes')),
        content: Text(
          context.tr('unsaved_changes_leave_message'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(context.tr('discard')),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context, false);
              await _save();
              if (mounted) {
                Navigator.pop(context, true);
              }
            },
            child: Text(context.tr('save_and_close')),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(context.tr('cancel')),
          ),
        ],
      ),
    );

    return result == false;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return PopScope(
      canPop: !_hasUnsavedChanges,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final shouldPop = await _onWillPop();
        if (shouldPop && context.mounted) {
          Navigator.pop(context);
        }
      },
      child: Scaffold(
        appBar: AppBar(
          // Make entire AppBar draggable
          flexibleSpace: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onPanStart: (details) => windowManager.startDragging(),
            child: const SizedBox.expand(),
          ),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(context.tr('edit_content')),
              Text(
                '${widget.application.company} • ${widget.application.position}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
            ],
          ),
          actions: [
            // Saving indicator
            if (_isSaving)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    const SizedBox(width: 8),
                    Text(context.tr('saving')),
                  ],
                ),
              ),

            // Unsaved changes indicator
            if (_hasUnsavedChanges && !_isSaving)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.circle,
                        size: 8,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        context.tr('unsaved'),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onPrimaryContainer,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            // Manual save button
            if (_hasUnsavedChanges && !_isSaving)
              TextButton.icon(
                onPressed: _save,
                icon: const Icon(Icons.save, size: 18),
                label: Text(context.tr('save')),
              ),

            const SizedBox(width: 8),

            // Preview PDF button
            ElevatedButton.icon(
              onPressed: _showPdfCustomization,
              icon: const Icon(Icons.picture_as_pdf_outlined, size: 18),
              label: Text(context.tr('preview_pdf')),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
              ),
            ),

            const SizedBox(width: 16),
          ],
        ),
        body: JobCvEditorWidget(
          cvData: _currentCvData,
          onChanged: _onCvDataChanged,
          applicationContext: widget.application,
          onApplicationChanged: _onApplicationChanged,
          coverLetter: _currentCoverLetter,
          onTabChanged: (index) {
            setState(() {
              _currentTabIndex = index;
            });

            // Reload cover letter when switching to cover letter tab (tab 7)
            if (index == 7) {
              _reloadCoverLetter();
            }
          },
        ),
      ),
    );
  }
}
