import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../core/ui/app_feedback.dart';
import '../core/ui/app_loading_state.dart';
import '../core/time/clock.dart';
import '../features/auth/business_logic/cubit/auth_cubit.dart';
import '../features/auth/business_logic/cubit/mutation_feedback_cubit.dart';
import '../features/auth/presentation/views/session_loading_view.dart';
import '../features/auth/presentation/views/sign_in_view.dart';
import '../features/auth/presentation/widgets/session_mutation_banner.dart';
import '../features/members/business_logic/cubit/members_cubit.dart';
import '../features/members/presentation/views/members_view.dart';
import '../features/members/presentation/views/member_details_view.dart';
import '../features/subscriptions/presentation/views/subscription_route_view.dart';
import '../features/dropins/presentation/views/dropins_view.dart';
import '../features/statistics/presentation/views/statistics_view.dart';
import '../l10n/app_localizations.dart';
import 'app_destination.dart';
import 'app_routes.dart';
import 'app_shell.dart';
import 'foundation_destination_view.dart';
import 'preview/foundation_preview_view.dart';
import 'session/data/repositories/gym_repository.dart';
import 'session/tenant_session_scope.dart';

GoRouter createAppRouter({
  String initialLocation = AppRoutes.members,
  AuthCubit? auth,
  Listenable? authRefresh,
  MembersCubit Function(GymRepository)? createMembers,
  MutationFeedbackCubit Function(GymRepository)? createFeedback,
  Clock clock = const SystemClock(),
}) => GoRouter(
  initialLocation: initialLocation,
  refreshListenable: authRefresh,
  redirect: auth == null
      ? null
      : (context, route) {
          final state = auth.state;
          final path = route.uri.path;
          final destination =
              state.initializing ||
                  state.loadingSession ||
                  (state.identity != null && !state.ready)
              ? AppRoutes.startup
              : state.identity == null
              ? AppRoutes.login
              : null;
          if (destination != null) {
            return path == destination ? null : destination;
          }
          // Readiness navigates from startup in Presentation as a fresh route
          // request, avoiding a redirect loop when cached settings arrive while
          // an earlier members→startup redirect is still being parsed.
          return path == AppRoutes.login ? AppRoutes.members : null;
        },
  routes: [
    if (auth != null) ...[
      GoRoute(path: AppRoutes.login, builder: (_, _) => const SignInView()),
      GoRoute(
        path: AppRoutes.startup,
        builder: (_, _) => const SessionLoadingView(),
      ),
    ],
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) {
        if (auth == null) return AppShell(navigationShell: navigationShell);
        final session = auth.state;
        final repository = session.repository;
        if (repository == null) return const Scaffold(body: AppLoadingState());
        return TenantSessionScope(
          key: ValueKey('${repository.uid}/${session.sessionEpoch}'),
          repository: repository,
          clock: clock,
          createMembers: createMembers!,
          createFeedback: createFeedback!,
          child: AppShell(
            navigationShell: navigationShell,
            feedback: const SessionMutationBanner(),
          ),
        );
      },
      branches: [
        for (final destination in AppDestination.values)
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: destination.path,
                builder: (context, state) => auth == null
                    ? FoundationDestinationView(destination: destination)
                    : switch (destination) {
                        AppDestination.members => const MembersView(),
                        AppDestination.dropins => const DropinsView(),
                        AppDestination.statistics => const StatisticsView(),
                        AppDestination.settings => FoundationDestinationView(
                          destination: destination,
                        ),
                      },
                routes: destination == AppDestination.members
                    ? [
                        GoRoute(
                          path: AppRoutes.memberSegment,
                          builder: (context, state) => auth != null
                              ? MemberDetailsView(
                                  memberId: state.pathParameters['memberId']!,
                                )
                              : FoundationDestinationView(
                                  destination: destination,
                                  title: AppLocalizations.of(context)
                                      .memberDetails,
                                ),
                          routes: [
                            GoRoute(
                              path: AppRoutes.subscriptionSegment,
                              builder: (context, state) => auth != null
                                  ? SubscriptionRouteView(
                                      memberId:
                                          state.pathParameters['memberId']!,
                                    )
                                  : FoundationDestinationView(
                                      destination: destination,
                                      title: AppLocalizations.of(context)
                                          .subscription,
                                    ),
                            ),
                          ],
                        ),
                      ]
                    : [],
              ),
            ],
          ),
      ],
    ),
    if (kDebugMode)
      GoRoute(
        path: AppRoutes.foundation,
        builder: (context, state) => const FoundationPreviewView(),
      ),
  ],
  errorBuilder: (context, state) {
    final strings = AppLocalizations.of(context);
    return Scaffold(
      body: SafeArea(
        child: AppFeedback(
          title: strings.unavailableTitle,
          message: strings.unavailableMessage,
          actionLabel: strings.backToMembers,
          onAction: () => context.go(AppRoutes.members),
        ),
      ),
    );
  },
);
