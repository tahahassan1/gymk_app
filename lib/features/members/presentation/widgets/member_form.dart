import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../app/session/data/repositories/gym_repository.dart';
import '../../../../core/ui/app_button.dart';
import '../../../../core/ui/app_form_host.dart';
import '../../../../core/ui/app_text_field.dart';
import '../../../../core/ui/submission_feedback.dart';
import '../../business_logic/cubit/member_form_cubit.dart';
import '../../business_logic/cubit/member_form_state.dart';
import '../../data/models/member.dart';

class MemberForm extends StatefulWidget {
  const MemberForm({super.key});
  static Future<Member?> show(
    BuildContext context,
    GymRepository repository, {
    Member? member,
  }) => AppFormHost.show<Member>(
    context,
    title: member == null ? 'إضافة عضو' : 'تعديل العضو',
    builder: (_) => BlocProvider(
      create: (_) => MemberFormCubit(repository, original: member),
      child: const MemberForm(),
    ),
  );
  @override
  State<MemberForm> createState() => _MemberFormState();
}

class _MemberFormState extends State<MemberForm> {
  late final TextEditingController _name;
  late final TextEditingController _phone;
  @override
  void initState() {
    super.initState();
    final state = context.read<MemberFormCubit>().state;
    _name = TextEditingController(text: state.name);
    _phone = TextEditingController(text: state.phone);
  }

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      BlocConsumer<MemberFormCubit, MemberFormState>(
        listenWhen: (a, b) => !a.submission.applied && b.submission.applied,
        listener: (context, state) =>
            Navigator.of(context).pop(context.read<MemberFormCubit>().result),
        builder: (context, state) {
          final cubit = context.read<MemberFormCubit>();
          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AppTextField(
                label: 'اسم العضو',
                controller: _name,
                onChanged: cubit.nameChanged,
              ),
              const SizedBox(height: 16),
              AppTextField(
                label: 'رقم الموبايل (اختياري)',
                controller: _phone,
                textDirection: TextDirection.ltr,
                keyboardType: TextInputType.phone,
                onChanged: cubit.phoneChanged,
              ),
              SubmissionFeedback(state: state.submission),
              const SizedBox(height: 16),
              AppButton(
                label: 'حفظ',
                busy: state.submission.busy,
                onPressed: cubit.submit,
              ),
            ],
          );
        },
      );
}
