import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:printing/printing.dart';

import '../localization/app_localizations.dart';

/// Enhanced multi-page PDF viewer with proper side-by-side layout support
///
/// Features:
/// - True side-by-side page layout (two pages displayed horizontally)
/// - Single page view mode
/// - Zoom in/out with buttons and keyboard shortcuts
/// - Print functionality
/// - Keyboard shortcuts (Ctrl+P to print, +/- to zoom)
/// - Smooth page rendering with caching
class MultiPagePdfViewer extends StatefulWidget {
  const MultiPagePdfViewer({
    required this.pdfBytes,
    required this.accentColor,
    this.fileName = 'document.pdf',
    this.showSideBySide = true,
    this.onPrint,
    super.key,
  });

  final Uint8List pdfBytes;
  final Color accentColor;
  final String fileName;
  final bool showSideBySide;
  final VoidCallback? onPrint;

  @override
  State<MultiPagePdfViewer> createState() => _MultiPagePdfViewerState();
}

class _MultiPagePdfViewerState extends State<MultiPagePdfViewer> {
  final List<ui.Image?> _pageImages = [];
  bool _isLoading = true;
  String? _errorMessage;
  int _pageCount = 0;

  bool _isSideBySide = true;
  double _zoom = 1.0;
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();

  static const double _minZoom = 0.5;
  static const double _maxZoom = 2.5;
  static const double _zoomStep = 0.1;

  // Base page dimensions for A4
  static const double _basePageWidth = 420.0;
  static const double _basePageHeight = 594.0; // A4 aspect ratio

  // Rendering quality (DPI scale)
  static const double _renderScale = 2.0;

  @override
  void initState() {
    super.initState();
    _isSideBySide = widget.showSideBySide;
    _loadDocument();
  }

  @override
  void didUpdateWidget(MultiPagePdfViewer oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Reload if PDF bytes changed
    if (oldWidget.pdfBytes != widget.pdfBytes) {
      _loadDocument();
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _focusNode.dispose();
    // Dispose images
    for (final image in _pageImages) {
      image?.dispose();
    }
    super.dispose();
  }

  Future<void> _loadDocument() async {
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

      // Use printing package to rasterize pages
      final images = <ui.Image?>[];
      int pageNum = 0;

      await for (final page in Printing.raster(
        widget.pdfBytes,
        pages: null, // All pages
        dpi: 150 * _renderScale, // High quality rendering
      )) {
        final image = await page.toImage();
        images.add(image);
        pageNum++;
      }

      if (!mounted) return;

      setState(() {
        _pageImages.clear();
        _pageImages.addAll(images);
        _pageCount = pageNum;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to load PDF: $e';
      });
    }
  }

  void _toggleViewMode() {
    setState(() {
      _isSideBySide = !_isSideBySide;
    });
  }

  void _zoomIn() {
    setState(() {
      _zoom = (_zoom + _zoomStep).clamp(_minZoom, _maxZoom);
    });
  }

  void _zoomOut() {
    setState(() {
      _zoom = (_zoom - _zoomStep).clamp(_minZoom, _maxZoom);
    });
  }

  void _resetZoom() {
    setState(() {
      _zoom = 1.0;
    });
  }

  void _handlePrint() {
    if (widget.onPrint != null) {
      widget.onPrint!();
    } else {
      Printing.layoutPdf(
        onLayout: (_) => widget.pdfBytes,
        name: widget.fileName,
      );
    }
  }

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (event is KeyDownEvent) {
      // Ctrl+P to print
      if (HardwareKeyboard.instance.isControlPressed &&
          event.logicalKey == LogicalKeyboardKey.keyP) {
        _handlePrint();
        return KeyEventResult.handled;
      }
      // Plus/Equal to zoom in
      if (event.logicalKey == LogicalKeyboardKey.equal ||
          event.logicalKey == LogicalKeyboardKey.numpadAdd) {
        _zoomIn();
        return KeyEventResult.handled;
      }
      // Minus to zoom out
      if (event.logicalKey == LogicalKeyboardKey.minus ||
          event.logicalKey == LogicalKeyboardKey.numpadSubtract) {
        _zoomOut();
        return KeyEventResult.handled;
      }
      // 0 to reset zoom
      if (event.logicalKey == LogicalKeyboardKey.digit0) {
        _resetZoom();
        return KeyEventResult.handled;
      }
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      focusNode: _focusNode,
      autofocus: true,
      onKeyEvent: _handleKeyEvent,
      child: GestureDetector(
        // Request focus when tapping the PDF area (prevents locking)
        onTap: () {
          if (!_focusNode.hasFocus) {
            _focusNode.requestFocus();
          }
        },
        behavior: HitTestBehavior.opaque,
        child: Container(
          color: Colors.grey.shade300,
          child: Stack(
            children: [
              // PDF content
              _buildPdfContent(),

              // Floating toolbar
              Positioned(
                top: 16,
                right: 16,
                child: _buildToolbar(),
              ),

              // Zoom indicator (bottom center)
              if (_zoom != 1.0)
                Positioned(
                  bottom: 20,
                  left: 0,
                  right: 0,
                  child: Center(child: _buildZoomIndicator()),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPdfContent() {
    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              color: widget.accentColor,
              strokeWidth: 3,
            ),
            const SizedBox(height: 16),
            Text(
              context.tr('loading_pdf'),
              style: TextStyle(
                color: Colors.grey.shade700,
                fontSize: 14,
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
            Text(
              _errorMessage!,
              style: TextStyle(color: Colors.grey.shade700),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadDocument,
              child: Text(context.tr('retry')),
            ),
          ],
        ),
      );
    }

    if (_pageImages.isEmpty) {
      return Center(
        child: Text(context.tr('no_pages_to_display')),
      );
    }

    return SingleChildScrollView(
      controller: _scrollController,
      padding: const EdgeInsets.all(24),
      child: Center(
        child:
            _isSideBySide ? _buildSideBySideLayout() : _buildSinglePageLayout(),
      ),
    );
  }

  /// Build side-by-side page layout (two pages per row)
  Widget _buildSideBySideLayout() {
    final pageWidth = _basePageWidth * _zoom * 0.8;
    final pageHeight = _basePageHeight * _zoom * 0.8;
    final spacing = 20.0 * _zoom;

    final rows = <Widget>[];

    for (int i = 0; i < _pageImages.length; i += 2) {
      final leftPage = _buildPageWidget(i, pageWidth, pageHeight);
      final rightPage = (i + 1 < _pageImages.length)
          ? _buildPageWidget(i + 1, pageWidth, pageHeight)
          : SizedBox(width: pageWidth, height: pageHeight);

      rows.add(
        Padding(
          padding: EdgeInsets.only(bottom: spacing),
          // Wrap in LayoutBuilder to handle overflow gracefully
          child: LayoutBuilder(
            builder: (context, constraints) {
              final totalWidth = pageWidth * 2 + spacing;
              // If content is wider than available space, use FittedBox to scale down
              if (totalWidth > constraints.maxWidth &&
                  constraints.maxWidth > 0) {
                return FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      leftPage,
                      SizedBox(width: spacing),
                      rightPage,
                    ],
                  ),
                );
              }
              return Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  leftPage,
                  SizedBox(width: spacing),
                  rightPage,
                ],
              );
            },
          ),
        ),
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: rows,
    );
  }

  /// Build single page layout (one page per row)
  Widget _buildSinglePageLayout() {
    final pageWidth = _basePageWidth * _zoom * 1.1;
    final pageHeight = _basePageHeight * _zoom * 1.1;
    final spacing = 24.0 * _zoom;

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
                color: widget.accentColor,
                strokeWidth: 2,
              ),
            ),
    );
  }

  Widget _buildToolbar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: widget.accentColor.withValues(alpha: 0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // View mode toggle
          _buildToolbarButton(
            icon: _isSideBySide ? Icons.view_week : Icons.view_agenda,
            tooltip: _isSideBySide
                ? context.tr('switch_to_single_page')
                : context.tr('switch_to_side_by_side'),
            onPressed: _toggleViewMode,
            label: _isSideBySide ? context.tr('split_view') : context.tr('single_view'),
            isActive: _isSideBySide,
          ),
          _buildDivider(),

          // Zoom controls
          _buildToolbarButton(
            icon: Icons.remove,
            tooltip: context.tr('zoom_out'),
            onPressed: _zoom > _minZoom ? _zoomOut : null,
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text(
              '${(_zoom * 100).round()}%',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          _buildToolbarButton(
            icon: Icons.add,
            tooltip: context.tr('zoom_in'),
            onPressed: _zoom < _maxZoom ? _zoomIn : null,
          ),
          _buildDivider(),

          // Page count
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text(
              context.tr('n_pages_count', {'count': '$_pageCount'}),
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.7),
                fontSize: 11,
              ),
            ),
          ),
          _buildDivider(),

          // Print button
          _buildToolbarButton(
            icon: Icons.print,
            tooltip: context.tr('print_shortcut'),
            onPressed: _handlePrint,
            useAccentColor: true,
          ),
        ],
      ),
    );
  }

  Widget _buildToolbarButton({
    required IconData icon,
    required String tooltip,
    VoidCallback? onPressed,
    String? label,
    bool useAccentColor = false,
    bool isActive = false,
  }) {
    final isEnabled = onPressed != null;
    final color = useAccentColor && isEnabled
        ? widget.accentColor
        : isActive && isEnabled
            ? widget.accentColor
            : isEnabled
                ? Colors.white
                : Colors.white.withValues(alpha: 0.3);

    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, color: color, size: 18),
                if (label != null) ...[
                  const SizedBox(width: 6),
                  Text(
                    label,
                    style: TextStyle(
                      color: color,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Container(
      width: 1,
      height: 24,
      color: Colors.white.withValues(alpha: 0.2),
    );
  }

  Widget _buildZoomIndicator() {
    return AnimatedOpacity(
      opacity: 1.0,
      duration: const Duration(milliseconds: 200),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.7),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _zoom > 1.0 ? Icons.zoom_in : Icons.zoom_out,
              color: widget.accentColor,
              size: 16,
            ),
            const SizedBox(width: 8),
            Text(
              '${(_zoom * 100).round()}%',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 8),
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: _resetZoom,
                borderRadius: BorderRadius.circular(4),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  child: Text(
                    context.tr('reset_zoom'),
                    style: TextStyle(
                      color: widget.accentColor,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
