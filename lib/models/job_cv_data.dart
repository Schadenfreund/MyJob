import 'master_profile.dart';
import 'user_data/personal_info.dart';
import 'user_data/work_experience.dart';
import 'user_data/skill.dart';
import 'user_data/language.dart';
import 'user_data/interest.dart';

/// CV data tailored for a specific job application
/// This is a clone of MasterProfile that can be customized per-job
class JobCvData {
  JobCvData({
    this.personalInfo,
    this.experiences = const [],
    this.education = const [],
    this.skills = const [],
    this.languages = const [],
    this.interests = const [],
  });

  /// Create from JSON
  factory JobCvData.fromJson(Map<String, dynamic> json) {
    return JobCvData(
      personalInfo: json['personalInfo'] != null
          ? PersonalInfo.fromJson(json['personalInfo'] as Map<String, dynamic>)
          : null,
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
    );
  }

  /// Create from MasterProfile (cloning for a job application)
  factory JobCvData.fromMasterProfile(MasterProfile profile) {
    return JobCvData(
      personalInfo: profile.personalInfo,
      experiences: List.from(profile.experiences),
      education: List.from(profile.education),
      skills: List.from(profile.skills),
      languages: List.from(profile.languages),
      interests: List.from(profile.interests),
    );
  }

  final PersonalInfo? personalInfo;
  final List<WorkExperience> experiences;
  final List<Education> education;
  final List<Skill> skills;
  final List<Language> languages;
  final List<Interest> interests;

  /// Convert to JSON
  Map<String, dynamic> toJson() => {
        'personalInfo': personalInfo?.toJson(),
        'experiences': experiences.map((e) => e.toJson()).toList(),
        'education': education.map((e) => e.toJson()).toList(),
        'skills': skills.map((e) => e.toJson()).toList(),
        'languages': languages.map((e) => e.toJson()).toList(),
        'interests': interests.map((e) => e.toJson()).toList(),
      };

  /// Create a copy with updated fields
  JobCvData copyWith({
    PersonalInfo? personalInfo,
    List<WorkExperience>? experiences,
    List<Education>? education,
    List<Skill>? skills,
    List<Language>? languages,
    List<Interest>? interests,
  }) {
    return JobCvData(
      personalInfo: personalInfo ?? this.personalInfo,
      experiences: experiences ?? this.experiences,
      education: education ?? this.education,
      skills: skills ?? this.skills,
      languages: languages ?? this.languages,
      interests: interests ?? this.interests,
    );
  }
}
