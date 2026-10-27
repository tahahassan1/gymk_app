import '../../../../core/data/model_validation.dart';
import '../../../../core/money/amount_policy.dart';
import '../../../../core/time/date_only.dart';

final class Dropin {
  Dropin({
    required String id,
    String? name,
    required int amount,
    required this.date,
  }) : id = documentId(id),
       name = optionalText(name),
       amount = validatedAmount(amount, AmountPurpose.paymentRecord);

  final String id;
  final String? name;
  final int amount;
  final DateOnly date;

  Dropin edit({String? name, required int amount, required DateOnly date}) =>
      Dropin(id: id, name: name, amount: amount, date: date);
}
