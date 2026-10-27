import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../app/session/data/repositories/gym_repository.dart';
import '../../../../core/theme/app_geometry.dart';
import '../../../../core/ui/app_loading_state.dart';
import '../../../../core/ui/read_notice.dart';
import '../../../members/business_logic/cubit/member_details_cubit.dart';
import '../../../members/business_logic/cubit/member_details_state.dart';
import '../../../members/business_logic/cubit/members_cubit.dart';
import '../../business_logic/cubit/subscription_form_cubit.dart';
import '../widgets/subscription_form.dart';

/// Direct route and modal entry share the same form and command.
class SubscriptionRouteView extends StatelessWidget {
  const SubscriptionRouteView({super.key, required this.memberId});
  final String memberId;
  @override
  Widget build(BuildContext context) => BlocProvider(
    key: ValueKey(memberId),
    create: (_) => MemberDetailsCubit(
      repository: context.read<GymRepository>(),
      policy: context.read<MembersCubit>().policy,
      memberId: memberId,
    ),
    child: BlocBuilder<MemberDetailsCubit, MemberDetailsState>(
      builder: (context, state) {
        if (!state.ready && state.failure == null) {
          return const AppLoadingState();
        }
        final member = state.member;
        if (member == null) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                const Text('العضو مش موجود في البيانات المتاحة'),
                ReadNotice(
                  complete: state.complete,
                  failure: state.failure,
                  onRetry: context.read<MemberDetailsCubit>().retry,
                ),
              ],
            ),
          );
        }
        final details = context.read<MemberDetailsCubit>();
        return Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: AppGeometry.formWidth),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: BlocProvider(
                create: (_) => SubscriptionFormCubit(
                  repository: details.repository,
                  policy: details.policy,
                  memberId: memberId,
                ),
                child: SubscriptionForm(member: member),
              ),
            ),
          ),
        );
      },
    ),
  );
}
