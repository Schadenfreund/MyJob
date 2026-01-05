import '../constants/app_constants.dart';

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

  // Legacy fields for backward compatibility
  @Deprecated('Use folder-based storage instead')
  final String? cvInstanceId;
  @Deprecated('Use folder-based storage instead')
  final String? coverLetterInstanceId;

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
      cvInstanceId: cvInstanceId ?? this.cvInstanceId,
      coverLetterInstanceId:
          coverLetterInstanceId ?? this.coverLetterInstanceId,
    );
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
