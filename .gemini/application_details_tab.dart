/// Application Details Tab - Add this method to JobCvEditorWidget
Widget _buildApplicationDetailsTab() {
  final theme = Theme.of(context);
  final application = widget.applicationContext;

  return SingleChildScrollView(
    padding: const EdgeInsets.all(24),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Row(
          children: [
            Icon(Icons.work, color: theme.colorScheme.primary, size: 28),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Application Details',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Manage status, dates, and notes for this application',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 32),

        // Info card - Read-only for now (would need full application editing integration)
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Company & Position',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 16),
                _buildDetailRow(
                  icon: Icons.business,
                  label: 'Company',
                  value: application.company,
                  theme: theme,
                ),
                const SizedBox(height: 12),
                _buildDetailRow(
                  icon: Icons.badge,
                  label: 'Position',
                  value: application.position,
                  theme: theme,
                ),
                if (application.location != null &&
                    application.location!.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  _buildDetailRow(
                    icon: Icons.location_on,
                    label: 'Location',
                    value: application.location!,
                    theme: theme,
                  ),
                ],
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 16),
                Text(
                  'Status & Timeline',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 16),
                _buildDetailRow(
                  icon: Icons.flag,
                  label: 'Status',
                  value: application.status.toString().split('.').last,
                  theme: theme,
                ),
                if (application.applicationDate != null) ...[
                  const SizedBox(height: 12),
                  _buildDetailRow(
                    icon: Icons.calendar_today,
                    label: 'Applied Date',
                    value: DateFormat(
                      'MMM dd, yyyy',
                    ).format(application.applicationDate!),
                    theme: theme,
                  ),
                ],
                if (application.notes != null &&
                    application.notes!.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 16),
                  Text(
                    'Notes',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      application.notes!,
                      style: theme.textTheme.bodyMedium,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Card(
          color: theme.colorScheme.primaryContainer.withOpacity(0.3),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  color: theme.colorScheme.primary,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'To edit application details (status, dates, company, etc.), use the Edit button on the application card in the main screen.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.8),
                    ),
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

Widget _buildDetailRow({
  required IconData icon,
  required String label,
  required String value,
  required ThemeData theme,
}) {
  return Row(
    children: [
      Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: theme.colorScheme.primaryContainer.withOpacity(0.5),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: 20, color: theme.colorScheme.primary),
      ),
      const SizedBox(width: 12),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              value,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    ],
  );
}
