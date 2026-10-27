import 'package:flutter/material.dart';

import 'members_mobile_layout.dart';

class MembersTabletLayout extends StatelessWidget {
  const MembersTabletLayout({
    super.key,
    required this.controls,
    required this.rows,
  });
  final Widget controls;
  final Widget rows;
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      // Reflow the selected tablet composition when its content pane is narrow.
      if (constraints.maxWidth < 760) {
        return MembersMobileLayout(controls: controls, rows: rows);
      }
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 300,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: controls,
            ),
          ),
          const VerticalDivider(width: 1),
          Expanded(
            child: CustomScrollView(
              key: const PageStorageKey('members-scroll'),
              slivers: [rows],
            ),
          ),
        ],
      );
    },
  );
}
