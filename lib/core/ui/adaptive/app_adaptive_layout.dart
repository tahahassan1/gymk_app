import 'package:flutter/widgets.dart';

import 'app_breakpoints.dart';

/// Selects one composition from bounded full-screen/shell constraints.
/// Keep state-owning providers and controllers above this widget.
class AppAdaptiveLayout extends StatelessWidget {
  const AppAdaptiveLayout({
    super.key,
    required this.mobileBuilder,
    required this.tabletBuilder,
  });

  final WidgetBuilder mobileBuilder;
  final WidgetBuilder tabletBuilder;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      if (!constraints.hasBoundedWidth) {
        throw FlutterError(
          'AppAdaptiveLayout requires a bounded parent width.',
        );
      }
      return constraints.maxWidth < AppBreakpoints.tablet
          ? mobileBuilder(context)
          : tabletBuilder(context);
    },
  );
}
