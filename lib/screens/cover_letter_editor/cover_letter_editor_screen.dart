import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:printing/printing.dart';
import '../../providers/documents_provider.dart';
import '../../models/cover_letter.dart';
import '../../models/template_style.dart';
import '../../services/settings_service.dart';

class CoverLetterEditorScreen extends StatefulWidget {
  const CoverLetterEditorScreen({super.key, required this.letterId});

  final String letterId;

  @override
  State<CoverLetterEditorScreen> createState() =>
      _CoverLetterEditorScreenState();
}

class _CoverLetterEditorScreenState extends State<CoverLetterEditorScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _recipientNameController = TextEditingController();
  final _recipientTitleController = TextEditingController();
  final _companyNameController = TextEditingController();
  final _jobTitleController = TextEditingController();
  final _greetingController = TextEditingController();
  final _bodyController = TextEditingController();
  final _closingController = TextEditingController();
  final _senderNameController = TextEditingController();

  // Sender contact info for PDF
  final _senderEmailController = TextEditingController();
  final _senderPhoneController = TextEditingController();
  final _senderAddressController = TextEditingController();

  CoverLetter? _letter;
  TemplateStyle _selectedTemplate = TemplateStyle.professional;

  @override
  void initState() {
    super.initState();
    _loadLetter();
  }

  void _loadLetter() {
    final provider = context.read<DocumentsProvider>();
    _letter = provider.getCoverLetterById(widget.letterId);
    if (_letter != null) {
      _nameController.text = _letter!.name;
      _recipientNameController.text = _letter!.recipientName ?? '';
      _recipientTitleController.text = _letter!.recipientTitle ?? '';
      _companyNameController.text = _letter!.companyName ?? '';
      _jobTitleController.text = _letter!.jobTitle ?? '';
      _greetingController.text = _letter!.greeting;
      _bodyController.text = _letter!.body;
      _closingController.text = _letter!.closing;
      _senderNameController.text = _letter!.senderName ?? '';
    }

    final settings = context.read<SettingsService>();
    _selectedTemplate = settings.defaultCoverLetterTemplate;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _recipientNameController.dispose();
    _recipientTitleController.dispose();
    _companyNameController.dispose();
    _jobTitleController.dispose();
    _greetingController.dispose();
    _bodyController.dispose();
    _closingController.dispose();
    _senderNameController.dispose();
    _senderEmailController.dispose();
    _senderPhoneController.dispose();
    _senderAddressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(_letter?.name ?? 'Edit Cover Letter'),
        actions: [
          IconButton(
            icon: const Icon(Icons.preview),
            tooltip: 'Preview PDF',
            onPressed: _previewPdf,
          ),
          IconButton(
            icon: const Icon(Icons.save),
            tooltip: 'Save',
            onPressed: _save,
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: Row(
          children: [
            // Editor
            Expanded(
              flex: 2,
              child: ListView(
                padding: const EdgeInsets.all(24),
                children: [
                  // Name
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Letter Name',
                      hintText: 'e.g., Tech Company Application',
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Sender Info
                  Text('Your Information',
                      style: theme.textTheme.headlineSmall),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _senderNameController,
                    decoration: const InputDecoration(labelText: 'Your Name'),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _senderEmailController,
                          decoration: const InputDecoration(labelText: 'Email'),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextFormField(
                          controller: _senderPhoneController,
                          decoration: const InputDecoration(labelText: 'Phone'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _senderAddressController,
                    decoration: const InputDecoration(labelText: 'Address'),
                  ),
                  const SizedBox(height: 24),

                  // Recipient Info
                  Text('Recipient Information',
                      style: theme.textTheme.headlineSmall),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _recipientNameController,
                          decoration: const InputDecoration(
                              labelText: 'Recipient Name'),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextFormField(
                          controller: _recipientTitleController,
                          decoration: const InputDecoration(labelText: 'Title'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _companyNameController,
                          decoration:
                              const InputDecoration(labelText: 'Company'),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextFormField(
                          controller: _jobTitleController,
                          decoration:
                              const InputDecoration(labelText: 'Job Title'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Letter Content
                  Text('Letter Content', style: theme.textTheme.headlineSmall),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _greetingController,
                    decoration: const InputDecoration(
                      labelText: 'Greeting',
                      hintText: 'e.g., Dear Hiring Manager,',
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _bodyController,
                    decoration: const InputDecoration(
                      labelText: 'Body',
                      hintText:
                          'Write your cover letter...\n\nUse ==PLACEHOLDER== for dynamic content.',
                      alignLabelWithHint: true,
                    ),
                    maxLines: 15,
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: 12),

                  // Placeholder detection
                  if (_letter != null && _getUnfilledPlaceholders().isNotEmpty) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.errorContainer,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.warning_amber_rounded,
                                color: theme.colorScheme.error,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Unfilled Placeholders',
                                style: theme.textTheme.titleSmall?.copyWith(
                                  color: theme.colorScheme.error,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: _getUnfilledPlaceholders().map((placeholder) {
                              return Chip(
                                label: Text('==$placeholder=='),
                                backgroundColor: theme.colorScheme.error.withOpacity(0.1),
                                labelStyle: TextStyle(
                                  color: theme.colorScheme.error,
                                  fontFamily: 'monospace',
                                  fontWeight: FontWeight.bold,
                                ),
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'These placeholders need to be customized for this application',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.error,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Helper tips
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.secondaryContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.lightbulb_outline,
                              color: theme.colorScheme.secondary,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Tips for Customization',
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '• Use ==COMPANY== for the company name',
                          style: theme.textTheme.bodySmall,
                        ),
                        Text(
                          '• Use ==POSITION== for the job title',
                          style: theme.textTheme.bodySmall,
                        ),
                        Text(
                          '• Replace ==XX== placeholders with job-specific details',
                          style: theme.textTheme.bodySmall,
                        ),
                        Text(
                          '• Auto-filled values from recipient fields above',
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _closingController,
                    decoration: const InputDecoration(
                      labelText: 'Closing',
                      hintText: 'e.g., Kind regards,',
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Save button
                  ElevatedButton.icon(
                    onPressed: _save,
                    icon: const Icon(Icons.save),
                    label: const Padding(
                      padding: EdgeInsets.all(12),
                      child: Text('Save Cover Letter'),
                    ),
                  ),
                ],
              ),
            ),

            // Template selector sidebar
            Container(
              width: 280,
              decoration: BoxDecoration(
                color: theme.cardColor,
                border: Border(
                  left: BorderSide(color: theme.dividerColor),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      'Template',
                      style: theme.textTheme.titleMedium,
                    ),
                  ),
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      children: TemplateStyle.allPresets.map((template) {
                        final isSelected =
                            _selectedTemplate.type == template.type &&
                                _selectedTemplate.primaryColor.toARGB32() ==
                                    template.primaryColor.toARGB32();
                        return _TemplateCard(
                          template: template,
                          isSelected: isSelected,
                          onTap: () {
                            setState(() => _selectedTemplate = template);
                          },
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Get list of placeholders that haven't been filled yet
  List<String> _getUnfilledPlaceholders() {
    if (_letter == null) return [];

    final bodyText = _bodyController.text;
    final regex = RegExp(r'==([A-Za-z0-9_\s]+)==');
    final matches = regex.allMatches(bodyText);

    final unfilled = <String>[];
    for (final match in matches) {
      final placeholder = match.group(1)!;
      // Check if it's not auto-filled
      if (placeholder.toUpperCase() != 'COMPANY' &&
          placeholder.toUpperCase() != 'POSITION' &&
          placeholder.trim() != '') {
        unfilled.add(placeholder);
      }
    }

    return unfilled.toSet().toList();
  }

  Future<void> _save() async {
    if (_letter == null) return;

    // Auto-fill placeholders from form fields
    final placeholders = <String, String>{};
    if (_companyNameController.text.isNotEmpty) {
      placeholders['COMPANY'] = _companyNameController.text;
    }
    if (_jobTitleController.text.isNotEmpty) {
      placeholders['POSITION'] = _jobTitleController.text;
    }

    final updatedLetter = _letter!.copyWith(
      name: _nameController.text,
      recipientName: _recipientNameController.text.isEmpty
          ? null
          : _recipientNameController.text,
      recipientTitle: _recipientTitleController.text.isEmpty
          ? null
          : _recipientTitleController.text,
      companyName: _companyNameController.text.isEmpty
          ? null
          : _companyNameController.text,
      jobTitle:
          _jobTitleController.text.isEmpty ? null : _jobTitleController.text,
      greeting: _greetingController.text,
      body: _bodyController.text,
      closing: _closingController.text,
      senderName: _senderNameController.text.isEmpty
          ? null
          : _senderNameController.text,
      placeholders: placeholders,
    );

    await context.read<DocumentsProvider>().updateCoverLetter(updatedLetter);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cover letter saved successfully')),
      );
    }
  }

  Future<void> _previewPdf() async {
    await _save();

    if (_letter == null) return;

    final provider = context.read<DocumentsProvider>();
    final letter = provider.getCoverLetterById(widget.letterId);
    if (letter == null) return;

    try {
      final bytes = await provider.generateCoverLetterPdf(
        letter,
        _selectedTemplate,
        senderAddress: _senderAddressController.text.isEmpty
            ? null
            : _senderAddressController.text,
        senderPhone: _senderPhoneController.text.isEmpty
            ? null
            : _senderPhoneController.text,
        senderEmail: _senderEmailController.text.isEmpty
            ? null
            : _senderEmailController.text,
      );
      if (mounted) {
        await Printing.layoutPdf(onLayout: (_) => bytes);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error generating PDF: $e')),
        );
      }
    }
  }
}

class _TemplateCard extends StatelessWidget {
  const _TemplateCard({
    required this.template,
    required this.isSelected,
    required this.onTap,
  });

  final TemplateStyle template;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(
          color: isSelected ? theme.colorScheme.primary : Colors.transparent,
          width: 2,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 50,
                decoration: BoxDecoration(
                  color: template.primaryColor,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Column(
                  children: [
                    Container(
                      height: 12,
                      color: template.accentColor,
                    ),
                    const Spacer(),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      template.type.label,
                      style: theme.textTheme.titleSmall,
                    ),
                    Text(
                      template.type.description,
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              if (isSelected)
                Icon(
                  Icons.check_circle,
                  color: theme.colorScheme.primary,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
