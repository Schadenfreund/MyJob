import 'package:flutter/material.dart';

/// A wrapper that makes a dialog draggable by its top handle bar
///
/// Used for large dialogs that need to be movable on desktop
class DraggableDialogWrapper extends StatefulWidget {
  const DraggableDialogWrapper({
    required this.child,
    this.widthFactor = 0.95,
    this.heightFactor = 0.95,
    super.key,
  });

  /// The dialog content
  final Widget child;

  /// Width as a factor of screen width (0.0 to 1.0)
  final double widthFactor;

  /// Height as a factor of screen height (0.0 to 1.0)
  final double heightFactor;

  @override
  State<DraggableDialogWrapper> createState() => _DraggableDialogWrapperState();
}

class _DraggableDialogWrapperState extends State<DraggableDialogWrapper> {
  Offset _offset = Offset.zero;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final dialogWidth = size.width * widget.widthFactor;
    final dialogHeight = size.height * widget.heightFactor;

    return Stack(
      children: [
        Positioned(
          left: (size.width - dialogWidth) / 2 + _offset.dx,
          top: (size.height - dialogHeight) / 2 + _offset.dy,
          child: Material(
            color: Colors.transparent,
            child: Container(
              width: dialogWidth,
              height: dialogHeight,
              decoration: BoxDecoration(
                color: const Color(0xFF1A1A1A),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.5),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              clipBehavior: Clip.antiAlias,
              child: Column(
                children: [
                  // Draggable title bar
                  GestureDetector(
                    onPanUpdate: (details) {
                      setState(() {
                        _offset += details.delta;
                      });
                    },
                    child: MouseRegion(
                      cursor: SystemMouseCursors.move,
                      child: Container(
                        height: 28,
                        color: Colors.black,
                        child: const Center(
                          child: Icon(
                            Icons.drag_handle,
                            color: Colors.white38,
                            size: 18,
                          ),
                        ),
                      ),
                    ),
                  ),
                  // The actual dialog content
                  Expanded(child: widget.child),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
