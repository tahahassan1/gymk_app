import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../core/theme/app_theme.dart';
import '../l10n/app_localizations.dart';

/// Owns and disposes the router supplied by the composition boundary.
class GymkApp extends StatefulWidget {
  const GymkApp({super.key, required this.router});

  final GoRouter router;

  @override
  State<GymkApp> createState() => _GymkAppState();
}

class _GymkAppState extends State<GymkApp> {
  @override
  void dispose() {
    widget.router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => MaterialApp.router(
    debugShowCheckedModeBanner: false,
    onGenerateTitle: (context) => AppLocalizations.of(context).appName,
    theme: AppTheme.light(),
    locale: const Locale('ar', 'EG'),
    supportedLocales: AppLocalizations.supportedLocales,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    routerConfig: widget.router,
  );
}
