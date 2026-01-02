import 'package:pdf/widgets.dart' as pw;
import '../../models/cv_data.dart';
import '../shared/pdf_styling.dart';
import '../shared/pdf_icons.dart';

/// Education Component - Professional education rendering
///
/// Provides clean education entry rendering with consistent styling.
class EducationComponent {
  EducationComponent._();

  /// Render a single education entry
  static pw.Widget entry({
    required Education education,
    required PdfStyling styling,
    bool showIcon = true,
  }) {
    return pw.Container(
      padding: pw.EdgeInsets.only(bottom: styling.space4),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          // Header row: Degree + Date
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Degree
              pw.Expanded(
                child: pw.Text(
                  education.degree,
                  style: pw.TextStyle(
                    fontSize: styling.fontSizeH4,
                    fontWeight: pw.FontWeight.bold,
                    color: styling.textPrimary,
                  ),
                ),
              ),

              // Date range with calendar icon
              pw.Row(
                mainAxisSize: pw.MainAxisSize.min,
                children: [
                  PdfIcons.calendar(color: styling.accent, size: 10),
                  pw.SizedBox(width: styling.space1),
                  pw.Text(
                    education.dateRange,
                    style: pw.TextStyle(
                      fontSize: styling.fontSizeSmall,
                      color: styling.textSecondary,
                    ),
                  ),
                ],
              ),
            ],
          ),

          pw.SizedBox(height: styling.space1),

          // Institution with school icon
          pw.Row(
            children: [
              if (showIcon) ...[
                PdfIcons.school(color: styling.accent, size: 12),
                pw.SizedBox(width: styling.space2),
              ],
              pw.Expanded(
                child: pw.Text(
                  education.institution,
                  style: pw.TextStyle(
                    fontSize: styling.fontSizeBody,
                    color: styling.textSecondary,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),

          // Description (if present)
          if (education.description != null &&
              education.description!.isNotEmpty) ...[
            pw.SizedBox(height: styling.space3),
            pw.Text(
              education.description!,
              style: pw.TextStyle(
                fontSize: styling.fontSizeBody,
                color: styling.textSecondary,
                lineSpacing: 1.5,
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Render a compact education entry (one-liner)
  static pw.Widget compactEntry({
    required Education education,
    required PdfStyling styling,
  }) {
    return pw.Container(
      padding: pw.EdgeInsets.only(bottom: styling.space2),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          // Left: Degree and institution
          pw.Expanded(
            child: pw.RichText(
              text: pw.TextSpan(
                children: [
                  pw.TextSpan(
                    text: education.degree,
                    style: pw.TextStyle(
                      fontSize: styling.fontSizeBody,
                      fontWeight: pw.FontWeight.bold,
                      color: styling.textPrimary,
                    ),
                  ),
                  pw.TextSpan(
                    text: ' - ${education.institution}',
                    style: pw.TextStyle(
                      fontSize: styling.fontSizeBody,
                      color: styling.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),

          pw.SizedBox(width: styling.space3),

          // Right: Date
          pw.Text(
            education.dateRange,
            style: pw.TextStyle(
              fontSize: styling.fontSizeSmall,
              color: styling.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  /// Render education entry in card format
  static pw.Widget cardEntry({
    required Education education,
    required PdfStyling styling,
  }) {
    return pw.Container(
      margin: pw.EdgeInsets.only(bottom: styling.space3),
      padding: styling.cardPadding,
      decoration: pw.BoxDecoration(
        color: styling.cardBackground,
        // Note: Cannot use borderRadius with non-uniform Border in pdf package
        border: pw.Border(
          left: pw.BorderSide(color: styling.accent, width: 3),
        ),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          // Degree with school icon
          pw.Row(
            children: [
              PdfIcons.school(color: styling.accent, size: 14),
              pw.SizedBox(width: styling.space2),
              pw.Expanded(
                child: pw.Text(
                  education.degree,
                  style: pw.TextStyle(
                    fontSize: styling.fontSizeH4,
                    fontWeight: pw.FontWeight.bold,
                    color: styling.textPrimary,
                  ),
                ),
              ),
            ],
          ),

          pw.SizedBox(height: styling.space2),

          // Institution and date
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Expanded(
                child: pw.Text(
                  education.institution,
                  style: pw.TextStyle(
                    fontSize: styling.fontSizeBody,
                    color: styling.textSecondary,
                  ),
                ),
              ),
              pw.Text(
                education.dateRange,
                style: pw.TextStyle(
                  fontSize: styling.fontSizeSmall,
                  color: styling.textSecondary,
                ),
              ),
            ],
          ),

          // Description
          if (education.description != null &&
              education.description!.isNotEmpty) ...[
            pw.SizedBox(height: styling.space2),
            pw.Text(
              education.description!,
              style: pw.TextStyle(
                fontSize: styling.fontSizeSmall,
                color: styling.textSecondary,
                lineSpacing: 1.4,
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Render all education entries in a section
  static pw.Widget section({
    required List<Education> education,
    required PdfStyling styling,
    EducationStyle style = EducationStyle.standard,
  }) {
    if (education.isEmpty) {
      return pw.SizedBox();
    }

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: education.map((edu) {
        switch (style) {
          case EducationStyle.standard:
            return entry(education: edu, styling: styling);

          case EducationStyle.compact:
            return compactEntry(education: edu, styling: styling);

          case EducationStyle.cards:
            return cardEntry(education: edu, styling: styling);
        }
      }).toList(),
    );
  }
}

/// Education rendering styles
enum EducationStyle {
  standard, // Default style with full details
  compact, // One-liner format
  cards, // Card-based layout
}
