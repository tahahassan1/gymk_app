import '../../../../core/data/submission_state.dart';
import '../../../../core/errors/app_failure.dart';
import '../../../../core/time/date_only.dart';
import '../../data/models/dropin.dart';

final class DropinsState {
  const DropinsState({
    required this.day,
    required this.today,
    this.rows = const [],
    this.ready = false,
    this.complete = false,
    this.pending = false,
    this.failure,
    this.submission = const SubmissionState(),
  });
  final DateOnly day, today;
  final List<Dropin> rows;
  final bool ready, complete, pending;
  final AppFailure? failure;
  final SubmissionState submission;
}
