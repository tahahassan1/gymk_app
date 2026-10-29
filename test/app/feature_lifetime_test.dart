import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymk_app/core/time/date_only.dart';
import 'package:gymk_app/features/members/business_logic/cubit/members_cubit.dart';
import 'package:gymk_app/features/members/business_logic/cubit/member_details_cubit.dart';
import 'package:gymk_app/features/dropins/business_logic/cubit/dropins_cubit.dart';
import 'package:gymk_app/features/dropins/business_logic/cubit/dropin_form_cubit.dart';
import 'package:gymk_app/features/statistics/business_logic/cubit/statistics_cubit.dart';
import 'package:gymk_app/features/settings/business_logic/cubit/settings_cubit.dart';
import 'package:gymk_app/features/auth/business_logic/cubit/mutation_feedback_cubit.dart';
import 'package:gymk_app/features/subscriptions/business_logic/policies/subscription_policy.dart';

import '../support/gym_fixture.dart';
import '../support/fake_clock.dart';

void main() {
  test('disposing feature owners closes emissions before awaiting listener cleanup', () async {
    final fixture = GymFixture();
    final clock = FakeClock(DateOnly(2026, 11, 10));
    final policy = SubscriptionPolicy(clock: clock);
    final owners = <BlocBase<Object?>>[
      MembersCubit(repository: fixture.repository, policy: policy),
      MemberDetailsCubit(
        repository: fixture.repository,
        policy: policy,
        memberId: 'one',
      ),
      DropinsCubit(repository: fixture.repository, clock: clock),
      DropinFormCubit(repository: fixture.repository, clock: clock),
      StatisticsCubit(repository: fixture.repository, clock: clock),
      SettingsCubit(fixture.repository),
      MutationFeedbackCubit(fixture.repository),
    ];
    addTearDown(() async {
      for (final owner in owners) {
        await owner.close();
      }
      await fixture.close();
    });
    await Future<void>.delayed(Duration.zero);
    final closing = <Future<void>>[];
    for (final owner in owners) {
      closing.add(owner.close());
      expect(
        owner.isClosed,
        isTrue,
        reason: '${owner.runtimeType} can no longer emit during teardown',
      );
    }
    fixture.publish();
    await Future.wait(closing);
  });
}
