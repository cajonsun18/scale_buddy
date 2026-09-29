import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/workflow_step.dart';

class WorkspacePlaceholder extends StatelessWidget {
  final WorkflowStepData stepData;

  const WorkspacePlaceholder({super.key, required this.stepData});

  @override
  Widget build(BuildContext context) {
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



