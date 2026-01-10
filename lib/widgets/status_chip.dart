import 'package:flutter/material.dart';
import '../constants/app_constants.dart';

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
    final color = _getStatusColor(status);

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
            _getStatusIcon(status),
            size: compact ? 12 : 14,
            color: color,
          ),
          SizedBox(width: compact ? 4 : 6),
          Text(
            _getStatusLabel(status),
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

  Color _getStatusColor(ApplicationStatus status) {
    switch (status) {
      case ApplicationStatus.draft:
        return Colors.blue;
      case ApplicationStatus.applied:
        return Colors.lightBlue;
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

  IconData _getStatusIcon(ApplicationStatus status) {
    switch (status) {
      case ApplicationStatus.draft:
        return Icons.edit_outlined;
      case ApplicationStatus.applied:
        return Icons.send_outlined;
      case ApplicationStatus.interviewing:
        return Icons.chat_outlined;
      case ApplicationStatus.successful:
        return Icons.check_circle_outline;
      case ApplicationStatus.rejected:
        return Icons.cancel_outlined;
      case ApplicationStatus.noResponse:
        return Icons.schedule;
    }
  }

  String _getStatusLabel(ApplicationStatus status) {
    switch (status) {
      case ApplicationStatus.draft:
        return 'Draft';
      case ApplicationStatus.applied:
        return 'Applied';
      case ApplicationStatus.interviewing:
        return 'Interview';
      case ApplicationStatus.successful:
        return 'Successful';
      case ApplicationStatus.rejected:
        return 'Rejected';
      case ApplicationStatus.noResponse:
        return 'No Response';
    }
  }
}
