import 'package:flutter/material.dart';

class MeasurementLabelWidget extends StatelessWidget {
  final String text;
  final bool isSelected;
  final VoidCallback onTap;
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
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      onPanStart: onPanStart,
      onPanUpdate: onPanUpdate,
      onPanEnd: onPanEnd,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: isMobile ? 10 : 8,
          vertical: 4,
        ),
        decoration: isMobile
            ? BoxDecoration(
                color:
                    backgroundColor ??
                    const Color(0xFF0F172A).withValues(alpha: 0.95),
                border: Border.all(
                  color:
                      borderColor ??
                      (isSelected
                          ? Colors.amber.shade400
                          : const Color(0xFF38BDF8)),
                  width: isSelected ? 2.0 : 1.5,
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
                color: isSelected
                    ? Colors.amber.shade100
                    : Colors.white.withValues(alpha: 0.9),
                border: Border.all(
                  color: isSelected
                      ? (borderColor ?? Colors.amber.shade800)
                      : (borderColor ?? Colors.grey.shade400),
                  width: isSelected ? 2.0 : 1.2,
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
              text,
              style: isMobile
                  ? TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      color: textColor ?? Colors.white,
                    )
                  : TextStyle(
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.w600,
                      color: textColor ?? Colors.black87,
                    ),
            ),
            if (isSelected && onDelete != null) ...[
              const SizedBox(width: 8),
              GestureDetector(
                onTap: onDelete,
                child: Container(
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                  padding: const EdgeInsets.all(4),
                  child: const Icon(Icons.close, size: 14, color: Colors.white),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
