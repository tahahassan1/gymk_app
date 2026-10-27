import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:gymk_app/core/errors/app_failure.dart';
import 'package:gymk_app/features/auth/business_logic/cubit/auth_cubit.dart';
import 'package:gymk_app/features/auth/data/models/auth_identity.dart';
import 'package:gymk_app/features/settings/data/models/gym_settings.dart';

import '../../support/fake_auth_repository.dart';
import '../../support/fake_gym_repository.dart';
import '../../support/fake_tenant_repository.dart';

GymSettings settings(String name) =>
    GymSettings(gymName: name, subscriptionPrice: 0, dropinPrice: 0);

Future<void> waitFor(AuthCubit cubit, bool Function() condition) async {
  if (condition()) return;
  await cubit.stream
      .firstWhere((_) => condition())
      .timeout(const Duration(seconds: 2));
}

void main() {
  test(
    'double sign-in is guarded immediately and cancellation is not an error',
    () async {
      final auth = FakeAuthRepository();
      final cubit = AuthCubit(
        authRepository: auth,
        createGymRepository: (_) => throw StateError('No tenant expected'),
        initialSettings: settings('جيمك'),
      );
      await waitFor(cubit, () => !cubit.state.initializing);
      auth.pendingSignIn = Completer<SignInResult>();
      final first = cubit.signIn();
      await cubit.signIn();
      expect(auth.signIns, 1);
      expect(cubit.state.signingIn, isTrue);
      auth.pendingSignIn!.complete(SignInResult.cancelled);
      await first;
      expect(cubit.state.signingIn, isFalse);
      expect(cubit.state.failure, isNull);
      await cubit.close();
      await auth.close();
    },
  );

  test(
    'sign-in failure clears busy state and can be explicitly cleared',
    () async {
      final auth = FakeAuthRepository();
      final cubit = AuthCubit(
        authRepository: auth,
        createGymRepository: (_) => throw StateError('No tenant expected'),
        initialSettings: settings('جيمك'),
      );
      await waitFor(cubit, () => !cubit.state.initializing);
      auth.pendingSignIn = Completer<SignInResult>();
      final attempt = cubit.signIn();
      auth.pendingSignIn!.completeError(
        const AppFailure(FailureKind.unavailable),
      );
      await attempt;
      expect(cubit.state.failure?.kind, FailureKind.unavailable);
      expect(cubit.state.signingIn, isFalse);
      expect(cubit.state.copyWith(failure: null).failure, isNull);
      await cubit.close();
      await auth.close();
    },
  );

  test(
    'restored cached settings allow offline use without bootstrap or resets',
    () async {
      final auth = FakeAuthRepository(current: AuthIdentity('A'));
      final tenant = FakeTenantRepository(
        'A',
        initial: snapshot(settings('الجيم القديم'), complete: false),
      );
      final cubit = AuthCubit(
        authRepository: auth,
        createGymRepository: (_) => tenant,
        initialSettings: settings('جيمك'),
      );
      await waitFor(cubit, () => cubit.state.ready);
      expect(tenant.bootstraps, 0);
      expect(tenant.currentSettings!.data!.gymName, 'الجيم القديم');
      expect(cubit.state.repository, same(tenant));
      final cleared = cubit.state.copyWith(
        identity: null,
        repository: null,
        failure: null,
      );
      expect(cleared.ready, isFalse);
      expect(cubit.state.ready, isTrue);
      await cubit.close();
      await auth.close();
    },
  );

  test('server-confirmed absence creates initial settings once; duplicate identity events do not recreate the tenant', () async {
    final auth = FakeAuthRepository(current: AuthIdentity('A'));
    final tenant = FakeTenantRepository(
      'A',
      initial: snapshot<GymSettings?>(null),
    );
    var factories = 0;
    final cubit = AuthCubit(
      authRepository: auth,
      createGymRepository: (_) {
        factories++;
        return tenant;
      },
      initialSettings: settings('جيمك'),
    );
    await waitFor(cubit, () => cubit.state.ready);
    auth.change(AuthIdentity('A'));
    await Future<void>.delayed(Duration.zero);
    expect(factories, 1);
    expect(tenant.bootstraps, 1);
    expect(tenant.currentSettings!.data!.subscriptionPrice, 0);
    expect(tenant.currentSettings!.data!.dropinPrice, 0);
    await cubit.close();
    await auth.close();
  });

  test('unverified cache absence cannot create settings and shows bounded recovery', () async {
    final auth = FakeAuthRepository(current: AuthIdentity('A'));
    final tenant = FakeTenantRepository(
      'A',
      initial: snapshot<GymSettings?>(null, complete: false),
    );
    final cubit = AuthCubit(
      authRepository: auth,
      createGymRepository: (_) => tenant,
      initialSettings: settings('جيمك'),
      initialReadTimeout: const Duration(milliseconds: 30),
    );
    await waitFor(cubit, () => cubit.state.failure != null);
    expect(tenant.bootstraps, 0);
    expect(tenant.closed, isTrue);
    expect(cubit.state.ready, isFalse);
    expect(cubit.state.failure?.code, 'initial-download');
    await cubit.close();
    await auth.close();
  });

  test(
    'bootstrap rejection remains recoverable and retry owns a new repository',
    () async {
      final auth = FakeAuthRepository(current: AuthIdentity('A'));
      final rejected = FakeTenantRepository(
        'A',
        initial: snapshot<GymSettings?>(null),
      )..bootstrapError = const AppFailure(FailureKind.permission);
      final recovered = FakeTenantRepository(
        'A',
        initial: snapshot(settings('الجيم الموجود')),
      );
      var attempts = 0;
      final cubit = AuthCubit(
        authRepository: auth,
        createGymRepository: (_) => attempts++ == 0 ? rejected : recovered,
        initialSettings: settings('جيمك'),
      );
      await waitFor(cubit, () => cubit.state.failure != null);
      expect(cubit.state.failure?.kind, FailureKind.permission);
      expect(rejected.closed, isTrue);
      await cubit.retrySession();
      expect(cubit.state.ready, isTrue);
      expect(recovered.bootstraps, 0);
      expect(cubit.state.failure, isNull);
      await cubit.close();
      await auth.close();
    },
  );

  test(
    'account change disposes the old gym and ignores late bootstrap results',
    () async {
      final auth = FakeAuthRepository(current: AuthIdentity('A'));
      final slow = FakeTenantRepository(
        'A',
        initial: snapshot<GymSettings?>(null),
      )..pendingBootstrap = Completer<void>();
      final next = FakeTenantRepository(
        'B',
        initial: snapshot(settings('جيم ب')),
      );
      final cubit = AuthCubit(
        authRepository: auth,
        createGymRepository: (uid) => uid == 'A' ? slow : next,
        initialSettings: settings('جيمك'),
      );
      await Future<void>.delayed(Duration.zero);
      expect(slow.bootstraps, 1);
      auth.change(AuthIdentity('B'));
      await waitFor(
        cubit,
        () => cubit.state.ready && cubit.state.identity!.uid == 'B',
      );
      expect(slow.closed, isTrue);
      slow.pendingBootstrap!.complete();
      await Future<void>.delayed(Duration.zero);
      expect(cubit.state.repository, same(next));
      expect(
        slow.settingsConsumers,
        1,
        reason: 'No new read after tenant disposal',
      );
      expect(cubit.state.identity!.uid, 'B');
      await cubit.close();
      await auth.close();
    },
  );

  test(
    'sign-out clears tenant state and closing ignores late sign-in completion',
    () async {
      final auth = FakeAuthRepository(current: AuthIdentity('A'));
      final tenant = FakeTenantRepository(
        'A',
        initial: snapshot(settings('جيم أ')),
      );
      final cubit = AuthCubit(
        authRepository: auth,
        createGymRepository: (_) => tenant,
        initialSettings: settings('جيمك'),
      );
      await waitFor(cubit, () => cubit.state.ready);
      await cubit.signOut();
      await waitFor(cubit, () => cubit.state.identity == null);
      expect(cubit.state.repository, isNull);
      expect(tenant.closed, isTrue);
      auth.pendingSignIn = Completer<SignInResult>();
      final pending = cubit.signIn();
      await cubit.close();
      auth.pendingSignIn!.completeError(
        const AppFailure(FailureKind.unavailable),
      );
      await pending;
      expect(auth.identities.hasListener, isFalse);
      await auth.close();
    },
  );
}
