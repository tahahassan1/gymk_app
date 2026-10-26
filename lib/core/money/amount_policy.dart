import '../text/western_digits.dart';
import 'gymk_currency.dart';

enum AmountPurpose { paymentRecord, defaultPrice }

enum AmountFailure {
  empty,
  malformed,
  negative,
  fractionalAmount,
  zeroNotAllowed,
  outOfRange,
}

sealed class AmountParseResult {
  const AmountParseResult();
}

final class ParsedAmount extends AmountParseResult {
  const ParsedAmount(this.minorUnits);

  final int minorUnits;
}

final class RejectedAmount extends AmountParseResult {
  const RejectedAmount(this.failure);

  final AmountFailure failure;
}

/// Exact whole-EGP input. Accepts Western, Arabic-Indic and Persian digits,
/// with '.' or Arabic decimal separator. An all-zero decimal suffix is an
/// exact whole-pound amount; nonzero fractions are rejected, never rounded.
/// Grouping separators, signs and scientific notation are not input syntax.
abstract final class AmountPolicy {
  static final _syntax = RegExp(r'^([0-9]+)(?:[.٫]([0-9]+))?$');

  static AmountParseResult parse(
    String input, {
    required AmountPurpose purpose,
  }) {
    final normalized = westernDigits(input.trim());
    if (normalized.isEmpty) return const RejectedAmount(AmountFailure.empty);
    if (normalized.startsWith('-') || normalized.startsWith('−')) {
      return const RejectedAmount(AmountFailure.negative);
    }
    final match = _syntax.firstMatch(normalized);
    if (match == null) return const RejectedAmount(AmountFailure.malformed);
    final fraction = match.group(2) ?? '';
    final precision = GymkCurrency.fractionDigits;
    if (fraction.length > precision &&
        fraction.substring(precision).contains(RegExp('[1-9]'))) {
      return const RejectedAmount(AmountFailure.fractionalAmount);
    }
    // Native Dart integers match the Android/Firestore signed 64-bit range.
    // Parsing the integer string avoids both floating-point conversion and
    // overflow during multiplication by a monetary scale.
    final scaledFraction = fraction
        .padRight(precision, '0')
        .substring(0, precision);
    final amount = int.tryParse('${match.group(1)}$scaledFraction');
    if (amount == null) return const RejectedAmount(AmountFailure.outOfRange);
    final failure = validateMinorUnits(amount, purpose: purpose);
    return failure == null ? ParsedAmount(amount) : RejectedAmount(failure);
  }

  static AmountFailure? validateMinorUnits(
    int amount, {
    required AmountPurpose purpose,
  }) {
    if (amount < 0) return AmountFailure.negative;
    if (amount == 0 && purpose == AmountPurpose.paymentRecord) {
      return AmountFailure.zeroNotAllowed;
    }
    return null;
  }
}
