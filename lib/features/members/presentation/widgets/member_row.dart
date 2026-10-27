import 'package:flutter/material.dart';

import '../../../../core/ui/app_formatters.dart';
import '../../business_logic/cubit/members_state.dart';
import 'membership_label.dart';

class MemberRow extends StatelessWidget {
  const MemberRow({
    super.key,
    required this.row,
    required this.coverageReady,
    required this.onTap,
  });
  final MemberRowData row;
  final bool coverageReady;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => ListTile(
    onTap: onTap,
    title: Text(row.member.name),
    subtitle: Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Wrap(
        spacing: 12,
        runSpacing: 8,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          if (coverageReady)
            MembershipLabel(status: row.coverage.status)
          else
            const Text('جاري تحميل الاشتراكات'),
          if (row.coverage.currentExpiry case final expiry?)
            Text('ينتهي ${AppFormatters.day(expiry)}'),
        ],
      ),
    ),
    trailing: const Icon(Icons.chevron_left),
  );
}
