import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../app/session/data/repositories/gym_repository.dart';
import '../../../../core/data/mutation_registry.dart';
import '../../../../core/data/submission_state.dart';
import '../../../../core/errors/app_failure.dart';
import '../../../../core/money/amount_policy.dart';
import '../../../../core/time/clock.dart';
import '../../../../core/time/date_only.dart';
import '../../data/models/dropin.dart';
import 'dropin_form_state.dart';

final class DropinFormCubit extends Cubit<DropinFormState> {
  DropinFormCubit({
    required this.repository,
    required this.clock,
    this.original,
  }) : id = original?.id ?? repository.newId(),
       operationId = repository.newId(),
       super(
         DropinFormState(
           date: original?.date ?? clock.today(),
           amount:
               (original?.amount ??
                       repository.currentSettings?.data?.dropinPrice ??
                       0)
                   .toString(),
           name: original?.name ?? '',
         ),
       ) {
    _settings = repository.watchSettings().listen(
      (snapshot) {
        _defaultsFailure = null;
        if (state.defaultsFailure != null) _publish(state);
        if (isClosed ||
            original != null ||
            _dirty ||
            _intent != null ||
            state.submission.busy ||
            state.submission.applied) {
          return;
        }
        final price = snapshot.data?.dropinPrice;
        if (price != null) {
          _publish(
            DropinFormState(
              date: state.date,
              amount: price.toString(),
              name: state.name,
              staleDate: state.staleDate,
            ),
          );
        }
      },
      onError: (Object error) {
        _defaultsFailure = error is AppFailure
            ? error
            : const AppFailure(FailureKind.unknown);
        if (!isClosed) _publish(state);
      },
    );
  }
  final GymRepository repository;
  final Clock clock;
  final Dropin? original;
  String id, operationId;
  late final StreamSubscription<Object?> _settings;
  AppFailure? _defaultsFailure;
  void _publish(DropinFormState next) {
    if (isClosed) return;
    emit(
      DropinFormState(
        date: next.date,
        amount: next.amount,
        name: next.name,
        staleDate: next.staleDate,
        submission: next.submission,
        defaultsFailure: _defaultsFailure,
      ),
    );
  }

  bool _dirty = false;
  Dropin? _intent;
  MutationHandle? _handle;
  bool get _editable =>
      !state.submission.busy &&
      !state.submission.applied &&
      !(_handle?.pending ?? false);
  void nameChanged(String value) {
    if (!_editable) return;
    _dirty = true;
    _publish(
      DropinFormState(
        date: state.date,
        amount: state.amount,
        name: value,
        staleDate: state.staleDate,
      ),
    );
  }

  void amountChanged(String value) {
    if (!_editable) return;
    _dirty = true;
    _publish(
      DropinFormState(
        date: state.date,
        amount: value,
        name: state.name,
        staleDate: state.staleDate,
      ),
    );
  }

  void dateChanged(DateOnly value) {
    if (!_editable || original == null) return;
    _dirty = true;
    _publish(
      DropinFormState(date: value, amount: state.amount, name: state.name),
    );
  }

  void refreshDate() {
    if (!_editable || original != null || state.date == clock.today()) return;
    _publish(
      DropinFormState(
        date: clock.today(),
        amount: state.amount,
        name: state.name,
        staleDate: true,
      ),
    );
  }

  void startNext() {
    if (!state.submission.applied || original != null) return;
    id = repository.newId();
    operationId = repository.newId();
    _handle = null;
    _intent = null;
    _dirty = false;
    _publish(
      DropinFormState(
        date: clock.today(),
        amount: (repository.currentSettings?.data?.dropinPrice ?? 0).toString(),
      ),
    );
  }

  void _fail(AppFailure failure) {
    if (!isClosed) {
      _publish(
        DropinFormState(
          date: state.date,
          amount: state.amount,
          name: state.name,
          staleDate: state.staleDate,
          submission: SubmissionState(failure: failure),
        ),
      );
    }
  }

  Future<void> submit() async {
    if (state.submission.busy || state.submission.applied) return;
    if (original == null &&
        !(_handle?.pending ?? false) &&
        state.date != clock.today()) {
      refreshDate();
      return;
    }
    _publish(
      DropinFormState(
        date: state.date,
        amount: state.amount,
        name: state.name,
        submission: const SubmissionState(busy: true),
      ),
    );
    try {
      if (!(_handle?.pending ?? false)) {
        final parsed = AmountPolicy.parse(
          state.amount,
          purpose: AmountPurpose.paymentRecord,
        );
        if (parsed is! ParsedAmount) {
          throw const AppFailure(FailureKind.validation, code: 'amount');
        }
        if (original case final old?) {
          final current = repository.currentDropins?.data
              .where((r) => r.id == id)
              .firstOrNull;
          if (current == null) throw const AppFailure(FailureKind.notFound);
          if (current.amount != old.amount ||
              current.name != old.name ||
              current.date != old.date) {
            throw const AppFailure(FailureKind.conflict, code: 'stale-edit');
          }
        }
        _intent = Dropin(
          id: id,
          name: state.name,
          amount: parsed.minorUnits,
          date: original == null ? clock.today() : state.date,
        );
      }
      _handle = repository.saveDropin(_intent!, operationId: operationId);
      final failure = await _handle!.localResult;
      if (!isClosed) {
        _publish(
          DropinFormState(
            date: state.date,
            amount: state.amount,
            name: state.name,
            submission: SubmissionState(
              applied: failure == null,
              failure: failure,
            ),
          ),
        );
      }
    } on AppFailure catch (failure) {
      _fail(failure);
    }
  }

  @override
  Future<void> close() async {
    await _settings.cancel();
    return super.close();
  }
}
