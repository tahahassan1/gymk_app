import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../core/ui/app_feedback.dart';
import '../l10n/app_localizations.dart';
import 'app_destination.dart';
import 'app_routes.dart';
import 'app_shell.dart';
import 'foundation_destination_view.dart';
import 'preview/foundation_preview_view.dart';

GoRouter createAppRouter({String initialLocation = AppRoutes.members}) =>
    GoRouter(
      initialLocation: initialLocation,
      routes: [
        StatefulShellRoute.indexedStack(
          builder: (context, state, navigationShell) =>
              AppShell(navigationShell: navigationShell),
          branches: [
            for (final destination in AppDestination.values)
              StatefulShellBranch(
                routes: [
                  GoRoute(
                    path: destination.path,
                    builder: (context, state) =>
                        FoundationDestinationView(destination: destination),
                    routes: destination == AppDestination.members
                        ? [
                            GoRoute(
                              path: AppRoutes.memberSegment,
                              builder: (context, state) =>
                                  FoundationDestinationView(
                                    destination: destination,
                                    title: AppLocalizations.of(context)
                                        .memberDetails,
                                  ),
                              routes: [
                                GoRoute(
                                  path: AppRoutes.subscriptionSegment,
                                  builder: (context, state) =>
                                      FoundationDestinationView(
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
