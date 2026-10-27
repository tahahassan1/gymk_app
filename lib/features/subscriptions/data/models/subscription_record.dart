import '../../../../core/data/model_validation.dart';
import '../../../../core/errors/app_failure.dart';
import '../../../../core/money/amount_policy.dart';
import '../../../../core/time/date_only.dart';

final class SubscriptionRecord {
  SubscriptionRecord({
    required String id,
    required String memberId,
    required this.startDate,
    required this.endDate,
    required int amount,
    required this.paidAt,
  }) : id = documentId(id),
       memberId = documentId(memberId),
       amount = validatedAmount(amount, AmountPurpose.paymentRecord) {
    if (endDate != startDate.addCalendarMonth()) {
      throw const AppFailure(FailureKind.validation, code: 'coverage-duration');
    }
  }

  final String id;
  final String memberId;
  final DateOnly startDate;
  final DateOnly endDate;
  final int amount;
  final DateOnly paidAt;

  /// Corrections preserve identity, member reference and payment date.
  SubscriptionRecord edit({required int amount, required DateOnly startDate}) =>
      SubscriptionRecord(
        id: id,
        memberId: memberId,
        startDate: startDate,
        endDate: startDate.addCalendarMonth(),
        amount: amount,
        paidAt: paidAt,
      );
}
