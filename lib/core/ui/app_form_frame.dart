import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../theme/app_colors.dart';
import '../theme/app_geometry.dart';
import 'adaptive/app_layout_mode.dart';

class AppFormFrame extends StatelessWidget {
  const AppFormFrame({
    super.key,
    required this.mode,
    required this.title,
    required this.child,
  });

  final AppLayoutMode mode;
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) => SafeArea(
    child: Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: Align(
        alignment: mode == AppLayoutMode.mobile
            ? Alignment.bottomCenter
            : Alignment.center,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: AppGeometry.formWidth),
          child: Material(
            color: AppColors.surface,
            borderRadius: mode == AppLayoutMode.mobile
                ? AppGeometry.sheetRadius
                : AppGeometry.radius,
            clipBehavior: Clip.antiAlias,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppGeometry.space24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      ),
                      IconButton(
                        tooltip: AppLocalizations.of(context).close,
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppGeometry.space16),
                  child,
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );
}
