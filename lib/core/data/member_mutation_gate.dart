import 'mutation_registry.dart';
import '../errors/app_failure.dart';

/// Prevents competing local mutations for one member. The lock ends at local
/// application/failure, so normal offline work never waits for cloud recovery.
final class MemberMutationGate {
  final _busy = <String>{};

  MutationHandle run(String memberId, MutationHandle Function() operation) {
    if (!_busy.add(memberId)) {
      throw const AppFailure(FailureKind.conflict, code: 'member-busy');
    }
    try {
      final handle = operation();
      handle.localSettlement.then((_) => _busy.remove(memberId));
      return handle;
    } catch (_) {
      _busy.remove(memberId);
      rethrow;
    }
  }
}
