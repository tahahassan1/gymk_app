import 'package:flutter/material.dart';

import '../../../../core/time/date_only.dart';
import '../../../../core/ui/app_date_field.dart';
import '../../../../core/ui/read_notice.dart';
import '../../../../core/ui/submission_feedback.dart';
import '../../business_logic/cubit/dropins_state.dart';

class DropinDayControls extends StatelessWidget {
  const DropinDayControls({
    super.key,
    required this.state,
    required this.onDay,
    required this.onToday,
    required this.onRetry,
  });
  final DropinsState state;
  final ValueChanged<DateOnly> onDay;
  final VoidCallback onToday, onRetry;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    mainAxisSize: MainAxisSize.min,
    children: [
      Text('الحصص المسجلة', style: Theme.of(context).textTheme.titleLarge),
      AppDateField(
        label: 'عرض يوم',
        value: state.day,
        lastDate: state.today,
        onChanged: onDay,
      ),
      if (state.day != state.today)
        TextButton(onPressed: onToday, child: const Text('ارجع لليوم')),
      ReadNotice(
        complete: state.complete,
        failure: state.failure,
        pending: state.pending,
        onRetry: onRetry,
      ),
      SubmissionFeedback(state: state.submission),
    ],
  );
}
