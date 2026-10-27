import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../app/session/data/repositories/gym_repository.dart';
import '../../../../core/ui/adaptive/app_layout_mode.dart';
import '../../../../core/ui/adaptive/app_layout_scope.dart';
import '../../../../core/ui/app_loading_state.dart';
import '../../../../core/time/clock.dart';
import '../../business_logic/cubit/statistics_cubit.dart';
import '../../business_logic/cubit/statistics_state.dart';
import '../layouts/statistics_mobile_layout.dart';
import '../layouts/statistics_tablet_layout.dart';
import '../widgets/statistics_controls.dart';
import '../widgets/cash_summary_card.dart';

class StatisticsView extends StatelessWidget {
  const StatisticsView({super.key});
  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) => StatisticsCubit(
      repository: context.read<GymRepository>(),
      clock: context.read<Clock>(),
    ),
    child: BlocBuilder<StatisticsCubit, StatisticsState>(
      builder: (context, state) {
        if (!state.ready && state.failure == null) {
          return const AppLoadingState();
        }
        final cubit = context.read<StatisticsCubit>();
        final controls = StatisticsControls(
          state: state,
          onMonth: cubit.monthChanged,
          onPrevious: cubit.previousMonth,
          onNext: cubit.nextMonth,
          onRetry: cubit.retry,
        );
        final total = CashSummaryCard(
          title: 'إجمالي المتحصلات',
          income: state.cash.total,
          complete: state.complete,
          emphasized: true,
        );
        final subscriptions = CashSummaryCard(
          title: 'الاشتراكات',
          income: state.cash.subscriptionIncome,
          count: state.cash.subscriptionCount,
          complete: state.complete,
        );
        final dropins = CashSummaryCard(
          title: 'الحصص الفردية',
          income: state.cash.dropinIncome,
          count: state.cash.dropinCount,
          complete: state.complete,
        );
        return AppLayoutScope.of(context) == AppLayoutMode.mobile
            ? StatisticsMobileLayout(
                controls: controls,
                total: total,
                subscriptions: subscriptions,
                dropins: dropins,
              )
            : StatisticsTabletLayout(
                controls: controls,
                total: total,
                subscriptions: subscriptions,
                dropins: dropins,
              );
      },
    ),
  );
}
