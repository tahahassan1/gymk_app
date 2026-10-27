import 'package:flutter/material.dart';

import '../../../../core/time/date_only.dart';
import '../../../../core/ui/app_month_picker.dart';
import '../../../../core/ui/app_formatters.dart';
import '../../../../core/ui/read_notice.dart';
import '../../business_logic/cubit/statistics_state.dart';

class StatisticsControls extends StatelessWidget {
  const StatisticsControls({
    super.key,
    required this.state,
    required this.onMonth,
    required this.onPrevious,
    required this.onNext,
    required this.onRetry,
  });
  final StatisticsState state;
  final ValueChanged<DateOnly> onMonth;
  final VoidCallback onPrevious, onNext, onRetry;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    mainAxisSize: MainAxisSize.min,
    children: [
      Text(
        'المتحصلات الشهرية',
        style: Theme.of(context).textTheme.headlineSmall,
      ),
      const SizedBox(height: 12),
      Wrap(
        spacing: 8,
        runSpacing: 8,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          OutlinedButton.icon(
            onPressed: () async {
              final value = await AppMonthPicker.show(context, state.month);
              if (value != null && context.mounted) onMonth(value);
            },
            icon: const Icon(Icons.calendar_month),
            label: Text(AppFormatters.month(state.month)),
          ),
          IconButton(
            tooltip: 'الشهر السابق',
            onPressed: onPrevious,
            icon: const Icon(Icons.chevron_right),
          ),
          IconButton(
            tooltip: 'الشهر التالي',
            onPressed: onNext,
            icon: const Icon(Icons.chevron_left),
          ),
        ],
      ),
      ReadNotice(
        complete: state.complete,
        failure: state.failure,
        pending: state.pending,
        onRetry: onRetry,
      ),
      if (state.complete &&
          state.cash.subscriptionCount == 0 &&
          state.cash.dropinCount == 0)
        const Text('مفيش متحصلات مسجلة للشهر ده'),
    ],
  );
}
