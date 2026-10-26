import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import 'app_routes.dart';

enum AppDestination {
  members(AppRoutes.members, Icons.people_outline),
  dropins(AppRoutes.dropins, Icons.fitness_center_outlined),
  statistics(AppRoutes.statistics, Icons.receipt_long_outlined),
  settings(AppRoutes.settings, Icons.settings_outlined);

  const AppDestination(this.path, this.icon);

  final String path;
  final IconData icon;

  String label(AppLocalizations strings) => switch (this) {
    members => strings.members,
    dropins => strings.dropins,
    statistics => strings.statistics,
    settings => strings.settings,
  };

  String description(AppLocalizations strings) => switch (this) {
    members => strings.membersDescription,
    dropins => strings.dropinsDescription,
    statistics => strings.statisticsDescription,
    settings => strings.settingsDescription,
  };
}
