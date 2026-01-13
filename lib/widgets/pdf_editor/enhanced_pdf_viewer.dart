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

  // Official A4 dimensions in points (1pt = 1/72 inch)
  // 210mm x 297mm -> 595.27pt x 841.89pt
  static const double _a4Width = 595.27;
  static const double _a4Height = 841.89;
  static const double _renderScale = 2.0; // Rasterization quality multiplier

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

      // High-quality rasterization for crisp text
      await for (final page in Printing.raster(
        widget.pdfBytes,
        pages: null,
        dpi: 96 * _renderScale, // Balanced for performance and quality
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
    return LayoutBuilder(
      builder: (context, constraints) {
        return ListenableBuilder(
          listenable: widget.controller,
          builder: (context, _) {
            final zoom = widget.controller.zoom;
            final viewMode = widget.controller.viewMode;

            return Container(
              color: const Color(0xFFF0F0F0), // Neutral library background
              child: _buildContent(constraints, zoom, viewMode),
            );
          },
        );
      },
    );
  }

  Widget _buildContent(
      BoxConstraints constraints, double zoom, PdfViewMode viewMode) {
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
            const Text(
              'Rendering Document...',
              style: TextStyle(
                color: Color(0xFF666666),
                fontSize: 13,
                fontWeight: FontWeight.w500,
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
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(32),
      child: Center(
        child: _buildPageLayout(constraints, zoom, viewMode),
      ),
    );
  }

  Widget _buildPageLayout(
      BoxConstraints constraints, double zoom, PdfViewMode viewMode) {
    // Standard spacing between pages
    const double baseSpacing = 24.0;
    const double paddingBuffer = 64.0; // Horizontal padding total
    final availableWidth =
        (constraints.maxWidth - paddingBuffer).clamp(0.0, double.infinity);

    // Objective: Robustly handle Split view in narrow windows
    if (viewMode == PdfViewMode.sideBySide) {
      // If window is too narrow for two readable pages, automatically fallback
      // to single-column layout (as requested in objective)
      if (availableWidth < 600) {
        return _buildSingleColumnLayout(availableWidth, zoom, true);
      }

      // Calculate desired width for two pages plus spacing
      double pageWidth = _a4Width * zoom * 0.75;
      double totalDesiredWidth = (pageWidth * 2) + baseSpacing;

      // Corrected scaling math: ensure Row never exceeds horizontal bounds
      if (totalDesiredWidth > availableWidth) {
        pageWidth = (availableWidth - baseSpacing) / 2;
      }

      final height = pageWidth * (_a4Height / _a4Width);
      final rows = <Widget>[];

      for (int i = 0; i < _pageImages.length; i += 2) {
        rows.add(
          Padding(
            padding: const EdgeInsets.only(bottom: baseSpacing),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildPage(i, pageWidth, height),
                if (i + 1 < _pageImages.length) ...[
                  const SizedBox(width: baseSpacing),
                  _buildPage(i + 1, pageWidth, height),
                ] else if (_pageImages.length > 1) ...[
                  const SizedBox(width: baseSpacing),
                  SizedBox(width: pageWidth, height: height),
                ],
              ],
            ),
          ),
        );
      }
      return Column(mainAxisSize: MainAxisSize.min, children: rows);
    }

    // Single Page or Fit Width modes
    final bool isFitWidth = viewMode == PdfViewMode.fitWidth;
    return _buildSingleColumnLayout(availableWidth, zoom, isFitWidth);
  }

  /// Unified single column layout builder
  Widget _buildSingleColumnLayout(
      double availableWidth, double zoom, bool isFitWidth) {
    const double baseSpacing = 24.0;

    double pageWidth;
    if (isFitWidth) {
      pageWidth = availableWidth.clamp(200.0, double.infinity);
    } else {
      pageWidth = _a4Width * zoom;
      // Safety clamp to prevent overflow even in single mode
      if (pageWidth > availableWidth) {
        pageWidth = availableWidth;
      }
    }

    final height = pageWidth * (_a4Height / _a4Width);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: _pageImages.asMap().entries.map((entry) {
        return Padding(
          padding: const EdgeInsets.only(bottom: baseSpacing),
          child: _buildPage(entry.key, pageWidth, height),
        );
      }).toList(),
    );
  }

  /// Build an individual PDF page with professional shadows
  Widget _buildPage(int index, double width, double height) {
    if (index >= _pageImages.length) return const SizedBox.shrink();
    final pageImage = _pageImages[index];

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(2),
        boxShadow: [
          // Multi-layered shadow for professional depth
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 1,
            spreadRadius: 0,
            offset: const Offset(0, 1),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 12,
            spreadRadius: -2,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: pageImage != null
          ? RawImage(
              image: pageImage,
              width: width,
              height: height,
              fit: BoxFit.contain,
              filterQuality: FilterQuality.medium,
            )
          : const Center(
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
    );
  }
}
