import '../../../../core/data/submission_state.dart';
import '../../../../core/time/date_only.dart';
import '../../../../core/errors/app_failure.dart';

final class DropinFormState {
  const DropinFormState({
    required this.date,
    required this.amount,
    this.name = '',
    this.staleDate = false,
    this.submission = const SubmissionState(),
    this.defaultsFailure,
  });
  final String name, amount;
  final DateOnly date;
  final bool staleDate;
  final SubmissionState submission;
  final AppFailure? defaultsFailure;
}
