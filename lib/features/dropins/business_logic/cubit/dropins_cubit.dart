import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../app/session/data/repositories/gym_repository.dart';
import '../../../../core/data/submission_state.dart';
import '../../../../core/errors/app_failure.dart';
import '../../../../core/time/clock.dart';
import '../../../../core/time/date_only.dart';
import '../../../../core/time/local_date_timer.dart';
import '../../data/models/dropin.dart';
import 'dropins_state.dart';

final class DropinsCubit extends Cubit<DropinsState> {
  DropinsCubit({required this.repository, required this.clock})
    : super(DropinsState(day: clock.today(), today: clock.today())) {
    _timer = LocalDateTimer(refreshDate);
    _subscription = repository.watchDropins().listen(
      (_) {
        _failure = null;
        _publish();
      },
      onError: (Object error) {
        _failure = error is AppFailure
            ? error
            : const AppFailure(FailureKind.unknown);
        _publish();
      },
    );
  }
  final GymRepository repository;
  final Clock clock;
  late final LocalDateTimer _timer;
  late final StreamSubscription<Object?> _subscription;
  AppFailure? _failure;
  bool _followToday = true;
  final _operations = <String, String>{};
  void dayChanged(DateOnly day) {
    if (day.isAfter(clock.today())) return;
    _followToday = day == clock.today();
    _publish(day: day);
  }

  void showToday() {
    _followToday = true;
    _publish(day: clock.today());
  }

  void refreshDate() {
    if (isClosed) return;
    _timer.restart();
    _publish(day: _followToday ? clock.today() : state.day);
  }

  Future<void> retry() => repository.retryReads();
  void _publish({DateOnly? day, SubmissionState? submission}) {
    if (isClosed) return;
    final snapshot = repository.currentDropins;
    final selected = day ?? state.day;
    final rows =
        (snapshot?.data ?? const <Dropin>[])
            .where((r) => r.date == selected)
            .toList()
          ..sort((a, b) => a.id.compareTo(b.id));
    emit(
      DropinsState(
        day: selected,
        today: clock.today(),
        rows: List.unmodifiable(rows),
        ready: snapshot != null,
        complete: snapshot?.isComplete ?? false,
        pending: snapshot?.hasPendingWrites ?? false,
        failure: _failure,
        submission: submission ?? state.submission,
      ),
    );
  }

  Future<void> delete(Dropin record) async {
    if (state.submission.busy) return;
    _publish(submission: const SubmissionState(busy: true));
    try {
      final current = repository.currentDropins?.data
          .where((r) => r.id == record.id)
          .firstOrNull;
      if (current == null) throw const AppFailure(FailureKind.notFound);
      if (current.amount != record.amount ||
          current.name != record.name ||
          current.date != record.date) {
        throw const AppFailure(FailureKind.conflict, code: 'stale-edit');
      }
      final handle = repository.deleteDropin(
        record,
        operationId: _operations.putIfAbsent(record.id, repository.newId),
      );
      final failure = await handle.localResult;
      if (!isClosed) _publish(submission: SubmissionState(failure: failure));
    } on AppFailure catch (failure) {
      if (!isClosed) _publish(submission: SubmissionState(failure: failure));
    }
  }

  @override
  Future<void> close() async {
    _timer.cancel();
    await _subscription.cancel();
    return super.close();
  }
}
