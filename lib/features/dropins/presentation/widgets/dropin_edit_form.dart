import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../app/session/data/repositories/gym_repository.dart';
import '../../../../core/time/clock.dart';
import '../../../../core/ui/app_form_host.dart';
import '../../business_logic/cubit/dropin_form_cubit.dart';
import '../../business_logic/cubit/dropin_form_state.dart';
import '../../data/models/dropin.dart';
import 'dropin_fields.dart';

class DropinEditForm extends StatefulWidget {
  const DropinEditForm({super.key});
  static Future<void> show(
    BuildContext context,
    GymRepository repository,
    Clock clock,
    Dropin record,
  ) => AppFormHost.show<void>(
    context,
    title: 'تعديل الحصة',
    builder: (_) => BlocProvider(
      create: (_) => DropinFormCubit(
        repository: repository,
        clock: clock,
        original: record,
      ),
      child: const DropinEditForm(),
    ),
  );
  @override
  State<DropinEditForm> createState() => _DropinEditFormState();
}

class _DropinEditFormState extends State<DropinEditForm> {
  late final TextEditingController _name, _amount;
  @override
  void initState() {
    super.initState();
    final state = context.read<DropinFormCubit>().state;
    _name = TextEditingController(text: state.name);
    _amount = TextEditingController(text: state.amount);
  }

  @override
  void dispose() {
    _name.dispose();
    _amount.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      BlocConsumer<DropinFormCubit, DropinFormState>(
        listenWhen: (a, b) => !a.submission.applied && b.submission.applied,
        listener: (context, _) => Navigator.of(context).pop(),
        builder: (context, state) {
          final cubit = context.read<DropinFormCubit>();
          return DropinFields(
            state: state,
            name: _name,
            amount: _amount,
            onName: cubit.nameChanged,
            onAmount: cubit.amountChanged,
            onDate: cubit.dateChanged,
            onSave: cubit.submit,
            readOnly: !cubit.canEdit,
          );
        },
      );
}
