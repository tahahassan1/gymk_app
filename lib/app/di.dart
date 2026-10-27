import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';

import '../core/time/clock.dart';
import '../features/members/business_logic/cubit/members_cubit.dart';
import '../features/subscriptions/business_logic/policies/subscription_policy.dart';
import 'session/data/repositories/gym_repository.dart';
import 'router.dart';

/// App composition only. Future route/form Cubits use factories; tenant
/// repositories/projections will belong to captured-UID session scopes.
GetIt configureDependencies() {
  final dependencies = GetIt.asNewInstance();
  dependencies.registerSingleton<Clock>(const SystemClock());
  dependencies.registerFactoryParam<MembersCubit, GymRepository, void>(
    (repository, _) => MembersCubit(
      repository: repository,
      policy: SubscriptionPolicy(clock: dependencies<Clock>()),
    ),
  );
  dependencies.registerFactory<GoRouter>(createAppRouter);
  return dependencies;
}
