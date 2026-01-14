import 'pdf_document_type.dart';
import 'template_style.dart';
import 'template_customization.dart';

/// User-saved PDF customization preset
class PdfPreset {
  final String id;
  final String name;
  final PdfDocumentType type;
  final String? basedOnPresetName;
  final TemplateStyle style;
  final TemplateCustomization customization;
  final DateTime createdAt;

  PdfPreset({
    required this.id,
    required this.name,
    this.type = PdfDocumentType.cv,
    this.basedOnPresetName,
    required this.style,
    required this.customization,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'type': type.name,
        'basedOnPresetName': basedOnPresetName,
        'style': style.toJson(),
        'customization': customization.toJson(),
        'createdAt': createdAt.toIso8601String(),
      };

  factory PdfPreset.fromJson(Map<String, dynamic> json) => PdfPreset(
        id: json['id'] as String,
        name: json['name'] as String,
        type: PdfDocumentType.fromString(json['type'] as String?),
        basedOnPresetName: json['basedOnPresetName'] as String?,
        style: TemplateStyle.fromJson(json['style']),
        customization: TemplateCustomization.fromJson(json['customization']),
        createdAt: DateTime.parse(json['createdAt'] as String),
      );
}
