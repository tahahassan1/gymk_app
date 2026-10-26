import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import 'adaptive/app_adaptive_layout.dart';
import 'adaptive/app_layout_mode.dart';
import 'app_form_frame.dart';

/// The route/child owns form controllers; changing composition keeps it mounted.
class AppFormHost extends StatelessWidget {
  const AppFormHost({super.key, required this.title, required this.child});

  final String title;
  final Widget child;

  static Future<T?> show<T>(
    BuildContext context, {
    required String title,
    required WidgetBuilder builder,
  }) => showGeneralDialog<T>(
    context: context,
    barrierDismissible: true,
    barrierLabel: AppLocalizations.of(context).close,
    transitionDuration: MediaQuery.disableAnimationsOf(context)
        ? Duration.zero
        : const Duration(milliseconds: 160),
    pageBuilder: (context, animation, secondaryAnimation) => AppFormHost(
      title: title,
      child: Builder(builder: builder),
    ),
  );

  @override
  Widget build(BuildContext context) => AppAdaptiveLayout(
    mobileBuilder: (_) =>
        AppFormFrame(mode: AppLayoutMode.mobile, title: title, child: child),
    tabletBuilder: (_) =>
        AppFormFrame(mode: AppLayoutMode.tablet, title: title, child: child),
  );
}
