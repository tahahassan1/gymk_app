import '../../../../core/errors/app_failure.dart';
import '../../../subscriptions/business_logic/policies/subscription_policy.dart';
import '../../data/models/member.dart';

enum MemberFilter { all, active, expiringSoon, expired }

final class MemberRowData {
  const MemberRowData({required this.member, required this.coverage});
  final Member member;
  final MembershipAssessment coverage;
}

const _keep = Object();

final class MembersState {
  const MembersState({
    this.rows = const [],
    this.query = '',
    this.filter = MemberFilter.all,
    this.membersReady = false,
    this.coverageReady = false,
    this.membersComplete = false,
    this.coverageComplete = false,
    this.membersFailure,
    this.coverageFailure,
  });

  final List<MemberRowData> rows;
  final String query;
  final MemberFilter filter;
  final bool membersReady;
  final bool coverageReady;
  final bool membersComplete;
  final bool coverageComplete;
  final AppFailure? membersFailure;
  final AppFailure? coverageFailure;
  bool get initialLoading => !membersReady;
  bool get complete => membersComplete && coverageComplete;

  MembersState copyWith({
    List<MemberRowData>? rows,
    String? query,
    MemberFilter? filter,
    bool? membersReady,
    bool? coverageReady,
    bool? membersComplete,
    bool? coverageComplete,
    Object? membersFailure = _keep,
    Object? coverageFailure = _keep,
  }) => MembersState(
    rows: rows ?? this.rows,
    query: query ?? this.query,
    filter: filter ?? this.filter,
    membersReady: membersReady ?? this.membersReady,
    coverageReady: coverageReady ?? this.coverageReady,
    membersComplete: membersComplete ?? this.membersComplete,
    coverageComplete: coverageComplete ?? this.coverageComplete,
    membersFailure: identical(membersFailure, _keep)
        ? this.membersFailure
        : membersFailure as AppFailure?,
    coverageFailure: identical(coverageFailure, _keep)
        ? this.coverageFailure
        : coverageFailure as AppFailure?,
  );
}
