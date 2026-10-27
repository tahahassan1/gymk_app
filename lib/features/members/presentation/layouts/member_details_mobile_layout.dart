import 'package:flutter/material.dart';

class MemberDetailsMobileLayout extends StatelessWidget {
  const MemberDetailsMobileLayout({
    super.key,
    required this.summary,
    required this.history,
  });
  final Widget summary, history;
  @override
  Widget build(BuildContext context) => CustomScrollView(
    key: const PageStorageKey('member-details-scroll'),
    slivers: [
      SliverPadding(
        padding: const EdgeInsets.all(16),
        sliver: SliverToBoxAdapter(child: summary),
      ),
      history,
    ],
  );
}
