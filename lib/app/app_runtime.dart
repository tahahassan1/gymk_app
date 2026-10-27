import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../features/auth/business_logic/cubit/auth_cubit.dart';
import '../features/auth/business_logic/cubit/auth_state.dart';
import '../features/auth/business_logic/cubit/mutation_feedback_cubit.dart';
import '../features/members/business_logic/cubit/members_cubit.dart';
import '../core/time/clock.dart';
import 'app.dart';
import 'app_routes.dart';
import 'auth_router_refresh.dart';
import 'router.dart';
import 'session/data/repositories/gym_repository.dart';

class AppRuntime extends StatefulWidget {
  const AppRuntime({
    super.key,
    required this.auth,
    required this.createMembers,
    required this.createFeedback,
    this.clock = const SystemClock(),
  });
  final AuthCubit auth;
  final MembersCubit Function(GymRepository) createMembers;
  final MutationFeedbackCubit Function(GymRepository) createFeedback;
  final Clock clock;

  @override
  State<AppRuntime> createState() => _AppRuntimeState();
}

class _AppRuntimeState extends State<AppRuntime> {
  late final AuthRouterRefresh _refresh;
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    _refresh = AuthRouterRefresh(widget.auth);
    _router = createAppRouter(
      initialLocation: widget.auth.state.ready
          ? AppRoutes.members
          : AppRoutes.startup,
      auth: widget.auth,
      authRefresh: _refresh,
      createMembers: widget.createMembers,
      createFeedback: widget.createFeedback,
      clock: widget.clock,
    );
  }

  @override
  Widget build(BuildContext context) => BlocProvider<AuthCubit>.value(
    value: widget.auth,
    child: BlocListener<AuthCubit, AuthState>(
      listenWhen: (previous, current) =>
          previous.sessionEpoch != current.sessionEpoch ||
          previous.ready != current.ready,
      listener: (_, current) {
        // Imperative dialogs/sheets live above the tenant subtree. Remove them
        // before routing so a fast account switch cannot retain old gym data.
        _router.routerDelegate.navigatorKey.currentState?.popUntil(
          (route) => route.settings is Page,
        );
        _router.go(
          current.ready
              ? AppRoutes.members
              : current.identity == null && !current.initializing
              ? AppRoutes.login
              : AppRoutes.startup,
        );
      },
      child: GymkApp(router: _router),
    ),
  );

  @override
  void dispose() {
    _refresh.dispose();
    unawaited(widget.auth.close());
    super.dispose();
  }
}
