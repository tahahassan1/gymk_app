import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

import '../../l10n/app_localizations.dart';
import '../theme/app_geometry.dart';
import 'app_assets.dart';

class AppLoadingState extends StatelessWidget {
  const AppLoadingState({super.key});

  @override
  Widget build(BuildContext context) {
    final label = AppLocalizations.of(context).loading;
    final reduceMotion =
        MediaQuery.disableAnimationsOf(context) ||
        MediaQuery.accessibleNavigationOf(context);
    return Semantics(
      label: label,
      liveRegion: true,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ExcludeSemantics(
            child: SizedBox(
              width: 240,
              height: 130,
              child: reduceMotion
                  ? Image.asset(AppAssets.logo, fit: BoxFit.contain)
                  : Lottie.asset(
                      AppAssets.loading,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) =>
                          Image.asset(AppAssets.logo, fit: BoxFit.contain),
                    ),
            ),
          ),
          const SizedBox(height: AppGeometry.space8),
          ExcludeSemantics(child: Text(label)),
        ],
      ),
    );
  }
}
