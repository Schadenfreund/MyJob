import '../../models/template_customization.dart';

/// CV Section translations for multilingual support
class CvTranslations {
  const CvTranslations._();

  /// Get translated section header
  static String getSectionHeader(String english, CvLanguage language) {
    if (language == CvLanguage.german) {
      return _germanTranslations[english] ?? english;
    }
    return english;
  }

  /// German translations for section headers
  static const Map<String, String> _germanTranslations = {
    // Uppercase sections (for headers)
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
  };

  /// Translate date string (e.g., "Jan 2020 - Present" or "2020 - 2023")
  static String translateDate(String dateString, CvLanguage language) {
    if (language != CvLanguage.german) return dateString;

    String translated = dateString;

    // Translate "Present" (case-insensitive)
    translated = translated.replaceAll('Present', 'Heute');
    translated = translated.replaceAll('present', 'Heute');
    translated = translated.replaceAll('PRESENT', 'HEUTE');

    // Translate month abbreviations and full names
    final monthTranslations = {
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
    };

    // Convert American date format (Month DD, YYYY) to German format (DD. Month YYYY)
    // Regex to match: "Month DD, YYYY" where Month is a full month name
    final fullDatePattern = RegExp(
        r'(January|February|March|April|May|June|July|August|September|October|November|December)\s+(\d{1,2}),\s+(\d{4})');

    translated = translated.replaceAllMapped(fullDatePattern, (match) {
      final month = match.group(1)!;
      final day = match.group(2)!;
      final year = match.group(3)!;
      final germanMonth = monthTranslations[month] ?? month;
      return '$day. $germanMonth $year';
    });

    // Replace remaining month names (for abbreviated formats like "Jan 2020")
    // Do this after the full date conversion to avoid conflicts
    final sortedKeys = monthTranslations.keys.toList()
      ..sort((a, b) => b.length.compareTo(a.length));

    for (final eng in sortedKeys) {
      final ger = monthTranslations[eng]!;
      // Only replace if not already converted in full date format
      if (!translated.contains('$ger ')) {
        translated = translated.replaceAll(eng, ger);
      }
    }

    return translated;
  }

  /// Translate cover letter greeting (e.g., "Dear" -> "Sehr geehrte/r")
  static String translateGreeting(String greeting, CvLanguage language) {
    if (language != CvLanguage.german) return greeting;

    final greetingTranslations = {
      'Dear': 'Sehr geehrte/r',
      'dear': 'Sehr geehrte/r',
      'Dear Hiring Manager': 'Sehr geehrte Damen und Herren',
      'To Whom It May Concern': 'Sehr geehrte Damen und Herren',
    };

    for (final entry in greetingTranslations.entries) {
      if (greeting.contains(entry.key)) {
        return greeting.replaceAll(entry.key, entry.value);
      }
    }

    return greeting;
  }

  /// Translate cover letter closing (e.g., "Sincerely" -> "Mit freundlichen Grüßen")
  static String translateClosing(String closing, CvLanguage language) {
    if (language != CvLanguage.german) return closing;

    final closingTranslations = {
      'Sincerely': 'Mit freundlichen Grüßen',
      'Best regards': 'Beste Grüße',
      'Kind regards': 'Freundliche Grüße',
      'Yours sincerely': 'Hochachtungsvoll',
      'Respectfully': 'Hochachtungsvoll',
    };

    for (final entry in closingTranslations.entries) {
      if (closing.toLowerCase().contains(entry.key.toLowerCase())) {
        return closing
            .replaceAll(entry.key, entry.value)
            .replaceAll(entry.key.toLowerCase(), entry.value);
      }
    }

    return closing;
  }
}
