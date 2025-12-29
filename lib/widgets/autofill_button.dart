import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/user_data_provider.dart';
import '../services/profile_autofill_service.dart';
import '../utils/ui_utils.dart';

/// Button widget that triggers auto-fill from user profile
class AutofillButton extends StatelessWidget {
  const AutofillButton({
    required this.onAutofill,
    this.fieldsToFill = const [],
    this.title = 'Use Profile Data',
    this.icon = Icons.auto_fix_high,
    this.variant = AutofillButtonVariant.elevated,
    this.showIfEmpty = true,
    super.key,
  });

  final VoidCallback onAutofill;
  final List<String> fieldsToFill;
  final String title;
  final IconData icon;
  final AutofillButtonVariant variant;
  final bool showIfEmpty;

  @override
  Widget build(BuildContext context) {
    final userDataProvider = context.watch<UserDataProvider>();
    final autofillService = ProfileAutofillService(userDataProvider);
    final isConfigured = autofillService.isProfileConfigured();

    if (!isConfigured && showIfEmpty) {
      return _buildNotConfiguredButton(context);
    }

    switch (variant) {
      case AutofillButtonVariant.elevated:
        return FilledButton.icon(
          onPressed: () => _handleAutofill(context, autofillService),
          icon: Icon(icon, size: 18),
          label: Text(title),
        );

      case AutofillButtonVariant.outlined:
        return OutlinedButton.icon(
          onPressed: () => _handleAutofill(context, autofillService),
          icon: Icon(icon, size: 18),
          label: Text(title),
        );

      case AutofillButtonVariant.text:
        return TextButton.icon(
          onPressed: () => _handleAutofill(context, autofillService),
          icon: Icon(icon, size: 18),
          label: Text(title),
        );

      case AutofillButtonVariant.compact:
        return IconButton.filled(
          onPressed: () => _handleAutofill(context, autofillService),
          icon: Icon(icon),
          tooltip: title,
        );
    }
  }

  Widget _buildNotConfiguredButton(BuildContext context) {
    final theme = Theme.of(context);

    return Tooltip(
      message: 'Configure your profile in Settings first',
      child: OutlinedButton.icon(
        onPressed: () => _showNotConfiguredDialog(context),
        icon: Icon(
          Icons.warning_amber_rounded,
          size: 18,
          color: theme.colorScheme.error,
        ),
        label: Text(
          'Profile Not Set',
          style: TextStyle(color: theme.colorScheme.error),
        ),
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: theme.colorScheme.error),
        ),
      ),
    );
  }

  void _showNotConfiguredDialog(BuildContext context) {
    final theme = Theme.of(context);
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        icon: Icon(
          Icons.warning_amber_rounded,
          color: theme.colorScheme.error,
          size: 48,
        ),
        title: const Text('Profile Not Configured'),
        content: const Text(
          'You haven\'t set up your user profile yet.\n\n'
          'Go to Settings → User Profile to add your basic information, '
          'skills, and interests. This will allow you to quickly fill in '
          'your CV and cover letter templates.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> _handleAutofill(
    BuildContext context,
    ProfileAutofillService autofillService,
  ) async {
    // Show confirmation dialog
    final confirmed = await autofillService.showAutofillDialog(
      context,
      title: title,
      fieldsToFill: fieldsToFill.isEmpty
          ? ['Contact information', 'Skills', 'Interests', 'Languages']
          : fieldsToFill,
    );

    if (confirmed && context.mounted) {
      // Execute the auto-fill callback
      onAutofill();

      // Show success message
      autofillService.showSuccessSnackbar(context);
    }
  }
}

/// Variants for the autofill button
enum AutofillButtonVariant {
  /// Filled button with elevation (default)
  elevated,

  /// Outlined button
  outlined,

  /// Text button
  text,

  /// Compact icon button
  compact,
}

/// Autofill section - combines button with status indicator
class AutofillSection extends StatelessWidget {
  const AutofillSection({
    required this.onAutofill,
    this.fieldsToFill = const [],
    this.title = 'Auto-fill from Profile',
    this.description,
    super.key,
  });

  final VoidCallback onAutofill;
  final List<String> fieldsToFill;
  final String title;
  final String? description;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final userDataProvider = context.watch<UserDataProvider>();
    final autofillService = ProfileAutofillService(userDataProvider);
    final availability = autofillService.getProfileDataAvailability();

    return Container(
      decoration: UIUtils.getInfoCard(context),
      padding: const EdgeInsets.all(UIUtils.cardPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Icon(
                Icons.auto_fix_high,
                color: theme.colorScheme.primary,
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (description != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        description!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.textTheme.bodySmall?.color
                              ?.withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),

          SizedBox(height: UIUtils.cardInternalGap),

          // Available data indicators
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (availability['name'] == true)
                _buildAvailabilityChip(context, 'Name', true),
              if (availability['email'] == true)
                _buildAvailabilityChip(context, 'Email', true),
              if (availability['phone'] == true)
                _buildAvailabilityChip(context, 'Phone', true),
              if (availability['skills'] == true)
                _buildAvailabilityChip(context, 'Skills', true),
              if (availability['interests'] == true)
                _buildAvailabilityChip(context, 'Interests', true),
              if (availability['languages'] == true)
                _buildAvailabilityChip(context, 'Languages', true),
            ],
          ),

          SizedBox(height: UIUtils.cardInternalGap),

          // Auto-fill button
          SizedBox(
            width: double.infinity,
            child: AutofillButton(
              onAutofill: onAutofill,
              fieldsToFill: fieldsToFill,
              variant: AutofillButtonVariant.elevated,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvailabilityChip(
      BuildContext context, String label, bool available) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Chip(
      avatar: Icon(
        available ? Icons.check_circle : Icons.cancel,
        size: 16,
        color: available ? colorScheme.tertiary : colorScheme.outline,
      ),
      label: Text(
        label,
        style: theme.textTheme.bodySmall,
      ),
      backgroundColor: available
          ? colorScheme.tertiary.withValues(alpha: 0.1)
          : colorScheme.outline.withValues(alpha: 0.1),
      side: BorderSide.none,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }
}
