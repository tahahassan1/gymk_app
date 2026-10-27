import '../../../../core/data/mutation_registry.dart';
import '../../../../core/errors/app_failure.dart';

final class MutationFeedbackState {
  MutationFeedbackState(List<MutationNotice> notices, {this.failure})
    : notices = List.unmodifiable(notices),
      pending = List.unmodifiable(notices.where((notice) => notice.pending)),
      rejected = List.unmodifiable(
        notices.where((notice) => notice.stage == MutationStage.rejected),
      );

  final List<MutationNotice> notices;
  final List<MutationNotice> pending;
  final List<MutationNotice> rejected;
  final AppFailure? failure;
}
