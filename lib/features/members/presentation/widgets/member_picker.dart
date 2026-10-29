import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../app/session/data/repositories/gym_repository.dart';
import '../../../../core/ui/app_button.dart';
import '../../../../core/ui/app_form_host.dart';
import '../../../../core/ui/app_text_field.dart';
import '../../../../core/ui/read_notice.dart';
import '../../business_logic/cubit/members_cubit.dart';
import '../../business_logic/cubit/members_state.dart';
import '../../../subscriptions/business_logic/policies/subscription_policy.dart';
import '../../data/models/member.dart';
import 'member_form.dart';

class MemberPicker extends StatefulWidget {
  const MemberPicker({super.key, required this.repository});
  final GymRepository repository;
  static Future<Member?> show(
    BuildContext context,
    GymRepository repository,
    SubscriptionPolicy policy,
  ) => AppFormHost.show<Member>(
    context,
    title: 'اختار العضو',
    builder: (_) => BlocProvider(
      create: (_) => MembersCubit(repository: repository, policy: policy),
      child: MemberPicker(repository: repository),
    ),
  );
  @override
  State<MemberPicker> createState() => _MemberPickerState();
}

class _MemberPickerState extends State<MemberPicker> {
  final _search = TextEditingController();
  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => BlocBuilder<MembersCubit, MembersState>(
    builder: (context, state) => Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppTextField(
          label: 'ابحث بالاسم',
          controller: _search,
          onChanged: context.read<MembersCubit>().searchChanged,
        ),
        ReadNotice(
          complete: state.membersComplete,
          failure: state.membersFailure,
        ),
        const SizedBox(height: 8),
        AppButton(
          label: 'إضافة عضو جديد',
          variant: AppButtonVariant.secondary,
          onPressed: () async {
            final member = await MemberForm.show(context, widget.repository);
            if (context.mounted && member != null) {
              Navigator.of(context).pop(member);
            }
          },
        ),
        if (state.rows.isEmpty)
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text('مفيش أعضاء مطابقين في البيانات المتاحة'),
          ),
        SizedBox(
          height: 240,
          child: ListView.builder(
            itemCount: state.rows.length,
            itemBuilder: (context, index) {
              final member = state.rows[index].member;
              return ListTile(
                title: Tooltip(
                  message: member.name,
                  child: Text(
                    member.name,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                onTap: () => Navigator.of(context).pop(member),
              );
            },
          ),
        ),
      ],
    ),
  );
}
