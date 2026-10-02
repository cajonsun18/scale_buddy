import 'package:flutter/material.dart';

class MeasurementLabelWidget extends StatelessWidget {
  final String text;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback? onDelete;
  final GestureDragStartCallback? onPanStart;
  final GestureDragUpdateCallback? onPanUpdate;
  final GestureDragEndCallback? onPanEnd;

  const MeasurementLabelWidget({
    super.key,
    required this.text,
    required this.isSelected,
    required this.onTap,
    this.onDelete,
    this.onPanStart,
    this.onPanUpdate,
    this.onPanEnd,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      onPanStart: onPanStart,
      onPanUpdate: onPanUpdate,
      onPanEnd: onPanEnd,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected
              ? Colors.amber.shade100
              : Colors.white.withValues(alpha: 0.9),
          border: Border.all(
            color: isSelected ? Colors.amber.shade800 : Colors.grey.shade400,
            width: isSelected ? 2 : 1,
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
              style: TextStyle(
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: Colors.black87,
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
