import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/cover_letter_template.dart';
import '../providers/user_data_provider.dart';
import '../services/profile_autofill_service.dart';
import '../widgets/common/custom_text_field.dart';
import '../widgets/autofill_button.dart';
import '../utils/ui_utils.dart';
import '../localization/app_localizations.dart';

/// Tabbed cover letter editor with organized sections
class TabbedCoverLetterEditor extends StatefulWidget {
  const TabbedCoverLetterEditor({
    required this.template,
    required this.onChanged,
    super.key,
  });

  final CoverLetterTemplate template;
  final ValueChanged<CoverLetterTemplate> onChanged;

  @override
  State<TabbedCoverLetterEditor> createState() =>
      _TabbedCoverLetterEditorState();
}

class _TabbedCoverLetterEditorState extends State<TabbedCoverLetterEditor>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Sender info controllers
  late TextEditingController _senderNameController;

  // Recipient info controllers (now editable for template customization)
  late TextEditingController _recipientNameController;
  late TextEditingController _recipientTitleController;
  late TextEditingController _companyNameController;
  late TextEditingController _jobTitleController;

  // Letter content controllers
  late TextEditingController _greetingController;
  late TextEditingController _bodyController;
  late TextEditingController _closingController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);

    // Initialize controllers
    _senderNameController =
        TextEditingController(text: widget.template.senderName ?? '');
    // Recipient info is left empty - will be filled when creating application
    _recipientNameController = TextEditingController();
    _recipientTitleController = TextEditingController();
    _companyNameController = TextEditingController();
    _jobTitleController = TextEditingController();
    _greetingController = TextEditingController(text: widget.template.greeting);
    _bodyController = TextEditingController(text: widget.template.body);
    _closingController = TextEditingController(text: widget.template.closing);

    // Add listeners (recipient fields are read-only in template mode)
    _senderNameController.addListener(_updateTemplate);
    _greetingController.addListener(_updateTemplate);
    _bodyController.addListener(_updateTemplate);
    _closingController.addListener(_updateTemplate);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _senderNameController.dispose();
    _recipientNameController.dispose();
    _recipientTitleController.dispose();
    _companyNameController.dispose();
    _jobTitleController.dispose();
    _greetingController.dispose();
    _bodyController.dispose();
    _closingController.dispose();
    super.dispose();
  }

  void _updateTemplate() {
    final updatedTemplate = widget.template.copyWith(
      senderName: _senderNameController.text.trim().isNotEmpty
          ? _senderNameController.text.trim()
          : null,
      greeting: _greetingController.text,
      body: _bodyController.text,
      closing: _closingController.text,
    );

    widget.onChanged(updatedTemplate);
  }

  void _autofillFromProfile() {
    final userDataProvider = context.read<UserDataProvider>();
    final autofillService = ProfileAutofillService(userDataProvider);

    final autofilled =
        autofillService.autofillCoverLetterTemplate(widget.template);

    // Update sender name
    _senderNameController.text = autofilled.senderName ?? '';

    _updateTemplate();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        // Tab bar
        Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            border: Border(
              bottom: BorderSide(
                color: theme.dividerColor,
                width: 1,
              ),
            ),
          ),
          child: TabBar(
            controller: _tabController,
            isScrollable: false,
            tabs: [
              _buildTab(Icons.person, context.tr('tab_sender')),
              _buildTab(Icons.business, context.tr('tab_recipient')),
              _buildTab(Icons.article, context.tr('tab_letter')),
            ],
          ),
        ),

        // Tab content
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildSenderTab(),
              _buildRecipientTab(),
              _buildLetterTab(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTab(IconData icon, String label) {
    return Tab(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18),
          const SizedBox(width: 8),
          Text(label),
        ],
      ),
    );
  }

  Widget _buildSenderTab() {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Auto-fill section
          AutofillSection(
            onAutofill: _autofillFromProfile,
            fieldsToFill: [context.tr('sender_name')],
            title: context.tr('autofill_from_profile'),
            description: '',
          ),

          const SizedBox(height: 20),

          Text(
            context.tr('sender_info'),
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 16),

          CustomTextField(
            controller: _senderNameController,
            label: context.tr('sender_name'),
            hint: 'Your Full Name',
            prefixIcon: Icons.person,
          ),

          const SizedBox(height: 12),

          // Info card
          Container(
            decoration: UIUtils.getInfoCard(context),
            padding: const EdgeInsets.all(UIUtils.cardPadding),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  size: 16,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    context.tr('contact_auto_pdf'),
                    style: theme.textTheme.bodySmall?.copyWith(fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecipientTab() {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.tr('recipient_info'),
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 16),

          // Info card
          Container(
            decoration: UIUtils.getInfoCard(context),
            padding: const EdgeInsets.all(UIUtils.cardPadding),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  size: 16,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    context.tr('recipient_fields_info'),
                    style: theme.textTheme.bodySmall?.copyWith(fontSize: 12),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          CustomTextField(
            controller: _recipientNameController,
            label: context.tr('recipient_name'),
            hint: 'Hiring Manager Name',
            prefixIcon: Icons.person_outline,
            enabled: false,
          ),
          const SizedBox(height: 12),

          CustomTextField(
            controller: _recipientTitleController,
            label: context.tr('recipient_title'),
            hint: 'HR Manager',
            prefixIcon: Icons.badge_outlined,
            enabled: false,
          ),
          const SizedBox(height: 12),

          CustomTextField(
            controller: _companyNameController,
            label: context.tr('company_name'),
            hint: 'Target Company',
            prefixIcon: Icons.business_outlined,
            enabled: false,
          ),
          const SizedBox(height: 12),

          CustomTextField(
            controller: _jobTitleController,
            label: context.tr('job_title_label'),
            hint: 'Position Applied For',
            prefixIcon: Icons.work_outline,
            enabled: false,
          ),
        ],
      ),
    );
  }

  Widget _buildLetterTab() {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.tr('letter_content'),
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),

          // Greeting
          CustomTextField(
            controller: _greetingController,
            label: context.tr('greeting'),
            hint: 'Dear Hiring Manager,',
            prefixIcon: Icons.waving_hand,
          ),
          const SizedBox(height: 12),

          // Placeholder guide (BEFORE body textarea for better UX)
          Container(
            decoration: UIUtils.getInfoCard(context),
            padding: const EdgeInsets.all(UIUtils.cardPadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.tips_and_updates,
                      size: 16,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      context.tr('placeholder_tips_title'),
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  context.tr('placeholder_tips_body'),
                  style: theme.textTheme.bodySmall?.copyWith(fontSize: 12),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Body
          CustomTextField(
            controller: _bodyController,
            label: context.tr('letter_body'),
            hint:
                'Write your cover letter here...\n\nUse ==COMPANY== and ==POSITION== as placeholders.',
            maxLines: 15,
            minLines: 10,
            keyboardType: TextInputType.multiline,
            textInputAction: TextInputAction.newline,
          ),

          const SizedBox(height: 12),

          // Closing
          CustomTextField(
            controller: _closingController,
            label: context.tr('closing'),
            hint: 'Kind regards,',
            prefixIcon: Icons.edit_note,
          ),

          const SizedBox(height: 12),

          // Character count and word count
          Row(
            children: [
              Icon(
                Icons.info_outline,
                size: 14,
                color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.6),
              ),
              const SizedBox(width: 6),
              Text(
                context.tr('chars_words_count', {
                  'chars': '${_bodyController.text.length}',
                  'words': '${_bodyController.text.trim().split(RegExp(r'\s+')).where((word) => word.isNotEmpty).length}',
                }),
                style: theme.textTheme.bodySmall?.copyWith(
                  fontSize: 12,
                  color:
                      theme.textTheme.bodySmall?.color?.withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
