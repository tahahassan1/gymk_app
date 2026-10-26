import 'package:flutter/material.dart';

import '../core/ui/app_feedback.dart';
import '../l10n/app_localizations.dart';
import 'app_destination.dart';

/// Honest development scaffolding, replaced by the corresponding feature phase.
class FoundationDestinationView extends StatelessWidget {
  const FoundationDestinationView({
    super.key,
    required this.destination,
    this.title,
  });

  final AppDestination destination;
  final String? title;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    return AppFeedback(
      title: title ?? destination.label(strings),
      message: '${destination.description(strings)}\n${strings.comingSoon}',
      icon: destination.icon,
    );
  }
}
