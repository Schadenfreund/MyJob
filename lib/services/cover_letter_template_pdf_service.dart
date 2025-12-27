import 'dart:io';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models/cover_letter.dart';
import '../models/cv_data.dart';
import '../models/template_style.dart';
import '../pdf/cover_letter_templates/electric_cover_letter_template.dart';

/// Service for generating professional cover letter PDFs using the Electric magazine-style template
class CoverLetterTemplatePdfService {
  /// Generate a cover letter PDF from CoverLetter data using the Electric template
  Future<File> generatePdfFromCoverLetter({
    required CoverLetter coverLetter,
    required String outputPath,
    ContactDetails? contactDetails,
    TemplateStyle? templateStyle,
  }) async {
    final style = templateStyle ?? TemplateStyle.electric;
    final pdf = pw.Document();

    // Load fonts (Inter for professional typography)
    final boldFont = await PdfGoogleFonts.interBold();
    final regularFont = await PdfGoogleFonts.interRegular();
    final mediumFont = await PdfGoogleFonts.interMedium();

    // Generate PDF using Electric template
    ElectricCoverLetterTemplate.build(
      pdf,
      coverLetter,
      style,
      contactDetails,
      regularFont: regularFont,
      boldFont: boldFont,
      mediumFont: mediumFont,
    );

    // Save the PDF
    final file = File(outputPath);
    await file.writeAsBytes(await pdf.save());
    return file;
  }
}
