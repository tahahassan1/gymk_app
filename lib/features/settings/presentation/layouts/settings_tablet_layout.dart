import 'package:flutter/material.dart';

import '../../../../core/theme/app_geometry.dart';

class SettingsTabletLayout extends StatelessWidget {
  const SettingsTabletLayout({
    super.key,
    required this.fields,
    required this.account,
  });
  final Widget fields, account;
  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    key: const PageStorageKey('settings-scroll'),
    padding: const EdgeInsets.all(24),
    child: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: AppGeometry.contentWidth),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'إعدادات الجيم',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 24),
            LayoutBuilder(
              builder: (_, constraints) {
                if (constraints.maxWidth < 760) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [fields, const SizedBox(height: 32), account],
                  );
                }
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 2, child: fields),
                    const SizedBox(width: 32),
                    Expanded(child: account),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    ),
  );
}
