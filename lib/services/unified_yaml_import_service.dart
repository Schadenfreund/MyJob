import 'dart:io';
import 'package:uuid/uuid.dart';
import 'package:yaml/yaml.dart';
import '../models/user_data/personal_info.dart';
import '../models/user_data/skill.dart';
import '../models/user_data/work_experience.dart';
import '../models/user_data/language.dart';
import '../models/user_data/interest.dart';
import '../models/master_profile.dart';

/// Unified YAML import service with auto-detection and smart routing
///
/// This service consolidates all YAML import functionality into a single
/// entry point that auto-detects file type and provides consistent parsing.
class UnifiedYamlImportService {
  /// Parse a YAML file from disk.
  Future<UnifiedImportResult> importYamlFile(File file) async {
    try {
      final content = await file.readAsString();
      return importYamlString(content, filePath: file.path);
    } catch (e) {
      return UnifiedImportResult.error('Failed to read file: $e');
    }
  }

  /// Parse a YAML string directly.
  ///
  /// Used by the in-dialog editor so the user can fix and re-parse without
  /// writing back to disk.  [filePath] is used only for language detection
  /// and template name formatting — it does not need to point to a real file.
  Future<UnifiedImportResult> importYamlString(
    String content, {
    required String filePath,
  }) async {
    try {
      final parsed = loadYaml(_normalizeRaw(content));
      if (parsed is! YamlMap) {
        return UnifiedImportResult.error(
          parsed == null
              ? 'The file appears to be empty.'
              : 'Expected a YAML mapping at the root level.',
        );
      }

      switch (_detectFileType(parsed)) {
        case YamlFileType.cvData:
          return _parseCvData(parsed, filePath);
        case YamlFileType.coverLetter:
          return _parseCoverLetter(parsed, filePath);
        case YamlFileType.unknown:
          return UnifiedImportResult.error(
            'Unable to determine file type. Expected CV data or Cover Letter template.',
          );
      }
    } catch (e) {
      return UnifiedImportResult.error(_cleanParseError(e));
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
    final detectedLanguage = _detectLanguage(yamlData, filePath);

    PersonalInfo? personalInfo;
    String profileSummary = '';
    List<Skill> skills = [];
    List<Language> languages = [];
    List<Interest> interests = [];
    List<WorkExperience> workExperiences = [];
    List<Education> education = [];

    // Parse personal info
    final piData = _asMap(yamlData['personal_info']);
    if (piData != null) {
      personalInfo = PersonalInfo(
        fullName: _str(piData['full_name']),
        jobTitle: _strOrNull(piData['job_title']),
        email: _strOrNull(piData['email']),
        phone: _strOrNull(piData['phone']),
        address: _strOrNull(piData['address']),
        city: _strOrNull(piData['city']),
        country: _strOrNull(piData['country']),
        linkedin: _strOrNull(piData['linkedin']),
        website: _strOrNull(piData['website']),
      );
      profileSummary = _str(piData['profile_summary']);
    }

    // Parse skills — malformed entries are skipped
    for (final skillData in _asList(yamlData['skills']) ?? []) {
      try {
        skills.add(Skill(
          name: _str(skillData['name']),
          category: _strOrNull(skillData['category']),
          level: _parseSkillLevel(_strOrNull(skillData['level'])),
        ));
      } catch (_) {}
    }

    // Parse languages — malformed entries are skipped
    for (final langData in _asList(yamlData['languages']) ?? []) {
      try {
        languages.add(Language(
          name: _str(langData['name']),
          proficiency: _parseLanguageProficiency(_strOrNull(langData['proficiency'])),
        ));
      } catch (_) {}
    }

    // Parse interests — malformed entries are skipped
    for (final interestData in _asList(yamlData['interests']) ?? []) {
      try {
        interests.add(Interest(
          name: _str(interestData['name']),
          category: _strOrNull(interestData['category']),
          level: _parseInterestLevel(_strOrNull(interestData['level'])),
        ));
      } catch (_) {}
    }

    // Parse work experience — malformed entries are skipped
    for (final expData in _asList(yamlData['work_experience']) ?? []) {
      try {
        final responsibilities = [
          ...?_asList(expData['responsibilities'])?.map((e) => e.toString()),
        ];
        workExperiences.add(WorkExperience(
          company: _str(expData['company']),
          position: _str(expData['position']),
          startDate: _parseDate(expData['start_date']),
          endDate: expData['end_date'] != null ? _parseDate(expData['end_date']) : null,
          isCurrent: expData['is_current'] is bool ? expData['is_current'] as bool : false,
          location: _strOrNull(expData['location']),
          description: _strOrNull(expData['description']),
          responsibilities: responsibilities,
        ));
      } catch (_) {}
    }

    // Parse education — supports camelCase (DEMO_DATA) and snake_case (exported); malformed entries skipped
    for (final eduData in _asList(yamlData['education']) ?? []) {
      try {
        final startRaw = eduData['startDate'] ?? eduData['start_date'];
        final endRaw = eduData['endDate'] ?? eduData['end_date'];
        final isCurrent = eduData['isCurrent'] ?? eduData['is_current'];
        education.add(Education(
          id: _strOrNull(eduData['id']) ?? const Uuid().v4(),
          institution: _str(eduData['institution']),
          degree: _str(eduData['degree']),
          fieldOfStudy: _str(eduData['fieldOfStudy'] ?? eduData['field_of_study']),
          startDate: _parseDate(startRaw),
          endDate: endRaw != null ? _parseDate(endRaw) : null,
          isCurrent: isCurrent is bool ? isCurrent : false,
          description: _strOrNull(eduData['description']),
          grade: _strOrNull(eduData['grade']),
        ));
      } catch (_) {}
    }

    return UnifiedImportResult.cv(
      filePath: filePath,
      language: detectedLanguage,
      personalInfo: personalInfo,
      profileSummary: profileSummary,
      defaultCoverLetterBody: _str(yamlData['default_cover_letter']),
      skills: skills,
      languages: languages,
      interests: interests,
      workExperiences: workExperiences,
      education: education,
    );
  }

  /// Parse cover letter template from YAML
  UnifiedImportResult _parseCoverLetter(YamlMap yamlData, String filePath) {
    final detectedLanguage = _detectLanguage(yamlData, filePath);

    final version = _str(yamlData['version'], 'current');

    // Determine which template to use
    final templateKey =
        version == 'past_tense' ? 'template_past_tense' : 'template';
    final template = _asMap(yamlData[templateKey]);

    if (template == null) {
      return UnifiedImportResult.error(
          'Template section not found in YAML file');
    }

    final greeting = _str(template['greeting']);
    final paragraphs = [
      ...?_asList(template['paragraphs'])?.map((e) => e.toString()),
    ];
    final closing = _str(template['closing']);
    final signature = _str(template['signature']);

    // Parse placeholders — malformed entries are skipped
    final placeholders = <CoverLetterPlaceholder>[];
    for (final ph in _asList(yamlData['placeholders']) ?? []) {
      try {
        placeholders.add(CoverLetterPlaceholder(
          name: _str(ph['name']),
          description: _str(ph['description']),
          location: _str(ph['location']),
          example: _str(ph['example']),
        ));
      } catch (_) {}
    }

    // Extract template name from file path (handles both / and \ separators)
    final fileName = File(filePath).uri.pathSegments.last;
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

  /// Detect language from the YAML `language` key or the file path.
  /// Returns a lowercase language code hint ('english', 'german', …).
  String _detectLanguage(YamlMap data, String filePath) {
    final explicit = data['language'] as String?;
    if (explicit != null) {
      return explicit.toLowerCase();
    }

    final lower = filePath.toLowerCase();
    if (lower.contains('german') ||
        lower.contains('deutsch') ||
        lower.contains('_de')) return 'german';
    if (lower.contains('english') || lower.contains('_en')) return 'english';

    return 'english'; // safe default
  }

  /// Parse a date from either a String or a DateTime (YAML 1.1 auto-parses
  /// unquoted YYYY-MM-DD scalars as DateTime, so we must handle both).
  DateTime _parseDate(dynamic value) {
    if (value is DateTime) return value;
    if (value is String) return DateTime.parse(value);
    throw ArgumentError('Cannot parse date from: $value (${value.runtimeType})');
  }

  /// Parse interest level from string
  InterestLevel? _parseInterestLevel(String? level) {
    if (level == null) return null;
    switch (level.toLowerCase()) {
      case 'casual':
        return InterestLevel.casual;
      case 'moderate':
        return InterestLevel.moderate;
      case 'passionate':
        return InterestLevel.passionate;
      default:
        return null;
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

  // ---------------------------------------------------------------------------
  // Pre-parse normalisation
  // ---------------------------------------------------------------------------

  /// Applies heuristic fixes to common user-editing mistakes and returns the
  /// repaired string without parsing it.  Safe to call on already-valid YAML.
  ///
  /// Fixes applied:
  ///   • CRLF / bare-CR line endings → LF
  ///   • UTF-8 BOM and tab indentation
  ///   • Sequence items (`- `) and their content that are under-indented
  ///     relative to their parent key (via [_fixListItemIndentation])
  ///   • Block-scalar content that lost its indentation (via [_sanitizeBlockScalars])
  static String autoFixYaml(String content) {
    var s = content.replaceAll('\r\n', '\n').replaceAll('\r', '\n');
    // Strip UTF-8 BOM
    if (s.startsWith('﻿')) s = s.substring(1);
    // Replace tab indentation
    s = s.replaceAllMapped(
      RegExp(r'^\t+', multiLine: true),
      (m) => '  ' * m[0]!.length,
    );
    // Fix list-item indentation first so block-scalar markers are at the
    // right level before the sanitizer runs.
    s = _fixListItemIndentation(s);
    // Then re-indent any de-indented block-scalar content.
    s = _sanitizeBlockScalars(s);
    return s;
  }

  static final _keyOnlyRe = RegExp(r'^\s*[\w][\w\s-]*:\s*$');

  /// Fixes sequence items (`- `) that are under-indented relative to their
  /// parent mapping key, processing each wrong-indent item and its content
  /// block independently.  Items already at the correct indentation are left
  /// untouched, so a mix of correctly- and wrongly-placed items in the same
  /// sequence is handled without over-shifting.
  static String _fixListItemIndentation(String content) {
    final lines = content.split('\n');
    final result = lines.toList();

    for (int i = 0; i < lines.length; i++) {
      if (lines[i].trim().isEmpty) continue;
      if (!_keyOnlyRe.hasMatch(lines[i])) continue;

      final parentIndent = lines[i].length - lines[i].trimLeft().length;
      final expectedItemIndent = parentIndent + 2;

      // Find the first non-empty child.
      int j = i + 1;
      while (j < lines.length && lines[j].trim().isEmpty) {
        j++;
      }
      if (j >= lines.length) continue;

      final firstChildTrimmed = lines[j].trimLeft();
      final firstChildIndent = lines[j].length - firstChildTrimmed.length;

      // Only act when the first child is an under-indented list item.
      if ((!firstChildTrimmed.startsWith('- ') && firstChildTrimmed != '-') ||
          firstChildIndent >= expectedItemIndent) {
        continue;
      }

      final wrongItemIndent = firstChildIndent;
      final shift = expectedItemIndent - wrongItemIndent;
      final padding = ' ' * shift;

      // Walk all lines in this key's scope and fix each item at the wrong
      // indent level, leaving items already at the correct level alone.
      int k = j;
      while (k < lines.length) {
        if (lines[k].trim().isEmpty) {
          k++;
          continue;
        }
        final kTrimmed = lines[k].trimLeft();
        final kIndent = lines[k].length - kTrimmed.length;
        final kIsItem = kTrimmed.startsWith('- ') || kTrimmed == '-';

        // A structural line at ≤ parentIndent that is not a list item ends scope.
        if (kIndent <= parentIndent && !kIsItem && _isYamlStructural(kTrimmed)) break;

        if (kIsItem && kIndent == wrongItemIndent) {
          result[k] = padding + lines[k];

          // Shift this item's content until the next item or scope boundary.
          int m = k + 1;
          while (m < lines.length) {
            if (lines[m].trim().isEmpty) {
              m++;
              continue;
            }
            final mTrimmed = lines[m].trimLeft();
            final mIndent = lines[m].length - mTrimmed.length;
            final mIsItem = mTrimmed.startsWith('- ') || mTrimmed == '-';
            // Next list item (correctly or wrongly indented) → outer loop handles it.
            if (mIsItem && mIndent <= expectedItemIndent) break;
            // Structural scope exit.
            if (!mIsItem && mIndent <= parentIndent && _isYamlStructural(mTrimmed)) break;
            result[m] = padding + lines[m];
            m++;
          }
          k = m;
        } else {
          k++;
        }
      }
    }

    return result.join('\n');
  }

  /// Strips the exception class name from a YAML parser error so only the
  /// location and message remain (e.g. "line 37, column 10: Expected ':'").
  static String _cleanParseError(Object e) {
    final raw = e.toString().trim();
    final cleaned = raw
        .replaceFirst(RegExp(r'^[A-Za-z]+Exception[^:]*:\s*'), '')
        .trim();
    return cleaned.isNotEmpty ? cleaned : raw;
  }

  /// Strips the UTF-8 BOM, converts tab indentation to spaces, then runs the
  /// block-scalar sanitizer.  Applied to every file before `loadYaml`.
  static String _normalizeRaw(String raw) {
    // Strip UTF-8 BOM that some Windows editors prepend.
    var s = raw.startsWith('﻿') ? raw.substring(1) : raw;
    // YAML forbids tab characters for indentation; replace leading tabs.
    s = s.replaceAllMapped(
      RegExp(r'^\t+', multiLine: true),
      (m) => '  ' * m[0]!.length,
    );
    return _sanitizeBlockScalars(s);
  }

  // ---------------------------------------------------------------------------
  // Safe-cast helpers — never throw, never return wrong type
  // ---------------------------------------------------------------------------

  /// Returns [v] as [YamlMap] if it is one, otherwise `null`.
  static YamlMap? _asMap(dynamic v) => v is YamlMap ? v : null;

  /// Returns [v] as [YamlList] if it is one, otherwise `null`.
  static YamlList? _asList(dynamic v) => v is YamlList ? v : null;

  /// Coerces any scalar to [String].  Returns [fallback] when [v] is `null`.
  /// Handles YAML 1.1 values that the parser may give as bool/int/double.
  static String _str(dynamic v, [String fallback = '']) =>
      v == null ? fallback : v.toString();

  /// Like [_str] but returns `null` when [v] is `null` or an empty string.
  static String? _strOrNull(dynamic v) {
    if (v == null) return null;
    final s = v.toString();
    return s.isEmpty ? null : s;
  }

  // ---------------------------------------------------------------------------
  // Block-scalar sanitizer
  // ---------------------------------------------------------------------------

  /// Fixes de-indented continuation lines inside YAML block scalars (`|`).
  ///
  /// When a line inside a block scalar accidentally loses its indentation (e.g.
  /// a paragraph line at column 0 instead of column 6), YAML terminates the
  /// scalar early and then fails to parse the orphaned line as a mapping key.
  /// This pass detects such lines — text that is not YAML structure — and
  /// restores their indentation before the string reaches the YAML parser.
  /// Well-formed files pass through unchanged.
  static String _sanitizeBlockScalars(String yaml) {
    final lines = yaml.split('\n');
    final result = <String>[];
    int? blockContentIndent;

    for (int i = 0; i < lines.length; i++) {
      final line = lines[i];
      final trimmed = line.trimLeft();
      final lineIndent = line.length - trimmed.length;

      if (blockContentIndent != null) {
        if (trimmed.isEmpty) {
          result.add(line);
          continue;
        }
        if (lineIndent >= blockContentIndent) {
          result.add(line);
        } else if (_isYamlStructural(trimmed)) {
          // Real YAML structure ends the block scalar.
          blockContentIndent = null;
          if (_startsBlockScalar(trimmed)) {
            blockContentIndent = _lookAheadContentIndent(lines, i + 1, lineIndent);
          }
          result.add(line);
        } else {
          // Prose that accidentally lost its indentation — restore it.
          result.add(' ' * blockContentIndent + trimmed);
        }
      } else {
        if (_startsBlockScalar(trimmed)) {
          blockContentIndent = _lookAheadContentIndent(lines, i + 1, lineIndent);
        }
        result.add(line);
      }
    }

    return result.join('\n');
  }

  /// Returns true if [trimmed] opens a YAML block literal scalar (`|`).
  static bool _startsBlockScalar(String trimmed) {
    return RegExp(r'(:\s*\|[-+]?\s*$)|(^-\s+\|[-+]?\s*$)|(^\|[-+]?\s*$)')
        .hasMatch(trimmed);
  }

  /// Returns true if [trimmed] looks like YAML structure rather than prose,
  /// meaning it should end an active block scalar rather than be re-indented.
  static bool _isYamlStructural(String trimmed) {
    if (trimmed.startsWith('#')) return true;
    if (trimmed.startsWith('- ') || trimmed == '-') return true;
    if (trimmed == '---' || trimmed == '...') return true;
    if (RegExp(r'^[\w-]+\s*:').hasMatch(trimmed)) return true;
    return false;
  }

  /// Scans forward from [from] to find the content indentation for the block
  /// scalar whose marker is at [parentIndent].
  ///
  /// Content must be more indented than the marker, so lines at ≤ [parentIndent]
  /// are skipped (they are de-indented content that [_sanitizeBlockScalars]
  /// will re-indent).  Falls back to [parentIndent] + 2 when no valid line
  /// is found before a structural boundary.
  static int _lookAheadContentIndent(
      List<String> lines, int from, int parentIndent) {
    final minValid = parentIndent + 1;
    for (int j = from; j < lines.length; j++) {
      final next = lines[j];
      final nextTrimmed = next.trimLeft();
      if (nextTrimmed.isEmpty) continue;
      final indent = next.length - nextTrimmed.length;
      if (indent >= minValid) return indent;
      // A structural line at an invalid indent ends the search.
      if (_isYamlStructural(nextTrimmed)) break;
    }
    return parentIndent + 2;
  }
}

/// Types of YAML files the system can import
enum YamlFileType {
  cvData,
  coverLetter,
  unknown,
}

/// Sealed import result hierarchy — each variant carries only the fields
/// that belong to it, eliminating nullable-field ambiguity.
sealed class UnifiedImportResult {
  const UnifiedImportResult();

  /// Whether the import was successful.
  bool get success;

  /// Convenience type-checks (kept for minimal diff in UI code).
  bool get isCvData => this is CvImportResult;
  bool get isCoverLetter => this is CoverLetterImportResult;

  /// Display name for the detected file type.
  String get fileTypeDisplay;

  /// Summary items for the preview UI.
  List<ImportSummaryItem> get importSummary;

  // ---------------------------------------------------------------------------
  // Factory constructors — backward-compatible call sites
  // ---------------------------------------------------------------------------

  /// Create a successful CV import result.
  factory UnifiedImportResult.cv({
    required String filePath,
    String? language,
    PersonalInfo? personalInfo,
    String profileSummary,
    String defaultCoverLetterBody,
    List<Skill> skills,
    List<Language> languages,
    List<Interest> interests,
    List<WorkExperience> workExperiences,
    List<Education> education,
  }) = CvImportResult;

  /// Create a successful cover letter import result.
  factory UnifiedImportResult.coverLetter({
    required String filePath,
    required String templateName,
    String? language,
    String? version,
    String? greeting,
    List<String> paragraphs,
    String? closing,
    String? signature,
    List<CoverLetterPlaceholder> placeholders,
  }) = CoverLetterImportResult;

  /// Create an error result.
  factory UnifiedImportResult.error(String message) = ImportError;
}

/// Successful CV data import.
class CvImportResult extends UnifiedImportResult {
  const CvImportResult({
    required this.filePath,
    this.language,
    this.personalInfo,
    this.profileSummary = '',
    this.defaultCoverLetterBody = '',
    this.skills = const [],
    this.languages = const [],
    this.interests = const [],
    this.workExperiences = const [],
    this.education = const [],
  });

  final String filePath;
  final String? language;
  final PersonalInfo? personalInfo;
  final String profileSummary;
  final String defaultCoverLetterBody;
  final List<Skill> skills;
  final List<Language> languages;
  final List<Interest> interests;
  final List<WorkExperience> workExperiences;
  final List<Education> education;

  @override
  bool get success => true;

  @override
  String get fileTypeDisplay => 'CV / Resume Data';

  @override
  List<ImportSummaryItem> get importSummary {
    final items = <ImportSummaryItem>[];
    if (personalInfo != null) {
      items.add(ImportSummaryItem(
        icon: 'person',
        label: 'personal_info',
        detail: personalInfo!.fullName,
      ));
    }
    if (skills.isNotEmpty) {
      items.add(ImportSummaryItem(
        icon: 'build',
        label: 'skills',
        detail: '${skills.length} skill${skills.length == 1 ? '' : 's'}',
      ));
    }
    if (languages.isNotEmpty) {
      items.add(ImportSummaryItem(
        icon: 'language',
        label: 'languages_section',
        detail:
            '${languages.length} language${languages.length == 1 ? '' : 's'}',
      ));
    }
    if (interests.isNotEmpty) {
      items.add(ImportSummaryItem(
        icon: 'interests',
        label: 'interests',
        detail:
            '${interests.length} interest${interests.length == 1 ? '' : 's'}',
      ));
    }
    if (workExperiences.isNotEmpty) {
      items.add(ImportSummaryItem(
        icon: 'work',
        label: 'work_experience',
        detail:
            '${workExperiences.length} position${workExperiences.length == 1 ? '' : 's'}',
      ));
    }
    if (education.isNotEmpty) {
      items.add(ImportSummaryItem(
        icon: 'school',
        label: 'education',
        detail:
            '${education.length} ${education.length == 1 ? 'degree' : 'degrees'}',
      ));
    }
    return items;
  }
}

/// Successful cover letter import.
class CoverLetterImportResult extends UnifiedImportResult {
  const CoverLetterImportResult({
    required this.filePath,
    required this.templateName,
    this.language,
    this.version,
    this.greeting,
    this.paragraphs = const [],
    this.closing,
    this.signature,
    this.placeholders = const [],
  });

  final String filePath;
  final String templateName;
  final String? language;
  final String? version;
  final String? greeting;
  final List<String> paragraphs;
  final String? closing;
  final String? signature;
  final List<CoverLetterPlaceholder> placeholders;

  @override
  bool get success => true;

  @override
  String get fileTypeDisplay => 'Cover Letter Template';

  @override
  List<ImportSummaryItem> get importSummary {
    final items = <ImportSummaryItem>[
      ImportSummaryItem(
        icon: 'mail',
        label: 'cover_letter',
        detail: templateName,
      ),
    ];
    if (placeholders.isNotEmpty) {
      items.add(ImportSummaryItem(
        icon: 'edit',
        label: 'import_placeholders',
        detail: '${placeholders.length} to fill',
      ));
    }
    return items;
  }
}

/// Import failure.
class ImportError extends UnifiedImportResult {
  const ImportError(this.error);

  final String error;

  @override
  bool get success => false;

  @override
  String get fileTypeDisplay => 'Unknown';

  @override
  List<ImportSummaryItem> get importSummary => const [];
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

