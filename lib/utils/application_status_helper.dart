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
  /// [useThemeColors] - If true, uses theme-based colors from AppColors.
  /// If false, uses direct Material colors (legacy).
  static Color getColor(
    ApplicationStatus status, {
    bool useThemeColors = true,
  }) {
    if (useThemeColors) {
      return _getThemeColor(status);
    }
    return _getDirectColor(status);
  }

  /// Get theme-based color for status
  static Color _getThemeColor(ApplicationStatus status) {
    switch (status) {
      case ApplicationStatus.draft:
        return AppColors.statusDraft;
      case ApplicationStatus.applied:
        return AppColors.statusApplied;
      case ApplicationStatus.interviewing:
        return AppColors.statusInterviewing;
      case ApplicationStatus.successful:
        return AppColors.statusAccepted;
      case ApplicationStatus.rejected:
        return AppColors.statusRejected;
      case ApplicationStatus.noResponse:
        return AppColors.statusWithdrawn;
    }
  }

  /// Get direct Material color for status (legacy)
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
  static IconData getIcon(
    ApplicationStatus status, {
    String variant = 'default',
  }) {
    switch (status) {
      case ApplicationStatus.draft:
        return Icons.edit_document;
      case ApplicationStatus.applied:
        return Icons.send_rounded;
      case ApplicationStatus.interviewing:
        return variant == 'badge' ? Icons.people_outline : Icons.forum_rounded;
      case ApplicationStatus.successful:
        return Icons.check_circle_rounded;
      case ApplicationStatus.rejected:
        return Icons.cancel_rounded;
      case ApplicationStatus.noResponse:
        return Icons.timer_off_rounded;
    }
  }

  /// Get the display label for a given status
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

  /// Check if a status is a terminal state
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
