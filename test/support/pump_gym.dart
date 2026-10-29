import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:gymk_app/app/app.dart';
import 'package:gymk_app/app/app_shell.dart';
import 'package:gymk_app/app/session/tenant_session_scope.dart';
import 'package:gymk_app/core/time/date_only.dart';
import 'package:gymk_app/features/auth/business_logic/cubit/mutation_feedback_cubit.dart';
import 'package:gymk_app/features/auth/presentation/widgets/session_mutation_banner.dart';
import 'package:gymk_app/features/members/business_logic/cubit/members_cubit.dart';
import 'package:gymk_app/features/members/presentation/views/members_view.dart';
import 'package:gymk_app/features/members/presentation/views/member_details_view.dart';
import 'package:gymk_app/features/subscriptions/business_logic/policies/subscription_policy.dart';
import 'package:gymk_app/features/dropins/presentation/views/dropins_view.dart';
import 'package:gymk_app/features/statistics/presentation/views/statistics_view.dart';
import 'package:gymk_app/features/settings/presentation/views/settings_view.dart';
import 'package:gymk_app/features/auth/business_logic/cubit/auth_cubit.dart';

import 'fake_auth_repository.dart';

import 'fake_clock.dart';
import 'gym_fixture.dart';

/// Uses the production adaptive shell and tenant ownership. Authentication has
/// its own runtime tests; feature tests keep their asynchronous fixture in one zone.
Future<void> pumpGym(
  WidgetTester tester,
  GymFixture fixture, {
  double width = 390,
  double height = 840,
  double scale = 1,
  FakeAuthRepository? authentication,
  bool settle = true,
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = Size(width, height);
  tester.platformDispatcher.textScaleFactorTestValue = scale;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
  final source = authentication ?? FakeAuthRepository();
  final auth = AuthCubit(
    authRepository: source,
    createGymRepository: (_) => fixture.repository,
    initialSettings: fixture.defaults,
  );
  final router = GoRouter(
    initialLocation: '/members',
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) => TenantSessionScope(
          repository: fixture.repository,
          clock: FakeClock(DateOnly(2026, 11, 10)),
          createMembers: (repo) => MembersCubit(
            repository: repo,
            policy: SubscriptionPolicy(
              clock: FakeClock(DateOnly(2026, 11, 10)),
            ),
          ),
          createFeedback: (repo) => MutationFeedbackCubit(repo),
          child: AppShell(
            navigationShell: shell,
            feedback: const SessionMutationBanner(),
          ),
        ),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/members',
                builder: (_, _) => const MembersView(),
                routes: [
                  GoRoute(
                    path: ':memberId',
                    builder: (_, s) => MemberDetailsView(
                      memberId: s.pathParameters['memberId']!,
                    ),
                  ),
                ],
              ),
            ],
          ),
          for (final path in ['/dropins', '/statistics', '/settings'])
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: path,
                  builder: (_, _) => switch (path) {
                    '/dropins' => const DropinsView(),
                    '/statistics' => const StatisticsView(),
                    '/settings' => const SettingsView(),
                    _ => const SizedBox.shrink(),
                  },
                ),
              ],
            ),
        ],
      ),
    ],
  );
  await tester.pumpWidget(
    BlocProvider<AuthCubit>.value(
      value: auth,
      child: GymkApp(router: router),
    ),
  );
  if (settle) {
    await tester.pumpAndSettle();
  } else {
    await tester.pump(const Duration(milliseconds: 100));
  }
  addTearDown(() async {
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    await auth.close();
    await source.close();
    await fixture.close();
  });
}
