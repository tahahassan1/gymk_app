import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymk_app/app/session/data/providers/record_codecs.dart';
import 'package:gymk_app/core/errors/app_failure.dart';
import 'package:gymk_app/core/time/date_only.dart';
import 'package:gymk_app/core/time/date_only_codec.dart';
import 'package:gymk_app/features/subscriptions/data/models/subscription_record.dart';

void main() {
  test(
    'date codec is zero-padded and rejects invalid/surplus representations',
    () {
      for (final date in [
        DateOnly(1, 1, 1),
        DateOnly(2024, 2, 29),
        DateOnly(9999, 12, 31),
      ]) {
        expect(DateOnlyCodec.decode(DateOnlyCodec.encode(date)), date);
      }
      expect(DateOnlyCodec.encode(DateOnly(2026, 1, 9)), '2026-01-09');
      for (final value in <Object?>[
        null,
        20261027,
        '2026-1-01',
        '2026-02-29',
        '0000-01-01',
        '2026-13-01',
        '2026-10-27T00:00:00Z',
        '2026-10-27\n',
        '٢٠٢٦-١٠-٢٧',
      ]) {
        expect(
          () => DateOnlyCodec.decode(value),
          throwsA(isA<AppFailure>()),
          reason: '$value',
        );
      }
    },
  );

  test('document ID is authoritative and phone remains a string', () {
    final member = RecordCodecs.member('path-id', {
      'id': 'wrong',
      'name': 'أحمد',
      'phone': '01012345678',
      'createdAt': Timestamp.fromDate(DateTime.utc(2026, 10, 27)),
    });
    expect(member.id, 'path-id');
    expect(member.phone, '01012345678');
    final roundTrip = RecordCodecs.member(
      member.id,
      RecordCodecs.memberData(member),
    );
    expect(roundTrip.createdAt, member.createdAt);
    expect(roundTrip.name, member.name);
    expect(RecordCodecs.memberData(member), isNot(contains('id')));
    expect(
      () => RecordCodecs.member('one', {
        'name': 'أحمد',
        'phone': 10123,
        'createdAt': Timestamp.now(),
      }),
      throwsA(isA<AppFailure>()),
    );
  });

  test('subscription roundtrip and correction preserve payment and member references', () {
    final record = SubscriptionRecord(
      id: 'payment',
      memberId: 'member',
      startDate: DateOnly(2026, 11, 26),
      endDate: DateOnly(2026, 12, 26),
      amount: 125,
      paidAt: DateOnly(2026, 11, 10),
    );
    final corrected = record.edit(
      amount: 150,
      startDate: DateOnly(2026, 11, 1),
    );
    final decoded = RecordCodecs.subscription(
      corrected.id,
      RecordCodecs.subscriptionData(corrected),
    );
    expect(decoded.memberId, 'member');
    expect(decoded.paidAt, DateOnly(2026, 11, 10));
    expect(decoded.endDate, DateOnly(2026, 12, 1));
    expect(decoded.amount, 150);
    expect(record.endDate, DateOnly(2026, 12, 26));
  });

  test('codecs reject malformed money, invalid coverage and missing required fields', () {
    final data = {
      'memberId': 'member',
      'startDate': '2026-10-27',
      'endDate': '2026-11-27',
      'amount': 125,
      'paidAt': '2026-10-27',
    };
    for (final amount in [125.0, '125', -1, 0]) {
      expect(
        () => RecordCodecs.subscription('one', {...data, 'amount': amount}),
        throwsA(isA<AppFailure>()),
      );
    }
    expect(
      () =>
          RecordCodecs.subscription('one', {...data, 'endDate': '2026-11-26'}),
      throwsA(isA<AppFailure>()),
    );
    expect(
      () => RecordCodecs.settings({'gymName': 'جيمك'}),
      throwsA(isA<AppFailure>()),
    );
    expect(
      () => RecordCodecs.dropin('one', {'amount': 50, 'date': '2026-02-30'}),
      throwsA(isA<AppFailure>()),
    );
  });

  test(
    'settings and independent drop-ins use whole EGP and date-only maps',
    () {
      final settings = RecordCodecs.settings({
        'gymName': 'جيمك',
        'defaultSubscriptionPrice': 0,
        'defaultDropinPrice': 50,
      });
      expect(
        RecordCodecs.settingsData(settings)['defaultSubscriptionPrice'],
        0,
      );
      final dropin = RecordCodecs.dropin('dropin', {
        'amount': 50,
        'date': '2026-10-27',
      });
      expect(dropin.name, isNull);
      expect(RecordCodecs.dropinData(dropin), {
        'amount': 50,
        'date': '2026-10-27',
      });
    },
  );
}
