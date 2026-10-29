import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/app_routes.dart';
import '../../../../app/session/data/repositories/gym_repository.dart';
import '../../../../core/ui/adaptive/app_layout_mode.dart';
import '../../../../core/ui/adaptive/app_layout_scope.dart';
import '../../../../core/ui/app_loading_state.dart';
import '../../../../core/ui/date_resume_observer.dart';
import '../../business_logic/cubit/members_cubit.dart';
import '../../business_logic/cubit/members_state.dart';
import '../../../subscriptions/presentation/widgets/subscription_form.dart';
import '../layouts/members_mobile_layout.dart';
import '../layouts/members_tablet_layout.dart';
import '../widgets/member_form.dart';
import '../widgets/member_picker.dart';
import '../widgets/member_row.dart';
import '../widgets/members_controls.dart';

class MembersView extends StatefulWidget {
  const MembersView({super.key});
  @override
  State<MembersView> createState() => _MembersViewState();
}

class _MembersViewState extends State<MembersView> {
  final _controlsKey = GlobalKey();
  final _search = TextEditingController();
  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<MembersCubit>();
    final repository = context.read<GymRepository>();
    return DateResumeObserver(
      onResume: cubit.refreshDate,
      child: BlocBuilder<MembersCubit, MembersState>(
        builder: (context, state) {
          final controls = MembersControls(
            key: _controlsKey,
            state: state,
            search: _search,
            onSearch: cubit.searchChanged,
            onFilter: cubit.filterChanged,
            onRetry: cubit.retry,
            onAdd: () => MemberForm.show(context, repository),
            onSubscribe: () async {
              final member = await MemberPicker.show(
                context,
                repository,
                cubit.policy,
              );
              if (context.mounted && member != null) {
                await SubscriptionForm.show(
                  context,
                  repository,
                  cubit.policy,
                  member,
                );
              }
            },
          );
          final Widget rows =
              state.initialLoading && state.membersFailure == null
              ? const SliverToBoxAdapter(child: AppLoadingState())
              : state.rows.isEmpty
              ? SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      state.query.isNotEmpty
                          ? 'مفيش أعضاء بالاسم ده'
                          : state.filter != MemberFilter.all
                          ? 'مفيش أعضاء بالحالة دي في البيانات المتاحة'
                          : state.membersComplete
                          ? 'لسه مفيش أعضاء'
                          : 'مفيش أعضاء في البيانات المتاحة على الجهاز',
                    ),
                  ),
                )
              : SliverList.separated(
                  itemCount: state.rows.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (context, index) => MemberRow(
                    row: state.rows[index],
                    coverageReady: state.coverageReady,
                    onTap: () => context.go(
                      '${AppRoutes.members}/${state.rows[index].member.id}',
                    ),
                  ),
                );
          return AppLayoutScope.of(context) == AppLayoutMode.mobile
              ? MembersMobileLayout(controls: controls, rows: rows)
              : MembersTabletLayout(controls: controls, rows: rows);
        },
      ),
    );
  }
}
