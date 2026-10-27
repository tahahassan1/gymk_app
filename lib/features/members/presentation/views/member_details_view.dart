import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/app_routes.dart';
import '../../../../app/session/data/repositories/gym_repository.dart';
import '../../../../core/ui/adaptive/app_layout_mode.dart';
import '../../../../core/ui/adaptive/app_layout_scope.dart';
import '../../../../core/ui/app_deletion_dialog.dart';
import '../../../../core/ui/app_loading_state.dart';
import '../../../../core/ui/date_resume_observer.dart';
import '../../../../core/ui/read_notice.dart';
import '../../business_logic/cubit/member_details_cubit.dart';
import '../../business_logic/cubit/member_details_state.dart';
import '../../business_logic/cubit/members_cubit.dart';
import '../../../subscriptions/presentation/widgets/subscription_form.dart';
import '../layouts/member_details_mobile_layout.dart';
import '../layouts/member_details_tablet_layout.dart';
import '../widgets/member_form.dart';
import '../widgets/member_summary.dart';
import '../widgets/subscription_history_row.dart';

class MemberDetailsView extends StatelessWidget {
  const MemberDetailsView({super.key, required this.memberId});
  final String memberId;
  @override
  Widget build(BuildContext context) => BlocProvider(
    key: ValueKey(memberId),
    create: (_) => MemberDetailsCubit(
      repository: context.read<GymRepository>(),
      policy: context.read<MembersCubit>().policy,
      memberId: memberId,
    ),
    child: Builder(
      builder: (context) {
        final cubit = context.read<MemberDetailsCubit>();
        final repository = cubit.repository;
        return DateResumeObserver(
          onResume: cubit.refreshDate,
          child: BlocBuilder<MemberDetailsCubit, MemberDetailsState>(
            builder: (context, state) {
              if (!state.ready && state.failure == null) {
                return const AppLoadingState();
              }
              if (state.member == null) {
                return SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      Text(
                        state.complete
                            ? 'العضو مش موجود'
                            : 'العضو مش موجود في البيانات المتاحة',
                      ),
                      ReadNotice(
                        complete: state.complete,
                        failure: state.failure,
                        onRetry: cubit.retry,
                      ),
                      TextButton(
                        onPressed: () => context.go(AppRoutes.members),
                        child: const Text('رجوع للأعضاء'),
                      ),
                    ],
                  ),
                );
              }
              final member = state.member!;
              final summary = MemberSummary(
                state: state,
                onBack: () => context.go(AppRoutes.members),
                onRetry: cubit.retry,
                onRenew: () => SubscriptionForm.show(
                  context,
                  repository,
                  cubit.policy,
                  member,
                ),
                onEdit: () =>
                    MemberForm.show(context, repository, member: member),
                onDelete: () async {
                  final confirmed = await AppDeletionDialog.confirm(
                    context,
                    title: 'حذف ${member.name}؟',
                    message: 'هيتم حذف العضو وكل اشتراكاته نهائيًا، وهتتغير المتحصلات التاريخية. الحصص الفردية مش هتتغير.',
                  );
                  if (confirmed && context.mounted) await cubit.deleteMember();
                },
              );
              final history = state.history.isEmpty
                  ? SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(
                          state.complete
                              ? 'مفيش اشتراكات مسجلة'
                              : 'مفيش اشتراكات في السجل المتاح',
                        ),
                      ),
                    )
                  : SliverList.separated(
                      itemCount: state.history.length,
                      separatorBuilder: (_, _) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final record = state.history[index];
                        return SubscriptionHistoryRow(
                          record: record,
                          onEdit: state.submission.busy
                              ? null
                              : () => SubscriptionForm.show(
                                  context,
                                  repository,
                                  cubit.policy,
                                  member,
                                  record: record,
                                ),
                          onDelete: state.submission.busy
                              ? null
                              : () async {
                                  final confirmed =
                                      await AppDeletionDialog.confirm(
                                        context,
                                        title: 'حذف الاشتراك؟',
                                        message: 'الاشتراك هيتحذف نهائيًا. حالة العضو والمتحصلات هيتحسبوا من السجلات الباقية من غير تغيير تواريخها.',
                                      );
                                  if (confirmed && context.mounted) {
                                    await cubit.deleteSubscription(record);
                                  }
                                },
                        );
                      },
                    );
              return AppLayoutScope.of(context) == AppLayoutMode.mobile
                  ? MemberDetailsMobileLayout(
                      summary: summary,
                      history: history,
                    )
                  : MemberDetailsTabletLayout(
                      summary: summary,
                      history: history,
                    );
            },
          ),
        );
      },
    ),
  );
}
