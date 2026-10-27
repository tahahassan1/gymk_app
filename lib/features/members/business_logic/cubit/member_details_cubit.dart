import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../app/session/data/repositories/gym_repository.dart';
import '../../../../core/data/mutation_registry.dart';
import '../../../../core/data/submission_state.dart';
import '../../../../core/errors/app_failure.dart';
import '../../../../core/time/local_date_timer.dart';
import '../../../subscriptions/business_logic/policies/coverage_period.dart';
import '../../../subscriptions/business_logic/policies/subscription_policy.dart';
import '../../../subscriptions/data/models/subscription_record.dart';
import '../policies/member_deletion_coordinator.dart';
import 'member_details_state.dart';

final class MemberDetailsCubit extends Cubit<MemberDetailsState> {
  MemberDetailsCubit({
    required this.repository,
    required this.policy,
    required this.memberId,
  }) : super(const MemberDetailsState()) {
    _timer = LocalDateTimer(refreshDate);
    _members = repository.watchMembers().listen(
      (_) {
        _membersFailure = null;
        _publish();
      },
      onError: (Object error) {
        _membersFailure = _failure(error);
        _publish();
      },
    );
    _history = repository.watchSubscriptions().listen(
      (_) {
        _historyFailure = null;
        _publish();
      },
      onError: (Object error) {
        _historyFailure = _failure(error);
        _publish();
      },
    );
    _publish();
  }
  final GymRepository repository;
  final SubscriptionPolicy policy;
  final String memberId;
  late final StreamSubscription<Object?> _members;
  late final StreamSubscription<Object?> _history;
  late final LocalDateTimer _timer;
  final _operations = <String, String>{};
  AppFailure? _membersFailure;
  AppFailure? _historyFailure;
  void refreshDate() {
    if (isClosed) return;
    _timer.restart();
    _publish();
  }

  void _publish({SubmissionState? submission}) {
    if (isClosed) return;
    final members = repository.currentMembers;
    final history = repository.currentSubscriptions;
    final records =
        (history?.data ?? const <SubscriptionRecord>[])
            .where((r) => r.memberId == memberId)
            .toList()
          ..sort((a, b) => b.startDate.compareTo(a.startDate));
    emit(
      MemberDetailsState(
        member: members?.data.where((m) => m.id == memberId).firstOrNull,
        history: List.unmodifiable(records),
        coverage: policy.assess(
          records.map(
            (r) => CoveragePeriod(start: r.startDate, end: r.endDate),
          ),
        ),
        ready: members != null && history != null,
        complete:
            (members?.isComplete ?? false) && (history?.isComplete ?? false),
        failure: _membersFailure ?? _historyFailure,
        submission: submission ?? state.submission,
      ),
    );
  }

  static AppFailure _failure(Object error) =>
      error is AppFailure ? error : const AppFailure(FailureKind.unknown);

  Future<void> retry() => repository.retryReads();
  Future<void> deleteMember() => _delete(
    'member',
    () =>
        MemberDeletionCoordinator(repository)
            .delete(memberId, operationId: _id('member')),
  );
  Future<void> deleteSubscription(SubscriptionRecord record) => _delete(
    record.id,
    () {
      final current = repository.currentSubscriptions?.data
          .where((r) => r.id == record.id)
          .firstOrNull;
      if (current == null) throw const AppFailure(FailureKind.notFound);
      if (current.amount != record.amount ||
          current.startDate != record.startDate) {
        throw const AppFailure(FailureKind.conflict, code: 'stale-edit');
      }
      return repository.deleteSubscription(record, operationId: _id(record.id));
    },
  );
  String _id(String key) => _operations.putIfAbsent(key, repository.newId);
  Future<void> _delete(String key, MutationHandle Function() action) async {
    if (state.submission.busy) return;
    _publish(submission: const SubmissionState(busy: true));
    try {
      final failure = await action().localResult;
      if (!isClosed) _publish(submission: SubmissionState(failure: failure));
    } on AppFailure catch (failure) {
      if (!isClosed) _publish(submission: SubmissionState(failure: failure));
    }
  }

  @override
  Future<void> close() async {
    _timer.cancel();
    await _members.cancel();
    await _history.cancel();
    return super.close();
  }
}
