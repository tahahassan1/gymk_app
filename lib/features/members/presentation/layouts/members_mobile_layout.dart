import 'package:flutter/material.dart';

class MembersMobileLayout extends StatelessWidget {
  const MembersMobileLayout({
    super.key,
    required this.controls,
    required this.rows,
  });
  final Widget controls;
  final Widget rows;
  @override
  Widget build(BuildContext context) => CustomScrollView(
    key: const PageStorageKey('members-scroll'),
    slivers: [
      SliverPadding(
        padding: const EdgeInsets.all(16),
        sliver: SliverToBoxAdapter(child: controls),
      ),
      rows,
    ],
  );
}
