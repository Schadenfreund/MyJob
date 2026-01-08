import '../constants/app_constants.dart';
import 'package:intl/intl.dart';

/// PDF translation helper for multilingual CV and Cover Letter generation
class PdfTranslations {
  /// Get translation for a given key in the specified language
  static String get(DocumentLanguage language, String key) {
    final translations =
        _translations[language] ?? _translations[DocumentLanguage.en]!;
    return translations[key] ?? _translations[DocumentLanguage.en]![key] ?? key;
  }

  /// Translation map for all supported languages
  static final Map<DocumentLanguage, Map<String, String>> _translations = {
    DocumentLanguage.en: {
      // Section Headers
      'profile_summary': 'Profile Summary',
      'professional_summary': 'Professional Summary',
      'experience': 'Experience',
      'work_experience': 'Work Experience',
      'education': 'Education',
      'skills': 'Skills',
      'core_competencies': 'Core Competencies',
      'languages': 'Languages',
      'interests': 'Interests',
      'contact': 'Contact',
      'personal_info': 'Personal Information',

      // Time periods
      'present': 'Present',
      'since': 'Since',
      'to': 'to',

      // Date formats (for display)
      'month_year': 'MMM yyyy',
      'full_date': 'MMMM d, yyyy',
      'short_date': 'MM/dd/yyyy',

      // Cover Letter
      'dear': 'Dear',
      'sincerely': 'Sincerely',
      'best_regards': 'Best regards',
      'kind_regards': 'Kind regards',

      // Common terms
      'phone': 'Phone',
      'email': 'Email',
      'address': 'Address',
      'location': 'Location',
      'website': 'Website',
      'linkedin': 'LinkedIn',
      'github': 'GitHub',

      // Language proficiency
      'native': 'Native',
      'fluent': 'Fluent',
      'advanced': 'Advanced',
      'intermediate': 'Intermediate',
      'basic': 'Basic',
    },
    DocumentLanguage.de: {
      // Section Headers
      'profile_summary': 'Profil',
      'professional_summary': 'Profil',
      'experience': 'Berufserfahrung',
      'work_experience': 'Berufserfahrung',
      'education': 'Ausbildung',
      'skills': 'Fähigkeiten',
      'core_competencies': 'Kernkompetenzen',
      'languages': 'Sprachen',
      'interests': 'Interessen',
      'contact': 'Kontakt',
      'personal_info': 'Persönliche Informationen',

      // Time periods
      'present': 'Heute',
      'since': 'Seit',
      'to': 'bis',

      // Date formats (for display)
      'month_year': 'MMM yyyy',
      'full_date': 'd. MMMM yyyy',
      'short_date': 'dd.MM.yyyy',

      // Cover Letter
      'dear': 'Sehr geehrte/r',
      'sincerely': 'Mit freundlichen Grüßen',
      'best_regards': 'Beste Grüße',
      'kind_regards': 'Freundliche Grüße',

      // Common terms
      'phone': 'Telefon',
      'email': 'E-Mail',
      'address': 'Adresse',
      'location': 'Standort',
      'website': 'Webseite',
      'linkedin': 'LinkedIn',
      'github': 'GitHub',

      // Language proficiency
      'native': 'Muttersprache',
      'fluent': 'Fließend',
      'advanced': 'Fortgeschritten',
      'intermediate': 'Mittelstufe',
      'basic': 'Grundkenntnisse',
    },
  };

  /// Format date according to language preference
  static String formatDate(DateTime date, DocumentLanguage language,
      {bool shortFormat = false}) {
    final locale = language == DocumentLanguage.de ? 'de_DE' : 'en_US';
    final pattern = shortFormat
        ? (language == DocumentLanguage.de ? 'dd.MM.yyyy' : 'MM/dd/yyyy')
        : (language == DocumentLanguage.de ? 'd. MMMM yyyy' : 'MMMM d, yyyy');

    return DateFormat(pattern, locale).format(date);
  }

  /// Format month/year for experience/education periods
  static String formatMonthYear(DateTime date, DocumentLanguage language) {
    final locale = language == DocumentLanguage.de ? 'de_DE' : 'en_US';
    return DateFormat('MMM yyyy', locale).format(date);
  }

  /// Format date range with proper language
  static String formatDateRange(
    DateTime? startDate,
    DateTime? endDate,
    DocumentLanguage language, {
    bool isCurrent = false,
  }) {
    if (startDate == null) return '';

    final start = formatMonthYear(startDate, language);
    final separator = ' ${get(language, "to")} ';

    if (isCurrent || endDate == null) {
      return '$start $separator ${get(language, "present")}';
    }

    final end = formatMonthYear(endDate, language);
    return '$start$separator$end';
  }

  /// Get language proficiency level translation
  static String getProficiencyLevel(String level, DocumentLanguage language) {
    final key = level.toLowerCase();
    return get(language, key);
  }
}
