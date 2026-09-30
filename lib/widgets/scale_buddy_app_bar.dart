import 'package:flutter/material.dart';

class ScaleBuddyAppBar extends StatelessWidget implements PreferredSizeWidget {
  final VoidCallback onNewMeasurement;
  final VoidCallback onZoomIn;
  final VoidCallback onZoomOut;

  const ScaleBuddyAppBar({
    super.key,
    required this.onNewMeasurement,
    required this.onZoomIn,
    required this.onZoomOut,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 1,
      shadowColor: Colors.black.withValues(alpha: 0.08),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(
              Icons.architecture,
              color: Theme.of(context).colorScheme.primary,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'ScaleBuddy',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.3,
                ),
              ),
              Text(
                'Screen-Bauzeichnungs-Messtool',
                style: TextStyle(fontSize: 11, color: Colors.black54),
              ),
            ],
          ),
        ],
      ),
      actions: [
        FilledButton.tonalIcon(
          onPressed: onNewMeasurement,
          icon: const Icon(Icons.crop, size: 18),
          label: const Text('Weitere Messung'),
        ),
        const SizedBox(width: 8),
        IconButton(
          tooltip: 'Verkleinern (Zoom -)',
          icon: const Icon(Icons.zoom_out),
          onPressed: onZoomOut,
        ),
        IconButton(
          tooltip: 'Vergrößern (Zoom +)',
          icon: const Icon(Icons.zoom_in),
          onPressed: onZoomIn,
        ),
        const SizedBox(width: 12),
      ],
    );
  }
}
