import 'dart:io';
import 'package:yaml/yaml.dart';
import '../models/user_data/personal_info.dart';
import '../models/user_data/skill.dart';
import '../models/user_data/work_experience.dart';
import '../models/user_data/language.dart';
import '../models/user_data/interest.dart';

/// Service for importing user data from YAML template files
class YamlImportService {
  /// Import CV data from YAML file
  Future<CvImportResult> importCvData(File yamlFile) async {
    try {
      final yamlString = await yamlFile.readAsString();
      final yamlData = loadYaml(yamlString) as YamlMap;

      PersonalInfo? personalInfo;
      List<Skill> skills = [];
      List<Language> languages = [];
      List<Interest> interests = [];
      List<WorkExperience> workExperiences = [];

      // Parse personal info
      if (yamlData['personal_info'] != null) {
        final piData = yamlData['personal_info'] as YamlMap;
        personalInfo = PersonalInfo(
          fullName: piData['full_name'] as String? ?? '',
          email: piData['email'] as String?,
          phone: piData['phone'] as String?,
          address: piData['address'] as String?,
          city: piData['city'] as String?,
          country: piData['country'] as String?,
          profileSummary: piData['profile_summary'] as String?,
        );
      }

      // Parse skills
      if (yamlData['skills'] != null) {
        final skillsList = yamlData['skills'] as YamlList;
        for (final skillData in skillsList) {
          final skill = Skill(
            name: skillData['name'] as String,
            category: skillData['category'] as String?,
            level: _parseSkillLevel(skillData['level'] as String?),
          );
          skills.add(skill);
        }
      }

      // Parse languages
      if (yamlData['languages'] != null) {
        final langList = yamlData['languages'] as YamlList;
        for (final langData in langList) {
          final language = Language(
            name: langData['name'] as String,
            proficiency:
                _parseLanguageProficiency(langData['proficiency'] as String?),
          );
          languages.add(language);
        }
      }

      // Parse interests
      if (yamlData['interests'] != null) {
        final interestsList = yamlData['interests'] as YamlList;
        for (final interestData in interestsList) {
          final interest = Interest(
            name: interestData['name'] as String,
            category: interestData['category'] as String?,
          );
          interests.add(interest);
        }
      }

      // Parse work experience
      if (yamlData['work_experience'] != null) {
        final expList = yamlData['work_experience'] as YamlList;
        for (final expData in expList) {
          final responsibilities = <String>[];
          if (expData['responsibilities'] != null) {
            final respList = expData['responsibilities'] as YamlList;
            responsibilities.addAll(respList.map((e) => e.toString()));
          }

          final workExp = WorkExperience(
            company: expData['company'] as String,
            position: expData['position'] as String,
            startDate: DateTime.parse(expData['start_date'] as String),
            endDate: expData['end_date'] != null
                ? DateTime.parse(expData['end_date'] as String)
                : null,
            isCurrent: expData['is_current'] as bool? ?? false,
            location: expData['location'] as String?,
            description: expData['description'] as String?,
            responsibilities: responsibilities,
          );
          workExperiences.add(workExp);
        }
      }

      return CvImportResult(
        success: true,
        personalInfo: personalInfo,
        skills: skills,
        languages: languages,
        interests: interests,
        workExperiences: workExperiences,
      );
    } catch (e) {
      return CvImportResult(
        success: false,
        error: 'Failed to import CV data: $e',
      );
    }
  }

  /// Import cover letter template from YAML file
  Future<CoverLetterImportResult> importCoverLetterTemplate(
      File yamlFile) async {
    try {
      final yamlString = await yamlFile.readAsString();
      final yamlData = loadYaml(yamlString) as YamlMap;

      final language = yamlData['language'] as String? ?? 'english';
      final version = yamlData['version'] as String? ?? 'current';

      // Determine which template to use
      final templateKey =
          version == 'past_tense' ? 'template_past_tense' : 'template';
      final template = yamlData[templateKey] as YamlMap?;

      if (template == null) {
        return CoverLetterImportResult(
          success: false,
          error: 'Template not found in YAML file',
        );
      }

      final greeting = template['greeting'] as String? ?? '';
      final paragraphs = <String>[];

      if (template['paragraphs'] != null) {
        final paraList = template['paragraphs'] as YamlList;
        paragraphs.addAll(paraList.map((e) => e.toString()));
      }

      final closing = template['closing'] as String? ?? '';
      final signature = template['signature'] as String? ?? '';

      // Parse placeholders
      final placeholders = <Map<String, String>>[];
      if (yamlData['placeholders'] != null) {
        final phList = yamlData['placeholders'] as YamlList;
        for (final ph in phList) {
          placeholders.add({
            'name': ph['name'] as String? ?? '',
            'description': ph['description'] as String? ?? '',
            'location': ph['location'] as String? ?? '',
            'example': ph['example'] as String? ?? '',
          });
        }
      }

      return CoverLetterImportResult(
        success: true,
        language: language,
        version: version,
        greeting: greeting,
        paragraphs: paragraphs,
        closing: closing,
        signature: signature,
        placeholders: placeholders,
      );
    } catch (e) {
      return CoverLetterImportResult(
        success: false,
        error: 'Failed to import cover letter template: $e',
      );
    }
  }

  /// Parse skill level from string
  SkillLevel _parseSkillLevel(String? level) {
    if (level == null) return SkillLevel.intermediate;
    switch (level.toLowerCase()) {
      case 'beginner':
        return SkillLevel.beginner;
      case 'intermediate':
        return SkillLevel.intermediate;
      case 'advanced':
        return SkillLevel.advanced;
      case 'expert':
        return SkillLevel.expert;
      default:
        return SkillLevel.intermediate;
    }
  }

  /// Parse language proficiency from string
  LanguageProficiency _parseLanguageProficiency(String? proficiency) {
    if (proficiency == null) return LanguageProficiency.intermediate;
    switch (proficiency.toLowerCase()) {
      case 'native':
        return LanguageProficiency.native;
      case 'fluent':
        return LanguageProficiency.fluent;
      case 'advanced':
        return LanguageProficiency.advanced;
      case 'intermediate':
        return LanguageProficiency.intermediate;
      case 'basic':
        return LanguageProficiency.basic;
      default:
        return LanguageProficiency.intermediate;
    }
  }
}

/// Result of CV data import
class CvImportResult {
  final bool success;
  final String? error;
  final PersonalInfo? personalInfo;
  final List<Skill> skills;
  final List<Language> languages;
  final List<Interest> interests;
  final List<WorkExperience> workExperiences;

  CvImportResult({
    required this.success,
    this.error,
    this.personalInfo,
    this.skills = const [],
    this.languages = const [],
    this.interests = const [],
    this.workExperiences = const [],
  });
}

/// Result of cover letter template import
class CoverLetterImportResult {
  final bool success;
  final String? error;
  final String language;
  final String version;
  final String greeting;
  final List<String> paragraphs;
  final String closing;
  final String signature;
  final List<Map<String, String>> placeholders;

  CoverLetterImportResult({
    required this.success,
    this.error,
    this.language = 'english',
    this.version = 'current',
    this.greeting = '',
    this.paragraphs = const [],
    this.closing = '',
    this.signature = '',
    this.placeholders = const [],
  });
}
