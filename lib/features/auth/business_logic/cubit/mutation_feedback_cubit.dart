import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../app/session/data/repositories/gym_repository.dart';
import '../../../../core/errors/app_failure.dart';
import 'mutation_feedback_state.dart';

final class MutationFeedbackCubit extends Cubit<MutationFeedbackState> {
  MutationFeedbackCubit(this.repository)
    : super(MutationFeedbackState(repository.mutations)) {
    _subscription = repository.mutationChanges.listen(
      (notices) {
        if (!isClosed) emit(MutationFeedbackState(notices));
      },
      onError: (Object error) {
        if (!isClosed) {
          emit(
            MutationFeedbackState(
              state.notices,
              failure: error is AppFailure
                  ? error
                  : const AppFailure(FailureKind.unknown),
            ),
          );
        }
      },
    );
  }

  final GymRepository repository;
  late final StreamSubscription<Object?> _subscription;
  void dismiss(String id) => repository.dismissFailure(id);

  @override
  Future<void> close() async {
    final stateClosed = super.close();
    await _subscription.cancel();
    return stateClosed;
  }
}
