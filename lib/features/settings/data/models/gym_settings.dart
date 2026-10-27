import '../../../../core/data/model_validation.dart';
import '../../../../core/money/amount_policy.dart';

final class GymSettings {
  GymSettings({
    required String gymName,
    required int subscriptionPrice,
    required int dropinPrice,
  }) : gymName = requiredName(gymName),
       subscriptionPrice = validatedAmount(
         subscriptionPrice,
         AmountPurpose.defaultPrice,
       ),
       dropinPrice = validatedAmount(dropinPrice, AmountPurpose.defaultPrice);

  final String gymName;
  final int subscriptionPrice;
  final int dropinPrice;
}
