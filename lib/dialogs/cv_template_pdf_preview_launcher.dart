import 'package:flutter/material.dart';
import 'cv_template_pdf_preview_dialog.dart';
import '../models/cv_template.dart';
import '../models/template_style.dart';
import '../widgets/draggable_dialog_wrapper.dart';

/// Launches a PDF preview
///
/// Opens a large draggable dialog that can be moved around the screen
class CvTemplatePdfPreviewLauncher {
  /// Opens PDF preview as a draggable dialog
  static Future<void> openPreview({
    required BuildContext context,
    required CvTemplate cvTemplate,
    TemplateStyle? templateStyle,
  }) async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black54,
      builder: (context) => DraggableDialogWrapper(
        child: CvTemplatePdfPreviewDialog(
          cvTemplate: cvTemplate,
          templateStyle: templateStyle,
        ),
      ),
    );
  }
}
