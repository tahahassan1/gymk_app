import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../core/ui/adaptive/app_adaptive_layout.dart';
import '../core/ui/adaptive/app_layout_mode.dart';
import 'app_shell_frame.dart';

class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) => AppAdaptiveLayout(
    mobileBuilder: (_) => AppShellFrame(
      mode: AppLayoutMode.mobile,
      navigationShell: navigationShell,
    ),
    tabletBuilder: (_) => AppShellFrame(
      mode: AppLayoutMode.tablet,
      navigationShell: navigationShell,
    ),
  );
}
