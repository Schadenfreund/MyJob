import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import 'package:pdf/pdf.dart';

/// Multi-page PDF viewer that displays all pages in a scrollable grid
/// Supports both single column and side-by-side viewing
class MultiPagePdfViewer extends StatefulWidget {
  const MultiPagePdfViewer({
    required this.pdfBytes,
    required this.accentColor,
    this.fileName = 'document.pdf',
    this.showSideBySide = true,
    super.key,
  });

  final Uint8List pdfBytes;
  final Color accentColor;
  final String fileName;
  final bool showSideBySide;

  @override
  State<MultiPagePdfViewer> createState() => _MultiPagePdfViewerState();
}

class _MultiPagePdfViewerState extends State<MultiPagePdfViewer> {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.grey.shade300,
      child: PdfPreview(
        build: (format) => widget.pdfBytes,
        allowPrinting: true,
        allowSharing: true,
        canChangeOrientation: false,
        canChangePageFormat: false,
        canDebug: false,
        pdfFileName: widget.fileName,
        useActions: true,

        // Multi-page configuration for best viewing
        maxPageWidth: widget.showSideBySide ? 600 : 800,
        padding: const EdgeInsets.all(16),

        // Background styling
        scrollViewDecoration: BoxDecoration(
          color: Colors.grey.shade300,
        ),

        // Individual page styling with accent color
        pdfPreviewPageDecoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: widget.accentColor.withValues(alpha: 0.15),
              blurRadius: 12,
              spreadRadius: 2,
              offset: const Offset(0, 4),
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: widget.accentColor.withValues(alpha: 0.3),
            width: 2,
          ),
        ),

        // Page format
        pageFormats: const {
          'A4': PdfPageFormat.a4,
        },
      ),
    );
  }
}
