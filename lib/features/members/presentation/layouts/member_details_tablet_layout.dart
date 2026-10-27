import 'package:flutter/material.dart';

import 'member_details_mobile_layout.dart';

class MemberDetailsTabletLayout extends StatelessWidget {
  const MemberDetailsTabletLayout({
    super.key,
    required this.summary,
    required this.history,
  });
  final Widget summary, history;
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (_, constraints) => constraints.maxWidth < 760
        ? MemberDetailsMobileLayout(summary: summary, history: history)
        : Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 320,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: summary,
                ),
              ),
              const VerticalDivider(width: 1),
              Expanded(
                child: CustomScrollView(
                  key: const PageStorageKey('member-details-scroll'),
                  slivers: [history],
                ),
              ),
            ],
          ),
  );
}
