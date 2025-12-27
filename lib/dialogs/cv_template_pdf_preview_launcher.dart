import 'package:flutter/material.dart';
import 'cv_template_pdf_preview_dialog.dart';
import '../models/cv_template.dart';
import '../models/template_style.dart';

/// Launches a PDF preview
///
/// On Windows, this opens a maximized fullscreen dialog that acts as a separate view
/// The preview supports multi-page viewing and live color updates
class CvTemplatePdfPreviewLauncher {
  /// Opens PDF preview in fullscreen dialog mode
  static Future<void> openPreview({
    required BuildContext context,
    required CvTemplate cvTemplate,
    TemplateStyle? templateStyle,
  }) async {
    // Use fullscreen dialog for maximum workspace
    await Navigator.of(context).push(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (context) => CvTemplatePdfPreviewDialog(
          cvTemplate: cvTemplate,
          templateStyle: templateStyle,
        ),
      ),
    );
  }
}
