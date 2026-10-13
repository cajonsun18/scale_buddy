import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../controllers/workspace_controller.dart';
import '../models/workflow_step.dart';
import '../theme/app_theme.dart';
import '../theme/responsive.dart';
import 'image_source_bottom_sheet.dart';

class WorkspacePlaceholder extends ConsumerWidget {
  final WorkflowStepData stepData;

  const WorkspacePlaceholder({super.key, required this.stepData});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (context.isMobile) {
      return _buildMobilePlaceholder(context, ref);
    }
    return _buildDesktopPlaceholder(context);
  }

  Widget _buildMobilePlaceholder(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final appColors = AppColors.of(context);

    return Center(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Semantics(
                button: true,
                label: 'Bild hinzufügen',
                child: Material(
                  color: Colors.transparent,
                  shape: CircleBorder(
                    side: BorderSide(
                      color: theme.colorScheme.primary,
                      width: 1.5,
                    ),
                  ),
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: () => _openSourcePicker(context, ref),
                    child: SizedBox(
                      width: 150,
                      height: 150,
                      child: Center(
                        child: Icon(
                          Icons.add,
                          size: 56,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Bild hinzufügen',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Referenzobjekt mit ins Bild nehmen',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: appColors.inputBorder),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openSourcePicker(BuildContext context, WidgetRef ref) {
    ImageSourceBottomSheet.show(
      context,
      onCamera: () {
        ref.read(workspaceControllerProvider.notifier).loadFromCamera();
      },
      onGallery: () {
        ref.read(workspaceControllerProvider.notifier).loadFromGalleryMobile();
      },
    );
  }

  Widget _buildDesktopPlaceholder(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                stepData.icon,
                size: 64,
                color: Colors.white.withValues(alpha: 0.18),
              ),
              const SizedBox(height: 16),
              Text(
                'Bild in den Workspace laden',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.of(context).sidebarBorder,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Klicke oben auf "Datei laden…", ziehe eine Bilddatei '
                'in diesen Bereich oder füge sie mit Strg+V ein.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.of(context).inputBorder,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 18),
              Text(
                'Unterstützte Formate: PNG, JPG, JPEG, BMP, WEBP, GIF',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 11,
                  color: AppColors.of(context).inputBorder,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
