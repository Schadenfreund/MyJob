import 'package:flutter/material.dart';

/// Reusable Cover Letter editor form widget (DRY principle)
/// Works with CoverLetter, CoverLetterTemplate, and CoverLetterInstance
class CoverLetterEditorForm extends StatefulWidget {
  const CoverLetterEditorForm({
    super.key,
    required this.initialName,
    required this.initialGreeting,
    required this.initialBody,
    required this.initialClosing,
    required this.initialSenderName,
    required this.onDataChanged,
    this.initialRecipientName,
    this.initialRecipientTitle,
    this.initialCompanyName,
    this.initialJobTitle,
    this.initialSenderEmail,
    this.initialSenderPhone,
    this.initialSenderAddress,
    this.nameLabel = 'Letter Name',
    this.nameHint = 'e.g., Tech Company Application',
    this.showRecipientFields = true,
    this.showSenderContactFields = true,
  });

  final String initialName;
  final String initialGreeting;
  final String initialBody;
  final String initialClosing;
  final String? initialSenderName;
  final String? initialRecipientName;
  final String? initialRecipientTitle;
  final String? initialCompanyName;
  final String? initialJobTitle;
  final String? initialSenderEmail;
  final String? initialSenderPhone;
  final String? initialSenderAddress;
  final Function(CoverLetterEditorData) onDataChanged;
  final String nameLabel;
  final String nameHint;
  final bool showRecipientFields;
  final bool showSenderContactFields;

  @override
  State<CoverLetterEditorForm> createState() => _CoverLetterEditorFormState();
}

class _CoverLetterEditorFormState extends State<CoverLetterEditorForm> {
  late final TextEditingController _nameController;
  late final TextEditingController _recipientNameController;
  late final TextEditingController _recipientTitleController;
  late final TextEditingController _companyNameController;
  late final TextEditingController _jobTitleController;
  late final TextEditingController _greetingController;
  late final TextEditingController _bodyController;
  late final TextEditingController _closingController;
  late final TextEditingController _senderNameController;
  late final TextEditingController _senderEmailController;
  late final TextEditingController _senderPhoneController;
  late final TextEditingController _senderAddressController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialName);
    _recipientNameController = TextEditingController(text: widget.initialRecipientName ?? '');
    _recipientTitleController = TextEditingController(text: widget.initialRecipientTitle ?? '');
    _companyNameController = TextEditingController(text: widget.initialCompanyName ?? '');
    _jobTitleController = TextEditingController(text: widget.initialJobTitle ?? '');
    _greetingController = TextEditingController(text: widget.initialGreeting);
    _bodyController = TextEditingController(text: widget.initialBody);
    _closingController = TextEditingController(text: widget.initialClosing);
    _senderNameController = TextEditingController(text: widget.initialSenderName ?? '');
    _senderEmailController = TextEditingController(text: widget.initialSenderEmail ?? '');
    _senderPhoneController = TextEditingController(text: widget.initialSenderPhone ?? '');
    _senderAddressController = TextEditingController(text: widget.initialSenderAddress ?? '');

    // Notify parent of initial data after build completes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _notifyDataChanged();
    });
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

  void _notifyDataChanged() {
    widget.onDataChanged(CoverLetterEditorData(
      name: _nameController.text,
      greeting: _greetingController.text,
      body: _bodyController.text,
      closing: _closingController.text,
      senderName: _senderNameController.text.isEmpty ? null : _senderNameController.text,
      recipientName: _recipientNameController.text.isEmpty ? null : _recipientNameController.text,
      recipientTitle: _recipientTitleController.text.isEmpty ? null : _recipientTitleController.text,
      companyName: _companyNameController.text.isEmpty ? null : _companyNameController.text,
      jobTitle: _jobTitleController.text.isEmpty ? null : _jobTitleController.text,
      senderEmail: _senderEmailController.text.isEmpty ? null : _senderEmailController.text,
      senderPhone: _senderPhoneController.text.isEmpty ? null : _senderPhoneController.text,
      senderAddress: _senderAddressController.text.isEmpty ? null : _senderAddressController.text,
    ));
  }

  /// Get list of placeholders that haven't been filled yet
  List<String> _getUnfilledPlaceholders() {
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        // Name
        TextFormField(
          controller: _nameController,
          decoration: InputDecoration(
            labelText: widget.nameLabel,
            hintText: widget.nameHint,
          ),
          onChanged: (_) => _notifyDataChanged(),
        ),
        const SizedBox(height: 24),

        // Sender Info
        Text('Your Information', style: theme.textTheme.headlineSmall),
        const SizedBox(height: 16),
        TextFormField(
          controller: _senderNameController,
          decoration: const InputDecoration(labelText: 'Your Name'),
          onChanged: (_) => _notifyDataChanged(),
        ),
        if (widget.showSenderContactFields) ...[
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _senderEmailController,
                  decoration: const InputDecoration(labelText: 'Email'),
                  onChanged: (_) => _notifyDataChanged(),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextFormField(
                  controller: _senderPhoneController,
                  decoration: const InputDecoration(labelText: 'Phone'),
                  onChanged: (_) => _notifyDataChanged(),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _senderAddressController,
            decoration: const InputDecoration(labelText: 'Address'),
            onChanged: (_) => _notifyDataChanged(),
          ),
        ],
        const SizedBox(height: 24),

        if (widget.showRecipientFields) ...[
          // Recipient Info
          Text('Recipient Information', style: theme.textTheme.headlineSmall),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _recipientNameController,
                  decoration: const InputDecoration(labelText: 'Recipient Name'),
                  onChanged: (_) => _notifyDataChanged(),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextFormField(
                  controller: _recipientTitleController,
                  decoration: const InputDecoration(labelText: 'Title'),
                  onChanged: (_) => _notifyDataChanged(),
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
                  decoration: const InputDecoration(labelText: 'Company'),
                  onChanged: (_) => _notifyDataChanged(),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextFormField(
                  controller: _jobTitleController,
                  decoration: const InputDecoration(labelText: 'Job Title'),
                  onChanged: (_) => _notifyDataChanged(),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
        ],

        // Letter Content
        Text('Letter Content', style: theme.textTheme.headlineSmall),
        const SizedBox(height: 16),
        TextFormField(
          controller: _greetingController,
          decoration: const InputDecoration(
            labelText: 'Greeting',
            hintText: 'e.g., Dear Hiring Manager,',
          ),
          onChanged: (_) => _notifyDataChanged(),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _bodyController,
          decoration: const InputDecoration(
            labelText: 'Body',
            hintText: 'Write your cover letter...\n\nUse ==PLACEHOLDER== for dynamic content.',
            alignLabelWithHint: true,
          ),
          maxLines: 15,
          onChanged: (_) {
            setState(() {});
            _notifyDataChanged();
          },
        ),
        const SizedBox(height: 12),

        // Placeholder detection
        if (_getUnfilledPlaceholders().isNotEmpty) ...[
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
          onChanged: (_) => _notifyDataChanged(),
        ),
      ],
    );
  }
}

/// Data class for Cover Letter editor output
class CoverLetterEditorData {
  final String name;
  final String greeting;
  final String body;
  final String closing;
  final String? senderName;
  final String? recipientName;
  final String? recipientTitle;
  final String? companyName;
  final String? jobTitle;
  final String? senderEmail;
  final String? senderPhone;
  final String? senderAddress;

  CoverLetterEditorData({
    required this.name,
    required this.greeting,
    required this.body,
    required this.closing,
    this.senderName,
    this.recipientName,
    this.recipientTitle,
    this.companyName,
    this.jobTitle,
    this.senderEmail,
    this.senderPhone,
    this.senderAddress,
  });

  /// Get auto-filled placeholders from form fields
  Map<String, String> get placeholders {
    final map = <String, String>{};
    if (companyName != null && companyName!.isNotEmpty) {
      map['COMPANY'] = companyName!;
    }
    if (jobTitle != null && jobTitle!.isNotEmpty) {
      map['POSITION'] = jobTitle!;
    }
    return map;
  }
}
