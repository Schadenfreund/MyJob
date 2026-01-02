import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import 'pdf_editor_controller.dart';

/// Enhanced PDF viewer with support for multiple view modes
///
/// This viewer provides a stable PDF preview that responds to controller
/// changes for zoom and view mode. Now supports true side-by-side layout.
class EnhancedPdfViewer extends StatefulWidget {
  const EnhancedPdfViewer({
    required this.pdfBytes,
    required this.controller,
    required this.fileName,
    super.key,
  });

  final Uint8List pdfBytes;
  final PdfEditorController controller;
  final String fileName;

  @override
  State<EnhancedPdfViewer> createState() => _EnhancedPdfViewerState();
}

class _EnhancedPdfViewerState extends State<EnhancedPdfViewer> {
  final List<ui.Image?> _pageImages = [];
  bool _isLoading = true;
  String? _errorMessage;
  Uint8List? _lastPdfBytes;

  final ScrollController _scrollController = ScrollController();

  // Base page dimensions for A4
  static const double _basePageWidth = 420.0;
  static const double _basePageHeight = 594.0; // A4 aspect ratio
  static const double _renderScale = 2.0;

  @override
  void initState() {
    super.initState();
    _loadDocument();
  }

  @override
  void didUpdateWidget(EnhancedPdfViewer oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Reload if PDF bytes changed
    if (oldWidget.pdfBytes != widget.pdfBytes ||
        _lastPdfBytes != widget.pdfBytes) {
      _loadDocument();
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    for (final image in _pageImages) {
      image?.dispose();
    }
    super.dispose();
  }

  Future<void> _loadDocument() async {
    if (_lastPdfBytes == widget.pdfBytes && _pageImages.isNotEmpty) {
      return; // Already loaded
    }

    // Save scroll position before loading
    double? savedScrollOffset;
    if (_scrollController.hasClients) {
      savedScrollOffset = _scrollController.offset;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Dispose old images
      for (final image in _pageImages) {
        image?.dispose();
      }
      _pageImages.clear();

      final images = <ui.Image?>[];

      await for (final page in Printing.raster(
        widget.pdfBytes,
        pages: null,
        dpi: 150 * _renderScale,
      )) {
        final image = await page.toImage();
        images.add(image);
      }

      if (!mounted) return;

      setState(() {
        _pageImages.clear();
        _pageImages.addAll(images);
        _lastPdfBytes = widget.pdfBytes;
        _isLoading = false;
      });

      // Restore scroll position after loading
      if (savedScrollOffset != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_scrollController.hasClients && mounted) {
            _scrollController.jumpTo(
              savedScrollOffset!
                  .clamp(0, _scrollController.position.maxScrollExtent),
            );
          }
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to load PDF: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.controller,
      builder: (context, _) {
        final zoom = widget.controller.zoom;
        final viewMode = widget.controller.viewMode;

        return Container(
          color: Colors.grey.shade300,
          child: _buildContent(zoom, viewMode),
        );
      },
    );
  }

  Widget _buildContent(double zoom, PdfViewMode viewMode) {
    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              color: widget.controller.style.accentColor,
              strokeWidth: 3,
            ),
            const SizedBox(height: 16),
            Text(
              'Loading PDF...',
              style: TextStyle(
                color: Colors.grey.shade700,
                fontSize: 14,
              ),
            ),
          ],
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: Colors.red.shade400),
            const SizedBox(height: 16),
            Text(_errorMessage!, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadDocument,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_pageImages.isEmpty) {
      return const Center(child: Text('No pages to display'));
    }

    return SingleChildScrollView(
      controller: _scrollController,
      padding: const EdgeInsets.all(24),
      child: Center(
        child: _buildPageLayout(zoom, viewMode),
      ),
    );
  }

  Widget _buildPageLayout(double zoom, PdfViewMode viewMode) {
    switch (viewMode) {
      case PdfViewMode.sideBySide:
        return _buildSideBySideLayout(zoom);
      case PdfViewMode.singlePage:
        return _buildSinglePageLayout(zoom);
      case PdfViewMode.fitWidth:
        return _buildFitWidthLayout(zoom);
    }
  }

  /// Build side-by-side page layout (two pages per row)
  Widget _buildSideBySideLayout(double zoom) {
    final pageWidth = _basePageWidth * zoom * 0.75;
    final pageHeight = _basePageHeight * zoom * 0.75;
    final spacing = 20.0 * zoom;

    final rows = <Widget>[];

    for (int i = 0; i < _pageImages.length; i += 2) {
      final leftPage = _buildPageWidget(i, pageWidth, pageHeight);
      final rightPage = (i + 1 < _pageImages.length)
          ? _buildPageWidget(i + 1, pageWidth, pageHeight)
          : SizedBox(width: pageWidth, height: pageHeight);

      rows.add(
        Padding(
          padding: EdgeInsets.only(bottom: spacing),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              leftPage,
              SizedBox(width: spacing),
              rightPage,
            ],
          ),
        ),
      );
    }

    return Column(mainAxisSize: MainAxisSize.min, children: rows);
  }

  /// Build single page layout (one page per row)
  Widget _buildSinglePageLayout(double zoom) {
    final pageWidth = _basePageWidth * zoom;
    final pageHeight = _basePageHeight * zoom;
    final spacing = 24.0 * zoom;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: _pageImages.asMap().entries.map((entry) {
        return Padding(
          padding: EdgeInsets.only(bottom: spacing),
          child: _buildPageWidget(entry.key, pageWidth, pageHeight),
        );
      }).toList(),
    );
  }

  /// Build fit-width layout (larger single pages)
  Widget _buildFitWidthLayout(double zoom) {
    final pageWidth = _basePageWidth * zoom * 1.3;
    final pageHeight = _basePageHeight * zoom * 1.3;
    final spacing = 24.0 * zoom;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: _pageImages.asMap().entries.map((entry) {
        return Padding(
          padding: EdgeInsets.only(bottom: spacing),
          child: _buildPageWidget(entry.key, pageWidth, pageHeight),
        );
      }).toList(),
    );
  }

  /// Build individual page widget with shadow
  Widget _buildPageWidget(int index, double width, double height) {
    final pageImage = _pageImages[index];

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: pageImage != null
          ? RawImage(
              image: pageImage,
              width: width,
              height: height,
              fit: BoxFit.contain,
              filterQuality: FilterQuality.high,
            )
          : Center(
              child: CircularProgressIndicator(
                color: widget.controller.style.accentColor,
                strokeWidth: 2,
              ),
            ),
    );
  }
}
