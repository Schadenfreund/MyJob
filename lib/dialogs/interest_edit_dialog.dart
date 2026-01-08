import 'package:flutter/material.dart';
import '../models/user_data/interest.dart';

/// Simple dialog for adding or editing an interest
///
/// Interests are simpler than other entities - just a name.
class InterestEditDialog extends StatefulWidget {
  const InterestEditDialog({
    this.interest,
    super.key,
  });

  final Interest? interest;

  @override
  State<InterestEditDialog> createState() => _InterestEditDialogState();
}

class _InterestEditDialogState extends State<InterestEditDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.interest != null) {
      _nameController.text = widget.interest!.name;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;

    final interest = Interest(
      id: widget.interest?.id,
      name: _nameController.text.trim(),
    );

    Navigator.pop(context, interest);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Dialog(
      child: Container(
        width: 400,
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Icon(
                    Icons.interests_outlined,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    widget.interest == null ? 'Add Interest' : 'Edit Interest',
                    style: theme.textTheme.titleLarge,
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Name field
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Interest *',
                  hintText: 'e.g. Photography, Hiking, Reading',
                  prefixIcon: Icon(Icons.favorite_outline),
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter an interest';
                  }
                  return null;
                },
                autofocus: true,
                textCapitalization: TextCapitalization.words,
              ),
              const SizedBox(height: 24),

              // Actions
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 12),
                  FilledButton.icon(
                    onPressed: _save,
                    icon: const Icon(Icons.check, size: 18),
                    label: const Text('Save'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
