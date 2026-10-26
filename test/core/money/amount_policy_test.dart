import 'package:flutter_test/flutter_test.dart';
import 'package:gymk_app/core/money/amount_policy.dart';
import 'package:gymk_app/core/ui/app_formatters.dart';

void main() {
  int parsed(
    String value, {
    AmountPurpose purpose = AmountPurpose.paymentRecord,
  }) =>
      (AmountPolicy.parse(value, purpose: purpose) as ParsedAmount).minorUnits;

  test('whole EGP conversion is exact across accepted digit styles', () {
    for (final input in [
      '125',
      ' 125 ',
      '١٢٥',
      '۱۲۵',
      '1٢۵',
      '00125',
      '125.00',
      '١٢٥٫٠٠',
    ]) {
      expect(parsed(input), 125, reason: input);
    }
    expect(parsed('9007199254740993'), 9007199254740993);
    expect(parsed('9223372036854775807'), 9223372036854775807);
  });

  test('nonzero fractional pounds are rejected rather than rounded', () {
    for (final input in ['0.01', '12.5', '١٢٫٥', '12.0001', '125.50']) {
      expect(
        AmountPolicy.parse(input, purpose: AmountPurpose.paymentRecord),
        isA<RejectedAmount>().having(
          (result) => result.failure,
          'failure',
          AmountFailure.fractionalAmount,
        ),
        reason: input,
      );
    }
  });

  test('zero is allowed for defaults and rejected for payment records', () {
    for (final input in ['0', '٠', '0.00', '٠٫٠', '000']) {
      expect(parsed(input, purpose: AmountPurpose.defaultPrice), 0);
      expect(
        AmountPolicy.parse(input, purpose: AmountPurpose.paymentRecord),
        isA<RejectedAmount>().having(
          (result) => result.failure,
          'failure',
          AmountFailure.zeroNotAllowed,
        ),
      );
    }
    expect(
      AmountPolicy.validateMinorUnits(0, purpose: AmountPurpose.defaultPrice),
      isNull,
    );
    expect(
      AmountPolicy.validateMinorUnits(0, purpose: AmountPurpose.paymentRecord),
      AmountFailure.zeroNotAllowed,
    );
    expect(
      AmountPolicy.validateMinorUnits(1, purpose: AmountPurpose.paymentRecord),
      isNull,
    );
  });

  test(
    'negative input and negative integer values are invalid for both purposes',
    () {
      for (final purpose in AmountPurpose.values) {
        for (final input in ['-1', '-١', '−1', '-0']) {
          expect(
            AmountPolicy.parse(input, purpose: purpose),
            isA<RejectedAmount>().having(
              (result) => result.failure,
              'failure',
              AmountFailure.negative,
            ),
          );
        }
        expect(
          AmountPolicy.validateMinorUnits(-1, purpose: purpose),
          AmountFailure.negative,
        );
      }
    },
  );

  test('empty, malformed, nonfinite and ambiguous amounts are rejected', () {
    for (final input in ['', ' ', '\t\n']) {
      expect(
        AmountPolicy.parse(input, purpose: AmountPurpose.defaultPrice),
        isA<RejectedAmount>().having(
          (result) => result.failure,
          'failure',
          AmountFailure.empty,
        ),
      );
    }
    for (final input in [
      'NaN',
      'Infinity',
      '∞',
      '1e3',
      '+12',
      '1,000',
      '1٬000',
      '1 000',
      '1.2.3',
      '1٫2.3',
      '12.',
      '.0',
      '12ج',
      '0x10',
    ]) {
      expect(
        AmountPolicy.parse(input, purpose: AmountPurpose.defaultPrice),
        isA<RejectedAmount>().having(
          (result) => result.failure,
          'failure',
          AmountFailure.malformed,
        ),
        reason: input,
      );
    }
  });

  test(
    'amounts exceeding signed 64-bit storage are rejected without wrapping',
    () {
      for (final input in [
        '9223372036854775808',
        '999999999999999999999999999999',
      ]) {
        expect(
          AmountPolicy.parse(input, purpose: AmountPurpose.paymentRecord),
          isA<RejectedAmount>().having(
            (result) => result.failure,
            'failure',
            AmountFailure.outOfRange,
          ),
        );
      }
    },
  );

  test(
    'parsed integer totals retain precision above binary floating-point range',
    () {
      final amounts = [
        '9007199254740993',
        '1',
        '1',
      ].map((value) => parsed(value));
      expect(
        amounts.fold<int>(0, (total, amount) => total + amount),
        9007199254740995,
      );
      expect(
        [
          '125',
          '250',
          '1',
        ].map((value) => parsed(value)).reduce((a, b) => a + b),
        376,
      );
    },
  );

  test(
    'presentation formats whole EGP with Western digits and bidi isolation',
    () {
      for (final value in [0, 125, 9007199254740993, 9223372036854775807]) {
        final formatted = AppFormatters.money(value);
        expect(formatted.startsWith('\u2068'), isTrue);
        expect(formatted.endsWith('\u2069'), isTrue);
        expect(formatted, contains('EGP'));
        expect(formatted.replaceAll(RegExp('[^0-9]'), ''), value.toString());
        expect(formatted, isNot(contains(RegExp('[٠-٩۰-۹]'))));
      }
    },
  );
}
