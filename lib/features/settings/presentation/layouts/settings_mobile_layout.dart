import 'package:flutter/material.dart';

class SettingsMobileLayout extends StatelessWidget {
  const SettingsMobileLayout({
    super.key,
    required this.fields,
    required this.account,
  });
  final Widget fields, account;
  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    key: const PageStorageKey('settings-scroll'),
    padding: const EdgeInsets.all(16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('الإعدادات', style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 24),
        fields,
        const SizedBox(height: 32),
        account,
      ],
    ),
  );
}
