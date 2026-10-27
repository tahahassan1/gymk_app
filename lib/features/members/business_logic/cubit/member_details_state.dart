import '../../../../core/data/submission_state.dart';
import '../../../../core/errors/app_failure.dart';
import '../../../subscriptions/business_logic/policies/subscription_policy.dart';
import '../../../subscriptions/data/models/subscription_record.dart';
import '../../data/models/member.dart';

final class MemberDetailsState {
  const MemberDetailsState({
    this.member,
    this.history = const [],
    this.coverage,
    this.ready = false,
    this.complete = false,
    this.failure,
    this.submission = const SubmissionState(),
  });
  final Member? member;
  final List<SubscriptionRecord> history;
  final MembershipAssessment? coverage;
  final bool ready;
  final bool complete;
  final AppFailure? failure;
  final SubmissionState submission;
}
