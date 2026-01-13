import '../constants/app_constants.dart';
import 'user_data/personal_info.dart';
import 'user_data/work_experience.dart';
import 'user_data/skill.dart';
import 'user_data/language.dart';
import 'user_data/interest.dart';

/// Master profile containing all user data for a specific language
class MasterProfile {
  MasterProfile({
    required this.language,
    this.personalInfo,
    this.profileSummary = '',
    this.experiences = const [],
    this.education = const [],
    this.skills = const [],
    this.languages = const [],
    this.interests = const [],
    this.defaultCoverLetterBody = '',
    this.defaultGreeting = 'Dear Hiring Manager,',
    this.defaultClosing = 'Kind regards,',
  });

  /// Create from JSON
  factory MasterProfile.fromJson(Map<String, dynamic> json) {
    return MasterProfile(
      language: DocumentLanguage.fromJson(json['language'] as String? ?? 'EN'),
      personalInfo: json['personalInfo'] != null
          ? PersonalInfo.fromJson(json['personalInfo'] as Map<String, dynamic>)
          : null,
      profileSummary: json['profileSummary'] as String? ?? '',
      experiences: (json['experiences'] as List<dynamic>?)
              ?.map((e) => WorkExperience.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      education: (json['education'] as List<dynamic>?)
              ?.map((e) => Education.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      skills: (json['skills'] as List<dynamic>?)
              ?.map((e) => Skill.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      languages: (json['languages'] as List<dynamic>?)
              ?.map((e) => Language.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      interests: (json['interests'] as List<dynamic>?)
              ?.map((e) => Interest.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      defaultCoverLetterBody: json['defaultCoverLetterBody'] as String? ?? '',
      defaultGreeting:
          json['defaultGreeting'] as String? ?? 'Dear Hiring Manager,',
      defaultClosing: json['defaultClosing'] as String? ?? 'Kind regards,',
    );
  }

  final DocumentLanguage language;
  final PersonalInfo? personalInfo;
  final String profileSummary;
  final List<WorkExperience> experiences;
  final List<Education> education;
  final List<Skill> skills;
  final List<Language> languages;
  final List<Interest> interests;
  final String defaultCoverLetterBody;
  final String defaultGreeting;
  final String defaultClosing;

  /// Convert to JSON
  Map<String, dynamic> toJson() => {
        'language': language.toJson(),
        'personalInfo': personalInfo?.toJson(),
        'profileSummary': profileSummary,
        'experiences': experiences.map((e) => e.toJson()).toList(),
        'education': education.map((e) => e.toJson()).toList(),
        'skills': skills.map((e) => e.toJson()).toList(),
        'languages': languages.map((e) => e.toJson()).toList(),
        'interests': interests.map((e) => e.toJson()).toList(),
        'defaultCoverLetterBody': defaultCoverLetterBody,
        'defaultGreeting': defaultGreeting,
        'defaultClosing': defaultClosing,
      };

  /// Create a copy with updated fields
  MasterProfile copyWith({
    DocumentLanguage? language,
    PersonalInfo? personalInfo,
    String? profileSummary,
    List<WorkExperience>? experiences,
    List<Education>? education,
    List<Skill>? skills,
    List<Language>? languages,
    List<Interest>? interests,
    String? defaultCoverLetterBody,
    String? defaultGreeting,
    String? defaultClosing,
  }) {
    return MasterProfile(
      language: language ?? this.language,
      personalInfo: personalInfo ?? this.personalInfo,
      profileSummary: profileSummary ?? this.profileSummary,
      experiences: experiences ?? this.experiences,
      education: education ?? this.education,
      skills: skills ?? this.skills,
      languages: languages ?? this.languages,
      interests: interests ?? this.interests,
      defaultCoverLetterBody:
          defaultCoverLetterBody ?? this.defaultCoverLetterBody,
      defaultGreeting: defaultGreeting ?? this.defaultGreeting,
      defaultClosing: defaultClosing ?? this.defaultClosing,
    );
  }

  /// Create an empty profile for a language
  factory MasterProfile.empty(DocumentLanguage language) {
    return MasterProfile(
      language: language,
      personalInfo: null,
      profileSummary: '',
      experiences: [],
      education: [],
      skills: [],
      languages: [],
      interests: [],
      defaultCoverLetterBody: '',
      defaultGreeting: 'Dear Hiring Manager,',
      defaultClosing: 'Kind regards,',
    );
  }
}

/// Education entry model
class Education {
  Education({
    required this.id,
    required this.institution,
    required this.degree,
    required this.fieldOfStudy,
    required this.startDate,
    this.endDate,
    this.isCurrent = false,
    this.description,
    this.grade,
  });

  factory Education.fromJson(Map<String, dynamic> json) {
    return Education(
      id: json['id'] as String,
      institution: json['institution'] as String,
      degree: json['degree'] as String,
      fieldOfStudy: json['fieldOfStudy'] as String,
      startDate: DateTime.parse(json['startDate'] as String),
      endDate: json['endDate'] != null
          ? DateTime.parse(json['endDate'] as String)
          : null,
      isCurrent: json['isCurrent'] as bool? ?? false,
      description: json['description'] as String?,
      grade: json['grade'] as String?,
    );
  }

  final String id;
  final String institution;
  final String degree;
  final String fieldOfStudy;
  final DateTime startDate;
  final DateTime? endDate;
  final bool isCurrent;
  final String? description;
  final String? grade;

  Map<String, dynamic> toJson() => {
        'id': id,
        'institution': institution,
        'degree': degree,
        'fieldOfStudy': fieldOfStudy,
        'startDate': startDate.toIso8601String(),
        'endDate': endDate?.toIso8601String(),
        'isCurrent': isCurrent,
        'description': description,
        'grade': grade,
      };

  Education copyWith({
    String? id,
    String? institution,
    String? degree,
    String? fieldOfStudy,
    DateTime? startDate,
    DateTime? endDate,
    bool? isCurrent,
    String? description,
    String? grade,
  }) {
    return Education(
      id: id ?? this.id,
      institution: institution ?? this.institution,
      degree: degree ?? this.degree,
      fieldOfStudy: fieldOfStudy ?? this.fieldOfStudy,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      isCurrent: isCurrent ?? this.isCurrent,
      description: description ?? this.description,
      grade: grade ?? this.grade,
    );
  }
}
