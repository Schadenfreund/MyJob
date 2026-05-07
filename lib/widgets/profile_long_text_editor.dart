import 'package:flutter/material.dart';
import '../utils/ui_utils.dart';

/// A [TextEditingController] that highlights ==PLACEHOLDER== patterns
/// and optionally highlights filled placeholder values (actual strings).
class PlaceholderHighlightController extends TextEditingController {
  PlaceholderHighlightController({super.text, this.highlightColor});

  Color? highlightColor;

  /// Filled placeholder values to highlight (e.g. company name, position).
  /// Only non-empty strings are matched.
  List<String> filledValues = const [];

  static final _placeholderPattern = RegExp(r'==([A-Za-z0-9_]+)==');

  @override
  TextSpan buildTextSpan({
    required BuildContext context,
    TextStyle? style,
    required bool withComposing,
  }) {
    final color = highlightColor;
    if (color == null || text.isEmpty) {
      return super.buildTextSpan(
          context: context, style: style, withComposing: withComposing);
    }

    // Build a combined pattern: ==PLACEHOLDER== OR filled values
    final nonEmpty =
        filledValues.where((v) => v.trim().isNotEmpty).toList();

    Pattern? combinedPattern;
    if (nonEmpty.isNotEmpty) {
      // Escape special regex chars in filled values, match whole words
      final escaped =
          nonEmpty.map((v) => RegExp.escape(v)).join('|');
      combinedPattern =
          RegExp('(==(?:[A-Za-z0-9_]+)==|$escaped)');
    } else {
      combinedPattern = _placeholderPattern;
    }

    final children = <TextSpan>[];
    var lastEnd = 0;

    for (final match
        in (combinedPattern as RegExp).allMatches(text)) {
      if (match.start > lastEnd) {
        children.add(TextSpan(text: text.substring(lastEnd, match.start)));
      }
      final matched = match.group(0)!;
      final isRawPlaceholder = _placeholderPattern.hasMatch(matched);
      children.add(TextSpan(
        text: matched,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w600,
          backgroundColor: isRawPlaceholder
              ? color.withValues(alpha: 0.1)
              : color.withValues(alpha: 0.08),
        ),
      ));
      lastEnd = match.end;
    }

    if (lastEnd < text.length) {
      children.add(TextSpan(text: text.substring(lastEnd)));
    }

    if (children.isEmpty) {
      return super.buildTextSpan(
          context: context, style: style, withComposing: withComposing);
    }

    return TextSpan(style: style, children: children);
  }
}

/// A chip that can be inserted into the text editor at cursor position.
class InsertableChip {
  final String label;
  final String insertText;
  final String description;

  const InsertableChip({
    required this.label,
    required this.insertText,
    required this.description,
  });
}

/// A standalone chip-row widget used to insert placeholders into a text field.
///
/// Call [onInsert] when a chip is tapped; the parent controls which controller
/// receives the text (body, greeting, closing, etc.).
class InsertableChipRow extends StatelessWidget {
  const InsertableChipRow({
    required this.chips,
    required this.onInsert,
    this.title,
    this.footer,
    super.key,
  });

  final List<InsertableChip> chips;
  final void Function(String) onInsert;
  final String? title;
  final String? footer;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(8),
        border:
            Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null) ...[
            Row(
              children: [
                Icon(Icons.touch_app_outlined,
                    size: 14, color: theme.colorScheme.primary),
                const SizedBox(width: 6),
                Text(
                  title!,
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
          ],
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: chips.map((chip) {
              return Tooltip(
                message: chip.description,
                child: InkWell(
                  onTap: () => onInsert(chip.insertText),
                  borderRadius: BorderRadius.circular(6),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                    decoration: BoxDecoration(
                      color:
                          theme.colorScheme.primary.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                          color: theme.colorScheme.primary
                              .withValues(alpha: 0.2)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.add,
                            size: 12, color: theme.colorScheme.primary),
                        const SizedBox(width: 4),
                        Text(
                          chip.label,
                          style: theme.textTheme.labelSmall?.copyWith(
                            fontFamily: 'monospace',
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          if (footer != null) ...[
            const SizedBox(height: 8),
            Text(
              footer!,
              style: theme.textTheme.bodySmall?.copyWith(
                color:
                    theme.textTheme.bodySmall?.color?.withValues(alpha: 0.5),
                fontSize: 11,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// A specialized editor for long text sections in the profile (Profile Summary, Cover Letter)
///
/// Features:
/// - Maintains its own [TextEditingController] to prevent focus loss during provider updates
/// - Detects changes from the initial value
/// - Shows a "Save Changes" button only when modifications are detected
/// - Consistent premium styling matching the rest of the profile
/// - Optional insertable chips that insert text at cursor position
class ProfileLongTextEditor extends StatefulWidget {
  const ProfileLongTextEditor({
    required this.initialValue,
    required this.onSave,
    required this.hintText,
    this.helpText,
    this.minLines = 4,
    this.maxLines,
    this.insertableChips,
    this.chipsTitle,
    this.chipsFooter,
    this.highlightColor,
    super.key,
  });

  final String initialValue;
  final Function(String) onSave;
  final String hintText;
  final String? helpText;
  final int minLines;
  final int? maxLines;
  final List<InsertableChip>? insertableChips;
  final String? chipsTitle;
  final String? chipsFooter;
  final Color? highlightColor;

  @override
  State<ProfileLongTextEditor> createState() => _ProfileLongTextEditorState();
}

class _ProfileLongTextEditorState extends State<ProfileLongTextEditor> {
  late PlaceholderHighlightController _controller;
  late FocusNode _focusNode;
  bool _isModified = false;

  @override
  void initState() {
    super.initState();
    _controller = PlaceholderHighlightController(
      text: widget.initialValue,
      highlightColor: widget.highlightColor,
    );
    _controller.addListener(_handleTextChanged);
    _focusNode = FocusNode();
  }

  @override
  void didUpdateWidget(ProfileLongTextEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    // If the provider changes the value externally (e.g. on language change or import),
    // and we haven't modified it locally, sync it.
    if (widget.initialValue != oldWidget.initialValue && !_isModified) {
      _controller.text = widget.initialValue;
    }
    if (widget.highlightColor != oldWidget.highlightColor) {
      _controller.highlightColor = widget.highlightColor;
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_handleTextChanged);
    _controller.dispose();
    _focusNode.dispose();
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

  void _insertAtCursor(String text) {
    final selection = _controller.selection;
    final currentText = _controller.text;

    if (selection.isValid && selection.start >= 0) {
      final newText = currentText.replaceRange(
        selection.start,
        selection.end,
        text,
      );
      _controller.value = TextEditingValue(
        text: newText,
        selection: TextSelection.collapsed(
          offset: selection.start + text.length,
        ),
      );
    } else {
      // No cursor position — append at end
      _controller.value = TextEditingValue(
        text: '$currentText$text',
        selection: TextSelection.collapsed(
          offset: currentText.length + text.length,
        ),
      );
    }

    _focusNode.requestFocus();
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
          focusNode: _focusNode,
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

        // Insertable chips
        if (widget.insertableChips != null && widget.insertableChips!.isNotEmpty) ...[
          const SizedBox(height: 12),
          _buildInsertableChips(theme),
        ],

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

  Widget _buildInsertableChips(ThemeData _) {
    return InsertableChipRow(
      chips: widget.insertableChips!,
      onInsert: _insertAtCursor,
      title: widget.chipsTitle,
      footer: widget.chipsFooter,
    );
  }
}
