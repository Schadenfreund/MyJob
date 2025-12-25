import 'package:flutter/material.dart';
import '../constants/app_constants.dart';
import '../theme/app_theme.dart';

/// A badge widget for displaying application status
class StatusBadge extends StatelessWidget {
  const StatusBadge({
    required this.status,
    super.key,
    this.size = StatusBadgeSize.medium,
  });

  final ApplicationStatus status;
  final StatusBadgeSize size;

  Color get _color {
    switch (status) {
      case ApplicationStatus.draft:
        return AppTheme.statusDraft;
      case ApplicationStatus.applied:
        return AppTheme.statusApplied;
      case ApplicationStatus.interviewing:
        return AppTheme.statusInterviewing;
      case ApplicationStatus.offered:
        return AppTheme.statusOffered;
      case ApplicationStatus.accepted:
        return AppTheme.statusAccepted;
      case ApplicationStatus.rejected:
        return AppTheme.statusRejected;
      case ApplicationStatus.withdrawn:
        return AppTheme.statusWithdrawn;
    }
  }

  IconData get _icon {
    switch (status) {
      case ApplicationStatus.draft:
        return Icons.edit_outlined;
      case ApplicationStatus.applied:
        return Icons.send_outlined;
      case ApplicationStatus.interviewing:
        return Icons.people_outline;
      case ApplicationStatus.offered:
        return Icons.local_offer_outlined;
      case ApplicationStatus.accepted:
        return Icons.check_circle_outline;
      case ApplicationStatus.rejected:
        return Icons.cancel_outlined;
      case ApplicationStatus.withdrawn:
        return Icons.undo_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    final double fontSize;
    final double iconSize;
    final EdgeInsets padding;

    switch (size) {
      case StatusBadgeSize.small:
        fontSize = 11;
        iconSize = 12;
        padding = const EdgeInsets.symmetric(horizontal: 6, vertical: 2);
      case StatusBadgeSize.medium:
        fontSize = 12;
        iconSize = 14;
        padding = const EdgeInsets.symmetric(horizontal: 8, vertical: 4);
      case StatusBadgeSize.large:
        fontSize = 14;
        iconSize = 16;
        padding = const EdgeInsets.symmetric(horizontal: 10, vertical: 6);
    }

    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: _color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: _color.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _icon,
            size: iconSize,
            color: _color,
          ),
          const SizedBox(width: 4),
          Text(
            status.label,
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.w500,
              color: _color,
            ),
          ),
        ],
      ),
    );
  }
}

enum StatusBadgeSize { small, medium, large }
