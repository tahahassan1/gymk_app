import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import 'app_button.dart';

class AppDeletionDialog extends StatelessWidget {
  const AppDeletionDialog({
    super.key,
    required this.title,
    required this.message,
  });

  final String title;
  final String message;

  static Future<bool> confirm(
    BuildContext context, {
    required String title,
    required String message,
  }) async =>
      await showDialog<bool>(
        context: context,
        builder: (_) => AppDeletionDialog(title: title, message: message),
      ) ??
      false;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    return AlertDialog(
      scrollable: true,
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(strings.back),
        ),
        AppButton(
          label: strings.deletePermanently,
          variant: AppButtonVariant.destructive,
          onPressed: () => Navigator.of(context).pop(true),
        ),
      ],
    );
  }
}
