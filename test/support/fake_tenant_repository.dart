import 'dart:async';

import 'package:gymk_app/core/data/read_snapshot.dart';
import 'package:gymk_app/features/settings/data/models/gym_settings.dart';

import 'fake_gym_repository.dart';

class FakeTenantRepository extends FakeGymRepository {
  FakeTenantRepository(this.tenantUid, {this.initial});
  final String tenantUid;
  ReadSnapshot<GymSettings?>? initial;
  final settingsSource = StreamController<ReadSnapshot<GymSettings?>>.broadcast(
    sync: true,
  );
  Completer<void>? pendingBootstrap;
  Object? bootstrapError;
  int bootstraps = 0;
  int settingsConsumers = 0;
  bool closed = false;

  @override
  String get uid => tenantUid;
  @override
  ReadSnapshot<GymSettings?>? get currentSettings => initial;
  @override
  Stream<ReadSnapshot<GymSettings?>> watchSettings() =>
      Stream<ReadSnapshot<GymSettings?>>.multi((sink) {
        settingsConsumers++;
        final subscription = settingsSource.stream.listen(
          sink.add,
          onError: sink.addError,
          onDone: sink.close,
        );
        sink.onCancel = subscription.cancel;
        if (initial case final value?) sink.add(value);
      });
  void emitSettings(ReadSnapshot<GymSettings?> value) {
    initial = value;
    if (!closed) settingsSource.add(value);
  }

  @override
  Future<void> ensureInitialSettings(GymSettings defaults) async {
    bootstraps++;
    if (pendingBootstrap case final pending?) await pending.future;
    if (bootstrapError case final error?) throw error;
    emitSettings(snapshot<GymSettings?>(defaults));
  }

  @override
  Future<void> close() async {
    if (closed) return;
    closed = true;
    await settingsSource.close();
    await super.close();
  }
}
