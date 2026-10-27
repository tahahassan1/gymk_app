import 'package:flutter/material.dart';

class StatisticsMobileLayout extends StatelessWidget {
  const StatisticsMobileLayout({
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
    padding: const EdgeInsets.all(16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        controls,
        const SizedBox(height: 16),
        total,
        const SizedBox(height: 16),
        subscriptions,
        const SizedBox(height: 16),
        dropins,
      ],
    ),
  );
}
