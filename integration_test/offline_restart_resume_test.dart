import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:gymk_app/core/errors/app_failure.dart';
import 'package:gymk_app/core/data/mutation_registry.dart';
import 'package:gymk_app/core/time/date_only.dart';
import 'package:gymk_app/features/members/business_logic/policies/member_deletion_coordinator.dart';
import 'package:gymk_app/features/subscriptions/data/models/subscription_record.dart';
import 'package:gymk_app/features/statistics/business_logic/cubit/statistics_cubit.dart';
import 'package:gymk_app/features/subscriptions/business_logic/policies/subscription_policy.dart';
import 'package:gymk_app/features/subscriptions/business_logic/policies/coverage_period.dart';

import '../test/support/fake_clock.dart';
import 'support/restart_session.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets(
    'restore SDK cache and queued writes across Android process death',
    (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Text('جيمك — استعادة البيانات بعد إيقاف العملية'),
          ),
        ),
      );
      await tester.runAsync(() async {
        final session = RestartSession();
        await session.open(seed: false);
        final repo = session.repository;
        final members = await repo.watchMembers().first.timeout(
          const Duration(seconds: 15),
        );
        final history = await repo.watchSubscriptions().first.timeout(
          const Duration(seconds: 15),
        );
        final dropins = await repo.watchDropins().first.timeout(
          const Duration(seconds: 15),
        );
        final settings = await repo.watchSettings().first.timeout(
          const Duration(seconds: 15),
        );
        expect(members.fromCache, isTrue);
        expect(members.isComplete, isFalse);
        expect(history.isComplete, isFalse);
        expect(dropins.isComplete, isFalse);
        expect(members.data, hasLength(2));
        expect(
          members.data.firstWhere((m) => m.id == 'restart-member').name,
          'بعد التعديل أوفلاين',
        );
        expect(members.data.any((m) => m.id == 'created-offline'), isTrue);
        expect(history.data, hasLength(2));
        expect(
          history.data.any((r) => r.memberId == 'cascade-member'),
          isFalse,
        );
        final renewal = history.data.firstWhere((r) => r.id != 'base');
        expect(renewal.startDate, DateOnly(2026, 11, 26));
        expect(renewal.endDate, DateOnly(2026, 12, 26));
        expect(renewal.paidAt, DateOnly(2026, 11, 10));
        expect(dropins.data, hasLength(2));
        expect(dropins.data.any((d) => d.id == 'delete-day'), isFalse);
        expect(settings.data!.subscriptionPrice, 150);
        expect(
          repo.mutations,
          isEmpty,
          reason: 'Operation notices are session memory, not a second persistent queue',
        );
        expect(
          members.hasPendingWrites ||
              history.hasPendingWrites ||
              dropins.hasPendingWrites,
          isTrue,
        );
        expect(
          () =>
              MemberDeletionCoordinator(repo)
                  .delete('restart-member', operationId: 'cold-delete'),
          throwsA(
            isA<AppFailure>().having(
              (f) => f.kind,
              'kind',
              FailureKind.incompleteData,
            ),
          ),
        );
        final clock = FakeClock(DateOnly(2026, 11, 10));
        final report = StatisticsCubit(repository: repo, clock: clock);
        await Future<void>.delayed(const Duration(milliseconds: 100));
        expect(report.state.cash.total, BigInt.from(215));
        expect(report.state.complete, isFalse);
        expect(report.state.pending, isTrue);
        final coverage = SubscriptionPolicy(clock: clock).assess(
          history.data.map(
            (r) => CoveragePeriod(start: r.startDate, end: r.endDate),
          ),
        );
        expect(coverage.currentExpiry, DateOnly(2026, 12, 26));
        debugPrint('GYMK_RESTART_WAITING_FOR_SERVICES uid=${repo.uid}');
        await session.firestore.enableNetwork();
        await session.confirmed();
        final root = session.firestore.collection('users').doc(repo.uid);
        final serverMembers = await root
            .collection('members')
            .get(const GetOptions(source: Source.server));
        final serverHistory = await root
            .collection('subscriptions')
            .get(const GetOptions(source: Source.server));
        final serverDropins = await root
            .collection('dropins')
            .get(const GetOptions(source: Source.server));
        expect(serverMembers.docs, hasLength(2));
        expect(serverHistory.docs, hasLength(2));
        expect(serverDropins.docs, hasLength(2));
        expect(
          serverMembers.docs.any((d) => d.id == 'cascade-member'),
          isFalse,
        );
        expect(
          serverHistory.docs.where((d) => d.id == renewal.id),
          hasLength(1),
        );
        await session.firestore.disableNetwork();
        final invalid = SubscriptionRecord(
          id: renewal.id,
          memberId: renewal.memberId,
          startDate: renewal.startDate,
          endDate: renewal.endDate,
          amount: 999,
          paidAt: DateOnly(2026, 12, 1),
        );
        final rejected = repo.saveSubscription(
          invalid,
          operationId: 'rejection-after-restart',
        );
        expect(
          await rejected.localResult.timeout(const Duration(seconds: 15)),
          isNull,
        );
        await session.firestore.enableNetwork();
        expect(
          (await rejected.remoteResult.timeout(const Duration(seconds: 30)))
              ?.kind,
          FailureKind.permission,
        );
        await session.confirmed();
        if (report.state.cash.total != BigInt.from(215)) {
          await report.stream
              .firstWhere((s) => s.cash.total == BigInt.from(215))
              .timeout(const Duration(seconds: 15));
        }
        expect(
          repo.mutations.any(
            (m) =>
                m.stage == MutationStage.rejected &&
                m.target == 'restart-member',
          ),
          isTrue,
        );
        expect(report.state.month, DateOnly(2026, 11, 1));
        await report.close();
        await session.close();
        debugPrint('GYMK_RESTART_VERIFIED');
      });
    },
    timeout: const Timeout(Duration(minutes: 4)),
  );
}
