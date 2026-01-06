import 'package:flutter/material.dart';

/// Editable text field model for PDF template editing
class EditableField {
  EditableField({
    required this.id,
    required this.label,
    required this.value,
    required this.onChanged,
    this.maxLines = 1,
    this.hint,
    this.actionIcon,
    this.actionTooltip,
    this.onAction,
  });

  final String id;
  final String label;
  final String value;
  final ValueChanged<String> onChanged;
  final int maxLines;
  final String? hint;
  final IconData? actionIcon;
  final String? actionTooltip;
  final VoidCallback? onAction;
}

/// Panel for editing PDF template text fields
///
/// This panel provides a sidebar UI for inline editing of template content.
/// It manages text controllers internally for proper state handling.
class TemplateEditPanel extends StatefulWidget {
  const TemplateEditPanel({
    required this.fields,
    required this.onSave,
    required this.onCancel,
    required this.accentColor,
    super.key,
  });

  final List<EditableField> fields;
  final VoidCallback onSave;
  final VoidCallback onCancel;
  final Color accentColor;

  @override
  State<TemplateEditPanel> createState() => _TemplateEditPanelState();
}

class _TemplateEditPanelState extends State<TemplateEditPanel> {
  // Text controllers for each field to maintain proper state
  final Map<String, TextEditingController> _controllers = {};

  @override
  void initState() {
    super.initState();
    _initControllers();
  }

  @override
  void didUpdateWidget(TemplateEditPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Update controllers if fields changed
    _updateControllers();
  }

  @override
  void dispose() {
    // Dispose all controllers to prevent memory leaks
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    _controllers.clear();
    super.dispose();
  }

  void _initControllers() {
    for (final field in widget.fields) {
      _controllers[field.id] = TextEditingController(text: field.value);
    }
  }

  void _updateControllers() {
    final existingIds = _controllers.keys.toSet();
    final newIds = widget.fields.map((f) => f.id).toSet();

    // Remove controllers for fields that no longer exist
    final removedIds = existingIds.difference(newIds);
    for (final id in removedIds) {
      _controllers[id]?.dispose();
      _controllers.remove(id);
    }

    // Add controllers for new fields
    for (final field in widget.fields) {
      if (!_controllers.containsKey(field.id)) {
        _controllers[field.id] = TextEditingController(text: field.value);
      } else {
        // Update existing controller only if the value changed externally
        final controller = _controllers[field.id]!;
        if (controller.text != field.value) {
          controller.text = field.value;
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF2D2D2D),
        border: Border(
          left: BorderSide(
            color: Colors.white.withValues(alpha: 0.1),
            width: 1,
          ),
        ),
      ),
      child: Column(
        children: [
          // Header
          _buildHeader(),

          // Editable fields
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: widget.fields.length,
              itemBuilder: (context, index) {
                final field = widget.fields[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: _buildTextField(field),
                );
              },
            ),
          ),

          // Action buttons
          _buildActionButtons(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: widget.accentColor.withValues(alpha: 0.3),
            width: 2,
          ),
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.edit, color: widget.accentColor, size: 20),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'EDIT TEMPLATE',
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              ),
            ),
          ),
          IconButton(
            onPressed: widget.onCancel,
            icon: const Icon(Icons.close, color: Colors.white),
            tooltip: 'Cancel',
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: Colors.white.withValues(alpha: 0.1),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: widget.onCancel,
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                side: BorderSide(
                  color: Colors.white.withValues(alpha: 0.3),
                ),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: const Text('Cancel'),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton(
              onPressed: widget.onSave,
              style: ElevatedButton.styleFrom(
                backgroundColor: widget.accentColor,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: const Text('Save Changes'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(EditableField field) {
    final controller = _controllers[field.id];
    if (controller == null) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                field.label,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.8),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
            ),
            if (field.onAction != null && field.actionIcon != null)
              IconButton(
                onPressed: field.onAction,
                icon: Icon(field.actionIcon, size: 18),
                tooltip: field.actionTooltip ?? '',
                color: Colors.white.withValues(alpha: 0.6),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
          ],
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          onChanged: field.onChanged,
          maxLines: field.maxLines,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
          ),
          decoration: InputDecoration(
            hintText: field.hint,
            hintStyle: TextStyle(
              color: Colors.white.withValues(alpha: 0.3),
              fontSize: 14,
            ),
            filled: true,
            fillColor: Colors.white.withValues(alpha: 0.05),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: Colors.white.withValues(alpha: 0.1),
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: Colors.white.withValues(alpha: 0.1),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: widget.accentColor,
                width: 2,
              ),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 12,
            ),
          ),
        ),
      ],
    );
  }
}
