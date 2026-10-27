import 'package:flutter_test/flutter_test.dart';
import 'package:gymk_app/core/data/mutation_registry.dart';
import 'package:gymk_app/core/errors/app_failure.dart';
import 'package:gymk_app/features/auth/business_logic/cubit/mutation_feedback_cubit.dart';

import '../../support/fake_gym_repository.dart';

void main() {
  test(
    'feedback preserves affected names and immutable pending/error projections',
    () async {
      final repository = FakeGymRepository();
      final cubit = MutationFeedbackCubit(repository);
      repository.emitMutations(const [
        MutationNotice(
          id: 'one',
          target: 'member',
          targetName: 'أحمد',
          action: MutationAction.saveMember,
          stage: MutationStage.locallyApplied,
          failure: null,
        ),
      ]);
      final old = cubit.state;
      repository.emitMutations(const [
        MutationNotice(
          id: 'one',
          target: 'member',
          targetName: 'أحمد',
          action: MutationAction.saveMember,
          stage: MutationStage.rejected,
          failure: AppFailure(FailureKind.permission),
        ),
      ]);
      expect(old.pending, hasLength(1));
      expect(cubit.state.pending, isEmpty);
      expect(cubit.state.rejected.single.targetName, 'أحمد');
      cubit.dismiss('one');
      expect(cubit.state.rejected, isEmpty);
      await cubit.close();
      expect(repository.mutationSource.hasListener, isFalse);
      await repository.close();
    },
  );
}
