import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/user_data_provider.dart';
import '../../../models/user_data/interest.dart';
import '../../../widgets/app_card.dart';
import '../../../utils/ui_utils.dart';

/// Interests management section
class InterestsSection extends StatelessWidget {
  const InterestsSection({
    this.showHeader = true,
    super.key,
  });

  final bool showHeader;

  @override
  Widget build(BuildContext context) {
    final userDataProvider = context.watch<UserDataProvider>();
    final interests = userDataProvider.interests;

    final content = interests.isEmpty
        ? _buildEmptyState(context, userDataProvider)
        : _buildInterestsList(context, userDataProvider, interests);

    if (!showHeader) {
      return content;
    }

    return AppCard(
      title: 'Interests',
      icon: Icons.interests_outlined,
      description: 'Add your hobbies and personal interests',
      trailing: AppCardActionButton(
        label: 'Add Interest',
        icon: Icons.add,
        onPressed: () => _addInterest(context, userDataProvider),
      ),
      children: [
        content,
      ],
    );
  }

  Widget _buildEmptyState(BuildContext context, UserDataProvider provider) {
    return UIUtils.buildEmptyState(
      context,
      icon: Icons.interests_outlined,
      title: 'No Interests Added',
      message: 'Add your hobbies and interests to personalize your profile.',
      action: FilledButton.icon(
        onPressed: () => _addInterest(context, provider),
        icon: const Icon(Icons.add, size: 18),
        label: const Text('Add Your First Interest'),
      ),
    );
  }

  Widget _buildInterestsList(BuildContext context, UserDataProvider provider,
      List<Interest> interests) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: interests
          .map((interest) => _buildInterestChip(context, provider, interest))
          .toList(),
    );
  }

  Widget _buildInterestChip(
      BuildContext context, UserDataProvider provider, Interest interest) {
    final theme = Theme.of(context);
    final color = theme.colorScheme.primary;

    return Container(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: color.withValues(alpha: 0.4),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _editInterest(context, provider, interest),
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  interest.name,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  Icons.edit,
                  size: 14,
                  color: color.withValues(alpha: 0.6),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static void showAddDialog(BuildContext context) {
    _addInterest(context, context.read<UserDataProvider>());
  }

  static Future<void> _addInterest(
      BuildContext context, UserDataProvider provider) async {
    final nameController = TextEditingController();

    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Interest'),
        content: TextField(
          controller: nameController,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Interest Name',
            hintText: 'e.g., Photography, Hiking',
          ),
          onSubmitted: (val) => Navigator.pop(context, val),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, nameController.text),
            child: const Text('Add'),
          ),
        ],
      ),
    );

    if (result != null && result.trim().isNotEmpty) {
      await provider.addInterest(Interest(name: result.trim()));
    }
  }

  Future<void> _editInterest(BuildContext context, UserDataProvider provider,
      Interest interest) async {
    final nameController = TextEditingController(text: interest.name);

    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Interest'),
        content: TextField(
          controller: nameController,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Interest Name',
          ),
          onSubmitted: (val) => Navigator.pop(context, val),
        ),
        actions: [
          TextButton.icon(
            onPressed: () async {
              await provider.deleteInterest(interest.id);
              if (context.mounted) Navigator.pop(context);
            },
            icon: const Icon(Icons.delete, color: Colors.red),
            label: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
          const Spacer(),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, nameController.text),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (result != null && result.trim().isNotEmpty) {
      await provider.updateInterest(interest.copyWith(name: result.trim()));
    }
  }
}
