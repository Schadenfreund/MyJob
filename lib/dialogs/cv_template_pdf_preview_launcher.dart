import 'package:flutter/material.dart';
import 'cv_template_pdf_preview_dialog.dart';
import '../models/cv_template.dart';
import '../models/template_style.dart';

/// Launches a PDF preview
///
/// Opens a large draggable dialog that can be moved around the screen
class CvTemplatePdfPreviewLauncher {
  /// Opens PDF preview as a full-screen page (consistent with Editor behavior)
  static Future<void> openPreview({
    required BuildContext context,
    required CvTemplate cvTemplate,
    TemplateStyle? templateStyle,
  }) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => CvTemplatePdfPreviewDialog(
          cvTemplate: cvTemplate,
          templateStyle: templateStyle,
        ),
      ),
    );
  }
}
