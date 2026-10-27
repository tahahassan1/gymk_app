import '../../../../core/data/submission_state.dart';
import '../../../../core/errors/app_failure.dart';

final class SettingsState {
  const SettingsState({
    this.name = '',
    this.subscriptionPrice = '',
    this.dropinPrice = '',
    this.ready = false,
    this.complete = false,
    this.dirty = false,
    this.readFailure,
    this.submission = const SubmissionState(),
  });
  final String name, subscriptionPrice, dropinPrice;
  final bool ready, complete, dirty;
  final AppFailure? readFailure;
  final SubmissionState submission;
}
