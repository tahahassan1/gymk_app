import '../../../../app/session/data/repositories/gym_repository.dart';
import '../../../../core/data/mutation_registry.dart';
import '../../../../core/data/member_cascade_limit.dart';
import '../../../../core/errors/app_failure.dart';

/// A deliberately bounded single-device operation, never a split-batch cascade.
final class MemberDeletionCoordinator {
  const MemberDeletionCoordinator(this.repository);
  final GymRepository repository;
  static const maxSubscriptions = MemberCascadeLimit.subscriptions;

  MutationHandle delete(String memberId, {required String operationId}) {
    final members = repository.currentMembers;
    final history = repository.currentSubscriptions;
    if (members == null ||
        history == null ||
        !members.isComplete ||
        !history.isComplete) {
      throw const AppFailure(FailureKind.incompleteData);
    }
    if (!members.data.any((m) => m.id == memberId)) {
      throw const AppFailure(FailureKind.notFound);
    }
    final ids = history.data
        .where((r) => r.memberId == memberId)
        .map((r) => r.id)
        .toList(growable: false);
    if (ids.length > maxSubscriptions) {
      throw const AppFailure(FailureKind.tooLarge);
    }
    return repository.deleteMemberCascade(
      memberId,
      ids,
      operationId: operationId,
    );
  }
}
