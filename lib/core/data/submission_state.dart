import '../errors/app_failure.dart';

/// Local form completion only. Eventual cloud outcomes stay in the repository.
final class SubmissionState {
  const SubmissionState({
    this.busy = false,
    this.applied = false,
    this.failure,
  });
  final bool busy;
  final bool applied;
  final AppFailure? failure;
}
