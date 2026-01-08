/// Cover Letter tab - Create and edit cover letter for this application
Widget _buildCoverLetterTab() {
  final theme = Theme.of(context);
  final application = widget.applicationContext;
  final hasContent = _bodyController.text.isNotEmpty;
  final wordCount = _bodyController.text
      .trim()
      .split(RegExp(r'\s+'))
      .where((word) => word.isNotEmpty)
      .length;
  final charCount = _bodyController.text.length;

  return SingleChildScrollView(
    padding: const EdgeInsets.all(24),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Row(
          children: [
            Icon(Icons.email, color: theme.colorScheme.primary, size: 28),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Cover Letter',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Personalize your cover letter for this application',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            ),
            OutlinedButton.icon(
              onPressed: () {
                // TODO: Implement template selector
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Template selection coming soon!'),
                    duration: Duration(seconds: 2),
                  ),
                );
              },
              icon: const Icon(Icons.library_books, size: 18),
              label: const Text('From Template'),
            ),
          ],
        ),
        const SizedBox(height: 24),

        // Recipient Information Card
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.person_outline,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Recipient Information',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _recipientNameController,
                  decoration: const InputDecoration(
                    labelText: 'Recipient Name',
                    hintText: 'e.g., Jane Smith',
                    prefixIcon: Icon(Icons.person),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _recipientTitleController,
                  decoration: const InputDecoration(
                    labelText: 'Recipient Title',
                    hintText: 'e.g., HR Manager',
                    prefixIcon: Icon(Icons.badge),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  initialValue: application?.company ?? '',
                  decoration: const InputDecoration(
                    labelText: 'Company Name',
                    prefixIcon: Icon(Icons.business),
                    border: OutlineInputBorder(),
                    enabled: false,
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  initialValue: application?.position ?? '',
                  decoration: const InputDecoration(
                    labelText: 'Position',
                    prefixIcon: Icon(Icons.work),
                    border: OutlineInputBorder(),
                    enabled: false,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Letter Content Card
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.article_outlined,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Letter Content',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _greetingController,
                  decoration: const InputDecoration(
                    labelText: 'Greeting',
                    hintText: 'Dear [Name],',
                    prefixIcon: Icon(Icons.waving_hand),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),

                // Placeholder guide
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: theme.colorScheme.primary.withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.lightbulb_outline,
                        size: 18,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Use ==COMPANY== and ==POSITION== as placeholders. They will be replaced automatically.',
                          style: theme.textTheme.bodySmall,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: _bodyController,
                  decoration: const InputDecoration(
                    labelText: 'Letter Body',
                    hintText:
                        'Write your cover letter here...\n\nExample:\nI am writing to express my interest in the ==POSITION== position at ==COMPANY==...',
                    border: OutlineInputBorder(),
                    alignLabelWithHint: true,
                  ),
                  maxLines: 15,
                  minLines: 10,
                ),
                const SizedBox(height: 8),

                // Word and character count
                Row(
                  children: [
                    Icon(
                      Icons.text_fields,
                      size: 14,
                      color: theme.textTheme.bodySmall?.color?.withOpacity(0.6),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '$charCount characters • $wordCount words',
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontSize: 12,
                        color: theme.textTheme.bodySmall?.color?.withOpacity(
                          0.6,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: _closingController,
                  decoration: const InputDecoration(
                    labelText: 'Closing',
                    hintText: 'e.g., Best regards,',
                    prefixIcon: Icon(Icons.edit_note),
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 16),

        // Preview button
        if (hasContent)
          SizedBox(
            width: double.infinity,
            child: FilledButton.tonalIcon(
              onPressed: () {
                // TODO: Show PDF preview
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('PDF preview coming soon!'),
                    duration: Duration(seconds: 2),
                  ),
                );
              },
              icon: const Icon(Icons.picture_as_pdf),
              label: const Text('Preview Cover Letter PDF'),
            ),
          ),
      ],
    ),
  );
}
