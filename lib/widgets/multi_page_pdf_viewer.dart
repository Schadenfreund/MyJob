import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import 'package:pdf/pdf.dart';

/// Professional multi-page PDF viewer
///
/// Features:
/// - Double-click to toggle between single-page and side-by-side views
/// - Visual indicator showing current view mode
/// - Professional page styling with shadows
/// - No asset dependencies (works without AssetManifest.json)
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
  bool _isSideBySide = true;

  @override
  void initState() {
    super.initState();
    _isSideBySide = widget.showSideBySide;
  }

  void _toggleViewMode() {
    setState(() {
      _isSideBySide = !_isSideBySide;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // PDF Preview with key to force rebuild on view change
        PdfPreview(
          key: ValueKey('pdf_preview_$_isSideBySide'),
          build: (format) => widget.pdfBytes,
          initialPageFormat: PdfPageFormat.a4,
          pdfFileName: widget.fileName,
          canChangePageFormat: false,
          canChangeOrientation: false,
          canDebug: false,
          allowPrinting: false,
          allowSharing: false,
          // Side-by-side: smaller page width allows horizontal layout
          // Single page: larger width for full-screen viewing
          maxPageWidth: _isSideBySide ? 400 : 700,
          // Show multiple pages for side-by-side, all pages for single view
          pages: _isSideBySide ? null : const [0, 1, 2, 3, 4, 5, 6, 7, 8, 9],
          useActions: false,
          scrollViewDecoration: BoxDecoration(
            color: Colors.grey.shade300,
          ),
          pdfPreviewPageDecoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
        ),

        // Clickable view mode toggle button (top right)
        Positioned(
          top: 20,
          right: 20,
          child: _buildViewModeToggle(),
        ),
      ],
    );
  }

  Widget _buildViewModeToggle() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _toggleViewMode,
        borderRadius: BorderRadius.circular(8),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.black87,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: widget.accentColor.withValues(alpha: 0.5),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: widget.accentColor.withValues(alpha: 0.3),
                blurRadius: 12,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                _isSideBySide ? Icons.view_week : Icons.view_agenda,
                color: widget.accentColor,
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                _isSideBySide ? 'Side-by-Side' : 'Single Page',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.touch_app,
                color: Colors.white.withValues(alpha: 0.6),
                size: 14,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
