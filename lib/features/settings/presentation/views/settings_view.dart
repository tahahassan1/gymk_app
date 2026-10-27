import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../app/session/data/repositories/gym_repository.dart';
import '../../business_logic/cubit/settings_cubit.dart';
import '../widgets/settings_workspace.dart';

class SettingsView extends StatelessWidget {
  const SettingsView({super.key});
  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) => SettingsCubit(context.read<GymRepository>()),
    child: const SettingsWorkspace(),
  );
}
