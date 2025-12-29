import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/widgets.dart' as pw;
import '../models/pdf_font_family.dart';

/// Simple PDF font service - loads bundled fonts from assets
class PdfFontService {
  PdfFontService._();

  static final Map<String, pw.Font> _cache = {};
  static Set<PdfFontFamily>? _availableFonts;

  /// Get list of available font families (fonts that are actually bundled)
  static Future<List<PdfFontFamily>> getAvailableFontFamilies() async {
    if (_availableFonts != null) {
      return _availableFonts!.toList();
    }

    final available = <PdfFontFamily>{};

    // Check each font family to see if it's bundled
    for (final family in PdfFontFamily.values) {
      // Try to load regular weight - if it exists, font family is available
      final possiblePaths = _getAllPossiblePaths(family, _Weight.regular);

      for (final path in possiblePaths) {
        try {
          await rootBundle.load(path);
          available.add(family);
          break; // Found it, move to next family
        } catch (_) {
          // Try next path
        }
      }
    }

    _availableFonts = available;
    return available.toList();
  }

  static Future<PdfFonts> getFonts(
      [PdfFontFamily family = PdfFontFamily.roboto]) async {
    final regular = await _load(family, _Weight.regular);
    final bold = await _load(family, _Weight.bold);
    final italic = await _load(family, _Weight.italic);

    // Try to load BoldItalic, but fall back to Bold if not available
    pw.Font boldItalic;
    try {
      boldItalic = await _load(family, _Weight.boldItalic);
    } catch (_) {
      boldItalic = bold; // Fallback to bold if BoldItalic doesn't exist
    }

    return PdfFonts(
      regular: regular,
      bold: bold,
      medium: bold,
      italic: italic,
      boldItalic: boldItalic,
    );
  }

  static Future<pw.Font> _load(PdfFontFamily family, _Weight weight) async {
    final key = '${family.name}_${weight.name}';

    if (_cache.containsKey(key)) {
      return _cache[key]!;
    }

    // Try multiple possible paths/names for the font
    final possiblePaths = _getAllPossiblePaths(family, weight);

    for (final path in possiblePaths) {
      try {
        final bytes = await rootBundle.load(path);
        final font = pw.Font.ttf(bytes);
        _cache[key] = font;
        return font;
      } catch (_) {
        // Try next path
      }
    }

    // If no font found, throw descriptive error
    throw Exception(
        'Could not load font: $family $weight. Tried: $possiblePaths');
  }

  /// Get all possible paths where this font might be located
  static List<String> _getAllPossiblePaths(
      PdfFontFamily family, _Weight weight) {
    final paths = <String>[];

    // Different possible family names
    final familyNames = _getFamilyNames(family);

    // Different possible weight names
    final weightNames = _getWeightNames(weight);

    // Try all combinations
    for (final familyName in familyNames) {
      for (final weightName in weightNames) {
        // Direct in assets/fonts/
        paths.add('assets/fonts/$familyName-$weightName.ttf');

        // In subdirectory (e.g., assets/fonts/Roboto/)
        paths.add('assets/fonts/$familyName/$familyName-$weightName.ttf');

        // With underscore (e.g., Open_Sans)
        final familyUnderscore = familyName.replaceAll(' ', '_');
        paths.add('assets/fonts/$familyUnderscore/$familyName-$weightName.ttf');
        paths.add(
            'assets/fonts/$familyUnderscore/$familyUnderscore-$weightName.ttf');
      }
    }

    return paths;
  }

  static List<String> _getFamilyNames(PdfFontFamily family) {
    switch (family) {
      case PdfFontFamily.roboto:
        return ['Roboto'];
      case PdfFontFamily.openSans:
        return ['OpenSans', 'Open Sans', 'Open_Sans'];
      case PdfFontFamily.notoSans:
        return ['NotoSans', 'Noto Sans', 'Noto_Sans'];
      case PdfFontFamily.lora:
        return ['Lora'];
    }
  }

  static List<String> _getWeightNames(_Weight weight) {
    switch (weight) {
      case _Weight.regular:
        return ['Regular', 'regular'];
      case _Weight.bold:
        return ['Bold', 'bold', 'SemiBold', 'Semibold'];
      case _Weight.italic:
        return ['Italic', 'italic'];
      case _Weight.boldItalic:
        return ['BoldItalic', 'Bolditalic', 'Bold-Italic', 'SemiBoldItalic'];
    }
  }

  static void clearCache() {
    _cache.clear();
    _availableFonts = null;
  }
}

enum _Weight { regular, bold, italic, boldItalic }

class PdfFonts {
  final pw.Font regular;
  final pw.Font bold;
  final pw.Font medium;
  final pw.Font italic;
  final pw.Font boldItalic;

  const PdfFonts({
    required this.regular,
    required this.bold,
    required this.medium,
    required this.italic,
    required this.boldItalic,
  });

  List<pw.Font> get fallbackList => [regular, bold, medium, italic, boldItalic];
}
