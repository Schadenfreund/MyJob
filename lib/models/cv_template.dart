import '../constants/app_constants.dart';
import 'cv_data.dart';

/// Base CV template that can be reused across applications
class CvTemplate {
  CvTemplate({
    required this.id,
    required this.name,
    this.language = DocumentLanguage.en,
    this.profile = '',
    this.skills = const [],
    this.languages = const [],
    this.interests = const [],
    this.contactDetails,
    this.experiences = const [],
    this.education = const [],
    this.createdAt,
    this.lastModified,
  });

  factory CvTemplate.fromJson(Map<String, dynamic> json) {
    return CvTemplate(
      id: json['id'] as String,
      name: json['name'] as String,
      language: DocumentLanguage.values.firstWhere(
        (l) => l.code == json['language'],
        orElse: () => DocumentLanguage.en,
      ),
      profile: json['profile'] as String? ?? '',
      skills: (json['skills'] as List<dynamic>?)
              ?.map((s) => s as String)
              .toList() ??
          [],
      languages: (json['languages'] as List<dynamic>?)
              ?.map((l) => LanguageSkill.fromJson(l as Map<String, dynamic>))
              .toList() ??
          [],
      interests: (json['interests'] as List<dynamic>?)
              ?.map((i) => i as String)
              .toList() ??
          [],
      contactDetails: json['contactDetails'] != null
          ? ContactDetails.fromJson(
              json['contactDetails'] as Map<String, dynamic>)
          : null,
      experiences: (json['experiences'] as List<dynamic>?)
              ?.map((e) => Experience.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      education: (json['education'] as List<dynamic>?)
              ?.map((e) => Education.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
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
  final String profile;
  final List<String> skills;
  final List<LanguageSkill> languages;
  final List<String> interests;
  final ContactDetails? contactDetails;
  final List<Experience> experiences;
  final List<Education> education;
  final DateTime? createdAt;
  final DateTime? lastModified;

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'language': language.code,
        'profile': profile,
        'skills': skills,
        'languages': languages.map((l) => l.toJson()).toList(),
        'interests': interests,
        'contactDetails': contactDetails?.toJson(),
        'experiences': experiences.map((e) => e.toJson()).toList(),
        'education': education.map((e) => e.toJson()).toList(),
        'createdAt': createdAt?.toIso8601String(),
        'lastModified': lastModified?.toIso8601String(),
      };

  CvTemplate copyWith({
    String? id,
    String? name,
    DocumentLanguage? language,
    String? profile,
    List<String>? skills,
    List<LanguageSkill>? languages,
    List<String>? interests,
    ContactDetails? contactDetails,
    List<Experience>? experiences,
    List<Education>? education,
    DateTime? createdAt,
    DateTime? lastModified,
  }) {
    return CvTemplate(
      id: id ?? this.id,
      name: name ?? this.name,
      language: language ?? this.language,
      profile: profile ?? this.profile,
      skills: skills ?? this.skills,
      languages: languages ?? this.languages,
      interests: interests ?? this.interests,
      contactDetails: contactDetails ?? this.contactDetails,
      experiences: experiences ?? this.experiences,
      education: education ?? this.education,
      createdAt: createdAt ?? this.createdAt,
      lastModified: lastModified ?? this.lastModified,
    );
  }

  /// Convert template to CvData for PDF generation
  CvData toCvData() {
    return CvData(
      id: id,
      name: name,
      language: language,
      profile: profile,
      skills: skills,
      languages: languages,
      interests: interests,
      contactDetails: contactDetails,
      experiences: experiences,
      education: education,
      lastModified: lastModified,
    );
  }
}

/// CV instance customized for a specific job application
class CvInstance {
  CvInstance({
    required this.id,
    required this.applicationId,
    required this.templateId,
    required this.name,
    this.language = DocumentLanguage.en,
    this.profile = '',
    this.skills = const [],
    this.languages = const [],
    this.interests = const [],
    this.contactDetails,
    this.experiences = const [],
    this.education = const [],
    this.customizations = const {},
    this.lastModified,
  });

  factory CvInstance.fromJson(Map<String, dynamic> json) {
    return CvInstance(
      id: json['id'] as String,
      applicationId: json['applicationId'] as String,
      templateId: json['templateId'] as String,
      name: json['name'] as String,
      language: DocumentLanguage.values.firstWhere(
        (l) => l.code == json['language'],
        orElse: () => DocumentLanguage.en,
      ),
      profile: json['profile'] as String? ?? '',
      skills: (json['skills'] as List<dynamic>?)
              ?.map((s) => s as String)
              .toList() ??
          [],
      languages: (json['languages'] as List<dynamic>?)
              ?.map((l) => LanguageSkill.fromJson(l as Map<String, dynamic>))
              .toList() ??
          [],
      interests: (json['interests'] as List<dynamic>?)
              ?.map((i) => i as String)
              .toList() ??
          [],
      contactDetails: json['contactDetails'] != null
          ? ContactDetails.fromJson(
              json['contactDetails'] as Map<String, dynamic>)
          : null,
      experiences: (json['experiences'] as List<dynamic>?)
              ?.map((e) => Experience.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      education: (json['education'] as List<dynamic>?)
              ?.map((e) => Education.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      customizations: (json['customizations'] as Map<String, dynamic>?)
              ?.map((k, v) => MapEntry(k, v as String)) ??
          {},
      lastModified: json['lastModified'] != null
          ? DateTime.parse(json['lastModified'] as String)
          : null,
    );
  }

  /// Create instance from template
  factory CvInstance.fromTemplate(
    CvTemplate template, {
    required String instanceId,
    required String applicationId,
  }) {
    return CvInstance(
      id: instanceId,
      applicationId: applicationId,
      templateId: template.id,
      name: template.name,
      language: template.language,
      profile: template.profile,
      skills: List.from(template.skills),
      languages: List.from(template.languages),
      interests: List.from(template.interests),
      contactDetails: template.contactDetails,
      experiences: List.from(template.experiences),
      education: List.from(template.education),
      lastModified: DateTime.now(),
    );
  }

  final String id;
  final String applicationId;
  final String templateId;
  final String name;
  final DocumentLanguage language;
  final String profile;
  final List<String> skills;
  final List<LanguageSkill> languages;
  final List<String> interests;
  final ContactDetails? contactDetails;
  final List<Experience> experiences;
  final List<Education> education;
  final Map<String, String> customizations;
  final DateTime? lastModified;

  Map<String, dynamic> toJson() => {
        'id': id,
        'applicationId': applicationId,
        'templateId': templateId,
        'name': name,
        'language': language.code,
        'profile': profile,
        'skills': skills,
        'languages': languages.map((l) => l.toJson()).toList(),
        'interests': interests,
        'contactDetails': contactDetails?.toJson(),
        'experiences': experiences.map((e) => e.toJson()).toList(),
        'education': education.map((e) => e.toJson()).toList(),
        'customizations': customizations,
        'lastModified': lastModified?.toIso8601String(),
      };

  CvInstance copyWith({
    String? id,
    String? applicationId,
    String? templateId,
    String? name,
    DocumentLanguage? language,
    String? profile,
    List<String>? skills,
    List<LanguageSkill>? languages,
    List<String>? interests,
    ContactDetails? contactDetails,
    List<Experience>? experiences,
    List<Education>? education,
    Map<String, String>? customizations,
    DateTime? lastModified,
  }) {
    return CvInstance(
      id: id ?? this.id,
      applicationId: applicationId ?? this.applicationId,
      templateId: templateId ?? this.templateId,
      name: name ?? this.name,
      language: language ?? this.language,
      profile: profile ?? this.profile,
      skills: skills ?? this.skills,
      languages: languages ?? this.languages,
      interests: interests ?? this.interests,
      contactDetails: contactDetails ?? this.contactDetails,
      experiences: experiences ?? this.experiences,
      education: education ?? this.education,
      customizations: customizations ?? this.customizations,
      lastModified: lastModified ?? this.lastModified,
    );
  }

  /// Convert instance to CvData for PDF generation
  CvData toCvData() {
    return CvData(
      id: id,
      name: name,
      language: language,
      profile: profile,
      skills: skills,
      languages: languages,
      interests: interests,
      contactDetails: contactDetails,
      experiences: experiences,
      education: education,
      lastModified: lastModified,
    );
  }
}
