import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../app/session/data/repositories/gym_repository.dart';
import '../../../../core/data/mutation_registry.dart';
import '../../../../core/data/submission_state.dart';
import '../../../../core/errors/app_failure.dart';
import '../../../../core/money/amount_policy.dart';
import '../../../../core/time/date_only.dart';
import '../../data/models/subscription_record.dart';
import '../policies/coverage_period.dart';
import '../policies/subscription_policy.dart';
import 'subscription_form_state.dart';

final class SubscriptionFormCubit extends Cubit<SubscriptionFormState> {
  SubscriptionFormCubit({
    required this.repository,
    required this.policy,
    required this.memberId,
    this.original,
  }) : id = original?.id ?? repository.newId(),
       operationId = repository.newId(),
       super(
         SubscriptionFormState(
           amount:
               (original?.amount ??
                       repository.currentSettings?.data?.subscriptionPrice ??
                       0)
                   .toString(),
           preview: policy.previewRenewal(
             _periods(repository, memberId, original?.id),
             manualStart:
                 original != null &&
                     !original.startDate.isAfter(policy.clock.today())
                 ? original.startDate
                 : null,
           ),
         ),
       ) {
    if (original != null) _setEditPreview();
  }
  final GymRepository repository;
  final SubscriptionPolicy policy;
  final String memberId;
  final SubscriptionRecord? original;
  final String id;
  final String operationId;
  SubscriptionRecord? _intent;
  MutationHandle? _handle;
  bool get _editable =>
      !state.submission.busy &&
      !state.submission.applied &&
      !(_handle?.pending ?? false);
  static Iterable<CoveragePeriod> _periods(
    GymRepository repository,
    String memberId,
    String? excluded,
  ) => (repository.currentSubscriptions?.data ?? const <SubscriptionRecord>[])
      .where((r) => r.memberId == memberId && r.id != excluded)
      .map((r) => CoveragePeriod(start: r.startDate, end: r.endDate));

  void _setEditPreview() {
    // An unchanged automatic future start remains valid for amount corrections.
    final record = original!;
    emit(
      SubscriptionFormState(
        amount: state.amount,
        preview: policy.previewCorrection(
          _periods(repository, memberId, record.id),
          start: record.startDate,
          previous: CoveragePeriod(
            start: record.startDate,
            end: record.endDate,
          ),
        ),
        manualStart: null,
      ),
    );
  }

  void amountChanged(String value) {
    if (_editable) {
      emit(
        SubscriptionFormState(
          amount: value,
          preview: state.preview,
          manualStart: state.manualStart,
          stale: state.stale,
        ),
      );
    }
  }

  void startChanged(DateOnly start) {
    if (!_editable) return;
    if (!policy.isManualStartAllowed(start)) {
      _fail(const AppFailure(FailureKind.validation, code: 'future-start'));
      return;
    }
    final preview = original == null
        ? policy.previewRenewal(
            _periods(repository, memberId, null),
            manualStart: start,
          )
        : policy.previewCorrection(
            _periods(repository, memberId, id),
            start: start,
            previous: CoveragePeriod(
              start: original!.startDate,
              end: original!.endDate,
            ),
          );
    emit(
      SubscriptionFormState(
        amount: state.amount,
        preview: preview,
        manualStart: start,
      ),
    );
  }

  void automaticStart() {
    if (!_editable || original != null) return;
    emit(
      SubscriptionFormState(
        amount: state.amount,
        preview: policy.previewRenewal(_periods(repository, memberId, null)),
      ),
    );
  }

  void _fail(AppFailure failure) {
    if (!isClosed) {
      emit(
        SubscriptionFormState(
          amount: state.amount,
          preview: state.preview,
          manualStart: state.manualStart,
          stale: state.stale,
          submission: SubmissionState(failure: failure),
        ),
      );
    }
  }

  Future<void> submit() async {
    if (state.submission.busy || state.submission.applied) return;
    emit(
      SubscriptionFormState(
        amount: state.amount,
        preview: state.preview,
        manualStart: state.manualStart,
        submission: const SubmissionState(busy: true),
      ),
    );
    try {
      if (!(_handle?.pending ?? false)) {
        if (!(repository.currentMembers?.data.any((m) => m.id == memberId) ??
            false)) {
          throw const AppFailure(FailureKind.notFound);
        }
        if (repository.currentSubscriptions == null) {
          throw const AppFailure(FailureKind.incompleteData);
        }
        if (state.manualStart != null &&
            !policy.isManualStartAllowed(state.manualStart!)) {
          throw const AppFailure(FailureKind.validation, code: 'future-start');
        }
        final amount = AmountPolicy.parse(
          state.amount,
          purpose: AmountPurpose.paymentRecord,
        );
        if (amount is! ParsedAmount) {
          throw const AppFailure(FailureKind.validation, code: 'amount');
        }
        if (original case final old?) {
          final current = repository.currentSubscriptions!.data
              .where((r) => r.id == id)
              .firstOrNull;
          if (current == null) throw const AppFailure(FailureKind.notFound);
          if (current.amount != old.amount ||
              current.startDate != old.startDate) {
            throw const AppFailure(FailureKind.conflict, code: 'stale-edit');
          }
        }
        final preview = original == null
            ? policy.previewRenewal(
                _periods(repository, memberId, null),
                manualStart: state.manualStart,
              )
            : policy.previewCorrection(
                _periods(repository, memberId, id),
                start: state.manualStart ?? original!.startDate,
                previous: CoveragePeriod(
                  start: original!.startDate,
                  end: original!.endDate,
                ),
              );
        final old = state.preview;
        if (old.asOf != preview.asOf ||
            old.currentExpiry != preview.currentExpiry ||
            old.period.start != preview.period.start ||
            old.resultingCurrentExpiry != preview.resultingCurrentExpiry) {
          emit(
            SubscriptionFormState(
              amount: state.amount,
              preview: preview,
              manualStart: state.manualStart,
              stale: true,
            ),
          );
          return;
        }
        _intent =
            original?.edit(
              amount: amount.minorUnits,
              startDate: preview.period.start,
            ) ??
            SubscriptionRecord(
              id: id,
              memberId: memberId,
              startDate: preview.period.start,
              endDate: preview.period.end,
              amount: amount.minorUnits,
              paidAt: preview.asOf,
            );
      }
      _handle = repository.saveSubscription(_intent!, operationId: operationId);
      final failure = await _handle!.localResult;
      if (!isClosed) {
        emit(
          SubscriptionFormState(
            amount: state.amount,
            preview: state.preview,
            manualStart: state.manualStart,
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
}
