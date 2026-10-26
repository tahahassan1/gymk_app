import 'package:flutter/widgets.dart';

import 'app_layout_mode.dart';

/// Passes shell mode into panes without classifying their narrower width again.
class AppLayoutScope extends InheritedWidget {
  const AppLayoutScope({super.key, required this.mode, required super.child});

  final AppLayoutMode mode;

  static AppLayoutMode of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<AppLayoutScope>()!.mode;

  @override
  bool updateShouldNotify(AppLayoutScope oldWidget) => mode != oldWidget.mode;
}
