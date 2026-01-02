import 'package:flutter/material.dart';
import 'pdf_editor_controller.dart';

/// Floating toolbar for PDF editor with zoom and view controls
class PdfEditorToolbar extends StatelessWidget {
  const PdfEditorToolbar({
    required this.controller,
    required this.accentColor,
    this.onPrint,
    super.key,
  });

  final PdfEditorController controller;
  final Color accentColor;
  final VoidCallback? onPrint;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.85),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: accentColor.withValues(alpha: 0.3),
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
                icon: controller.viewMode.icon,
                tooltip: controller.viewMode.label,
                onPressed: controller.cycleViewMode,
                label: controller.viewMode == PdfViewMode.sideBySide
                    ? 'Split'
                    : controller.viewMode == PdfViewMode.singlePage
                        ? 'Single'
                        : 'Fit',
              ),
              _buildDivider(),

              // Zoom controls (compact)
              _buildToolbarButton(
                icon: Icons.remove,
                tooltip: 'Zoom Out',
                onPressed: controller.zoom > PdfEditorController.minZoom
                    ? controller.zoomOut
                    : null,
              ),
              // Clickable percentage badge (click to reset to 100%)
              Tooltip(
                message: 'Click to reset to 100%',
                child: GestureDetector(
                  onTap: () => controller.setZoom(1.0),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: accentColor,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      '${(controller.zoom * 100).round()}%',
                      style: const TextStyle(
                        color: Colors.black,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
              _buildToolbarButton(
                icon: Icons.add,
                tooltip: 'Zoom In',
                onPressed: controller.zoom < PdfEditorController.maxZoom
                    ? controller.zoomIn
                    : null,
              ),
              _buildDivider(),

              // Fit width button
              _buildToolbarButton(
                icon: Icons.fit_screen,
                tooltip: 'Fit Width',
                onPressed: () {
                  controller.resetZoom();
                  controller.setViewMode(PdfViewMode.fitWidth);
                },
              ),

              if (onPrint != null) ...[
                _buildDivider(),
                _buildToolbarButton(
                  icon: Icons.print,
                  tooltip: 'Print',
                  onPressed: onPrint,
                  accentColor: true,
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildToolbarButton({
    required IconData icon,
    required String tooltip,
    VoidCallback? onPressed,
    String? label,
    bool accentColor = false,
  }) {
    final isEnabled = onPressed != null;
    final color = accentColor && isEnabled
        ? this.accentColor
        : isEnabled
            ? Colors.white
            : Colors.white.withValues(alpha: 0.3);

    return Tooltip(
      message: tooltip,
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
    );
  }

  Widget _buildDivider() {
    return Container(
      width: 1,
      height: 24,
      color: Colors.white.withValues(alpha: 0.2),
    );
  }
}
