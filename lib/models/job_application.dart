import '../constants/app_constants.dart';

/// Model for tracking status changes
class StatusChange {
  StatusChange({
    required this.status,
    required this.changedAt,
    this.notes,
  });

  factory StatusChange.fromJson(Map<String, dynamic> json) {
    return StatusChange(
      status: ApplicationStatus.values.firstWhere(
        (s) => s.name == json['status'],
        orElse: () => ApplicationStatus.draft,
      ),
      changedAt: DateTime.parse(json['changedAt'] as String),
      notes: json['notes'] as String?,
    );
  }

  final ApplicationStatus status;
  final DateTime changedAt;
  final String? notes;

  Map<String, dynamic> toJson() => {
        'status': status.name,
        'changedAt': changedAt.toIso8601String(),
        'notes': notes,
      };

  StatusChange copyWith({
    ApplicationStatus? status,
    DateTime? changedAt,
    Object? notes = _unset,
  }) {
    return StatusChange(
      status: status ?? this.status,
      changedAt: changedAt ?? this.changedAt,
      notes: notes == _unset ? this.notes : notes as String?,
    );
  }

  static const _unset = Object();
}

/// Model representing a job application
class JobApplication {
  JobApplication({
    required this.id,
    required this.company,
    required this.position,
    required this.baseLanguage,
    this.folderPath,
    this.status = ApplicationStatus.draft,
    this.applicationDate,
    this.lastUpdated,
    this.location,
    this.jobUrl,
    this.contactFirstName,
    this.contactLastName,
    this.contactEmail,
    this.notes,
    this.salary,
    this.interviewDate,
    this.followUpDate,
    this.reminders = const [],
    this.statusHistory = const [],
  });

  /// Create from JSON
  factory JobApplication.fromJson(Map<String, dynamic> json) {
    return JobApplication(
      id: json['id'] as String,
      company: json['company'] as String,
      position: json['position'] as String,
      baseLanguage: json['baseLanguage'] != null
          ? DocumentLanguage.fromJson(json['baseLanguage'] as String)
          : DocumentLanguage.en,
      folderPath: json['folderPath'] as String?,
      status: ApplicationStatus.values.firstWhere(
        (s) => s.name == json['status'],
        orElse: () => ApplicationStatus.draft,
      ),
      applicationDate: json['applicationDate'] != null
          ? DateTime.parse(json['applicationDate'] as String)
          : null,
      lastUpdated: json['lastUpdated'] != null
          ? DateTime.parse(json['lastUpdated'] as String)
          : null,
      location: json['location'] as String?,
      jobUrl: json['jobUrl'] as String?,
      contactFirstName: json['contactFirstName'] as String? ??
          _splitLegacyContactPerson(json['contactPerson'] as String?)[0],
      contactLastName: json['contactLastName'] as String? ??
          _splitLegacyContactPerson(json['contactPerson'] as String?)[1],
      contactEmail: json['contactEmail'] as String?,
      notes: json['notes'] as String?,
      salary: json['salary'] as String?,
      interviewDate: json['interviewDate'] != null
          ? DateTime.parse(json['interviewDate'] as String)
          : null,
      followUpDate: json['followUpDate'] != null
          ? DateTime.parse(json['followUpDate'] as String)
          : null,
      reminders: (json['reminders'] as List<dynamic>?)
              ?.map((r) => Reminder.fromJson(r as Map<String, dynamic>))
              .toList() ??
          [],
      statusHistory: (json['statusHistory'] as List<dynamic>?)
              ?.map((s) => StatusChange.fromJson(s as Map<String, dynamic>))
              .toList() ??
          [],
      // Note: Legacy cvInstanceId and coverLetterInstanceId fields are ignored for backward compatibility
    );
  }

  final String id;
  final String company;
  final String position;
  final DocumentLanguage baseLanguage;
  final String? folderPath;
  final ApplicationStatus status;
  final DateTime? applicationDate;
  final DateTime? lastUpdated;
  final String? location;
  final String? jobUrl;
  final String? contactFirstName;
  final String? contactLastName;
  final String? contactEmail;

  /// Full contact name derived from first + last name.
  String? get contactPerson {
    final parts = [contactFirstName, contactLastName]
        .where((s) => s != null && s.isNotEmpty)
        .join(' ');
    return parts.isEmpty ? null : parts;
  }

  static List<String?> _splitLegacyContactPerson(String? value) {
    if (value == null || value.isEmpty) return [null, null];
    final idx = value.indexOf(' ');
    if (idx == -1) return [value, null];
    return [value.substring(0, idx), value.substring(idx + 1)];
  }
  final String? notes;
  final String? salary;
  final DateTime? interviewDate;
  final DateTime? followUpDate;
  final List<Reminder> reminders;
  final List<StatusChange>? statusHistory;

  /// Safe getter for status history - returns empty list if null
  List<StatusChange> get safeStatusHistory => statusHistory ?? [];

  /// Convert to JSON
  Map<String, dynamic> toJson() => {
        'id': id,
        'company': company,
        'position': position,
        'baseLanguage': baseLanguage.toJson(),
        'folderPath': folderPath,
        'status': status.name,
        'applicationDate': applicationDate?.toIso8601String(),
        'lastUpdated': lastUpdated?.toIso8601String(),
        'location': location,
        'jobUrl': jobUrl,
        'contactFirstName': contactFirstName,
        'contactLastName': contactLastName,
        'contactEmail': contactEmail,
        'notes': notes,
        'salary': salary,
        'interviewDate': interviewDate?.toIso8601String(),
        'followUpDate': followUpDate?.toIso8601String(),
        'reminders': reminders.map((r) => r.toJson()).toList(),
        'statusHistory': statusHistory?.map((s) => s.toJson()).toList(),
      };

  /// Create a copy with updated fields
  JobApplication copyWith({
    String? id,
    String? company,
    String? position,
    DocumentLanguage? baseLanguage,
    String? folderPath,
    ApplicationStatus? status,
    DateTime? applicationDate,
    DateTime? lastUpdated,
    String? location,
    String? jobUrl,
    String? contactFirstName,
    String? contactLastName,
    String? contactEmail,
    String? notes,
    String? salary,
    DateTime? interviewDate,
    DateTime? followUpDate,
    List<Reminder>? reminders,
    List<StatusChange>? statusHistory,
  }) {
    return JobApplication(
      id: id ?? this.id,
      company: company ?? this.company,
      position: position ?? this.position,
      baseLanguage: baseLanguage ?? this.baseLanguage,
      folderPath: folderPath ?? this.folderPath,
      status: status ?? this.status,
      applicationDate: applicationDate ?? this.applicationDate,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      location: location ?? this.location,
      jobUrl: jobUrl ?? this.jobUrl,
      contactFirstName: contactFirstName ?? this.contactFirstName,
      contactLastName: contactLastName ?? this.contactLastName,
      contactEmail: contactEmail ?? this.contactEmail,
      notes: notes ?? this.notes,
      salary: salary ?? this.salary,
      interviewDate: interviewDate ?? this.interviewDate,
      followUpDate: followUpDate ?? this.followUpDate,
      reminders: reminders ?? this.reminders,
      statusHistory: statusHistory ?? this.statusHistory,
    );
  }

  /// Create a copy with a new status, recording the transition in [statusHistory].
  ///
  /// [at] defaults to now; pass a custom value when back-filling history entries.
  /// Automatically sets [applicationDate] the first time status reaches [applied].
  JobApplication withStatusChange(
    ApplicationStatus newStatus, {
    String? notes,
    DateTime? at,
  }) {
    if (newStatus == status) return this;
    final when = at ?? DateTime.now();
    return copyWith(
      status: newStatus,
      lastUpdated: DateTime.now(),
      applicationDate: newStatus == ApplicationStatus.applied &&
              applicationDate == null
          ? when
          : applicationDate,
      statusHistory: [
        ...safeStatusHistory,
        StatusChange(status: newStatus, changedAt: when, notes: notes),
      ],
    );
  }

  /// Get the date when a specific status was reached, if ever
  DateTime? getStatusChangeDate(ApplicationStatus targetStatus) {
    final change = safeStatusHistory
        .where((change) => change.status == targetStatus)
        .lastOrNull;
    return change?.changedAt;
  }

  /// Get all status changes in chronological order
  List<StatusChange> get chronologicalStatusHistory {
    final history = [...safeStatusHistory];
    history.sort((a, b) => a.changedAt.compareTo(b.changedAt));
    return history;
  }
}

/// Model for application reminders
class Reminder {
  Reminder({
    required this.id,
    required this.date,
    required this.message,
    this.isCompleted = false,
  });

  factory Reminder.fromJson(Map<String, dynamic> json) {
    return Reminder(
      id: json['id'] as String,
      date: DateTime.parse(json['date'] as String),
      message: json['message'] as String,
      isCompleted: json['isCompleted'] as bool? ?? false,
    );
  }

  final String id;
  final DateTime date;
  final String message;
  final bool isCompleted;

  Map<String, dynamic> toJson() => {
        'id': id,
        'date': date.toIso8601String(),
        'message': message,
        'isCompleted': isCompleted,
      };

  Reminder copyWith({
    String? id,
    DateTime? date,
    String? message,
    bool? isCompleted,
  }) {
    return Reminder(
      id: id ?? this.id,
      date: date ?? this.date,
      message: message ?? this.message,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }
}
