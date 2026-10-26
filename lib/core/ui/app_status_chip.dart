import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_geometry.dart';

enum AppStatusTone { success, warning, danger, neutral }

/// Receives a label/tone; membership rules belong to the caller's policy/Cubit.
class AppStatusChip extends StatelessWidget {
  const AppStatusChip({super.key, required this.label, required this.tone});

  final String label;
  final AppStatusTone tone;

  @override
  Widget build(BuildContext context) {
    final (foreground, background) = switch (tone) {
      AppStatusTone.success => (AppColors.success, AppColors.successSurface),
      AppStatusTone.warning => (AppColors.warning, AppColors.warningSurface),
      AppStatusTone.danger => (AppColors.danger, AppColors.dangerSurface),
      AppStatusTone.neutral => (AppColors.neutral, AppColors.neutralSurface),
    };
    return DecoratedBox(
      decoration: BoxDecoration(
        color: background,
        borderRadius: AppGeometry.radius,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppGeometry.space12,
          vertical: AppGeometry.space4,
        ),
        child: Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium
              ?.copyWith(color: foreground),
        ),
      ),
    );
  }
}
