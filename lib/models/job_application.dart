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
    this.contactPerson,
    this.contactEmail,
    this.notes,
    this.salary,
    this.interviewDate,
    this.followUpDate,
    this.reminders = const [],
    this.statusHistory = const [],
    // Legacy fields for backward compatibility
    this.cvInstanceId,
    this.coverLetterInstanceId,
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
      contactPerson: json['contactPerson'] as String?,
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
      // Legacy fields
      cvInstanceId: (json['cvInstanceId'] ?? json['cvId']) as String?,
      coverLetterInstanceId:
          (json['coverLetterInstanceId'] ?? json['coverLetterId']) as String?,
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
  final String? contactPerson;
  final String? contactEmail;
  final String? notes;
  final String? salary;
  final DateTime? interviewDate;
  final DateTime? followUpDate;
  final List<Reminder> reminders;
  final List<StatusChange>? statusHistory;

  // Legacy fields for backward compatibility
  @Deprecated('Use folder-based storage instead')
  final String? cvInstanceId;
  @Deprecated('Use folder-based storage instead')
  final String? coverLetterInstanceId;

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
        'contactPerson': contactPerson,
        'contactEmail': contactEmail,
        'notes': notes,
        'salary': salary,
        'interviewDate': interviewDate?.toIso8601String(),
        'followUpDate': followUpDate?.toIso8601String(),
        'reminders': reminders.map((r) => r.toJson()).toList(),
        'statusHistory': statusHistory?.map((s) => s.toJson()).toList(),
        // Legacy fields
        'cvInstanceId': cvInstanceId,
        'coverLetterInstanceId': coverLetterInstanceId,
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
    String? contactPerson,
    String? contactEmail,
    String? notes,
    String? salary,
    DateTime? interviewDate,
    DateTime? followUpDate,
    List<Reminder>? reminders,
    List<StatusChange>? statusHistory,
    String? cvInstanceId,
    String? coverLetterInstanceId,
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
      contactPerson: contactPerson ?? this.contactPerson,
      contactEmail: contactEmail ?? this.contactEmail,
      notes: notes ?? this.notes,
      salary: salary ?? this.salary,
      interviewDate: interviewDate ?? this.interviewDate,
      followUpDate: followUpDate ?? this.followUpDate,
      reminders: reminders ?? this.reminders,
      statusHistory: statusHistory ?? this.statusHistory,
      cvInstanceId: cvInstanceId ?? this.cvInstanceId,
      coverLetterInstanceId:
          coverLetterInstanceId ?? this.coverLetterInstanceId,
    );
  }

  /// Create a copy with a new status and add to history
  JobApplication withStatusChange(ApplicationStatus newStatus,
      {String? notes}) {
    // Don't add to history if status hasn't changed
    if (newStatus == status) return this;

    final statusChange = StatusChange(
      status: newStatus,
      changedAt: DateTime.now(),
      notes: notes,
    );

    return copyWith(
      status: newStatus,
      lastUpdated: DateTime.now(),
      statusHistory: [...safeStatusHistory, statusChange],
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
