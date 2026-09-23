import 'package:flutter/material.dart';
import '../controllers/workspace_controller.dart';

class WorkspaceToolbar extends StatelessWidget {
  final WorkspaceController controller;

  const WorkspaceToolbar({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      color: const Color(0xFF0F172A).withValues(alpha: 0.6),
      child: Row(
        children: [
          Icon(
            Icons.image,
            size: 18,
            color: Colors.white.withValues(alpha: 0.7),
          ),
          const SizedBox(width: 8),
          Text(
            controller.loadedImage != null
                ? 'Workspace: ${controller.loadedImage!.fileName}'
                : 'Workspace: Kein Bild geladen',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
            overflow: TextOverflow.ellipsis,
          ),
          const Spacer(),
          FilledButton.tonalIcon(
            onPressed: controller.isLoading ? null : controller.loadFromPicker,
            icon: const Icon(Icons.folder_open, size: 16),
            label: const Text('Datei laden…'),
          ),
          const SizedBox(width: 6),
          OutlinedButton.icon(
            onPressed: controller.isLoading ? null : controller.pasteFromClipboard,
            icon: const Icon(Icons.content_paste, size: 16),
            label: const Text('Einfügen'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.white,
              side: const BorderSide(color: Color(0xFF475569)),
            ),
          ),
          const SizedBox(width: 6),
          OutlinedButton.icon(
            onPressed: controller.isLoading ? null : controller.loadSample,
            icon: const Icon(Icons.auto_awesome, size: 16),
            label: const Text('Beispiel'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.white,
              side: const BorderSide(color: Color(0xFF475569)),
            ),
          ),
          if (controller.loadedImage != null) ...[
            const SizedBox(width: 6),
            IconButton(
              tooltip: 'Bild entfernen',
              icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
              onPressed: controller.isLoading ? null : controller.clearImage,
            ),
          ],
        ],
      ),
    );
  }
}
