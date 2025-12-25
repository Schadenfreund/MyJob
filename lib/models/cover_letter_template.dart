import '../constants/app_constants.dart';
import 'cover_letter.dart';

/// Base cover letter template that can be reused across applications
class CoverLetterTemplate {
  CoverLetterTemplate({
    required this.id,
    required this.name,
    this.language = DocumentLanguage.en,
    this.greeting = 'Dear Hiring Manager,',
    this.body = '',
    this.closing = 'Kind regards,',
    this.senderName,
    this.createdAt,
    this.lastModified,
  });

  factory CoverLetterTemplate.fromJson(Map<String, dynamic> json) {
    return CoverLetterTemplate(
      id: json['id'] as String,
      name: json['name'] as String,
      language: DocumentLanguage.values.firstWhere(
        (l) => l.code == json['language'],
        orElse: () => DocumentLanguage.en,
      ),
      greeting: json['greeting'] as String? ?? 'Dear Hiring Manager,',
      body: json['body'] as String? ?? '',
      closing: json['closing'] as String? ?? 'Kind regards,',
      senderName: json['senderName'] as String?,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : null,
      lastModified: json['lastModified'] != null
          ? DateTime.parse(json['lastModified'] as String)
          : null,
    );
  }

  final String id;
  final String name;
  final DocumentLanguage language;
  final String greeting;
  final String body;
  final String closing;
  final String? senderName;
  final DateTime? createdAt;
  final DateTime? lastModified;

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'language': language.code,
        'greeting': greeting,
        'body': body,
        'closing': closing,
        'senderName': senderName,
        'createdAt': createdAt?.toIso8601String(),
        'lastModified': lastModified?.toIso8601String(),
      };

  CoverLetterTemplate copyWith({
    String? id,
    String? name,
    DocumentLanguage? language,
    String? greeting,
    String? body,
    String? closing,
    String? senderName,
    DateTime? createdAt,
    DateTime? lastModified,
  }) {
    return CoverLetterTemplate(
      id: id ?? this.id,
      name: name ?? this.name,
      language: language ?? this.language,
      greeting: greeting ?? this.greeting,
      body: body ?? this.body,
      closing: closing ?? this.closing,
      senderName: senderName ?? this.senderName,
      createdAt: createdAt ?? this.createdAt,
      lastModified: lastModified ?? this.lastModified,
    );
  }
}

/// Cover letter instance customized for a specific job application
class CoverLetterInstance {
  CoverLetterInstance({
    required this.id,
    required this.applicationId,
    required this.templateId,
    required this.name,
    this.language = DocumentLanguage.en,
    this.recipientName,
    this.recipientTitle,
    this.companyName,
    this.jobTitle,
    this.greeting = 'Dear Hiring Manager,',
    this.body = '',
    this.closing = 'Kind regards,',
    this.senderName,
    this.placeholders = const {},
    this.customizations = const {},
    this.lastModified,
  });

  factory CoverLetterInstance.fromJson(Map<String, dynamic> json) {
    return CoverLetterInstance(
      id: json['id'] as String,
      applicationId: json['applicationId'] as String,
      templateId: json['templateId'] as String,
      name: json['name'] as String,
      language: DocumentLanguage.values.firstWhere(
        (l) => l.code == json['language'],
        orElse: () => DocumentLanguage.en,
      ),
      recipientName: json['recipientName'] as String?,
      recipientTitle: json['recipientTitle'] as String?,
      companyName: json['companyName'] as String?,
      jobTitle: json['jobTitle'] as String?,
      greeting: json['greeting'] as String? ?? 'Dear Hiring Manager,',
      body: json['body'] as String? ?? '',
      closing: json['closing'] as String? ?? 'Kind regards,',
      senderName: json['senderName'] as String?,
      placeholders: (json['placeholders'] as Map<String, dynamic>?)
              ?.map((k, v) => MapEntry(k, v as String)) ??
          {},
      customizations: (json['customizations'] as Map<String, dynamic>?)
              ?.map((k, v) => MapEntry(k, v as String)) ??
          {},
      lastModified: json['lastModified'] != null
          ? DateTime.parse(json['lastModified'] as String)
          : null,
    );
  }

  /// Create instance from template
  factory CoverLetterInstance.fromTemplate(
    CoverLetterTemplate template, {
    required String instanceId,
    required String applicationId,
    String? companyName,
    String? jobTitle,
  }) {
    // Auto-fill placeholders
    final placeholders = <String, String>{};
    if (companyName != null) placeholders['COMPANY'] = companyName;
    if (jobTitle != null) placeholders['POSITION'] = jobTitle;

    return CoverLetterInstance(
      id: instanceId,
      applicationId: applicationId,
      templateId: template.id,
      name: template.name,
      language: template.language,
      companyName: companyName,
      jobTitle: jobTitle,
      greeting: template.greeting,
      body: template.body,
      closing: template.closing,
      senderName: template.senderName,
      placeholders: placeholders,
      lastModified: DateTime.now(),
    );
  }

  final String id;
  final String applicationId;
  final String templateId;
  final String name;
  final DocumentLanguage language;
  final String? recipientName;
  final String? recipientTitle;
  final String? companyName;
  final String? jobTitle;
  final String greeting;
  final String body;
  final String closing;
  final String? senderName;
  final Map<String, String> placeholders;
  final Map<String, String> customizations;
  final DateTime? lastModified;

  Map<String, dynamic> toJson() => {
        'id': id,
        'applicationId': applicationId,
        'templateId': templateId,
        'name': name,
        'language': language.code,
        'recipientName': recipientName,
        'recipientTitle': recipientTitle,
        'companyName': companyName,
        'jobTitle': jobTitle,
        'greeting': greeting,
        'body': body,
        'closing': closing,
        'senderName': senderName,
        'placeholders': placeholders,
        'customizations': customizations,
        'lastModified': lastModified?.toIso8601String(),
      };

  CoverLetterInstance copyWith({
    String? id,
    String? applicationId,
    String? templateId,
    String? name,
    DocumentLanguage? language,
    String? recipientName,
    String? recipientTitle,
    String? companyName,
    String? jobTitle,
    String? greeting,
    String? body,
    String? closing,
    String? senderName,
    Map<String, String>? placeholders,
    Map<String, String>? customizations,
    DateTime? lastModified,
  }) {
    return CoverLetterInstance(
      id: id ?? this.id,
      applicationId: applicationId ?? this.applicationId,
      templateId: templateId ?? this.templateId,
      name: name ?? this.name,
      language: language ?? this.language,
      recipientName: recipientName ?? this.recipientName,
      recipientTitle: recipientTitle ?? this.recipientTitle,
      companyName: companyName ?? this.companyName,
      jobTitle: jobTitle ?? this.jobTitle,
      greeting: greeting ?? this.greeting,
      body: body ?? this.body,
      closing: closing ?? this.closing,
      senderName: senderName ?? this.senderName,
      placeholders: placeholders ?? this.placeholders,
      customizations: customizations ?? this.customizations,
      lastModified: lastModified ?? this.lastModified,
    );
  }

  /// Process the body text by replacing placeholders
  String get processedBody {
    var result = body;
    for (final entry in placeholders.entries) {
      result = result.replaceAll('==${entry.key}==', entry.value);
    }
    return result;
  }

  /// Convert instance to CoverLetter for PDF generation
  CoverLetter toCoverLetter() {
    return CoverLetter(
      id: id,
      name: name,
      language: language,
      recipientName: recipientName,
      recipientTitle: recipientTitle,
      companyName: companyName,
      jobTitle: jobTitle,
      greeting: greeting,
      body: body,
      closing: closing,
      senderName: senderName,
      placeholders: placeholders,
      lastModified: lastModified,
    );
  }
}
