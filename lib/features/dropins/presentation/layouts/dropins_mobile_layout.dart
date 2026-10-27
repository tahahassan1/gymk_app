import 'package:flutter/material.dart';

class DropinsMobileLayout extends StatelessWidget {
  const DropinsMobileLayout({
    super.key,
    required this.entry,
    required this.dayControls,
    required this.rows,
  });
  final Widget entry, dayControls, rows;
  @override
  Widget build(BuildContext context) => CustomScrollView(
    key: const PageStorageKey('dropins-scroll'),
    slivers: [
      SliverPadding(
        padding: const EdgeInsets.all(16),
        sliver: SliverToBoxAdapter(child: entry),
      ),
      SliverPadding(
        padding: const EdgeInsets.all(16),
        sliver: SliverToBoxAdapter(child: dayControls),
      ),
      rows,
    ],
  );
}
