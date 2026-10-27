import 'package:flutter/material.dart';

import 'dropins_mobile_layout.dart';

class DropinsTabletLayout extends StatelessWidget {
  const DropinsTabletLayout({
    super.key,
    required this.entry,
    required this.dayControls,
    required this.rows,
  });
  final Widget entry, dayControls, rows;
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (_, constraints) {
      if (constraints.maxWidth < 760) {
        return DropinsMobileLayout(
          entry: entry,
          dayControls: dayControls,
          rows: rows,
        );
      }
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 320,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: entry,
            ),
          ),
          const VerticalDivider(width: 1),
          Expanded(
            child: CustomScrollView(
              key: const PageStorageKey('dropins-scroll'),
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.all(24),
                  sliver: SliverToBoxAdapter(child: dayControls),
                ),
                rows,
              ],
            ),
          ),
        ],
      );
    },
  );
}
