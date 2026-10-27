import '../../../../core/time/date_only.dart';
import '../../../dropins/data/models/dropin.dart';
import '../../../subscriptions/data/models/subscription_record.dart';

final class MonthlyCash {
  const MonthlyCash({
    required this.subscriptionIncome,
    required this.dropinIncome,
    required this.subscriptionCount,
    required this.dropinCount,
  });
  final BigInt subscriptionIncome, dropinIncome;
  final int subscriptionCount, dropinCount;
  BigInt get total => subscriptionIncome + dropinIncome;
}

abstract final class MonthlyCashCalculator {
  /// BigInt prevents overflow when summing valid signed-64-bit record amounts.
  static MonthlyCash calculate(
    DateOnly month,
    Iterable<SubscriptionRecord> subscriptions,
    Iterable<Dropin> dropins,
  ) {
    final start = DateOnly(month.year, month.month, 1);
    final end = start.year == 9999 && start.month == 12
        ? null
        : start.addCalendarMonth();
    var subscriptionIncome = BigInt.zero;
    var dropinIncome = BigInt.zero;
    var subscriptionCount = 0;
    var dropinCount = 0;
    for (final record in subscriptions) {
      if (!record.paidAt.isBefore(start) &&
          (end == null || record.paidAt.isBefore(end))) {
        subscriptionIncome += BigInt.from(record.amount);
        subscriptionCount++;
      }
    }
    for (final record in dropins) {
      if (!record.date.isBefore(start) &&
          (end == null || record.date.isBefore(end))) {
        dropinIncome += BigInt.from(record.amount);
        dropinCount++;
      }
    }
    return MonthlyCash(
      subscriptionIncome: subscriptionIncome,
      dropinIncome: dropinIncome,
      subscriptionCount: subscriptionCount,
      dropinCount: dropinCount,
    );
  }
}
