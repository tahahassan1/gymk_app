import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../app/session/data/repositories/gym_repository.dart';
import '../../../../core/data/mutation_registry.dart';
import '../../../../core/data/read_snapshot.dart';
import '../../../../core/data/submission_state.dart';
import '../../../../core/errors/app_failure.dart';
import '../../../../core/money/amount_policy.dart';
import '../../data/models/gym_settings.dart';
import 'settings_state.dart';

final class SettingsCubit extends Cubit<SettingsState> {
  SettingsCubit(this.repository)
    : operationId = repository.newId(),
      super(const SettingsState()) {
    _mutations = repository.mutationChanges.listen(
      (_) {
        final handle = _handle;
        if (handle?.stage == MutationStage.rejected &&
            state.submission.applied &&
            _intent != null) {
          _baseline = _beforeIntent;
          _publish(
            name: _intent!.gymName,
            subscriptionPrice: _intent!.subscriptionPrice.toString(),
            dropinPrice: _intent!.dropinPrice.toString(),
            dirty: true,
            submission: SubmissionState(failure: handle!.failure),
          );
        }
      },
      onError: (Object error) {
        _readFailure = error is AppFailure
            ? error
            : const AppFailure(FailureKind.unknown);
        _publish();
      },
    );
    _settings = repository.watchSettings().listen(
      (snapshot) {
        if (isClosed) return;
        _snapshot = snapshot;
        _readFailure = null;
        if (snapshot.data == null) {
          _readFailure = const AppFailure(FailureKind.notFound);
        }
        if (!state.dirty && !state.submission.busy && snapshot.data != null) {
          _load(snapshot.data!);
        } else {
          _publish();
        }
      },
      onError: (Object error) {
        _snapshot = _snapshot?.asIncomplete();
        _readFailure = error is AppFailure
            ? error
            : const AppFailure(FailureKind.unknown);
        _publish();
      },
    );
  }
  final GymRepository repository;
  String operationId;
  late final StreamSubscription<Object?> _settings, _mutations;
  ReadSnapshot<GymSettings?>? _snapshot;
  GymSettings? _baseline, _intent, _beforeIntent;
  AppFailure? _readFailure;
  MutationHandle? _handle;
  bool get _editable =>
      !state.submission.busy &&
      (state.submission.applied || !(_handle?.pending ?? false));
  bool get hasKnownPendingChanges =>
      repository.mutations.any((m) => m.pending) ||
      (repository.currentMembers?.hasPendingWrites ?? false) ||
      (repository.currentSubscriptions?.hasPendingWrites ?? false) ||
      (repository.currentDropins?.hasPendingWrites ?? false) ||
      (repository.currentSettings?.hasPendingWrites ?? false);
  void _publish({
    String? name,
    String? subscriptionPrice,
    String? dropinPrice,
    bool? dirty,
    SubmissionState? submission,
  }) {
    if (isClosed) return;
    emit(
      SettingsState(
        name: name ?? state.name,
        subscriptionPrice: subscriptionPrice ?? state.subscriptionPrice,
        dropinPrice: dropinPrice ?? state.dropinPrice,
        ready: _snapshot != null,
        complete: _snapshot?.isComplete ?? false,
        dirty: dirty ?? state.dirty,
        readFailure: _readFailure,
        submission: submission ?? state.submission,
      ),
    );
  }

  void _load(GymSettings value) {
    _baseline = value;
    _publish(
      name: value.gymName,
      subscriptionPrice: value.subscriptionPrice.toString(),
      dropinPrice: value.dropinPrice.toString(),
      dirty: false,
    );
  }

  void _newEdit() {
    if (state.submission.applied) {
      operationId = repository.newId();
      _handle = null;
      _intent = null;
    }
  }

  void nameChanged(String value) {
    if (!_editable) return;
    _newEdit();
    _publish(name: value, dirty: true, submission: const SubmissionState());
  }

  void subscriptionPriceChanged(String value) {
    if (!_editable) return;
    _newEdit();
    _publish(
      subscriptionPrice: value,
      dirty: true,
      submission: const SubmissionState(),
    );
  }

  void dropinPriceChanged(String value) {
    if (!_editable) return;
    _newEdit();
    _publish(
      dropinPrice: value,
      dirty: true,
      submission: const SubmissionState(),
    );
  }

  void reloadDraft() {
    if (!_editable || _snapshot?.data == null) return;
    _handle = null;
    _intent = null;
    operationId = repository.newId();
    _load(_snapshot!.data!);
    _publish(submission: const SubmissionState());
  }

  Future<void> retry() => repository.retryReads();
  static bool _same(GymSettings a, GymSettings b) =>
      a.gymName == b.gymName &&
      a.subscriptionPrice == b.subscriptionPrice &&
      a.dropinPrice == b.dropinPrice;
  Future<void> submit() async {
    if (state.submission.busy || (state.submission.applied && !state.dirty)) {
      return;
    }
    _publish(submission: const SubmissionState(busy: true));
    try {
      if (!(_handle?.pending ?? false)) {
        final latest = repository.currentSettings?.data;
        if (latest == null || _baseline == null) {
          throw const AppFailure(FailureKind.incompleteData);
        }
        if (!_same(latest, _baseline!)) {
          throw const AppFailure(FailureKind.conflict, code: 'stale-settings');
        }
        _beforeIntent = _baseline;
        final subscription = AmountPolicy.parse(
          state.subscriptionPrice,
          purpose: AmountPurpose.defaultPrice,
        );
        final dropin = AmountPolicy.parse(
          state.dropinPrice,
          purpose: AmountPurpose.defaultPrice,
        );
        if (subscription is! ParsedAmount || dropin is! ParsedAmount) {
          throw const AppFailure(FailureKind.validation, code: 'default-price');
        }
        _intent = GymSettings(
          gymName: state.name,
          subscriptionPrice: subscription.minorUnits,
          dropinPrice: dropin.minorUnits,
        );
      }
      _handle = repository.saveSettings(_intent!, operationId: operationId);
      final failure = await _handle!.localResult;
      if (isClosed) return;
      if (failure == null) {
        _baseline = _intent;
        _publish(
          name: _intent!.gymName,
          subscriptionPrice: _intent!.subscriptionPrice.toString(),
          dropinPrice: _intent!.dropinPrice.toString(),
          dirty: false,
          submission: const SubmissionState(applied: true),
        );
      } else {
        _publish(submission: SubmissionState(failure: failure));
      }
    } on AppFailure catch (failure) {
      _publish(submission: SubmissionState(failure: failure));
    }
  }

  @override
  Future<void> close() async {
    await _settings.cancel();
    await _mutations.cancel();
    return super.close();
  }
}
