import 'package:flutter/material.dart';

class MeasurementLabelWidget extends StatefulWidget {
  final String text;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback? onDoubleTap;
  final VoidCallback? onDelete;
  final GestureDragStartCallback? onPanStart;
  final GestureDragUpdateCallback? onPanUpdate;
  final GestureDragEndCallback? onPanEnd;
  final bool isMobile;
  final Color? borderColor;
  final Color? textColor;
  final Color? backgroundColor;

  const MeasurementLabelWidget({
    super.key,
    required this.text,
    required this.isSelected,
    required this.onTap,
    this.onDoubleTap,
    this.onDelete,
    this.onPanStart,
    this.onPanUpdate,
    this.onPanEnd,
    this.isMobile = false,
    this.borderColor,
    this.textColor,
    this.backgroundColor,
  });

  @override
  State<MeasurementLabelWidget> createState() => _MeasurementLabelWidgetState();
}

class _MeasurementLabelWidgetState extends State<MeasurementLabelWidget> {
  bool _isDragging = false;

  @override
  Widget build(BuildContext context) {
    final isDraggable = widget.onPanStart != null || widget.onPanUpdate != null;
    final cursor = isDraggable
        ? (_isDragging ? SystemMouseCursors.grabbing : SystemMouseCursors.grab)
        : SystemMouseCursors.click;

    return MouseRegion(
      cursor: cursor,
      child: GestureDetector(
        onTap: widget.onTap,
        onDoubleTap: widget.onDoubleTap,
        onPanStart: isDraggable
            ? (details) {
                setState(() {
                  _isDragging = true;
                });
                widget.onPanStart?.call(details);
              }
            : null,
        onPanUpdate: isDraggable ? widget.onPanUpdate : null,
        onPanEnd: isDraggable
            ? (details) {
                setState(() {
                  _isDragging = false;
                });
                widget.onPanEnd?.call(details);
              }
            : null,
        onPanCancel: isDraggable
            ? () {
                setState(() {
                  _isDragging = false;
                });
              }
            : null,
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: widget.isMobile ? 10 : 8,
            vertical: 4,
          ),
          decoration: widget.isMobile
              ? BoxDecoration(
                  color:
                      widget.backgroundColor ??
                      const Color(0xFF0F172A).withValues(alpha: 0.95),
                  border: Border.all(
                    color:
                        widget.borderColor ??
                        (widget.isSelected
                            ? Colors.amber.shade400
                            : const Color(0xFF38BDF8)),
                    width: widget.isSelected ? 2.0 : 1.5,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.4),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                )
              : BoxDecoration(
                  color: widget.isSelected
                      ? Colors.amber.shade100
                      : Colors.white.withValues(alpha: 0.9),
                  border: Border.all(
                    color: widget.isSelected
                        ? (widget.borderColor ?? Colors.amber.shade800)
                        : (widget.borderColor ?? Colors.grey.shade400),
                    width: widget.isSelected ? 2.0 : 1.2,
                  ),
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                widget.text,
                style: widget.isMobile
                    ? TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        color: widget.textColor ?? Colors.white,
                      )
                    : TextStyle(
                        fontWeight: widget.isSelected
                            ? FontWeight.bold
                            : FontWeight.w600,
                        color: widget.textColor ?? Colors.black87,
                      ),
              ),
              if (widget.isSelected && widget.onDelete != null) ...[
                const SizedBox(width: 8),
                MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: GestureDetector(
                    onTap: widget.onDelete,
                    child: Container(
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      padding: const EdgeInsets.all(4),
                      child: const Icon(
                        Icons.close,
                        size: 14,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
