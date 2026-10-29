import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../app/session/data/repositories/gym_repository.dart';
import '../../../../core/data/mutation_registry.dart';
import '../../../../core/data/submission_state.dart';
import '../../../../core/errors/app_failure.dart';
import '../../data/models/member.dart';
import 'member_form_state.dart';

final class MemberFormCubit extends Cubit<MemberFormState> {
  MemberFormCubit(this.repository, {this.original, DateTime Function()? now})
    : _now = now ?? DateTime.now,
      id = original?.id ?? repository.newId(),
      operationId = repository.newId(),
      super(
        MemberFormState(
          name: original?.name ?? '',
          phone: original?.phone ?? '',
        ),
      );
  final GymRepository repository;
  final Member? original;
  final DateTime Function() _now;
  final String id;
  final String operationId;
  Member? result;
  Member? _intent;
  MutationHandle? _handle;
  bool get _hasSubmittedIntent =>
      _handle != null && _handle!.stage != MutationStage.rejected;
  bool get _editable =>
      !state.submission.busy &&
      !state.submission.applied &&
      !_hasSubmittedIntent;
  bool get canEdit => _editable;
  void nameChanged(String value) {
    if (_editable) emit(MemberFormState(name: value, phone: state.phone));
  }

  void phoneChanged(String value) {
    if (_editable) emit(MemberFormState(name: state.name, phone: value));
  }

  Future<void> submit() async {
    if (state.submission.busy || state.submission.applied) return;
    emit(
      MemberFormState(
        name: state.name,
        phone: state.phone,
        submission: const SubmissionState(busy: true),
      ),
    );
    try {
      if (!_hasSubmittedIntent) {
        if (original != null &&
            !(repository.currentMembers?.data.any((m) => m.id == id) ??
                false)) {
          throw const AppFailure(FailureKind.notFound);
        }
        if (original case final old?) {
          final current = repository.currentMembers!.data.firstWhere(
            (m) => m.id == id,
          );
          if (current.name != old.name || current.phone != old.phone) {
            throw const AppFailure(FailureKind.conflict, code: 'stale-edit');
          }
        }
        _intent = Member(
          id: id,
          name: state.name,
          phone: state.phone,
          createdAt: original?.createdAt ?? _intent?.createdAt ?? _now(),
        );
      }
      if (!_hasSubmittedIntent) {
        _handle = repository.saveMember(_intent!, operationId: operationId);
      }
      final failure = await _handle!.localResult;
      if (isClosed) return;
      if (failure == null) result = _intent;
      emit(
        MemberFormState(
          name: state.name,
          phone: state.phone,
          submission: SubmissionState(
            applied: failure == null,
            failure: failure,
          ),
        ),
      );
    } on AppFailure catch (failure) {
      if (!isClosed) {
        emit(
          MemberFormState(
            name: state.name,
            phone: state.phone,
            submission: SubmissionState(failure: failure),
          ),
        );
      }
    }
  }
}
