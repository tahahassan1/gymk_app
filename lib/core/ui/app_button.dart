import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_geometry.dart';

enum AppButtonVariant { primary, secondary, destructive }

class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.busy = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null && !busy;
    final background = switch (variant) {
      AppButtonVariant.primary => AppColors.brandPrimary,
      AppButtonVariant.secondary => AppColors.surface,
      AppButtonVariant.destructive => AppColors.danger,
    };
    final foreground = variant == AppButtonVariant.destructive
        ? AppColors.surface
        : AppColors.ink;
    return Padding(
      padding: const EdgeInsetsDirectional.only(
        bottom: AppGeometry.space4,
        end: AppGeometry.space4,
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: AppGeometry.radius,
          boxShadow: enabled && variant == AppButtonVariant.primary
              ? const [
                  BoxShadow(
                    color: AppColors.ink,
                    offset: AppGeometry.shadowOffset,
                  ),
                ]
              : null,
        ),
        child: FilledButton(
          onPressed: enabled ? onPressed : null,
          style: FilledButton.styleFrom(
            backgroundColor: background,
            foregroundColor: foreground,
            disabledBackgroundColor: AppColors.surfaceMuted,
            disabledForegroundColor: AppColors.textSecondary,
            minimumSize: const Size(0, AppGeometry.controlHeight),
            padding: const EdgeInsets.symmetric(
              horizontal: AppGeometry.space16,
              vertical: AppGeometry.space12,
            ),
            shape: const RoundedRectangleBorder(
              borderRadius: AppGeometry.radius,
            ),
            side: BorderSide(
              color: variant == AppButtonVariant.destructive
                  ? AppColors.danger
                  : AppColors.ink,
              width: 2,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (busy) ...[
                const SizedBox.square(
                  dimension: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(width: AppGeometry.space8),
              ],
              Flexible(child: Text(label, textAlign: TextAlign.center)),
            ],
          ),
        ),
      ),
    );
  }
}
