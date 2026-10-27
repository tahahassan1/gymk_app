import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../features/auth/business_logic/cubit/mutation_feedback_cubit.dart';
import '../../features/members/business_logic/cubit/members_cubit.dart';
import 'data/repositories/gym_repository.dart';

/// State owners sit above replaceable shell layouts and are keyed per session.
class TenantSessionScope extends StatelessWidget {
  const TenantSessionScope({
    super.key,
    required this.repository,
    required this.createMembers,
    required this.createFeedback,
    required this.child,
  });
  final GymRepository repository;
  final MembersCubit Function(GymRepository) createMembers;
  final MutationFeedbackCubit Function(GymRepository) createFeedback;
  final Widget child;

  @override
  Widget build(BuildContext context) => RepositoryProvider<GymRepository>.value(
    value: repository,
    child: MultiBlocProvider(
      providers: [
        BlocProvider<MembersCubit>(create: (_) => createMembers(repository)),
        BlocProvider<MutationFeedbackCubit>(
          create: (_) => createFeedback(repository),
        ),
      ],
      child: child,
    ),
  );
}
