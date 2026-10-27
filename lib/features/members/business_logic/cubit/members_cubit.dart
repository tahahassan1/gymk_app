import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../app/session/data/repositories/gym_repository.dart';
import '../../../../core/errors/app_failure.dart';
import '../../../../core/time/local_date_timer.dart';
import '../../../subscriptions/business_logic/policies/coverage_period.dart';
import '../../../subscriptions/business_logic/policies/subscription_policy.dart';
import '../../../subscriptions/data/models/subscription_record.dart';
import '../../data/models/member.dart';
import 'members_state.dart';

final class MembersCubit extends Cubit<MembersState> {
  MembersCubit({required this.repository, required this.policy})
    : super(const MembersState()) {
    _dateTimer = LocalDateTimer(refreshDate);
    _membersSubscription = repository.watchMembers().listen(
      (snapshot) {
        if (isClosed) return;
        _members = snapshot.data;
        _publish(
          state.copyWith(
            membersReady: true,
            membersComplete: snapshot.isComplete,
            membersFailure: null,
          ),
        );
      },
      onError: (Object error) {
        if (!isClosed) {
          emit(
            state.copyWith(
              membersFailure: _failure(error),
              membersComplete: false,
            ),
          );
        }
      },
    );
    _coverageSubscription = repository.watchSubscriptions().listen(
      (snapshot) {
        if (isClosed) return;
        _index = _indexRecords(snapshot.data);
        _publish(
          state.copyWith(
            coverageReady: true,
            coverageComplete: snapshot.isComplete,
            coverageFailure: null,
          ),
        );
      },
      onError: (Object error) {
        if (!isClosed) {
          emit(
            state.copyWith(
              coverageFailure: _failure(error),
              coverageComplete: false,
            ),
          );
        }
      },
    );
  }

  final GymRepository repository;
  final SubscriptionPolicy policy;
  late final LocalDateTimer _dateTimer;
  late final StreamSubscription<Object?> _membersSubscription;
  late final StreamSubscription<Object?> _coverageSubscription;
  List<Member> _members = const [];
  Map<String, List<CoveragePeriod>> _index = const {};

  void searchChanged(String query) => _publish(state.copyWith(query: query));
  void filterChanged(MemberFilter filter) =>
      _publish(state.copyWith(filter: filter));
  void refreshDate() {
    if (isClosed) return;
    _dateTimer.restart();
    _publish(state);
  }

  Future<void> retry() => repository.retryReads();

  void _publish(MembersState next) {
    if (isClosed) return;
    final query = next.query.trim().toLowerCase();
    final today = policy.clock.today();
    final rows = <MemberRowData>[];
    for (final member in _members) {
      if (!member.name.toLowerCase().contains(query)) continue;
      final coverage = policy.assess(
        _index[member.id] ?? const [],
        asOf: today,
      );
      final included = switch (next.filter) {
        MemberFilter.all => true,
        MemberFilter.active => coverage.status == MembershipStatus.active,
        MemberFilter.expiringSoon =>
          coverage.status == MembershipStatus.expiringSoon,
        MemberFilter.expired => coverage.status == MembershipStatus.expired,
      };
      if (included) rows.add(MemberRowData(member: member, coverage: coverage));
    }
    rows.sort((left, right) => left.member.name.compareTo(right.member.name));
    emit(next.copyWith(rows: List.unmodifiable(rows)));
  }

  static Map<String, List<CoveragePeriod>> _indexRecords(
    List<SubscriptionRecord> records,
  ) {
    final result = <String, List<CoveragePeriod>>{};
    for (final record in records) {
      (result[record.memberId] ??= []).add(
        CoveragePeriod(start: record.startDate, end: record.endDate),
      );
    }
    return result;
  }

  static AppFailure _failure(Object error) =>
      error is AppFailure ? error : const AppFailure(FailureKind.unknown);

  @override
  Future<void> close() async {
    _dateTimer.cancel();
    await Future.wait([
      _membersSubscription.cancel(),
      _coverageSubscription.cancel(),
    ]);
    return super.close();
  }
}
