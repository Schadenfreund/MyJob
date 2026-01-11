import 'package:flutter/material.dart';
import '../constants/app_constants.dart';
import '../utils/application_status_helper.dart';

/// A badge widget for displaying application status
class StatusBadge extends StatelessWidget {
  const StatusBadge({
    required this.status,
    super.key,
    this.size = StatusBadgeSize.medium,
  });

  final ApplicationStatus status;
  final StatusBadgeSize size;

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

    final color = ApplicationStatusHelper.getColor(status, useThemeColors: true);
    final icon = ApplicationStatusHelper.getIcon(status, variant: 'badge');

    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: iconSize,
            color: color,
          ),
          const SizedBox(width: 4),
          Text(
            status.label,
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.w500,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

enum StatusBadgeSize { small, medium, large }
