import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../controllers/workspace_controller.dart';
import '../models/workspace_state.dart';

class WorkspaceToolbar extends ConsumerWidget {
  const WorkspaceToolbar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(workspaceControllerProvider);
    final controller = ref.watch(workspaceControllerProvider.notifier);

    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.of(context).toolbarBg,
        border: Border(bottom: BorderSide(color: AppColors.of(context).toolbarBorder, width: 1)),
      ),
      child: Row(
        children: [
          const Text('Ansicht:', style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600)),
          const SizedBox(width: 12),
          _ToolbarButton(
            icon: Icons.image,
            label: 'Original',
            isActive: state.loadedImage != null,
            onPressed: () {},
          ),
          const SizedBox(width: 8),
          _ToolbarButton(
            icon: Icons.layers,
            label: 'Messungen',
            isActive: state.loadedImage != null,
            onPressed: () {},
          ),
          const Spacer(),
          if (state.status == LoadingStatus.loading)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)),
            ),
          FilledButton.icon(
            onPressed: state.status == LoadingStatus.loading ? null : () => controller.loadFromPicker(),
            icon: const Icon(Icons.folder_open, size: 16),
            label: const Text('Datei laden…', style: TextStyle(fontSize: 13)),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Colors.white,
              minimumSize: const Size(0, 36),
            ),
          ),
          const SizedBox(width: 8),
          FilledButton.icon(
            onPressed: state.status == LoadingStatus.loading ? null : () => controller.loadSample(),
            icon: const Icon(Icons.science, size: 16),
            label: const Text('Beispiel laden', style: TextStyle(fontSize: 13)),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.of(context).toolbarBorder,
              foregroundColor: Colors.white,
              minimumSize: const Size(0, 36),
            ),
          ),
          const SizedBox(width: 8),
          if (state.loadedImage != null)
            IconButton(
              tooltip: 'Bild entfernen',
              icon: Icon(Icons.delete_outline, color: Theme.of(context).colorScheme.error, size: 20),
              onPressed: state.status == LoadingStatus.loading ? null : () => controller.clearImage(),
            ),
        ],
      ),
    );
  }
}

class _ToolbarButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onPressed;

  const _ToolbarButton({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      onPressed: isActive ? onPressed : null,
      icon: Icon(icon, size: 16, color: isActive ? AppColors.of(context).iconActive : AppColors.of(context).iconInactive),
      label: Text(label, style: TextStyle(fontSize: 13, color: isActive ? AppColors.of(context).iconActive : AppColors.of(context).iconInactive)),
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        minimumSize: const Size(0, 36),
        backgroundColor: isActive ? Colors.blue.withValues(alpha: 0.2) : Colors.transparent,
      ),
    );
  }
}


