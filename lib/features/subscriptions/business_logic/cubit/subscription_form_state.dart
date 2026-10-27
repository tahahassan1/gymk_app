import '../../../../core/data/submission_state.dart';
import '../../../../core/time/date_only.dart';
import '../policies/subscription_policy.dart';

final class SubscriptionFormState {
  const SubscriptionFormState({
    required this.amount,
    required this.preview,
    this.manualStart,
    this.stale = false,
    this.submission = const SubmissionState(),
  });
  final String amount;
  final RenewalPreview preview;
  final DateOnly? manualStart;
  final bool stale;
  final SubmissionState submission;
}
