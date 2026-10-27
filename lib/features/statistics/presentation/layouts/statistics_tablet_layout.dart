import 'package:flutter/material.dart';

import '../../../../core/theme/app_geometry.dart';

class StatisticsTabletLayout extends StatelessWidget {
  const StatisticsTabletLayout({
    super.key,
    required this.controls,
    required this.total,
    required this.subscriptions,
    required this.dropins,
  });
  final Widget controls, total, subscriptions, dropins;
  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    key: const PageStorageKey('statistics-scroll'),
    padding: const EdgeInsets.all(24),
    child: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: AppGeometry.contentWidth),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            controls,
            const SizedBox(height: 24),
            total,
            const SizedBox(height: 24),
            LayoutBuilder(
              builder: (_, constraints) => Wrap(
                spacing: 16,
                runSpacing: 16,
                children: [
                  SizedBox(
                    width: constraints.maxWidth >= 640
                        ? (constraints.maxWidth - 16) / 2
                        : constraints.maxWidth,
                    child: subscriptions,
                  ),
                  SizedBox(
                    width: constraints.maxWidth >= 640
                        ? (constraints.maxWidth - 16) / 2
                        : constraints.maxWidth,
                    child: dropins,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
