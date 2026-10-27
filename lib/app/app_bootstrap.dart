import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';
import '../core/ui/app_feedback.dart';
import '../core/ui/app_loading_state.dart';
import '../l10n/app_localizations.dart';

/// Initialization and router creation happen once outside layout builders.
class AppBootstrap extends StatefulWidget {
  const AppBootstrap({
    super.key,
    required this.initialize,
    required this.readyBuilder,
  });

  final Future<void> Function() initialize;
  final Widget Function() readyBuilder;

  @override
  State<AppBootstrap> createState() => _AppBootstrapState();
}

class _AppBootstrapState extends State<AppBootstrap> {
  Widget? _ready;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    setState(() => _failed = false);
    try {
      await widget.initialize();
      if (!mounted) return;
      final ready = widget.readyBuilder();
      setState(() => _ready = ready);
    } catch (_) {
      if (mounted) setState(() => _failed = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_ready case final ready?) return ready;
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      locale: const Locale('ar', 'EG'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      theme: AppTheme.light(),
      home: Scaffold(
        body: SafeArea(
          child: _failed
              ? AppFeedback(
                  title: 'مش قادرين نبدأ التطبيق',
                  message: 'جرّب تاني. لو المشكلة مستمرة، راجع اتصالك وإعدادات التطبيق.',
                  actionLabel: 'حاول تاني',
                  onAction: _initialize,
                )
              : const AppLoadingState(),
        ),
      ),
    );
  }
}
