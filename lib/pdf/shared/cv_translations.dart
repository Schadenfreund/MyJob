/// CV Section translations for multilingual PDF support.
///
/// Uses language codes ('en', 'de', 'hr', etc.) matching [AppLocalizations].
/// Any code without a translation entry falls back to English — correct
/// degradation for custom languages that have not yet provided PDF translations.
///
/// To add a new language, add an entry to each of the static const maps below.
class CvTranslations {
  const CvTranslations._();

  // ============================================================================
  // SECTION HEADERS
  // ============================================================================

  /// Get translated section header.
  static String getSectionHeader(String english, String languageCode) {
    return _sectionTranslations[languageCode]?[english] ?? english;
  }

  static const Map<String, Map<String, String>> _sectionTranslations = {
    'de': {
      // Uppercase (for styled headers)
      'PROFILE': 'PROFIL',
      'EXPERIENCE': 'BERUFSERFAHRUNG',
      'EDUCATION': 'AUSBILDUNG',
      'SKILLS': 'FÄHIGKEITEN',
      'LANGUAGES': 'SPRACHEN',
      'INTERESTS': 'INTERESSEN',
      'CONTACT': 'KONTAKT',
      // Title case (for regular use)
      'Profile': 'Profil',
      'Experience': 'Berufserfahrung',
      'Education': 'Bildung',
      'Skills': 'Fähigkeiten',
      'Languages': 'Sprachen',
      'Interests': 'Interessen',
      'Contact': 'Kontakt',
    },
    'hr': {
      // Uppercase (for styled headers)
      'PROFILE': 'PROFIL',
      'EXPERIENCE': 'ISKUSTVO',
      'EDUCATION': 'OBRAZOVANJE',
      'SKILLS': 'VJEŠTINE',
      'LANGUAGES': 'JEZICI',
      'INTERESTS': 'INTERESI',
      'CONTACT': 'KONTAKT',
      // Title case (for regular use)
      'Profile': 'Profil',
      'Experience': 'Iskustvo',
      'Education': 'Obrazovanje',
      'Skills': 'Vještine',
      'Languages': 'Jezici',
      'Interests': 'Interesi',
      'Contact': 'Kontakt',
    },
  };

  // ============================================================================
  // DATE TRANSLATION
  // ============================================================================

  /// Translate date string (e.g., "Jan 2020 - Present" or "2020 - 2023").
  static String translateDate(String dateString, String languageCode) {
    final months = _monthTranslations[languageCode];
    if (months == null) return dateString;

    String translated = dateString;

    // Translate "Present"
    final presentWord = _presentTranslations[languageCode];
    if (presentWord != null) {
      translated = translated.replaceAll('Present', presentWord);
      translated = translated.replaceAll('present', presentWord);
      translated = translated.replaceAll('PRESENT', presentWord.toUpperCase());
    }

    // Convert American date format (Month DD, YYYY) to European (DD. Month YYYY).
    // Must run before the abbreviation loop to use full month names correctly.
    final fullDatePattern = RegExp(
        r'(January|February|March|April|May|June|July|August|September|October|November|December)\s+(\d{1,2}),\s+(\d{4})');

    translated = translated.replaceAllMapped(fullDatePattern, (match) {
      final month = match.group(1)!;
      final day = match.group(2)!;
      final year = match.group(3)!;
      final localMonth = months[month] ?? month;
      return '$day. $localMonth $year';
    });

    // Replace remaining month names / abbreviations (e.g. "Jan 2020").
    // Sort longest-first to avoid partial matches (e.g. "Mar" inside "March").
    final sortedKeys = months.keys.toList()
      ..sort((a, b) => b.length.compareTo(a.length));

    for (final eng in sortedKeys) {
      final loc = months[eng]!;
      // Skip if the translated form is already present (avoids double-replacement)
      if (!translated.contains('$loc ')) {
        translated = translated.replaceAll(eng, loc);
      }
    }

    return translated;
  }

  static const Map<String, String> _presentTranslations = {
    'de': 'Heute',
    'hr': 'Trenutno',
  };

  static const Map<String, Map<String, String>> _monthTranslations = {
    'de': {
      // Abbreviations
      'Jan': 'Jan',
      'Feb': 'Feb',
      'Mar': 'Mär',
      'Apr': 'Apr',
      'May': 'Mai',
      'Jun': 'Jun',
      'Jul': 'Jul',
      'Aug': 'Aug',
      'Sep': 'Sep',
      'Oct': 'Okt',
      'Nov': 'Nov',
      'Dec': 'Dez',
      // Full names
      'January': 'Januar',
      'February': 'Februar',
      'March': 'März',
      'April': 'April',
      'June': 'Juni',
      'July': 'Juli',
      'August': 'August',
      'September': 'September',
      'October': 'Oktober',
      'November': 'November',
      'December': 'Dezember',
    },
    'hr': {
      // Abbreviations
      'Jan': 'Sij',
      'Feb': 'Velj',
      'Mar': 'Ožu',
      'Apr': 'Tra',
      'May': 'Svi',
      'Jun': 'Lip',
      'Jul': 'Srp',
      'Aug': 'Kol',
      'Sep': 'Ruj',
      'Oct': 'Lis',
      'Nov': 'Stu',
      'Dec': 'Pro',
      // Full names
      'January': 'Siječanj',
      'February': 'Veljača',
      'March': 'Ožujak',
      'April': 'Travanj',
      'June': 'Lipanj',
      'July': 'Srpanj',
      'August': 'Kolovoz',
      'September': 'Rujan',
      'October': 'Listopad',
      'November': 'Studeni',
      'December': 'Prosinac',
    },
  };

  // ============================================================================
  // COVER LETTER GREETING
  // ============================================================================

  /// Translate cover letter greeting (e.g., "Dear" → "Sehr geehrte/r").
  static String translateGreeting(String greeting, String languageCode) {
    final translations = _greetingTranslations[languageCode];
    if (translations == null) return greeting;

    for (final entry in translations.entries) {
      if (greeting.contains(entry.key)) {
        return greeting.replaceAll(entry.key, entry.value);
      }
    }
    return greeting;
  }

  static const Map<String, Map<String, String>> _greetingTranslations = {
    'de': {
      'Dear Hiring Manager': 'Sehr geehrte Damen und Herren',
      'To Whom It May Concern': 'Sehr geehrte Damen und Herren',
      'Dear': 'Sehr geehrte/r',
      'dear': 'Sehr geehrte/r',
    },
    'hr': {
      'Dear Hiring Manager': 'Poštovana gospođo/gospodo',
      'To Whom It May Concern': 'Poštovana gospođo/gospodo',
      'Dear': 'Poštovani/a',
      'dear': 'Poštovani/a',
    },
  };

  // ============================================================================
  // COVER LETTER CLOSING
  // ============================================================================

  /// Translate cover letter closing (e.g., "Sincerely" → "Mit freundlichen Grüßen").
  static String translateClosing(String closing, String languageCode) {
    final translations = _closingTranslations[languageCode];
    if (translations == null) return closing;

    for (final entry in translations.entries) {
      if (closing.toLowerCase().contains(entry.key.toLowerCase())) {
        return closing
            .replaceAll(entry.key, entry.value)
            .replaceAll(entry.key.toLowerCase(), entry.value);
      }
    }
    return closing;
  }

  static const Map<String, Map<String, String>> _closingTranslations = {
    'de': {
      'Sincerely': 'Mit freundlichen Grüßen',
      'Best regards': 'Beste Grüße',
      'Kind regards': 'Freundliche Grüße',
      'Yours sincerely': 'Hochachtungsvoll',
      'Respectfully': 'Hochachtungsvoll',
    },
    'hr': {
      'Sincerely': 'S poštovanjem',
      'Best regards': 'S lijepim pozdravima',
      'Kind regards': 'Srdačni pozdravi',
      'Yours sincerely': 'S poštovanjem',
      'Respectfully': 'S poštovanjem',
    },
  };

  // ============================================================================
  // LANGUAGE PROFICIENCY LEVEL
  // ============================================================================

  /// Translate language proficiency level (e.g., "Native" → "Muttersprache").
  static String translateLanguageLevel(String level, String languageCode) {
    return _levelTranslations[languageCode]?[level] ?? level;
  }

  static const Map<String, Map<String, String>> _levelTranslations = {
    'de': {
      'Native': 'Muttersprache',
      'native': 'Muttersprache',
      'NATIVE': 'MUTTERSPRACHE',
      'Fluent': 'Fließend',
      'fluent': 'Fließend',
      'FLUENT': 'FLIESSEND',
      'Advanced': 'Sehr gut',
      'advanced': 'Sehr gut',
      'ADVANCED': 'SEHR GUT',
      'Intermediate': 'Fortgeschritten',
      'intermediate': 'Fortgeschritten',
      'INTERMEDIATE': 'FORTGESCHRITTEN',
      'Beginner': 'Anfänger',
      'beginner': 'Anfänger',
      'BEGINNER': 'ANFÄNGER',
      'Basic': 'Grundkenntnisse',
      'basic': 'Grundkenntnisse',
      'BASIC': 'GRUNDKENNTNISSE',
      // CEFR levels
      'C2': 'C2 (Muttersprachlich)',
      'C1': 'C1 (Sehr gut)',
      'B2': 'B2 (Fortgeschritten)',
      'B1': 'B1 (Mittelstufe)',
      'A2': 'A2 (Grundkenntnisse)',
      'A1': 'A1 (Anfänger)',
    },
    'hr': {
      'Native': 'Materinski',
      'native': 'Materinski',
      'NATIVE': 'MATERINSKI',
      'Fluent': 'Tečno',
      'fluent': 'Tečno',
      'FLUENT': 'TEČNO',
      'Advanced': 'Napredan',
      'advanced': 'Napredan',
      'ADVANCED': 'NAPREDAN',
      'Intermediate': 'Srednji',
      'intermediate': 'Srednji',
      'INTERMEDIATE': 'SREDNJI',
      'Beginner': 'Početnik',
      'beginner': 'Početnik',
      'BEGINNER': 'POČETNIK',
      'Basic': 'Osnovno',
      'basic': 'Osnovno',
      'BASIC': 'OSNOVNO',
      // CEFR levels
      'C2': 'C2 (Materinski)',
      'C1': 'C1 (Napredan)',
      'B2': 'B2 (Viši srednji)',
      'B1': 'B1 (Srednji)',
      'A2': 'A2 (Osnovno)',
      'A1': 'A1 (Početnik)',
    },
  };

  // ============================================================================
  // COMMON LABELS
  // ============================================================================

  /// Translate common labels (e.g., "at" → "bei", "Languages:" → "Sprachen:").
  static String translateLabel(String label, String languageCode) {
    return _labelTranslations[languageCode]?[label] ?? label;
  }

  static const Map<String, Map<String, String>> _labelTranslations = {
    'de': {
      // Prepositions
      ' at ': ' bei ',
      'at ': 'bei ',
      ' at': ' bei',
      // Labels with colons
      'Languages:': 'Sprachen:',
      'languages:': 'Sprachen:',
      'LANGUAGES:': 'SPRACHEN:',
      'Interests:': 'Interessen:',
      'interests:': 'Interessen:',
      'INTERESTS:': 'INTERESSEN:',
      'Skills:': 'Fähigkeiten:',
      'skills:': 'Fähigkeiten:',
      'SKILLS:': 'FÄHIGKEITEN:',
      // Standalone labels
      'Languages': 'Sprachen',
      'Interests': 'Interessen',
      'Skills': 'Fähigkeiten',
    },
    'hr': {
      // Prepositions
      ' at ': ' u ',
      'at ': 'u ',
      ' at': ' u',
      // Labels with colons
      'Languages:': 'Jezici:',
      'languages:': 'Jezici:',
      'LANGUAGES:': 'JEZICI:',
      'Interests:': 'Interesi:',
      'interests:': 'Interesi:',
      'INTERESTS:': 'INTERESI:',
      'Skills:': 'Vještine:',
      'skills:': 'Vještine:',
      'SKILLS:': 'VJEŠTINE:',
      // Standalone labels
      'Languages': 'Jezici',
      'Interests': 'Interesi',
      'Skills': 'Vještine',
    },
  };
}
