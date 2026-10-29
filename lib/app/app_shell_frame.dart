import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../core/theme/app_geometry.dart';
import '../core/ui/adaptive/app_layout_mode.dart';
import '../core/ui/adaptive/app_layout_scope.dart';
import '../core/ui/app_assets.dart';
import '../l10n/app_localizations.dart';
import 'app_destination.dart';

/// Both compositions keep the same frame and keyed branch host alive.
class AppShellFrame extends StatelessWidget {
  const AppShellFrame({
    super.key,
    required this.mode,
    required this.navigationShell,
    this.feedback = const SizedBox.shrink(),
  });

  final AppLayoutMode mode;
  final StatefulNavigationShell navigationShell;
  final Widget feedback;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final tablet = mode == AppLayoutMode.tablet;
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Image.asset(
              AppAssets.logo,
              width: 44,
              height: 44,
              fit: BoxFit.contain,
              excludeFromSemantics: true,
            ),
            const SizedBox(width: AppGeometry.space8),
            Text(strings.appName),
          ],
        ),
      ),
      body: SafeArea(
        child: Row(
          children: [
            if (tablet) ...[
              SingleChildScrollView(
                child: IntrinsicHeight(
                  child: NavigationRail(
                    selectedIndex: navigationShell.currentIndex,
                    onDestinationSelected: navigationShell.goBranch,
                    labelType: NavigationRailLabelType.all,
                    destinations: [
                      for (final destination in AppDestination.values)
                        NavigationRailDestination(
                          icon: Icon(destination.icon),
                          label: Text(destination.label(strings)),
                        ),
                    ],
                  ),
                ),
              ),
              const VerticalDivider(width: 1),
            ],
            Expanded(
              key: const ValueKey('branch-host'),
              child: AppLayoutScope(
                mode: mode,
                child: LayoutBuilder(
                  builder: (context, constraints) => Column(
                    children: [
                      ConstrainedBox(
                        constraints: BoxConstraints(
                          maxHeight: constraints.maxHeight * .4,
                        ),
                        child: SingleChildScrollView(child: feedback),
                      ),
                      Expanded(child: navigationShell),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: tablet
          ? null
          : NavigationBar(
              selectedIndex: navigationShell.currentIndex,
              onDestinationSelected: navigationShell.goBranch,
              destinations: [
                for (final destination in AppDestination.values)
                  NavigationDestination(
                    icon: Icon(destination.icon),
                    label: destination.label(strings),
                  ),
              ],
            ),
    );
  }
}
