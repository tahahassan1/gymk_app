import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../core/time/clock.dart';
import '../features/auth/business_logic/cubit/auth_cubit.dart';
import '../features/auth/business_logic/cubit/mutation_feedback_cubit.dart';
import '../features/auth/data/providers/firebase_auth_provider.dart';
import '../features/auth/data/repositories/auth_repository.dart';
import '../features/auth/data/repositories/firebase_auth_repository.dart';
import '../features/members/business_logic/cubit/members_cubit.dart';
import '../features/settings/data/models/gym_settings.dart';
import '../features/subscriptions/business_logic/policies/subscription_policy.dart';
import 'router.dart';
import 'session/data/providers/firestore_gym_data_provider.dart';
import 'session/data/repositories/firestore_gym_repository.dart';
import 'session/data/repositories/gym_repository.dart';

/// App composition only. Route/form Cubits use factories; tenant repositories
/// and projections belong to captured-UID session scopes.
GetIt configureDependencies() {
  final dependencies = GetIt.asNewInstance();
  dependencies.registerSingleton<Clock>(const SystemClock());
  dependencies.registerLazySingleton<AuthRepository>(
    () => FirebaseAuthRepository(
      FirebaseAuthProvider(
        firebase: FirebaseAuth.instance,
        google: GoogleSignIn.instance,
      ),
    ),
  );
  dependencies.registerFactory<AuthCubit>(
    () => AuthCubit(
      authRepository: dependencies<AuthRepository>(),
      createGymRepository: (uid) => FirestoreGymRepository(
        FirestoreGymDataProvider(
          firestore: FirebaseFirestore.instance,
          uid: uid,
        ),
      ),
      initialSettings: GymSettings(
        gymName: 'جيمك',
        subscriptionPrice: 0,
        dropinPrice: 0,
      ),
    ),
  );
  dependencies.registerFactoryParam<MutationFeedbackCubit, GymRepository, void>(
    (repository, _) => MutationFeedbackCubit(repository),
  );
  dependencies.registerFactoryParam<MembersCubit, GymRepository, void>(
    (repository, _) => MembersCubit(
      repository: repository,
      policy: SubscriptionPolicy(clock: dependencies<Clock>()),
    ),
  );
  dependencies.registerFactory<GoRouter>(createAppRouter);
  return dependencies;
}
