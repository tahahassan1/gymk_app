import 'package:flutter/material.dart';

import '../../../../core/ui/app_status_chip.dart';
import '../../../subscriptions/business_logic/policies/subscription_policy.dart';

class MembershipLabel extends StatelessWidget {
  const MembershipLabel({super.key, required this.status});
  final MembershipStatus status;
  @override
  Widget build(BuildContext context) {
    final (label, tone) = switch (status) {
      MembershipStatus.active => ('ساري', AppStatusTone.success),
      MembershipStatus.expiringSoon => ('قرب يخلص', AppStatusTone.warning),
      MembershipStatus.expired => ('منتهي', AppStatusTone.danger),
      MembershipStatus.noSubscription => ('بدون اشتراك', AppStatusTone.neutral),
    };
    return AppStatusChip(label: label, tone: tone);
  }
}
