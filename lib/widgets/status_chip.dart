import 'package:flutter/material.dart';
import '../constants/app_constants.dart';
import '../utils/application_status_helper.dart';

/// Reusable status chip widget with consistent styling
/// Matches the chip design from Profile tab (skills, languages, interests)
class StatusChip extends StatelessWidget {
  final ApplicationStatus status;
  final bool compact;

  const StatusChip({
    required this.status,
    this.compact = false,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final color = ApplicationStatusHelper.getColor(status);

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 10,
        vertical: compact ? 4 : 6,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: color.withOpacity(0.4),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            ApplicationStatusHelper.getIcon(status),
            size: compact ? 12 : 14,
            color: color,
          ),
          SizedBox(width: compact ? 4 : 6),
          Text(
            ApplicationStatusHelper.getLabel(status, short: true),
            style: TextStyle(
              fontSize: compact ? 11 : 12,
              fontWeight: FontWeight.w500,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
