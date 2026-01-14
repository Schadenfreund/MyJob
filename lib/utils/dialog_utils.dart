import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Centralized dialog utilities for consistent dialog behavior across the app
class DialogUtils {
  DialogUtils._();

  // ============================================================================
  // CONFIRMATION DIALOGS
  // ============================================================================

  /// Show a delete confirmation dialog
  /// Returns true if user confirmed deletion, false otherwise
  static Future<bool> showDeleteConfirmation(
    BuildContext context, {
    required String title,
    required String message,
    String confirmLabel = 'Delete',
    String cancelLabel = 'Cancel',
    IconData icon = Icons.delete_outline,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        icon: Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: AppColors.lightDanger.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            color: AppColors.lightDanger,
            size: 28,
          ),
        ),
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(cancelLabel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.lightDanger,
              foregroundColor: Colors.white,
            ),
            child: Text(confirmLabel),
          ),
        ],
      ),
    );

    return result ?? false;
  }

  /// Show a generic confirmation dialog
  /// Returns true if user confirmed, false otherwise
  static Future<bool> showConfirmation(
    BuildContext context, {
    required String title,
    required String message,
    String confirmLabel = 'Confirm',
    String cancelLabel = 'Cancel',
    IconData? icon,
    Color? iconColor,
  }) async {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        icon: icon != null
            ? Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: (iconColor ?? primaryColor).withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  color: iconColor ?? primaryColor,
                  size: 28,
                ),
              )
            : null,
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(cancelLabel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(confirmLabel),
          ),
        ],
      ),
    );

    return result ?? false;
  }

  // ============================================================================
  // INFORMATION DIALOGS
  // ============================================================================

  /// Show an information dialog with a single OK button
  static Future<void> showInfo(
    BuildContext context, {
    required String title,
    required String message,
    String buttonLabel = 'OK',
    IconData icon = Icons.info_outline,
  }) async {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;

    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        icon: Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: primaryColor.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            color: primaryColor,
            size: 28,
          ),
        ),
        title: Text(title),
        content: Text(message),
        actions: [
          FilledButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(buttonLabel),
          ),
        ],
      ),
    );
  }

  /// Show an error dialog
  static Future<void> showError(
    BuildContext context, {
    required String title,
    required String message,
    String buttonLabel = 'OK',
  }) async {
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        icon: Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: AppColors.lightDanger.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.error_outline,
            color: AppColors.lightDanger,
            size: 28,
          ),
        ),
        title: Text(title),
        content: Text(message),
        actions: [
          FilledButton(
            onPressed: () => Navigator.of(context).pop(),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.lightDanger,
              foregroundColor: Colors.white,
            ),
            child: Text(buttonLabel),
          ),
        ],
      ),
    );
  }

  /// Show a success dialog
  static Future<void> showSuccess(
    BuildContext context, {
    required String title,
    required String message,
    String buttonLabel = 'OK',
  }) async {
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        icon: Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: AppColors.lightSuccess.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.check_circle_outline,
            color: AppColors.lightSuccess,
            size: 28,
          ),
        ),
        title: Text(title),
        content: Text(message),
        actions: [
          FilledButton(
            onPressed: () => Navigator.of(context).pop(),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.lightSuccess,
              foregroundColor: Colors.white,
            ),
            child: Text(buttonLabel),
          ),
        ],
      ),
    );
  }

  // ============================================================================
  // INPUT DIALOGS
  // ============================================================================

  /// Show a text input dialog
  /// Returns the entered text, or null if cancelled
  static Future<String?> showTextInput(
    BuildContext context, {
    required String title,
    String? message,
    String? initialValue,
    String? hintText,
    String confirmLabel = 'OK',
    String cancelLabel = 'Cancel',
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) async {
    final controller = TextEditingController(text: initialValue);
    final formKey = GlobalKey<FormState>();

    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (message != null) ...[
                Text(message),
                const SizedBox(height: AppSpacing.md),
              ],
              TextFormField(
                controller: controller,
                autofocus: true,
                maxLines: maxLines,
                keyboardType: keyboardType,
                decoration: InputDecoration(
                  hintText: hintText,
                ),
                validator: validator,
                onFieldSubmitted: (_) {
                  if (formKey.currentState?.validate() ?? false) {
                    Navigator.of(context).pop(controller.text);
                  }
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(null),
            child: Text(cancelLabel),
          ),
          FilledButton(
            onPressed: () {
              if (formKey.currentState?.validate() ?? false) {
                Navigator.of(context).pop(controller.text);
              }
            },
            child: Text(confirmLabel),
          ),
        ],
      ),
    );

    controller.dispose();
    return result;
  }

  // ============================================================================
  // LOADING DIALOGS
  // ============================================================================

  /// Show a loading dialog that blocks user interaction
  /// Returns a function to close the dialog
  static VoidCallback showLoading(
    BuildContext context, {
    String? message,
  }) {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => PopScope(
        canPop: false,
        child: AlertDialog(
          content: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              if (message != null) ...[
                const SizedBox(width: AppSpacing.lg),
                Flexible(child: Text(message)),
              ],
            ],
          ),
        ),
      ),
    );

    return () {
      if (context.mounted) {
        Navigator.of(context).pop();
      }
    };
  }
}

// ============================================================================
// SNACKBAR UTILITIES (DEPRECATED - Use UIUtils)
// ============================================================================

/// Extension on BuildContext for easy SnackBar display
extension SnackBarExtension on BuildContext {
  /// Show a success snackbar
  void showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(this).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: AppColors.lightSuccess,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(AppDimensions.inputBorderRadius)),
        margin: const EdgeInsets.all(AppSpacing.md),
      ),
    );
  }

  /// Show an error snackbar
  void showErrorSnackBar(String message) {
    ScaffoldMessenger.of(this).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: AppColors.lightDanger,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(AppDimensions.inputBorderRadius)),
        margin: const EdgeInsets.all(AppSpacing.md),
      ),
    );
  }

  /// Show an info snackbar
  void showInfoSnackBar(String message) {
    final theme = Theme.of(this);
    ScaffoldMessenger.of(this).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.info_outline, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: theme.colorScheme.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(AppDimensions.inputBorderRadius)),
        margin: const EdgeInsets.all(AppSpacing.md),
      ),
    );
  }

  /// Show a warning snackbar
  void showWarningSnackBar(String message) {
    ScaffoldMessenger.of(this).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.warning_amber, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(message, style: const TextStyle(color: Colors.white)),
            ),
          ],
        ),
        backgroundColor: AppColors.lightWarning,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(AppDimensions.inputBorderRadius)),
        margin: const EdgeInsets.all(AppSpacing.md),
      ),
    );
  }
}
