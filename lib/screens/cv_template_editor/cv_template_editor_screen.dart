import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/cv_template.dart';
import '../../providers/templates_provider.dart';
import '../../widgets/tabbed_cv_editor.dart';
import '../../dialogs/cv_template_pdf_preview_launcher.dart';
import '../../localization/app_localizations.dart';

/// CV Template Editor Screen - Streamlined content-focused editor
///
/// **UX IMPROVEMENT:** Removed template style sidebar - users now select
/// styles directly in the PDF preview dialog where they can see real-time results.
class CvTemplateEditorScreen extends StatefulWidget {
  const CvTemplateEditorScreen({
    required this.templateId,
    super.key,
  });

  final String templateId;

  @override
  State<CvTemplateEditorScreen> createState() => _CvTemplateEditorScreenState();
}

class _CvTemplateEditorScreenState extends State<CvTemplateEditorScreen> {
  CvTemplate? _template;
  CvTemplate? _currentTemplate;
  bool _hasUnsavedChanges = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTemplate();
  }

  Future<void> _loadTemplate() async {
    final provider = context.read<TemplatesProvider>();
    final template = provider.getCvTemplateById(widget.templateId);

    if (template == null) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.tr('template_not_found'))),
        );
      }
      return;
    }

    setState(() {
      _template = template;
      _isLoading = false;
    });
  }

  Future<void> _save() async {
    if (_template == null || _currentTemplate == null) return;

    try {
      final provider = context.read<TemplatesProvider>();

      final updatedTemplate = _currentTemplate!.copyWith(
        lastModified: DateTime.now(),
      );

      await provider.updateCvTemplate(updatedTemplate);

      setState(() {
        _template = updatedTemplate;
        _currentTemplate = updatedTemplate;
        _hasUnsavedChanges = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.tr('template_saved')),
            backgroundColor: Theme.of(context).colorScheme.primary,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${context.tr('template_save_failed')}: ${e.toString()}'),
            backgroundColor: Theme.of(context).colorScheme.error,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  void _onTemplateChanged(CvTemplate template) {
    setState(() {
      _currentTemplate = template;
      _hasUnsavedChanges = true;
    });
  }

  Future<bool> _onWillPop() async {
    if (!_hasUnsavedChanges) return true;

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.tr('discard_changes')),
        content: Text(
          context.tr('discard_changes_message'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(context.tr('cancel')),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: Text(context.tr('discard')),
          ),
        ],
      ),
    );

    return result ?? false;
  }

  Future<void> _handlePreview() async {
    // Auto-save if there are changes
    if (_hasUnsavedChanges) {
      // Show saving indicator
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                const SizedBox(width: 16),
                Text(context.tr('saving_changes')),
              ],
            ),
            duration: const Duration(seconds: 1),
          ),
        );
      }
      await _save();
    }

    if (_template == null) return;

    final previewTemplate = _currentTemplate ?? _template!;

    if (mounted) {
      await CvTemplatePdfPreviewLauncher.openPreview(
        context: context,
        cvTemplate: previewTemplate,
        templateStyle: previewTemplate.templateStyle,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: Text(context.tr('loading'))),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_template == null) {
      return Scaffold(
        appBar: AppBar(title: Text(context.tr('error'))),
        body: Center(child: Text(context.tr('template_not_found'))),
      );
    }

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
          title: Row(
            children: [
              Text('${context.tr('edit')}: ${_template!.name}'),
              if (_hasUnsavedChanges) ...[
                const SizedBox(width: 8),
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
                    context.tr('unsaved'),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onPrimaryContainer,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ],
          ),
          actions: [
            if (_hasUnsavedChanges)
              TextButton.icon(
                onPressed: _save,
                icon: const Icon(Icons.save, size: 18),
                label: Text(context.tr('save')),
                style: TextButton.styleFrom(
                  foregroundColor: theme.colorScheme.primary,
                ),
              ),
            const SizedBox(width: 8),
            ElevatedButton.icon(
              onPressed: _handlePreview,
              icon: const Icon(Icons.visibility, size: 18),
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
        body: TabbedCvEditor(
          template: _currentTemplate ?? _template!,
          onChanged: _onTemplateChanged,
        ),
      ),
    );
  }
}
