import 'package:intl/intl.dart';

/// Centralized date formatting utilities for consistent date display across the app
class AppDateUtils {
  AppDateUtils._();

  // ============================================================================
  // DATE FORMATTERS
  // ============================================================================

  static final DateFormat _fullDateFormat = DateFormat('MMM d, yyyy');
  static final DateFormat _shortDateFormat = DateFormat('MMM yyyy');
  static final DateFormat _monthYearFormat = DateFormat('MMMM yyyy');
  static final DateFormat _dayMonthFormat = DateFormat('d MMM');
  static final DateFormat _isoFormat = DateFormat('yyyy-MM-dd');

  // ============================================================================
  // FORMATTING METHODS
  // ============================================================================

  /// Format date as "Jan 15, 2024"
  static String formatFull(DateTime? date) {
    if (date == null) return '';
    return _fullDateFormat.format(date);
  }

  /// Format date as "Jan 2024"
  static String formatShort(DateTime? date) {
    if (date == null) return '';
    return _shortDateFormat.format(date);
  }

  /// Format date as "January 2024"
  static String formatMonthYear(DateTime? date) {
    if (date == null) return '';
    return _monthYearFormat.format(date);
  }

  /// Format date as "15 Jan"
  static String formatDayMonth(DateTime? date) {
    if (date == null) return '';
    return _dayMonthFormat.format(date);
  }

  /// Format date as "2024-01-15" (ISO format for storage)
  static String formatIso(DateTime? date) {
    if (date == null) return '';
    return _isoFormat.format(date);
  }

  /// Format date range as "Jan 2020 - Mar 2024" or "Jan 2020 - Present"
  static String formatDateRange(
    DateTime? startDate,
    DateTime? endDate, {
    bool isCurrent = false,
    String currentLabel = 'Present',
  }) {
    if (startDate == null) return '';

    final start = formatShort(startDate);
    if (isCurrent || endDate == null) {
      return '$start - $currentLabel';
    }
    return '$start - ${formatShort(endDate)}';
  }

  /// Calculate duration between two dates and format as "2 years, 3 months"
  static String formatDuration(
    DateTime? startDate,
    DateTime? endDate, {
    bool isCurrent = false,
  }) {
    if (startDate == null) return '';

    final end = (isCurrent || endDate == null) ? DateTime.now() : endDate;
    final months = _monthsBetween(startDate, end);

    if (months < 1) {
      return 'Less than a month';
    } else if (months < 12) {
      return months == 1 ? '1 month' : '$months months';
    } else {
      final years = months ~/ 12;
      final remainingMonths = months % 12;
      final yearStr = years == 1 ? '1 year' : '$years years';
      if (remainingMonths == 0) {
        return yearStr;
      }
      final monthStr =
          remainingMonths == 1 ? '1 month' : '$remainingMonths months';
      return '$yearStr, $monthStr';
    }
  }

  // ============================================================================
  // RELATIVE TIME FORMATTING
  // ============================================================================

  /// Format relative time as "2 hours ago", "Yesterday", "3 days ago", etc.
  static String formatTimeAgo(DateTime? date) {
    if (date == null) return '';

    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inSeconds < 60) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      final minutes = difference.inMinutes;
      return minutes == 1 ? '1 minute ago' : '$minutes minutes ago';
    } else if (difference.inHours < 24) {
      final hours = difference.inHours;
      return hours == 1 ? '1 hour ago' : '$hours hours ago';
    } else if (difference.inDays < 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      final days = difference.inDays;
      return days == 1 ? '1 day ago' : '$days days ago';
    } else if (difference.inDays < 30) {
      final weeks = difference.inDays ~/ 7;
      return weeks == 1 ? '1 week ago' : '$weeks weeks ago';
    } else if (difference.inDays < 365) {
      final months = difference.inDays ~/ 30;
      return months == 1 ? '1 month ago' : '$months months ago';
    } else {
      final years = difference.inDays ~/ 365;
      return years == 1 ? '1 year ago' : '$years years ago';
    }
  }

  /// Format relative time with "Updated" prefix: "Updated 2 hours ago"
  static String formatLastUpdated(DateTime? date) {
    if (date == null) return '';
    return 'Updated ${formatTimeAgo(date)}';
  }

  // ============================================================================
  // PARSING METHODS
  // ============================================================================

  /// Parse ISO date string (yyyy-MM-dd) to DateTime
  static DateTime? parseIso(String? dateString) {
    if (dateString == null || dateString.isEmpty) return null;
    try {
      return DateTime.parse(dateString);
    } catch (_) {
      return null;
    }
  }

  // ============================================================================
  // UTILITY METHODS
  // ============================================================================

  /// Calculate months between two dates
  static int _monthsBetween(DateTime start, DateTime end) {
    return (end.year - start.year) * 12 + (end.month - start.month);
  }

  /// Check if date is today
  static bool isToday(DateTime? date) {
    if (date == null) return false;
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  /// Check if date is in the past
  static bool isPast(DateTime? date) {
    if (date == null) return false;
    return date.isBefore(DateTime.now());
  }

  /// Check if date is in the future
  static bool isFuture(DateTime? date) {
    if (date == null) return false;
    return date.isAfter(DateTime.now());
  }

  /// Get the start of day for a given date
  static DateTime startOfDay(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  /// Get the end of day for a given date
  static DateTime endOfDay(DateTime date) {
    return DateTime(date.year, date.month, date.day, 23, 59, 59, 999);
  }
}
