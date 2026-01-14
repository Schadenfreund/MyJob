import 'package:flutter/material.dart';
import '../utils/ui_utils.dart';

/// A specialized editor for long text sections in the profile (Profile Summary, Cover Letter)
///
/// Features:
/// - Maintains its own [TextEditingController] to prevent focus loss during provider updates
/// - Detects changes from the initial value
/// - Shows a "Save Changes" button only when modifications are detected
/// - Consistent premium styling matching the rest of the profile
class ProfileLongTextEditor extends StatefulWidget {
  const ProfileLongTextEditor({
    required this.initialValue,
    required this.onSave,
    required this.hintText,
    this.helpText,
    this.minLines = 4,
    this.maxLines,
    super.key,
  });

  final String initialValue;
  final Function(String) onSave;
  final String hintText;
  final String? helpText;
  final int minLines;
  final int? maxLines;

  @override
  State<ProfileLongTextEditor> createState() => _ProfileLongTextEditorState();
}

class _ProfileLongTextEditorState extends State<ProfileLongTextEditor> {
  late TextEditingController _controller;
  bool _isModified = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
    _controller.addListener(_handleTextChanged);
  }

  @override
  void didUpdateWidget(ProfileLongTextEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    // If the provider changes the value externally (e.g. on language change or import),
    // and we haven't modified it locally, sync it.
    if (widget.initialValue != oldWidget.initialValue && !_isModified) {
      _controller.text = widget.initialValue;
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_handleTextChanged);
    _controller.dispose();
    super.dispose();
  }

  void _handleTextChanged() {
    final modified = _controller.text != widget.initialValue;
    if (modified != _isModified) {
      setState(() {
        _isModified = modified;
      });
    }
  }

  void _handleSave() {
    widget.onSave(_controller.text);
    setState(() {
      _isModified = false;
    });
  }

  void _handleReset() {
    _controller.text = widget.initialValue;
    setState(() {
      _isModified = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.helpText != null) ...[
          Text(
            widget.helpText!,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.textTheme.bodySmall?.color?.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 16),
        ],
        TextField(
          controller: _controller,
          minLines: widget.minLines,
          maxLines: widget.maxLines,
          style: theme.textTheme.bodyMedium,
          decoration: InputDecoration(
            hintText: widget.hintText,
            hintStyle: theme.textTheme.bodyMedium?.copyWith(
              color: theme.textTheme.bodySmall?.color?.withOpacity(0.4),
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: theme.colorScheme.outline.withValues(alpha: 0.2),
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: theme.colorScheme.outline.withValues(alpha: 0.2),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: theme.colorScheme.primary,
                width: 2,
              ),
            ),
            filled: true,
            fillColor: theme.colorScheme.surfaceContainerHighest
                .withValues(alpha: 0.2),
            contentPadding: const EdgeInsets.all(16),
          ),
        ),

        // Animated Save Bar
        AnimatedSize(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          child: SizedBox(
            height: _isModified ? null : 0,
            child: Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Row(
                children: [
                  const Spacer(),
                  TextButton(
                    onPressed: _handleReset,
                    child: const Text('Discard'),
                  ),
                  const SizedBox(width: 12),
                  UIUtils.buildPrimaryButton(
                    label: 'Save Changes',
                    onPressed: _handleSave,
                    icon: Icons.save_outlined,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
