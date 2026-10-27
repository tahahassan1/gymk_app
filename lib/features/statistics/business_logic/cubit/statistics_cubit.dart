import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../app/session/data/repositories/gym_repository.dart';
import '../../../../core/errors/app_failure.dart';
import '../../../../core/data/mutation_registry.dart';
import '../../../../core/time/clock.dart';
import '../../../../core/time/date_only.dart';
import '../../../dropins/data/models/dropin.dart';
import '../../../subscriptions/data/models/subscription_record.dart';
import '../policies/monthly_cash_calculator.dart';
import 'statistics_state.dart';

final class StatisticsCubit extends Cubit<StatisticsState> {
  StatisticsCubit({required GymRepository repository, required Clock clock})
    : this._(repository, clock.today());
  StatisticsCubit._(this.repository, DateOnly today)
    : super(
        StatisticsState(
          month: DateOnly(today.year, today.month, 1),
          cash: MonthlyCashCalculator.calculate(today, const [], const []),
        ),
      ) {
    _subscriptions = repository.watchSubscriptions().listen(
      (_) {
        _subscriptionFailure = null;
        _publish();
      },
      onError: (Object error) {
        _subscriptionFailure = _failure(error);
        _publish();
      },
    );
    _dropins = repository.watchDropins().listen(
      (_) {
        _dropinFailure = null;
        _publish();
      },
      onError: (Object error) {
        _dropinFailure = _failure(error);
        _publish();
      },
    );
    _mutations = repository.mutationChanges.listen(
      (_) => _publish(),
      onError: (Object error) {
        _dropinFailure = _failure(error);
        _publish();
      },
    );
    _publish();
  }
  final GymRepository repository;
  late final StreamSubscription<Object?> _subscriptions, _dropins, _mutations;
  AppFailure? _subscriptionFailure, _dropinFailure;
  static AppFailure _failure(Object error) =>
      error is AppFailure ? error : const AppFailure(FailureKind.unknown);
  void monthChanged(DateOnly value) =>
      _publish(month: DateOnly(value.year, value.month, 1));
  void previousMonth() {
    final month = state.month;
    if (month.year == 1 && month.month == 1) return;
    _publish(
      month: DateOnly(
        month.month == 1 ? month.year - 1 : month.year,
        month.month == 1 ? 12 : month.month - 1,
        1,
      ),
    );
  }

  void nextMonth() {
    if (state.month.year == 9999 && state.month.month == 12) return;
    _publish(month: state.month.addCalendarMonth());
  }

  Future<void> retry() => repository.retryReads();
  void _publish({DateOnly? month}) {
    if (isClosed) return;
    final selected = month ?? state.month;
    final subscriptions = repository.currentSubscriptions;
    final dropins = repository.currentDropins;
    emit(
      StatisticsState(
        month: selected,
        cash: MonthlyCashCalculator.calculate(
          selected,
          subscriptions?.data ?? const <SubscriptionRecord>[],
          dropins?.data ?? const <Dropin>[],
        ),
        ready: subscriptions != null && dropins != null,
        complete:
            (subscriptions?.isComplete ?? false) &&
            (dropins?.isComplete ?? false),
        pending:
            (subscriptions?.hasPendingWrites ?? false) ||
            (dropins?.hasPendingWrites ?? false) ||
            repository.mutations.any(
              (m) =>
                  m.pending &&
                  (m.action == MutationAction.saveSubscription ||
                      m.action == MutationAction.deleteSubscription ||
                      m.action == MutationAction.saveDropin ||
                      m.action == MutationAction.deleteDropin ||
                      m.action == MutationAction.deleteMember),
            ),
        subscriptionFailure: _subscriptionFailure,
        dropinFailure: _dropinFailure,
      ),
    );
  }

  @override
  Future<void> close() async {
    await _subscriptions.cancel();
    await _dropins.cancel();
    await _mutations.cancel();
    return super.close();
  }
}
