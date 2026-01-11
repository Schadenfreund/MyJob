import 'dart:io';
import 'package:yaml/yaml.dart';
import '../models/user_data/personal_info.dart';
import '../models/user_data/skill.dart';
import '../models/user_data/work_experience.dart';
import '../models/user_data/language.dart';
import '../models/user_data/interest.dart';

/// Unified YAML import service with auto-detection and smart routing
///
/// This service consolidates all YAML import functionality into a single
/// entry point that auto-detects file type and provides consistent parsing.
class UnifiedYamlImportService {
  /// Detect the type of YAML file and parse accordingly
  Future<UnifiedImportResult> importYamlFile(File file) async {
    try {
      final yamlString = await file.readAsString();
      final yamlData = loadYaml(yamlString) as YamlMap;

      // Auto-detect file type based on content
      final fileType = _detectFileType(yamlData);

      switch (fileType) {
        case YamlFileType.cvData:
          return _parseCvData(yamlData, file.path);
        case YamlFileType.coverLetter:
          return _parseCoverLetter(yamlData, file.path);
        case YamlFileType.unknown:
          return UnifiedImportResult.error(
            'Unable to determine file type. Expected CV data or Cover Letter template.',
          );
      }
    } catch (e) {
      return UnifiedImportResult.error('Failed to parse YAML file: $e');
    }
  }

  /// Detect file type based on YAML content structure
  YamlFileType _detectFileType(YamlMap data) {
    // CV data indicators
    final hasCvIndicators = data.containsKey('personal_info') ||
        data.containsKey('skills') ||
        data.containsKey('work_experience') ||
        data.containsKey('languages') ||
        data.containsKey('interests');

    // Cover letter indicators
    final hasCoverLetterIndicators = data.containsKey('template') ||
        data.containsKey('template_past_tense') ||
        (data.containsKey('greeting') && data.containsKey('paragraphs'));

    if (hasCoverLetterIndicators && !hasCvIndicators) {
      return YamlFileType.coverLetter;
    } else if (hasCvIndicators) {
      return YamlFileType.cvData;
    }

    return YamlFileType.unknown;
  }

  /// Parse CV data from YAML
  UnifiedImportResult _parseCvData(YamlMap yamlData, String filePath) {
    // Try to detect language from multiple sources
    String? detectedLanguage = yamlData['language'] as String?;

    // If not specified, try to detect from file path
    if (detectedLanguage == null) {
      final fileName = filePath.toLowerCase();
      if (fileName.contains('german') || fileName.contains('deutsch') || fileName.contains('_de')) {
        detectedLanguage = 'german';
      } else if (fileName.contains('english') || fileName.contains('_en')) {
        detectedLanguage = 'english';
      }
    }

    // Default to English if still not detected
    detectedLanguage ??= 'english';

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
        jobTitle: piData['job_title'] as String?,
        email: piData['email'] as String?,
        phone: piData['phone'] as String?,
        address: piData['address'] as String?,
        city: piData['city'] as String?,
        country: piData['country'] as String?,
        linkedin: piData['linkedin'] as String?,
        website: piData['website'] as String?,
        profileSummary: piData['profile_summary'] as String?,
      );
    }

    // Parse skills
    if (yamlData['skills'] != null) {
      final skillsList = yamlData['skills'] as YamlList;
      for (final skillData in skillsList) {
        skills.add(Skill(
          name: skillData['name'] as String,
          category: skillData['category'] as String?,
          level: _parseSkillLevel(skillData['level'] as String?),
        ));
      }
    }

    // Parse languages
    if (yamlData['languages'] != null) {
      final langList = yamlData['languages'] as YamlList;
      for (final langData in langList) {
        languages.add(Language(
          name: langData['name'] as String,
          proficiency:
              _parseLanguageProficiency(langData['proficiency'] as String?),
        ));
      }
    }

    // Parse interests
    if (yamlData['interests'] != null) {
      final interestsList = yamlData['interests'] as YamlList;
      for (final interestData in interestsList) {
        interests.add(Interest(
          name: interestData['name'] as String,
          category: interestData['category'] as String?,
        ));
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

        workExperiences.add(WorkExperience(
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
        ));
      }
    }

    return UnifiedImportResult.cv(
      filePath: filePath,
      language: detectedLanguage,
      personalInfo: personalInfo,
      skills: skills,
      languages: languages,
      interests: interests,
      workExperiences: workExperiences,
    );
  }

  /// Parse cover letter template from YAML
  UnifiedImportResult _parseCoverLetter(YamlMap yamlData, String filePath) {
    // Try to detect language from multiple sources
    String? detectedLanguage = yamlData['language'] as String?;

    // If not specified, try to detect from file path
    if (detectedLanguage == null) {
      final fileName = filePath.toLowerCase();
      if (fileName.contains('german') || fileName.contains('deutsch') || fileName.contains('_de')) {
        detectedLanguage = 'german';
      } else if (fileName.contains('english') || fileName.contains('_en')) {
        detectedLanguage = 'english';
      }
    }

    // Default to English if still not detected
    detectedLanguage ??= 'english';

    final version = yamlData['version'] as String? ?? 'current';

    // Determine which template to use
    final templateKey =
        version == 'past_tense' ? 'template_past_tense' : 'template';
    final template = yamlData[templateKey] as YamlMap?;

    if (template == null) {
      return UnifiedImportResult.error(
          'Template section not found in YAML file');
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
    final placeholders = <CoverLetterPlaceholder>[];
    if (yamlData['placeholders'] != null) {
      final phList = yamlData['placeholders'] as YamlList;
      for (final ph in phList) {
        placeholders.add(CoverLetterPlaceholder(
          name: ph['name'] as String? ?? '',
          description: ph['description'] as String? ?? '',
          location: ph['location'] as String? ?? '',
          example: ph['example'] as String? ?? '',
        ));
      }
    }

    // Extract template name from file path
    final fileName = filePath.split('/').last.split('\\').last;
    final templateName = _formatTemplateName(fileName);

    return UnifiedImportResult.coverLetter(
      filePath: filePath,
      templateName: templateName,
      language: detectedLanguage,
      version: version,
      greeting: greeting,
      paragraphs: paragraphs,
      closing: closing,
      signature: signature,
      placeholders: placeholders,
    );
  }

  /// Format file name into a readable template name
  String _formatTemplateName(String fileName) {
    final name = fileName
        .replaceAll('.yaml', '')
        .replaceAll('.yml', '')
        .replaceAll('_', ' ');
    return name.split(' ').map((word) {
      if (word.isEmpty) return word;
      return word[0].toUpperCase() + word.substring(1);
    }).join(' ');
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

/// Types of YAML files the system can import
enum YamlFileType {
  cvData,
  coverLetter,
  unknown,
}

/// Unified import result that handles both CV and Cover Letter data
class UnifiedImportResult {
  final bool success;
  final String? error;
  final YamlFileType fileType;
  final String? filePath;

  // CV Data fields
  final PersonalInfo? personalInfo;
  final List<Skill> skills;
  final List<Language> languages;
  final List<Interest> interests;
  final List<WorkExperience> workExperiences;

  // Cover Letter fields
  final String? templateName;
  final String? language;
  final String? version;
  final String? greeting;
  final List<String> paragraphs;
  final String? closing;
  final String? signature;
  final List<CoverLetterPlaceholder> placeholders;

  UnifiedImportResult._({
    required this.success,
    this.error,
    required this.fileType,
    this.filePath,
    this.personalInfo,
    this.skills = const [],
    this.languages = const [],
    this.interests = const [],
    this.workExperiences = const [],
    this.templateName,
    this.language,
    this.version,
    this.greeting,
    this.paragraphs = const [],
    this.closing,
    this.signature,
    this.placeholders = const [],
  });

  /// Create a successful CV import result
  factory UnifiedImportResult.cv({
    required String filePath,
    String? language,
    PersonalInfo? personalInfo,
    List<Skill> skills = const [],
    List<Language> languages = const [],
    List<Interest> interests = const [],
    List<WorkExperience> workExperiences = const [],
  }) {
    return UnifiedImportResult._(
      success: true,
      fileType: YamlFileType.cvData,
      filePath: filePath,
      language: language,
      personalInfo: personalInfo,
      skills: skills,
      languages: languages,
      interests: interests,
      workExperiences: workExperiences,
    );
  }

  /// Create a successful cover letter import result
  factory UnifiedImportResult.coverLetter({
    required String filePath,
    required String templateName,
    String? language,
    String? version,
    String? greeting,
    List<String> paragraphs = const [],
    String? closing,
    String? signature,
    List<CoverLetterPlaceholder> placeholders = const [],
  }) {
    return UnifiedImportResult._(
      success: true,
      fileType: YamlFileType.coverLetter,
      filePath: filePath,
      templateName: templateName,
      language: language,
      version: version,
      greeting: greeting,
      paragraphs: paragraphs,
      closing: closing,
      signature: signature,
      placeholders: placeholders,
    );
  }

  /// Create an error result
  factory UnifiedImportResult.error(String message) {
    return UnifiedImportResult._(
      success: false,
      error: message,
      fileType: YamlFileType.unknown,
    );
  }

  /// Check if this is CV data
  bool get isCvData => fileType == YamlFileType.cvData;

  /// Check if this is a cover letter
  bool get isCoverLetter => fileType == YamlFileType.coverLetter;

  /// Get the file type as a display string
  String get fileTypeDisplay {
    switch (fileType) {
      case YamlFileType.cvData:
        return 'CV / Resume Data';
      case YamlFileType.coverLetter:
        return 'Cover Letter Template';
      case YamlFileType.unknown:
        return 'Unknown';
    }
  }

  /// Get summary of what will be imported
  List<ImportSummaryItem> get importSummary {
    final items = <ImportSummaryItem>[];

    if (isCvData) {
      if (personalInfo != null) {
        items.add(ImportSummaryItem(
          icon: 'person',
          label: 'Personal Info',
          detail: personalInfo!.fullName,
        ));
      }
      if (skills.isNotEmpty) {
        items.add(ImportSummaryItem(
          icon: 'build',
          label: 'Skills',
          detail: '${skills.length} skill${skills.length == 1 ? '' : 's'}',
        ));
      }
      if (languages.isNotEmpty) {
        items.add(ImportSummaryItem(
          icon: 'language',
          label: 'Languages',
          detail:
              '${languages.length} language${languages.length == 1 ? '' : 's'}',
        ));
      }
      if (interests.isNotEmpty) {
        items.add(ImportSummaryItem(
          icon: 'interests',
          label: 'Interests',
          detail:
              '${interests.length} interest${interests.length == 1 ? '' : 's'}',
        ));
      }
      if (workExperiences.isNotEmpty) {
        items.add(ImportSummaryItem(
          icon: 'work',
          label: 'Work Experience',
          detail:
              '${workExperiences.length} position${workExperiences.length == 1 ? '' : 's'}',
        ));
      }
    } else if (isCoverLetter) {
      items.add(ImportSummaryItem(
        icon: 'mail',
        label: 'Cover Letter',
        detail: templateName ?? 'Template',
      ));
      if (placeholders.isNotEmpty) {
        items.add(ImportSummaryItem(
          icon: 'edit',
          label: 'Placeholders',
          detail: '${placeholders.length} to fill',
        ));
      }
    }

    return items;
  }
}

/// Summary item for display in the import preview
class ImportSummaryItem {
  final String icon;
  final String label;
  final String detail;

  ImportSummaryItem({
    required this.icon,
    required this.label,
    required this.detail,
  });
}

/// Cover letter placeholder info
class CoverLetterPlaceholder {
  final String name;
  final String description;
  final String location;
  final String example;

  CoverLetterPlaceholder({
    required this.name,
    required this.description,
    required this.location,
    required this.example,
  });
}
