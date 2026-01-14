import 'package:flutter/material.dart';
import '../constants/app_constants.dart';
import '../theme/app_theme.dart';

/// Centralized helper for application status display properties
///
/// Provides consistent colors, icons, and labels for ApplicationStatus values
/// across the entire application.
class ApplicationStatusHelper {
  ApplicationStatusHelper._();

  /// Get the color for a given status
  ///
  /// [useThemeColors] - If true, uses theme-based colors from AppTheme.
  /// If false, uses direct Material colors.
  static Color getColor(
    ApplicationStatus status, {
    bool useThemeColors = false,
  }) {
    if (useThemeColors) {
      return _getThemeColor(status);
    }
    return _getDirectColor(status);
  }

  /// Get theme-based color for status (used by StatusBadge)
  static Color _getThemeColor(ApplicationStatus status) {
    switch (status) {
      case ApplicationStatus.draft:
        return AppTheme.statusDraft;
      case ApplicationStatus.applied:
        return AppTheme.statusApplied;
      case ApplicationStatus.interviewing:
        return AppTheme.statusInterviewing;
      case ApplicationStatus.successful:
        return AppTheme.statusAccepted;
      case ApplicationStatus.rejected:
        return AppTheme.statusRejected;
      case ApplicationStatus.noResponse:
        return AppTheme.statusWithdrawn;
    }
  }

  /// Get direct Material color for status (used by StatusChip and CompactApplicationCard)
  static Color _getDirectColor(ApplicationStatus status) {
    switch (status) {
      case ApplicationStatus.draft:
        return Colors.grey;
      case ApplicationStatus.applied:
        return Colors.orange;
      case ApplicationStatus.interviewing:
        return Colors.orange;
      case ApplicationStatus.successful:
        return Colors.green;
      case ApplicationStatus.rejected:
        return Colors.red.withOpacity(0.7);
      case ApplicationStatus.noResponse:
        return Colors.grey;
    }
  }

  /// Get the icon for a given status
  ///
  /// [variant] - Icon style variant:
  ///   - 'default': Standard icons (chat_outlined for interviewing)
  ///   - 'badge': Badge variant (people_outline for interviewing)
  static IconData getIcon(
    ApplicationStatus status, {
    String variant = 'default',
  }) {
    switch (status) {
      case ApplicationStatus.draft:
        return Icons.edit_outlined;
      case ApplicationStatus.applied:
        return Icons.send_outlined;
      case ApplicationStatus.interviewing:
        return variant == 'badge' ? Icons.people_outline : Icons.chat_outlined;
      case ApplicationStatus.successful:
        return Icons.check_circle_outline;
      case ApplicationStatus.rejected:
        return Icons.cancel_outlined;
      case ApplicationStatus.noResponse:
        return Icons.schedule;
    }
  }

  /// Get the display label for a given status
  ///
  /// [short] - If true, returns shorter label for compact displays
  static String getLabel(
    ApplicationStatus status, {
    bool short = false,
  }) {
    switch (status) {
      case ApplicationStatus.draft:
        return 'Draft';
      case ApplicationStatus.applied:
        return 'Applied';
      case ApplicationStatus.interviewing:
        return short ? 'Interview' : 'Interviewing';
      case ApplicationStatus.successful:
        return 'Successful';
      case ApplicationStatus.rejected:
        return 'Rejected';
      case ApplicationStatus.noResponse:
        return 'No Response';
    }
  }

  /// Get all available application statuses
  static List<ApplicationStatus> getAllStatuses() {
    return ApplicationStatus.values;
  }

  /// Check if a status is a terminal state (successful or rejected)
  static bool isTerminal(ApplicationStatus status) {
    return status == ApplicationStatus.successful ||
        status == ApplicationStatus.rejected ||
        status == ApplicationStatus.noResponse;
  }

  /// Check if a status represents an active application
  static bool isActive(ApplicationStatus status) {
    return status == ApplicationStatus.applied ||
        status == ApplicationStatus.interviewing;
  }
}
