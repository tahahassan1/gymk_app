import 'package:flutter_test/flutter_test.dart';
import 'package:gymk_app/core/errors/app_failure.dart';
import 'package:gymk_app/core/time/date_only.dart';
import 'package:gymk_app/features/dropins/data/models/dropin.dart';
import 'package:gymk_app/features/members/data/models/member.dart';
import 'package:gymk_app/features/settings/data/models/gym_settings.dart';

void main() {
  test('member correction keeps document identity and metadata, and can clear phone', () {
    final created = DateTime.utc(2026, 10, 27);
    final member = Member(
      id: 'one',
      name: ' أحمد ',
      phone: '01012345678',
      createdAt: created,
    );
    final edited = member.edit(name: 'محمود', phone: null);
    expect(edited.id, member.id);
    expect(edited.createdAt, created);
    expect(edited.phone, isNull);
    expect(member.name, 'أحمد');
    expect(member.phone, '01012345678');
    expect(() => member.edit(name: '  '), throwsA(isA<AppFailure>()));
    expect(
      () => Member(id: 'a/b', name: 'أحمد', createdAt: created),
      throwsA(isA<AppFailure>()),
    );
  });

  test(
    'zero defaults are valid while zero/negative payments remain invalid',
    () {
      final settings = GymSettings(
        gymName: ' جيمك ',
        subscriptionPrice: 0,
        dropinPrice: 0,
      );
      expect(settings.gymName, 'جيمك');
      expect(settings.subscriptionPrice, 0);
      for (final amount in [-1, 0]) {
        expect(
          () => Dropin(id: 'one', amount: amount, date: DateOnly(2026, 10, 27)),
          throwsA(isA<AppFailure>()),
        );
      }
      expect(
        () =>
            GymSettings(gymName: 'جيمك', subscriptionPrice: -1, dropinPrice: 0),
        throwsA(isA<AppFailure>()),
      );
    },
  );

  test(
    'drop-in correction retains ID, can clear name and can move its date',
    () {
      final record = Dropin(
        id: 'one',
        name: ' أحمد ',
        amount: 50,
        date: DateOnly(2026, 10, 27),
      );
      final corrected = record.edit(
        name: '',
        amount: 60,
        date: DateOnly(2026, 11, 1),
      );
      expect(corrected.id, record.id);
      expect(corrected.name, isNull);
      expect(corrected.date, DateOnly(2026, 11, 1));
      expect(record.date, DateOnly(2026, 10, 27));
      expect(record.amount, 50);
    },
  );
}
