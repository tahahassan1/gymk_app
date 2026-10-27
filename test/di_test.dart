import 'package:flutter_test/flutter_test.dart';
import 'package:gymk_app/app/di.dart';
import 'package:gymk_app/features/members/business_logic/cubit/members_cubit.dart';

import 'support/fake_gym_repository.dart';

void main() {
  test('route factories create fresh Cubits bound to the supplied tenant repository', () async {
    final dependencies = configureDependencies();
    final repository = FakeGymRepository();
    final first = dependencies<MembersCubit>(param1: repository);
    first.searchChanged('أحمد');
    await first.close();
    final reopened = dependencies<MembersCubit>(param1: repository);
    expect(reopened, isNot(same(first)));
    expect(reopened.repository, same(repository));
    expect(reopened.state.query, isEmpty);
    await reopened.close();
    expect(repository.members.hasListener, isFalse);
    await repository.close();
    await dependencies.reset();
  });
}
