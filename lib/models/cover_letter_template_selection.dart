/// Cover letter template types - independent from CV templates
/// but matching their visual designs
enum CoverLetterTemplateType {
  /// Modern - Clean professional with accent bar (matches CV Modern)
  modern('Modern', 'Clean professional layout with accent color top bar'),

  /// Traditional - Conservative, formal (matches CV Traditional)
  traditional('Traditional',
      'Conservative, traditional layout for formal applications'),

  /// Compact - Space-efficient (matches CV Compact)
  compact('Compact', 'Space-efficient layout maximizing content');

  const CoverLetterTemplateType(this.label, this.description);
  final String label;
  final String description;
}

/// Cover letter template selection - independent from CV template selection
class CoverLetterTemplateSelection {
  const CoverLetterTemplateSelection({
    required this.templateType,
  });

  final CoverLetterTemplateType templateType;

  CoverLetterTemplateSelection copyWith({
    CoverLetterTemplateType? templateType,
  }) {
    return CoverLetterTemplateSelection(
      templateType: templateType ?? this.templateType,
    );
  }

  Map<String, dynamic> toJson() => {
        'templateType': templateType.name,
      };

  factory CoverLetterTemplateSelection.fromJson(Map<String, dynamic> json) {
    final typeName = json['templateType'] as String? ?? 'modern';
    final type = CoverLetterTemplateType.values.firstWhere(
      (e) => e.name == typeName,
      orElse: () => CoverLetterTemplateType.modern,
    );
    return CoverLetterTemplateSelection(templateType: type);
  }

  /// Default selection
  static const defaultSelection = CoverLetterTemplateSelection(
    templateType: CoverLetterTemplateType.modern,
  );
}
