import '../../../../core/data/submission_state.dart';

final class MemberFormState {
  const MemberFormState({
    this.name = '',
    this.phone = '',
    this.submission = const SubmissionState(),
  });
  final String name;
  final String phone;
  final SubmissionState submission;
}
