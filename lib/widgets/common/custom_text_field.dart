import 'package:flutter/material.dart';

/// Custom text field with consistent styling
class CustomTextField extends StatefulWidget {
  const CustomTextField({
    super.key,
    this.label,
    this.hint,
    this.initialValue = '',
    this.keyboardType = TextInputType.text,
    this.obscureText = false,
    this.prefixIcon,
    this.suffixIcon,
    this.onChanged,
    this.onSubmitted,
    this.errorText,
    this.validator,
    this.maxLines = 1,
    this.minLines = 1,
    this.maxLength,
    this.enabled = true,
    this.required = false,
    this.textInputAction = TextInputAction.next,
    this.controller,
  });

  final String? label;
  final String? hint;
  final String initialValue;
  final TextInputType keyboardType;
  final bool obscureText;
  final IconData? prefixIcon;
  final IconData? suffixIcon;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final String? errorText;
  final String? Function(String?)? validator;
  final int? maxLines;
  final int minLines;
  final int? maxLength;
  final bool enabled;
  final bool required;
  final TextInputAction textInputAction;
  final TextEditingController? controller;

  @override
  State<CustomTextField> createState() => _CustomTextFieldState();
}

class _CustomTextFieldState extends State<CustomTextField> {
  late TextEditingController _controller;
  late bool _obscureText;
  bool _ownsController = false;
  String? _validationError;

  @override
  void initState() {
    super.initState();
    if (widget.controller != null) {
      _controller = widget.controller!;
    } else {
      _controller = TextEditingController(text: widget.initialValue);
      _ownsController = true;
    }
    _obscureText = widget.obscureText;
  }

  @override
  void dispose() {
    if (_ownsController) {
      _controller.dispose();
    }
    super.dispose();
  }

  /// Validate email format (basic validation)
  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return widget.required ? 'Email is required' : null;
    }

    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value)) {
      return 'Please enter a valid email';
    }

    return null;
  }

  /// Validate phone format (basic validation - allows international formats)
  String? _validatePhone(String? value) {
    if (value == null || value.isEmpty) {
      return widget.required ? 'Phone is required' : null;
    }

    // Allow international formats: +, digits, spaces, dashes, parentheses
    final phoneRegex = RegExp(r'^\+?[\d\s\-\(\)]{10,}$');
    if (!phoneRegex.hasMatch(value)) {
      return 'Please enter a valid phone number';
    }

    return null;
  }

  /// Get the appropriate validator based on keyboard type
  String? Function(String?)? _getValidator() {
    if (widget.validator != null) {
      return widget.validator;
    }

    // Auto-validate based on keyboard type
    if (widget.keyboardType == TextInputType.emailAddress) {
      return _validateEmail;
    } else if (widget.keyboardType == TextInputType.phone) {
      return _validatePhone;
    }

    return null;
  }

  void _handleChanged(String value) {
    // Run validation
    final validator = _getValidator();
    if (validator != null) {
      setState(() {
        _validationError = validator(value);
      });
    }

    widget.onChanged?.call(value);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.label != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 12), // Increased from 8 to 12
            child: Row(
              children: [
                Text(
                  widget.label!,
                  style: theme.textTheme.labelLarge,
                ),
                if (widget.required)
                  Text(
                    ' *',
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: theme.colorScheme.error,
                    ),
                  ),
              ],
            ),
          ),
        TextField(
          controller: _controller,
          enabled: widget.enabled,
          keyboardType: widget.keyboardType,
          obscureText: _obscureText,
          maxLines: _obscureText ? 1 : widget.maxLines,
          minLines: widget.minLines,
          maxLength: widget.maxLength,
          textInputAction: widget.textInputAction,
          onChanged: _handleChanged,
          onSubmitted: widget.onSubmitted,
          decoration: InputDecoration(
            hintText: widget.hint,
            errorText: widget.errorText ?? _validationError,
            prefixIcon:
                widget.prefixIcon != null ? Icon(widget.prefixIcon) : null,
            suffixIcon: widget.obscureText
                ? IconButton(
                    icon: Icon(
                      _obscureText ? Icons.visibility_off : Icons.visibility,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscureText = !_obscureText;
                      });
                    },
                  )
                : (widget.suffixIcon != null ? Icon(widget.suffixIcon) : null),
          ),
        ),
      ],
    );
  }
}
