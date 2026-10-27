import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../app/session/data/repositories/gym_repository.dart';
import '../../../../core/time/clock.dart';
import '../../business_logic/cubit/dropins_cubit.dart';
import '../../business_logic/cubit/dropin_form_cubit.dart';
import '../widgets/dropins_workspace.dart';

class DropinsView extends StatelessWidget {
  const DropinsView({super.key});
  @override
  Widget build(BuildContext context) {
    final repository = context.read<GymRepository>();
    final clock = context.read<Clock>();
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) => DropinsCubit(repository: repository, clock: clock),
        ),
        BlocProvider(
          create: (_) => DropinFormCubit(repository: repository, clock: clock),
        ),
      ],
      child: const DropinsWorkspace(),
    );
  }
}
