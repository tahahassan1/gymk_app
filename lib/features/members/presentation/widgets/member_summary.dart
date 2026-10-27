import 'package:flutter/material.dart';

import '../../../../core/ui/app_button.dart';
import '../../../../core/ui/app_formatters.dart';
import '../../../../core/ui/read_notice.dart';
import '../../../../core/ui/submission_feedback.dart';
import '../../business_logic/cubit/member_details_state.dart';
import 'membership_label.dart';

class MemberSummary extends StatelessWidget {
  const MemberSummary({
    super.key,
    required this.state,
    required this.onRenew,
    required this.onEdit,
    required this.onDelete,
    required this.onRetry,
    required this.onBack,
  });
  final MemberDetailsState state;
  final VoidCallback onRenew, onEdit, onDelete, onRetry, onBack;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    mainAxisSize: MainAxisSize.min,
    children: [
      Align(
        alignment: AlignmentDirectional.centerStart,
        child: TextButton.icon(
          onPressed: onBack,
          icon: const Icon(Icons.arrow_back),
          label: const Text('الأعضاء'),
        ),
      ),
      Text(
        state.member!.name,
        style: Theme.of(context).textTheme.headlineSmall,
      ),
      if (state.member!.phone case final phone?)
        Text('\u2066$phone\u2069', textDirection: TextDirection.ltr),
      const SizedBox(height: 12),
      if (state.coverage case final coverage?) ...[
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: MembershipLabel(status: coverage.status),
        ),
        if (coverage.currentExpiry case final date?)
          Text('ينتهي ${AppFormatters.day(date)}'),
        if (coverage.currentExpiry == null && coverage.lastExpiredOn != null)
          Text(
            'آخر انتهاء سابق: ${AppFormatters.day(coverage.lastExpiredOn!)}',
          ),
      ],
      ReadNotice(
        complete: state.complete,
        failure: state.failure,
        onRetry: onRetry,
      ),
      SubmissionFeedback(state: state.submission),
      const SizedBox(height: 16),
      AppButton(
        label: 'جدّد الاشتراك',
        onPressed: state.submission.busy ? null : onRenew,
      ),
      TextButton(
        onPressed: state.submission.busy ? null : onEdit,
        child: const Text('تعديل بيانات العضو'),
      ),
      TextButton(
        onPressed: state.submission.busy ? null : onDelete,
        child: Text(
          'حذف العضو نهائيًا',
          style: TextStyle(color: Theme.of(context).colorScheme.error),
        ),
      ),
    ],
  );
}
