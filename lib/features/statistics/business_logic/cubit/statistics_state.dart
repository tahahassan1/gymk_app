import '../../../../core/errors/app_failure.dart';
import '../../../../core/time/date_only.dart';
import '../policies/monthly_cash_calculator.dart';

final class StatisticsState {
  const StatisticsState({
    required this.month,
    required this.cash,
    this.ready = false,
    this.complete = false,
    this.pending = false,
    this.subscriptionFailure,
    this.dropinFailure,
  });
  final DateOnly month;
  final MonthlyCash cash;
  final bool ready, complete, pending;
  final AppFailure? subscriptionFailure, dropinFailure;
  AppFailure? get failure => subscriptionFailure ?? dropinFailure;
}
