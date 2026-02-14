import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../localization/app_localizations.dart';
import '../../../models/user_data/interest.dart';
import '../../../providers/user_data_provider.dart';
import '../../../utils/ui_utils.dart';
import '../../../widgets/app_card.dart';

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
      title: context.tr('interests'),
      icon: Icons.interests_outlined,
      description: context.tr('interests_desc'),
      trailing: AppCardActionButton(
        label: context.tr('add'),
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
      title: context.tr('no_interests_added'),
      message: context.tr('interests_empty_message'),
      action: FilledButton.icon(
        onPressed: () => _addInterest(context, provider),
        icon: const Icon(Icons.add, size: 18),
        label: Text(context.tr('add_first_interest')),
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
        title: Text(context.tr('add_interest')),
        content: TextField(
          controller: nameController,
          autofocus: true,
          decoration: InputDecoration(
            labelText: context.tr('interest_name'),
            hintText: context.tr('interest_hint'),
          ),
          onSubmitted: (val) => Navigator.pop(context, val),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(context.tr('cancel')),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, nameController.text),
            child: Text(context.tr('add')),
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
        title: Text(context.tr('edit_interest')),
        content: TextField(
          controller: nameController,
          autofocus: true,
          decoration: InputDecoration(
            labelText: context.tr('interest_name'),
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
            label: Text(context.tr('delete'), style: const TextStyle(color: Colors.red)),
          ),
          const Spacer(),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(context.tr('cancel')),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, nameController.text),
            child: Text(context.tr('save')),
          ),
        ],
      ),
    );

    if (result != null && result.trim().isNotEmpty) {
      await provider.updateInterest(interest.copyWith(name: result.trim()));
    }
  }
}
